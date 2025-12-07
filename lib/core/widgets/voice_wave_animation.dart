import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Advanced voice wave animation widget
/// Creates a mesmerizing, physics-based audio visualization
/// Inspired by Perplexity AI and modern voice interfaces
class VoiceWaveAnimation extends StatefulWidget {
  final double soundLevel;
  final bool isListening;
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const VoiceWaveAnimation({
    super.key,
    required this.soundLevel,
    required this.isListening,
    this.primaryColor = const Color(0xFF6366F1), // Indigo
    this.secondaryColor = const Color(0xFF8B5CF6), // Purple
    this.size = 200,
  });

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Main pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for the circular waves
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Rotation for the outer ring
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    if (widget.isListening) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _rotationController.repeat();
    _particleController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
    _rotationController.stop();
    _particleController.stop();
  }

  @override
  void didUpdateWidget(VoiceWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isListening && !oldWidget.isListening) {
      _startAnimations();
    } else if (!widget.isListening && oldWidget.isListening) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _waveController,
          _rotationController,
          _particleController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: VoiceWavePainter(
              soundLevel: widget.soundLevel,
              isListening: widget.isListening,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              pulseValue: _pulseAnimation.value,
              glowValue: _glowAnimation.value,
              waveProgress: _waveController.value,
              rotation: _rotationController.value * 2 * math.pi,
              particleProgress: _particleController.value,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

/// Custom painter for the voice wave visualization
class VoiceWavePainter extends CustomPainter {
  final double soundLevel;
  final bool isListening;
  final Color primaryColor;
  final Color secondaryColor;
  final double pulseValue;
  final double glowValue;
  final double waveProgress;
  final double rotation;
  final double particleProgress;

  VoiceWavePainter({
    required this.soundLevel,
    required this.isListening,
    required this.primaryColor,
    required this.secondaryColor,
    required this.pulseValue,
    required this.glowValue,
    required this.waveProgress,
    required this.rotation,
    required this.particleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;

    // Draw outer glow when listening
    if (isListening) {
      _drawOuterGlow(canvas, center, baseRadius);
      _drawExpandingWaves(canvas, center, baseRadius);
      _drawParticles(canvas, center, baseRadius);
    }

    // Draw rotating outer ring
    _drawRotatingRing(canvas, center, baseRadius);

    // Draw frequency bars (circular)
    _drawFrequencyBars(canvas, center, baseRadius);

    // Draw main orb with gradient
    _drawMainOrb(canvas, center, baseRadius);

    // Draw inner core
    _drawInnerCore(canvas, center, baseRadius);

    // Draw center highlight
    _drawCenterHighlight(canvas, center, baseRadius);
  }

  void _drawOuterGlow(Canvas canvas, Offset center, double baseRadius) {
    final glowRadius = baseRadius * 2 * pulseValue;
    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.3 * glowValue * (0.5 + soundLevel * 0.5)),
        primaryColor.withValues(alpha: 0.1 * glowValue),
        primaryColor.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: glowRadius),
      );

    canvas.drawCircle(center, glowRadius, paint);
  }

  void _drawExpandingWaves(Canvas canvas, Offset center, double baseRadius) {
    for (int i = 0; i < 3; i++) {
      final progress = (waveProgress + i * 0.33) % 1.0;
      final waveRadius = baseRadius * 1.5 + progress * baseRadius * 1.5;
      final opacity = (1.0 - progress) * 0.4 * (0.3 + soundLevel * 0.7);

      final paint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - progress);

      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  void _drawParticles(Canvas canvas, Offset center, double baseRadius) {
    const particleCount = 12;
    final random = math.Random(42); // Fixed seed for consistent particles

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + rotation * 0.5;
      final particlePhase = (particleProgress + i * 0.08) % 1.0;

      // Spiral outward movement
      final distance = baseRadius * 1.2 + particlePhase * baseRadius * 1.5;
      final wobble = math.sin(particlePhase * math.pi * 4 + i) * 10;

      final x = center.dx + math.cos(angle) * distance + wobble;
      final y = center.dy + math.sin(angle) * distance;

      final particleSize = (3 + random.nextDouble() * 3) * (1 - particlePhase * 0.5);
      final opacity = (1.0 - particlePhase) * 0.6 * (0.5 + soundLevel * 0.5);

      final gradient = RadialGradient(
        colors: [
          secondaryColor.withValues(alpha: opacity),
          primaryColor.withValues(alpha: opacity * 0.5),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: particleSize),
        );

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  void _drawRotatingRing(Canvas canvas, Offset center, double baseRadius) {
    final ringRadius = baseRadius * 1.4;
    const segmentCount = 32;

    for (int i = 0; i < segmentCount; i++) {
      final angle = (i / segmentCount) * 2 * math.pi + rotation;
      final segmentLength = 0.15 + soundLevel * 0.2;

      final startAngle = angle - segmentLength / 2;
      final sweepAngle = segmentLength;

      // Vary segment intensity based on position and sound
      var intensity = 0.3 + math.sin(angle * 3 + waveProgress * 2 * math.pi) * 0.2 +
          soundLevel * 0.5;
      intensity = intensity.clamp(0.0, 1.0);

      final paint = Paint()
        ..color = primaryColor.withValues(alpha: intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  void _drawFrequencyBars(Canvas canvas, Offset center, double baseRadius) {
    const barCount = 24;
    final barRadius = baseRadius * 1.1;

    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi - math.pi / 2;

      // Create varying bar heights based on sound level and position
      final phaseOffset = math.sin(angle * 2 + waveProgress * 4 * math.pi);
      var heightMultiplier = 0.3 + soundLevel * 0.7 + phaseOffset * 0.2 * soundLevel;
      heightMultiplier = heightMultiplier.clamp(0.1, 1.0);
      final barHeight = baseRadius * 0.3 * heightMultiplier;

      final innerRadius = barRadius;
      final outerRadius = barRadius + barHeight;

      final x1 = center.dx + math.cos(angle) * innerRadius;
      final y1 = center.dy + math.sin(angle) * innerRadius;
      final x2 = center.dx + math.cos(angle) * outerRadius;
      final y2 = center.dy + math.sin(angle) * outerRadius;

      // Gradient from primary to secondary based on height
      final t = heightMultiplier.clamp(0.0, 1.0);
      final color = Color.lerp(primaryColor, secondaryColor, t)!;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  void _drawMainOrb(Canvas canvas, Offset center, double baseRadius) {
    final orbRadius = baseRadius * pulseValue;

    // Main gradient orb
    final gradient = RadialGradient(
      colors: [
        secondaryColor.withValues(alpha: 0.9),
        primaryColor.withValues(alpha: 0.8),
        primaryColor.withValues(alpha: 0.6),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: orbRadius),
      );

    canvas.drawCircle(center, orbRadius, paint);

    // Highlight/shine effect
    final highlightGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Colors.white.withValues(alpha: 0.4),
        Colors.white.withValues(alpha: 0.0),
      ],
    );

    final highlightPaint = Paint()
      ..shader = highlightGradient.createShader(
        Rect.fromCircle(center: center, radius: orbRadius),
      );

    canvas.drawCircle(center, orbRadius, highlightPaint);
  }

  void _drawInnerCore(Canvas canvas, Offset center, double baseRadius) {
    final coreRadius = baseRadius * 0.6 * pulseValue;

    // Pulsing inner core
    final coreIntensity = 0.5 + soundLevel * 0.5;
    final coreGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: coreIntensity * 0.8),
        secondaryColor.withValues(alpha: coreIntensity * 0.6),
        primaryColor.withValues(alpha: 0.3),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );

    canvas.drawCircle(center, coreRadius, corePaint);
  }

  void _drawCenterHighlight(Canvas canvas, Offset center, double baseRadius) {
    // Subtle center dot
    final dotRadius = baseRadius * 0.15;
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(center, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) {
    return oldDelegate.soundLevel != soundLevel ||
        oldDelegate.isListening != isListening ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.particleProgress != particleProgress;
  }
}

/// Morphing blob animation for idle state
class MorphingBlobAnimation extends StatefulWidget {
  final double size;
  final Color color;

  const MorphingBlobAnimation({
    super.key,
    this.size = 150,
    this.color = const Color(0xFF6366F1),
  });

  @override
  State<MorphingBlobAnimation> createState() => _MorphingBlobAnimationState();
}

class _MorphingBlobAnimationState extends State<MorphingBlobAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MorphingBlobPainter(
            progress: _controller.value,
            color: widget.color,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }
}

class MorphingBlobPainter extends CustomPainter {
  final double progress;
  final Color color;

  MorphingBlobPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 3;

    final path = Path();
    const points = 6;

    for (int i = 0; i <= points * 10; i++) {
      final angle = (i / (points * 10)) * 2 * math.pi;

      // Create organic blob shape with multiple sine waves
      final wobble1 = math.sin(angle * 3 + progress * 2 * math.pi) * 0.15;
      final wobble2 = math.cos(angle * 2 + progress * 3 * math.pi) * 0.1;
      final wobble3 = math.sin(angle * 5 + progress * 4 * math.pi) * 0.05;

      final radius = baseRadius * (1 + wobble1 + wobble2 + wobble3);
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    // Gradient fill
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.4),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: baseRadius * 1.3),
      );

    canvas.drawPath(path, paint);

    // Subtle glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(MorphingBlobPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
