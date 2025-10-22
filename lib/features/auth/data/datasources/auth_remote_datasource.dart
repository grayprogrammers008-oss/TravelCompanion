import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/user_model.dart';

/// Remote data source for authentication using Supabase
class AuthRemoteDataSource {
  final SupabaseClient _client = SupabaseClientWrapper.client;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
        },
      );

      if (response.user == null) {
        throw Exception('Sign up failed: No user returned');
      }

      // Wait a moment for the trigger to create profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch user profile from profiles table
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
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
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed: No user returned');
      }

      // Fetch user profile
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(profileData);
    } on AuthException catch (e) {
      // Provide detailed error messages for common issues
      String errorMessage = e.message;

      if (e.message.contains('Invalid login credentials')) {
        errorMessage = '''
Invalid email or password. Possible reasons:
• Email not confirmed (check your inbox)
• Wrong password
• Account doesn't exist (try Sign Up)
• Account disabled

Original error: ${e.message}''';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = '''
Email not confirmed!
• Check your email inbox for confirmation link
• Check spam folder
• Contact admin to manually confirm your account

Original error: ${e.message}''';
      } else if (e.statusCode == 'NETWORK_ERROR') {
        errorMessage = '''
Network connection failed!
• Check your internet connection
• Try using mobile hotspot
• VPN might be blocking Supabase
• Firewall might be blocking access

Original error: ${e.message}''';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(profileData);
    } catch (e) {
      return null;
    }
  }

  /// Get auth state changes stream
  Stream<User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      final profileData = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(profileData);
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Change password for current user
  ///
  /// This method properly verifies the current password by re-authenticating
  /// the user before updating their password. This ensures security.
  ///
  /// Throws [Exception] if:
  /// - No user is logged in
  /// - Current password is incorrect
  /// - Password update fails
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    print('🔐 [ChangePassword] Starting password change process...');

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('❌ [ChangePassword] Error: No user logged in');
        throw Exception('No user logged in');
      }

      // Get user's email for re-authentication
      final email = user.email;
      if (email == null) {
        print('❌ [ChangePassword] Error: User email not found');
        throw Exception('User email not found');
      }

      print('🔐 [ChangePassword] User: $email');
      print('🔐 [ChangePassword] Step 1: Verifying current password via re-authentication...');

      // Step 1: Verify current password by attempting to re-authenticate
      try {
        final verificationResponse = await _client.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );

        if (verificationResponse.user == null) {
          print('❌ [ChangePassword] Re-authentication returned null user');
          throw Exception('Current password is incorrect');
        }

        print('✅ [ChangePassword] Step 1 SUCCESS: Current password verified');
      } on AuthException catch (e) {
        print('❌ [ChangePassword] Re-authentication failed: ${e.message}');

        // Re-authentication failed - current password is incorrect
        if (e.message.toLowerCase().contains('invalid') ||
            e.message.toLowerCase().contains('credentials') ||
            e.message.toLowerCase().contains('password')) {
          print('❌ [ChangePassword] Current password is INCORRECT');
          throw Exception('Current password is incorrect');
        }
        throw Exception('Password verification failed: ${e.message}');
      } catch (e) {
        // For any other error during verification, treat as incorrect password
        print('❌ [ChangePassword] Unexpected error during verification: $e');
        throw Exception('Current password is incorrect');
      }

      print('🔐 [ChangePassword] Step 2: Updating to new password...');

      // Step 2: Current password verified, now update to new password
      final response = await _client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (response.user == null) {
        print('❌ [ChangePassword] Password update returned null user');
        throw Exception('Password update failed');
      }

      print('✅ [ChangePassword] Step 2 SUCCESS: Password updated successfully');
      print('✅ [ChangePassword] Password change complete!');
    } on AuthException catch (e) {
      print('❌ [ChangePassword] AuthException: ${e.message}');
      throw Exception('Password change failed: ${e.message}');
    } catch (e) {
      // Re-throw our custom exceptions as-is
      if (e.toString().contains('Current password is incorrect')) {
        print('❌ [ChangePassword] Final error: Current password incorrect');
        rethrow;
      }
      print('❌ [ChangePassword] Unexpected error: $e');
      throw Exception('Password change failed: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;
}
