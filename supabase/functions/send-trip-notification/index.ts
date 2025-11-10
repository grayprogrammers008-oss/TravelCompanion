// Supabase Edge Function: send-trip-notification
// Sends Firebase Cloud Messaging push notifications for trip updates

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')! // Firebase Cloud Messaging server key

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
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const { trip_id, payload, exclude_user_id }: RequestBody = await req.json()

    console.log('📤 Sending trip notification:', { trip_id, type: payload.type })

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 1. Get all trip members
    const { data: members, error: membersError } = await supabase
      .from('trip_members')
      .select('user_id, profiles:user_id(full_name)')
      .eq('trip_id', trip_id)

    if (membersError) {
      console.error('Failed to fetch trip members:', membersError)
      throw membersError
    }

    console.log(`   Found ${members?.length || 0} trip members`)

    // 2. Filter out excluded user and get FCM tokens
    const userIds = members
      ?.filter(m => m.user_id !== exclude_user_id)
      .map(m => m.user_id) || []

    if (userIds.length === 0) {
      console.log('   No users to notify (all excluded or no members)')
      return new Response(
        JSON.stringify({ success: true, sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 3. Get FCM tokens for these users
    const { data: tokens, error: tokensError } = await supabase
      .from('user_fcm_tokens')
      .select('user_id, fcm_token')
      .in('user_id', userIds)
      .eq('is_active', true)

    if (tokensError) {
      console.error('Failed to fetch FCM tokens:', tokensError)
      throw tokensError
    }

    console.log(`   Found ${tokens?.length || 0} FCM tokens`)

    if (!tokens || tokens.length === 0) {
      console.log('   No FCM tokens found')
      return new Response(
        JSON.stringify({ success: true, sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 4. Generate notification title and body
    const { title, body } = generateNotificationContent(payload)

    // 5. Send FCM notifications
    const fcmPromises = tokens.map(({ fcm_token }) =>
      sendFCMNotification(fcm_token, title, body, payload)
    )

    const results = await Promise.allSettled(fcmPromises)
    const successCount = results.filter(r => r.status === 'fulfilled').length
    const failureCount = results.filter(r => r.status === 'rejected').length

    console.log(`   ✅ Sent ${successCount} notifications, ${failureCount} failed`)

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failureCount,
        total: tokens.length
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Error sending trip notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// Generate notification title and body from payload
function generateNotificationContent(payload: NotificationPayload): { title: string, body: string } {
  let title = ''
  let body = ''

  switch (payload.type) {
    case 'trip_created':
      title = 'New Trip Created'
      body = `${payload.sender_name || 'Someone'} created a new trip: ${payload.trip_name}`
      break
    case 'trip_updated':
      title = 'Trip Updated'
      const field = payload.updated_field ? ` (${payload.updated_field})` : ''
      body = `${payload.sender_name || 'Someone'} updated ${payload.trip_name}${field}`
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
    default:
      title = payload.trip_name
      body = payload.message_text || 'Trip update'
  }

  return { title, body }
}

// Send FCM notification
async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data: NotificationPayload
): Promise<void> {
  const fcmEndpoint = 'https://fcm.googleapis.com/fcm/send'

  const message = {
    to: token,
    notification: {
      title,
      body,
      sound: 'default',
      badge: '1',
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    priority: 'high',
  }

  const response = await fetch(fcmEndpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify(message),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`FCM error: ${response.status} - ${error}`)
  }

  console.log(`   📤 Sent notification to token: ${token.substring(0, 20)}...`)
}
