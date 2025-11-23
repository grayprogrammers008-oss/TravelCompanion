import 'dart:convert';
import 'package:http/http.dart' as http;

/// Standalone script to send test email to NithyaGanesan53@gmail.com
///
/// Run with: dart run scripts/send_test_email_nithya.dart
void main() async {
  const apiKey = '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';
  const brevoApiUrl = 'https://api.brevo.com/v3';
  const senderEmail = 'palkarfoods224@gmail.com';
  const senderName = 'TravelCompanion';

  print('📧 Sending test email to NithyaGanesan53@gmail.com...\n');

  // Build email content
  final htmlContent = _buildTripInviteEmail(
    toName: 'Nithya',
    tripName: 'TravelCompanion Integration Test',
    inviterName: 'Claude (Development Team)',
    inviteCode: 'TEST2024',
    tripDestination: 'Brevo Email Service',
    tripStartDate: 'November 15, 2025',
    tripEndDate: 'November 15, 2025',
  );

  final textContent = '''
Hi Nithya!

Claude (Development Team) has invited you to join their trip: TravelCompanion Integration Test

Trip Details:
📍 Brevo Email Service
📅 November 15, 2025 - November 15, 2025

Your Invite Code: TEST2024

This is a test email to verify the Brevo email integration is working correctly.

---
This invitation was sent by Claude (Development Team) via TravelCompanion
© 2024 TravelCompanion. All rights reserved.
''';

  // Send email
  print('📨 Sending trip invitation email...');
  try {
    final response = await http.post(
      Uri.parse('$brevoApiUrl/smtp/email'),
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'sender': {
          'name': senderName,
          'email': senderEmail,
        },
        'to': [
          {
            'email': 'NithyaGanesan53@gmail.com',
            'name': 'Nithya',
          }
        ],
        'subject': '🎉 You\'re invited to TravelCompanion Integration Test!',
        'htmlContent': htmlContent,
        'textContent': textContent,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('\n✅ SUCCESS! Email sent to NithyaGanesan53@gmail.com');
      print('📬 Message ID: ${responseData['messageId']}');
      print('');
      print('Email Details:');
      print('  To: NithyaGanesan53@gmail.com');
      print('  Subject: 🎉 You\'re invited to TravelCompanion Integration Test!');
      print('  From: $senderName <$senderEmail>');
      print('');
      print('The email includes:');
      print('  ✨ Beautiful Brilliant purple gradient header');
      print('  📍 Trip destination: Brevo Email Service');
      print('  📅 Trip dates: November 15, 2025');
      print('  🔑 Invite code: TEST2024');
      print('  🔗 Deep link button to accept invitation');
    } else {
      print('\n❌ FAILED to send email');
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('\n❌ Error sending email: $e');
  }
}

String _buildTripInviteEmail({
  required String toName,
  required String tripName,
  required String inviterName,
  required String inviteCode,
  String? tripDestination,
  String? tripStartDate,
  String? tripEndDate,
}) {
  final destinationText = tripDestination != null
      ? '<p style="color: #64748B; font-size: 16px; margin: 0 0 8px 0;">📍 $tripDestination</p>'
      : '';

  final datesText = (tripStartDate != null && tripEndDate != null)
      ? '<p style="color: #64748B; font-size: 16px; margin: 0 0 24px 0;">📅 $tripStartDate - $tripEndDate</p>'
      : '';

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Trip Invitation</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #F8FAFC;">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #F8FAFC;">
    <tr>
      <td style="padding: 40px 20px;">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: #FFFFFF; border-radius: 16px; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);">

          <!-- Header -->
          <tr>
            <td style="padding: 40px 40px 20px 40px; text-align: center; background: linear-gradient(135deg, #7B5FE8 0%, #5234B8 100%); border-radius: 16px 16px 0 0;">
              <h1 style="margin: 0; color: #FFFFFF; font-size: 32px; font-weight: 700; letter-spacing: -0.5px;">
                ✈️ TravelCompanion
              </h1>
              <p style="margin: 8px 0 0 0; color: rgba(255, 255, 255, 0.9); font-size: 16px;">
                Your Journey, Together
              </p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding: 40px;">
              <h2 style="margin: 0 0 16px 0; color: #0F172A; font-size: 24px; font-weight: 600;">
                Hi $toName! 👋
              </h2>

              <p style="margin: 0 0 24px 0; color: #334155; font-size: 16px; line-height: 1.6;">
                <strong>$inviterName</strong> has invited you to join their trip:
              </p>

              <!-- Trip Info Card -->
              <div style="background-color: #F1F5F9; border-radius: 12px; padding: 24px; margin: 0 0 32px 0;">
                <h3 style="margin: 0 0 12px 0; color: #7B5FE8; font-size: 22px; font-weight: 700;">
                  $tripName
                </h3>
                $destinationText
                $datesText

                <div style="background-color: #FFFFFF; border: 2px dashed #7B5FE8; border-radius: 8px; padding: 16px; margin-top: 16px; text-align: center;">
                  <p style="margin: 0 0 8px 0; color: #64748B; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600;">
                    Your Invite Code
                  </p>
                  <p style="margin: 0; color: #7B5FE8; font-size: 32px; font-weight: 700; font-family: 'Courier New', monospace; letter-spacing: 4px;">
                    $inviteCode
                  </p>
                </div>
              </div>

              <!-- CTA Button -->
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="text-align: center;">
                    <a href="travelcompanion://invite/$inviteCode" style="display: inline-block; background: linear-gradient(135deg, #7B5FE8 0%, #5234B8 100%); color: #FFFFFF; text-decoration: none; padding: 16px 48px; border-radius: 12px; font-size: 16px; font-weight: 700; box-shadow: 0 8px 24px -4px rgba(123, 95, 232, 0.3);">
                      Accept Invitation
                    </a>
                  </td>
                </tr>
              </table>

              <p style="margin: 32px 0 0 0; color: #64748B; font-size: 14px; text-align: center; line-height: 1.6;">
                Don't have the TravelCompanion app yet?<br>
                Download it from the App Store or Google Play
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 40px; background-color: #F8FAFC; border-radius: 0 0 16px 16px; text-align: center;">
              <p style="margin: 0; color: #94A3B8; font-size: 12px;">
                This invitation was sent by $inviterName via TravelCompanion
              </p>
              <p style="margin: 8px 0 0 0; color: #CBD5E1; font-size: 11px;">
                © 2024 TravelCompanion. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
}
