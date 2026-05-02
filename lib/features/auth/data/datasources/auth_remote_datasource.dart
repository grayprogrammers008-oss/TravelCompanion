import 'package:flutter/foundation.dart';
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

      // Wait for the trigger to create profile with retry logic
      Map<String, dynamic>? profileData;
      int retryCount = 0;
      const maxRetries = 5;

      while (profileData == null && retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));

        try {
          profileData = await _client
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();
        } catch (e) {
          debugPrint('🔄 Retry $retryCount: Profile not ready yet - $e');
        }

        retryCount++;
      }

      // If trigger didn't create the profile, create it manually
      if (profileData == null) {
        debugPrint('⚠️ Trigger did not create profile, creating manually...');
        try {
          await _client.from('profiles').insert({
            'id': response.user!.id,
            'email': response.user!.email,
            'full_name': fullName,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          profileData = await _client
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();
        } catch (e) {
          debugPrint('❌ Manual profile creation failed: $e');
        }
      }

      if (profileData == null) {
        throw Exception('Sign up failed: Profile creation failed. Please try logging in.');
      }

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
          .maybeSingle();

      if (profileData == null) {
        throw Exception('Sign in failed: User profile not found. Please contact support.');
      }

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
          .maybeSingle();

      if (profileData == null) return null;

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
          .maybeSingle();

      if (profileData == null) {
        throw Exception('Update profile failed: Profile not found');
      }

      return UserModel.fromJson(profileData);
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      debugPrint('🔐 [ResetPassword] Starting password reset for: $email');

      // Use different redirect URLs for web and mobile
      String redirectUrl;
      if (kIsWeb) {
        // For web: Use HTTPS URL
        redirectUrl = 'https://travelcrew.app/auth/reset-password';
      } else {
        // For mobile: Use custom scheme
        redirectUrl = 'travelcrew://auth/reset-password';
      }

      debugPrint('🔐 [ResetPassword] Redirect URL: $redirectUrl');
      debugPrint('🔐 [ResetPassword] Sending reset email via Supabase...');

      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );

      debugPrint('✅ [ResetPassword] Reset email sent successfully!');
      debugPrint('   ℹ️  Check your inbox and spam folder');
      debugPrint('   ℹ️  Make sure Supabase has email templates configured');
    } on AuthException catch (e) {
      debugPrint('❌ [ResetPassword] AuthException: ${e.message}');
      debugPrint('   Status code: ${e.statusCode}');
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ [ResetPassword] Unexpected error: $e');
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

  /// Update password (used after reset password link)
  Future<void> updatePassword({required String newPassword}) async {
    try {
      print('🔐 [UpdatePassword] Updating password via reset link...');

      // User is already authenticated via the access token from the reset link
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        print('❌ [UpdatePassword] Update returned null user');
        throw Exception('Password update failed');
      }

      print('✅ [UpdatePassword] Password updated successfully');
    } on AuthException catch (e) {
      print('❌ [UpdatePassword] AuthException: ${e.message}');
      throw Exception('Password update failed: ${e.message}');
    } catch (e) {
      print('❌ [UpdatePassword] Unexpected error: $e');
      throw Exception('Password update failed: $e');
    }
  }

  /// Verify OTP token and update password (password reset flow)
  ///
  /// This method handles the complete password reset flow:
  /// 1. Verifies the OTP token from the email
  /// 2. Updates the user's password
  Future<void> verifyOtpAndUpdatePassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      print('🔐 [VerifyOTP] Starting password reset with OTP verification...');
      print('🔐 [VerifyOTP] Token: ${token.substring(0, 8)}...');

      // Step 1: Verify the OTP token (this will authenticate the user)
      final verifyResponse = await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
      );

      if (verifyResponse.user == null) {
        print('❌ [VerifyOTP] Token verification failed - no user returned');
        throw Exception('Invalid or expired reset link. Please request a new one.');
      }

      print('✅ [VerifyOTP] Step 1 SUCCESS: Token verified, user authenticated');
      print('🔐 [VerifyOTP] Step 2: Updating password...');

      // Step 2: Update the password (user is now authenticated)
      final updateResponse = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (updateResponse.user == null) {
        print('❌ [VerifyOTP] Password update failed - no user returned');
        throw Exception('Password update failed. Please try again.');
      }

      print('✅ [VerifyOTP] Step 2 SUCCESS: Password updated');
      print('✅ [VerifyOTP] Password reset complete!');
    } on AuthException catch (e) {
      print('❌ [VerifyOTP] AuthException: ${e.message}');

      // Provide user-friendly error messages
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('expired')) {
        throw Exception('Invalid or expired reset link. Please request a new password reset email.');
      } else if (e.message.toLowerCase().contains('weak')) {
        throw Exception('Password is too weak. Please use a stronger password.');
      }

      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      print('❌ [VerifyOTP] Unexpected error: $e');

      // Don't wrap our custom exceptions
      if (e.toString().contains('Invalid or expired')) {
        rethrow;
      }

      throw Exception('Password reset failed: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;
}
