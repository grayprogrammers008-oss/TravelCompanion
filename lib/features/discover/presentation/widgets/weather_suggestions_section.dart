import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/weather_suggestion.dart';
import '../providers/discover_providers.dart';

/// Section widget displaying weather-based place suggestions
class WeatherSuggestionsSection extends ConsumerWidget {
  final Function(DiscoverPlace) onPlaceTapped;
  final Function(DiscoverPlace)? onQuickAdd;

  const WeatherSuggestionsSection({
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

    // Use mock weather data for now (can be replaced with real API call)
    final weather = _getMockWeather();

    // Generate weather-based suggestions
    final suggestions = WeatherSuggestionEngine.generateSuggestions(
      allPlaces: discoverState.places,
      weather: weather,
      limit: 8,
    );

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final weatherSummary = WeatherSuggestionEngine.getWeatherSummary(weather);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weather Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                weather.effectiveCondition.color.withValues(alpha: 0.2),
                weather.effectiveCondition.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: weather.effectiveCondition.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Weather icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: weather.effectiveCondition.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  weather.effectiveCondition.icon,
                  color: weather.effectiveCondition.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Weather info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          weather.temperatureText,
                          style: context.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: weather.effectiveCondition.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: weather.effectiveCondition.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            weather.effectiveCondition.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weatherSummary,
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.recommend,
                color: weather.effectiveCondition.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Perfect for Today',
                style: context.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${suggestions.length} places',
                style: context.bodySmall.copyWith(
                  color: context.textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),

        // Horizontal list of weather suggestions
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _WeatherSuggestionCard(
                suggestion: suggestion,
                onTap: () => onPlaceTapped(suggestion.place),
                onQuickAdd: onQuickAdd != null
                    ? () => onQuickAdd!(suggestion.place)
                    : null,
                isFavorite: discoverState.isFavorite(suggestion.place.placeId),
                onToggleFavorite: () {
                  ref.read(discoverStateProvider.notifier).toggleFavorite(
                    suggestion.place.placeId,
                    place: suggestion.place,
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  /// Get mock weather data based on time of day and random conditions
  WeatherData _getMockWeather() {
    final hour = DateTime.now().hour;

    // Simulate different weather based on time
    if (hour >= 6 && hour < 10) {
      return WeatherData.mock(temperature: 24, condition: WeatherCondition.pleasant);
    } else if (hour >= 10 && hour < 14) {
      return WeatherData.mock(temperature: 32, condition: WeatherCondition.sunny);
    } else if (hour >= 14 && hour < 18) {
      return WeatherData.mock(temperature: 30, condition: WeatherCondition.cloudy);
    } else if (hour >= 18 && hour < 21) {
      return WeatherData.mock(temperature: 26, condition: WeatherCondition.pleasant);
    } else {
      return WeatherData.mock(temperature: 22, condition: WeatherCondition.cloudy);
    }
  }
}

/// Card widget for a single weather suggestion
class _WeatherSuggestionCard extends ConsumerWidget {
  final WeatherSuggestion suggestion;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _WeatherSuggestionCard({
    required this.suggestion,
    required this.onTap,
    this.onQuickAdd,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = suggestion.place;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
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
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),

            // Weather badge (indoor/outdoor)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: suggestion.isIndoorActivity
                      ? Colors.blue.withValues(alpha: 0.9)
                      : Colors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      suggestion.isIndoorActivity
                          ? Icons.home
                          : Icons.wb_sunny,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.isIndoorActivity ? 'Indoor' : 'Outdoor',
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
                    // Weather reason
                    Row(
                      children: [
                        Icon(
                          suggestion.weather.icon,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            suggestion.reason,
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
                      color: place.category.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: place.category.color.withValues(alpha: 0.4),
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
    final place = suggestion.place;

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
      color: suggestion.weather.color.withValues(alpha: 0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: suggestion.weather.color,
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
            suggestion.place.category.color.withValues(alpha: 0.3),
            suggestion.place.category.color.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          suggestion.place.category.icon,
          size: 40,
          color: suggestion.place.category.color.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
