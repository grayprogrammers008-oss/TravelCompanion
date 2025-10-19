import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_access.dart';

/// Animated gradient background with wave effect
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Duration duration;
  final bool animate;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.duration = const Duration(seconds: 5),
    this.animate = true,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
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
    final colors = widget.colors ??
        [
          themeData.primaryColor,
          AppTheme.accentPurple,
          AppTheme.accentCoral,
        ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Mesh gradient background (multiple gradients overlayed)
class MeshGradientBackground extends StatelessWidget {
  final Widget child;
  final List<List<Color>>? gradients;
  final double opacity;

  const MeshGradientBackground({
    super.key,
    required this.child,
    this.gradients,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final defaultGradients = [
      [themeData.primaryColor, AppTheme.accentPurple],
      [AppTheme.accentCoral, AppTheme.accentGold],
      [AppTheme.accentOrange, themeData.primaryColor],
    ];

    final usedGradients = gradients ?? defaultGradients;

    return Stack(
      children: [
        // Base color
        Container(color: AppTheme.neutral50),

        // Gradient layers
        ...List.generate(usedGradients.length, (index) {
          return Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: _getAlignment(index),
                    radius: 1.5,
                    colors: usedGradients[index],
                  ),
                ),
              ),
            ),
          );
        }),

        // Content
        child,
      ],
    );
  }

  Alignment _getAlignment(int index) {
    switch (index % 3) {
      case 0:
        return Alignment.topLeft;
      case 1:
        return Alignment.topRight;
      case 2:
        return Alignment.bottomCenter;
      default:
        return Alignment.center;
    }
  }
}

/// Glassmorphic background with blur
class GlassmorphicBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double blur;
  final Gradient? gradient;

  const GlassmorphicBackground({
    super.key,
    required this.child,
    this.backgroundColor,
    this.blur = 20.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeData.primaryColor.withValues(alpha: 0.1),
                AppTheme.accentPurple.withValues(alpha: 0.05),
              ],
            ),
      ),
      child: child,
    );
  }
}

/// Decorative floating circles background
class FloatingCirclesBackground extends StatefulWidget {
  final Widget child;
  final int circleCount;
  final List<Color>? colors;

  const FloatingCirclesBackground({
    super.key,
    required this.child,
    this.circleCount = 5,
    this.colors,
  });

  @override
  State<FloatingCirclesBackground> createState() =>
      _FloatingCirclesBackgroundState();
}

class _FloatingCirclesBackgroundState extends State<FloatingCirclesBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _yAnimations;
  late List<Animation<double>> _xAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.circleCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 3000 + (index * 500)),
        vsync: this,
      ),
    );

    _yAnimations = _controllers.map((controller) {
      return Tween<double>(begin: -0.1, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _xAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 0.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final colors = widget.colors ??
        [
          themeData.primaryColor.withValues(alpha: 0.1),
          AppTheme.accentCoral.withValues(alpha: 0.1),
          AppTheme.accentPurple.withValues(alpha: 0.1),
          AppTheme.accentGold.withValues(alpha: 0.1),
          AppTheme.accentOrange.withValues(alpha: 0.1),
        ];

    return Stack(
      children: [
        Container(color: AppTheme.neutral50),
        ...List.generate(widget.circleCount, (index) {
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width *
                    (0.1 + (index * 0.15) + _xAnimations[index].value),
                top: MediaQuery.of(context).size.height *
                    _yAnimations[index].value,
                child: Container(
                  width: 100 + (index * 30),
                  height: 100 + (index * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors[index % colors.length],
                        colors[index % colors.length].withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        widget.child,
      ],
    );
  }
}

/// Wave pattern background
class WaveBackground extends StatefulWidget {
  final Widget child;
  final Color? waveColor;
  final double height;

  const WaveBackground({
    super.key,
    required this.child,
    this.waveColor,
    this.height = 200.0,
  });

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return Stack(
      children: [
        Container(color: AppTheme.neutral50),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animation: _animation.value,
                waveColor: widget.waveColor ?? themeData.primaryColor.withValues(alpha: 0.1),
              ),
              size: Size(MediaQuery.of(context).size.width, widget.height),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animation;
  final Color waveColor;

  WavePainter({
    required this.animation,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            (size.height * 0.2) *
                (0.5 + 0.5 * math.sin((i / size.width + animation) * 2 * math.pi)),
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
