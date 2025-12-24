import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/discover_providers.dart';

/// A bottom sheet that allows users to search for a location
/// and select it to explore places in that area.
class LocationSearchSheet extends ConsumerStatefulWidget {
  const LocationSearchSheet({super.key});

  /// Show the location search sheet as a modal bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSearchSheet(),
    );
  }

  @override
  ConsumerState<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends ConsumerState<LocationSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _isSelectingPlace = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto focus the search field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Use the debounced search from Google Places Service
    ref.read(googlePlacesServiceProvider).getAutocompleteDebounced(
      query: query,
      types: '(regions)', // Search for cities, regions, countries
      onResults: (predictions) {
        if (mounted) {
          setState(() {
            _predictions = predictions;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() {
      _isSelectingPlace = true;
      _error = null;
    });

    try {
      final placesService = ref.read(googlePlacesServiceProvider);
      final details = await placesService.getPlaceDetails(
        placeId: prediction.placeId,
      );

      if (details == null) {
        setState(() {
          _error = 'Could not get location details. Please try again.';
          _isSelectingPlace = false;
        });
        return;
      }

      if (details.latitude == null || details.longitude == null) {
        setState(() {
          _error = 'Location coordinates not available. Please try another place.';
          _isSelectingPlace = false;
        });
        return;
      }

      // Update the discover provider with the selected location
      // Pass the country so category-specific coordinates can be used
      await ref.read(discoverStateProvider.notifier).setLocation(
        latitude: details.latitude!,
        longitude: details.longitude!,
        locationName: details.shortName,
        country: details.country, // Pass country for category-specific search
      );

      // Close the bottom sheet
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ [LocationSearch] Error selecting place: $e');
      setState(() {
        _error = 'Failed to select location. Please try again.';
        _isSelectingPlace = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isSelectingPlace = true;
      _error = null;
    });

    try {
      // Clear country and use GPS location
      await ref.read(discoverStateProvider.notifier).clearCountry();

      // Close the bottom sheet
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ [LocationSearch] Error using current location: $e');
      setState(() {
        _error = 'Failed to get current location. Please try again.';
        _isSelectingPlace = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: context.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Location',
                          style: context.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Search for any city, region, or landmark',
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
            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: context.textColor.withValues(alpha: 0.5),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _predictions = [];
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.textColor.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.textColor.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: context.bodySmall.copyWith(
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading or selecting indicator
            if (_isLoading || _isSelectingPlace)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isSelectingPlace ? 'Setting location...' : 'Searching...',
                      style: context.bodyMedium.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

            // Results list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Use Current Location option
                  if (_searchController.text.isEmpty && !_isSelectingPlace)
                    _buildCurrentLocationTile(),

                  // Search results
                  if (_predictions.isNotEmpty && !_isSelectingPlace) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        'Search Results',
                        style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ..._predictions.map((prediction) => _buildPredictionTile(prediction)),
                  ],

                  // Empty state
                  if (_predictions.isEmpty &&
                      _searchController.text.isNotEmpty &&
                      !_isLoading &&
                      !_isSelectingPlace)
                    _buildEmptyState(),

                  // Popular locations when search is empty
                  if (_searchController.text.isEmpty && !_isSelectingPlace) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Text(
                        'Popular Destinations',
                        style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ..._popularLocations.map((loc) => _buildQuickLocationTile(loc)),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: _useCurrentLocation,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          'Use Current Location',
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Search places near your GPS location',
          style: context.bodySmall.copyWith(
            color: context.textColor.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: context.textColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildPredictionTile(PlacePrediction prediction) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _selectPlace(prediction),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            prediction.typeIcon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          prediction.mainText,
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          prediction.secondaryText,
          style: context.bodySmall.copyWith(
            color: context.textColor.withValues(alpha: 0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: context.textColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildQuickLocationTile(_QuickLocation location) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () async {
          setState(() {
            _isSelectingPlace = true;
          });

          await ref.read(discoverStateProvider.notifier).setLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: location.name,
            country: location.country, // Pass country for category-specific search
          );

          if (mounted) {
            Navigator.pop(context);
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: location.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            location.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          location.name,
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          location.description,
          style: context.bodySmall.copyWith(
            color: context.textColor.withValues(alpha: 0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: context.textColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: context.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No locations found',
            style: context.titleSmall.copyWith(
              color: context.textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching for a city, region, or country',
            style: context.bodySmall.copyWith(
              color: context.textColor.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Popular quick-access locations
  static final List<_QuickLocation> _popularLocations = [
    _QuickLocation(
      name: 'Goa, India',
      description: 'Beaches & nightlife',
      emoji: '🏖️',
      color: Colors.orange,
      latitude: 15.2993,
      longitude: 74.1240,
      country: 'India',
    ),
    _QuickLocation(
      name: 'Phuket, Thailand',
      description: 'Tropical paradise',
      emoji: '🌴',
      color: Colors.green,
      latitude: 7.8804,
      longitude: 98.3923,
      country: 'Thailand',
    ),
    _QuickLocation(
      name: 'Bali, Indonesia',
      description: 'Culture & beaches',
      emoji: '🏝️',
      color: Colors.teal,
      latitude: -8.4095,
      longitude: 115.1889,
      country: 'Indonesia',
    ),
    _QuickLocation(
      name: 'Paris, France',
      description: 'City of love',
      emoji: '🗼',
      color: Colors.blue,
      latitude: 48.8566,
      longitude: 2.3522,
      country: 'France',
    ),
    _QuickLocation(
      name: 'Tokyo, Japan',
      description: 'Modern & traditional',
      emoji: '🗾',
      color: Colors.red,
      latitude: 35.6762,
      longitude: 139.6503,
      country: 'Japan',
    ),
    _QuickLocation(
      name: 'Dubai, UAE',
      description: 'Luxury & adventure',
      emoji: '🌃',
      color: Colors.amber,
      latitude: 25.2048,
      longitude: 55.2708,
      country: 'UAE',
    ),
  ];
}

/// Data class for quick location options
class _QuickLocation {
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final double latitude;
  final double longitude;
  final String country; // Country name for category-specific coordinates

  const _QuickLocation({
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.latitude,
    required this.longitude,
    required this.country,
  });
}
