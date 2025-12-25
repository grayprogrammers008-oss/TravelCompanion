import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Widget that displays a map while getting the user's location
/// Shows a pulsing marker when location is found
class LocationMapWidget extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final bool isLoading;
  final String? locationName;
  final VoidCallback? onRetry;

  const LocationMapWidget({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.isLoading = true,
    this.locationName,
    this.onRetry,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Default center - India
  static const _defaultCenter = LatLng(20.5937, 78.9629);
  static const _defaultZoom = 4.0;
  static const _locationFoundZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Pulsing animation for location marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When location is found, animate map to that location
    if (widget.userLatitude != null &&
        widget.userLongitude != null &&
        (oldWidget.userLatitude != widget.userLatitude ||
         oldWidget.userLongitude != widget.userLongitude)) {
      _animateToLocation();
    }
  }

  void _animateToLocation() {
    if (widget.userLatitude == null || widget.userLongitude == null) return;

    try {
      _mapController.move(
        LatLng(widget.userLatitude!, widget.userLongitude!),
        _locationFoundZoom,
      );
    } catch (e) {
      debugPrint('Error moving map: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _center {
    if (widget.userLatitude != null && widget.userLongitude != null) {
      return LatLng(widget.userLatitude!, widget.userLongitude!);
    }
    return _defaultCenter;
  }

  double get _zoom {
    if (widget.userLatitude != null && widget.userLongitude != null) {
      return _locationFoundZoom;
    }
    return _defaultZoom;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travelcrew.app',
                maxZoom: 19,
              ),
              // User location marker (when found)
              if (widget.userLatitude != null && widget.userLongitude != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.userLatitude!, widget.userLongitude!),
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing outer ring
                              Container(
                                width: 60 * _pulseAnimation.value,
                                height: 60 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.primaryColor.withValues(
                                    alpha: 0.3 * (1 - _pulseAnimation.value),
                                  ),
                                ),
                              ),
                              // Inner marker
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.primaryColor,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.primaryColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Loading overlay
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 18,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Finding your location...',
                            style: context.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please allow location access',
                        style: context.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Location found info card
        if (!widget.isLoading && widget.locationName != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Location Found',
                          style: context.bodySmall.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.locationName!,
                          style: context.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Retry button (shown when not loading and no location)
        if (!widget.isLoading &&
            widget.userLatitude == null &&
            widget.onRetry != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }
}
