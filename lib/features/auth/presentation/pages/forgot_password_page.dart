import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

/// Forgot Password Page with OTP verification
///
/// 3-step flow with Email or Phone option:
/// 1. Enter email OR phone number
/// 2. Enter OTP code received via email/SMS
/// 3. Set new password
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Track if navigation has been scheduled to prevent duplicate navigations
  bool _hasScheduledNavigation = false;

  // Reset method selection (email or phone)
  ResetMethod _selectedMethod = ResetMethod.email;

  // Store session from OTP verification to use in password update
  Session? _otpSession;

  // Password strength tracking
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    // Check if we're returning to this page with state preserved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resetState = ref.read(passwordResetProvider);
      if (resetState.isInFlow) {
        _selectedMethod = resetState.method;
        if (resetState.email != null && resetState.email!.isNotEmpty) {
          _emailController.text = resetState.email!;
        }
        if (resetState.phone != null && resetState.phone!.isNotEmpty) {
          _phoneController.text = resetState.phone!;
        }
      }
    });
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  double get _passwordStrength {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score / 5;
  }

  String get _passwordStrengthText {
    if (_passwordStrength <= 0.2) return 'Very Weak';
    if (_passwordStrength <= 0.4) return 'Weak';
    if (_passwordStrength <= 0.6) return 'Fair';
    if (_passwordStrength <= 0.8) return 'Strong';
    return 'Very Strong';
  }

  Color get _passwordStrengthColor {
    if (_passwordStrength <= 0.2) return Colors.red;
    if (_passwordStrength <= 0.4) return Colors.orange;
    if (_passwordStrength <= 0.6) return Colors.amber;
    if (_passwordStrength <= 0.8) return Colors.lightGreen;
    return Colors.green;
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Format phone number with country code
  String _formatPhoneNumber(String phone) {
    // Remove any spaces or special characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Add +91 if not present (India)
    if (!cleaned.startsWith('91') && cleaned.length == 10) {
      cleaned = '+91$cleaned';
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  /// Step 1: Send OTP to email or phone
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedMethod == ResetMethod.email) {
        // Send OTP via email
        final email = _emailController.text.trim();
        debugPrint('🔐 [ForgotPassword] Sending OTP to email: $email');

        await Supabase.instance.client.auth.resetPasswordForEmail(email);

        debugPrint('✅ [ForgotPassword] Email OTP sent successfully!');

        if (mounted) {
          setState(() => _isLoading = false);
          ref.read(passwordResetProvider.notifier).startFlowWithEmail(email);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Send OTP via phone (SMS)
        final phone = _formatPhoneNumber(_phoneController.text.trim());
        debugPrint('🔐 [ForgotPassword] Sending OTP to phone: $phone');

        // Use signInWithOtp for phone - this sends SMS OTP
        await Supabase.instance.client.auth.signInWithOtp(
          phone: phone,
        );

        debugPrint('✅ [ForgotPassword] SMS OTP sent successfully!');

        if (mounted) {
          setState(() => _isLoading = false);
          ref.read(passwordResetProvider.notifier).startFlowWithPhone(phone);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $phone'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPassword] AuthException: ${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = _getReadableError(e.message);
      });
    } catch (e) {
      debugPrint('❌ [ForgotPassword] Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  }

  /// Resend OTP without resetting the flow
  /// This keeps the user on the OTP step and just sends a new code
  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resetState = ref.read(passwordResetProvider);

      if (resetState.method == ResetMethod.email) {
        // Get email from provider state or controller
        final email = resetState.email ?? _emailController.text.trim();
        if (email.isEmpty) {
          throw Exception('Email not found. Please go back and enter your email.');
        }

        debugPrint('🔐 [ForgotPassword] Resending OTP to email: $email');
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
        debugPrint('✅ [ForgotPassword] Email OTP resent successfully!');

        if (mounted) {
          _otpController.clear();
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New OTP sent to $email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Phone OTP resend
        final phone = resetState.phone ?? _formatPhoneNumber(_phoneController.text.trim());
        if (phone.isEmpty) {
          throw Exception('Phone number not found. Please go back and enter your phone.');
        }

        debugPrint('🔐 [ForgotPassword] Resending OTP to phone: $phone');
        await Supabase.instance.client.auth.signInWithOtp(phone: phone);
        debugPrint('✅ [ForgotPassword] SMS OTP resent successfully!');

        if (mounted) {
          _otpController.clear();
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New OTP sent to $phone'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPassword] Resend OTP failed: ${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = _getReadableError(e.message);
      });
    } catch (e) {
      debugPrint('❌ [ForgotPassword] Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  /// Step 2: Verify OTP and move to password step
  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resetState = ref.read(passwordResetProvider);
      debugPrint('🔐 [ForgotPassword] Verifying OTP...');

      AuthResponse response;

      if (resetState.method == ResetMethod.email) {
        // Verify email OTP
        response = await Supabase.instance.client.auth.verifyOTP(
          email: resetState.email ?? _emailController.text.trim(),
          token: _otpController.text.trim(),
          type: OtpType.recovery,
        );
      } else {
        // Verify phone OTP
        response = await Supabase.instance.client.auth.verifyOTP(
          phone: resetState.phone ?? _formatPhoneNumber(_phoneController.text.trim()),
          token: _otpController.text.trim(),
          type: OtpType.sms,
        );
      }

      if (response.session != null) {
        debugPrint('✅ [ForgotPassword] OTP verified successfully!');
        debugPrint('   Session access token: ${response.session!.accessToken.substring(0, 20)}...');
        debugPrint('   Refresh token: ${response.session!.refreshToken?.substring(0, 20) ?? "null"}...');

        // Store the session tokens in PROVIDER (not local state) to survive widget rebuilds
        // This is critical because router rebuilds after auth state change will recreate this widget
        final accessToken = response.session!.accessToken;
        final refreshToken = response.session!.refreshToken ?? '';
        ref.read(passwordResetProvider.notifier).moveToPasswordStepWithSession(accessToken, refreshToken);
        debugPrint('   ✅ Session tokens saved to provider');

        // Also store locally as backup
        _otpSession = response.session;

        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified! Please set your new password.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Invalid OTP');
      }
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPassword] OTP verification failed: ${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = _getReadableError(e.message);
      });
    } catch (e) {
      debugPrint('❌ [ForgotPassword] Error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid or expired OTP. Please try again.';
      });
    }
  }

  /// Step 3: Update password
  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔐 [ForgotPassword] Updating password...');

      // Check if we have a current session from Supabase client
      var currentSession = Supabase.instance.client.auth.currentSession;
      final currentUser = Supabase.instance.client.auth.currentUser;
      debugPrint('   Current session: ${currentSession != null ? "exists" : "null"}');
      debugPrint('   Current user: ${currentUser?.email ?? "null"}');
      debugPrint('   Stored OTP session (local): ${_otpSession != null ? "exists" : "null"}');

      // Get session tokens from provider (survives widget rebuilds)
      final resetState = ref.read(passwordResetProvider);
      debugPrint('   Provider has session tokens: ${resetState.hasSessionTokens}');
      if (resetState.hasSessionTokens) {
        debugPrint('   Provider access token (first 20 chars): ${resetState.accessToken!.substring(0, 20)}...');
        debugPrint('   Provider refresh token: ${resetState.refreshToken?.substring(0, 20) ?? "null"}...');
      }

      // If we have a current session and user, we can proceed directly
      if (currentSession != null && currentUser != null) {
        debugPrint('   ✅ Using current active session');
      }
      // If no current session, try to restore from PROVIDER tokens first (more reliable)
      else if (resetState.accessToken != null && resetState.accessToken!.isNotEmpty) {
        debugPrint('   Restoring session from PROVIDER tokens...');

        // Try with refresh token first if available
        if (resetState.refreshToken != null && resetState.refreshToken!.isNotEmpty) {
          debugPrint('   Trying setSession with refresh token...');
          try {
            final response = await Supabase.instance.client.auth.setSession(resetState.refreshToken!);
            debugPrint('   Session restored from refresh token: ${response.session != null}');
            debugPrint('   User after restore: ${response.user?.email ?? "null"}');
            currentSession = response.session;
          } catch (restoreError) {
            debugPrint('   ❌ Failed to restore with refresh token: $restoreError');
          }
        }

        // If still no session, try recoverSession with access token
        if (currentSession == null) {
          debugPrint('   Trying recoverSession with access token...');
          try {
            final recoverResponse = await Supabase.instance.client.auth.recoverSession(resetState.accessToken!);
            debugPrint('   Recover session result: ${recoverResponse.session != null}');
            debugPrint('   User after recover: ${recoverResponse.user?.email ?? "null"}');
            currentSession = recoverResponse.session;
          } catch (recoverError) {
            debugPrint('   ❌ Recover session also failed: $recoverError');
          }
        }
      }
      // Fallback to local _otpSession if provider tokens didn't work
      else if (_otpSession != null) {
        debugPrint('   Restoring from local OTP session (fallback)...');
        debugPrint('   Access token (first 20 chars): ${_otpSession!.accessToken.substring(0, 20)}...');
        debugPrint('   Refresh token: ${_otpSession!.refreshToken?.substring(0, 20) ?? "null"}...');

        // setSession expects a refresh token to get a new session
        if (_otpSession!.refreshToken != null) {
          try {
            final response = await Supabase.instance.client.auth.setSession(_otpSession!.refreshToken!);
            debugPrint('   Session restored: ${response.session != null}');
            debugPrint('   User after restore: ${response.user?.email ?? "null"}');
            currentSession = response.session;
          } catch (restoreError) {
            debugPrint('   ❌ Failed to restore session: $restoreError');
            // Try alternative: recoverSession using the full access token
            debugPrint('   Trying alternative: recoverSession with access token...');
            try {
              final recoverResponse = await Supabase.instance.client.auth.recoverSession(_otpSession!.accessToken);
              debugPrint('   Recover session result: ${recoverResponse.session != null}');
              currentSession = recoverResponse.session;
            } catch (recoverError) {
              debugPrint('   ❌ Recover session also failed: $recoverError');
            }
          }
        } else {
          debugPrint('   ⚠️ No refresh token available');
        }
      }

      // Final check - do we have a valid session now?
      final finalSession = Supabase.instance.client.auth.currentSession;
      final finalUser = Supabase.instance.client.auth.currentUser;
      debugPrint('   Final session check: ${finalSession != null ? "exists" : "null"}');
      debugPrint('   Final user: ${finalUser?.email ?? "null"}');

      if (finalSession == null || finalUser == null) {
        throw Exception('Session expired. Please start the password reset process again.');
      }

      debugPrint('   Calling updateUser...');
      final updateResponse = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      debugPrint('✅ [ForgotPassword] Password updated successfully!');
      debugPrint('   User: ${updateResponse.user?.email ?? "null"}');

      // CRITICAL: Mark success in provider FIRST before any other operations
      // This ensures success state persists even if widget rebuilds during signOut
      ref.read(passwordResetProvider.notifier).markSuccess();
      debugPrint('   ✅ Marked success in provider');

      setState(() {
        _isLoading = false;
      });

      // Sign out to force re-login (fire and forget - success view handles navigation)
      try {
        await Supabase.instance.client.auth.signOut();
        debugPrint('   Signed out successfully');
      } catch (signOutError) {
        debugPrint('   Sign out error (non-critical): $signOutError');
        // This is not critical - the password was already updated
      }

      // Navigation is handled by _buildSuccessView() which schedules auto-navigation
      // This ensures navigation happens even if widget is rebuilt after signOut
      return;
    } on AuthException catch (e) {
      debugPrint('❌ [ForgotPassword] Password update failed: ${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = _getReadableError(e.message);
      });
    } catch (e) {
      debugPrint('❌ [ForgotPassword] Error: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      setState(() {
        _isLoading = false;
        // Show actual error for debugging - helps identify the root cause
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _getReadableError(String message) {
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please wait a few minutes.';
    }
    if (message.contains('Invalid') || message.contains('invalid')) {
      return 'Invalid OTP code. Please check and try again.';
    }
    if (message.contains('expired')) {
      return 'OTP has expired. Please request a new one.';
    }
    if (message.contains('not found')) {
      return 'Account not found. Please check your email/phone.';
    }
    if (message.contains('Phone') && !message.contains('provider')) {
      return 'Invalid phone number format. Use 10 digits.';
    }
    // Phone provider not configured in Supabase
    if (message.contains('unsupported') && message.contains('phone')) {
      return 'SMS service is not available. Please use email instead.';
    }
    if (message.contains('provider')) {
      return 'SMS service is not configured. Please use email to reset your password.';
    }
    // Session missing or expired
    if (message.contains('session') || message.contains('Session')) {
      return 'Session expired. Please start the password reset process again.';
    }
    if (message.contains('Auth session missing')) {
      return 'Session expired. Please restart the password reset process.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the password reset state from provider
    final resetState = ref.watch(passwordResetProvider);
    final currentStep = resetState.currentStep;
    final isSuccess = resetState.isSuccess; // Use provider's success state

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (currentStep > 0 && !isSuccess) {
              ref.read(passwordResetProvider.notifier).goBack();
              setState(() {
                _errorMessage = null;
              });
            } else {
              // Reset flow when leaving
              ref.read(passwordResetProvider.notifier).resetFlow();
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: isSuccess ? _buildSuccessView() : _buildStepContent(currentStep),
      ),
    );
  }

  Widget _buildSuccessView() {
    // Schedule navigation to login after a delay (only once)
    if (!_hasScheduledNavigation) {
      _hasScheduledNavigation = true;
      debugPrint('🔐 [ForgotPassword] Success view shown, scheduling navigation...');

      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Wait 2 seconds to show success message
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          debugPrint('🔐 [ForgotPassword] Navigating to login...');
          // Reset the flow state and navigate
          ref.read(passwordResetProvider.notifier).resetFlow();
          context.go('/login');
        }
      });
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
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
              'Redirecting to login...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing2xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing2xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator
            _buildStepIndicator(currentStep),
            const SizedBox(height: AppTheme.spacing2xl),

            // Step content
            if (currentStep == 0) _buildContactStep(),
            if (currentStep == 1) _buildOtpStep(),
            if (currentStep == 2) _buildPasswordStep(),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: [
        _buildStepDot(0, 'Contact', currentStep),
        Expanded(child: _buildStepLine(0, currentStep)),
        _buildStepDot(1, 'OTP', currentStep),
        Expanded(child: _buildStepLine(1, currentStep)),
        _buildStepDot(2, 'Password', currentStep),
      ],
    );
  }

  Widget _buildStepDot(int step, String label, int currentStep) {
    final isActive = currentStep >= step;
    final isCurrent = currentStep == step;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: primaryColor, width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? primaryColor : Colors.grey,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int beforeStep, int currentStep) {
    final isActive = currentStep > beforeStep;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? primaryColor : Colors.grey.shade300,
    );
  }

  /// Step 1: Choose Email or Phone and enter contact info
  Widget _buildContactStep() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon changes based on selected method
        Icon(
          _selectedMethod == ResetMethod.email
              ? Icons.email_outlined
              : Icons.phone_android,
          size: 64,
          color: primaryColor,
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Title
        const Text(
          'Reset Your Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Description
        const Text(
          'Choose how you want to receive your verification code.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing2xl),

        // Email / Phone toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildMethodTab(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  isSelected: _selectedMethod == ResetMethod.email,
                  onTap: () {
                    setState(() {
                      _selectedMethod = ResetMethod.email;
                      _errorMessage = null;
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildMethodTab(
                  label: 'Phone',
                  icon: Icons.phone_android,
                  isSelected: _selectedMethod == ResetMethod.phone,
                  subtitle: 'Coming Soon',
                  isDisabled: true, // Disabled until SMS provider is configured
                  onTap: () {
                    // Show message that phone is coming soon
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone OTP will be available soon. Please use email for now.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing2xl),

        // Email or Phone field based on selection
        if (_selectedMethod == ResetMethod.email)
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'you@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            validator: Validators.email,
          )
        else
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_isLoading,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '9876543210',
              prefixIcon: const Icon(Icons.phone_android),
              prefixText: '+91 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              helperText: 'Enter 10-digit mobile number',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length != 10) {
                return 'Enter a valid 10-digit phone number';
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                return 'Enter a valid Indian mobile number';
              }
              return null;
            },
          ),
        const SizedBox(height: AppTheme.spacing2xl),

        // Send OTP button
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _selectedMethod == ResetMethod.email
                      ? 'Send OTP to Email'
                      : 'Send OTP to Phone',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildMethodTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? subtitle,
    bool isDisabled = false,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final effectiveSelected = isSelected && !isDisabled;

    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMd,
          horizontal: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: effectiveSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDisabled
                      ? Colors.grey.shade400
                      : (effectiveSelected ? Colors.white : Colors.grey),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled
                        ? Colors.grey.shade400
                        : (effectiveSelected ? Colors.white : Colors.grey),
                    fontWeight: effectiveSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDisabled ? Colors.orange.shade300 : Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final resetState = ref.watch(passwordResetProvider);
    final contactInfo = resetState.contactInfo ??
        (_selectedMethod == ResetMethod.email
            ? _emailController.text.trim()
            : _formatPhoneNumber(_phoneController.text.trim()));
    final isPhone = resetState.method == ResetMethod.phone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Icon(
          Icons.pin_outlined,
          size: 64,
          color: primaryColor,
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Title
        const Text(
          'Enter OTP Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Description
        Text(
          'Enter the 6-digit code sent to\n$contactInfo',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Method indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: (isPhone ? Colors.green : Colors.blue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPhone ? Icons.sms : Icons.email,
                size: 16,
                color: isPhone ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                isPhone ? 'Sent via SMS' : 'Sent via Email',
                style: TextStyle(
                  fontSize: 12,
                  color: isPhone ? Colors.green : Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing2xl),

        // OTP field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          enabled: !_isLoading,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: '------',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Resend OTP link
        TextButton(
          onPressed: _isLoading ? null : _resendOtp,
          child: const Text('Didn\'t receive code? Resend OTP'),
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Verify button
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Verify OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Icon(
          Icons.lock_reset,
          size: 64,
          color: primaryColor,
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Title
        const Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Description
        const Text(
          'Enter your new password below.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing2xl),

        // New password field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          onChanged: _checkPasswordStrength,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'Enter new password',
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
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Password strength indicator
        if (_passwordController.text.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                _passwordStrengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _passwordStrengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Password requirements checklist
          _buildRequirement('At least 8 characters', _hasMinLength),
          _buildRequirement('Uppercase letter (A-Z)', _hasUppercase),
          _buildRequirement('Lowercase letter (a-z)', _hasLowercase),
          _buildRequirement('Number (0-9)', _hasNumber),
          _buildRequirement('Special character (!@#\$%^&*)', _hasSpecialChar),
        ],
        const SizedBox(height: AppTheme.spacingLg),

        // Confirm password field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          enabled: !_isLoading,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter new password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
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
        ),
        const SizedBox(height: AppTheme.spacing2xl),

        // Update password button
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePassword,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
