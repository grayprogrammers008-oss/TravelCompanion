import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';
import '../providers/discover_providers.dart';

/// Card widget to display a discovered place
class PlaceCard extends ConsumerWidget {
  final DiscoverPlace place;
  final VoidCallback? onTap;
  final double? userLatitude;
  final double? userLongitude;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onQuickAdd;

  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.userLatitude,
    this.userLongitude,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button overlay
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(context, ref),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  // Distance badge
                  if (userLatitude != null && userLongitude != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.distanceText(userLatitude, userLongitude),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Quick add to trip button
                  if (onQuickAdd != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onQuickAdd,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_location_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details - compact layout to prevent overflow
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Flexible(
                      child: Text(
                        place.name,
                        style: context.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Rating and Status in same row to save space
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            place.ratingText,
                            style: context.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (place.statusText != null) ...[
                          if (place.rating != null) const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: place.openNow == true
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              place.statusText!,
                              style: context.bodySmall.copyWith(
                                color: place.openNow == true
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, WidgetRef ref) {
    if (place.hasPhotos) {
      final photoUrlAsync = ref.watch(
        placePhotoUrlProvider(place.firstPhotoReference!),
      );

      return photoUrlAsync.when(
        data: (url) {
          if (url == null) {
            return _buildFallbackImage(context);
          }
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => _buildLoadingImage(context),
            errorWidget: (context, url, error) => _buildFallbackImage(context),
          );
        },
        loading: () => _buildLoadingImage(context),
        error: (error, stackTrace) => _buildFallbackImage(context),
      );
    }

    return _buildFallbackImage(context);
  }

  Widget _buildLoadingImage(BuildContext context) {
    return Container(
      color: place.category.color.withValues(alpha: 0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: place.category.color,
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            place.category.color.withValues(alpha: 0.3),
            place.category.color.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          place.category.icon,
          size: 40,
          color: place.category.color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
