import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌟 TRAVELCOMPANION - WANDERLUST PREMIUM DESIGN SYSTEM 🌟
///
/// A world-class, emotionally resonant design language that makes opening
/// this app feel like opening a beautifully designed travel magazine the
/// morning before your trip - exciting, sophisticated, and full of possibility.
///
/// Core Emotion: "Anticipation of Adventure"
/// - Primary: Excitement (I can't wait!)
/// - Secondary: Trust (They've got this)
/// - Tertiary: Delight (This is so well done)
///
/// Design Philosophy:
/// - SAPPHIRE SUNSET: Trust + Adventure in perfect harmony
/// - EDITORIAL CLARITY: Magazine-quality typography
/// - SOFT GEOMETRY: Friendly, approachable rounded elements
/// - DELIGHTFUL MOTION: Animations that spark joy
/// - ACCESSIBLE BEAUTY: WCAG AAA compliant throughout

class AppThemeV2 {
  // ==================== SAPPHIRE SUNSET COLOR SYSTEM ====================

  /// Primary Brand: "Deep Sky Sapphire"
  /// Psychology: Trust (airlines), Professionalism, Calm, Adventure
  static const Color sapphire950 = Color(0xFF0C1E3E);  // Deep night sky
  static const Color sapphire900 = Color(0xFF163152);  // Midnight flight
  static const Color sapphire800 = Color(0xFF1E4064);  // Ocean twilight
  static const Color sapphire700 = Color(0xFF2B5A8A);  // Deep water
  static const Color sapphire600 = Color(0xFF3B75B5);  // Classic aviation blue ⭐ PRIMARY
  static const Color sapphire500 = Color(0xFF4B8DD6);  // Bright sky
  static const Color sapphire400 = Color(0xFF6BA3E0);  // Day sky
  static const Color sapphire300 = Color(0xFF93BEF0);  // Light blue
  static const Color sapphire200 = Color(0xFFC4DCF7);  // Pale blue
  static const Color sapphire100 = Color(0xFFE3EFFC);  // Ice blue
  static const Color sapphire50 = Color(0xFFF5F9FF);   // Almost white blue

  /// Accent: "Golden Hour Collection"
  /// Psychology: Energy, Warmth, Adventure, Happiness
  static const Color sunriseOrange = Color(0xFFFF7A59);  // Morning energy
  static const Color sunsetGold = Color(0xFFFFB84D);     // Warm excitement
  static const Color sunsetPink = Color(0xFFFF6B9D);     // Adventure romance
  static const Color sunriseCoral = Color(0xFFFF9E80);   // Soft warmth

  /// Neutrals: "Cloud + Charcoal"
  /// Warm blacks for better harmony with sapphire
  static const Color ink = Color(0xFF0F1419);         // Primary text (warm black)
  static const Color charcoal = Color(0xFF1A1F28);    // Secondary text
  static const Color slate = Color(0xFF4A5568);       // Tertiary text
  static const Color stone = Color(0xFF718096);       // Disabled, placeholders
  static const Color silver = Color(0xFFCBD5E1);      // Borders, dividers
  static const Color cloud = Color(0xFFE5E7EB);       // Soft backgrounds
  static const Color mist = Color(0xFFF3F4F6);        // Subtle backgrounds
  static const Color snow = Color(0xFFFAFBFC);        // Main background

  /// Semantic Colors
  static const Color success = Color(0xFF10B981);   // Emerald (universal success green)
  static const Color warning = Color(0xFFF59E0B);   // Amber (attention without alarm)
  static const Color error = Color(0xFFEF4444);     // Rose (clear but not harsh)
  static const Color info = Color(0xFF3B82F6);      // Sky blue (friendly information)

  // ==================== SIGNATURE GRADIENTS ====================

  /// The hero gradient: "Sunset Journey"
  /// Sapphire → Sky → Gold → Orange
  static const LinearGradient sunsetJourney = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      sapphire600,   // Sapphire
      sapphire500,   // Bright Sky
      sunsetGold,    // Sunset Gold
      sunriseOrange, // Sunrise Orange
    ],
    stops: [0.0, 0.25, 0.75, 1.0],
  );

  /// Premium sapphire gradient
  static const LinearGradient sapphireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sapphire600, sapphire500],
  );

  /// Warm sunset gradient
  static const LinearGradient warmSunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetGold, sunriseOrange, sunsetPink],
    stops: [0.0, 0.5, 1.0],
  );

  /// Shimmer effect for loading
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [mist, cloud, mist],
    stops: [0.0, 0.5, 1.0],
  );

  // ==================== SPACING SYSTEM ====================
  /// Modified 8px base with golden ratio influence

  static const double spacing1 = 4.0;    // 0.25rem
  static const double spacing2 = 8.0;    // 0.5rem
  static const double spacing3 = 12.0;   // 0.75rem
  static const double spacing4 = 16.0;   // 1rem - BASE UNIT ⭐
  static const double spacing5 = 20.0;   // 1.25rem
  static const double spacing6 = 24.0;   // 1.5rem
  static const double spacing8 = 32.0;   // 2rem
  static const double spacing10 = 40.0;  // 2.5rem
  static const double spacing12 = 48.0;  // 3rem
  static const double spacing16 = 64.0;  // 4rem
  static const double spacing20 = 80.0;  // 5rem
  static const double spacing24 = 96.0;  // 6rem
  static const double spacing32 = 128.0; // 8rem

  // ==================== BORDER RADIUS - SOFT GEOMETRY ====================
  /// Everything is slightly rounded (6px minimum) - friendly and approachable

  static const double radiusXs = 6.0;     // Badges, tiny chips
  static const double radiusSm = 10.0;    // Buttons, inputs, chips
  static const double radiusMd = 14.0;    // Cards, medium components
  static const double radiusLg = 20.0;    // Large cards, modals
  static const double radiusXl = 28.0;    // Hero cards, feature images
  static const double radius2xl = 36.0;   // Extra large images
  static const double radiusFull = 9999.0; // Avatars, pills

  // ==================== ELEVATION - FLOATING ELEMENTS ====================

  /// Extra small shadow - subtle hover, slight depth
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0D0F1419),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Small shadow - cards at rest
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  /// Medium shadow - dropdowns, popovers
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// Large shadow - modals, sheets
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// Extra large shadow - dialogs, overlays
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x1A0F1419),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  /// 2XL shadow - maximum elevation
  static const List<BoxShadow> shadow2xl = [
    BoxShadow(
      color: Color(0x400F1419),
      offset: Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
  ];

  /// Signature sapphire glow - primary CTAs, active elements
  static final List<BoxShadow> sapphireGlow = [
    BoxShadow(
      color: sapphire600.withValues(alpha: 0.05),
      offset: const Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: sapphire600.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
    BoxShadow(
      color: sapphire600.withValues(alpha: 0.2),
      offset: const Offset(0, 8),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];

  /// Sunrise glow - special actions, highlights
  static final List<BoxShadow> sunriseGlow = [
    BoxShadow(
      color: sunriseOrange.withValues(alpha: 0.05),
      offset: const Offset(0, 0),
      blurRadius: 0,
      spreadRadius: 1,
    ),
    BoxShadow(
      color: sunriseOrange.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
    BoxShadow(
      color: sunriseOrange.withValues(alpha: 0.2),
      offset: const Offset(0, 8),
      blurRadius: 32,
      spreadRadius: -4,
    ),
  ];

  // ==================== LIGHT THEME ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme - Sapphire Sunset
      colorScheme: const ColorScheme(
        brightness: Brightness.light,

        // Primary - Sapphire
        primary: sapphire600,
        onPrimary: Colors.white,
        primaryContainer: sapphire100,
        onPrimaryContainer: sapphire900,
        primaryFixed: sapphire100,
        primaryFixedDim: sapphire200,
        onPrimaryFixed: sapphire900,
        onPrimaryFixedVariant: sapphire700,

        // Secondary - Sunrise Orange
        secondary: sunriseOrange,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFE8DD),
        onSecondaryContainer: Color(0xFF8C3D1A),
        secondaryFixed: Color(0xFFFFE8DD),
        secondaryFixedDim: Color(0xFFFFD4BB),
        onSecondaryFixed: Color(0xFF8C3D1A),
        onSecondaryFixedVariant: Color(0xFFCC5C39),

        // Tertiary - Sunset Gold
        tertiary: sunsetGold,
        onTertiary: ink,
        tertiaryContainer: Color(0xFFFFF4D6),
        onTertiaryContainer: Color(0xFF8A6B00),
        tertiaryFixed: Color(0xFFFFF4D6),
        tertiaryFixedDim: Color(0xFFFFEBAA),
        onTertiaryFixed: Color(0xFF8A6B00),
        onTertiaryFixedVariant: Color(0xFFCC9524),

        // Error
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFFBA1A1A),

        // Surface & Background
        surface: snow,
        onSurface: ink,
        surfaceDim: mist,
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: sapphire50,
        surfaceContainer: cloud,
        surfaceContainerHigh: mist,
        surfaceContainerHighest: silver,
        onSurfaceVariant: charcoal,

        // Outline
        outline: silver,
        outlineVariant: cloud,

        // Shadow & Scrim
        shadow: Color(0x1A0F1419),
        scrim: Color(0x80000000),

        // Inverse
        inverseSurface: charcoal,
        onInverseSurface: snow,
        inversePrimary: sapphire400,
        surfaceTint: sapphire600,
      ),

      // Typography - Editorial Clarity
      textTheme: TextTheme(
        // Display - Crimson Pro (Serif for headlines)
        displayLarge: GoogleFonts.crimsonPro(
          fontSize: 72,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
          height: 1.1,
          color: ink,
        ),
        displayMedium: GoogleFonts.crimsonPro(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.15,
          color: ink,
        ),
        displaySmall: GoogleFonts.crimsonPro(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.2,
          color: ink,
        ),

        // Headlines - Crimson Pro
        headlineLarge: GoogleFonts.crimsonPro(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.25,
          color: ink,
        ),
        headlineMedium: GoogleFonts.crimsonPro(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: ink,
        ),
        headlineSmall: GoogleFonts.crimsonPro(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: ink,
        ),

        // Titles - Inter
        titleLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
          color: ink,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
          color: ink,
        ),

        // Body - Inter
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.6,
          color: charcoal,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.5,
          color: charcoal,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.5,
          color: slate,
        ),

        // Labels - Inter
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.4,
          color: ink,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: ink,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.3,
          color: ink,
        ),
      ),

      // Scaffold
      scaffoldBackgroundColor: snow,

      // AppBar Theme - Clean with backdrop blur
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.crimsonPro(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: ink,
        ),
        iconTheme: const IconThemeData(
          color: ink,
          size: 24,
        ),
      ),

      // Card Theme - Soft elevation
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x1A0F1419),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
          side: BorderSide(
            color: Color(0x0A000000),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme - Sapphire with glow
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing6,
            vertical: spacing3,
          ),
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusSm)),
          ),
          backgroundColor: sapphire600,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          shadowColor: sapphire600,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.white.withValues(alpha: 0.1);
              }
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.2);
              }
              return null;
            },
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: sapphire600,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing6,
            vertical: spacing3,
          ),
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusSm)),
          ),
          side: const BorderSide(color: sapphire600, width: 2),
          foregroundColor: sapphire600,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration Theme - Clean and accessible
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: silver, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: silver, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: sapphire600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: slate,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: sapphire600,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: stone.withValues(alpha: 0.6),
        ),
        helperStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: slate,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: error,
        ),
      ),

      // Floating Action Button Theme - Sapphire with glow
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: sapphire600,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
        ),
      ),

      // Chip Theme - Soft sapphire background
      chipTheme: ChipThemeData(
        backgroundColor: sapphire100,
        deleteIconColor: sapphire700,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: sapphire700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusXs)),
        ),
      ),

      // Bottom Navigation Bar Theme - Clean with sapphire accents
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: sapphire600,
        unselectedItemColor: stone,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: sapphire100,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sapphire600,
              );
            }
            return GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: stone,
            );
          },
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: sapphire600,
                size: 26,
              );
            }
            return const IconThemeData(
              color: stone,
              size: 26,
            );
          },
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: cloud,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: charcoal,
        size: 24,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.crimsonPro(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: slate,
          height: 1.6,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink.withValues(alpha: 0.96),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusSm)),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: sapphire600,
        linearTrackColor: sapphire100,
        circularTrackColor: sapphire100,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return sapphire600;
            }
            return stone;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return sapphire300;
            }
            return cloud;
          },
        ),
      ),
    );
  }

  // Dark theme placeholder - Future implementation
  static ThemeData get darkTheme {
    // Will implement in Phase 2
    return lightTheme;
  }
}
