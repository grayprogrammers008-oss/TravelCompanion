import 'package:flutter/foundation.dart';
import '../../../../core/config/data_source_config.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

/// Implementation of authentication repository with hybrid Supabase/SQLite support
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      // Use Supabase if configured as primary
      if (DataSourceConfig.useSupabase) {
        try {
          final userModel = await _remoteDataSource.signUp(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
          );

          // Sync to SQLite if enabled
          if (DataSourceConfig.enableSync) {
            try {
              await _localDataSource.signUp(
                email: email,
                password: password,
                fullName: fullName,
                phoneNumber: phoneNumber,
              );
            } catch (e) {
              if (kDebugMode) print('⚠️  Failed to sync to SQLite: $e');
            }
          }

          return userModel.toEntity();
        } catch (e) {
          if (kDebugMode) print('❌ Supabase signup failed: $e');

          // Fallback to SQLite if enabled
          if (DataSourceConfig.enableFallback) {
            if (kDebugMode) print('⚠️  Using SQLite fallback');
            final userModel = await _localDataSource.signUp(
              email: email,
              password: password,
              fullName: fullName,
              phoneNumber: phoneNumber,
            );
            return userModel.toEntity();
          }
          rethrow;
        }
      } else {
        // Use SQLite as primary
        final userModel = await _localDataSource.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phoneNumber: phoneNumber,
        );
        return userModel.toEntity();
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Use Supabase if configured as primary
      if (DataSourceConfig.useSupabase) {
        try {
          final userModel = await _remoteDataSource.signIn(
            email: email,
            password: password,
          );
          return userModel.toEntity();
        } catch (e) {
          if (kDebugMode) print('❌ Supabase signin failed: $e');

          // Fallback to SQLite if enabled
          if (DataSourceConfig.enableFallback) {
            if (kDebugMode) print('⚠️  Using SQLite fallback');
            final userModel = await _localDataSource.signIn(
              email: email,
              password: password,
            );
            return userModel.toEntity();
          }
          rethrow;
        }
      } else {
        // Use SQLite as primary
        final userModel = await _localDataSource.signIn(
          email: email,
          password: password,
        );
        return userModel.toEntity();
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from both if using Supabase
      if (DataSourceConfig.useSupabase) {
        try {
          await _remoteDataSource.signOut();

          // Also sign out from SQLite
          if (DataSourceConfig.enableSync) {
            await _localDataSource.signOut();
          }
        } catch (e) {
          if (kDebugMode) print('❌ Supabase signout failed: $e');

          // Fallback to SQLite
          if (DataSourceConfig.enableFallback) {
            await _localDataSource.signOut();
          }
        }
      } else {
        await _localDataSource.signOut();
      }
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      // Use Supabase if configured as primary
      if (DataSourceConfig.useSupabase) {
        try {
          final userModel = await _remoteDataSource.getCurrentUser();
          return userModel?.toEntity();
        } catch (e) {
          if (kDebugMode) print('❌ Supabase get user failed: $e');

          // Fallback to SQLite if enabled
          if (DataSourceConfig.enableFallback) {
            final userModel = await _localDataSource.getCurrentUser();
            return userModel?.toEntity();
          }
          return null;
        }
      } else {
        final userModel = await _localDataSource.getCurrentUser();
        return userModel?.toEntity();
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<String?> get authStateChanges {
    // Use Supabase stream if configured
    if (DataSourceConfig.useSupabase) {
      return _remoteDataSource.authStateChanges.map((user) => user?.id);
    } else {
      return _localDataSource.authStateChanges;
    }
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
      // Use Supabase if configured as primary
      if (DataSourceConfig.useSupabase) {
        try {
          final userModel = await _remoteDataSource.updateProfile(
            userId: currentUser.id,
            fullName: fullName,
            phoneNumber: phoneNumber,
            avatarUrl: avatarUrl,
          );

          // Sync to SQLite if enabled
          if (DataSourceConfig.enableSync) {
            try {
              await _localDataSource.updateProfile(
                userId: currentUser.id,
                fullName: fullName,
                phoneNumber: phoneNumber,
                avatarUrl: avatarUrl,
              );
            } catch (e) {
              if (kDebugMode) print('⚠️  Failed to sync to SQLite: $e');
            }
          }

          return userModel.toEntity();
        } catch (e) {
          if (kDebugMode) print('❌ Supabase update failed: $e');

          // Fallback to SQLite if enabled
          if (DataSourceConfig.enableFallback) {
            if (kDebugMode) print('⚠️  Using SQLite fallback');
            final userModel = await _localDataSource.updateProfile(
              userId: currentUser.id,
              fullName: fullName,
              phoneNumber: phoneNumber,
              avatarUrl: avatarUrl,
            );
            return userModel.toEntity();
          }
          rethrow;
        }
      } else {
        final userModel = await _localDataSource.updateProfile(
          userId: currentUser.id,
          fullName: fullName,
          phoneNumber: phoneNumber,
          avatarUrl: avatarUrl,
        );
        return userModel.toEntity();
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      // Use Supabase if configured
      if (DataSourceConfig.useSupabase) {
        await _remoteDataSource.resetPassword(email);
      } else {
        await _localDataSource.resetPassword(email);
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  @override
  bool get isAuthenticated {
    if (DataSourceConfig.useSupabase) {
      return _remoteDataSource.isAuthenticated;
    } else {
      return _localDataSource.isAuthenticated;
    }
  }
}
