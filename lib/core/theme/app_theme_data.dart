import 'package:flutter/material.dart';
import 'app_theme.dart';

/// App theme variations with different color schemes
enum AppThemeType {
  tropicalTeal, // Original - Tropical paradise (Teal)
  sunsetOrange, // Warm sunset vibes (Orange/Coral)
  oceanBlue, // Deep ocean (Blue)
  forestGreen, // Nature/Adventure (Green)
  royalPurple, // Luxury (Purple)
  cherryRed, // Passionate travel (Red/Pink)
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
  final List<BoxShadow> primaryShadow;
  final IconData icon;

  const AppThemeData({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.primaryDeep,
    required this.primaryLight,
    required this.primaryPale,
    required this.primaryGradient,
    required this.primaryShadow,
    required this.icon,
  });

  /// Get theme data for a specific theme type
  static AppThemeData getThemeData(AppThemeType type) {
    switch (type) {
      case AppThemeType.tropicalTeal:
        return _tropicalTeal;
      case AppThemeType.sunsetOrange:
        return _sunsetOrange;
      case AppThemeType.oceanBlue:
        return _oceanBlue;
      case AppThemeType.forestGreen:
        return _forestGreen;
      case AppThemeType.royalPurple:
        return _royalPurple;
      case AppThemeType.cherryRed:
        return _cherryRed;
    }
  }

  // Theme 1: Tropical Teal (Original)
  static const AppThemeData _tropicalTeal = AppThemeData(
    name: 'Tropical Teal',
    description: 'Vibrant tropical waters and paradise beaches',
    primaryColor: Color(0xFF00B8A9),
    primaryDeep: Color(0xFF008C7D),
    primaryLight: Color(0xFF4DD4C6),
    primaryPale: Color(0xFFE0F7F5),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00B8A9), Color(0xFF008C7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4D00B8A9), // 30% opacity
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.waves,
  );

  // Theme 2: Sunset Orange
  static const AppThemeData _sunsetOrange = AppThemeData(
    name: 'Sunset Orange',
    description: 'Warm golden hour and tropical sunsets',
    primaryColor: Color(0xFFFF8A65),
    primaryDeep: Color(0xFFE64A19),
    primaryLight: Color(0xFFFFAB91),
    primaryPale: Color(0xFFFFE5DD),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4DFF8A65),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.wb_sunny,
  );

  // Theme 3: Ocean Blue
  static const AppThemeData _oceanBlue = AppThemeData(
    name: 'Ocean Blue',
    description: 'Deep ocean depths and clear skies',
    primaryColor: Color(0xFF1E88E5),
    primaryDeep: Color(0xFF0D47A1),
    primaryLight: Color(0xFF64B5F6),
    primaryPale: Color(0xFFE3F2FD),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4D1E88E5),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.water,
  );

  // Theme 4: Forest Green
  static const AppThemeData _forestGreen = AppThemeData(
    name: 'Forest Green',
    description: 'Nature adventures and mountain escapes',
    primaryColor: Color(0xFF43A047),
    primaryDeep: Color(0xFF1B5E20),
    primaryLight: Color(0xFF76D275),
    primaryPale: Color(0xFFE8F5E9),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4D43A047),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.forest,
  );

  // Theme 5: Royal Purple
  static const AppThemeData _royalPurple = AppThemeData(
    name: 'Royal Purple',
    description: 'Luxury travel and premium experiences',
    primaryColor: Color(0xFF7E57C2),
    primaryDeep: Color(0xFF4A148C),
    primaryLight: Color(0xFF9575CD),
    primaryPale: Color(0xFFF3E5F5),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF7E57C2), Color(0xFF4A148C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4D7E57C2),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.diamond,
  );

  // Theme 6: Cherry Red
  static const AppThemeData _cherryRed = AppThemeData(
    name: 'Cherry Red',
    description: 'Passionate wanderlust and vibrant journeys',
    primaryColor: Color(0xFFE91E63),
    primaryDeep: Color(0xFFC2185B),
    primaryLight: Color(0xFFF06292),
    primaryPale: Color(0xFFFCE4EC),
    primaryGradient: LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    primaryShadow: [
      BoxShadow(
        color: Color(0x4DE91E63),
        blurRadius: 24,
        spreadRadius: 0,
        offset: Offset(0, 8),
      ),
    ],
    icon: Icons.favorite,
  );

  /// Generate Flutter ThemeData from AppThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        onPrimary: Colors.white,
        secondary: primaryDeep,
        secondaryContainer: primaryPale,
        surface: Colors.white,
        onSurface: AppTheme.neutral900,
        error: AppTheme.error,
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

      // Scaffold Background
      scaffoldBackgroundColor: AppTheme.neutral50,
    );
  }
}
