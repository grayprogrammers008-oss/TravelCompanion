# Dynamic Theming Architecture - Professional Approach

## 🎯 The Problem

**Current Issue:**
- Components use hardcoded colors: `AppTheme.primaryTeal`
- Changing themes doesn't change the app
- Need to manually update hundreds of files
- Not scalable or maintainable

**What We Need:**
- Components automatically use current theme
- Change theme = entire app updates instantly
- Zero hardcoded colors in components
- One source of truth for all colors

---

## 🏗️ The Solution: 3-Layer Architecture

### Layer 1: Theme Definition (What we already have ✅)
```dart
// lib/core/theme/app_theme_data.dart
class AppThemeData {
  final Color primaryColor;
  final Color accentColor;
  // ... all colors defined here
}
```

### Layer 2: Theme Access (What we need to create 🔨)
```dart
// Make it EASY for components to get theme colors
// Two approaches:
```

**Approach A: Extension on BuildContext (Recommended)**
```dart
extension ThemeExtensions on BuildContext {
  // Quick access to theme colors
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get errorColor => Theme.of(this).colorScheme.error;

  // Quick access to custom theme data
  AppThemeData get appTheme {
    // Get our custom theme data
    return ref.read(currentThemeDataProvider);
  }
}
```

**Approach B: Theme Provider Widget (Alternative)**
```dart
class AppThemeProvider extends InheritedWidget {
  final AppThemeData themeData;

  static AppThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeProvider>()!.themeData;
  }
}
```

### Layer 3: Component Usage (Simple & Clean)
```dart
// OLD WAY ❌ - Hardcoded
Container(
  color: AppTheme.primaryTeal,  // Fixed color, never changes
)

// NEW WAY ✅ - Dynamic
Container(
  color: context.primaryColor,  // Auto-updates with theme!
)

// OR with Theme.of(context)
Container(
  color: Theme.of(context).colorScheme.primary,
)
```

---

## 📋 Implementation Plan

### Step 1: Create Theme Extensions
**File:** `lib/core/theme/theme_extensions.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme_data.dart';
import 'theme_provider.dart' as theme_provider;

/// Extension on BuildContext for easy theme access
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

  // === Text Colors ===

  TextStyle get headlineStyle => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get titleStyle => Theme.of(this).textTheme.titleMedium!;
  TextStyle get bodyStyle => Theme.of(this).textTheme.bodyMedium!;

  // === Spacing (from our theme) ===

  double get spacingXs => 8.0;
  double get spacingSm => 12.0;
  double get spacingMd => 16.0;
  double get spacingLg => 24.0;
  double get spacingXl => 32.0;

  // === Border Radius ===

  double get radiusSm => 8.0;
  double get radiusMd => 12.0;
  double get radiusLg => 16.0;

  // === Custom Theme Data (for gradients, custom colors) ===

  /// Get custom AppThemeData (requires WidgetRef)
  /// Use this in ConsumerWidget/ConsumerStatefulWidget
  AppThemeData appThemeData(WidgetRef ref) {
    return ref.watch(theme_provider.currentThemeDataProvider);
  }
}

/// Extension on WidgetRef for Riverpod widgets
extension AppThemeRef on WidgetRef {
  /// Get current custom theme data
  AppThemeData get appTheme => watch(theme_provider.currentThemeDataProvider);
}
```

### Step 2: Update Components to Use Extensions

**Before ❌:**
```dart
class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal,  // Hardcoded!
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        'Hello',
        style: TextStyle(color: AppTheme.neutral900),  // Hardcoded!
      ),
    );
  }
}
```

**After ✅:**
```dart
class MyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.primaryColor,  // Dynamic! 🎉
        borderRadius: BorderRadius.circular(context.radiusMd),
      ),
      child: Text(
        'Hello',
        style: context.bodyStyle,  // Dynamic! 🎉
      ),
    );
  }
}
```

**For Riverpod Widgets:**
```dart
class MyCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.appTheme;  // Custom theme data

    return Container(
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,  // Custom gradient!
        boxShadow: theme.primaryShadow,   // Custom shadow!
      ),
      child: Text(
        'Hello',
        style: context.headlineStyle.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
```

### Step 3: Create Theme-Aware Widgets
**File:** `lib/core/widgets/themed_widgets.dart` (NEW)

```dart
/// Pre-built themed components that auto-update

class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ThemedCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(context.spacingMd),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(context.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;

  const ThemedButton({
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary
            ? context.accentColor
            : context.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingLg,
          vertical: context.spacingMd,
        ),
      ),
      child: Text(label),
    );
  }
}

class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final bool isPrimary;

  const ThemedIcon({
    required this.icon,
    this.size,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? 24,
      color: isPrimary ? context.primaryColor : context.textColor,
    );
  }
}
```

### Step 4: Deprecate Old Constants

**File:** `lib/core/theme/app_theme.dart`

```dart
class AppTheme {
  // Mark old colors as deprecated
  @Deprecated('Use context.primaryColor or Theme.of(context).colorScheme.primary')
  static const Color primaryTeal = Color(0xFF00B8A9);

  @Deprecated('Use context.accentColor or Theme.of(context).colorScheme.secondary')
  static const Color accentCoral = Color(0xFFFF6B9D);

  // Keep only semantic/neutral colors that don't change with theme
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral700 = Color(0xFF334155);
  // ... etc

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Keep spacing/radius constants (theme-agnostic)
  static const double spacingXs = 8.0;
  static const double spacingMd = 16.0;
  // ... etc
}
```

---

## 🎨 Usage Examples

### Example 1: Simple Container
```dart
// Automatically uses current theme's primary color
Container(
  color: context.primaryColor,
  padding: EdgeInsets.all(context.spacingMd),
  child: Text(
    'Hello',
    style: context.titleStyle,
  ),
)
```

### Example 2: Custom Gradient Card
```dart
class TripCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.appTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,  // Ocean Blue gradient in Ocean theme
        borderRadius: BorderRadius.circular(context.radiusLg),
        boxShadow: theme.primaryShadow,
      ),
      child: Text(
        'Trip Name',
        style: context.headlineStyle.copyWith(color: Colors.white),
      ),
    );
  }
}
```

### Example 3: Icon with Theme Color
```dart
Icon(
  Icons.location_on,
  color: context.primaryColor,  // Auto-updates with theme!
  size: 20,
)
```

---

## 📦 Migration Strategy

### Phase 1: Setup (Week 1)
1. ✅ Create `theme_extensions.dart`
2. ✅ Create `themed_widgets.dart`
3. ✅ Test in one screen
4. ✅ Document usage

### Phase 2: Gradual Migration (Week 2-3)
1. Update one feature at a time:
   - Start with Trips (most visible)
   - Then Expenses
   - Then Checklists
   - Then Settings
2. Test theme switching after each feature
3. No breaking changes - old code still works

### Phase 3: Deprecation (Week 4)
1. Mark old constants as `@Deprecated`
2. IDE will warn but not break
3. Developers update when convenient

### Phase 4: Cleanup (Later)
1. Remove deprecated constants
2. Full theme support everywhere

---

## ✅ Benefits

### 1. **Automatic Theme Updates**
```dart
// Change theme in settings
ref.read(themeProvider.notifier).setTheme(AppThemeType.sunset);

// ENTIRE app updates instantly!
// - All buttons turn coral
// - All icons turn coral
// - All gradients change
// Zero code changes needed
```

### 2. **Clean Component Code**
```dart
// Instead of:
color: AppTheme.primaryTeal  // What if we want blue?

// We write:
color: context.primaryColor  // Works with ANY theme!
```

### 3. **Type Safety**
```dart
// Compiler enforces correct usage
context.primaryColor  // ✅ Correct
context.primaryColr   // ❌ Typo caught at compile time
```

### 4. **Easy Testing**
```dart
testWidgets('Button uses theme color', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: oceanTheme,  // Test with Ocean theme
      home: MyButton(),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  expect(button.style!.backgroundColor, equals(oceanBlue));
});
```

---

## 🚀 Implementation Files

### Files to Create:
1. `lib/core/theme/theme_extensions.dart` - BuildContext extensions
2. `lib/core/widgets/themed_widgets.dart` - Pre-built themed widgets

### Files to Update:
1. `lib/core/theme/app_theme.dart` - Add @Deprecated to old colors
2. Components (gradual migration)

---

## 📖 Developer Guide

### When to Use What:

#### Use `context.primaryColor` for:
- ✅ Simple colors
- ✅ Most common use case
- ✅ Cleaner code

```dart
color: context.primaryColor
```

#### Use `Theme.of(context).colorScheme.primary` for:
- ✅ When you don't have extensions imported
- ✅ More explicit/verbose code

```dart
color: Theme.of(context).colorScheme.primary
```

#### Use `ref.appTheme` for:
- ✅ Custom gradients
- ✅ Custom shadows
- ✅ Special theme features

```dart
final theme = ref.appTheme;
gradient: theme.primaryGradient
```

---

## 🎯 End Result

### Before:
```dart
// 100 files using hardcoded teal
AppTheme.primaryTeal
AppTheme.primaryTeal
AppTheme.primaryTeal
// Change theme → Nothing happens 😢
```

### After:
```dart
// 100 files using dynamic theme
context.primaryColor
context.primaryColor
context.primaryColor
// Change theme → Everything updates! 🎉
```

---

## 🔥 Next Steps

1. **Should I create the extension files?**
2. **Update 2-3 components as examples?**
3. **Document the pattern?**

This architecture is:
- ✅ Industry standard (used by Google, Airbnb, etc.)
- ✅ Scalable (works for 10 or 1000 components)
- ✅ Maintainable (one place to change theming)
- ✅ Type-safe (compiler catches errors)
- ✅ Developer-friendly (easy to use)

**Ready to implement?** 🚀
