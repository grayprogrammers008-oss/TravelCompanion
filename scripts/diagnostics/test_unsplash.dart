import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Unsplash API...\n');

  const accessKey = 'iLIdeLGraeoRJUQPJMY01oZT4wDo3RlHouy0cMG5zXA';
  const query = 'paris travel landmark';

  final uri = Uri.parse('https://api.unsplash.com/photos/random').replace(
    queryParameters: {
      'query': query,
      'orientation': 'landscape',
    },
  );

  print('📡 Calling: $uri');
  print('🔑 Using API Key: ${accessKey.substring(0, 10)}...\n');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Client-ID $accessKey',
        'Accept-Version': 'v1',
      },
    ).timeout(const Duration(seconds: 10));

    print('📥 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ SUCCESS!');
      print('');
      print('Image URL: ${data['urls']['regular']}');
      print('Photographer: ${data['user']['name']}');
      print('');
      print('🎉 Your Unsplash API key is working correctly!');
    } else if (response.statusCode == 401) {
      print('❌ ERROR: Invalid API key (401 Unauthorized)');
      print('');
      print('Please check:');
      print('1. Your API key is correct');
      print('2. Your Unsplash app is active');
      print('3. Visit: https://unsplash.com/oauth/applications');
    } else if (response.statusCode == 403) {
      print('⚠️  Rate limit reached (403 Forbidden)');
      print('Free tier: 50 requests/hour');
      print('Wait an hour or upgrade your plan');
    } else {
      print('❌ ERROR: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Network error: $e');
  }
}
