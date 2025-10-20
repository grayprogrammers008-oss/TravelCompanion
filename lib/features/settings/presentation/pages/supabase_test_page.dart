import 'package:flutter/material.dart';
import '../../../../test_supabase_connectivity.dart';

/// Supabase Connectivity Test Page
///
/// Add this to your settings or debug menu to test Supabase connection
///
/// Usage:
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const SupabaseTestPage()),
/// );
class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;

  @override
  void initState() {
    super.initState();
    // Auto-run test on page load
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      final results = await testSupabaseConnectivity();

      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'overall_success': false,
          'errors': ['Unexpected error: $e'],
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connectivity Test'),
        backgroundColor: const Color(0xFF00B8A9),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00B8A9),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Testing Supabase connectivity...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          : _buildResults(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _runTest,
        backgroundColor: const Color(0xFF00B8A9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh),
        label: const Text('Run Test Again'),
      ),
    );
  }

  Widget _buildResults() {
    if (_testResults == null) {
      return const Center(
        child: Text('No test results yet'),
      );
    }

    final overallSuccess = _testResults!['overall_success'] as bool? ?? false;
    final tests = _testResults!['tests'] as Map<String, dynamic>? ?? {};
    final errors = _testResults!['errors'] as List? ?? [];
    final warnings = _testResults!['warnings'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Status Card
          Card(
            color: overallSuccess ? Colors.green[50] : Colors.red[50],
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: overallSuccess ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    overallSuccess ? Icons.check_circle : Icons.error,
                    color: overallSuccess ? Colors.green : Colors.red,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overallSuccess ? 'CONNECTION SUCCESS' : 'CONNECTION ISSUES',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: overallSuccess ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          overallSuccess
                              ? 'Supabase is connected and working!'
                              : 'Supabase connection has problems',
                          style: TextStyle(
                            fontSize: 14,
                            color: overallSuccess ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Test Results
          Text(
            'Test Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          const SizedBox(height: 12),

          ...tests.entries.map((entry) {
            final testName = _formatTestName(entry.key);
            final passed = entry.value as bool;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  color: passed ? Colors.green : Colors.red,
                ),
                title: Text(testName),
                subtitle: Text(passed ? 'Passed' : 'Failed'),
              ),
            );
          }),

          // Errors
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Errors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 12),
            ...errors.map((error) {
              return Card(
                color: Colors.red[50],
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(
                    error.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }),
          ],

          // Warnings
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Warnings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 12),
            ...warnings.map((warning) {
              return Card(
                color: Colors.orange[50],
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(
                    warning.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }),
          ],

          // Current User Info
          if (_testResults!['current_user'] != null) ...[
            const SizedBox(height: 24),
            Text(
              'Current User',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'User ID',
                      _testResults!['current_user']['id'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Email',
                      _testResults!['current_user']['email'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Email Confirmed',
                      _testResults!['current_user']['email_confirmed'].toString(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Additional Info
          if (_testResults!['profile_count'] != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people, color: Color(0xFF00B8A9)),
                title: const Text('Profiles in Database'),
                trailing: Text(
                  _testResults!['profile_count'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B8A9),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Recommendations
          _buildRecommendations(overallSuccess, tests, errors),

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(
    bool overallSuccess,
    Map<String, dynamic> tests,
    List errors,
  ) {
    return Card(
      color: const Color(0xFFF1F5F9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (overallSuccess) ...[
              const Text('✅ Supabase is working correctly!'),
              const SizedBox(height: 8),
              if (tests['database_access'] == false) ...[
                const Text(
                  '⚠️ Deploy database schema from SUPABASE_SCHEMA.sql',
                  style: TextStyle(color: Color(0xFFFF8A65)),
                ),
              ],
              const SizedBox(height: 8),
              const Text('💡 You can now signup and use the app!'),
            ] else ...[
              const Text(
                '❌ Fix the errors listed above before using the app',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              const Text('Common fixes:'),
              const SizedBox(height: 4),
              const Text('• Check internet connection'),
              const Text('• Verify Supabase credentials'),
              const Text('• Ensure Supabase project is active'),
              const Text('• Deploy database schema'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTestName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
