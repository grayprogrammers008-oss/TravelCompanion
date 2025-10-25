import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme_data.dart';
import 'theme_provider.dart' as theme_provider;

/// Extension on BuildContext for easy theme access
///
/// This allows components to use dynamic theme colors instead of hardcoded values.
///
/// Usage:
/// ```dart
/// Container(
///   color: context.primaryColor,  // Auto-updates with theme!
///   padding: EdgeInsets.all(context.spacingMd),
///   child: Text('Hello', style: context.titleStyle),
/// )
/// ```
extension AppThemeContext on BuildContext {
  // === Standard Material Colors (Auto-updates with theme) ===

  /// Primary brand color (e.g., Ocean Blue, Sunset Coral)
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// Secondary/accent color
  Color get accentColor => Theme.of(this).colorScheme.secondary;

  /// Background color
  Color get backgroundColor => Theme.of(this).colorScheme.surface;

  /// Text color on surface
  Color get textColor => Theme.of(this).colorScheme.onSurface;

  /// Error/danger color
  Color get errorColor => Theme.of(this).colorScheme.error;

  /// Success color (from tertiary)
  Color get successColor => Theme.of(this).colorScheme.tertiary;

  // === Light/Dark variants ===

  Color get primaryLight => Theme.of(this).colorScheme.primaryContainer;
  Color get primaryDark => Theme.of(this).colorScheme.onPrimaryContainer;

  // === Surfaces & Containers ===

  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get cardColor => Theme.of(this).cardTheme.color ?? Colors.white;

  // === Text Styles ===

  TextStyle get displayLarge => Theme.of(this).textTheme.displayLarge!;
  TextStyle get displayMedium => Theme.of(this).textTheme.displayMedium!;
  TextStyle get displaySmall => Theme.of(this).textTheme.displaySmall!;

  TextStyle get headlineLarge => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get headlineMedium => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get headlineSmall => Theme.of(this).textTheme.headlineSmall!;

  TextStyle get titleLarge => Theme.of(this).textTheme.titleLarge!;
  TextStyle get titleMedium => Theme.of(this).textTheme.titleMedium!;
  TextStyle get titleSmall => Theme.of(this).textTheme.titleSmall!;

  TextStyle get bodyLarge => Theme.of(this).textTheme.bodyLarge!;
  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;

  TextStyle get labelLarge => Theme.of(this).textTheme.labelLarge!;
  TextStyle get labelMedium => Theme.of(this).textTheme.labelMedium!;
  TextStyle get labelSmall => Theme.of(this).textTheme.labelSmall!;

  // === Convenient Aliases ===

  TextStyle get headlineStyle => headlineMedium;
  TextStyle get titleStyle => titleMedium;
  TextStyle get bodyStyle => bodyMedium;
  TextStyle get captionStyle => labelSmall;

  // === Spacing (from our theme) ===

  double get spacingXs => 8.0;
  double get spacingSm => 12.0;
  double get spacingMd => 16.0;
  double get spacingLg => 24.0;
  double get spacingXl => 32.0;
  double get spacing2xl => 48.0;
  double get spacing3xl => 64.0;

  // === Border Radius ===

  double get radiusXs => 4.0;
  double get radiusSm => 8.0;
  double get radiusMd => 12.0;
  double get radiusLg => 16.0;
  double get radiusXl => 24.0;
  double get radiusFull => 999.0;

  // === Icon Sizes ===

  double get iconSizeXs => 16.0;
  double get iconSizeSm => 20.0;
  double get iconSizeMd => 24.0;
  double get iconSizeLg => 32.0;
  double get iconSizeXl => 48.0;

  // === Opacity Values ===

  double get opacityDisabled => 0.38;
  double get opacityMedium => 0.60;
  double get opacityHigh => 0.87;

  // === Elevation ===

  double get elevation0 => 0;
  double get elevation1 => 1;
  double get elevation2 => 2;
  double get elevation4 => 4;
  double get elevation8 => 8;
  double get elevation16 => 16;
}

/// Extension on WidgetRef for Riverpod widgets
///
/// This allows ConsumerWidget/ConsumerStatefulWidget to access custom theme data.
///
/// Usage:
/// ```dart
/// class MyCard extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final theme = ref.appTheme;  // Custom theme data
///
///     return Container(
///       decoration: BoxDecoration(
///         gradient: theme.primaryGradient,  // Custom gradient!
///         boxShadow: theme.primaryShadow,   // Custom shadow!
///       ),
///       child: Text('Hello', style: context.headlineStyle),
///     );
///   }
/// }
/// ```
extension AppThemeRef on WidgetRef {
  /// Get current custom theme data
  AppThemeData get appTheme => watch(theme_provider.currentThemeDataProvider);
}

/// Mixin for Stateful widgets to easily access theme
mixin ThemeAccessMixin on ConsumerState {
  /// Get the current app theme data
  AppThemeData get appTheme => ref.watch(theme_provider.currentThemeDataProvider);
}
