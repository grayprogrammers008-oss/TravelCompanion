import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Easy Mode configuration for accessibility
/// When enabled, the app uses larger text, bigger buttons, and simplified UI
class EasyModeConfig {
  /// Text scale factor multiplier (1.0 = normal, 1.3 = 30% larger)
  final double textScaleFactor;

  /// Minimum touch target size (48dp normal, 72dp easy mode)
  final double minTouchTargetSize;

  /// Whether to show icon labels
  final bool showIconLabels;

  /// Whether to use high contrast colors
  final bool highContrast;

  /// Whether to simplify forms (hide optional fields)
  final bool simplifyForms;

  /// Spacing multiplier (1.0 = normal, 1.5 = 50% more spacing)
  final double spacingMultiplier;

  /// Icon size multiplier
  final double iconSizeMultiplier;

  /// Border radius multiplier (larger = more rounded)
  final double borderRadiusMultiplier;

  const EasyModeConfig({
    this.textScaleFactor = 1.0,
    this.minTouchTargetSize = 48.0,
    this.showIconLabels = false,
    this.highContrast = false,
    this.simplifyForms = false,
    this.spacingMultiplier = 1.0,
    this.iconSizeMultiplier = 1.0,
    this.borderRadiusMultiplier = 1.0,
  });

  /// Normal mode configuration
  static const EasyModeConfig normal = EasyModeConfig();

  /// Easy mode configuration with accessibility enhancements
  static const EasyModeConfig easy = EasyModeConfig(
    textScaleFactor: 1.3,
    minTouchTargetSize: 72.0,
    showIconLabels: true,
    highContrast: true,
    simplifyForms: true,
    spacingMultiplier: 1.3,
    iconSizeMultiplier: 1.4,
    borderRadiusMultiplier: 1.2,
  );

  /// Get scaled text style
  TextStyle scaleTextStyle(TextStyle style) {
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * textScaleFactor,
    );
  }

  /// Get scaled icon size
  double scaleIconSize(double size) {
    return size * iconSizeMultiplier;
  }

  /// Get scaled spacing
  double scaleSpacing(double spacing) {
    return spacing * spacingMultiplier;
  }

  /// Get scaled border radius
  double scaleBorderRadius(double radius) {
    return radius * borderRadiusMultiplier;
  }

  /// Ensure minimum touch target size
  double ensureMinTouchTarget(double size) {
    return size < minTouchTargetSize ? minTouchTargetSize : size;
  }
}

/// Provider for Easy Mode state using Riverpod 2.0+ Notifier pattern
class EasyModeNotifier extends Notifier<bool> {
  static const String _prefKey = 'easy_mode_enabled';

  @override
  bool build() {
    // Initialize with false, then load from prefs
    _loadPreference();
    return false;
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getBool(_prefKey) ?? false;
    if (savedValue != state) {
      state = savedValue;
    }
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }
}

/// Provider for easy mode enabled state
final easyModeEnabledProvider =
    NotifierProvider<EasyModeNotifier, bool>(() {
  return EasyModeNotifier();
});

/// Provider for easy mode configuration
final easyModeConfigProvider = Provider<EasyModeConfig>((ref) {
  final isEasyMode = ref.watch(easyModeEnabledProvider);
  return isEasyMode ? EasyModeConfig.easy : EasyModeConfig.normal;
});

/// Extension for easy access to easy mode in widgets
extension EasyModeContext on BuildContext {
  /// Get easy mode config from nearest ProviderScope
  EasyModeConfig get easyMode {
    try {
      final container = ProviderScope.containerOf(this);
      return container.read(easyModeConfigProvider);
    } catch (_) {
      return EasyModeConfig.normal;
    }
  }

  /// Check if easy mode is enabled
  bool get isEasyModeEnabled {
    try {
      final container = ProviderScope.containerOf(this);
      return container.read(easyModeEnabledProvider);
    } catch (_) {
      return false;
    }
  }
}

/// Widget that rebuilds when easy mode changes
class EasyModeBuilder extends ConsumerWidget {
  final Widget Function(BuildContext context, EasyModeConfig config) builder;

  const EasyModeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(easyModeConfigProvider);
    return builder(context, config);
  }
}

/// Easy mode aware button with minimum touch target
class EasyModeButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const EasyModeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(easyModeConfigProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: config.minTouchTargetSize,
        minWidth: config.minTouchTargetSize,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding != null
              ? padding!.add(EdgeInsets.all(config.scaleSpacing(4)))
              : EdgeInsets.all(config.scaleSpacing(16)),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ??
                BorderRadius.circular(config.scaleBorderRadius(8)),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Easy mode aware icon button with optional label
class EasyModeIconButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final Color? color;
  final double? size;

  const EasyModeIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(easyModeConfigProvider);
    final iconSize = config.scaleIconSize(size ?? 24);

    if (config.showIconLabels && label != null) {
      // Show icon with label below
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(config.scaleBorderRadius(8)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: config.minTouchTargetSize,
            minWidth: config.minTouchTargetSize,
          ),
          child: Padding(
            padding: EdgeInsets.all(config.scaleSpacing(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: color),
                SizedBox(height: config.scaleSpacing(4)),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 10 * config.textScaleFactor,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Standard icon button
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize, color: color),
      constraints: BoxConstraints(
        minHeight: config.minTouchTargetSize,
        minWidth: config.minTouchTargetSize,
      ),
    );
  }
}

/// Easy mode aware text widget
class EasyModeText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const EasyModeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(easyModeConfigProvider);
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    return Text(
      text,
      style: config.scaleTextStyle(baseStyle),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
