import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';

/// Mini map preview showing place locations relative to user
class MiniMapPreview extends StatefulWidget {
  final List<DiscoverPlace> places;
  final double? userLatitude;
  final double? userLongitude;
  final double radiusKm;
  final PlaceCategory? category; // Nullable for "Popular Nearby" mode
  final Function(DiscoverPlace)? onPlaceTapped;
  final VoidCallback? onExpandTapped;

  const MiniMapPreview({
    super.key,
    required this.places,
    this.userLatitude,
    this.userLongitude,
    this.radiusKm = 10,
    this.category, // Optional - null for "Popular Nearby"
    this.onPlaceTapped,
    this.onExpandTapped,
  });

  @override
  State<MiniMapPreview> createState() => _MiniMapPreviewState();
}

class _MiniMapPreviewState extends State<MiniMapPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _selectedPlaceIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userLatitude == null || widget.userLongitude == null) {
      return _buildNoLocationState(context);
    }

    // Cluster nearby places
    final clusters = _clusterPlaces(widget.places);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
            child: Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 16,
                  color: widget.category?.color ?? context.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Places around you',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textColor.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                // Place count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (widget.category?.color ?? context.primaryColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.places.length} places',
                    style: context.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.category?.color ?? context.primaryColor,
                    ),
                  ),
                ),
                // Expand button
                if (widget.onExpandTapped != null)
                  IconButton(
                    onPressed: widget.onExpandTapped,
                    icon: Icon(
                      Icons.fullscreen,
                      size: 18,
                      color: context.textColor.withValues(alpha: 0.5),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Expand map',
                  ),
              ],
            ),
          ),
          // Mini map
          GestureDetector(
            onTapUp: (details) => _handleTap(details, clusters),
            child: SizedBox(
              height: 160,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MiniMapPainter(
                      clusters: clusters,
                      userLatitude: widget.userLatitude!,
                      userLongitude: widget.userLongitude!,
                      radiusKm: widget.radiusKm,
                      categoryColor: widget.category?.color ?? context.primaryColor,
                      pulseValue: _pulseAnimation.value,
                      selectedIndex: _selectedPlaceIndex,
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          // Selected place info
          if (_selectedPlaceIndex != null && _selectedPlaceIndex! < clusters.length)
            _buildSelectedPlaceInfo(context, clusters[_selectedPlaceIndex!]),
          // Legend
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildNoLocationState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off,
            color: context.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 12),
          Text(
            'Location needed for map preview',
            style: context.bodyMedium.copyWith(
              color: context.textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlaceInfo(BuildContext context, _PlaceCluster cluster) {
    final place = cluster.places.first;
    final color = widget.category?.color ?? context.primaryColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cluster.places.length > 1
                      ? '${cluster.places.length} places here'
                      : place.name,
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cluster.places.length == 1)
                  Text(
                    place.distanceText(widget.userLatitude, widget.userLongitude),
                    style: context.bodySmall.copyWith(
                      fontSize: 10,
                      color: context.textColor.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.onPlaceTapped != null)
            TextButton(
              onPressed: () => widget.onPlaceTapped!(place),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                'View',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final categoryColor = widget.category?.color ?? context.primaryColor;
    final categoryName = widget.category?.displayName ?? 'Popular Places';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // You marker
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'You',
            style: context.bodySmall.copyWith(
              fontSize: 9,
              color: context.textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          // Place marker
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: context.bodySmall.copyWith(
              fontSize: 9,
              color: context.textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          // Radius
          Icon(
            Icons.radio_button_unchecked,
            size: 8,
            color: context.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.radiusKm.toInt()} km radius',
            style: context.bodySmall.copyWith(
              fontSize: 9,
              color: context.textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  List<_PlaceCluster> _clusterPlaces(List<DiscoverPlace> places) {
    final clusters = <_PlaceCluster>[];
    final clustered = <int>{};

    for (int i = 0; i < places.length; i++) {
      if (clustered.contains(i)) continue;

      final place = places[i];
      final clusterPlaces = <DiscoverPlace>[place];
      clustered.add(i);

      // Find nearby places to cluster (within ~500m on the map)
      for (int j = i + 1; j < places.length; j++) {
        if (clustered.contains(j)) continue;

        final other = places[j];
        final distance = _haversineDistance(
          place.latitude ?? 0,
          place.longitude ?? 0,
          other.latitude ?? 0,
          other.longitude ?? 0,
        );

        // Cluster if within 500 meters
        if (distance < 0.5) {
          clusterPlaces.add(other);
          clustered.add(j);
        }
      }

      clusters.add(_PlaceCluster(
        places: clusterPlaces,
        centerLat: clusterPlaces.map((p) => p.latitude ?? 0).reduce((a, b) => a + b) / clusterPlaces.length,
        centerLng: clusterPlaces.map((p) => p.longitude ?? 0).reduce((a, b) => a + b) / clusterPlaces.length,
      ));
    }

    return clusters;
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  void _handleTap(TapUpDetails details, List<_PlaceCluster> clusters) {
    final size = context.size;
    if (size == null) return;

    final center = Offset(size.width / 2, 80); // Map center
    final maxRadius = math.min(size.width, 160.0) / 2 - 20;

    // Check if tapped on a cluster
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final position = _getClusterPosition(
        cluster,
        widget.userLatitude!,
        widget.userLongitude!,
        widget.radiusKm,
        center,
        maxRadius,
      );

      final distance = (details.localPosition - position).distance;
      final markerRadius = cluster.places.length > 1 ? 14.0 : 10.0;

      if (distance <= markerRadius + 5) {
        setState(() => _selectedPlaceIndex = i);
        return;
      }
    }

    // Tapped outside - clear selection
    setState(() => _selectedPlaceIndex = null);
  }

  Offset _getClusterPosition(
    _PlaceCluster cluster,
    double userLat,
    double userLng,
    double radiusKm,
    Offset center,
    double maxRadius,
  ) {
    final distance = _haversineDistance(
      userLat,
      userLng,
      cluster.centerLat,
      cluster.centerLng,
    );

    final bearing = _calculateBearing(
      userLat,
      userLng,
      cluster.centerLat,
      cluster.centerLng,
    );

    // Scale distance to fit in radius
    final scaledDistance = (distance / radiusKm).clamp(0.0, 1.0) * maxRadius;

    // Convert bearing to screen coordinates
    final angle = bearing - math.pi / 2; // Adjust so north is up
    final dx = math.cos(angle) * scaledDistance;
    final dy = math.sin(angle) * scaledDistance;

    return center + Offset(dx, dy);
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_toRadians(lat2));
    final x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.cos(dLon);
    return math.atan2(y, x);
  }
}

/// Place cluster for grouping nearby places
class _PlaceCluster {
  final List<DiscoverPlace> places;
  final double centerLat;
  final double centerLng;

  _PlaceCluster({
    required this.places,
    required this.centerLat,
    required this.centerLng,
  });
}

/// Custom painter for the mini map
class _MiniMapPainter extends CustomPainter {
  final List<_PlaceCluster> clusters;
  final double userLatitude;
  final double userLongitude;
  final double radiusKm;
  final Color categoryColor;
  final double pulseValue;
  final int? selectedIndex;
  final bool isDarkMode;

  _MiniMapPainter({
    required this.clusters,
    required this.userLatitude,
    required this.userLongitude,
    required this.radiusKm,
    required this.categoryColor,
    required this.pulseValue,
    this.selectedIndex,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 20;

    // Draw radius circles
    _drawRadiusCircles(canvas, center, maxRadius);

    // Draw compass directions
    _drawCompassDirections(canvas, center, maxRadius);

    // Draw place markers
    _drawPlaceMarkers(canvas, center, maxRadius);

    // Draw user location marker (on top)
    _drawUserMarker(canvas, center);
  }

  void _drawRadiusCircles(Canvas canvas, Offset center, double maxRadius) {
    final circlePaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric circles
    for (int i = 3; i >= 1; i--) {
      final radius = maxRadius * (i / 3);
      canvas.drawCircle(center, radius, circlePaint);
      canvas.drawCircle(center, radius, borderPaint);
    }
  }

  void _drawCompassDirections(Canvas canvas, Offset center, double maxRadius) {
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.3),
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    // Draw N, S, E, W
    final directions = [
      ('N', Offset(center.dx, center.dy - maxRadius - 12)),
      ('S', Offset(center.dx, center.dy + maxRadius + 4)),
      ('E', Offset(center.dx + maxRadius + 6, center.dy - 5)),
      ('W', Offset(center.dx - maxRadius - 12, center.dy - 5)),
    ];

    for (final (label, offset) in directions) {
      textPaint.text = TextSpan(text: label, style: textStyle);
      textPaint.layout();
      textPaint.paint(canvas, offset);
    }
  }

  void _drawPlaceMarkers(Canvas canvas, Offset center, double maxRadius) {
    for (int i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final isSelected = selectedIndex == i;

      // Calculate position
      final distance = _haversineDistance(
        userLatitude,
        userLongitude,
        cluster.centerLat,
        cluster.centerLng,
      );

      final bearing = _calculateBearing(
        userLatitude,
        userLongitude,
        cluster.centerLat,
        cluster.centerLng,
      );

      // Scale distance to fit in radius
      final scaledDistance = (distance / radiusKm).clamp(0.0, 1.0) * maxRadius;

      // Convert bearing to screen coordinates (north is up)
      final angle = bearing - math.pi / 2;
      final dx = math.cos(angle) * scaledDistance;
      final dy = math.sin(angle) * scaledDistance;
      final position = center + Offset(dx, dy);

      // Draw marker
      final isCluster = cluster.places.length > 1;
      final markerRadius = isCluster ? 12.0 : 8.0;

      // Selection ring
      if (isSelected) {
        final ringPaint = Paint()
          ..color = categoryColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(position, markerRadius + 4, ringPaint);
      }

      // Marker shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(position + const Offset(1, 2), markerRadius, shadowPaint);

      // Marker fill
      final markerPaint = Paint()
        ..color = isSelected ? categoryColor : categoryColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, markerRadius, markerPaint);

      // Marker border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, markerRadius, borderPaint);

      // Draw cluster count
      if (isCluster) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${cluster.places.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          position - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  void _drawUserMarker(Canvas canvas, Offset center) {
    // Pulse ring
    final pulsePaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.3 * pulseValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20 * pulseValue, pulsePaint);

    // Outer ring
    final outerPaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14, outerPaint);

    // User marker shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center + const Offset(1, 2), 8, shadowPaint);

    // User marker
    final userPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, userPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 8, borderPaint);

    // Inner dot
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, innerPaint);
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_toRadians(lat2));
    final x = math.cos(_toRadians(lat1)) * math.sin(_toRadians(lat2)) -
        math.sin(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.cos(dLon);
    return math.atan2(y, x);
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.clusters.length != clusters.length;
  }
}
