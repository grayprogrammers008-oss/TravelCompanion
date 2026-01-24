import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';
import '../providers/discover_providers.dart';

/// Smart Suggestions Section with personalized recommendations
class SmartSuggestionsSection extends ConsumerStatefulWidget {
  final Function(DiscoverPlace) onPlaceTapped;
  final Function(DiscoverPlace) onQuickAdd;
  final Function(PlaceCategory) onCategoryTapped;

  const SmartSuggestionsSection({
    super.key,
    required this.onPlaceTapped,
    required this.onQuickAdd,
    required this.onCategoryTapped,
  });

  @override
  ConsumerState<SmartSuggestionsSection> createState() =>
      _SmartSuggestionsSectionState();
}

class _SmartSuggestionsSectionState
    extends ConsumerState<SmartSuggestionsSection> {
  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverStateProvider);
    final places = discoverState.places;
    final favoriteIds = discoverState.favoriteIds;

    // Don't show if no places loaded
    if (places.isEmpty || !discoverState.hasLocation) {
      return const SizedBox.shrink();
    }

    // Get time-based suggestions
    final timeSuggestion = _getTimeSuggestion();
    final suggestedCategories = _getSuggestedCategories(timeSuggestion.timeOfDay);

    // Get popular nearby (top rated)
    final popularNearby = _getPopularNearby(places);

    // Get trending (most reviewed)
    final trending = _getTrending(places);

    // Get personalized (based on favorites)
    final personalized = _getPersonalized(places, favoriteIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time-based suggestion banner
        _TimeSuggestionBanner(
          suggestion: timeSuggestion,
          suggestedCategories: suggestedCategories,
          onCategoryTapped: widget.onCategoryTapped,
        ),

        // Popular Nearby Section
        if (popularNearby.isNotEmpty)
          _SuggestionRow(
            title: 'Popular Nearby',
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            subtitle: 'Highly rated places close to you',
            places: popularNearby,
            onPlaceTapped: widget.onPlaceTapped,
            onQuickAdd: widget.onQuickAdd,
            favoriteIds: favoriteIds,
          ),

        // Trending This Week
        if (trending.isNotEmpty)
          _SuggestionRow(
            title: 'Trending',
            icon: Icons.trending_up,
            iconColor: Colors.green,
            subtitle: 'Most visited this week',
            places: trending,
            onPlaceTapped: widget.onPlaceTapped,
            onQuickAdd: widget.onQuickAdd,
            favoriteIds: favoriteIds,
            showVisitorCount: true,
          ),

        // Personalized suggestions (if user has favorites)
        if (personalized.isNotEmpty)
          _SuggestionRow(
            title: 'For You',
            icon: Icons.auto_awesome,
            iconColor: Colors.purple,
            subtitle: 'Based on your favorites',
            places: personalized,
            onPlaceTapped: widget.onPlaceTapped,
            onQuickAdd: widget.onQuickAdd,
            favoriteIds: favoriteIds,
          ),
      ],
    );
  }

  /// Get time-based suggestion
  _TimeSuggestion _getTimeSuggestion() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 10) {
      return _TimeSuggestion(
        timeOfDay: TimeOfDay.morning,
        greeting: 'Good Morning!',
        message: 'Start your day with these peaceful spots',
        emoji: '🌅',
        gradient: [const Color(0xFFFFB347), const Color(0xFFFFCC33)],
      );
    } else if (hour >= 10 && hour < 14) {
      return _TimeSuggestion(
        timeOfDay: TimeOfDay.midday,
        greeting: 'Lunch Time!',
        message: 'Great places to grab a bite nearby',
        emoji: '☀️',
        gradient: [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
      );
    } else if (hour >= 14 && hour < 17) {
      return _TimeSuggestion(
        timeOfDay: TimeOfDay.afternoon,
        greeting: 'Good Afternoon!',
        message: 'Perfect time for sightseeing',
        emoji: '🏛️',
        gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      );
    } else if (hour >= 17 && hour < 20) {
      return _TimeSuggestion(
        timeOfDay: TimeOfDay.evening,
        greeting: 'Good Evening!',
        message: 'Catch the sunset at these spots',
        emoji: '🌆',
        gradient: [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      );
    } else {
      return _TimeSuggestion(
        timeOfDay: TimeOfDay.night,
        greeting: 'Night Owl?',
        message: 'Places with great nightlife',
        emoji: '🌙',
        gradient: [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
      );
    }
  }

  /// Get suggested categories based on time of day
  List<PlaceCategory> _getSuggestedCategories(TimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case TimeOfDay.morning:
        return [
          PlaceCategory.religious,
          PlaceCategory.nature,
          PlaceCategory.hillStation,
        ];
      case TimeOfDay.midday:
        return [
          PlaceCategory.urban,
          PlaceCategory.familyKids,
          PlaceCategory.heritage,
        ];
      case TimeOfDay.afternoon:
        return [
          PlaceCategory.heritage,
          PlaceCategory.wildlife,
          PlaceCategory.adventure,
        ];
      case TimeOfDay.evening:
        return [
          PlaceCategory.hillStation,
          PlaceCategory.beach,
          PlaceCategory.honeymoon,
        ];
      case TimeOfDay.night:
        return [
          PlaceCategory.urban,
          PlaceCategory.honeymoon,
          PlaceCategory.seniorFriendly,
        ];
    }
  }

  /// Get popular nearby places (highest rated)
  List<DiscoverPlace> _getPopularNearby(List<DiscoverPlace> places) {
    final sorted = List<DiscoverPlace>.from(places);
    sorted.sort((a, b) {
      final ratingA = a.rating ?? 0;
      final ratingB = b.rating ?? 0;
      if (ratingA != ratingB) return ratingB.compareTo(ratingA);
      // Tie-breaker: more reviews
      return (b.userRatingsTotal ?? 0).compareTo(a.userRatingsTotal ?? 0);
    });
    return sorted.take(5).toList();
  }

  /// Get trending places (most reviewed)
  List<DiscoverPlace> _getTrending(List<DiscoverPlace> places) {
    final sorted = List<DiscoverPlace>.from(places);
    sorted.sort((a, b) {
      return (b.userRatingsTotal ?? 0).compareTo(a.userRatingsTotal ?? 0);
    });
    // Filter to places with significant reviews
    return sorted
        .where((p) => (p.userRatingsTotal ?? 0) > 100)
        .take(5)
        .toList();
  }

  /// Get personalized suggestions based on favorites
  List<DiscoverPlace> _getPersonalized(
    List<DiscoverPlace> places,
    Set<String> favoriteIds,
  ) {
    if (favoriteIds.isEmpty) return [];

    // Find categories user likes
    final favoriteTypes = <String>{};
    for (final place in places) {
      if (favoriteIds.contains(place.placeId)) {
        favoriteTypes.addAll(place.types);
      }
    }

    if (favoriteTypes.isEmpty) return [];

    // Find similar places not yet favorited
    final suggestions = places.where((p) {
      if (favoriteIds.contains(p.placeId)) return false;
      return p.types.any((t) => favoriteTypes.contains(t));
    }).toList();

    // Sort by rating
    suggestions.sort((a, b) {
      return (b.rating ?? 0).compareTo(a.rating ?? 0);
    });

    return suggestions.take(5).toList();
  }
}

/// Time of day enum
enum TimeOfDay { morning, midday, afternoon, evening, night }

/// Time suggestion data
class _TimeSuggestion {
  final TimeOfDay timeOfDay;
  final String greeting;
  final String message;
  final String emoji;
  final List<Color> gradient;

  _TimeSuggestion({
    required this.timeOfDay,
    required this.greeting,
    required this.message,
    required this.emoji,
    required this.gradient,
  });
}

/// Time suggestion banner widget
class _TimeSuggestionBanner extends StatelessWidget {
  final _TimeSuggestion suggestion;
  final List<PlaceCategory> suggestedCategories;
  final Function(PlaceCategory) onCategoryTapped;

  const _TimeSuggestionBanner({
    required this.suggestion,
    required this.suggestedCategories,
    required this.onCategoryTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: suggestion.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: suggestion.gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  suggestion.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.greeting,
                        style: context.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        suggestion.message,
                        style: context.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Suggested categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: suggestedCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CategoryChip(
                    category: category,
                    onTap: () => onCategoryTapped(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category chip for time suggestions
class _CategoryChip extends StatelessWidget {
  final PlaceCategory category;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                category.displayName,
                style: context.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal suggestion row
class _SuggestionRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String subtitle;
  final List<DiscoverPlace> places;
  final Function(DiscoverPlace) onPlaceTapped;
  final Function(DiscoverPlace) onQuickAdd;
  final Set<String> favoriteIds;
  final bool showVisitorCount;

  const _SuggestionRow({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.subtitle,
    required this.places,
    required this.onPlaceTapped,
    required this.onQuickAdd,
    required this.favoriteIds,
    this.showVisitorCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Horizontal scroll of place cards
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              final isFavorite = favoriteIds.contains(place.placeId);
              return _CompactPlaceCard(
                place: place,
                isFavorite: isFavorite,
                onTap: () => onPlaceTapped(place),
                onQuickAdd: () => onQuickAdd(place),
                showVisitorCount: showVisitorCount,
                iconColor: iconColor,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Compact place card for horizontal scroll
class _CompactPlaceCard extends ConsumerWidget {
  final DiscoverPlace place;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final bool showVisitorCount;
  final Color iconColor;

  const _CompactPlaceCard({
    required this.place,
    required this.isFavorite,
    required this.onTap,
    required this.onQuickAdd,
    required this.showVisitorCount,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get photo URL from provider if photo reference exists
    final photoUrlAsync = place.firstPhotoReference != null
        ? ref.watch(placePhotoUrlProvider(place.firstPhotoReference!))
        : const AsyncValue<String?>.data(null);

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.textColor.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Photo
                      SizedBox(
                        height: 85,
                        width: double.infinity,
                        child: photoUrlAsync.when(
                          data: (photoUrl) => photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, s) => _buildPlaceholder(context),
                                )
                              : _buildPlaceholder(context),
                          loading: () => _buildPlaceholder(context),
                          error: (e, s) => _buildPlaceholder(context),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Rating badge
                      if (place.rating != null)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  place.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Favorite indicator
                      if (isFavorite)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      // Visitor count badge
                      if (showVisitorCount && place.userRatingsTotal != null)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatCount(place.userRatingsTotal!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: context.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Open status or quick add
                        Row(
                          children: [
                            if (place.openNow != null)
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: place.openNow!
                                            ? Colors.green
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      place.openNow! ? 'Open' : 'Closed',
                                      style: context.bodySmall.copyWith(
                                        fontSize: 9,
                                        color: place.openNow!
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onQuickAdd();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: context.primaryColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.image,
          color: context.primaryColor.withValues(alpha: 0.3),
          size: 24,
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
