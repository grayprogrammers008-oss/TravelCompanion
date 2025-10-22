import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of authentication repository - Supabase only
///
/// This repository uses only Supabase for all authentication operations.
/// SQLite support has been completely removed for online-only mode.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      if (kDebugMode) {
        print('🚀 Signing up with Supabase (online-only mode)');
        print('   Email: $email');
      }

      final userModel = await _remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (kDebugMode) {
        print('✅ Signup successful!');
        print('   User ID: ${userModel.id}');
      }

      return userModel.toEntity();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Signup failed: $e');
      }
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 Signing in with Supabase');
        print('   Email: $email');
      }

      final userModel = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print('✅ Sign in successful!');
      }

      return userModel.toEntity();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign in failed: $e');
      }
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('👋 Signing out from Supabase');
      }

      await _remoteDataSource.signOut();

      if (kDebugMode) {
        print('✅ Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out failed: $e');
      }
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();

      if (userModel != null && kDebugMode) {
        print('👤 Current user: ${userModel.email}');
      }

      return userModel?.toEntity();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get current user failed: $e');
      }
      return null;
    }
  }

  @override
  Stream<String?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((user) => user?.id);
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      if (kDebugMode) {
        print('📝 Updating profile in Supabase');
        print('   User ID: ${currentUser.id}');
      }

      final userModel = await _remoteDataSource.updateProfile(
        userId: currentUser.id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
      );

      if (kDebugMode) {
        print('✅ Profile update successful');
      }

      return userModel.toEntity();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Profile update failed: $e');
      }
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('📧 Sending password reset email');
        print('   Email: $email');
      }

      await _remoteDataSource.resetPassword(email);

      if (kDebugMode) {
        print('✅ Password reset email sent');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Password reset failed: $e');
      }
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 Changing password');
      }

      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (kDebugMode) {
        print('✅ Password changed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Password change failed: $e');
      }
      rethrow; // Re-throw to preserve the original error message
    }
  }

  @override
  bool get isAuthenticated {
    return _remoteDataSource.isAuthenticated;
  }
}
