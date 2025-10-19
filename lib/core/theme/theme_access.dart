import 'package:flutter/material.dart';
import 'app_theme_data.dart';

/// InheritedWidget to provide AppThemeData throughout the widget tree
/// This allows any widget (not just ConsumerWidget) to access the current theme
class AppThemeProvider extends InheritedWidget {
  final AppThemeData themeData;

  const AppThemeProvider({
    super.key,
    required this.themeData,
    required super.child,
  });

  /// Access the current AppThemeData from any widget
  static AppThemeData of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppThemeProvider>();
    assert(provider != null, 'AppThemeProvider not found in widget tree');
    return provider!.themeData;
  }

  /// Try to access AppThemeData, returns null if not found
  static AppThemeData? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppThemeProvider>();
    return provider?.themeData;
  }

  @override
  bool updateShouldNotify(AppThemeProvider oldWidget) {
    return themeData != oldWidget.themeData;
  }
}

/// Extension to make accessing AppThemeData easier
extension AppThemeExtension on BuildContext {
  /// Get the current AppThemeData
  AppThemeData get appThemeData => AppThemeProvider.of(this);

  /// Try to get the current AppThemeData, returns null if not found
  AppThemeData? get appThemeDataOrNull => AppThemeProvider.maybeOf(this);
}
