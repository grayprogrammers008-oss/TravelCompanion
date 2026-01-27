import 'dart:io';

void main() async {
  print('Testing network connectivity...');

  try {
    // Test 1: Basic DNS lookup
    print('\n1. Testing DNS resolution for Supabase...');
    final addresses = await InternetAddress.lookup('ckgaoxajvonazdwpsmai.supabase.co');
    print('✅ DNS works! Resolved to: ${addresses.first.address}');

    // Test 2: Try connecting to Google
    print('\n2. Testing general internet connectivity...');
    final googleAddresses = await InternetAddress.lookup('google.com');
    print('✅ Internet works! Can reach Google: ${googleAddresses.first.address}');

    // Test 3: Try HTTP request to Supabase
    print('\n3. Testing HTTP connection to Supabase...');
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://ckgaoxajvonazdwpsmai.supabase.co'));
    final response = await request.close();
    print('✅ HTTP works! Status: ${response.statusCode}');
    client.close();

    print('\n🎉 All network tests passed!');
  } catch (e) {
    print('❌ Network test failed: $e');
    print('\n🔍 Troubleshooting steps:');
    print('1. Check if you have internet connection');
    print('2. If on emulator: Restart emulator with network access');
    print('3. If on physical device: Check WiFi/mobile data');
    print('4. Try disabling VPN/proxy');
    print('5. Check firewall settings');
  }
}
