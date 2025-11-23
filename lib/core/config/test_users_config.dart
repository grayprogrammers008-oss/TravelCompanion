import 'dart:convert';
import 'package:flutter/services.dart';

// Test Users Configuration Loader
//
// This class loads test user configuration from assets/config/test_users.json
// The JSON file is committed to the repo with empty passwords.
// Each developer fills in their local copy with individual passwords for each user.

class TestUsersConfig {
  static Map<String, dynamic>? _config;
  static bool _isLoaded = false;

  /// Load configuration from JSON file
  static Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/config/test_users.json');
      _config = json.decode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
    } catch (e) {
      // If file doesn't exist or has errors, use defaults
      _config = {
        'enableTestUserDropdown': false,
        'testUsers': [
          {'name': 'Select Test User', 'email': '', 'password': ''},
        ],
      };
      _isLoaded = true;
    }
  }

  /// List of test users with individual passwords (loaded from JSON)
  static List<Map<String, String>> get testUsers {
    final users = _config?['testUsers'] as List? ?? [];
    return users.map((user) {
      return {
        'name': user['name'] as String? ?? '',
        'email': user['email'] as String? ?? '',
        'password': user['password'] as String? ?? '',
      };
    }).toList();
  }

  /// Enable/disable test user dropdown (loaded from JSON)
  static bool get enableTestUserDropdown {
    return _config?['enableTestUserDropdown'] as bool? ?? false;
  }
}
