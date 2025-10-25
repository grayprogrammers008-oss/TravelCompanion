import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_extensions.dart';

/// Pre-built themed components that automatically update with theme changes
///
/// These widgets use the dynamic theme system to ensure consistent styling
/// across the app and automatic updates when themes change.

/// A card that automatically uses theme colors
///
/// Usage:
/// ```dart
/// ThemedCard(
///   child: Text('Hello'),
/// )
/// ```
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool withShadow;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(context.spacingMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.cardColor,
        borderRadius: BorderRadius.circular(borderRadius ?? context.radiusLg),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// A primary button that automatically uses theme colors
///
/// Usage:
/// ```dart
/// ThemedButton(
///   label: 'Create Trip',
///   onPressed: () {},
/// )
/// ```
class ThemedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const ThemedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isSecondary ? context.accentColor : context.primaryColor,
          side: BorderSide(
            color: isSecondary ? context.accentColor : context.primaryColor,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.spacingLg,
            vertical: context.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radiusMd),
          ),
        ),
        child: _buildButtonChild(context),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? context.accentColor : context.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: context.spacingLg,
          vertical: context.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radiusMd),
        ),
        elevation: context.elevation2,
      ),
      child: _buildButtonChild(context),
    );
  }

  Widget _buildButtonChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? context.primaryColor : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.iconSizeSm),
          SizedBox(width: context.spacingSm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}

/// An icon that automatically uses theme colors
///
/// Usage:
/// ```dart
/// ThemedIcon(
///   icon: Icons.location_on,
///   isPrimary: true,
/// )
/// ```
class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final bool isPrimary;
  final Color? color;

  const ThemedIcon({
    super.key,
    required this.icon,
    this.size,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? context.iconSizeMd,
      color: color ?? (isPrimary ? context.primaryColor : context.textColor),
    );
  }
}

/// A chip/badge that automatically uses theme colors
///
/// Usage:
/// ```dart
/// ThemedChip(
///   label: '5 days left',
///   icon: Icons.calendar_today,
/// )
/// ```
class ThemedChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isPrimary;
  final VoidCallback? onTap;

  const ThemedChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (isPrimary ? context.primaryColor : context.primaryLight);
    final fgColor = textColor ??
        (isPrimary ? Colors.white : context.primaryColor);

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacingSm,
        vertical: context.spacingXs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.iconSizeXs, color: fgColor),
            SizedBox(width: context.spacingXs),
          ],
          Text(
            label,
            style: context.labelSmall.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radiusFull),
        child: content,
      );
    }

    return content;
  }
}

/// A gradient container for premium features
///
/// Usage:
/// ```dart
/// ThemedGradientCard(
///   child: Text('Premium Feature'),
/// )
/// ```
class ThemedGradientCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;

  const ThemedGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.appTheme;

    return Container(
      padding: padding ?? EdgeInsets.all(context.spacingLg),
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? context.radiusLg),
        boxShadow: theme.primaryShadow,
      ),
      child: child,
    );
  }
}

/// A section header that automatically uses theme typography
///
/// Usage:
/// ```dart
/// ThemedSectionHeader(
///   title: 'Recent Trips',
///   action: TextButton(child: Text('See All')),
/// )
/// ```
class ThemedSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsets? padding;

  const ThemedSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: context.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: context.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// A divider that automatically uses theme colors
///
/// Usage:
/// ```dart
/// ThemedDivider()
/// ```
class ThemedDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;

  const ThemedDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? context.spacingMd,
      thickness: thickness ?? 1,
      color: color ?? context.textColor.withOpacity(0.1),
    );
  }
}

/// A loading indicator that automatically uses theme colors
///
/// Usage:
/// ```dart
/// ThemedLoadingIndicator()
/// ```
class ThemedLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const ThemedLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size ?? 40,
        width: size ?? 40,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? context.primaryColor,
          ),
        ),
      ),
    );
  }
}

/// An empty state widget that automatically uses theme styling
///
/// Usage:
/// ```dart
/// ThemedEmptyState(
///   icon: Icons.inbox,
///   title: 'No trips yet',
///   message: 'Create your first trip to get started',
///   action: ThemedButton(label: 'Create Trip', onPressed: () {}),
/// )
/// ```
class ThemedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const ThemedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: context.iconSizeXl * 2,
              color: context.textColor.withOpacity(context.opacityMedium),
            ),
            SizedBox(height: context.spacingLg),
            Text(
              title,
              style: context.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacingSm),
            Text(
              message,
              style: context.bodyMedium.copyWith(
                color: context.textColor.withOpacity(context.opacityHigh),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              SizedBox(height: context.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
