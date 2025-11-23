import 'dart:convert';
import 'package:http/http.dart' as http;

/// Quick script to check Brevo sender configuration
///
/// Run with: dart run scripts/test_brevo_sender.dart
void main() async {
  const apiKey = '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';
  const brevoApiUrl = 'https://api.brevo.com/v3';

  print('🔍 Checking Brevo sender configuration...\n');

  // Check account info
  try {
    final accountResponse = await http.get(
      Uri.parse('$brevoApiUrl/account'),
      headers: {
        'api-key': apiKey,
        'Accept': 'application/json',
      },
    );

    if (accountResponse.statusCode == 200) {
      final accountData = jsonDecode(accountResponse.body);
      print('✅ Account Information:');
      print('   Email: ${accountData['email']}');
      print('   Company: ${accountData['companyName']}');
      print('   Plan: ${accountData['plan']}\n');
    }
  } catch (e) {
    print('❌ Error fetching account info: $e\n');
  }

  // Check senders
  try {
    final sendersResponse = await http.get(
      Uri.parse('$brevoApiUrl/senders'),
      headers: {
        'api-key': apiKey,
        'Accept': 'application/json',
      },
    );

    if (sendersResponse.statusCode == 200) {
      final sendersData = jsonDecode(sendersResponse.body);
      final senders = sendersData['senders'] as List;

      print('📧 Configured Senders:');
      if (senders.isEmpty) {
        print('   ⚠️  No verified senders found!');
        print('   ⚠️  You need to verify a sender email in Brevo dashboard');
        print('   🔗 Go to: https://app.brevo.com/settings/senders\n');
      } else {
        for (final sender in senders) {
          print('   - ${sender['name']} <${sender['email']}>');
          print('     Active: ${sender['active']}');
          print('');
        }
      }
    }
  } catch (e) {
    print('❌ Error fetching senders: $e\n');
  }

  // Test email sending (dry run)
  print('🧪 Testing email send (to a test address)...\n');
  try {
    final testEmailResponse = await http.post(
      Uri.parse('$brevoApiUrl/smtp/email'),
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'sender': {
          'name': 'TravelCompanion',
          'email': 'noreply@travelcompanion.app',
        },
        'to': [
          {
            'email': 'test@example.com',
            'name': 'Test User',
          }
        ],
        'subject': '🎉 TravelCompanion Test Email',
        'htmlContent': '<h1>Test Email</h1><p>This is a test from TravelCompanion app.</p>',
        'textContent': 'Test Email\nThis is a test from TravelCompanion app.',
      }),
    );

    print('Response Status: ${testEmailResponse.statusCode}');
    print('Response Body: ${testEmailResponse.body}\n');

    if (testEmailResponse.statusCode == 201) {
      final responseData = jsonDecode(testEmailResponse.body);
      print('✅ Email sent successfully!');
      print('   Message ID: ${responseData['messageId']}\n');
    } else if (testEmailResponse.statusCode == 400) {
      final errorData = jsonDecode(testEmailResponse.body);
      print('❌ Email sending failed:');
      print('   ${errorData['message']}\n');

      if (errorData['message'].toString().contains('sender')) {
        print('⚠️  Action Required:');
        print('   1. Go to Brevo dashboard: https://app.brevo.com/settings/senders');
        print('   2. Add and verify sender email: noreply@travelcompanion.app');
        print('   3. Or use the verified sender from your account\n');
      }
    }
  } catch (e) {
    print('❌ Error testing email: $e\n');
  }
}
