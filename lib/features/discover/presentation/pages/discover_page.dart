import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/services/google_maps_url_parser.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../itinerary/presentation/widgets/add_location_to_trip_sheet.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/popular_destination.dart';
import '../providers/discover_providers.dart';
import '../widgets/mini_map_preview.dart';
import '../widgets/place_card.dart';
import '../widgets/smart_suggestions_section.dart';
import '../widgets/place_detail_sheet.dart';
import '../widgets/popular_destinations_section.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/trip_planning_assistant_sheet.dart';

/// Discover Page - Browse tourist places by category
/// Uses Google Places API to fetch real data based on user location
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('🏠 [DiscoverPage] initState called');
    // Initialize location and load places on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎯 [DiscoverPage] Post frame callback - calling initialize()');
      ref.read(discoverStateProvider.notifier).initialize();
    });
  }

  void _onCategorySelected(PlaceCategory category) {
    ref.read(discoverStateProvider.notifier).changeCategory(category);
  }

  void _onPlaceTapped(DiscoverPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetailSheet(place: place),
    );
  }

  void _showQuickAddToTrip(DiscoverPlace place) {
    // Convert DiscoverPlace to ParsedLocation for the AddLocationToTripSheet
    final location = ParsedLocation(
      latitude: place.latitude,
      longitude: place.longitude,
      placeName: place.name,
      placeId: place.placeId,
      originalUrl: 'https://www.google.com/maps/place/?q=place_id:${place.placeId}',
    );

    // Show the Add to Trip sheet
    AddLocationToTripSheet.show(context, location);
  }

  void _onDestinationTapped(PopularDestination destination) {
    // Show a bottom sheet with destination details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DestinationDetailSheet(
        destination: destination,
        onExploreNearby: () {
          Navigator.pop(context);
          _onExploreNearby(destination);
        },
      ),
    );
  }

  void _onExploreNearby(PopularDestination destination) {
    // Set the location to the destination and load nearby places
    ref.read(discoverStateProvider.notifier).setLocation(
      latitude: destination.latitude,
      longitude: destination.longitude,
      locationName: destination.name,
      country: destination.country, // Pass country for category-specific search
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverStateProvider);
    final filteredPlaces = discoverState.filteredPlaces;
    final hasLocation = discoverState.hasLocation;

    return Scaffold(
      floatingActionButton: _buildFloatingActionButton(discoverState),
      body: CustomScrollView(
        slivers: [
          // App Bar Header
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: context.primaryColor,
            elevation: 0,
            title: Row(
              children: [
                Icon(
                  Icons.explore,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Discover',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            actions: [
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: () {
                  ref.read(discoverStateProvider.notifier).refresh();
                },
              ),
              // Map toggle button
              if (hasLocation && filteredPlaces.isNotEmpty)
                IconButton(
                  icon: Icon(
                    discoverState.viewMode == DiscoverViewMode.grid
                        ? Icons.map_outlined
                        : Icons.grid_view,
                    color: Colors.white,
                  ),
                  tooltip: discoverState.viewMode == DiscoverViewMode.grid
                      ? 'Map View'
                      : 'Grid View',
                  onPressed: () {
                    ref.read(discoverStateProvider.notifier).toggleViewMode();
                  },
                ),
            ],
          ),

          // LOADING STATES (shown regardless of location)
          if (discoverState.isGettingLocation)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your location...'),
                  ],
                ),
              ),
            )
          else if (discoverState.error != null)
            SliverFillRemaining(
              child: _buildErrorState(discoverState.error!, discoverState.isPermissionDeniedForever),
            )
          else if (discoverState.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Finding places near you...'),
                  ],
                ),
              ),
            )

          // NO LOCATION: Show inspirational content first
          else if (!hasLocation) ...[
            // Location controls (search & enable location)
            SliverToBoxAdapter(
              child: _buildLocationPrompt(discoverState),
            ),

            // AI-Powered Recommendations (always visible)
            SliverToBoxAdapter(
              child: RecommendationsSection(
                onPlaceTapped: _onPlaceTapped,
                onQuickAdd: _showQuickAddToTrip,
              ),
            ),

            // Popular Destinations (PROMINENT)
            SliverToBoxAdapter(
              child: PopularDestinationsSection(
                onDestinationTapped: _onDestinationTapped,
                onExploreNearby: _onExploreNearby,
              ),
            ),

            // Categories (for future use when they enable location)
            SliverToBoxAdapter(
              child: _buildCategorySection(discoverState, filteredPlaces.length),
            ),
          ]

          // HAS LOCATION: Show nearby content first
          else if (discoverState.viewMode == DiscoverViewMode.map)
            SliverFillRemaining(
              child: _buildMapView(filteredPlaces, discoverState),
            )
          else ...[
            // Location indicator with controls
            SliverToBoxAdapter(
              child: _buildLocationIndicator(discoverState),
            ),

            // AI-Powered Recommendations (always visible)
            SliverToBoxAdapter(
              child: RecommendationsSection(
                onPlaceTapped: _onPlaceTapped,
                onQuickAdd: _showQuickAddToTrip,
              ),
            ),

            // Category Selection Section (IMMEDIATE ACTION)
            SliverToBoxAdapter(
              child: _buildCategorySection(discoverState, filteredPlaces.length),
            ),

            // NEARBY PLACES - PRIMARY CONTENT
            if (filteredPlaces.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(discoverState),
              )
            else ...[
              // Mini Map Preview (collapsible)
              SliverToBoxAdapter(
                child: MiniMapPreview(
                  places: filteredPlaces,
                  userLatitude: discoverState.userLatitude,
                  userLongitude: discoverState.userLongitude,
                  radiusKm: discoverState.selectedDistance.kilometers.toDouble(),
                  category: discoverState.selectedCategory,
                  onPlaceTapped: _onPlaceTapped,
                  onExpandTapped: () {
                    ref.read(discoverStateProvider.notifier).toggleViewMode();
                  },
                ),
              ),

              // Places Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final place = filteredPlaces[index];
                      return PlaceCard(
                        place: place,
                        userLatitude: discoverState.userLatitude,
                        userLongitude: discoverState.userLongitude,
                        isFavorite: discoverState.isFavorite(place.placeId),
                        onTap: () => _onPlaceTapped(place),
                        onFavoriteToggle: () {
                          ref.read(discoverStateProvider.notifier).toggleFavorite(place.placeId, place: place);
                        },
                        onQuickAdd: () => _showQuickAddToTrip(place),
                      );
                    },
                    childCount: filteredPlaces.length,
                  ),
                ),
              ),

              // Smart Suggestions (context-aware)
              if (discoverState.places.isNotEmpty)
                SliverToBoxAdapter(
                  child: SmartSuggestionsSection(
                    onPlaceTapped: _onPlaceTapped,
                    onQuickAdd: _showQuickAddToTrip,
                    onCategoryTapped: _onCategorySelected,
                  ),
                ),

              // Popular Destinations (SECONDARY - Explore More)
              SliverToBoxAdapter(
                child: _buildExploreMoreSection(discoverState),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection(DiscoverState discoverState, int placesCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with results count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'What would you like to explore?',
                style: context.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textColor.withValues(alpha: 0.8),
                ),
              ),
              if (!discoverState.isLoading && discoverState.hasLocation)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: discoverState.selectedCategory.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$placesCount found',
                    style: context.bodySmall.copyWith(
                      color: discoverState.selectedCategory.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Category grid - 4 columns
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: PlaceCategory.values.length,
            itemBuilder: (context, index) {
              final category = PlaceCategory.values[index];
              final isSelected = category == discoverState.selectedCategory;
              return _buildCategoryItem(category, isSelected);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(PlaceCategory category, bool isSelected) {
    return InkWell(
      onTap: () => _onCategorySelected(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.2)
              : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? category.color
                : context.textColor.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: isSelected ? 0.3 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 18,
                color: isSelected ? category.color : category.color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                category.displayName,
                style: context.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? category.color
                      : context.textColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPrompt(DiscoverState discoverState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore,
                    color: context.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Places',
                        style: context.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Find attractions near you or search any location',
                        style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(discoverStateProvider.notifier).getUserLocation(),
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Use My Location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      side: BorderSide(color: context.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDestinationSearch(),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationIndicator(DiscoverState discoverState) {
    final locationName = discoverState.locationName ?? 'Current Location';
    final distance = discoverState.selectedDistance;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location and Search Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Location pill (tappable)
                Expanded(
                  child: InkWell(
                    onTap: () => _showDestinationSearch(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationName,
                              style: context.bodyMedium.copyWith(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.edit_location_outlined,
                            size: 16,
                            color: context.primaryColor.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Search button
                IconButton.filled(
                  onPressed: () => _showDestinationSearch(),
                  icon: const Icon(Icons.search, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                  tooltip: 'Search destination',
                ),
              ],
            ),
          ),

          // Distance selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Icon(
                  Icons.near_me,
                  size: 16,
                  color: context.textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Within:',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: DiscoverDistance.values.map((dist) {
                        final isSelected = dist == distance;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(dist.displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(discoverStateProvider.notifier).changeDistance(dist);
                              }
                            },
                            selectedColor: context.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: context.primaryColor,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? context.primaryColor : context.textColor.withValues(alpha: 0.7),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDestinationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DestinationSearchSheet(
        onDestinationSelected: (lat, lng, name) {
          ref.read(discoverStateProvider.notifier).setLocation(
            latitude: lat,
            longitude: lng,
            locationName: name,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildExploreMoreSection(DiscoverState discoverState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.travel_explore,
                    size: 20,
                    color: context.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Explore More Destinations',
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Discover popular places around the world',
            style: context.bodySmall.copyWith(
              color: context.textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // Popular Destinations
          PopularDestinationsSection(
            onDestinationTapped: _onDestinationTapped,
            onExploreNearby: _onExploreNearby,
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(DiscoverState discoverState) {
    final hasFavorites = discoverState.favoriteIds.isNotEmpty;

    if (hasFavorites) {
      // Show "Plan Trip" when user has favorited places
      return FloatingActionButton.extended(
        onPressed: () => TripPlanningAssistantSheet.show(context),
        icon: const Icon(Icons.auto_awesome),
        label: Text('Plan Trip (${discoverState.favoriteIds.length})'),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
      );
    }

    // Show hint FAB to guide users
    return FloatingActionButton.extended(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap the heart on places you like to save them for trip planning!',
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      icon: const Icon(Icons.lightbulb_outline),
      label: const Text('Get Trip Ideas'),
      backgroundColor: Colors.amber[700],
      foregroundColor: Colors.white,
    );
  }

  Widget _buildMapView(List<DiscoverPlace> places, DiscoverState discoverState) {
    // Sort places by distance
    final sortedPlaces = List<DiscoverPlace>.from(places);
    if (discoverState.userLatitude != null && discoverState.userLongitude != null) {
      sortedPlaces.sort((a, b) {
        final distA = a.distanceFrom(discoverState.userLatitude, discoverState.userLongitude);
        final distB = b.distanceFrom(discoverState.userLatitude, discoverState.userLongitude);
        if (distA == null && distB == null) return 0;
        if (distA == null) return 1;
        if (distB == null) return -1;
        return distA.compareTo(distB);
      });
    }

    return Column(
      children: [
        // Map header with user location
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primaryColor,
                context.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Places Near You',
                      style: context.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sortedPlaces.length} ${discoverState.selectedCategory.displayName.toLowerCase()} sorted by distance',
                      style: context.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Open all in Google Maps button
              if (discoverState.userLatitude != null)
                IconButton(
                  onPressed: () => _openAllInMaps(discoverState),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  tooltip: 'Open in Google Maps',
                ),
            ],
          ),
        ),

        // Places list sorted by distance
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedPlaces.length,
            itemBuilder: (context, index) {
              final place = sortedPlaces[index];
              final distance = place.distanceText(
                discoverState.userLatitude,
                discoverState.userLongitude,
              );
              final isFavorite = discoverState.isFavorite(place.placeId);

              return _buildMapPlaceCard(
                place: place,
                distance: distance,
                index: index + 1,
                isFavorite: isFavorite,
                discoverState: discoverState,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceCard({
    required DiscoverPlace place,
    required String distance,
    required int index,
    required bool isFavorite,
    required DiscoverState discoverState,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onPlaceTapped(place),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Index badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: discoverState.selectedCategory.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Distance
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 14,
                              color: context.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: context.bodySmall.copyWith(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Rating
                        if (place.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 2),
                              Text(
                                place.ratingText,
                                style: context.bodySmall,
                              ),
                            ],
                          ),
                        // Open status
                        if (place.statusText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (place.openNow == true
                                      ? Colors.green
                                      : Colors.red)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              place.statusText!,
                              style: context.bodySmall.copyWith(
                                color: place.openNow == true
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick add to trip button
                  IconButton(
                    onPressed: () => _showQuickAddToTrip(place),
                    icon: Icon(
                      Icons.add_location_alt,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    tooltip: 'Add to Trip',
                  ),
                  // Favorite button
                  IconButton(
                    onPressed: () {
                      ref.read(discoverStateProvider.notifier).toggleFavorite(place.placeId, place: place);
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  // Directions button
                  IconButton(
                    onPressed: () => _openDirections(place),
                    icon: Icon(
                      Icons.directions,
                      color: context.primaryColor,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    tooltip: 'Get Directions',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDirections(DiscoverPlace place) async {
    if (place.latitude == null || place.longitude == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAllInMaps(DiscoverState discoverState) async {
    if (discoverState.userLatitude == null || discoverState.userLongitude == null) return;

    // URL encode the keyword for safe URL usage
    final keyword = Uri.encodeComponent(discoverState.selectedCategory.googlePlaceKeyword);
    final url = Uri.parse(
      'https://www.google.com/maps/search/$keyword/@${discoverState.userLatitude},${discoverState.userLongitude},14z',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildErrorState(String error, [bool isPermissionDeniedForever = false]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermissionDeniedForever ? Icons.location_off : Icons.error_outline,
              size: 64,
              color: isPermissionDeniedForever
                  ? context.primaryColor.withValues(alpha: 0.5)
                  : context.textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isPermissionDeniedForever ? 'Location Access Needed' : 'Oops! Something went wrong',
              style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: context.bodyMedium.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isPermissionDeniedForever) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  ref.read(discoverStateProvider.notifier).initialize();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(discoverStateProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(DiscoverState discoverState) {
    final isShowingFavorites = discoverState.showFavoritesOnly;

    String message;
    IconData icon;

    if (isShowingFavorites) {
      message = 'No favorite places yet. Tap the heart icon on places to add them to your favorites.';
      icon = Icons.favorite_border;
    } else {
      message = 'No ${discoverState.selectedCategory.displayName.toLowerCase()} found nearby. Try a different category or increase the distance.';
      icon = discoverState.selectedCategory.icon;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: discoverState.selectedCategory.color.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isShowingFavorites ? 'No Favorites' : 'No Places Found',
              style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.bodyMedium.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isShowingFavorites)
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(discoverStateProvider.notifier).toggleShowFavoritesOnly();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Show All Places'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(discoverStateProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing destination details
class _DestinationDetailSheet extends StatelessWidget {
  final PopularDestination destination;
  final VoidCallback onExploreNearby;

  const _DestinationDetailSheet({
    required this.destination,
    required this.onExploreNearby,
  });

  @override
  Widget build(BuildContext context) {
    final regionInfo = RegionInfo.getInfo(destination.region);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Hero image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        destination.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: regionInfo.color.withValues(alpha: 0.2),
                          child: Icon(
                            regionInfo.icon,
                            size: 64,
                            color: regionInfo.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name and region
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            destination.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: regionInfo.color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(regionInfo.icon, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                destination.region.split(' ').first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Country
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          destination.country,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      destination.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    // Best time to visit
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Best Time to Visit',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  destination.bestTimeToVisit,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Highlights
                    Text(
                      'Highlights',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: destination.highlights.map((highlight) {
                        return Chip(
                          label: Text(highlight),
                          backgroundColor: regionInfo.color.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          labelStyle: TextStyle(
                            color: regionInfo.color,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onExploreNearby,
                            icon: const Icon(Icons.explore),
                            label: const Text('Explore Nearby'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openInMaps(destination),
                            icon: const Icon(Icons.map),
                            label: const Text('View on Map'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openInMaps(PopularDestination destination) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

/// Bottom sheet for searching destinations
class _DestinationSearchSheet extends StatefulWidget {
  final void Function(double lat, double lng, String name) onDestinationSelected;

  const _DestinationSearchSheet({required this.onDestinationSelected});

  @override
  State<_DestinationSearchSheet> createState() => _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends State<_DestinationSearchSheet> {
  final _searchController = TextEditingController();
  final _placesService = GooglePlacesService();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() => _predictions = []);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _placesService.getAutocomplete(
      query: query,
      types: '(regions)', // Search for cities, regions, countries
    );

    setState(() {
      _predictions = results;
      _isLoading = false;
    });
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    setState(() => _isLoading = true);

    // Get place details to get coordinates
    final details = await _placesService.getPlaceDetails(
      placeId: prediction.placeId,
    );

    setState(() => _isLoading = false);

    if (details != null && details.latitude != null && details.longitude != null) {
      widget.onDestinationSelected(
        details.latitude!,
        details.longitude!,
        prediction.mainText,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Search Destination',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search city, region or place...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _predictions = []);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _predictions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.travel_explore,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Search for a destination\nlike "Ooty" or "Goa"'
                                  : 'No results found',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                prediction.typeIcon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Text(
                              prediction.mainText,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              prediction.secondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _onPredictionSelected(prediction),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
