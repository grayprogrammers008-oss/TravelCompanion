import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/config/test_users_config.dart';
import '../providers/auth_providers.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Test user dropdown state
  String? _selectedTestUser;
  bool _configLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    // Load test users configuration
    _loadTestConfig();
  }

  Future<void> _loadTestConfig() async {
    await TestUsersConfig.loadConfig();
    if (mounted) {
      setState(() {
        _configLoaded = true;
        // Set initial selected user to the first one in the list
        if (TestUsersConfig.testUsers.isNotEmpty) {
          _selectedTestUser = TestUsersConfig.testUsers.first['name'];
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTestUserSelected(String? userName) {
    if (userName == null) return;

    final user = TestUsersConfig.testUsers.firstWhere((u) => u['name'] == userName);
    setState(() {
      _selectedTestUser = userName;
      _emailController.text = user['email']!;
      _passwordController.text = user['password']!;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Welcome back! 🎉'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to home page
        // Small delay to show the success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final themeData = context.appThemeData;

    return Scaffold(
      body: MeshGradientBackground(
        intensity: 0.8,
        child: Stack(
          children: [
            // Decorative Circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo & Branding Section
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingLg),
                          child: Column(
                            children: [
                              // App Icon with Shadow
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingLg),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusXl),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 24,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.airplanemode_active,
                                  size: 48,
                                  color: themeData.primaryColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),

                              // App Name
                              Text(
                                'Travel Crew',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: themeData.primaryColor,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.spacingXs),

                              // Tagline
                              Text(
                                'Your Journey, Together',
                                style: context.bodyLarge.copyWith(
                                      color: context.textColor.withValues(alpha: 0.7),
                                      letterSpacing: 0.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXl),

                        // Form Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXl),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingXl),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Welcome Text
                                  Text(
                                    'Welcome Back!',
                                    style: context.headlineMedium.copyWith(
                                          color: context.textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.spacingXs),
                                  Text(
                                    'Sign in to continue your adventure',
                                    style: context.bodyMedium.copyWith(
                                          color: context.textColor.withValues(alpha: 0.6),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.spacingXl),

                                  // TEMPORARY: Test User Selector (only shown if enabled and config loaded)
                                  if (_configLoaded && TestUsersConfig.enableTestUserDropdown) ...[
                                    Container(
                                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.1),
                                        border: Border.all(color: Colors.amber),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.bug_report, color: Colors.amber, size: 16),
                                              const SizedBox(width: AppTheme.spacingXs),
                                              Text(
                                                'Testing Mode',
                                                style: context.bodySmall.copyWith(
                                                  color: Colors.amber.shade900,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppTheme.spacingSm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingMd,
                                              vertical: AppTheme.spacingSm,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person, size: 20, color: Colors.grey),
                                                const SizedBox(width: AppTheme.spacingSm),
                                                Expanded(
                                                  child: DropdownButton<String>(
                                                    value: _selectedTestUser,
                                                    isExpanded: true,
                                                    underline: const SizedBox(),
                                                    items: TestUsersConfig.testUsers
                                                        .map((user) => DropdownMenuItem<String>(
                                                              value: user['name'],
                                                              child: Text(user['name']!),
                                                            ))
                                                        .toList(),
                                                    onChanged: authState.isLoading ? null : _onTestUserSelected,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingMd),
                                  ],

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      hintText: 'you@example.com',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(
                                            AppTheme.spacingSm),
                                        padding: const EdgeInsets.all(
                                            AppTheme.spacingXs),
                                        decoration: BoxDecoration(
                                          color: themeData.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm),
                                        ),
                                        child: Icon(
                                          Icons.email_outlined,
                                          color: themeData.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    validator: Validators.email,
                                    enabled: !authState.isLoading,
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(
                                            AppTheme.spacingSm),
                                        padding: const EdgeInsets.all(
                                            AppTheme.spacingXs),
                                        decoration: BoxDecoration(
                                          color: themeData.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm),
                                        ),
                                        child: Icon(
                                          Icons.lock_outlined,
                                          color: themeData.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: context.textColor.withValues(alpha: 0.4),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: Validators.password,
                                    enabled: !authState.isLoading,
                                  ),
                                  const SizedBox(height: AppTheme.spacingSm),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: authState.isLoading
                                          ? null
                                          : () {
                                              _showForgotPasswordDialog(context);
                                            },
                                      style: TextButton.styleFrom(
                                        foregroundColor: themeData.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingSm,
                                          vertical: AppTheme.spacingXs,
                                        ),
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: context.labelLarge.copyWith(
                                              color: themeData.primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingLg),

                                  // Login Button with Gradient
                                  GlossyButton(
                                    label: 'Sign In',
                                    onPressed: authState.isLoading ? null : _handleLogin,
                                    isLoading: authState.isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLg),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: context.bodyMedium.copyWith(
                                    color: context.textColor.withValues(alpha: 0.6),
                                  ),
                            ),
                            TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const SignUpPage(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: themeData.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm,
                                ),
                              ),
                              child: Text(
                                'Sign Up',
                                style: context.labelLarge.copyWith(
                                      color: themeData.primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final themeData = dialogContext.appThemeData;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: themeData.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 32,
                    color: themeData.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Title
                Text(
                  'Reset Password',
                  style: context.headlineSmall.copyWith(
                        color: context.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXs),

                // Description
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: context.bodyMedium.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(AppTheme.spacingSm),
                      padding: const EdgeInsets.all(AppTheme.spacingXs),
                      decoration: BoxDecoration(
                        color: themeData.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: themeData.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: themeData.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: themeData.primaryShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .resetPassword(emailController.text.trim());
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Password reset email sent! 📧'),
                                      backgroundColor: AppTheme.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppTheme.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMd),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingMd),
                          ),
                          child: const Text(
                            'Send Reset Link',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
