import 'dart:math';
import 'package:flutter/material.dart';

/// SmartGeoLoader - A morphing geometric shape loader
/// Features smooth transitions between unique polygon shapes
/// with gradient stroke and slow rotation for a premium look
class AppLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final Color? secondaryColor;

  const AppLoadingIndicator({
    super.key,
    this.size = 100,
    this.message,
    this.color,
    this.secondaryColor,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _morphController;
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final Stopwatch _stopwatch;

  final _factory = _ShapeFactory(
    vertices: 7,
    recentMemory: 30,
    seed: DateTime.now().millisecondsSinceEpoch,
  );

  late _Shape _current;
  late _Shape _next;

  double _morphStartTime = 0.0;

  static const double morphDuration = 1.55;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();

    _current = _factory.nextUnique();
    _next = _factory.nextUnique(avoidLike: _current);

    // Morph animation controller
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_onTick)
      ..repeat();

    // Slow rotation controller (20 seconds for full rotation)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse/breathing controller (2 seconds per breath cycle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Subtle scale: 1.0 -> 1.05 -> 1.0
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _onTick() {
    final now = _stopwatch.elapsedMicroseconds / 1e6;
    final progress = (now - _morphStartTime) / morphDuration;

    if (progress >= 1.0) {
      _morphStartTime = now;
      _current = _next;
      _next = _factory.nextUnique(avoidLike: _current);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _morphController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = _stopwatch.elapsedMicroseconds / 1e6;
    final progress = ((now - _morphStartTime) / morphDuration).clamp(0.0, 1.0);

    // Primary and secondary colors for gradient
    final primaryColor = widget.color ?? const Color(0xFF0EA5E9); // Cyan blue
    final secondaryColor = widget.secondaryColor ?? const Color(0xFF8B5CF6); // Purple

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // White circle badge behind the loader
        Stack(
          alignment: Alignment.center,
          children: [
            // Semi-transparent white circle backdrop
            Container(
              width: widget.size * 0.85,
              height: widget.size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            // The animated loader
            AnimatedBuilder(
              animation: Listenable.merge([_rotationController, _pulseController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _GeoPainter(
                          progress: progress,
                          current: _current,
                          next: _next,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          rotationValue: _rotationController.value,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        if (widget.message != null) ...[
          SizedBox(height: widget.size * 0.2),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: widget.size * 0.14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _GeoPainter extends CustomPainter {
  final double progress;
  final _Shape current;
  final _Shape next;
  final Color primaryColor;
  final Color secondaryColor;
  final double rotationValue;

  _GeoPainter({
    required this.progress,
    required this.current,
    required this.next,
    required this.primaryColor,
    required this.secondaryColor,
    required this.rotationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dimension = min(size.width, size.height);

    final patchRadius = dimension * 0.46;
    const margin = 8.0;
    final allowedRadius = patchRadius - margin;

    // Calculate morph progress with easing
    final easedProgress = _smootherstep(progress);

    // Align next shape vertices to current for smooth transition
    final alignedNext = _bestAlign(current.points, next.points);

    // Interpolate vertices
    final interpolatedPoints = List<Offset>.generate(current.points.length, (i) {
      return Offset.lerp(current.points[i], alignedNext[i], easedProgress)!;
    });

    // Fit to canvas and constrain within circle
    var canvasPoints = _fitToRadius(interpolatedPoints, center, allowedRadius * 0.92);
    canvasPoints = _shrinkToCircle(canvasPoints, center, allowedRadius);

    // Build smooth path using Catmull-Rom splines for seamless curves
    final path = _createSmoothPath(canvasPoints);

    // Create seamless sweep gradient for the stroke using SweepGradient
    // (no explicit start/end angles to avoid seam line)
    final gradientShader = SweepGradient(
      colors: [
        primaryColor,
        secondaryColor,
        primaryColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(rotationValue * 2 * pi),
    ).createShader(Rect.fromCircle(center: center, radius: dimension / 2));

    // Draw main stroke with gradient
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = gradientShader,
    );
  }

  List<Offset> _bestAlign(List<Offset> a, List<Offset> b) {
    final n = a.length;
    double bestScore = double.infinity;
    late List<Offset> bestB;

    double score(List<Offset> x) {
      double s = 0;
      for (int i = 0; i < n; i++) {
        final d = a[i] - x[i];
        s += d.dx * d.dx + d.dy * d.dy;
      }
      return s;
    }

    for (int shift = 0; shift < n; shift++) {
      final candidate = List<Offset>.generate(n, (i) => b[(i + shift) % n]);
      final sc = score(candidate);
      if (sc < bestScore) {
        bestScore = sc;
        bestB = candidate;
      }
    }

    final reversed = b.reversed.toList();
    for (int shift = 0; shift < n; shift++) {
      final candidate = List<Offset>.generate(n, (i) => reversed[(i + shift) % n]);
      final sc = score(candidate);
      if (sc < bestScore) {
        bestScore = sc;
        bestB = candidate;
      }
    }

    return bestB;
  }

  List<Offset> _shrinkToCircle(List<Offset> pts, Offset center, double allowedR) {
    double maxDist = 0.0;
    for (final p in pts) {
      maxDist = max(maxDist, (p - center).distance);
    }
    if (maxDist <= allowedR || maxDist == 0) return pts;
    final scale = allowedR / maxDist;
    return pts.map((p) => center + (p - center) * scale).toList();
  }

  List<Offset> _fitToRadius(List<Offset> pts, Offset center, double radius) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final p in pts) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }

    final w = maxX - minX;
    final h = maxY - minY;
    final scale = (radius * 2) / max(w == 0 ? 1 : w, h == 0 ? 1 : h);

    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    return pts.map((p) {
      final x = (p.dx - cx) * scale + center.dx;
      final y = (p.dy - cy) * scale + center.dy;
      return Offset(x, y);
    }).toList();
  }

  static double _smootherstep(double x) {
    x = x.clamp(0.0, 1.0);
    return x * x * x * (x * (x * 6 - 15) + 10);
  }

  /// Creates a smooth closed path using Catmull-Rom to Bezier conversion
  /// This eliminates jerky line transitions during morphing
  Path _createSmoothPath(List<Offset> points) {
    final path = Path();
    final n = points.length;
    if (n < 3) {
      // Fallback for too few points
      if (n > 0) path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < n; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (n > 0) path.close();
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < n; i++) {
      // Get 4 points for Catmull-Rom spline
      final p0 = points[(i - 1 + n) % n];
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final p3 = points[(i + 2) % n];

      // Convert Catmull-Rom to cubic Bezier control points
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

  @override
  bool shouldRepaint(covariant _GeoPainter oldDelegate) => true;
}

class _Shape {
  final List<Offset> points;
  final int signature;
  const _Shape(this.points, this.signature);
}

class _ShapeFactory {
  final int vertices;
  final int recentMemory;
  int _seed;
  final Set<int> _recent = {};
  final List<int> _recentQueue = [];

  _ShapeFactory({
    required this.vertices,
    required this.recentMemory,
    required int seed,
  }) : _seed = seed;

  _Shape nextUnique({_Shape? avoidLike}) {
    for (int tries = 0; tries < 60; tries++) {
      final s = _nextShape();
      final sig = s.signature;

      if (_recent.contains(sig)) continue;
      if (avoidLike != null && _tooSimilar(sig, avoidLike.signature)) continue;

      _remember(sig);
      return s;
    }
    final s = _nextShape();
    _remember(s.signature);
    return s;
  }

  bool _tooSimilar(int a, int b) {
    return ((a >> 6) == (b >> 6));
  }

  void _remember(int sig) {
    _recent.add(sig);
    _recentQueue.add(sig);
    if (_recentQueue.length > recentMemory) {
      final old = _recentQueue.removeAt(0);
      _recent.remove(old);
    }
  }

  _Shape _nextShape() {
    _seed = (1664525 * _seed + 1013904223) & 0x7fffffff;
    final seed = _seed;

    const base = 0.78;
    const varR = 0.40;

    final mode = seed % 14;
    final dip1 = (seed ~/ 7) % vertices;
    final dip2 = (seed ~/ 31) % vertices;

    final angles = List<double>.generate(vertices, (i) {
      final u = i / vertices;
      final jitter = (_hash(seed * 91.7 + i * 7.3) - 0.5) * 0.22;
      return (u * pi * 2) + jitter;
    })..sort();

    final radii = List<double>.generate(vertices, (i) {
      final h = pow(_hash(seed * 17.9 + i * 13.1), 0.72).toDouble();
      var r = (base - 0.22) + varR * h;
      if (i == dip1) r *= 0.52;
      if (mode.isEven && i == dip2) r *= 0.70;
      return r;
    });

    final basePts = List<Offset>.generate(vertices, (i) {
      final a = angles[i];
      final r = radii[i];
      return Offset(cos(a) * r, sin(a) * r);
    });

    final order = _orderForMode(mode, seed, vertices);
    final pts = List<Offset>.generate(vertices, (i) => basePts[order[i]]);

    final sig = (mode & 0x1F) |
        ((dip1 & 0x0F) << 5) |
        ((dip2 & 0x0F) << 9) |
        ((order[0] & 0x0F) << 13) |
        ((order[1] & 0x0F) << 17) |
        ((order[2] & 0x0F) << 21);

    return _Shape(pts, sig);
  }

  List<int> _orderForMode(int mode, int seed, int n) {
    List<int> rot(List<int> a) {
      final shift = seed % n;
      return List<int>.generate(n, (i) => (a[i] + shift) % n);
    }

    switch (mode) {
      case 0:
        return List<int>.generate(n, (i) => i);
      case 1:
        return [0, 2, 4, 6, 3, 1, 5];
      case 2:
        return rot([0, 3, 1, 5, 2, 6, 4]);
      case 3:
        return rot([0, 1, 2, 5, 6, 4, 3]);
      case 4:
        return _zigZag(n);
      case 5:
        return _evensOdds(n, seed);
      case 6:
        return _star(n, 2);
      case 7:
        return _star(n, 3);
      case 8:
        return _jump(n, seed, 2);
      case 9:
        return _jump(n, seed, 3);
      case 10:
        return rot([0, 4, 1, 5, 2, 6, 3]);
      case 11:
        return rot([0, 2, 5, 1, 4, 6, 3]);
      case 12:
        return rot([0, 5, 2, 6, 1, 4, 3]);
      default:
        return _jump(n, seed, 4);
    }
  }

  static List<int> _star(int n, int step) {
    final order = <int>[];
    final seen = List<bool>.filled(n, false);
    int cur = 0;
    for (int i = 0; i < n; i++) {
      order.add(cur);
      seen[cur] = true;
      cur = (cur + step) % n;
      if (seen[cur] && i < n - 1) cur = seen.indexOf(false);
    }
    return order;
  }

  static List<int> _zigZag(int n) {
    final o = <int>[];
    int a = 0, b = n - 1;
    while (a <= b) {
      o.add(a);
      if (a != b) o.add(b);
      a++;
      b--;
    }
    return o.take(n).toList();
  }

  static List<int> _evensOdds(int n, int seed) {
    final evens = <int>[], odds = <int>[];
    for (int i = 0; i < n; i++) {
      (i.isEven ? evens : odds).add(i);
    }
    final combined = [...evens, ...odds];
    final shift = seed % n;
    return List<int>.generate(n, (i) => combined[(i + shift) % n]);
  }

  static List<int> _jump(int n, int seed, int jumpBase) {
    final used = List<bool>.filled(n, false);
    final order = <int>[];
    int cur = seed % n;
    for (int i = 0; i < n; i++) {
      if (!used[cur]) {
        order.add(cur);
        used[cur] = true;
      } else {
        final nxt = used.indexOf(false);
        order.add(nxt);
        used[nxt] = true;
      }
      final jump = jumpBase + ((seed + i) % 3);
      cur = (cur + jump) % n;
    }
    return order;
  }

  static double _hash(double x) {
    final v = sin(x * 12.9898) * 43758.5453;
    return v - v.floorToDouble();
  }
}
