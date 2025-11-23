import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌟 BRILLIANT THEME SYSTEM 🌟
///
/// A stunning, vibrant design system inspired by Fitonist's playful 3D aesthetic
/// Features bold gradients, playful colors, and modern rounded design
///
/// Design Philosophy:
/// - VIBRANT: Bold, energetic colors that excite
/// - PLAYFUL: Rounded corners and friendly interactions
/// - MODERN: Contemporary 3D-inspired aesthetics
/// - JOYFUL: Makes users smile and feel energized

class BrilliantTheme {
  // ==================== VIBRANT COLOR PALETTE ====================
  // Inspired by sunsets, candy, neon lights, and tropical paradise

  // Primary Purple Spectrum - The Star of the Show
  static const Color electricPurple = Color(0xFF7B5FE8);      // Main brand - Vibrant & Bold
  static const Color lavenderDream = Color(0xFFC8B8FF);       // Light purple - Soft & Dreamy
  static const Color deepViolet = Color(0xFF5234B8);          // Dark purple - Rich & Deep
  static const Color purpleMist = Color(0xFFEFE9FF);          // Container - Subtle & Elegant

  // Candy Pink Spectrum - Sweet & Playful
  static const Color candyPink = Color(0xFFFF88CC);           // Main pink - Sweet & Fun
  static const Color rosyBlush = Color(0xFFFFB8E6);           // Light pink - Gentle & Soft
  static const Color hotPink = Color(0xFFE64D9C);             // Dark pink - Bold & Energetic
  static const Color pinkSugar = Color(0xFFFFE8F5);           // Container - Delicate bg

  // Sky Blue Spectrum - Cool & Refreshing
  static const Color skyBlue = Color(0xFFA8D8FF);             // Main blue - Airy & Light
  static const Color cloudWhite = Color(0xFFD4ECFF);          // Light blue - Crisp & Clean
  static const Color oceanBlue = Color(0xFF6BA8E8);           // Dark blue - Deep & Cool
  static const Color icyBlue = Color(0xFFE8F4FF);             // Container - Fresh bg

  // Sunset Spectrum - Warm & Inviting
  static const Color sunsetPeach = Color(0xFFFFB8A8);         // Main peach - Warm & Cozy
  static const Color softCoral = Color(0xFFFFD8CC);           // Light peach - Gentle warmth
  static const Color burntOrange = Color(0xFFFF8866);         // Dark peach - Vibrant glow
  static const Color peachCream = Color(0xFFFFEBE6);          // Container - Soft bg

  // Mint Green Spectrum - Fresh & Energetic
  static const Color mintFresh = Color(0xFF88FFDD);           // Main mint - Cool & Fresh
  static const Color mintLight = Color(0xFFB8FFEE);           // Light mint - Airy & Crisp
  static const Color emeraldMint = Color(0xFF4DE8BB);         // Dark mint - Rich & Vibrant
  static const Color mintCream = Color(0xFFE0FFF8);           // Container - Subtle bg

  // Sunshine Spectrum - Happy & Bright
  static const Color sunshineyellow = Color(0xFFFFE066);      // Main yellow - Bright & Happy
  static const Color lemonSorbet = Color(0xFFFFEE99);         // Light yellow - Soft glow
  static const Color goldenHour = Color(0xFFFFCC00);          // Dark yellow - Rich gold
  static const Color butterCream = Color(0xFFFFF8E0);         // Container - Warm bg

  // Electric Accents - Pop of Energy
  static const Color electricBlue = Color(0xFF00E5FF);        // Neon blue - High energy
  static const Color neonPink = Color(0xFFFF0080);            // Neon pink - Bold statement
  static const Color limeGreen = Color(0xFFCCFF00);           // Lime - Fresh pop
  static const Color hotMagenta = Color(0xFFFF00FF);          // Magenta - Maximum impact

  // Neutrals - Modern & Clean (with slight warmth)
  static const Color pearl = Color(0xFFFAFAFF);               // Almost white with purple tint
  static const Color cloud = Color(0xFFF4F4FF);               // Very light
  static const Color fog = Color(0xFFE8E8F8);                 // Light gray with purple
  static const Color stone = Color(0xFFD0D0E8);               // Soft gray
  static const Color slate = Color(0xFFA8A8C8);               // Medium light
  static const Color charcoal = Color(0xFF666688);            // Medium dark
  static const Color graphite = Color(0xFF4A4A68);            // Dark gray
  static const Color midnight = Color(0xFF2E2E48);            // Very dark
  static const Color obsidian = Color(0xFF1A1A38);            // Almost black

  // Semantic Colors - Friendly & Approachable
  static const Color successGreen = Color(0xFF10D89E);        // Bright success
  static const Color warningAmber = Color(0xFFFFB84D);        // Warm warning
  static const Color errorRed = Color(0xFFFF6B6B);            // Friendly error
  static const Color infoBlue = Color(0xFF4D9FFF);            // Helpful info

  // ==================== BREATHTAKING GRADIENTS ====================

  // Purple Power - Main brand gradient
  static const LinearGradient purplePower = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricPurple, deepViolet],
    stops: [0.0, 1.0],
  );

  // Candy Crush - Sweet pink to purple
  static const LinearGradient candyCrush = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [candyPink, electricPurple],
    stops: [0.0, 1.0],
  );

  // Sunset Paradise - 3-color warm blend
  static const LinearGradient sunsetParadise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunsetPeach, candyPink, electricPurple],
    stops: [0.0, 0.5, 1.0],
  );

  // Ocean Breeze - Cool blue to purple
  static const LinearGradient oceanBreeze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, electricPurple],
    stops: [0.0, 1.0],
  );

  // Mint Magic - Fresh green to purple
  static const LinearGradient mintMagic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintFresh, electricPurple],
    stops: [0.0, 1.0],
  );

  // Rainbow Dreams - 4-color spectrum
  static const LinearGradient rainbowDreams = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, lavenderDream, rosyBlush, softCoral],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  // Neon Nights - Electric vibes
  static const LinearGradient neonNights = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, neonPink, hotMagenta],
    stops: [0.0, 0.5, 1.0],
  );

  // Tropical Vibes - Warm paradise
  static const LinearGradient tropicalVibes = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunshineyellow, sunsetPeach, candyPink],
    stops: [0.0, 0.5, 1.0],
  );

  // Fresh Morning - Cool awakening
  static const LinearGradient freshMorning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mintFresh, skyBlue, lavenderDream],
    stops: [0.0, 0.5, 1.0],
  );

  // Glass Morphism - Frosted overlay
  static const LinearGradient glassMorph = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x20FFFFFF),
    ],
  );

  // ==================== DESIGN SYSTEM ====================

  // Spacing - Generous & Breathing
  static const double space2xs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  static const double space3xl = 64.0;
  static const double space4xl = 96.0;

  // Border Radius - Playfully Rounded
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radius2xl = 40.0;
  static const double radius3xl = 48.0;
  static const double radiusFull = 9999.0;

  // Shadows - Depth & Dimension
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x12000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x18000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x22000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x28000000),
      offset: Offset(0, 16),
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ];

  // Colored Shadows - 3D Floating Effect
  static final List<BoxShadow> shadowPurple = [
    BoxShadow(
      color: electricPurple.withValues(alpha: 0.35),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static final List<BoxShadow> shadowPink = [
    BoxShadow(
      color: candyPink.withValues(alpha: 0.35),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static final List<BoxShadow> shadowBlue = [
    BoxShadow(
      color: skyBlue.withValues(alpha: 0.35),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static final List<BoxShadow> shadowMint = [
    BoxShadow(
      color: mintFresh.withValues(alpha: 0.35),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static final List<BoxShadow> shadowNeon = [
    BoxShadow(
      color: neonPink.withValues(alpha: 0.4),
      offset: const Offset(0, 8),
      blurRadius: 28,
      spreadRadius: -2,
    ),
  ];

  // ==================== BRILLIANT LIGHT THEME ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme - Vibrant & Energetic
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: electricPurple,
        onPrimary: Colors.white,
        primaryContainer: purpleMist,
        onPrimaryContainer: deepViolet,
        secondary: candyPink,
        onSecondary: Colors.white,
        secondaryContainer: pinkSugar,
        onSecondaryContainer: hotPink,
        tertiary: sunshineyellow,
        onTertiary: graphite,
        tertiaryContainer: butterCream,
        onTertiaryContainer: Color(0xFF8A6B00),
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDADA),
        onErrorContainer: Color(0xFFBA1A1A),
        surface: pearl,
        onSurface: obsidian,
        surfaceContainerHighest: cloud,
        onSurfaceVariant: charcoal,
        outline: stone,
        outlineVariant: fog,
        shadow: Color(0x1A000000),
        scrim: Color(0x80000000),
        inverseSurface: midnight,
        onInverseSurface: pearl,
        inversePrimary: lavenderDream,
      ),

      // Typography - Modern & Bold
      textTheme: TextTheme(
        // Display - Extra bold for maximum impact
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          letterSpacing: -2.0,
          height: 1.0,
          color: obsidian,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 45,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          height: 1.1,
          color: obsidian,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: obsidian,
        ),

        // Headlines - Bold & Friendly
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.25,
          color: obsidian,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.3,
          color: obsidian,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.3,
          color: obsidian,
        ),

        // Titles - Clean & Modern
        titleLarge: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1.4,
          color: obsidian,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
          height: 1.5,
          color: obsidian,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          height: 1.4,
          color: obsidian,
        ),

        // Body - Readable & Friendly
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.6,
          color: charcoal,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.5,
          color: charcoal,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.4,
          color: slate,
        ),

        // Labels - Bold & Clear
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          height: 1.4,
          color: obsidian,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.3,
          color: obsidian,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.3,
          color: obsidian,
        ),
      ),

      // Scaffold
      scaffoldBackgroundColor: pearl,

      // AppBar - Clean & Minimal
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: pearl,
        foregroundColor: obsidian,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          color: obsidian,
        ),
        iconTheme: const IconThemeData(
          color: obsidian,
          size: 24,
        ),
      ),

      // Cards - Rounded & Elevated
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x18000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),  // 32dp!
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons - Bold & Rounded
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),  // Extra rounded!
          ),
          backgroundColor: electricPurple,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,  // Extra bold!
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: electricPurple,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Outlined Buttons - Bold Border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          side: const BorderSide(color: electricPurple, width: 2.5),  // Thicker!
          foregroundColor: electricPurple,
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Fields - Rounded & Modern
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceLg,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: fog, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: fog, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: electricPurple, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: errorRed, width: 2.5),
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: slate,
        ),
        floatingLabelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: electricPurple,
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: slate,
        ),
      ),

      // Floating Action Button - Bold & Vibrant
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 12,
        backgroundColor: electricPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),

      // Chips - Fully Rounded Pills
      chipTheme: ChipThemeData(
        backgroundColor: purpleMist,
        deleteIconColor: charcoal,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: electricPurple,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: spaceSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),

      // Bottom Navigation - Modern & Bold
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: electricPurple,
        unselectedItemColor: slate,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: fog,
        thickness: 1,
        space: 1,
      ),

      // Icons
      iconTheme: const IconThemeData(
        color: charcoal,
        size: 24,
      ),
    );
  }

  // ==================== BRILLIANT DARK THEME ====================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: lavenderDream,
        onPrimary: obsidian,
        primaryContainer: deepViolet,
        onPrimaryContainer: lavenderDream,
        secondary: rosyBlush,
        onSecondary: obsidian,
        secondaryContainer: hotPink,
        onSecondaryContainer: rosyBlush,
        tertiary: lemonSorbet,
        onTertiary: obsidian,
        tertiaryContainer: Color(0xFF8A6B00),
        onTertiaryContainer: lemonSorbet,
        error: errorRed,
        onError: obsidian,
        errorContainer: Color(0xFF8B0000),
        onErrorContainer: Color(0xFFFFDADA),
        surface: obsidian,
        onSurface: pearl,
        surfaceContainerHighest: midnight,
        onSurfaceVariant: fog,
        outline: slate,
        outlineVariant: charcoal,
        shadow: Color(0x40000000),
        scrim: Color(0xC0000000),
        inverseSurface: cloud,
        onInverseSurface: obsidian,
        inversePrimary: electricPurple,
      ),

      scaffoldBackgroundColor: obsidian,

      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 57,
          fontWeight: FontWeight.w900,
          color: pearl,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: pearl,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: fog,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: obsidian,
        foregroundColor: pearl,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: pearl,
        ),
      ),

      cardTheme: CardThemeData(
        color: midnight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
    );
  }
}
