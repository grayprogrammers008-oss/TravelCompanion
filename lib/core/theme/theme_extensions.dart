import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme_data.dart';
import 'theme_provider.dart';

/// Extension on BuildContext to easily access current theme data
extension ThemeContextExtension on BuildContext {
  /// Get the current app theme data
  /// Note: This requires the widget to be a ConsumerWidget or ConsumerStatefulWidget
  /// For regular widgets, use Theme.of(context) or pass themeData as parameter
  AppThemeData get appTheme {
    // This is a helper that throws a clear error if used incorrectly
    throw UnsupportedError(
      'appTheme can only be used in ConsumerWidget. '
      'Use ref.watch(currentThemeDataProvider) instead.',
    );
  }
}

/// Extension on WidgetRef to easily access current theme data
extension ThemeRefExtension on WidgetRef {
  /// Get the current app theme data
  AppThemeData get appTheme => watch(currentThemeDataProvider);
}

/// Mixin for Stateful widgets to easily access theme
mixin ThemeAccessMixin on ConsumerState {
  /// Get the current app theme data
  AppThemeData get appTheme => ref.watch(currentThemeDataProvider);
}
