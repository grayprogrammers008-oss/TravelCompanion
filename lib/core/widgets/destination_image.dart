import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_images.dart';
import '../theme/app_theme.dart';
import '../theme/theme_access.dart';
import '../services/image_service.dart';

/// Premium destination image widget with real images from Google Places
///
/// Features:
/// - Fetches real destination images from Google Places API
/// - Shows shimmer loading effect while fetching
/// - Falls back to gradient if image unavailable
/// - Caches images to reduce API calls
class DestinationImage extends StatefulWidget {
  final String? imageUrl;
  final String? tripName;
  final String? destination;
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
    this.destination,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showOverlay = false,
    this.overlayChild,
  });

  @override
  State<DestinationImage> createState() => _DestinationImageState();
}

class _DestinationImageState extends State<DestinationImage> {
  final ImageService _imageService = ImageService();
  String? _fetchedImageUrl;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Force print to console - this MUST appear
    print('🚨🚨🚨 [DestinationImage] initState called! tripName=${widget.tripName}, imageUrl=${widget.imageUrl}');
    _loadImage();
  }

  Future<void> _loadImage() async {
    // Using print instead of debugPrint for more reliable console output
    print('🖼️ [DestinationImage] _loadImage called');
    print('🖼️ [DestinationImage] imageUrl: ${widget.imageUrl}');
    print('🖼️ [DestinationImage] tripName: ${widget.tripName}');
    print('🖼️ [DestinationImage] destination: ${widget.destination}');

    // If imageUrl is provided, use it directly
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      print('🖼️ [DestinationImage] Using provided imageUrl');
      return;
    }

    // Otherwise, try to fetch from Google Places using destination or tripName
    final searchQuery = widget.destination ?? widget.tripName;
    if (searchQuery == null || searchQuery.isEmpty) {
      print('🖼️ [DestinationImage] No search query available, skipping fetch');
      return;
    }

    print('🖼️ [DestinationImage] Fetching image for: $searchQuery');

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = await _imageService.getDestinationImage(searchQuery);
      print('🖼️ [DestinationImage] Received URL: ${url != null ? "${url.substring(0, 50)}..." : "null"}');
      if (mounted) {
        setState(() {
          _fetchedImageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('🖼️ [DestinationImage] Error loading image: $e');
      print('🖼️ [DestinationImage] Stack: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = (widget.tripName ?? widget.destination ?? 'default')
        .destinationColorPair;

    // Determine which image URL to use
    final imageUrl = widget.imageUrl ?? _fetchedImageUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate effective dimensions - prefer widget dimensions, then parent constraints
        // Handle double.infinity by falling back to parent constraints
        double effectiveWidth;
        if (widget.width != null && widget.width!.isFinite) {
          effectiveWidth = widget.width!;
        } else if (constraints.maxWidth.isFinite) {
          effectiveWidth = constraints.maxWidth;
        } else {
          effectiveWidth = 300; // Fallback width
        }

        double effectiveHeight;
        if (widget.height != null && widget.height!.isFinite) {
          effectiveHeight = widget.height!;
        } else if (constraints.maxHeight.isFinite) {
          effectiveHeight = constraints.maxHeight;
        } else {
          effectiveHeight = 200; // Fallback height
        }

        return SizedBox(
          width: effectiveWidth,
          height: effectiveHeight,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: Stack(
              children: [
                // Gradient background (fallback)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(colors[0]),
                          Color(colors[1]),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DestinationPatternPainter(),
                      child: imageUrl == null &&
                              !_isLoading &&
                              (widget.tripName != null || widget.destination != null)
                          ? Center(
                              child: Icon(
                                _getDestinationIcon(
                                    widget.tripName ?? widget.destination ?? ''),
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // Real image (if available)
                if (imageUrl != null && !_hasError)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: widget.fit,
                      placeholder: (context, url) => _buildShimmer(),
                      errorWidget: (context, url, error) => const SizedBox(),
                    ),
                  ),
                // Shimmer loading effect
                if (_isLoading)
                  Positioned.fill(child: _buildShimmer()),
                // Overlay gradient (for text readability)
                if (widget.showOverlay)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
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
                if (widget.overlayChild != null)
                  Positioned.fill(
                    child: widget.overlayChild!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
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
  final String? cacheKey;

  const UserAvatarWidget({
    super.key,
    this.imageUrl,
    this.userName,
    this.size = 40,
    this.showBorder = false,
    this.cacheKey,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;

    // If imageUrl is provided, show the image
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final borderWidth = showBorder ? 2.0 : 0.0;
      final imageSize = size - (borderWidth * 2);

      // Outer container for border and shadow
      // Inner ClipOval for the actual image (sized to fit inside border)
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, // Border color as background
          boxShadow: showBorder ? AppTheme.shadowMd : null,
        ),
        child: Center(
          child: ClipOval(
            child: SizedBox(
              width: imageSize,
              height: imageSize,
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                cacheKey: cacheKey ?? imageUrl,
                fit: BoxFit.cover,
                width: imageSize,
                height: imageSize,
                // Force re-fetch from network, don't use stale cache
                maxHeightDiskCache: 500,
                maxWidthDiskCache: 500,
                placeholder: (context, url) => Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: themeData.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(userName),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: imageSize * 0.4,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: themeData.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(userName),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: imageSize * 0.4,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Otherwise show gradient avatar with initials
    return _buildGradientAvatar(themeData);
  }

  Widget _buildGradientAvatar(dynamic themeData) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: themeData.primaryGradient,
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
            letterSpacing: 0.5,
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
    final themeData = context.appThemeData;
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
                gradient: themeData.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: themeData.primaryShadow,
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
                  gradient: themeData.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: themeData.primaryShadow,
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
