import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_access.dart';

/// Premium confetti animation for celebrations
///
/// Shows colorful confetti particles falling from the top
/// Perfect for success actions like trip creation, invite acceptance
class ConfettiAnimation extends StatefulWidget {
  final bool show;
  final Duration duration;
  final VoidCallback? onComplete;
  final int particleCount;

  const ConfettiAnimation({
    super.key,
    this.show = false,
    this.duration = const Duration(milliseconds: 3000),
    this.onComplete,
    this.particleCount = 100,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.show) {
      _generateParticles();
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _generateParticles();
      _controller.reset();
      _controller.forward();
    }
  }

  void _generateParticles() {
    _particles.clear();
    // Get theme data in initState - store it for later use
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(ConfettiParticle(
        color: _getRandomColor(),
        size: _random.nextDouble() * 10 + 5,
        startX: _random.nextDouble(),
        startY: -0.1,
        endX: _random.nextDouble(),
        endY: 1.2,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: _random.nextDouble() * 4 - 2,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      AppTheme.accentCoral,
      AppTheme.accentGold,
      AppTheme.accentPurple,
      AppTheme.accentOrange,
      AppTheme.success,
      AppTheme.info,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double rotation;
  final double rotationSpeed;

  ConfettiParticle({
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      final x = size.width * (particle.startX + (particle.endX - particle.startX) * progress);
      final y = size.height * (particle.startY + (particle.endY - particle.startY) * progress);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + particle.rotationSpeed * progress * 2 * pi);

      // Draw confetti as rounded rectangles
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        Radius.circular(particle.size * 0.2),
      );
      canvas.drawRRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Helper to show confetti overlay
class ConfettiOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 3000),
    int particleCount = 100,
  }) {
    hide(); // Remove any existing confetti

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: ConfettiAnimation(
          show: true,
          duration: duration,
          particleCount: particleCount,
          onComplete: () => hide(),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
