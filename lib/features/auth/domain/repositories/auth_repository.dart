// SUPABASE DISABLED - Using SQLite for local development
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_entity.dart';

/// Abstract authentication repository
/// Defines the contract for authentication operations
abstract class AuthRepository {
  /// Sign up with email and password
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  /// Sign in with email and password
  Future<UserEntity> signIn({required String email, required String password});

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();

  /// Stream of authentication state changes
  /// Returns userId for SQLite, User for Supabase
  Stream<String?> get authStateChanges;

  /// Update user profile
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  });

  /// Reset password via email
  Future<void> resetPassword(String email);

  /// Change password for current user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Update password (used after reset password link)
  Future<void> updatePassword({required String newPassword});

  /// Verify OTP token and update password (password reset flow)
  Future<void> verifyOtpAndUpdatePassword({
    required String token,
    required String newPassword,
  });

  /// Check if user is authenticated
  bool get isAuthenticated;
}
