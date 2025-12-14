import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  // User dropdown state
  String? _selectedUserId;
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

    // Load test users configuration (for password lookup)
    _loadTestConfig();
  }

  Future<void> _loadTestConfig() async {
    await TestUsersConfig.loadConfig();
    if (mounted) {
      setState(() {
        _configLoaded = true;
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

  void _onUserSelected(String? userId, List<LoginUserModel> users) {
    if (userId == null) return;

    setState(() {
      _selectedUserId = userId;

      // Check if it's the empty placeholder option
      if (userId.isEmpty) {
        _emailController.clear();
        _passwordController.clear();
        return;
      }

      // Find the selected user from database users
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => const LoginUserModel(id: '', email: ''),
      );

      if (user.email.isNotEmpty) {
        _emailController.text = user.email;

        // Try to find password from test config (if available)
        final testUser = TestUsersConfig.testUsers.firstWhere(
          (u) => u['email']?.toLowerCase() == user.email.toLowerCase(),
          orElse: () => {'password': ''},
        );
        _passwordController.text = testUser['password'] ?? '';
      }
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

        // Navigate to welcome choice page
        // Small delay to show the success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // TEMPORARY: Go to welcome choice page for design review
          context.go(AppRoutes.welcomeChoice);
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

  Future<void> _sendTestNotification() async {
    try {
      debugPrint('🧪 Sending test notification...');

      // Create and initialize local notification plugin
      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      // Initialize the plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await localNotifications.initialize(initSettings);
      debugPrint('   ✅ Local notifications initialized');

      // Create Android notification channel first
      const androidChannel = AndroidNotificationChannel(
        'test_channel',
        'Test Notifications',
        description: 'Test notification channel',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      debugPrint('   ✅ Notification channel created');

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        ticker: 'Test notification',
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show test notification
      await localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🎉 Test Notification',
        'Firebase notifications are working! This is a test message from TravelCrew.',
        details,
      );

      debugPrint('✅ Test notification sent successfully');

      if (mounted) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Test notification sent! Check your notification tray.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Show dialog with instructions
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('📬 Notification Sent!'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The notification was sent successfully!'),
                  SizedBox(height: 16),
                  Text('To see it:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('1. Swipe DOWN from the top-center of the screen'),
                  SizedBox(height: 4),
                  Text('2. Or press Command+L to lock and see it on lock screen'),
                  SizedBox(height: 16),
                  Text('iOS Simulator limitations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• Banners appear briefly then auto-hide'),
                  Text('• No sound/vibration'),
                  Text('• Must check Notification Center manually'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it!'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send test notification: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            duration: const Duration(seconds: 4),
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

                                  // User Selector - fetches all users from database
                                  if (_configLoaded && TestUsersConfig.enableTestUserDropdown) ...[
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final usersAsync = ref.watch(allUsersForLoginProvider);

                                        return usersAsync.when(
                                          data: (users) {
                                            if (users.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            return Container(
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
                                                        'Quick Login (${users.length} users)',
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
                                                            value: _selectedUserId,
                                                            isExpanded: true,
                                                            underline: const SizedBox(),
                                                            hint: const Text('Select a user...'),
                                                            items: [
                                                              const DropdownMenuItem<String>(
                                                                value: '',
                                                                child: Text('Select User'),
                                                              ),
                                                              ...users.map((user) => DropdownMenuItem<String>(
                                                                value: user.id,
                                                                child: Text(
                                                                  user.displayName,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              )),
                                                            ],
                                                            onChanged: authState.isLoading
                                                                ? null
                                                                : (userId) => _onUserSelected(userId, users),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          loading: () => Container(
                                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.1),
                                              border: Border.all(color: Colors.amber),
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: AppTheme.spacingSm),
                                                Text('Loading users...'),
                                              ],
                                            ),
                                          ),
                                          error: (error, _) => const SizedBox.shrink(),
                                        );
                                      },
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
                                              context.push('/forgot-password');
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

                                  const SizedBox(height: AppTheme.spacingMd),

                                  // Test Notification Button (for development)
                                  OutlinedButton.icon(
                                    onPressed: authState.isLoading ? null : _sendTestNotification,
                                    icon: const Icon(Icons.notifications_active, size: 18),
                                    label: const Text('Test Notification'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: themeData.primaryColor,
                                      side: BorderSide(color: themeData.primaryColor.withValues(alpha: 0.3)),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spacingMd,
                                        horizontal: AppTheme.spacingLg,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      ),
                                    ),
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

}
