import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

/// Password Reset Page
///
/// This page is accessed via deep link when user clicks the reset password link
/// in their email. It allows them to set a new password.
///
/// With PKCE flow, Supabase handles authentication automatically when user
/// clicks the reset link. The user is already authenticated when they reach
/// this page, so we just need to update their password.
class ResetPasswordPage extends ConsumerStatefulWidget {
  /// Access token from the reset password link (may be null with PKCE flow)
  final String? accessToken;

  const ResetPasswordPage({
    super.key,
    this.accessToken,
  });

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  bool _isCheckingSession = true;
  bool _hasValidSession = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Check if user has a valid session (PKCE flow auto-authenticates)
  Future<void> _checkSession() async {
    debugPrint('🔐 [ResetPassword] Checking session...');
    debugPrint('   Access token from URL: ${widget.accessToken ?? "null"}');

    // Give Supabase a moment to process the deep link and set the session
    await Future.delayed(const Duration(milliseconds: 500));

    final session = ref.read(supabaseClientProvider).auth.currentSession;
    final user = ref.read(supabaseClientProvider).auth.currentUser;

    debugPrint('   Session: ${session != null ? "exists" : "null"}');
    debugPrint('   User: ${user?.email ?? "null"}');

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
        _hasValidSession = session != null && user != null;
      });

      if (!_hasValidSession && widget.accessToken == null) {
        setState(() {
          _errorMessage = 'Invalid or expired reset link. Please request a new password reset email.';
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔐 [ResetPassword] Updating password...');

      if (_hasValidSession) {
        // User is authenticated via PKCE flow - just update password
        debugPrint('   Using direct password update (user authenticated via PKCE)');
        await ref.read(authControllerProvider.notifier).updatePassword(
              newPassword: _passwordController.text.trim(),
            );
      } else if (widget.accessToken != null && widget.accessToken!.isNotEmpty) {
        // Fall back to OTP verification method
        debugPrint('   Using OTP verification method');
        await ref.read(authControllerProvider.notifier).verifyOtpAndUpdatePassword(
              token: widget.accessToken!,
              newPassword: _passwordController.text.trim(),
            );
      } else {
        throw Exception('No valid session or token. Please request a new reset link.');
      }

      debugPrint('✅ [ResetPassword] Password updated successfully!');

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      // Sign out to force re-login with new password
      await ref.read(supabaseClientProvider).auth.signOut();

      // Show success message and navigate to login after delay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please login with your new password.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Wait a moment then navigate to login
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      debugPrint('❌ [ResetPassword] Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isCheckingSession
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppTheme.spacingLg),
                    Text('Verifying reset link...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing2xl),
                child: _isSuccess ? _buildSuccessView() : _buildResetForm(),
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppTheme.spacing3xl * 2),
        const Icon(
          Icons.check_circle,
          size: 100,
          color: Colors.green,
        ),
        const SizedBox(height: AppTheme.spacing2xl),
        const Text(
          'Password Reset Successful!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        const Text(
          'Your password has been updated successfully.\n\nRedirecting to login...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: AppTheme.spacing2xl),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          // Icon
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Title
          const Text(
            'Create New Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Description
          const Text(
            'Please enter your new password below.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // New Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter your new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            validator: Validators.password,
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Reset Password button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Back to login
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    context.go('/');
                  },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}
