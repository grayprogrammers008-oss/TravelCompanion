import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/theme_access.dart';

/// Beautiful mesh gradient background with animated blobs
/// Performance optimized: pauses animation during scroll
class MeshGradientBackground extends StatefulWidget {
  final Widget child;
  final bool animated;
  final double intensity; // 0.0 to 1.0

  const MeshGradientBackground({
    super.key,
    required this.child,
    this.animated = false, // Disabled by default for performance
    this.intensity = 0.7,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pause animation during scroll to improve performance
  void _handleScrollNotification(ScrollNotification notification) {
    if (!widget.animated) return;

    if (notification is ScrollStartNotification) {
      if (!_isScrolling) {
        _isScrolling = true;
        _controller.stop();
      }
    } else if (notification is ScrollEndNotification) {
      if (_isScrolling) {
        _isScrolling = false;
        // Resume animation after scroll ends
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_isScrolling) {
            _controller.repeat();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final size = MediaQuery.of(context).size;

    // Cache blob positions to avoid recalculating during static state
    final blob1Offset = widget.animated && !_isScrolling
        ? Offset(
            math.sin(_controller.value * 2 * math.pi) * 50,
            math.cos(_controller.value * 2 * math.pi) * 50,
          )
        : Offset.zero;
    final blob2Offset = widget.animated && !_isScrolling
        ? Offset(
            math.cos(_controller.value * 2 * math.pi + 2) * 60,
            math.sin(_controller.value * 2 * math.pi + 2) * 60,
          )
        : Offset.zero;
    final blob3Offset = widget.animated && !_isScrolling
        ? Offset(
            math.sin(_controller.value * 2 * math.pi + 4) * 40,
            math.cos(_controller.value * 2 * math.pi + 4) * 40,
          )
        : Offset.zero;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        return false; // Don't block the notification
      },
      child: Stack(
        children: [
          // Base gradient background - wrapped in RepaintBoundary
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                gradient: themeData.backgroundGradient,
              ),
            ),
          ),

          // Static blobs when not animated (much better performance)
          if (!widget.animated) ...[
            // Static blob 1 (top-left)
            Positioned(
              left: -size.width * 0.3,
              top: -size.height * 0.2,
              child: _StaticBlob(
                width: size.width * 0.8,
                height: size.height * 0.6,
                colors: [
                  themeData.primaryLight.withValues(alpha: 0.15 * widget.intensity),
                  themeData.primaryColor.withValues(alpha: 0.08 * widget.intensity),
                  Colors.transparent,
                ],
              ),
            ),
            // Static blob 2 (bottom-right)
            Positioned(
              right: -size.width * 0.2,
              bottom: -size.height * 0.15,
              child: _StaticBlob(
                width: size.width * 0.7,
                height: size.height * 0.5,
                colors: [
                  themeData.accentColor.withValues(alpha: 0.12 * widget.intensity),
                  themeData.primaryDeep.withValues(alpha: 0.06 * widget.intensity),
                  Colors.transparent,
                ],
              ),
            ),
            // Static blob 3 (center)
            Positioned(
              left: size.width * 0.2,
              top: size.height * 0.15,
              child: _StaticBlob(
                width: size.width * 0.6,
                height: size.height * 0.5,
                colors: [
                  themeData.primaryColor.withValues(alpha: 0.1 * widget.intensity),
                  themeData.primaryLight.withValues(alpha: 0.05 * widget.intensity),
                  Colors.transparent,
                ],
              ),
            ),
          ] else ...[
            // Animated blobs - wrapped in RepaintBoundary
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Blob 1 (top-left)
                      Positioned(
                        left: -size.width * 0.3 + blob1Offset.dx,
                        top: -size.height * 0.2 + blob1Offset.dy,
                        child: _StaticBlob(
                          width: size.width * 0.8,
                          height: size.height * 0.6,
                          colors: [
                            themeData.primaryLight.withValues(alpha: 0.15 * widget.intensity),
                            themeData.primaryColor.withValues(alpha: 0.08 * widget.intensity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      // Blob 2 (bottom-right)
                      Positioned(
                        right: -size.width * 0.2 + blob2Offset.dx,
                        bottom: -size.height * 0.15 + blob2Offset.dy,
                        child: _StaticBlob(
                          width: size.width * 0.7,
                          height: size.height * 0.5,
                          colors: [
                            themeData.accentColor.withValues(alpha: 0.12 * widget.intensity),
                            themeData.primaryDeep.withValues(alpha: 0.06 * widget.intensity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      // Blob 3 (center)
                      Positioned(
                        left: size.width * 0.5 + blob3Offset.dx - size.width * 0.3,
                        top: size.height * 0.4 + blob3Offset.dy - size.height * 0.25,
                        child: _StaticBlob(
                          width: size.width * 0.6,
                          height: size.height * 0.5,
                          colors: [
                            themeData.primaryColor.withValues(alpha: 0.1 * widget.intensity),
                            themeData.primaryLight.withValues(alpha: 0.05 * widget.intensity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          // Content
          widget.child,
        ],
      ),
    );
  }
}

/// Static blob widget for better performance (no animation overhead)
class _StaticBlob extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> colors;

  const _StaticBlob({
    required this.width,
    required this.height,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Diagonal stripe gradient background
class DiagonalGradientBackground extends StatelessWidget {
  final Widget child;
  final int stripeCount;
  final double opacity;

  const DiagonalGradientBackground({
    super.key,
    required this.child,
    this.stripeCount = 8,
    this.opacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: themeData.backgroundGradient,
          ),
        ),

        // Diagonal stripes
        CustomPaint(
          painter: _DiagonalStripesPainter(
            color1: themeData.primaryColor.withValues(alpha: opacity),
            color2: themeData.accentColor.withValues(alpha: opacity * 0.5),
            stripeCount: stripeCount,
          ),
          size: Size.infinite,
        ),

        // Content
        child,
      ],
    );
  }
}

class _DiagonalStripesPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final int stripeCount;

  _DiagonalStripesPainter({
    required this.color1,
    required this.color2,
    required this.stripeCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stripeWidth = (size.width + size.height) / stripeCount;

    for (int i = 0; i < stripeCount * 2; i++) {
      paint.color = i % 2 == 0 ? color1 : color2;
      final path = Path();
      final startX = i * stripeWidth - size.height;

      path.moveTo(startX, 0);
      path.lineTo(startX + stripeWidth, 0);
      path.lineTo(startX + stripeWidth + size.height, size.height);
      path.lineTo(startX + size.height, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wave pattern gradient background
class WaveGradientBackground extends StatefulWidget {
  final Widget child;
  final bool animated;
  final int waveCount;

  const WaveGradientBackground({
    super.key,
    required this.child,
    this.animated = true,
    this.waveCount = 3,
  });

  @override
  State<WaveGradientBackground> createState() => _WaveGradientBackgroundState();
}

class _WaveGradientBackgroundState extends State<WaveGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    if (widget.animated) {
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

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: themeData.backgroundGradient,
          ),
        ),

        // Animated waves
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavePainter(
                color1: themeData.primaryColor.withValues(alpha: 0.08),
                color2: themeData.primaryLight.withValues(alpha: 0.05),
                color3: themeData.accentColor.withValues(alpha: 0.06),
                animationValue: _controller.value,
                waveCount: widget.waveCount,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Color color3;
  final double animationValue;
  final int waveCount;

  _WavePainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.animationValue,
    required this.waveCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [color1, color2, color3];

    for (int i = 0; i < waveCount; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final path = Path();
      final waveHeight = 100.0;
      final waveLength = size.width / 2;
      final yOffset = size.height * 0.3 + (i * size.height * 0.2);
      final phaseShift = animationValue * 2 * math.pi + (i * math.pi / 3);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x++) {
        final y = yOffset +
            math.sin((x / waveLength) * 2 * math.pi + phaseShift) * waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

/// Radial burst gradient background
class RadialBurstBackground extends StatelessWidget {
  final Widget child;
  final int rayCount;
  final double opacity;

  const RadialBurstBackground({
    super.key,
    required this.child,
    this.rayCount = 12,
    this.opacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: themeData.backgroundGradient,
          ),
        ),

        // Radial burst from center
        CustomPaint(
          painter: _RadialBurstPainter(
            color: themeData.primaryColor.withValues(alpha: opacity),
            rayCount: rayCount,
          ),
          size: Size.infinite,
        ),

        // Content
        child,
      ],
    );
  }
}

class _RadialBurstPainter extends CustomPainter {
  final Color color;
  final int rayCount;

  _RadialBurstPainter({
    required this.color,
    required this.rayCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final path = Path();

      path.moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );
      path.lineTo(
        center.dx + math.cos(angle + 0.3) * maxRadius,
        center.dy + math.sin(angle + 0.3) * maxRadius,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating particles gradient background
class ParticleGradientBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;

  const ParticleGradientBackground({
    super.key,
    required this.child,
    this.particleCount = 20,
  });

  @override
  State<ParticleGradientBackground> createState() =>
      _ParticleGradientBackgroundState();
}

class _ParticleGradientBackgroundState extends State<ParticleGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    particles = List.generate(
      widget.particleCount,
      (i) => _Particle(
        seed: i.toDouble(),
      ),
    );
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
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: themeData.backgroundGradient,
          ),
        ),

        // Floating particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(
                particles: particles,
                animationValue: _controller.value,
                color1: themeData.primaryColor.withValues(alpha: 0.06),
                color2: themeData.accentColor.withValues(alpha: 0.04),
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double seed;
  final double size;
  final double speedX;
  final double speedY;

  _Particle({required this.seed})
      : size = 40 + (seed % 5) * 20,
        speedX = 0.1 + (seed % 3) * 0.05,
        speedY = 0.15 + (seed % 4) * 0.05;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Color color1;
  final Color color2;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final paint = Paint()
        ..color = i % 2 == 0 ? color1 : color2
        ..style = PaintingStyle.fill;

      final x = (particle.seed * size.width +
              animationValue * particle.speedX * size.width) %
          size.width;
      final y = (particle.seed * size.height +
              animationValue * particle.speedY * size.height) %
          size.height;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
