import 'package:flutter/animation.dart';

/// Premium animation constants for Travel Crew
///
/// These values create a cohesive, delightful animation system
/// that makes every interaction feel smooth and responsive.
class AppAnimations {
  AppAnimations._();

  // ============================================================================
  // DURATIONS - Carefully tuned for premium feel
  // ============================================================================

  /// Lightning fast - For immediate feedback (icon state changes, ripples)
  static const Duration instant = Duration(milliseconds: 100);

  /// Quick - For micro-interactions (button presses, checkboxes)
  static const Duration quick = Duration(milliseconds: 150);

  /// Fast - For UI feedback (snackbars, tooltips appearing)
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal - For standard transitions (dialogs, bottom sheets)
  static const Duration normal = Duration(milliseconds: 300);

  /// Medium - For card animations, list items
  static const Duration medium = Duration(milliseconds: 400);

  /// Slow - For page transitions, hero animations
  static const Duration slow = Duration(milliseconds: 500);

  /// Leisurely - For special emphasis animations
  static const Duration leisurely = Duration(milliseconds: 700);

  /// Very slow - For loading states, shimmer
  static const Duration verySlow = Duration(milliseconds: 1000);

  // ============================================================================
  // CURVES - Premium easing functions
  // ============================================================================

  /// Smooth entrance - Elements slide in gracefully
  static const Curve entrance = Curves.easeOut;

  /// Smooth exit - Elements slide out elegantly
  static const Curve exit = Curves.easeIn;

  /// Bouncy - For playful, attention-grabbing animations
  static const Curve bouncy = Curves.elasticOut;

  /// Spring - Natural, physics-based feel
  static const Curve spring = Curves.easeInOutBack;

  /// Emphasized - Material Design 3 emphasis curve
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Decelerate - Smooth slowdown
  static const Curve decelerate = Curves.decelerate;

  /// Anticipate - Slight pull-back before moving
  static const Curve anticipate = Curves.easeInOutBack;

  // ============================================================================
  // STAGGER DELAYS - For sequential animations
  // ============================================================================

  /// Tiny delay between list items (50ms)
  static const Duration staggerTiny = Duration(milliseconds: 50);

  /// Small delay between items (75ms)
  static const Duration staggerSmall = Duration(milliseconds: 75);

  /// Medium delay between items (100ms)
  static const Duration staggerMedium = Duration(milliseconds: 100);

  /// Large delay between items (150ms)
  static const Duration staggerLarge = Duration(milliseconds: 150);

  // ============================================================================
  // SCALE VALUES - For scale animations
  // ============================================================================

  /// Subtle scale down (0.95)
  static const double scaleSubtle = 0.95;

  /// Small scale down (0.9)
  static const double scaleSmall = 0.9;

  /// Medium scale down (0.8)
  static const double scaleMedium = 0.8;

  /// Large scale up (1.1)
  static const double scaleLarge = 1.1;

  /// Emphasis scale up (1.2)
  static const double scaleEmphasis = 1.2;

  // ============================================================================
  // OFFSET VALUES - For slide animations
  // ============================================================================

  /// Small slide distance (20px)
  static const double slideSmall = 20.0;

  /// Medium slide distance (40px)
  static const double slideMedium = 40.0;

  /// Large slide distance (80px)
  static const double slideLarge = 80.0;

  /// Full screen slide (1.0 = full screen width/height)
  static const double slideFull = 1.0;

  // ============================================================================
  // ROTATION VALUES - For rotation animations
  // ============================================================================

  /// Slight rotation (5 degrees)
  static const double rotationSlight = 0.087; // ~5 degrees in radians

  /// Small rotation (15 degrees)
  static const double rotationSmall = 0.262; // ~15 degrees in radians

  /// Medium rotation (45 degrees)
  static const double rotationMedium = 0.785; // ~45 degrees in radians

  /// Full rotation (360 degrees)
  static const double rotationFull = 6.283; // ~360 degrees in radians

  // ============================================================================
  // OPACITY VALUES - For fade animations
  // ============================================================================

  /// Fully transparent
  static const double opacityInvisible = 0.0;

  /// Very subtle (10% opacity)
  static const double opacitySubtle = 0.1;

  /// Semi-transparent (50% opacity)
  static const double opacitySemi = 0.5;

  /// Mostly visible (80% opacity)
  static const double opacityMostly = 0.8;

  /// Fully visible
  static const double opacityFull = 1.0;

  // ============================================================================
  // SHIMMER - For loading states
  // ============================================================================

  /// Shimmer animation duration
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  /// Shimmer pause between cycles
  static const Duration shimmerPause = Duration(milliseconds: 300);

  // ============================================================================
  // HERO - For hero animations
  // ============================================================================

  /// Hero flight duration
  static const Duration heroDuration = Duration(milliseconds: 400);

  /// Hero flight curve
  static const Curve heroCurve = Curves.easeInOutCubic;

  // ============================================================================
  // PAGE TRANSITIONS - For route animations
  // ============================================================================

  /// Page transition duration
  static const Duration pageTransition = Duration(milliseconds: 350);

  /// Page transition curve
  static const Curve pageTransitionCurve = Curves.easeInOutCubicEmphasized;
}

/// Animation presets for common use cases
class AnimationPresets {
  AnimationPresets._();

  /// Fade in animation preset
  static const fadeIn = AnimationConfig(
    duration: AppAnimations.normal,
    curve: AppAnimations.entrance,
  );

  /// Fade out animation preset
  static const fadeOut = AnimationConfig(
    duration: AppAnimations.normal,
    curve: AppAnimations.exit,
  );

  /// Slide up animation preset
  static const slideUp = AnimationConfig(
    duration: AppAnimations.medium,
    curve: AppAnimations.emphasized,
  );

  /// Slide down animation preset
  static const slideDown = AnimationConfig(
    duration: AppAnimations.medium,
    curve: AppAnimations.emphasized,
  );

  /// Scale up animation preset
  static const scaleUp = AnimationConfig(
    duration: AppAnimations.normal,
    curve: AppAnimations.bouncy,
  );

  /// Bounce animation preset
  static const bounce = AnimationConfig(
    duration: AppAnimations.slow,
    curve: AppAnimations.bouncy,
  );

  /// Spring animation preset
  static const spring = AnimationConfig(
    duration: AppAnimations.medium,
    curve: AppAnimations.spring,
  );
}

/// Animation configuration class
class AnimationConfig {
  final Duration duration;
  final Curve curve;

  const AnimationConfig({
    required this.duration,
    required this.curve,
  });
}
