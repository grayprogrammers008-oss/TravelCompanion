// Welcome Choice Page
//
// Shown to new users (with no trips) after login.
// Provides three clear options:
// 1. Create a New Trip - For trip organizers
// 2. Join an Existing Trip - For people invited by friends
// 3. Explore Public Trips - Browse and join public trips
//
// Users with existing trips skip this and go directly to Dashboard.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;

class WelcomeChoicePage extends ConsumerStatefulWidget {
  const WelcomeChoicePage({super.key});

  @override
  ConsumerState<WelcomeChoicePage> createState() => _WelcomeChoicePageState();
}

class _WelcomeChoicePageState extends ConsumerState<WelcomeChoicePage>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  AnimationController? _backgroundController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Content animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Background animation - continuous loop
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animationController!.forward();
    _initialized = true;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _backgroundController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    // Show loading while animations initialize
    if (!_initialized || _fadeAnimation == null || _slideAnimation == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeData.primaryColor.withValues(alpha: 0.08),
                Colors.white,
                themeData.primaryColor.withValues(alpha: 0.04),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(themeData),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: _slideAnimation!,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                  child: Column(
                    children: [
                      // Logo and welcome text - compact
                      _buildHeader(themeData),

                      const Spacer(flex: 1),

                      // Choice cards
                      _buildChoiceCards(context, themeData),

                      const Spacer(flex: 1),

                      // Skip option
                      _buildSkipOption(context, themeData),

                      const SizedBox(height: AppTheme.spacingSm),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic themeData) {
    return Column(
      children: [
        // App icon - smaller
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeData.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.flight_takeoff,
            size: 36,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),

        // Welcome text
        Text(
          'Welcome to TravelCompanion!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.neutral900,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppTheme.spacingXs),

        Text(
          'Plan trips together, split expenses easily,\nand make memories with friends.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.neutral600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChoiceCards(BuildContext context, dynamic themeData) {
    return Column(
      children: [
        // Create Trip Card - Primary
        _buildCompactCard(
          context: context,
          themeData: themeData,
          icon: Icons.add_location_alt,
          title: 'Create a New Trip',
          subtitle: 'Start planning your next adventure',
          isPrimary: true,
          onTap: () => context.push('/trips/quick'),
        ),

        const SizedBox(height: AppTheme.spacingSm),

        // Join Trip Card
        _buildCompactCard(
          context: context,
          themeData: themeData,
          icon: Icons.group_add,
          title: 'Join an Existing Trip',
          subtitle: 'Enter invite code from a friend',
          isPrimary: false,
          onTap: () => _showJoinTripDialog(context, themeData),
        ),

        const SizedBox(height: AppTheme.spacingSm),

        // Explore Public Trips Card
        _buildCompactCard(
          context: context,
          themeData: themeData,
          icon: Icons.explore,
          title: 'Explore Public Trips',
          subtitle: 'Browse and join trips by others',
          isPrimary: false,
          onTap: () => context.push('/trips/browse'),
        ),
      ],
    );
  }

  Widget _buildCompactCard({
    required BuildContext context,
    required dynamic themeData,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? themeData.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: isPrimary
              ? null
              : Border.all(color: AppTheme.neutral200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? themeData.primaryColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isPrimary ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : themeData.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isPrimary ? Colors.white : themeData.primaryColor,
              ),
            ),

            const SizedBox(width: AppTheme.spacingMd),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? Colors.white : AppTheme.neutral900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipOption(BuildContext context, dynamic themeData) {
    return TextButton(
      onPressed: () => context.go('/dashboard'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Skip for now',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: AppTheme.neutral500,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(dynamic themeData) {
    final controller = _backgroundController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final value = controller.value;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeData.primaryColor.withValues(alpha: 0.08),
                Colors.white,
                themeData.primaryColor.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Floating circle 1 - large, top right
              Positioned(
                top: -80 + (30 * _wave(value, 0)),
                right: -80 + (20 * _wave(value, 0.2)),
                child: _buildFloatingShape(
                  size: 220,
                  color: themeData.primaryColor.withValues(alpha: 0.1),
                  rotation: value * 0.5,
                ),
              ),

              // Floating circle 2 - medium, bottom left
              Positioned(
                bottom: -40 + (25 * _wave(value, 0.3)),
                left: -40 + (15 * _wave(value, 0.5)),
                child: _buildFloatingShape(
                  size: 160,
                  color: themeData.primaryColor.withValues(alpha: 0.08),
                  rotation: -value * 0.3,
                ),
              ),

              // Floating circle 3 - small, top left
              Positioned(
                top: size.height * 0.15 + (20 * _wave(value, 0.4)),
                left: -30 + (10 * _wave(value, 0.6)),
                child: _buildFloatingShape(
                  size: 80,
                  color: themeData.primaryColor.withValues(alpha: 0.12),
                  rotation: value * 0.8,
                ),
              ),

              // Floating circle 4 - small, center right
              Positioned(
                top: size.height * 0.4 + (15 * _wave(value, 0.7)),
                right: -20 + (12 * _wave(value, 0.1)),
                child: _buildFloatingShape(
                  size: 60,
                  color: themeData.primaryColor.withValues(alpha: 0.1),
                  rotation: -value * 0.6,
                ),
              ),

              // Floating circle 5 - tiny, bottom right
              Positioned(
                bottom: size.height * 0.25 + (18 * _wave(value, 0.8)),
                right: size.width * 0.2 + (10 * _wave(value, 0.9)),
                child: _buildFloatingShape(
                  size: 40,
                  color: themeData.primaryColor.withValues(alpha: 0.15),
                  rotation: value,
                ),
              ),

              // Floating circle 6 - tiny, top center
              Positioned(
                top: size.height * 0.08 + (12 * _wave(value, 0.2)),
                left: size.width * 0.4 + (8 * _wave(value, 0.4)),
                child: _buildFloatingShape(
                  size: 30,
                  color: themeData.primaryColor.withValues(alpha: 0.1),
                  rotation: -value * 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingShape({
    required double size,
    required Color color,
    required double rotation,
  }) {
    return Transform.rotate(
      angle: rotation * math.pi,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: size * 0.3,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }

  // Sine wave function for smooth oscillation
  double _wave(double value, double offset) {
    return math.sin((value + offset) * 2 * math.pi);
  }

  void _showJoinTripDialog(BuildContext context, dynamic themeData) {
    final codeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: themeData.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.group_add,
                        color: themeData.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join a Trip',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.neutral900,
                          ),
                        ),
                        Text(
                          'Enter the invite code from your friend',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // Code input
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'ABCD1234',
                    hintStyle: TextStyle(
                      color: AppTheme.neutral300,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                    filled: true,
                    fillColor: AppTheme.neutral50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(
                        color: themeData.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Join button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement join trip logic
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Join trip feature coming soon! Code: ${codeController.text}'),
                          backgroundColor: themeData.primaryColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Join Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Help text
                Center(
                  child: Text(
                    'Ask the trip organizer to share the invite code with you',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
