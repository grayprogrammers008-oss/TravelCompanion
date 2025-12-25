import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/place_recommendation.dart';
import '../../domain/entities/discover_place.dart';
import '../providers/discover_providers.dart';

/// Section widget displaying AI-powered recommendations
class RecommendationsSection extends ConsumerWidget {
  final Function(DiscoverPlace) onPlaceTapped;
  final Function(DiscoverPlace)? onQuickAdd;

  const RecommendationsSection({
    super.key,
    required this.onPlaceTapped,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverState = ref.watch(discoverStateProvider);

    // Only show if we have places loaded
    if (discoverState.places.isEmpty || discoverState.isLoading) {
      return const SizedBox.shrink();
    }

    // Generate recommendations
    final recommendations = RecommendationEngine.generateAllRecommendations(
      allPlaces: discoverState.places,
      favoriteIds: discoverState.favoriteIds,
      userLat: discoverState.userLatitude,
      userLng: discoverState.userLongitude,
    );

    // Filter to only non-empty groups
    final nonEmptyGroups = recommendations.where((g) => g.isNotEmpty).toList();

    if (nonEmptyGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only the first 2-3 most relevant groups
    final groupsToShow = nonEmptyGroups.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400,
                      Colors.blue.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For You',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalized recommendations',
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recommendation groups
        ...groupsToShow.map((group) => _RecommendationGroupWidget(
          group: group,
          onPlaceTapped: onPlaceTapped,
          onQuickAdd: onQuickAdd,
          isFavorite: (placeId) => discoverState.isFavorite(placeId),
          onToggleFavorite: (place) {
            ref.read(discoverStateProvider.notifier).toggleFavorite(place.placeId, place: place);
          },
          userLat: discoverState.userLatitude,
          userLng: discoverState.userLongitude,
        )),

        const SizedBox(height: 8),
      ],
    );
  }
}

/// Widget for a single recommendation group
class _RecommendationGroupWidget extends StatelessWidget {
  final RecommendationGroup group;
  final Function(DiscoverPlace) onPlaceTapped;
  final Function(DiscoverPlace)? onQuickAdd;
  final bool Function(String) isFavorite;
  final Function(DiscoverPlace) onToggleFavorite;
  final double? userLat;
  final double? userLng;

  const _RecommendationGroupWidget({
    required this.group,
    required this.onPlaceTapped,
    this.onQuickAdd,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: group.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  group.type.icon,
                  color: group.type.color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.type.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: group.type.color,
                      ),
                    ),
                    if (group.basedOn != null)
                      Text(
                        group.basedOn!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      )
                    else
                      Text(
                        group.type.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal list of recommendations
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: group.recommendations.length,
            itemBuilder: (context, index) {
              final rec = group.recommendations[index];
              return _RecommendationCard(
                recommendation: rec,
                onTap: () => onPlaceTapped(rec.place),
                onQuickAdd: onQuickAdd != null ? () => onQuickAdd!(rec.place) : null,
                isFavorite: isFavorite(rec.place.placeId),
                onToggleFavorite: () => onToggleFavorite(rec.place),
                userLat: userLat,
                userLng: userLng,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card widget for a single recommendation
class _RecommendationCard extends ConsumerWidget {
  final PlaceRecommendation recommendation;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final double? userLat;
  final double? userLng;

  const _RecommendationCard({
    required this.recommendation,
    required this.onTap,
    this.onQuickAdd,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.userLat,
    this.userLng,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = recommendation.place;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Positioned.fill(
              child: _buildImage(context, ref),
            ),

            // Gradient overlay
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
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Match score indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMatchColor(recommendation.matchScore),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(recommendation.matchScore * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Favorite button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isFavorite ? Colors.red : Colors.grey[600],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Reason
                    Row(
                      children: [
                        Icon(
                          recommendation.type.icon,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            recommendation.reason,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Rating
                    if (place.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.ratingText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Quick add button
            if (onQuickAdd != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onQuickAdd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, WidgetRef ref) {
    final place = recommendation.place;

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
      color: recommendation.type.color.withValues(alpha: 0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: recommendation.type.color,
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
            recommendation.type.color.withValues(alpha: 0.3),
            recommendation.type.color.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          recommendation.place.category.icon,
          size: 40,
          color: recommendation.type.color.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Color _getMatchColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.grey;
  }
}
