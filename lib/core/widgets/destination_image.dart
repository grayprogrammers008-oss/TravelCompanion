import 'package:flutter/material.dart';
import '../constants/app_images.dart';
import '../theme/app_theme.dart';

/// Premium destination image widget with gradient fallback
///
/// Displays trip destination images with beautiful gradient fallbacks
/// when images are not available or still loading.
class DestinationImage extends StatelessWidget {
  final String? imageUrl;
  final String? tripName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showOverlay;
  final Widget? overlayChild;

  const DestinationImage({
    super.key,
    this.imageUrl,
    this.tripName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showOverlay = false,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    final colors = (tripName ?? 'default').destinationColorPair;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(colors[0]),
            Color(colors[1]),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _DestinationPatternPainter(),
            ),
          ),

          // Trip name icon
          if (tripName != null && tripName!.isNotEmpty)
            Center(
              child: Icon(
                _getDestinationIcon(tripName!),
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),

          // Overlay gradient
          if (showOverlay)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

          // Overlay content
          if (overlayChild != null)
            Positioned.fill(
              child: overlayChild!,
            ),
        ],
      ),
    );
  }

  IconData _getDestinationIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('beach') ||
        lower.contains('maldives') ||
        lower.contains('bora')) {
      return Icons.beach_access;
    }
    if (lower.contains('mountain') ||
        lower.contains('switzerland') ||
        lower.contains('iceland')) {
      return Icons.terrain;
    }
    if (lower.contains('city') ||
        lower.contains('new york') ||
        lower.contains('tokyo') ||
        lower.contains('paris')) {
      return Icons.location_city;
    }
    if (lower.contains('island') ||
        lower.contains('bali') ||
        lower.contains('santorini')) {
      return Icons.water;
    }
    if (lower.contains('desert') || lower.contains('dubai')) {
      return Icons.wb_sunny;
    }
    return Icons.flight_takeoff;
  }
}

/// Custom painter for decorative destination patterns
class _DestinationPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    final circleRadius = size.width * 0.3;

    canvas.drawCircle(
      Offset(-circleRadius * 0.5, -circleRadius * 0.5),
      circleRadius,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width + circleRadius * 0.3, size.height * 0.7),
      circleRadius * 0.8,
      paint,
    );

    // Draw decorative lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = Colors.white.withValues(alpha: 0.1);

    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * 0.3, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar widget with gradient fallback
class UserAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? userName;
  final double size;
  final bool showBorder;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    this.userName,
    this.size = 40,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: 2,
              )
            : null,
        boxShadow: showBorder ? AppTheme.shadowMd : null,
      ),
      child: Center(
        child: Text(
          _getInitials(userName),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }
}

/// Empty state illustration widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowTeal,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // Action button
            if (onAction != null && actionLabel != null)
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowTeal,
                ),
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingMd,
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
