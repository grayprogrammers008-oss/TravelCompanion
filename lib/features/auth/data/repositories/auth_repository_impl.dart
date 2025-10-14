// SUPABASE DISABLED - Using SQLite for local development
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

/// Implementation of authentication repository
class AuthRepositoryImpl implements AuthRepository {
  // Using local datasource instead of remote
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._localDataSource);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    final userModel = await _localDataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final userModel = await _localDataSource.signIn(
      email: email,
      password: password,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> signOut() async {
    await _localDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userModel = await _localDataSource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  Stream<String?> get authStateChanges => _localDataSource.authStateChanges;

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

    final userModel = await _localDataSource.updateProfile(
      userId: currentUser.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
    return userModel.toEntity();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _localDataSource.resetPassword(email);
  }

  @override
  bool get isAuthenticated => _localDataSource.isAuthenticated;
}
