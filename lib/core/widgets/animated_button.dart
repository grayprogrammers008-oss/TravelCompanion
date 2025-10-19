import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_access.dart';

/// Premium animated button with scale and ripple effects
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool isLoading;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.gradient,
    this.padding,
    this.borderRadius,
    this.elevation = 4.0,
    this.isLoading = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading ? _handleTapDown : null,
      onTapUp: widget.onPressed != null && !widget.isLoading ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading ? _handleTapCancel : null,
      onTap: widget.onPressed != null && !widget.isLoading ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: widget.gradient ?? (widget.backgroundColor != null
                    ? LinearGradient(
                        colors: [widget.backgroundColor!, widget.backgroundColor!],
                      )
                    : themeData.primaryGradient),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: themeData.primaryColor.withValues(alpha: 0.3),
                    blurRadius: _isPressed ? widget.elevation / 2 : widget.elevation * 2,
                    offset: Offset(0, _isPressed ? widget.elevation / 4 : widget.elevation),
                  ),
                ],
              ),
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
              ),
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Ripple effect button with expanding circles
class RippleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? rippleColor;
  final Duration rippleDuration;

  const RippleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.rippleColor,
    this.rippleDuration = const Duration(milliseconds: 600),
  });

  @override
  State<RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<RippleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.rippleDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
    });
    _controller.forward(from: 0.0);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTap : null,
      child: CustomPaint(
        painter: RipplePainter(
          animation: _animation,
          tapPosition: _tapPosition,
          color: widget.rippleColor ?? themeData.primaryColor.withValues(alpha: 0.3),
        ),
        child: widget.child,
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset? tapPosition;
  final Color color;

  RipplePainter({
    required this.animation,
    required this.tapPosition,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (tapPosition == null) return;

    final paint = Paint()
      ..color = color.withValues(alpha: color.a * (1.0 - animation.value))
      ..style = PaintingStyle.fill;

    final maxRadius = (size.width > size.height ? size.width : size.height) * 1.5;
    final radius = maxRadius * animation.value;

    canvas.drawCircle(tapPosition!, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.tapPosition != tapPosition;
  }
}

/// Floating Action Button with pulse animation
class PulseFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double size;
  final bool showPulse;

  const PulseFAB({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.gradient,
    this.size = 56.0,
    this.showPulse = true,
  });

  @override
  State<PulseFAB> createState() => _PulseFABState();
}

class _PulseFABState extends State<PulseFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.showPulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.showPulse && _controller.isAnimating) {
      _controller.stop();
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
      alignment: Alignment.center,
      children: [
        // Pulse rings
        if (widget.showPulse)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size * _scaleAnimation.value,
                height: widget.size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.gradient ??
                      LinearGradient(
                        colors: [
                          themeData.primaryColor.withValues(alpha: _opacityAnimation.value),
                          themeData.primaryColor.withValues(alpha: _opacityAnimation.value * 0.5),
                        ],
                      ),
                ),
              );
            },
          ),

        // Main FAB
        AnimatedButton(
          onPressed: widget.onPressed,
          gradient: widget.gradient,
          backgroundColor: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.size / 2),
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
        ),
      ],
    );
  }
}

/// Glossy button with shine effect
class GlossyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlossyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradient,
    this.borderRadius,
    this.padding,
  });

  @override
  State<GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<GlossyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    return AnimatedButton(
      onPressed: widget.onPressed,
      gradient: widget.gradient,
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      child: Stack(
        children: [
          widget.child,
          // Shine overlay
          AnimatedBuilder(
            animation: _shineAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusMd),
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
                          Colors.white.withValues(alpha: 0.3),
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
    );
  }
}
