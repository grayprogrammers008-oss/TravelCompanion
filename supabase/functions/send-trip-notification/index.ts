// Supabase Edge Function: send-trip-notification
//
// Fans out an FCM push to every member of a trip (except the originator)
// via the FCM HTTP v1 API. The legacy `fcm/send` endpoint with a Server
// Key was shut down by Google in June 2024 — v1 authenticates with a
// short-lived OAuth2 access token minted from a Firebase service account.
//
// Required env vars:
//   * SUPABASE_URL                        — auto-provided in functions
//   * SUPABASE_SERVICE_ROLE_KEY           — auto-provided in functions
//   * FIREBASE_SERVICE_ACCOUNT_JSON       — full JSON contents of a service
//                                           account key file (one line).
//                                           Firebase Console → Project
//                                           Settings → Service Accounts →
//                                           "Generate new private key".

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from "npm:google-auth-library@^9"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!

const serviceAccount = JSON.parse(SERVICE_ACCOUNT_JSON) as {
  project_id: string
  client_email: string
  private_key: string
}
const FCM_PROJECT_ID = serviceAccount.project_id

// `JWT` caches the access token internally (~55-minute TTL) so we don't
// re-mint one per request.
const jwtClient = new JWT({
  email: serviceAccount.client_email,
  key: serviceAccount.private_key,
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
})

interface NotificationPayload {
  type: string
  trip_id: string
  trip_name: string
  message_id?: string
  sender_id?: string
  sender_name?: string
  sender_avatar_url?: string
  message_text?: string
  reaction_emoji?: string
  updated_field?: string
  member_name?: string
}

interface RequestBody {
  trip_id: string
  payload: NotificationPayload
  exclude_user_id?: string
}

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { trip_id, payload, exclude_user_id }: RequestBody = await req.json()
    console.log('📤 Sending trip notification:', { trip_id, type: payload.type })

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 1. Members of this trip.
    const { data: members, error: membersError } = await supabase
      .from('trip_members')
      .select('user_id')
      .eq('trip_id', trip_id)

    if (membersError) throw membersError

    const userIds = (members ?? [])
      .filter((m) => m.user_id !== exclude_user_id)
      .map((m) => m.user_id)

    if (userIds.length === 0) {
      return jsonOk({ sent: 0, reason: 'no_recipients' })
    }

    // 2. Active FCM tokens for those members.
    const { data: tokens, error: tokensError } = await supabase
      .from('user_fcm_tokens')
      .select('user_id, fcm_token')
      .in('user_id', userIds)
      .eq('is_active', true)

    if (tokensError) throw tokensError
    if (!tokens || tokens.length === 0) {
      return jsonOk({ sent: 0, reason: 'no_tokens' })
    }

    // 3. Mint a single access token for this whole fan-out.
    const accessToken = await getAccessToken()

    // 4. Generate title/body and send.
    const { title, body } = generateNotificationContent(payload)

    const results = await Promise.allSettled(
      tokens.map((t) =>
        sendFCMNotification(accessToken, t.fcm_token, title, body, payload)
      )
    )

    const sent = results.filter((r) => r.status === 'fulfilled').length
    const failed = results.length - sent
    console.log(`   ✅ Sent ${sent}, failed ${failed}`)

    // 5. Garbage-collect any tokens FCM said are no longer valid.
    const deadTokens: string[] = []
    results.forEach((r, i) => {
      if (r.status === 'rejected' && r.reason?.unregistered === true) {
        deadTokens.push(tokens[i].fcm_token)
      }
    })
    if (deadTokens.length > 0) {
      await supabase
        .from('user_fcm_tokens')
        .update({ is_active: false })
        .in('fcm_token', deadTokens)
      console.log(`   🧹 Marked ${deadTokens.length} token(s) inactive`)
    }

    return jsonOk({ sent, failed, total: tokens.length })
  } catch (error) {
    console.error('❌ send-trip-notification failed:', error)
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

function jsonOk(payload: Record<string, unknown>): Response {
  return new Response(
    JSON.stringify({ success: true, ...payload }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  )
}

async function getAccessToken(): Promise<string> {
  const { token } = await jwtClient.getAccessToken()
  if (!token) throw new Error('Failed to obtain FCM access token')
  return token
}

function generateNotificationContent(payload: NotificationPayload): { title: string; body: string } {
  let title = ''
  let body = ''

  switch (payload.type) {
    case 'trip_created':
      title = 'New Trip Created'
      body = `${payload.sender_name || 'Someone'} created a new trip: ${payload.trip_name}`
      break
    case 'trip_updated':
      title = 'Trip Updated'
      body = `${payload.sender_name || 'Someone'} updated ${payload.trip_name}${
        payload.updated_field ? ` (${payload.updated_field})` : ''
      }`
      break
    case 'trip_deleted':
      title = 'Trip Deleted'
      body = `${payload.sender_name || 'Someone'} deleted the trip: ${payload.trip_name}`
      break
    case 'member_added':
      title = 'Member Added'
      body = `${payload.member_name || 'Someone'} joined ${payload.trip_name}`
      break
    case 'member_removed':
      title = 'Member Removed'
      body = `${payload.member_name || 'Someone'} left ${payload.trip_name}`
      break
    case 'new_message':
      title = payload.sender_name || 'New Message'
      body = payload.message_text || `You have a new message in ${payload.trip_name}`
      break
    case 'poll_created':
      title = `New poll in ${payload.trip_name}`
      body = `${payload.sender_name || 'Organizer'} asks: ${payload.message_text || 'Cast your vote'}`
      break
    case 'poll_closed':
      title = `Poll closed in ${payload.trip_name}`
      body = payload.message_text || 'A vote has finished'
      break
    default:
      title = payload.trip_name
      body = payload.message_text || 'Trip update'
  }
  return { title, body }
}

async function sendFCMNotification(
  accessToken: string,
  deviceToken: string,
  title: string,
  body: string,
  data: NotificationPayload,
): Promise<void> {
  // FCM v1 requires every value in `data` to be a string.
  const stringData: Record<string, string> = { click_action: 'FLUTTER_NOTIFICATION_CLICK' }
  for (const [k, v] of Object.entries(data)) {
    if (v !== undefined && v !== null) stringData[k] = String(v)
  }

  const message = {
    message: {
      token: deviceToken,
      notification: { title, body },
      data: stringData,
      android: {
        priority: 'high',
        notification: { sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    },
  }

  const url = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify(message),
  })

  if (!response.ok) {
    const text = await response.text()
    // FCM v1: a token that's been uninstalled / replaced returns
    // NOT_FOUND or UNREGISTERED. Surface that so the caller can clean up.
    const unregistered =
      response.status === 404 ||
      /UNREGISTERED|registration-token-not-registered/i.test(text)
    const err = new Error(
      `FCM error: ${response.status} - ${text}`,
    ) as Error & { unregistered: boolean }
    err.unregistered = unregistered
    throw err
  }
}
