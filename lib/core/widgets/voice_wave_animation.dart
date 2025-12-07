import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ultra-realistic sci-fi voice wave animation
/// Features holographic plasma core, neural network particles,
/// cyberpunk scanning lines, and ethereal waveforms
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
    this.primaryColor = const Color(0xFF00D9FF), // Cyan
    this.secondaryColor = const Color(0xFF8B5CF6), // Purple
    this.size = 200,
  });

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with TickerProviderStateMixin {
  // Core animation controllers
  late AnimationController _coreController;
  late AnimationController _plasmaController;
  late AnimationController _ringController;
  late AnimationController _particleController;
  late AnimationController _scanController;
  late AnimationController _waveController;
  late AnimationController _glitchController;
  late AnimationController _energyController;

  // Smoothed sound level for fluid animations
  double _smoothSoundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    if (widget.isListening) {
      _startAnimations();
    }
  }

  void _initAnimations() {
    // Core pulsing - fast heartbeat
    _coreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Plasma swirl - organic movement
    _plasmaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Ring rotation - slow majestic spin
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Particle system - neural network flow
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Scanning line - cyberpunk effect
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Waveform - audio visualization
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Glitch effect - occasional distortion
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Energy burst
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  void _startAnimations() {
    _coreController.repeat(reverse: true);
    _plasmaController.repeat();
    _ringController.repeat();
    _particleController.repeat();
    _scanController.repeat();
    _waveController.repeat();
    _energyController.repeat();

    // Random glitch trigger
    _triggerRandomGlitch();
  }

  void _triggerRandomGlitch() async {
    while (mounted && widget.isListening) {
      await Future.delayed(Duration(milliseconds: 500 + math.Random().nextInt(2000)));
      if (mounted && widget.isListening) {
        _glitchController.forward(from: 0);
      }
    }
  }

  void _stopAnimations() {
    _coreController.stop();
    _plasmaController.stop();
    _ringController.stop();
    _particleController.stop();
    _scanController.stop();
    _waveController.stop();
    _glitchController.stop();
    _energyController.stop();
  }

  @override
  void didUpdateWidget(VoiceWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Smooth sound level transition
    _smoothSoundLevel = _smoothSoundLevel * 0.7 + widget.soundLevel * 0.3;

    if (widget.isListening && !oldWidget.isListening) {
      _startAnimations();
    } else if (!widget.isListening && oldWidget.isListening) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _coreController.dispose();
    _plasmaController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    _scanController.dispose();
    _waveController.dispose();
    _glitchController.dispose();
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _coreController,
          _plasmaController,
          _ringController,
          _particleController,
          _scanController,
          _waveController,
          _glitchController,
          _energyController,
        ]),
        builder: (context, child) {
          return CustomPaint(
            painter: SciFiVoicePainter(
              soundLevel: widget.soundLevel,
              smoothSoundLevel: _smoothSoundLevel,
              isListening: widget.isListening,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
              coreValue: _coreController.value,
              plasmaValue: _plasmaController.value,
              ringValue: _ringController.value,
              particleValue: _particleController.value,
              scanValue: _scanController.value,
              waveValue: _waveController.value,
              glitchValue: _glitchController.value,
              energyValue: _energyController.value,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

/// Ultra-realistic sci-fi painter
class SciFiVoicePainter extends CustomPainter {
  final double soundLevel;
  final double smoothSoundLevel;
  final bool isListening;
  final Color primaryColor;
  final Color secondaryColor;
  final double coreValue;
  final double plasmaValue;
  final double ringValue;
  final double particleValue;
  final double scanValue;
  final double waveValue;
  final double glitchValue;
  final double energyValue;

  static final math.Random _random = math.Random(42);

  SciFiVoicePainter({
    required this.soundLevel,
    required this.smoothSoundLevel,
    required this.isListening,
    required this.primaryColor,
    required this.secondaryColor,
    required this.coreValue,
    required this.plasmaValue,
    required this.ringValue,
    required this.particleValue,
    required this.scanValue,
    required this.waveValue,
    required this.glitchValue,
    required this.energyValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 4;

    // Apply glitch transformation occasionally
    if (glitchValue > 0 && glitchValue < 0.5) {
      canvas.save();
      canvas.translate(
        math.sin(glitchValue * 20) * 3 * soundLevel,
        math.cos(glitchValue * 15) * 2 * soundLevel,
      );
    }

    // Layer 1: Deep space background glow
    _drawDeepSpaceGlow(canvas, center, baseRadius);

    // Layer 2: Energy field / Holographic grid
    _drawHolographicGrid(canvas, center, baseRadius);

    // Layer 3: Outer energy rings (multiple)
    _drawEnergyRings(canvas, center, baseRadius);

    // Layer 4: Neural network particles
    _drawNeuralParticles(canvas, center, baseRadius);

    // Layer 5: Plasma tendrils
    _drawPlasmaTendrils(canvas, center, baseRadius);

    // Layer 6: Audio waveform ring
    _drawAudioWaveform(canvas, center, baseRadius);

    // Layer 7: Scanning beam
    _drawScanningBeam(canvas, center, baseRadius);

    // Layer 8: Main plasma core
    _drawPlasmaCore(canvas, center, baseRadius);

    // Layer 9: Energy sparks
    _drawEnergySparks(canvas, center, baseRadius);

    // Layer 10: Inner holographic core
    _drawHolographicCore(canvas, center, baseRadius);

    // Layer 11: Central eye / AI lens
    _drawAILens(canvas, center, baseRadius);

    // Layer 12: Data streams
    if (isListening) {
      _drawDataStreams(canvas, center, baseRadius);
    }

    if (glitchValue > 0 && glitchValue < 0.5) {
      canvas.restore();
    }
  }

  void _drawDeepSpaceGlow(Canvas canvas, Offset center, double baseRadius) {
    final intensity = 0.3 + smoothSoundLevel * 0.4;

    // Multiple layered glows for depth
    for (int i = 3; i >= 0; i--) {
      final radius = baseRadius * (2.5 + i * 0.5) * (1 + coreValue * 0.1);
      final gradient = RadialGradient(
        colors: [
          primaryColor.withOpacity(intensity * 0.15 / (i + 1)),
          secondaryColor.withOpacity(intensity * 0.08 / (i + 1)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      canvas.drawCircle(
        center,
        radius,
        Paint()..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
      );
    }
  }

  void _drawHolographicGrid(Canvas canvas, Offset center, double baseRadius) {
    if (!isListening) return;

    final gridPaint = Paint()
      ..color = primaryColor.withOpacity(0.08 + smoothSoundLevel * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Circular grid lines
    for (int i = 1; i <= 6; i++) {
      final radius = baseRadius * 0.4 * i + plasmaValue * 10;
      canvas.drawCircle(center, radius, gridPaint);
    }

    // Radial lines
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * math.pi + ringValue * math.pi * 0.1;
      final innerRadius = baseRadius * 0.3;
      final outerRadius = baseRadius * 2.4;

      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * innerRadius,
          center.dy + math.sin(angle) * innerRadius,
        ),
        Offset(
          center.dx + math.cos(angle) * outerRadius,
          center.dy + math.sin(angle) * outerRadius,
        ),
        gridPaint,
      );
    }
  }

  void _drawEnergyRings(Canvas canvas, Offset center, double baseRadius) {
    // Multiple rotating rings at different speeds
    final rings = [
      (radius: 1.6, rotation: ringValue * 2 * math.pi, width: 2.0, segments: 60),
      (radius: 1.9, rotation: -ringValue * 1.5 * math.pi, width: 1.5, segments: 80),
      (radius: 2.2, rotation: ringValue * math.pi, width: 1.0, segments: 100),
    ];

    for (final ring in rings) {
      final ringRadius = baseRadius * ring.radius;

      for (int i = 0; i < ring.segments; i++) {
        final angle = (i / ring.segments) * 2 * math.pi + ring.rotation;

        // Wave-like intensity variation
        final waveOffset = math.sin(angle * 8 + waveValue * 2 * math.pi + plasmaValue * 4);
        var intensity = 0.2 + waveOffset * 0.15 + smoothSoundLevel * 0.5;
        intensity = intensity.clamp(0.0, 1.0);

        final arcLength = (2 * math.pi / ring.segments) * 0.7;

        final gradient = SweepGradient(
          center: Alignment.center,
          startAngle: angle,
          endAngle: angle + arcLength,
          colors: [
            primaryColor.withOpacity(intensity),
            secondaryColor.withOpacity(intensity * 0.7),
            primaryColor.withOpacity(intensity * 0.3),
          ],
        );

        final paint = Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: ringRadius),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring.width
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ringRadius),
          angle,
          arcLength,
          false,
          paint,
        );
      }
    }
  }

  void _drawNeuralParticles(Canvas canvas, Offset center, double baseRadius) {
    const particleCount = 40;

    for (int i = 0; i < particleCount; i++) {
      final baseAngle = (i / particleCount) * 2 * math.pi;
      final particlePhase = (particleValue + i * 0.025) % 1.0;

      // Spiral outward movement with oscillation
      final spiralOffset = math.sin(particlePhase * 4 * math.pi + i) * 0.3;
      final distance = baseRadius * (0.8 + particlePhase * 1.5 + spiralOffset * smoothSoundLevel);
      final angle = baseAngle + particlePhase * math.pi * 0.5 + ringValue * 0.2;

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      // Particle size based on phase and sound
      final size = (2 + _random.nextDouble() * 3) * (1 - particlePhase * 0.5) * (1 + smoothSoundLevel);
      final opacity = (1 - particlePhase) * 0.8 * (0.4 + smoothSoundLevel * 0.6);

      // Draw particle with glow
      final glowGradient = RadialGradient(
        colors: [
          (i % 3 == 0 ? secondaryColor : primaryColor).withOpacity(opacity),
          (i % 3 == 0 ? primaryColor : secondaryColor).withOpacity(opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      canvas.drawCircle(
        Offset(x, y),
        size * 2,
        Paint()..shader = glowGradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: size * 2),
        ),
      );

      // Bright center
      canvas.drawCircle(
        Offset(x, y),
        size * 0.5,
        Paint()..color = Colors.white.withOpacity(opacity),
      );

      // Draw connection lines between nearby particles
      if (i > 0 && i % 3 == 0) {
        final prevI = i - 3;
        final prevPhase = (particleValue + prevI * 0.025) % 1.0;
        final prevDist = baseRadius * (0.8 + prevPhase * 1.5);
        final prevAngle = (prevI / particleCount) * 2 * math.pi + prevPhase * math.pi * 0.5;

        final px = center.dx + math.cos(prevAngle) * prevDist;
        final py = center.dy + math.sin(prevAngle) * prevDist;

        canvas.drawLine(
          Offset(x, y),
          Offset(px, py),
          Paint()
            ..color = primaryColor.withOpacity(opacity * 0.3)
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  void _drawPlasmaTendrils(Canvas canvas, Offset center, double baseRadius) {
    const tendrilCount = 8;

    for (int i = 0; i < tendrilCount; i++) {
      final baseAngle = (i / tendrilCount) * 2 * math.pi + plasmaValue * math.pi;

      final path = Path();
      path.moveTo(
        center.dx + math.cos(baseAngle) * baseRadius * 0.6,
        center.dy + math.sin(baseAngle) * baseRadius * 0.6,
      );

      // Create organic tendril shape
      for (int j = 1; j <= 20; j++) {
        final t = j / 20;
        final distance = baseRadius * (0.6 + t * 1.2);
        final wobble1 = math.sin(t * 6 + plasmaValue * 4 * math.pi + i) * 0.2;
        final wobble2 = math.cos(t * 4 + plasmaValue * 3 * math.pi + i * 2) * 0.15;
        final angle = baseAngle + (wobble1 + wobble2) * (1 + smoothSoundLevel);

        path.lineTo(
          center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance,
        );
      }

      final gradient = ui.Gradient.linear(
        Offset(center.dx + math.cos(baseAngle) * baseRadius * 0.6,
               center.dy + math.sin(baseAngle) * baseRadius * 0.6),
        Offset(center.dx + math.cos(baseAngle) * baseRadius * 1.8,
               center.dy + math.sin(baseAngle) * baseRadius * 1.8),
        [
          primaryColor.withOpacity(0.4 + smoothSoundLevel * 0.3),
          secondaryColor.withOpacity(0.2),
          Colors.transparent,
        ],
        [0.0, 0.6, 1.0],
      );

      canvas.drawPath(
        path,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + smoothSoundLevel * 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawAudioWaveform(Canvas canvas, Offset center, double baseRadius) {
    final waveRadius = baseRadius * 1.3;
    const segments = 120;

    final path = Path();

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 2 * math.pi;

      // Multi-frequency waveform
      final wave1 = math.sin(angle * 12 + waveValue * 4 * math.pi) * 0.1;
      final wave2 = math.sin(angle * 8 + waveValue * 6 * math.pi + 1) * 0.08;
      final wave3 = math.sin(angle * 20 + waveValue * 8 * math.pi) * 0.05;

      final waveIntensity = (wave1 + wave2 + wave3) * (0.5 + soundLevel * 2);
      final radius = waveRadius * (1 + waveIntensity);

      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    // Glow effect
    canvas.drawPath(
      path,
      Paint()
        ..color = primaryColor.withOpacity(0.15 + soundLevel * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = primaryColor.withOpacity(0.6 + soundLevel * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawScanningBeam(Canvas canvas, Offset center, double baseRadius) {
    if (!isListening) return;

    final scanAngle = scanValue * 2 * math.pi;
    final beamLength = baseRadius * 2.5;

    // Create scanning beam gradient
    final gradient = ui.Gradient.linear(
      center,
      Offset(
        center.dx + math.cos(scanAngle) * beamLength,
        center.dy + math.sin(scanAngle) * beamLength,
      ),
      [
        primaryColor.withOpacity(0.4),
        primaryColor.withOpacity(0.1),
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );

    // Draw beam as a thin triangle
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + math.cos(scanAngle - 0.1) * beamLength,
        center.dy + math.sin(scanAngle - 0.1) * beamLength,
      )
      ..lineTo(
        center.dx + math.cos(scanAngle + 0.1) * beamLength,
        center.dy + math.sin(scanAngle + 0.1) * beamLength,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Scanning line
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(scanAngle) * beamLength,
        center.dy + math.sin(scanAngle) * beamLength,
      ),
      Paint()
        ..color = primaryColor.withOpacity(0.6)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawPlasmaCore(Canvas canvas, Offset center, double baseRadius) {
    final coreRadius = baseRadius * (0.8 + coreValue * 0.15 + smoothSoundLevel * 0.1);

    // Outer plasma glow
    final outerGlow = RadialGradient(
      colors: [
        secondaryColor.withOpacity(0.6),
        primaryColor.withOpacity(0.4),
        primaryColor.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );

    canvas.drawCircle(
      center,
      coreRadius * 1.5,
      Paint()
        ..shader = outerGlow.createShader(
          Rect.fromCircle(center: center, radius: coreRadius * 1.5),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Main plasma body
    final coreGradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.9),
        primaryColor.withOpacity(0.8),
        secondaryColor.withOpacity(0.6),
        secondaryColor.withOpacity(0.3),
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = coreGradient.createShader(
          Rect.fromCircle(center: center, radius: coreRadius),
        ),
    );
  }

  void _drawEnergySparks(Canvas canvas, Offset center, double baseRadius) {
    if (!isListening) return;

    final sparkCount = (10 + soundLevel * 15).toInt();

    for (int i = 0; i < sparkCount; i++) {
      final phase = (energyValue + i * 0.1) % 1.0;
      final angle = _random.nextDouble() * 2 * math.pi + plasmaValue * 2;
      final distance = baseRadius * (0.6 + phase * 0.8);

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final sparkSize = 1 + _random.nextDouble() * 2;
      final opacity = (1 - phase) * 0.8;

      // Draw spark with trail
      final trailLength = 8 + soundLevel * 5;
      final trailAngle = angle + math.pi;

      final gradient = ui.Gradient.linear(
        Offset(x, y),
        Offset(
          x + math.cos(trailAngle) * trailLength,
          y + math.sin(trailAngle) * trailLength,
        ),
        [
          Colors.white.withOpacity(opacity),
          primaryColor.withOpacity(opacity * 0.5),
          Colors.transparent,
        ],
        [0.0, 0.3, 1.0],
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(
          x + math.cos(trailAngle) * trailLength,
          y + math.sin(trailAngle) * trailLength,
        ),
        Paint()
          ..shader = gradient
          ..strokeWidth = sparkSize
          ..strokeCap = StrokeCap.round,
      );

      // Spark core
      canvas.drawCircle(
        Offset(x, y),
        sparkSize,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  void _drawHolographicCore(Canvas canvas, Offset center, double baseRadius) {
    final innerRadius = baseRadius * 0.5 * (1 + coreValue * 0.1);

    // Holographic rings inside core
    for (int i = 0; i < 4; i++) {
      final ringRadius = innerRadius * (0.3 + i * 0.2);
      final rotation = ringValue * (i % 2 == 0 ? 1 : -1) * 2 * math.pi;

      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = primaryColor.withOpacity(0.3 + soundLevel * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Draw small dots on ring
      for (int j = 0; j < 8; j++) {
        final dotAngle = (j / 8) * 2 * math.pi + rotation;
        final dotX = center.dx + math.cos(dotAngle) * ringRadius;
        final dotY = center.dy + math.sin(dotAngle) * ringRadius;

        canvas.drawCircle(
          Offset(dotX, dotY),
          1.5,
          Paint()..color = Colors.white.withOpacity(0.6 + soundLevel * 0.3),
        );
      }
    }
  }

  void _drawAILens(Canvas canvas, Offset center, double baseRadius) {
    final lensRadius = baseRadius * 0.25 * (1 + coreValue * 0.05);

    // Outer lens ring
    canvas.drawCircle(
      center,
      lensRadius * 1.2,
      Paint()
        ..color = primaryColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Lens gradient (eye-like)
    final lensGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      colors: [
        Colors.white,
        primaryColor.withOpacity(0.9),
        secondaryColor.withOpacity(0.8),
        Colors.black.withOpacity(0.3),
      ],
      stops: const [0.0, 0.2, 0.5, 1.0],
    );

    canvas.drawCircle(
      center,
      lensRadius,
      Paint()
        ..shader = lensGradient.createShader(
          Rect.fromCircle(center: center, radius: lensRadius),
        ),
    );

    // Pupil
    canvas.drawCircle(
      Offset(center.dx - lensRadius * 0.1, center.dy - lensRadius * 0.1),
      lensRadius * 0.3,
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    // Highlight
    canvas.drawCircle(
      Offset(center.dx - lensRadius * 0.25, center.dy - lensRadius * 0.25),
      lensRadius * 0.15,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
  }

  void _drawDataStreams(Canvas canvas, Offset center, double baseRadius) {
    const streamCount = 6;

    for (int i = 0; i < streamCount; i++) {
      final baseAngle = (i / streamCount) * 2 * math.pi + energyValue * math.pi;
      final streamLength = baseRadius * 2;

      // Draw binary-like data points along stream
      for (int j = 0; j < 15; j++) {
        final t = (j / 15 + energyValue) % 1.0;
        final distance = baseRadius * 0.8 + t * streamLength * 0.8;
        final wobble = math.sin(t * 10 + i) * 5;

        final x = center.dx + math.cos(baseAngle) * distance + wobble;
        final y = center.dy + math.sin(baseAngle) * distance;

        final opacity = (1 - t) * 0.6;
        final size = 2 + (1 - t) * 2;

        canvas.drawCircle(
          Offset(x, y),
          size,
          Paint()..color = primaryColor.withOpacity(opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(SciFiVoicePainter oldDelegate) => true;
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

    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.4),
      ],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: baseRadius * 1.3),
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  @override
  bool shouldRepaint(MorphingBlobPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
