import 'dart:math' as math;
import 'package:flutter/material.dart';

/// AI Ring Animation - Organic Glowing Ring Effect
/// Flowing cyan and purple colors around a circular shape
class AISphereAnimation extends StatefulWidget {
  final double size;
  final bool isActive;
  final double soundLevel;
  final Color primaryColor;
  final Color glowColor;

  const AISphereAnimation({
    super.key,
    this.size = 250,
    this.isActive = false,
    this.soundLevel = 0.0,
    this.primaryColor = const Color(0xFF00D9FF),
    this.glowColor = const Color(0xFF00D9FF),
  });

  @override
  State<AISphereAnimation> createState() => _AISphereAnimationState();
}

class _AISphereAnimationState extends State<AISphereAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _morphController;
  late AnimationController _pulseController;
  late AnimationController _colorController;

  // Smooth sound level for natural transitions
  double _smoothSoundLevel = 0.0;
  double _targetSoundLevel = 0.0;

  @override
  void initState() {
    super.initState();

    // Main rotation - smooth continuous flow
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    // Morphing animation for organic shape
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();

    // Pulse/breathing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Color flow animation
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Smooth sound level updates
    _rotationController.addListener(_updateSmoothSoundLevel);
  }

  void _updateSmoothSoundLevel() {
    _targetSoundLevel = widget.soundLevel;
    _smoothSoundLevel = _smoothSoundLevel + (_targetSoundLevel - _smoothSoundLevel) * 0.08;
  }

  @override
  void didUpdateWidget(AISphereAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _rotationController.duration = const Duration(milliseconds: 4000);
      _morphController.duration = const Duration(milliseconds: 3000);
      _pulseController.duration = const Duration(milliseconds: 1500);
    } else if (!widget.isActive && oldWidget.isActive) {
      _rotationController.duration = const Duration(milliseconds: 8000);
      _morphController.duration = const Duration(milliseconds: 5000);
      _pulseController.duration = const Duration(milliseconds: 3000);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _morphController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _rotationController,
        _morphController,
        _pulseController,
        _colorController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow
              _buildBackgroundGlow(),

              // Main ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _OrganicRingPainter(
                  rotationPhase: _rotationController.value * 2 * math.pi,
                  morphPhase: _morphController.value * 2 * math.pi,
                  pulseValue: _pulseController.value,
                  colorPhase: _colorController.value * 2 * math.pi,
                  isActive: widget.isActive,
                  soundLevel: _smoothSoundLevel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundGlow() {
    final intensity = widget.isActive ? 0.3 + _smoothSoundLevel * 0.2 : 0.15;
    final glowSize = widget.size * (0.7 + _pulseController.value * 0.05);

    return Container(
      width: glowSize,
      height: glowSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withValues(alpha: intensity * 0.5),
            blurRadius: 80,
            spreadRadius: 20,
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: intensity * 0.4),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for organic flowing ring
class _OrganicRingPainter extends CustomPainter {
  final double rotationPhase;
  final double morphPhase;
  final double pulseValue;
  final double colorPhase;
  final bool isActive;
  final double soundLevel;

  _OrganicRingPainter({
    required this.rotationPhase,
    required this.morphPhase,
    required this.pulseValue,
    required this.colorPhase,
    required this.isActive,
    required this.soundLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;

    // Draw multiple ring layers for depth
    _drawRingLayer(canvas, center, baseRadius, 0, 0.15, 12.0); // Outer glow
    _drawRingLayer(canvas, center, baseRadius, 1, 0.25, 8.0);
    _drawRingLayer(canvas, center, baseRadius, 2, 0.4, 5.0);
    _drawRingLayer(canvas, center, baseRadius, 3, 0.6, 3.0);
    _drawRingLayer(canvas, center, baseRadius, 4, 0.85, 2.0); // Core
  }

  void _drawRingLayer(Canvas canvas, Offset center, double baseRadius,
      int layerIndex, double alpha, double blur) {
    final path = Path();

    // Layer-specific parameters
    final layerOffset = layerIndex * 0.15;
    final radiusScale = 1.0 - layerIndex * 0.02;

    // Sound reactive amplitude
    final soundAmplitude = isActive ? soundLevel * 0.15 : 0.0;
    final baseAmplitude = isActive ? 0.08 + soundAmplitude : 0.05;

    // Create organic ring shape
    const segments = 120;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = t * 2 * math.pi;

      // Calculate organic radius variation
      final organicOffset = _calculateOrganicOffset(
        angle,
        baseAmplitude,
        layerOffset,
        layerIndex,
      );

      final radius = baseRadius * radiusScale * (1.0 + organicOffset);
      final x = center.dx + radius * math.cos(angle + rotationPhase * 0.3);
      final y = center.dy + radius * math.sin(angle + rotationPhase * 0.3);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Create gradient colors based on angle
    final colors = _getLayerColors(layerIndex, alpha);

    // Draw glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isActive ? 4.0 : 2.5) - layerIndex * 0.3 + blur
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: colors,
        startAngle: colorPhase,
        endAngle: colorPhase + 2 * math.pi,
        transform: GradientRotation(rotationPhase * 0.5),
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.2));

    canvas.drawPath(path, glowPaint);

    // Draw main stroke for inner layers
    if (layerIndex >= 2) {
      final mainPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isActive ? 3.0 : 2.0) - layerIndex * 0.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = SweepGradient(
          center: Alignment.center,
          colors: colors,
          startAngle: colorPhase,
          endAngle: colorPhase + 2 * math.pi,
          transform: GradientRotation(rotationPhase * 0.5),
        ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.2));

      canvas.drawPath(path, mainPaint);
    }
  }

  double _calculateOrganicOffset(double angle, double amplitude,
      double layerOffset, int layerIndex) {
    // Multiple wave components for organic feel
    final wave1 = math.sin(angle * 3 + morphPhase + layerOffset) * 0.5;
    final wave2 = math.sin(angle * 5 + morphPhase * 0.7 + layerOffset * 2) * 0.3;
    final wave3 = math.sin(angle * 2 + morphPhase * 1.3 + layerOffset * 0.5) * 0.2;

    // Sound reactive component - smooth variation
    final soundWave = isActive
        ? math.sin(angle * 4 + rotationPhase * 2 + layerIndex * 0.5) * soundLevel * 0.3
        : 0.0;

    // Pulse breathing
    final pulseScale = 1.0 + pulseValue * 0.05;

    return (wave1 + wave2 + wave3 + soundWave) * amplitude * pulseScale;
  }

  List<Color> _getLayerColors(int layerIndex, double alpha) {
    // Cyan to purple gradient flowing around the ring
    final cyanColor = Color(0xFF00D9FF).withValues(alpha: alpha);
    final purpleColor = Color(0xFF8B5CF6).withValues(alpha: alpha);
    final darkBlueColor = Color(0xFF1E3A5F).withValues(alpha: alpha * 0.6);
    final whiteColor = Colors.white.withValues(alpha: alpha * 0.8);

    // Different color distributions per layer
    if (layerIndex == 0) {
      // Outer glow - more purple
      return [
        purpleColor,
        darkBlueColor,
        cyanColor,
        darkBlueColor,
        purpleColor,
      ];
    } else if (layerIndex == 1) {
      return [
        cyanColor,
        purpleColor,
        cyanColor,
        purpleColor,
        cyanColor,
      ];
    } else if (layerIndex == 2) {
      return [
        purpleColor,
        cyanColor,
        whiteColor,
        cyanColor,
        purpleColor,
      ];
    } else if (layerIndex == 3) {
      return [
        cyanColor,
        whiteColor,
        purpleColor,
        whiteColor,
        cyanColor,
      ];
    } else {
      // Core - brightest
      return [
        whiteColor,
        cyanColor,
        whiteColor,
        purpleColor,
        whiteColor,
      ];
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicRingPainter oldDelegate) {
    return rotationPhase != oldDelegate.rotationPhase ||
        morphPhase != oldDelegate.morphPhase ||
        pulseValue != oldDelegate.pulseValue ||
        colorPhase != oldDelegate.colorPhase ||
        isActive != oldDelegate.isActive ||
        soundLevel != oldDelegate.soundLevel;
  }
}
