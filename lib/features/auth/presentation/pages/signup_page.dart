import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../providers/auth_providers.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.of(context).pop(); // Go back to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully! 🎉'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
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
            left: -100,
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
            right: -150,
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
            child: Column(
              children: [
                // Back Button
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
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
                                      padding:
                                          const EdgeInsets.all(AppTheme.spacingMd),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusLg),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 24,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.person_add,
                                        size: 40,
                                        color: AppTheme.accentPurple,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingMd),

                                    // Title
                                    Text(
                                      'Join Travel Crew',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.spacingXs),

                                    // Subtitle
                                    Text(
                                      'Start planning amazing trips together',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            letterSpacing: 0.5,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacingLg),

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Full Name Field
                                        TextFormField(
                                          controller: _fullNameController,
                                          decoration: InputDecoration(
                                            labelText: 'Full Name',
                                            hintText: 'John Doe',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(
                                                  AppTheme.spacingSm),
                                              padding: const EdgeInsets.all(
                                                  AppTheme.spacingXs),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentPurple
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radiusSm),
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                                color: AppTheme.accentPurple,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          validator: Validators.name,
                                          enabled: !authState.isLoading,
                                        ),
                                        const SizedBox(height: AppTheme.spacingMd),

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
                                                borderRadius:
                                                    BorderRadius.circular(
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

                                        // Phone Number Field (Optional)
                                        TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                            labelText: 'Phone Number (Optional)',
                                            hintText: '+1 234 567 8900',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(
                                                  AppTheme.spacingSm),
                                              padding: const EdgeInsets.all(
                                                  AppTheme.spacingXs),
                                              decoration: BoxDecoration(
                                                color: AppTheme.neutral100,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radiusSm),
                                              ),
                                              child: const Icon(
                                                Icons.phone_outlined,
                                                color: AppTheme.neutral600,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          validator: Validators.phoneNumber,
                                          enabled: !authState.isLoading,
                                        ),
                                        const SizedBox(height: AppTheme.spacingMd),

                                        // Password Field
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            hintText: 'Min 8 characters',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(
                                                  AppTheme.spacingSm),
                                              padding: const EdgeInsets.all(
                                                  AppTheme.spacingXs),
                                              decoration: BoxDecoration(
                                                color: themeData.primaryColor.withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
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
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: AppTheme.neutral400,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: Validators.password,
                                          enabled: !authState.isLoading,
                                        ),
                                        const SizedBox(height: AppTheme.spacingMd),

                                        // Confirm Password Field
                                        TextFormField(
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          decoration: InputDecoration(
                                            labelText: 'Confirm Password',
                                            hintText: 'Re-enter password',
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.all(
                                                  AppTheme.spacingSm),
                                              padding: const EdgeInsets.all(
                                                  AppTheme.spacingXs),
                                              decoration: BoxDecoration(
                                                color: themeData.primaryColor.withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
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
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: AppTheme.neutral400,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) =>
                                              Validators.confirmPassword(
                                            value,
                                            _passwordController.text,
                                          ),
                                          enabled: !authState.isLoading,
                                        ),
                                        const SizedBox(height: AppTheme.spacingLg),

                                        // Sign Up Button with Gradient
                                        GlossyButton(
                                          label: 'Create Account',
                                          onPressed: authState.isLoading ? null : _handleSignUp,
                                          isLoading: authState.isLoading,
                                        ),
                                        const SizedBox(height: AppTheme.spacingMd),

                                        // Terms and Privacy
                                        Text(
                                          'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.neutral500,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacingMd),
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
          ],
        ),
      ),
    );
  }
}
