import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_access.dart';

/// Premium glassmorphic card with frosted glass effect
///
/// Creates a stunning frosted glass appearance with blur,
/// gradient borders, and subtle shine effects
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.gradient,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(opacity),
                    Colors.white.withOpacity(opacity * 0.5),
                  ],
                ),
            borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
            boxShadow: boxShadow ?? AppTheme.shadowLg,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glossy card with gradient overlay and shine effect
class GlossyCard extends StatefulWidget {
  final Widget child;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool showShine;

  const GlossyCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.onTap,
    this.showShine = true,
  });

  @override
  State<GlossyCard> createState() => _GlossyCardState();
}

class _GlossyCardState extends State<GlossyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shineAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.showShine) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.02 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient ?? themeData.primaryGradient,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: _isHovered ? AppTheme.shadowXl : AppTheme.shadowLg,
            ),
            child: Stack(
              children: [
                // Content
                Padding(
                  padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacingMd),
                  child: widget.child,
                ),

                // Shine effect
                if (widget.showShine)
                  AnimatedBuilder(
                    animation: _shineAnimation,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: ClipRRect(
                          borderRadius: widget.borderRadius ??
                              BorderRadius.circular(AppTheme.radiusLg),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                stops: [
                                  _shineAnimation.value - 0.1,
                                  _shineAnimation.value,
                                  _shineAnimation.value + 0.1,
                                ],
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium elevated card with floating effect
class FloatingCard extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double elevation;

  const FloatingCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.onTap,
    this.elevation = 8.0,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: themeData.primaryColor.withOpacity(0.1 + (_floatAnimation.value / 80)),
                    blurRadius: widget.elevation + _floatAnimation.value,
                    offset: Offset(0, widget.elevation / 2 + _floatAnimation.value / 2),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Neumorphic card with soft 3D effect
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool isPressed;
  final VoidCallback? onTap;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.isPressed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppTheme.neutral50;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: isPressed
              ? [
                  // Inner shadows when pressed
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ]
              : [
                  // Outer shadows (raised)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 10,
                    offset: const Offset(-4, -4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(4, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// Gradient border card with shimmer
class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final Gradient? borderGradient;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.borderGradient,
    this.borderWidth = 2.0,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return Container(
      decoration: BoxDecoration(
        gradient: borderGradient ?? themeData.primaryGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: themeData.primaryShadow,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: borderRadius != null
              ? BorderRadius.circular(
                  (borderRadius as BorderRadius).topLeft.x - borderWidth)
              : BorderRadius.circular(AppTheme.radiusLg - borderWidth),
        ),
        child: child,
      ),
    );
  }
}
