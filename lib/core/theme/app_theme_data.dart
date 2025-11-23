import 'package:flutter/material.dart';
import 'app_theme.dart';

/// App theme variations - Clean, professional themes inspired by world-class apps
/// Philosophy: SOLID COLORS ONLY. No gradients on buttons. Minimal shadows.
enum AppThemeType {
  ocean,      // Professional blue (Booking.com inspired)
  sunset,     // Warm coral (Airbnb inspired)
  emerald,    // Trustworthy green (Grab inspired)
  royal,      // Premium purple (Stripe inspired)
  lavender,   // Calming lavender (Meditation app inspired)
  blossom,    // Soft pink (Wellness app inspired)
  desert,     // Warm beige (Wellness app inspired)
  brilliant,  // Vibrant purple (Fitonist inspired) - NEW!
}

/// Theme data for each theme type
class AppThemeData {
  final String name;
  final String description;
  final Color primaryColor;
  final Color primaryDeep;
  final Color primaryLight;
  final Color primaryPale;
  final LinearGradient primaryGradient;
  final LinearGradient glossyGradient;
  final LinearGradient headerGradient;
  final LinearGradient backgroundGradient;
  final List<BoxShadow> primaryShadow;
  final List<BoxShadow> glossyShadow;
  final IconData icon;
  final Color accentColor;
  final bool isDark;  // NEW: Support for dark mode

  const AppThemeData({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.primaryDeep,
    required this.primaryLight,
    required this.primaryPale,
    required this.primaryGradient,
    required this.glossyGradient,
    required this.headerGradient,
    required this.backgroundGradient,
    required this.primaryShadow,
    required this.glossyShadow,
    required this.icon,
    required this.accentColor,
    this.isDark = false,
  });

  /// Get theme data for a specific theme type
  static AppThemeData getThemeData(AppThemeType type) {
    switch (type) {
      case AppThemeType.ocean:
        return _ocean;
      case AppThemeType.sunset:
        return _sunset;
      case AppThemeType.emerald:
        return _emerald;
      case AppThemeType.royal:
        return _royal;
      case AppThemeType.lavender:
        return _lavender;
      case AppThemeType.blossom:
        return _blossom;
      case AppThemeType.desert:
        return _desert;
      case AppThemeType.brilliant:
        return _brilliant;
    }
  }

  // ==================== LIGHT THEMES ====================

  /// Theme 1: Ocean Blue - Professional & Trustworthy (Booking.com inspired)
  static const AppThemeData _ocean = AppThemeData(
    name: 'Ocean Blue',
    description: 'Professional blue - Trust & reliability',
    primaryColor: Color(0xFF0066CC),      // Booking.com blue
    primaryDeep: Color(0xFF0052A3),       // Darker blue
    primaryLight: Color(0xFF3385D6),      // Lighter blue
    primaryPale: Color(0xFFE6F2FF),       // Very pale blue
    primaryGradient: LinearGradient(
      colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF0052A3),
        Color(0xFF0066CC),
        Color(0xFF3385D6),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFAFBFC),
        Color(0xFFFFFFFF),
        Color(0xFFF5F7FA),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x200066CC),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x300066CC),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.water_drop_rounded,
    accentColor: Color(0xFF00C48C),      // Success green
    isDark: false,
  );

  /// Theme 2: Sunset Coral - Warm & Inviting (Airbnb inspired)
  static const AppThemeData _sunset = AppThemeData(
    name: 'Sunset Coral',
    description: 'Warm coral - Friendly & welcoming',
    primaryColor: Color(0xFFFF385C),      // Airbnb pink/coral
    primaryDeep: Color(0xFFE31C5F),       // Darker coral
    primaryLight: Color(0xFFFF5A7C),      // Lighter coral
    primaryPale: Color(0xFFFFE8ED),       // Very pale pink
    primaryGradient: LinearGradient(
      colors: [Color(0xFFFF385C), Color(0xFFE31C5F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFFE31C5F),
        Color(0xFFFF385C),
        Color(0xFFFF5A7C),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFFF385C), Color(0xFFE31C5F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFFFAFB),
        Color(0xFFFFFFFF),
        Color(0xFFFFF5F7),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x20FF385C),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x30FF385C),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.wb_twilight_rounded,
    accentColor: Color(0xFFFFB400),       // Golden yellow accent
    isDark: false,
  );

  /// Theme 3: Emerald Green - Trustworthy & Fresh (Grab inspired)
  static const AppThemeData _emerald = AppThemeData(
    name: 'Emerald Green',
    description: 'Fresh green - Growth & harmony',
    primaryColor: Color(0xFF00B14F),      // Grab green
    primaryDeep: Color(0xFF009440),       // Darker green
    primaryLight: Color(0xFF00D963),      // Lighter green
    primaryPale: Color(0xFFE6F9EF),       // Very pale green
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00B14F), Color(0xFF009440)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF009440),
        Color(0xFF00B14F),
        Color(0xFF00D963),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF00B14F), Color(0xFF009440)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFAFDFB),
        Color(0xFFFFFFFF),
        Color(0xFFF5FAF7),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x2000B14F),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x3000B14F),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.eco_rounded,
    accentColor: Color(0xFF0066CC),       // Blue accent for variety
    isDark: false,
  );

  /// Theme 4: Royal Purple - Premium & Sophisticated (Stripe inspired)
  static const AppThemeData _royal = AppThemeData(
    name: 'Royal Purple',
    description: 'Premium purple - Elegant & sophisticated',
    primaryColor: Color(0xFF635BFF),      // Stripe purple
    primaryDeep: Color(0xFF5145E5),       // Darker purple
    primaryLight: Color(0xFF8B85FF),      // Lighter purple
    primaryPale: Color(0xFFEEEDFF),       // Very pale purple
    primaryGradient: LinearGradient(
      colors: [Color(0xFF635BFF), Color(0xFF5145E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF5145E5),
        Color(0xFF635BFF),
        Color(0xFF8B85FF),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF635BFF), Color(0xFF5145E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFBFBFF),
        Color(0xFFFFFFFF),
        Color(0xFFF7F7FF),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x20635BFF),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x30635BFF),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.auto_awesome_rounded,
    accentColor: Color(0xFF00D4FF),       // Cyan accent
    isDark: false,
  );

  /// Theme 5: Lavender Serenity - Calming & Peaceful (Meditation app inspired)
  static const AppThemeData _lavender = AppThemeData(
    name: 'Lavender Serenity',
    description: 'Calming lavender - Peace & mindfulness',
    primaryColor: Color(0xFF9B88ED),      // Soft lavender
    primaryDeep: Color(0xFF7E6BC9),       // Deeper lavender
    primaryLight: Color(0xFFB9A8F5),      // Lighter lavender
    primaryPale: Color(0xFFF3F0FF),       // Very pale lavender
    primaryGradient: LinearGradient(
      colors: [Color(0xFF9B88ED), Color(0xFFB9A8F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF7E6BC9),
        Color(0xFF9B88ED),
        Color(0xFFD4C8FF),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF9B88ED), Color(0xFFB9A8F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFDFCFF),
        Color(0xFFFFFFFF),
        Color(0xFFF8F6FF),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x209B88ED),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x309B88ED),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.spa_rounded,
    accentColor: Color(0xFFE0B3FF),       // Soft pink-purple accent
    isDark: false,
  );

  /// Theme 6: Blossom Pink - Soft & Gentle (Wellness app inspired)
  static const AppThemeData _blossom = AppThemeData(
    name: 'Blossom Pink',
    description: 'Soft pink - Gentle & nurturing',
    primaryColor: Color(0xFFE896D5),      // Soft pink
    primaryDeep: Color(0xFFD576C1),       // Deeper pink
    primaryLight: Color(0xFFF0B3E3),      // Lighter pink
    primaryPale: Color(0xFFFFF5FC),       // Very pale pink
    primaryGradient: LinearGradient(
      colors: [Color(0xFFE896D5), Color(0xFFF0B3E3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFFD576C1),
        Color(0xFFE896D5),
        Color(0xFFFFC8F2),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFE896D5), Color(0xFFF0B3E3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFFFDFE),
        Color(0xFFFFFFFF),
        Color(0xFFFFF8FC),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x20E896D5),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x30E896D5),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.favorite_rounded,
    accentColor: Color(0xFFFFB8E8),       // Bright pink accent
    isDark: false,
  );

  /// Theme 7: Desert Bloom - Warm & Peaceful (Wellness app inspired - 222.webp)
  static const AppThemeData _desert = AppThemeData(
    name: 'Desert Bloom',
    description: 'Warm beige - Calm & balanced',
    primaryColor: Color(0xFFD4A574),      // Warm tan/beige
    primaryDeep: Color(0xFFB88C5D),       // Deeper tan
    primaryLight: Color(0xFFE6C9A8),      // Lighter beige
    primaryPale: Color(0xFFF5E6DD),       // Very pale peach (from reference)
    primaryGradient: LinearGradient(
      colors: [Color(0xFFD4A574), Color(0xFFB88C5D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFFB88C5D),
        Color(0xFFD4A574),
        Color(0xFFE6C9A8),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFD4A574), Color(0xFFE6C9A8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFFFBF8),
        Color(0xFFFFFFFF),
        Color(0xFFF5E6DD),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x20D4A574),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x30D4A574),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.wb_sunny_rounded,
    accentColor: Color(0xFFC9A58D),       // Muted rose-tan accent
    isDark: false,
  );

  /// Theme 8: Brilliant - Vibrant & Playful (Fitonist inspired)
  static const AppThemeData _brilliant = AppThemeData(
    name: 'Brilliant',
    description: 'Vibrant purple - Energetic & playful',
    primaryColor: Color(0xFF7B5FE8),      // Electric purple (Fitonist)
    primaryDeep: Color(0xFF5234B8),       // Deep violet
    primaryLight: Color(0xFFC8B8FF),      // Lavender dream
    primaryPale: Color(0xFFEFE9FF),       // Purple mist
    primaryGradient: LinearGradient(
      colors: [Color(0xFF7B5FE8), Color(0xFF5234B8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF5234B8),
        Color(0xFF7B5FE8),
        Color(0xFFC8B8FF),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF7B5FE8), Color(0xFF5234B8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFAFAFF),
        Color(0xFFFFFFFF),
        Color(0xFFF4F4FF),
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x307B5FE8),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x407B5FE8),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
    icon: Icons.auto_awesome,
    accentColor: Color(0xFFFF88CC),       // Candy pink accent
    isDark: false,
  );


  /// Generate Flutter ThemeData from AppThemeData
  ThemeData toThemeData() {
    // Choose light or dark base theme
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : AppTheme.neutral50;
    final textColor = isDark ? const Color(0xFFF1F5F9) : AppTheme.neutral900; // Light text on dark
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral600;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        primaryContainer: isDark ? primaryPale.withValues(alpha: 0.2) : primaryLight,
        onPrimary: Colors.white, // Always white text on primary color
        onPrimaryContainer: isDark ? Colors.white : AppTheme.neutral900,
        secondary: accentColor,
        secondaryContainer: isDark ? accentColor.withValues(alpha: 0.2) : primaryPale,
        onSecondary: Colors.white, // Always white text on accent color
        onSecondaryContainer: isDark ? Colors.white : AppTheme.neutral900,
        surface: surfaceColor,
        onSurface: textColor, // Light text on dark surface
        surfaceContainerHighest: isDark ? const Color(0xFF334155) : AppTheme.neutral100,
        onSurfaceVariant: secondaryTextColor,
        outline: isDark ? const Color(0xFF475569) : AppTheme.neutral300,
        error: AppTheme.error,
        onError: Colors.white,
        tertiary: primaryDeep,
        onTertiary: Colors.white,
        inverseSurface: isDark ? Colors.white : AppTheme.neutral900,
        onInverseSurface: isDark ? AppTheme.neutral900 : Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundColor,

      // Text Theme - Proper colors for light/dark
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: secondaryTextColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
        bodySmall: TextStyle(color: secondaryTextColor),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: secondaryTextColor),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E293B) : primaryColor,
        foregroundColor: Colors.white, // Always white
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Always white
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Always white
        ),
      ),

      // Elevated Button Theme - SOLID COLOR ONLY (no gradients!)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // Always white text on colored button
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // Always white
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF475569) : AppTheme.neutral200,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF475569) : AppTheme.neutral200,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingMd,
        ),
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : AppTheme.neutral400,
          fontSize: 14,
        ),
        // Ensure input text is visible in dark mode
        floatingLabelStyle: TextStyle(
          color: primaryColor,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        color: surfaceColor,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? const Color(0xFF64748B) : AppTheme.neutral400,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? primaryPale.withValues(alpha: 0.3) : primaryPale,
        selectedColor: primaryColor,
        disabledColor: isDark ? const Color(0xFF1E293B) : AppTheme.neutral100,
        labelStyle: TextStyle(
          color: isDark ? Colors.white : primaryDeep,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: isDark ? AppTheme.neutral900 : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: isDark ? primaryPale.withValues(alpha: 0.3) : primaryPale,
        circularTrackColor: isDark ? primaryPale.withValues(alpha: 0.3) : primaryPale,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF334155) : AppTheme.neutral200,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
      ),

      // List Tile Theme - Fix dark mode text
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: secondaryTextColor,
          fontSize: 16,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}
