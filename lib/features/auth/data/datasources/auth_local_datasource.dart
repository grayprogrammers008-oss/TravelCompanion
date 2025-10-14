import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../../core/database/database_helper.dart';
import '../models/user_model.dart';

/// Local data source for authentication using SQLite
/// This replaces Supabase auth during local development
class AuthLocalDataSource {
  // Singleton pattern to preserve state
  static final AuthLocalDataSource _instance = AuthLocalDataSource._internal();
  factory AuthLocalDataSource() => _instance;
  AuthLocalDataSource._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // Store current user ID in memory
  String? _currentUserId;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Check if email already exists
      final existingUsers = await db.query(
        'profiles',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (existingUsers.isNotEmpty) {
        throw Exception('Email already exists');
      }

      // Create user ID
      final userId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      // Insert user profile
      await db.insert('profiles', {
        'id': userId,
        'email': email.toLowerCase(),
        'full_name': fullName,
        'phone_number': phoneNumber,
        'avatar_url': null,
        'created_at': now,
        'updated_at': now,
      });

      // Store password hash
      final passwordHash = _hashPassword(password);
      await db.insert('auth_sessions', {
        'id': _uuid.v4(),
        'user_id': userId,
        'password_hash': passwordHash,
        'created_at': now,
      });

      // Set as current user
      _currentUserId = userId;

      // Return user model
      return UserModel(
        id: userId,
        email: email.toLowerCase(),
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: null,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Find user by email
      final users = await db.query(
        'profiles',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (users.isEmpty) {
        throw Exception('Invalid email or password');
      }

      final userData = users.first;
      final userId = userData['id'] as String;

      // Verify password
      final sessions = await db.query(
        'auth_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (sessions.isEmpty) {
        throw Exception('Invalid email or password');
      }

      final storedHash = sessions.first['password_hash'] as String;
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        throw Exception('Invalid email or password');
      }

      // Set as current user
      _currentUserId = userId;

      // Return user model
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUserId = null;
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    if (_currentUserId == null) return null;

    try {
      final db = await _dbHelper.database;
      final users = await db.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [_currentUserId],
      );

      if (users.isEmpty) {
        _currentUserId = null;
        return null;
      }

      return UserModel.fromJson(users.first);
    } catch (e) {
      return null;
    }
  }

  /// Get auth state changes stream
  /// Note: SQLite doesn't support real-time streams like Supabase
  /// This is a simplified version that emits current user state
  Stream<String?> get authStateChanges {
    return Stream.periodic(
      const Duration(seconds: 1),
      (_) => _currentUserId,
    ).distinct();
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    try {
      final db = await _dbHelper.database;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await db.update(
        'profiles',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );

      final users = await db.query(
        'profiles',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        throw Exception('User not found');
      }

      return UserModel.fromJson(users.first);
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    // For local development, we'll just simulate success
    // In a real app, this would send an email
    await Future.delayed(const Duration(milliseconds: 500));
    // In local mode, we just acknowledge the request
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Hash password using SHA-256
  /// Note: In production, use bcrypt or similar secure hashing
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// For testing: Clear current session
  void clearSession() {
    _currentUserId = null;
  }
}
