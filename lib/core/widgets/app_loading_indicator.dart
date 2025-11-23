import 'package:flutter/material.dart';

/// Bouncing Bus Loader - Reusable loading indicator across the app
/// Replicates the CSS animation from assets/bouncing_bus_loader/
class AppLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = 90,
    this.message,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _roadAnimation;

  @override
  void initState() {
    super.initState();

    // 600ms animation cycle (matching CSS)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();

    // Bus bounce: 0 -> -5px -> 0
    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -5,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Road sliding animation
    _roadAnimation = Tween<double>(
      begin: 0,
      end: -18,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size * 0.78, // Maintain aspect ratio
          child: Stack(
            children: [
              // Road at bottom
              Positioned(
                bottom: widget.size * 0.089,
                left: widget.size * 0.067,
                right: widget.size * 0.067,
                child: AnimatedBuilder(
                  animation: _roadAnimation,
                  builder: (context, child) {
                    return Container(
                      height: widget.size * 0.089,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.9),
                            const Color(0xFF0F172A).withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          children: [
                            Positioned(
                              top: widget.size * 0.033,
                              bottom: widget.size * 0.033,
                              left: _roadAnimation.value,
                              right: -18,
                              child: CustomPaint(
                                painter: _RoadDashesPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bouncing bus
              Positioned(
                bottom: widget.size * 0.2,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: Center(
                        child: Container(
                          width: widget.size * 0.689,
                          height: widget.size * 0.356,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(widget.size * 0.111),
                              topRight: Radius.circular(widget.size * 0.111),
                              bottomLeft: Radius.circular(widget.size * 0.133),
                              bottomRight: Radius.circular(widget.size * 0.133),
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF22D3EE), // Cyan
                                Color(0xFF0EA5E9), // Blue
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                                blurRadius: widget.size * 0.2,
                                offset: Offset(0, widget.size * 0.089),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Window
                              Positioned(
                                top: widget.size * 0.067,
                                left: widget.size * 0.111,
                                right: widget.size * 0.111,
                                bottom: widget.size * 0.156,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(widget.size * 0.089),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFE0F2FE), // Light cyan
                                        Color(0xFF7DD3FC), // Lighter blue
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Left wheel
                              Positioned(
                                bottom: widget.size * -0.089,
                                left: widget.size * 0.133,
                                child: Container(
                                  width: widget.size * 0.144,
                                  height: widget.size * 0.144,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF020617),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // Right wheel
                              Positioned(
                                bottom: widget.size * -0.089,
                                right: widget.size * 0.133,
                                child: Container(
                                  width: widget.size * 0.144,
                                  height: widget.size * 0.144,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF020617),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (widget.message != null) ...[
          SizedBox(height: widget.size * 0.178),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: widget.size * 0.156,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Custom painter for road dashes
class _RoadDashesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.fill;

    // Draw repeating dashes (12px dash, 6px gap = 18px cycle)
    double x = 4;
    while (x < size.width + 18) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, 12, 2),
          const Radius.circular(1),
        ),
        paint,
      );
      x += 18;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
