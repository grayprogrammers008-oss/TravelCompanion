import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌟 TRAVEL CREW - ELITE DESIGN SYSTEM 🌟
///
/// A breathtaking, world-class design language that creates an immediate
/// emotional connection. Inspired by luxury travel, boutique hotels,
/// and premium lifestyle apps. Every pixel crafted to perfection.
///
/// Design Philosophy:
/// - PREMIUM: Luxury feel with sophisticated aesthetics
/// - WANDERLUST: Evokes excitement and adventure
/// - INTUITIVE: Effortless, delightful interactions
/// - MEMORABLE: Users remember and crave this experience

class AppTheme {
  // ==================== ELITE COLOR PALETTE ====================
  // Inspired by tropical destinations, luxury resorts, and wanderlust

  // Primary Brand Colors - Tropical Teal Paradise
  static const Color primaryTeal = Color(0xFF00B8A9);      // Vibrant tropical waters
  static const Color primaryDeep = Color(0xFF008C7D);      // Deep ocean depths
  static const Color primaryLight = Color(0xFF4DD4C6);     // Shallow lagoon
  static const Color primaryPale = Color(0xFFE0F7F5);      // Misty morning shore

  // Accent Colors - Sunset & Adventure
  static const Color accentCoral = Color(0xFFFF6B9D);      // Tropical sunset
  static const Color accentGold = Color(0xFFFFC145);       // Golden hour
  static const Color accentPurple = Color(0xFF9B5DE5);     // Twilight magic
  static const Color accentOrange = Color(0xFFFF8A65);     // Sunset glow

  // Neutral Colors - Sophisticated & Premium
  static const Color neutral900 = Color(0xFF0F172A);       // Rich midnight
  static const Color neutral800 = Color(0xFF1E293B);       // Slate darkness
  static const Color neutral700 = Color(0xFF334155);       // Storm cloud
  static const Color neutral600 = Color(0xFF475569);       // Slate gray
  static const Color neutral500 = Color(0xFF64748B);       // Cool gray
  static const Color neutral400 = Color(0xFF94A3B8);       // Soft gray
  static const Color neutral300 = Color(0xFFCBD5E1);       // Light mist
  static const Color neutral200 = Color(0xFFE2E8F0);       // Pale cloud
  static const Color neutral100 = Color(0xFFF1F5F9);       // Almost white
  static const Color neutral50 = Color(0xFFF8FAFC);        // Pure light

  // Semantic Colors - Status & Feedback
  static const Color success = Color(0xFF10B981);          // Emerald success
  static const Color warning = Color(0xFFF59E0B);          // Amber warning
  static const Color error = Color(0xFFEF4444);            // Rose error
  static const Color info = Color(0xFF3B82F6);             // Blue info

  // ==================== PREMIUM GRADIENTS ====================
  // Breathtaking gradients that create visual depth

  // Primary Brand Gradient - Tropical Paradise
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B8A9), Color(0xFF008C7D)],
    stops: [0.0, 1.0],
  );

  // Sunset Dream - Magical hour
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B9D), Color(0xFFFFC145), Color(0xFFFF8A65)],
    stops: [0.0, 0.6, 1.0],
  );

  // Ocean Deep - Mysterious waters
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B8A9), Color(0xFF3B82F6)],
    stops: [0.0, 1.0],
  );

  // Twilight Magic - Purple dreams
  static const LinearGradient twilightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B5DE5), Color(0xFFFF6B9D)],
    stops: [0.0, 1.0],
  );

  // Glass Morphism - Modern premium feel
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x1AFFFFFF),
    ],
  );

  // Shimmer Effect - Loading elegance
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Color(0xFFE2E8F0),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ==================== SPACING SYSTEM ====================

  static const double spacing2xs = 4.0;
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2xl = 48.0;
  static const double spacing3xl = 64.0;

  // ==================== BORDER RADIUS ====================

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radius2xl = 32.0;
  static const double radiusFull = 9999.0;

  // ==================== SHADOWS ====================

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 10),
      blurRadius: 24,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x24000000),
      offset: Offset(0, 20),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  // Colored shadows for premium effect
  static final List<BoxShadow> shadowTeal = [
    BoxShadow(
      color: primaryTeal.withValues(alpha: 0.3),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static final List<BoxShadow> shadowCoral = [
    BoxShadow(
      color: accentCoral.withValues(alpha: 0.3),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  // Legacy color names for backwards compatibility
  @Deprecated('Use primaryTeal instead')
  static const Color primaryColor = primaryTeal;
  @Deprecated('Use accentCoral instead')
  static const Color secondaryColor = accentCoral;
  @Deprecated('Use primaryTeal instead')
  static const Color accentColor = primaryTeal;
  @Deprecated('Use neutral50 instead')
  static const Color backgroundColor = neutral50;
  @Deprecated('Use Colors.white instead')
  static const Color surfaceColor = Colors.white;
  @Deprecated('Use error instead')
  static const Color errorColor = error;
  @Deprecated('Use neutral900 instead')
  static const Color textPrimary = neutral900;
  @Deprecated('Use neutral600 instead')
  static const Color textSecondary = neutral600;
  @Deprecated('Use neutral400 instead')
  static const Color textLight = neutral400;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryTeal,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE0F7F5),
        onPrimaryContainer: primaryDeep,
        secondary: accentCoral,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFE8EE),
        onSecondaryContainer: Color(0xFFB91D5C),
        tertiary: accentGold,
        onTertiary: neutral900,
        tertiaryContainer: Color(0xFFFFF4D6),
        onTertiaryContainer: Color(0xFF8A6B00),
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFFBA1A1A),
        surface: neutral50,
        onSurface: neutral900,
        surfaceContainerHighest: neutral100,
        onSurfaceVariant: neutral700,
        outline: neutral300,
        outlineVariant: neutral200,
        shadow: Color(0x1A000000),
        scrim: Color(0x80000000),
        inverseSurface: neutral800,
        onInverseSurface: neutral50,
        inversePrimary: Color(0xFF5DDFD0),
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 57,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          height: 1.1,
          color: neutral900,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: neutral900,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.2,
          color: neutral900,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.25,
          color: neutral900,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: neutral900,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.3,
          color: neutral900,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
          color: neutral900,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          height: 1.5,
          color: neutral900,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
          color: neutral900,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.6,
          color: neutral700,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.5,
          color: neutral700,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.4,
          color: neutral600,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.4,
          color: neutral900,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.3,
          color: neutral900,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.3,
          color: neutral900,
        ),
      ),

      // Scaffold
      scaffoldBackgroundColor: neutral50,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: neutral50,
        foregroundColor: neutral900,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: neutral900,
        ),
        iconTheme: const IconThemeData(
          color: neutral900,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
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
            horizontal: spacingLg,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: neutral300, width: 1.5),
          foregroundColor: neutral900,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: neutral200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: neutral200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: neutral600,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryTeal,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: neutral400,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: neutral100,
        deleteIconColor: neutral600,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: neutral900,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryTeal,
        unselectedItemColor: neutral400,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: neutral700,
        size: 24,
      ),
    );
  }

  // Dark Theme (for future use)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: accentCoral,
        tertiary: accentGold,
        error: error,
      ),
    );
  }
}
