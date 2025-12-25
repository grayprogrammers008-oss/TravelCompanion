import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../shared/models/trip_model.dart';
import '../providers/ai_suggestions_provider.dart';
import '../providers/trip_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../../../../shared/models/itinerary_model.dart';
import '../../../discover/presentation/providers/discover_providers.dart';
import '../../../discover/domain/entities/discover_place.dart';
import '../../../discover/domain/entities/place_category.dart';

/// AI-powered suggestions card that appears on the Home page
/// Shows nearby places, weather, and travel tips based on context
class AiSuggestionsCard extends ConsumerWidget {
  final AppThemeData themeData;

  const AiSuggestionsCard({
    super.key,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(aiSuggestionsProvider);

    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions == null || suggestions.places.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildCard(context, ref, suggestions);
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => const SizedBox.shrink(), // Hide on error
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        0,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00D9FF).withValues(alpha: 0.1),
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Finding nearby places...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, AiSuggestions suggestions) {
    // Watch discover state for favorites
    final discoverState = ref.watch(discoverStateProvider);
    final favoriteIds = discoverState.favoriteIds;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00D9FF).withValues(alpha: 0.15),
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - compact design
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingSm,
                AppTheme.spacingSm,
                AppTheme.spacingXs,
                0,
              ),
              child: Row(
                children: [
                  // AI Icon with gradient - smaller
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Explore Nearby',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${suggestions.contextLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // See All button - more compact
                  GestureDetector(
                    onTap: () => _showAllPlaces(context, ref, suggestions),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: themeData.primaryColor,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: themeData.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal scrollable places - compact design
            SizedBox(
              height: 80, // Compact height that fits content without overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingXs,
                  AppTheme.spacingMd,
                  AppTheme.spacingSm,
                ),
                itemCount: suggestions.places.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final place = suggestions.places[index];
                  final isFavorite = favoriteIds.contains(place.placeId);
                  return _buildPlaceCard(context, ref, place, index == 0, isFavorite);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, WidgetRef ref, NearbyPlace place, bool isFirst, bool isFavorite) {
    final placesService = GooglePlacesService();
    // Request higher quality photo (400px for crisp display on retina screens)
    final photoUrl = place.photos.isNotEmpty
        ? placesService.getPhotoUrl(
            photoReference: place.photos.first.photoReference,
            maxWidth: 400,
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(
        right: AppTheme.spacingSm,
        left: isFirst ? 0 : 0,
      ),
      child: GestureDetector(
        onTap: () => _showPlaceDetails(context, ref, place),
        child: Container(
          width: 150, // Compact width for horizontal layout
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  // Image - left side
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppTheme.radiusMd),
                    ),
                    child: SizedBox(
                      width: 50,
                      height: double.infinity,
                      child: Container(
                        color: AppTheme.neutral100,
                        child: photoUrl != null
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 50,
                                height: double.infinity,
                                errorBuilder: (context, error, stack) => _buildPlaceholder(place),
                              )
                            : _buildPlaceholder(place),
                      ),
                    ),
                  ),
                  // Info - right side
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              place.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (place.rating != null) ...[
                                const Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  place.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.neutral600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (place.openNow != null) ...[
                                if (place.rating != null) const SizedBox(width: 4),
                                Text(
                                  place.openNow! ? '• Open' : '• Closed',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: place.openNow! ? Colors.green : Colors.red,
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
              // Favorite button - top right corner
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _toggleFavorite(ref, place),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? const Color(0xFFE91E63).withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggle favorite for a place
  void _toggleFavorite(WidgetRef ref, NearbyPlace place) {
    HapticFeedback.lightImpact();
    // Convert NearbyPlace to DiscoverPlace for the toggle
    final discoverPlace = DiscoverPlace(
      placeId: place.placeId,
      name: place.name,
      vicinity: place.vicinity,
      latitude: place.latitude,
      longitude: place.longitude,
      types: place.types,
      rating: place.rating,
      userRatingsTotal: place.userRatingsTotal,
      openNow: place.openNow,
      photos: place.photos,
      category: PlaceCategory.urban, // Default category for nearby places
    );
    ref.read(discoverStateProvider.notifier).toggleFavorite(place.placeId, place: discoverPlace);
  }

  Widget _buildPlaceholder(NearbyPlace place) {
    final icon = _getPlaceIcon(place.types);
    return Container(
      color: AppTheme.neutral100,
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: AppTheme.neutral400,
        ),
      ),
    );
  }

  IconData _getPlaceIcon(List<String> types) {
    if (types.contains('restaurant') || types.contains('food')) {
      return Icons.restaurant;
    }
    if (types.contains('tourist_attraction') || types.contains('point_of_interest')) {
      return Icons.attractions;
    }
    if (types.contains('museum')) {
      return Icons.museum;
    }
    if (types.contains('park')) {
      return Icons.park;
    }
    if (types.contains('shopping_mall') || types.contains('store')) {
      return Icons.shopping_bag;
    }
    if (types.contains('lodging') || types.contains('hotel')) {
      return Icons.hotel;
    }
    return Icons.place;
  }

  void _showPlaceDetails(BuildContext context, WidgetRef ref, NearbyPlace place) {
    // For now, show a simple bottom sheet with place details
    // In future, could navigate to a detailed place page
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow sheet to resize for keyboard/content
      builder: (context) => SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Place name
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),

                  // Rating and status - wrap to prevent overflow
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (place.rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 4),
                            Text(
                              '${place.rating!.toStringAsFixed(1)} (${place.userRatingsTotal ?? 0})',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.neutral600,
                              ),
                            ),
                          ],
                        ),
                      if (place.openNow != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: place.openNow!
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            place.openNow! ? 'Open Now' : 'Closed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: place.openNow! ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (place.vicinity != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.neutral500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.vicinity!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingMd),

                  // Action buttons - 3 options
                  Column(
                    children: [
                      // Primary action: Add & Schedule (opens form)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToTripWithSchedule(context, ref, place);
                          },
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text('Add & Schedule'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      // Secondary actions row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _openDirections(place);
                              },
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Directions', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _quickAddToTrip(context, ref, place);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Quick Add', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Open Google Maps with directions to the place
  Future<void> _openDirections(NearbyPlace place) async {
    if (place.latitude == null || place.longitude == null) {
      debugPrint('⚠️ [AISuggestions] No coordinates for directions');
      return;
    }

    // Try Google Maps app first, fallback to web
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}&destination_place_id=${place.placeId}',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to Apple Maps on iOS
        final appleMapsUrl = Uri.parse(
          'https://maps.apple.com/?daddr=${place.latitude},${place.longitude}&dirflg=d',
        );
        if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('❌ [AISuggestions] Failed to open directions: $e');
    }
  }

  /// Add to trip with schedule - shows visual slot picker
  void _addToTripWithSchedule(BuildContext context, WidgetRef ref, NearbyPlace place) {
    final tripsAsync = ref.read(userTripsProvider);

    tripsAsync.when(
      data: (trips) {
        // Filter to only active (non-completed) trips
        final activeTrips = trips.where((t) => !t.trip.isCompleted).toList();

        if (activeTrips.isEmpty) {
          _showNoTripsDialog(context);
        } else if (activeTrips.length == 1) {
          // Single active trip - show slot picker directly
          _showItinerarySlotPicker(context, ref, activeTrips.first, place);
        } else {
          // Multiple active trips - show selector then slot picker
          _showTripSelectorForSchedule(context, ref, activeTrips, place);
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading your trips...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (_, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load trips. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      },
    );
  }

  /// Show visual itinerary slot picker to insert place
  void _showItinerarySlotPicker(
    BuildContext context,
    WidgetRef ref,
    TripWithMembers tripWithMembers,
    NearbyPlace place,
  ) {
    HapticFeedback.mediumImpact();
    final trip = tripWithMembers.trip;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with place info
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [themeData.primaryColor, themeData.primaryColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.add_location_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insert "${place.name}"',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tap a slot to add to ${trip.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Itinerary slot picker
              Expanded(
                child: _ItinerarySlotPicker(
                  tripId: trip.id,
                  place: place,
                  themeData: themeData,
                  scrollController: scrollController,
                  onSlotSelected: (dayNumber, orderIndex) async {
                    Navigator.pop(sheetContext);
                    await _performQuickAddWithSlot(
                      context,
                      ref,
                      tripWithMembers,
                      place,
                      dayNumber,
                      orderIndex,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Perform quick add at specific slot
  Future<void> _performQuickAddWithSlot(
    BuildContext context,
    WidgetRef ref,
    TripWithMembers tripWithMembers,
    NearbyPlace place,
    int dayNumber,
    int orderIndex,
  ) async {
    HapticFeedback.mediumImpact();

    final trip = tripWithMembers.trip;
    final controller = ref.read(itineraryControllerProvider.notifier);

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Adding to Day $dayNumber...')),
          ],
        ),
        backgroundColor: themeData.primaryColor,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      await controller.createItem(
        tripId: trip.id,
        title: place.name,
        description: _buildPlaceDescription(place),
        location: place.vicinity ?? place.name,
        // Note: Not passing latitude/longitude to maintain consistent display format
        // with existing itinerary items (simple time indicator instead of map thumbnail)
        placeId: place.placeId,
        dayNumber: dayNumber,
        orderIndex: orderIndex,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        HapticFeedback.lightImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Added to Day $dayNumber'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                context.push('/trips/${trip.id}/itinerary');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Show trip selector then show slot picker
  void _showTripSelectorForSchedule(
    BuildContext context,
    WidgetRef ref,
    List<TripWithMembers> activeTrips,
    NearbyPlace place,
  ) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeData.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          Icons.edit_calendar,
                          color: themeData.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add & Schedule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Choose trip for "${place.name}"',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral500,
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

                const Divider(height: 1),

                // Trip list
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
                    itemCount: activeTrips.length,
                    itemBuilder: (context, index) {
                      final tripWithMembers = activeTrips[index];
                      final trip = tripWithMembers.trip;

                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            color: AppTheme.neutral100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            child: DestinationImage(
                              destination: trip.destination ?? trip.name,
                              tripId: trip.id,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        title: Text(
                          trip.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          trip.destination ?? 'No destination',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.neutral400,
                          size: 22,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showItinerarySlotPicker(context, ref, tripWithMembers, place);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Quick add place to trip itinerary - smart selection based on active trips
  void _quickAddToTrip(BuildContext context, WidgetRef ref, NearbyPlace place) {
    final tripsAsync = ref.read(userTripsProvider);

    tripsAsync.when(
      data: (trips) {
        // Filter to only active (non-completed) trips
        final activeTrips = trips.where((t) => !t.trip.isCompleted).toList();

        if (activeTrips.isEmpty) {
          // No active trips - prompt to create one
          _showNoTripsDialog(context);
        } else if (activeTrips.length == 1) {
          // Single active trip - quick add directly
          _performQuickAdd(context, ref, activeTrips.first, place);
        } else {
          // Multiple active trips - show selector for quick add
          _showQuickAddTripSelector(context, ref, activeTrips, place);
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading your trips...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      error: (_, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load trips. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      },
    );
  }

  /// Perform quick add - directly save to itinerary without navigation
  Future<void> _performQuickAdd(
    BuildContext context,
    WidgetRef ref,
    TripWithMembers tripWithMembers,
    NearbyPlace place,
  ) async {
    HapticFeedback.mediumImpact();

    final trip = tripWithMembers.trip;
    final controller = ref.read(itineraryControllerProvider.notifier);

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Adding "${place.name}"...')),
          ],
        ),
        backgroundColor: themeData.primaryColor,
        duration: const Duration(seconds: 10), // Will be dismissed on completion
      ),
    );

    try {
      await controller.createItem(
        tripId: trip.id,
        title: place.name,
        description: _buildPlaceDescription(place),
        location: place.vicinity ?? place.name,
        // Note: Not passing latitude/longitude to maintain consistent display format
        // with existing itinerary items (simple time indicator instead of map thumbnail)
        placeId: place.placeId,
      );

      // Clear the loading snackbar and show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        HapticFeedback.lightImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Added to "${trip.name}" itinerary'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                context.push('/trips/${trip.id}/itinerary');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Show dialog when user has no active trips
  void _showNoTripsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Active Trips'),
        content: const Text(
          'Create a trip first to add this place to your itinerary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/trips/create');
            },
            child: const Text('Create Trip'),
          ),
        ],
      ),
    );
  }

  /// Show trip selector for quick add (only active trips)
  void _showQuickAddTripSelector(
    BuildContext context,
    WidgetRef ref,
    List<TripWithMembers> activeTrips,
    NearbyPlace place,
  ) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header - compact
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeData.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Icon(
                          Icons.add_location_alt,
                          color: themeData.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Add to Trip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              place.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral500,
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

                const Divider(height: 1),

                // Trip list - compact
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
                    itemCount: activeTrips.length,
                    itemBuilder: (context, index) {
                      final tripWithMembers = activeTrips[index];
                      final trip = tripWithMembers.trip;

                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            color: AppTheme.neutral100,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            child: DestinationImage(
                              destination: trip.destination ?? trip.name,
                              tripId: trip.id,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        title: Text(
                          trip.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          trip.destination ?? 'No destination',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.add_circle,
                          color: themeData.primaryColor,
                          size: 22,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _performQuickAdd(context, ref, tripWithMembers, place);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build description from place data
  String _buildPlaceDescription(NearbyPlace place) {
    final parts = <String>[];

    if (place.rating != null) {
      parts.add('⭐ ${place.rating!.toStringAsFixed(1)} rating');
    }

    if (place.userRatingsTotal != null && place.userRatingsTotal! > 0) {
      parts.add('${place.userRatingsTotal} reviews');
    }

    if (place.types.isNotEmpty) {
      final typeLabels = place.types
          .take(2)
          .map((t) => t.replaceAll('_', ' '))
          .map((t) => t[0].toUpperCase() + t.substring(1))
          .toList();
      parts.add(typeLabels.join(', '));
    }

    return parts.join(' · ');
  }

  void _showAllPlaces(BuildContext context, WidgetRef ref, AiSuggestions suggestions) {
    // Show a full-screen bottom sheet with all places
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingMd),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nearby Places',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            suggestions.contextLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Places list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: suggestions.places.length,
                  itemBuilder: (context, index) {
                    final place = suggestions.places[index];
                    return _buildPlaceListTile(context, ref, place);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceListTile(BuildContext context, WidgetRef ref, NearbyPlace place) {
    final placesService = GooglePlacesService();
    // Request higher quality photo for list tiles
    final photoUrl = place.photos.isNotEmpty
        ? placesService.getPhotoUrl(
            photoReference: place.photos.first.photoReference,
            maxWidth: 300,
          )
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showPlaceDetails(context, ref, place);
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.neutral100,
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _buildPlaceholder(place),
                        )
                      : _buildPlaceholder(place),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          const Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 2),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          if (place.userRatingsTotal != null) ...[
                            Text(
                              ' (${place.userRatingsTotal})',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.neutral500,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                        ],
                        if (place.openNow != null)
                          Text(
                            place.openNow! ? '• Open' : '• Closed',
                            style: TextStyle(
                              fontSize: 12,
                              color: place.openNow! ? Colors.green : Colors.red,
                            ),
                          ),
                      ],
                    ),
                    if (place.vicinity != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        place.vicinity!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: AppTheme.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual itinerary slot picker widget
class _ItinerarySlotPicker extends ConsumerWidget {
  final String tripId;
  final NearbyPlace place;
  final AppThemeData themeData;
  final ScrollController scrollController;
  final Function(int dayNumber, int orderIndex) onSlotSelected;

  const _ItinerarySlotPicker({
    required this.tripId,
    required this.place,
    required this.themeData,
    required this.scrollController,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryByDaysProvider(tripId));

    return itineraryAsync.when(
      data: (days) {
        if (days.isEmpty) {
          // No existing itinerary - show day 1 option
          return _buildEmptyItinerary(context);
        }
        return _buildDaysList(context, days);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Error loading itinerary: $e'),
        ),
      ),
    );
  }

  Widget _buildEmptyItinerary(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Add to Day 1 option
        _buildDayHeader(1, 0),
        _buildInsertSlot(
          context,
          dayNumber: 1,
          orderIndex: 0,
          label: 'Add as first activity',
        ),
        const SizedBox(height: AppTheme.spacingLg),
        // Quick add days
        Text(
          'Or add to another day:',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.neutral500,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 2; // Days 2-8
            return ActionChip(
              label: Text('Day $day'),
              onPressed: () => onSlotSelected(day, 0),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDaysList(BuildContext context, List<ItineraryDay> days) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: days.length + 1, // +1 for "Add new day" option
      itemBuilder: (context, index) {
        if (index == days.length) {
          // Add new day option
          final nextDay = days.isEmpty ? 1 : days.last.dayNumber + 1;
          return Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: _buildInsertSlot(
              context,
              dayNumber: nextDay,
              orderIndex: 0,
              label: 'Add to Day $nextDay (new day)',
              isNewDay: true,
            ),
          );
        }

        final day = days[index];
        return _buildDaySection(context, day);
      },
    );
  }

  Widget _buildDaySection(BuildContext context, ItineraryDay day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDayHeader(day.dayNumber, day.items.length),
        // Insert slot at start of day
        _buildInsertSlot(
          context,
          dayNumber: day.dayNumber,
          orderIndex: 0,
          label: 'Insert at start',
          compact: true,
        ),
        // Existing items with insert slots between them
        ...day.items.asMap().entries.expand((entry) {
          final itemIndex = entry.key;
          final item = entry.value;
          return [
            _buildExistingItem(item),
            _buildInsertSlot(
              context,
              dayNumber: day.dayNumber,
              orderIndex: itemIndex + 1,
              label: 'Insert here',
              compact: true,
            ),
          ];
        }),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildDayHeader(int dayNumber, int itemCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: themeData.primaryColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              'Day $dayNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            itemCount == 0 ? 'No activities' : '$itemCount ${itemCount == 1 ? 'activity' : 'activities'}',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingItem(ItineraryItemModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place,
            size: 16,
            color: AppTheme.neutral500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neutral700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.startTime != null)
            Text(
              '${item.startTime!.hour.toString().padLeft(2, '0')}:${item.startTime!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.neutral500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsertSlot(
    BuildContext context, {
    required int dayNumber,
    required int orderIndex,
    required String label,
    bool compact = false,
    bool isNewDay = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSlotSelected(dayNumber, orderIndex);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: themeData.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: themeData.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNewDay ? Icons.add_circle : Icons.add,
              size: compact ? 14 : 18,
              color: themeData.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: themeData.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
