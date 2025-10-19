import 'package:flutter/material.dart';
import 'app_theme.dart';

/// App theme variations - Modern, glossy themes from global leaders
enum AppThemeType {
  midnight,     // Dark elegant (Apple-inspired)
  ocean,        // Modern blue (Google-inspired)
  sunset,       // Warm gradient (Instagram-inspired)
  forest,       // Natural green (Spotify-inspired)
  lavender,     // Soft purple (Notion-inspired)
  rose,         // Elegant pink (Airbnb-inspired)
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
  final LinearGradient glossyGradient;      // NEW: Multi-stop glossy gradient
  final LinearGradient headerGradient;      // NEW: Rich header gradient
  final LinearGradient backgroundGradient;  // NEW: Subtle background gradient
  final List<BoxShadow> primaryShadow;
  final List<BoxShadow> glossyShadow;       // NEW: Enhanced glossy shadow
  final IconData icon;
  final Color accentColor;

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
  });

  /// Get theme data for a specific theme type
  static AppThemeData getThemeData(AppThemeType type) {
    switch (type) {
      case AppThemeType.midnight:
        return _midnight;
      case AppThemeType.ocean:
        return _ocean;
      case AppThemeType.sunset:
        return _sunset;
      case AppThemeType.forest:
        return _forest;
      case AppThemeType.lavender:
        return _lavender;
      case AppThemeType.rose:
        return _rose;
    }
  }

  // Theme 1: Midnight - Dark Elegant (Apple-inspired)
  static const AppThemeData _midnight = AppThemeData(
    name: 'Midnight',
    description: 'Elegant dark slate with premium feel',
    primaryColor: Color(0xFF1E293B),
    primaryDeep: Color(0xFF0F172A),
    primaryLight: Color(0xFF475569),
    primaryPale: Color(0xFFE2E8F0),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF0F172A),  // Deep midnight
        Color(0xFF475569),  // Light slate highlight
        Color(0xFF1E293B),  // Medium slate
        Color(0xFF0F172A),  // Back to deep
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [
        Color(0xFF1E293B),  // Slate
        Color(0xFF3B82F6),  // Blue accent
        Color(0xFF0F172A),  // Deep midnight
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFF8FAFC),  // Soft white
        Color(0xFFFFFFFF),  // Pure white
        Color(0xFFE2E8F0),  // Pale slate tint
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x401E293B),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x661E293B),  // 40% opacity
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 12),
      ),
    ],
    icon: Icons.nightlight_round,
    accentColor: Color(0xFF3B82F6),
  );

  // Theme 2: Ocean - Modern Blue (Google Material-inspired)
  static const AppThemeData _ocean = AppThemeData(
    name: 'Ocean',
    description: 'Modern blue with clean aesthetics',
    primaryColor: Color(0xFF0EA5E9),
    primaryDeep: Color(0xFF0284C7),
    primaryLight: Color(0xFF38BDF8),
    primaryPale: Color(0xFFE0F2FE),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF0284C7),  // Deep ocean
        Color(0xFF38BDF8),  // Bright aqua highlight
        Color(0xFF06B6D4),  // Cyan accent
        Color(0xFF0EA5E9),  // Sky blue
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [
        Color(0xFF0EA5E9),  // Sky blue
        Color(0xFF06B6D4),  // Cyan accent
        Color(0xFF0284C7),  // Deep ocean
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFF0F9FF),  // Lightest blue
        Color(0xFFFFFFFF),  // Pure white
        Color(0xFFE0F2FE),  // Pale sky
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x400EA5E9),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x700EA5E9),  // 44% opacity
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 12),
      ),
    ],
    icon: Icons.water_drop,
    accentColor: Color(0xFF06B6D4),
  );

  // Theme 3: Sunset - Warm Gradient (Instagram-inspired)
  static const AppThemeData _sunset = AppThemeData(
    name: 'Sunset',
    description: 'Vibrant warm tones with energy',
    primaryColor: Color(0xFFF97316),
    primaryDeep: Color(0xFFEA580C),
    primaryLight: Color(0xFFFB923C),
    primaryPale: Color(0xFFFFEDD5),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFFEA580C),  // Deep orange
        Color(0xFFFBBF24),  // Golden yellow highlight
        Color(0xFFFB923C),  // Bright orange
        Color(0xFFF97316),  // Sunset orange
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [
        Color(0xFFF97316),  // Sunset orange
        Color(0xFFFBBF24),  // Golden accent
        Color(0xFFEA580C),  // Deep orange
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFFF7ED),  // Soft peach
        Color(0xFFFFFFFF),  // Pure white
        Color(0xFFFFEDD5),  // Pale sunset
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x40F97316),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x70F97316),  // 44% opacity
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 12),
      ),
    ],
    icon: Icons.wb_twilight,
    accentColor: Color(0xFFFBBF24),
  );

  // Theme 4: Forest - Natural Green (Spotify-inspired)
  static const AppThemeData _forest = AppThemeData(
    name: 'Forest',
    description: 'Fresh green with natural harmony',
    primaryColor: Color(0xFF10B981),
    primaryDeep: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    primaryPale: Color(0xFFD1FAE5),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF059669),  // Deep forest
        Color(0xFF34D399),  // Bright mint highlight
        Color(0xFF14B8A6),  // Teal accent
        Color(0xFF10B981),  // Emerald green
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [
        Color(0xFF10B981),  // Emerald green
        Color(0xFF14B8A6),  // Teal accent
        Color(0xFF059669),  // Deep forest
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFECFDF5),  // Lightest mint
        Color(0xFFFFFFFF),  // Pure white
        Color(0xFFD1FAE5),  // Pale green
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4010B981),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x7010B981),  // 44% opacity
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 12),
      ),
    ],
    icon: Icons.eco,
    accentColor: Color(0xFF14B8A6),
  );

  // Theme 5: Lavender - Soft Purple (Notion-inspired)
  static const AppThemeData _lavender = AppThemeData(
    name: 'Lavender',
    description: 'Calm purple with sophistication',
    primaryColor: Color(0xFF8B5CF6),
    primaryDeep: Color(0xFF7C3AED),
    primaryLight: Color(0xFFA78BFA),
    primaryPale: Color(0xFFEDE9FE),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFF7C3AED),  // Deep violet
        Color(0xFFA78BFA),  // Light lavender highlight
        Color(0xFFC084FC),  // Bright purple accent
        Color(0xFF8B5CF6),  // Medium purple
      ],
      stops: [0.0, 0.3, 0.65, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [
        Color(0xFF8B5CF6),  // Violet
        Color(0xFFC084FC),  // Light purple accent
        Color(0xFF7C3AED),  // Deep violet
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFF5F3FF),  // Lightest lavender
        Color(0xFFFFFFFF),  // Pure white
        Color(0xFFEDE9FE),  // Pale purple
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x408B5CF6),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x708B5CF6),  // 44% opacity
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 12),
      ),
    ],
    icon: Icons.auto_awesome,
    accentColor: Color(0xFFC084FC),
  );

  // Theme 6: Rose - Elegant Pink (Airbnb-inspired)
  static const AppThemeData _rose = AppThemeData(
    name: 'Rose',
    description: 'Elegant rose with warmth',
    primaryColor: Color(0xFFEC4899),
    primaryDeep: Color(0xFFDB2777),
    primaryLight: Color(0xFFF472B6),
    primaryPale: Color(0xFFFCE7F3),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glossyGradient: LinearGradient(
      colors: [
        Color(0xFFDB2777),  // Deep rose
        Color(0xFFF472B6),  // Light pink highlight
        Color(0xFFF9A8D4),  // Soft pink accent
        Color(0xFFEC4899),  // Hot pink
      ],
      stops: [0.0, 0.3, 0.65, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [
        Color(0xFFEC4899),  // Hot pink
        Color(0xFFF9A8D4),  // Soft pink accent
        Color(0xFFDB2777),  // Deep rose
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFDF2F8),  // Lightest pink
        Color(0xFFFFFFFF),  // Pure white
        Color(0xFFFCE7F3),  // Pale rose
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x40EC4899),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    glossyShadow: [
      BoxShadow(
        color: Color(0x70EC4899),  // 44% opacity
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 12),
      ),
    ],
    icon: Icons.favorite_rounded,
    accentColor: Color(0xFFF9A8D4),
  );

  /// Generate Flutter ThemeData from AppThemeData with glassmorphism
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        onPrimary: Colors.white,
        secondary: accentColor,
        secondaryContainer: primaryPale,
        surface: Colors.white,
        onSurface: AppTheme.neutral900,
        error: AppTheme.error,
        tertiary: primaryDeep,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
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

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.neutral200,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(
            color: AppTheme.neutral200,
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
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        color: Colors.white,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppTheme.neutral400,
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
        backgroundColor: primaryPale,
        selectedColor: primaryColor,
        disabledColor: AppTheme.neutral100,
        labelStyle: TextStyle(
          color: primaryDeep,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
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
        linearTrackColor: primaryPale,
        circularTrackColor: primaryPale,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppTheme.neutral50,
    );
  }
}
