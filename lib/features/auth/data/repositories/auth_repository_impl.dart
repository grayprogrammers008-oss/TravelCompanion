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
        debugPrint('🚀 Signing up with Supabase (online-only mode)');
        debugPrint('   Email: $email');
      }

      final userModel = await _remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (kDebugMode) {
        debugPrint('✅ Signup successful!');
        debugPrint('   User ID: ${userModel.id}');
      }

      return userModel.toEntity();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Signup failed: $e');
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
        debugPrint('🔐 Signing in with Supabase');
        debugPrint('   Email: $email');
      }

      final userModel = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('✅ Sign in successful!');
      }

      return userModel.toEntity();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign in failed: $e');
      }
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        debugPrint('👋 Signing out from Supabase');
      }

      await _remoteDataSource.signOut();

      if (kDebugMode) {
        debugPrint('✅ Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign out failed: $e');
      }
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();

      if (userModel != null && kDebugMode) {
        debugPrint('👤 Current user: ${userModel.email}');
      }

      return userModel?.toEntity();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Get current user failed: $e');
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
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      if (kDebugMode) {
        debugPrint('📝 Updating profile in Supabase');
        debugPrint('   User ID: ${currentUser.id}');
      }

      final userModel = await _remoteDataSource.updateProfile(
        userId: currentUser.id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
      );

      if (kDebugMode) {
        debugPrint('✅ Profile update successful');
      }

      return userModel.toEntity();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Profile update failed: $e');
      }
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        debugPrint('📧 Sending password reset email');
        debugPrint('   Email: $email');
      }

      await _remoteDataSource.resetPassword(email);

      if (kDebugMode) {
        debugPrint('✅ Password reset email sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Password reset failed: $e');
      }
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  bool get isAuthenticated {
    return _remoteDataSource.isAuthenticated;
  }
}
