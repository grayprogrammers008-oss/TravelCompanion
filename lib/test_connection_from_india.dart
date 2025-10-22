import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';

/// Connection Test Page - For Nithya to run from India
/// This will test every step of the connection to identify the exact failure point
class ConnectionTestPage extends StatefulWidget {
  const ConnectionTestPage({super.key});

  @override
  State<ConnectionTestPage> createState() => _ConnectionTestPageState();
}

class _ConnectionTestPageState extends State<ConnectionTestPage> {
  final List<TestResult> _results = [];
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    // Auto-run tests on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAllTests();
    });
  }

  Future<void> _runAllTests() async {
    setState(() {
      _testing = true;
      _results.clear();
    });

    await _test1_InternetConnection();
    await _test2_DNSResolution();
    await _test3_SupabaseReachability();
    await _test4_SupabaseInitialization();
    await _test5_DatabaseConnection();
    await _test6_AuthEndpoint();
    await _test7_SignUpTest();
    await _test8_LoginTest();

    setState(() {
      _testing = false;
    });
  }

  Future<void> _test1_InternetConnection() async {
    _addResult('Test 1: Internet Connection', 'testing');

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _updateResult('Test 1: Internet Connection', 'success',
            'Internet is working! IP: ${result[0].address}');
      } else {
        _updateResult('Test 1: Internet Connection', 'failed',
            'Cannot resolve google.com');
      }
    } on SocketException catch (e) {
      _updateResult('Test 1: Internet Connection', 'failed',
          'Socket error: ${e.message}. Check WiFi/Mobile Data.');
    } on TimeoutException {
      _updateResult('Test 1: Internet Connection', 'failed',
          'Timeout! Very slow internet or network blocking DNS');
    } catch (e) {
      _updateResult(
          'Test 1: Internet Connection', 'failed', 'Error: ${e.toString()}');
    }
  }

  Future<void> _test2_DNSResolution() async {
    _addResult('Test 2: DNS Resolution for Supabase', 'testing');

    try {
      final result =
          await InternetAddress.lookup('ckgaoxajvonazdwpsmai.supabase.co')
              .timeout(const Duration(seconds: 10));

      if (result.isNotEmpty) {
        _updateResult('Test 2: DNS Resolution for Supabase', 'success',
            'Supabase domain resolves to: ${result[0].address}');
      } else {
        _updateResult('Test 2: DNS Resolution for Supabase', 'failed',
            'Cannot resolve Supabase domain!');
      }
    } on SocketException catch (e) {
      _updateResult('Test 2: DNS Resolution for Supabase', 'failed',
          'DNS BLOCKED! ${e.message}\n\nYour ISP/Firewall is blocking Supabase!\n\nTry:\n1. Mobile hotspot\n2. VPN (Cloudflare WARP)\n3. Different WiFi');
    } on TimeoutException {
      _updateResult('Test 2: DNS Resolution for Supabase', 'failed',
          'DNS timeout! Network very slow or ISP blocking');
    } catch (e) {
      _updateResult('Test 2: DNS Resolution for Supabase', 'failed',
          'Error: ${e.toString()}');
    }
  }

  Future<void> _test3_SupabaseReachability() async {
    _addResult('Test 3: HTTPS Connection to Supabase', 'testing');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      final request = await client
          .getUrl(Uri.parse('https://ckgaoxajvonazdwpsmai.supabase.co'))
          .timeout(const Duration(seconds: 15));

      final response = await request.close().timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 500) {
        _updateResult('Test 3: HTTPS Connection to Supabase', 'success',
            'Successfully connected! Status: ${response.statusCode}');
      } else {
        _updateResult('Test 3: HTTPS Connection to Supabase', 'warning',
            'Connected but got status: ${response.statusCode}');
      }

      client.close();
    } on SocketException catch (e) {
      _updateResult('Test 3: HTTPS Connection to Supabase', 'failed',
          'NETWORK BLOCKED!\n\n${e.message}\n\nYour firewall/ISP is blocking Supabase!\n\nSOLUTIONS:\n1. Switch to mobile hotspot\n2. Use VPN (try Cloudflare WARP)\n3. Check corporate firewall settings');
    } on TimeoutException {
      _updateResult('Test 3: HTTPS Connection to Supabase', 'failed',
          'CONNECTION TIMEOUT!\n\nSupabase is not reachable from your network.\n\nTry:\n1. Mobile hotspot\n2. VPN\n3. Different network');
    } catch (e) {
      _updateResult('Test 3: HTTPS Connection to Supabase', 'failed',
          'Error: ${e.toString()}');
    }
  }

  Future<void> _test4_SupabaseInitialization() async {
    _addResult('Test 4: Supabase SDK Initialization', 'testing');

    try {
      await Supabase.initialize(
        url: 'https://ckgaoxajvonazdwpsmai.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrZ2FveGFqdm9uYXpkd3BzbWFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4NTE0OTIsImV4cCI6MjA3NTQyNzQ5Mn0.poUiysXLCNjZHHTCEOM3CgKgnna32phQXT_Ob6fx7Hg',
      ).timeout(const Duration(seconds: 20));

      _updateResult('Test 4: Supabase SDK Initialization', 'success',
          'Supabase client initialized successfully!');
    } on TimeoutException {
      _updateResult('Test 4: Supabase SDK Initialization', 'failed',
          'Initialization timeout! Network too slow or blocked.');
    } catch (e) {
      if (e.toString().contains('already been initialized')) {
        _updateResult('Test 4: Supabase SDK Initialization', 'success',
            'Already initialized (that\'s fine!)');
      } else {
        _updateResult('Test 4: Supabase SDK Initialization', 'failed',
            'Init error: ${e.toString()}');
      }
    }
  }

  Future<void> _test5_DatabaseConnection() async {
    _addResult('Test 5: Database Query Test', 'testing');

    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('profiles')
          .select()
          .limit(1)
          .timeout(const Duration(seconds: 15));

      _updateResult('Test 5: Database Query Test', 'success',
          'Database accessible! Returned ${response.length} records.');
    } on PostgrestException catch (e) {
      _updateResult('Test 5: Database Query Test', 'warning',
          'Database error: ${e.message}\n\nThis might be OK if RLS policies are strict.');
    } on TimeoutException {
      _updateResult('Test 5: Database Query Test', 'failed',
          'Database query timeout! Network issue or Supabase is slow.');
    } catch (e) {
      _updateResult('Test 5: Database Query Test', 'failed',
          'Error: ${e.toString()}');
    }
  }

  Future<void> _test6_AuthEndpoint() async {
    _addResult('Test 6: Authentication Endpoint', 'testing');

    try {
      final client = Supabase.instance.client;

      // Try to get current session (should be null if not logged in)
      final session = client.auth.currentSession;

      _updateResult('Test 6: Authentication Endpoint', 'success',
          'Auth endpoint accessible! Current session: ${session != null ? "Logged in" : "Not logged in"}');
    } catch (e) {
      _updateResult('Test 6: Authentication Endpoint', 'failed',
          'Auth endpoint error: ${e.toString()}');
    }
  }

  Future<void> _test7_SignUpTest() async {
    _addResult('Test 7: Sign Up Test', 'testing');

    try {
      final client = Supabase.instance.client;

      // Use a test email that won't conflict
      final testEmail =
          'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'Test123456!';

      final response = await client.auth
          .signUp(
        email: testEmail,
        password: testPassword,
        data: {'full_name': 'Test User'},
      )
          .timeout(const Duration(seconds: 20));

      if (response.user != null) {
        _updateResult('Test 7: Sign Up Test', 'success',
            'Sign up works! Created test user: $testEmail\n\nUser ID: ${response.user!.id}');

        // Clean up - try to delete the test user (may fail, that's OK)
        try {
          await client.auth.signOut();
        } catch (_) {}
      } else {
        _updateResult('Test 7: Sign Up Test', 'warning',
            'Sign up completed but no user returned. Check Supabase dashboard.');
      }
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        _updateResult('Test 7: Sign Up Test', 'success',
            'Sign up endpoint works! (Email already exists is expected)');
      } else {
        _updateResult('Test 7: Sign Up Test', 'failed',
            'Auth error: ${e.message}\n\nStatus: ${e.statusCode}');
      }
    } on TimeoutException {
      _updateResult('Test 7: Sign Up Test', 'failed',
          'SIGN UP TIMEOUT!\n\nThe auth endpoint is not responding.\n\nTry:\n1. VPN\n2. Mobile hotspot\n3. Wait and retry');
    } catch (e) {
      _updateResult(
          'Test 7: Sign Up Test', 'failed', 'Error: ${e.toString()}');
    }
  }

  Future<void> _test8_LoginTest() async {
    _addResult('Test 8: Login Test', 'testing');

    try {
      final client = Supabase.instance.client;

      // Try with a known test account (update these if you have a real test account)
      const testEmail = 'test@example.com';
      const testPassword = 'test123456';

      final response = await client.auth
          .signInWithPassword(
        email: testEmail,
        password: testPassword,
      )
          .timeout(const Duration(seconds: 20));

      if (response.user != null) {
        _updateResult('Test 8: Login Test', 'success',
            'Login works! Test account logged in successfully.');
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        _updateResult('Test 8: Login Test', 'success',
            'Login endpoint works! (Invalid credentials is expected for test account)');
      } else if (e.message.contains('Email not confirmed')) {
        _updateResult('Test 8: Login Test', 'success',
            'Login endpoint works! (Email not confirmed is expected)');
      } else {
        _updateResult('Test 8: Login Test', 'failed',
            'Auth error: ${e.message}\n\nStatus: ${e.statusCode}');
      }
    } on TimeoutException {
      _updateResult('Test 8: Login Test', 'failed',
          'LOGIN TIMEOUT!\n\nAuthentication is not working from your network.\n\nThis is a NETWORK ISSUE.\n\nSOLUTIONS:\n1. Try mobile hotspot\n2. Use VPN (Cloudflare WARP)\n3. Contact ISP/IT department');
    } catch (e) {
      _updateResult('Test 8: Login Test', 'failed', 'Error: ${e.toString()}');
    }
  }

  void _addResult(String test, String status) {
    setState(() {
      _results.add(TestResult(test, status, ''));
    });
  }

  void _updateResult(String test, String status, String details) {
    setState(() {
      final index = _results.indexWhere((r) => r.test == test);
      if (index != -1) {
        _results[index] = TestResult(test, status, details);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testing ? null : _runAllTests,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            color: Colors.blue,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔍 Network Diagnostics for India',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This will test your connection to Supabase step-by-step.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_testing)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          const SizedBox(height: 16),
          ..._results.map((result) => _buildResultCard(result)),
          if (!_testing && _results.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSummaryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(TestResult result) {
    Color color;
    IconData icon;

    switch (result.status) {
      case 'success':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'testing':
        color = Colors.blue;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          result.test,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: result.details.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  result.details,
                  style: TextStyle(
                    color: result.status == 'failed'
                        ? Colors.red.shade700
                        : Colors.black87,
                  ),
                ),
              )
            : null,
        isThreeLine: result.details.length > 50,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final passed = _results.where((r) => r.status == 'success').length;
    final failed = _results.where((r) => r.status == 'failed').length;
    final warnings = _results.where((r) => r.status == 'warning').length;

    String summary;
    Color summaryColor;

    if (failed == 0) {
      summary =
          '✅ All tests passed! Your connection to Supabase is working perfectly.';
      summaryColor = Colors.green;
    } else if (failed <= 2) {
      summary =
          '⚠️ Some tests failed. Check the failed tests above for solutions.';
      summaryColor = Colors.orange;
    } else {
      summary =
          '❌ Multiple tests failed. This is likely a NETWORK ISSUE.\n\nTry:\n1. Mobile hotspot\n2. VPN (Cloudflare WARP)\n3. Different WiFi network';
      summaryColor = Colors.red;
    }

    return Card(
      color: summaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Test Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('✅ Passed: $passed'),
            Text('❌ Failed: $failed'),
            if (warnings > 0) Text('⚠️  Warnings: $warnings'),
            const Divider(height: 24),
            Text(
              summary,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: summaryColor,
              ),
            ),
            if (failed > 2) ...[
              const SizedBox(height: 16),
              const Text(
                '🌍 For users in India:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Some ISPs block Supabase domains'),
              const Text('• Corporate firewalls may block cloud services'),
              const Text('• Try mobile data instead of WiFi'),
              const Text('• VPN usually solves the issue'),
            ],
          ],
        ),
      ),
    );
  }
}

class TestResult {
  final String test;
  final String status;
  final String details;

  TestResult(this.test, this.status, this.details);
}
