// AI Orb Animation - Beautiful Morphing Orb Effect
//
// A stunning AI orb animation with seamless looping morphing effects
// Features multiple flowing colors: cyan, purple, magenta, and gold
// Responds to sound levels for reactive listening animation

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Seamless looping morphing orb with multiple flowing colors
/// Perfect for AI listening states with sound-reactive effects
class AiOrbAnimation extends StatefulWidget {
  const AiOrbAnimation({
    super.key,
    this.size = 200,
    this.isActive = true,
    this.soundLevel = 0.0,
    this.period = const Duration(milliseconds: 3600),
  });

  final double size;
  final bool isActive;
  final double soundLevel;
  final Duration period;

  @override
  State<AiOrbAnimation> createState() => _AiOrbAnimationState();
}

class _AiOrbAnimationState extends State<AiOrbAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Smooth sound level for natural transitions
  double _smoothSoundLevel = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();

    _controller.addListener(_updateSmoothSoundLevel);
  }

  void _updateSmoothSoundLevel() {
    final target = widget.soundLevel;
    // Smooth interpolation for sound level
    _smoothSoundLevel = _smoothSoundLevel + (target - _smoothSoundLevel) * 0.1;
  }

  @override
  void didUpdateWidget(covariant AiOrbAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
      _controller.repeat();
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.duration = widget.period;
      } else {
        // Slow down when inactive
        _controller.duration = const Duration(milliseconds: 6000);
      }
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = reduceMotion ? 0.0 : _controller.value;

            return CustomPaint(
              painter: _AiOrbPainter(
                t: t,
                soundLevel: _smoothSoundLevel,
                isActive: widget.isActive,
                reduceMotion: reduceMotion,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AiOrbPainter extends CustomPainter {
  _AiOrbPainter({
    required this.t,
    required this.soundLevel,
    required this.isActive,
    required this.reduceMotion,
  });

  final double t; // 0..1 animation progress
  final double soundLevel;
  final bool isActive;
  final bool reduceMotion;

  // Multi-color palette
  static const Color _cyanColor = Color(0xFF00D9FF);
  static const Color _purpleColor = Color(0xFF8B5CF6);
  static const Color _magentaColor = Color(0xFFE040FB);
  static const Color _goldColor = Color(0xFFFFD54F);
  static const Color _tealColor = Color(0xFF00BFA5);

  // Easing function for smooth animations
  static double _ease(double x) => 0.5 - 0.5 * cos(x * pi);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;

    // Use 2*pi*t for seamless looping (t goes 0->1 continuously)
    final phase = t * 2 * pi;

    // Breathing effect - uses integer frequency for seamless loop
    final breathe = _ease((sin(phase) + 1) / 2);

    // Listen pulse - double frequency, still seamless
    final listenPulse = _ease((sin(phase * 2) + 1) / 2);

    // Sound reactive adjustments
    final soundAmp = isActive ? soundLevel * 0.25 : 0.0;
    final baseR = r * (0.40 + 0.04 * breathe + soundAmp * 0.05);

    // Morphing amplitude
    final morphAmp = reduceMotion ? 0.0 : (0.03 + 0.02 * listenPulse + soundAmp * 0.025);

    // Draw layers
    _drawOuterGlow(canvas, c, baseR, phase, listenPulse, soundAmp);
    _drawMiddleGlow(canvas, c, baseR, phase, listenPulse);
    _drawMainOrb(canvas, c, baseR, phase, morphAmp, breathe, listenPulse);
    _drawInnerCore(canvas, c, baseR, phase, breathe, listenPulse);
    _drawHighlights(canvas, c, baseR, phase, breathe);
  }

  void _drawOuterGlow(Canvas canvas, Offset c, double baseR, double phase,
      double listenPulse, double soundAmp) {
    final glowRadius = baseR * 1.6;
    final intensity = 0.12 + listenPulse * 0.08 + soundAmp * 0.08;

    final colors = [
      _cyanColor.withValues(alpha: intensity * 0.5),
      _purpleColor.withValues(alpha: intensity * 0.4),
      _magentaColor.withValues(alpha: intensity * 0.3),
      Colors.transparent,
    ];

    final gradient = ui.Gradient.radial(
      c,
      glowRadius,
      colors,
      [0.0, 0.4, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(c, glowRadius, paint);
  }

  void _drawMiddleGlow(Canvas canvas, Offset c, double baseR, double phase,
      double listenPulse) {
    final glowRadius = baseR * 1.3;
    final intensity = 0.20 + listenPulse * 0.12;

    // Smoothly interpolate colors based on phase
    final colorMix = (sin(phase) + 1) / 2;
    final color1 = Color.lerp(_cyanColor, _purpleColor, colorMix)!;
    final color2 = Color.lerp(_purpleColor, _magentaColor, colorMix)!;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color1.withValues(alpha: intensity),
          color2.withValues(alpha: intensity * 0.8),
          _tealColor.withValues(alpha: intensity * 0.6),
          color1.withValues(alpha: intensity),
        ],
        stops: const [0.0, 0.33, 0.67, 1.0],
        transform: GradientRotation(phase),
      ).createShader(Rect.fromCircle(center: c, radius: glowRadius))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseR * 0.25)
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(c, glowRadius, paint);
  }

  void _drawMainOrb(Canvas canvas, Offset c, double baseR, double phase,
      double amp, double breathe, double listenPulse) {
    // Create smooth blob using cubic bezier curves
    final path = _createSmoothBlob(c, baseR, phase, amp);

    // Halo effect with seamless sweep gradient
    final haloIntensity = 0.18 + 0.08 * listenPulse;
    final haloPaint = Paint()
      ..blendMode = BlendMode.screen
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = SweepGradient(
        colors: [
          _cyanColor.withValues(alpha: haloIntensity),
          _purpleColor.withValues(alpha: haloIntensity * 0.9),
          _magentaColor.withValues(alpha: haloIntensity * 0.8),
          _goldColor.withValues(alpha: haloIntensity * 0.6),
          _cyanColor.withValues(alpha: haloIntensity),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(phase * 0.5),
      ).createShader(Rect.fromCircle(center: c, radius: baseR * 1.5));
    canvas.drawPath(path, haloPaint);

    // Main fill with radial gradient
    final colorMix = (sin(phase) + 1) / 2;
    final mainColor = Color.lerp(_cyanColor, _purpleColor, colorMix)!;
    final secondaryColor = Color.lerp(_purpleColor, _magentaColor, colorMix)!;

    final fillPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = ui.Gradient.radial(
        c.translate(-baseR * 0.15, -baseR * 0.18),
        baseR * 2.2,
        [
          Colors.white.withValues(alpha: 0.12),
          mainColor.withValues(alpha: 0.80 * (0.75 + 0.25 * breathe)),
          secondaryColor.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        [0.0, 0.45, 0.75, 1.0],
      );
    canvas.drawPath(path, fillPaint);

    // Subtle edge highlight
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.screen
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          _cyanColor.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.10),
          _purpleColor.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.10),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(phase * 0.3),
      ).createShader(Rect.fromCircle(center: c, radius: baseR * 1.2));
    canvas.drawPath(path, edgePaint);
  }

  /// Creates a smooth blob path using cubic bezier curves
  /// Uses only integer frequency multipliers for seamless looping
  Path _createSmoothBlob(Offset c, double baseR, double phase, double amp) {
    final path = Path();
    const segments = 6; // Number of control points (must be even for symmetry)
    final points = <Offset>[];

    // Generate control points with smooth deformation
    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * pi;

      // Use only integer multiples of phase for seamless looping
      // wave1: 2x frequency, wave2: 3x frequency, wave3: 4x frequency
      final wave1 = sin(angle * 2 + phase * 2) * 0.5;
      final wave2 = sin(angle * 3 + phase * 3) * 0.3;
      final wave3 = sin(angle * 4 - phase * 4) * 0.2;

      final deform = (wave1 + wave2 + wave3) * amp;
      final radius = baseR * (1.0 + deform);

      points.add(Offset(
        c.dx + radius * cos(angle),
        c.dy + radius * sin(angle),
      ));
    }

    // Create smooth closed curve using cubic bezier
    // Catmull-Rom to Bezier conversion for smooth curves
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < segments; i++) {
      final p0 = points[(i - 1 + segments) % segments];
      final p1 = points[i];
      final p2 = points[(i + 1) % segments];
      final p3 = points[(i + 2) % segments];

      // Calculate control points using Catmull-Rom spline
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    path.close();
    return path;
  }

  void _drawInnerCore(Canvas canvas, Offset c, double baseR, double phase,
      double breathe, double listenPulse) {
    final coreRadius = baseR * (0.5 + 0.05 * breathe);
    final intensity = 0.35 + 0.15 * listenPulse;

    // Inner glowing core with color shift
    final colorMix = (sin(phase * 0.5) + 1) / 2 * 0.3;
    final coreColor = Color.lerp(_cyanColor, _goldColor, colorMix)!;

    final coreGradient = ui.Gradient.radial(
      c,
      coreRadius,
      [
        Colors.white.withValues(alpha: intensity * 0.7),
        coreColor.withValues(alpha: intensity * 0.5),
        coreColor.withValues(alpha: intensity * 0.15),
        Colors.transparent,
      ],
      [0.0, 0.3, 0.6, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(c, coreRadius, corePaint);
  }

  void _drawHighlights(Canvas canvas, Offset c, double baseR, double phase,
      double breathe) {
    // Top-left specular highlight
    final highlightOffset = Offset(-baseR * 0.25, -baseR * 0.25);
    final highlightRadius = baseR * 0.3;

    final highlightGradient = ui.Gradient.radial(
      c + highlightOffset,
      highlightRadius,
      [
        Colors.white.withValues(alpha: 0.20 + 0.08 * breathe),
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );

    final highlightPaint = Paint()
      ..shader = highlightGradient
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(c + highlightOffset, highlightRadius, highlightPaint);

    // Bottom-right color accent
    final accentOffset = Offset(baseR * 0.2, baseR * 0.3);
    final accentRadius = baseR * 0.25;

    final colorMix = (sin(phase + pi) + 1) / 2;
    final accentColor = Color.lerp(_purpleColor, _magentaColor, colorMix)!;

    final accentGradient = ui.Gradient.radial(
      c + accentOffset,
      accentRadius,
      [
        accentColor.withValues(alpha: 0.12),
        accentColor.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );

    final accentPaint = Paint()
      ..shader = accentGradient
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(c + accentOffset, accentRadius, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _AiOrbPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.isActive != isActive ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
