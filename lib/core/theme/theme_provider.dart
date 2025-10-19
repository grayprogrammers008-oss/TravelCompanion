import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_data.dart';

part 'theme_provider.g.dart';

/// Theme notifier that persists theme selection
@riverpod
class Theme extends _$Theme {
  static const String _themeKey = 'selected_theme';

  @override
  AppThemeType build() {
    // Load saved theme asynchronously
    _loadTheme();
    return AppThemeType.tropicalTeal; // Default theme
  }

  /// Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);

      if (themeName != null) {
        final themeType = AppThemeType.values.firstWhere(
          (t) => t.name == themeName,
          orElse: () => AppThemeType.tropicalTeal,
        );
        state = themeType;
      }
    } catch (e) {
      // If error loading theme, keep default
      state = AppThemeType.tropicalTeal;
    }
  }

  /// Change theme and persist to SharedPreferences
  Future<void> setTheme(AppThemeType themeType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeType.name);
      state = themeType;
    } catch (e) {
      // If error saving, still change the theme in memory
      state = themeType;
    }
  }

  /// Get current theme data
  AppThemeData get currentThemeData => AppThemeData.getThemeData(state);
}

/// Provider for current theme data
@riverpod
AppThemeData currentThemeData(Ref ref) {
  final themeType = ref.watch(themeProvider);
  return AppThemeData.getThemeData(themeType);
}
