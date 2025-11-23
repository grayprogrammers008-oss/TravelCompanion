import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

/// Email service using Brevo (SendinBlue) API for sending trip invitations and notifications
///
/// Usage:
/// ```dart
/// final emailService = EmailService();
/// await emailService.sendTripInvite(
///   toEmail: 'friend@example.com',
///   toName: 'John Doe',
///   tripName: 'Bali Adventure 2024',
///   inviterName: 'Jane Smith',
///   inviteCode: 'ABC123',
/// );
/// ```
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const String _brevoApiUrl = 'https://api.brevo.com/v3';

  final String _apiKey = SupabaseConfig.brevoApiKey;
  final String _senderEmail = SupabaseConfig.brevoSenderEmail;
  final String _senderName = SupabaseConfig.brevoSenderName;

  /// Test the Brevo API connection
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_brevoApiUrl/account'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Brevo connection successful!');
          debugPrint('Account: ${data['email']}');
          debugPrint('Company: ${data['companyName']}');
          debugPrint('Plan: ${data['plan']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Brevo connection failed: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error testing Brevo connection: $e');
      }
      return false;
    }
  }

  /// Send a trip invitation email via Brevo
  Future<bool> sendTripInvite({
    required String toEmail,
    required String toName,
    required String tripName,
    required String inviterName,
    required String inviteCode,
    String? tripDestination,
    String? tripStartDate,
    String? tripEndDate,
  }) async {
    try {
      // Build the email HTML content
      final htmlContent = _buildInviteEmailHtml(
        toName: toName,
        tripName: tripName,
        inviterName: inviterName,
        inviteCode: inviteCode,
        tripDestination: tripDestination,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
      );

      // Build the email plain text content (fallback)
      final textContent = _buildInviteEmailText(
        toName: toName,
        tripName: tripName,
        inviterName: inviterName,
        inviteCode: inviteCode,
      );

      // Send via Brevo API
      final response = await http.post(
        Uri.parse('$_brevoApiUrl/smtp/email'),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sender': {
            'name': _senderName,
            'email': _senderEmail,
          },
          'to': [
            {
              'email': toEmail,
              'name': toName,
            }
          ],
          'subject': '🎉 You\'re invited to $tripName!',
          'htmlContent': htmlContent,
          'textContent': textContent,
        }),
      );

      if (response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Trip invitation email sent to $toEmail');
          final responseData = jsonDecode(response.body);
          debugPrint('Message ID: ${responseData['messageId']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to send email. Status: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending email: $e');
      }
      return false;
    }
  }

  /// Send a generic email (for future use)
  Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String htmlContent,
    String? textContent,
    String? toName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_brevoApiUrl/smtp/email'),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sender': {
            'name': _senderName,
            'email': _senderEmail,
          },
          'to': [
            {
              'email': toEmail,
              if (toName != null) 'name': toName,
            }
          ],
          'subject': subject,
          'htmlContent': htmlContent,
          if (textContent != null) 'textContent': textContent,
        }),
      );

      if (response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Email sent to $toEmail');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to send email: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending email: $e');
      }
      return false;
    }
  }

  /// Send email to multiple recipients
  Future<bool> sendBulkEmail({
    required List<String> toEmails,
    required String subject,
    required String htmlContent,
    String? textContent,
  }) async {
    try {
      final recipients = toEmails.map((email) => {'email': email}).toList();

      final response = await http.post(
        Uri.parse('$_brevoApiUrl/smtp/email'),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sender': {
            'name': _senderName,
            'email': _senderEmail,
          },
          'to': recipients,
          'subject': subject,
          'htmlContent': htmlContent,
          if (textContent != null) 'textContent': textContent,
        }),
      );

      if (response.statusCode == 201) {
        if (kDebugMode) {
          debugPrint('✅ Bulk email sent to ${toEmails.length} recipients');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to send bulk email: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending bulk email: $e');
      }
      return false;
    }
  }

  /// Build HTML email content for trip invitation
  String _buildInviteEmailHtml({
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
                    <a href="https://pathio.travel/invite/$inviteCode" style="display: inline-block; background: linear-gradient(135deg, #7B5FE8 0%, #5234B8 100%); color: #FFFFFF; text-decoration: none; padding: 16px 48px; border-radius: 12px; font-size: 16px; font-weight: 700; box-shadow: 0 8px 24px -4px rgba(123, 95, 232, 0.3);">
                      Open Invitation
                    </a>
                  </td>
                </tr>
              </table>

              <p style="margin: 24px 0 0 0; color: #64748B; font-size: 14px; text-align: center; line-height: 1.6;">
                Clicking the button will open the app if installed,<br>
                or guide you to download it from the App Store or Google Play
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

  /// Build plain text email content (fallback)
  String _buildInviteEmailText({
    required String toName,
    required String tripName,
    required String inviterName,
    required String inviteCode,
  }) {
    return '''
Hi $toName!

$inviterName has invited you to join their trip: $tripName

Your Invite Code: $inviteCode

Open the TravelCompanion app and enter this code to accept the invitation.

Don't have the app yet? Download it from the App Store or Google Play.

---
This invitation was sent by $inviterName via TravelCompanion
© 2024 TravelCompanion. All rights reserved.
''';
  }
}
