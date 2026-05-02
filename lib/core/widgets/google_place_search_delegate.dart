import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/google_places_service.dart';
import '../services/place_cache_service.dart';
import '../theme/app_theme.dart';

/// Search delegate for Google Places autocomplete
///
/// Returns a [PlaceDetails] object when a place is selected
class GooglePlaceSearchDelegate extends SearchDelegate<PlaceDetails?> {
  final GooglePlacesService _placesService = GooglePlacesService();
  final PlaceCacheService _cacheService = PlaceCacheService();
  final String? restrictToCountry;
  final String searchTypes;

  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;

  GooglePlaceSearchDelegate({
    this.restrictToCountry,
    this.searchTypes = '(cities)', // Default to cities
  }) : super(
          searchFieldLabel: 'Search destination...',
          searchFieldStyle: const TextStyle(fontSize: 16),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.neutral700),
        titleTextStyle: TextStyle(
          color: AppTheme.neutral800,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: AppTheme.neutral400),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _predictions = [];
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return _buildEmptyState();
    }

    // Trigger search
    _searchPlaces();

    return _buildSearchResults(context);
  }

  void _searchPlaces() {
    _isLoading = true;

    _placesService.getAutocompleteDebounced(
      query: query,
      types: searchTypes,
      components: restrictToCountry != null ? 'country:$restrictToCountry' : null,
      onResults: (predictions) {
        _predictions = predictions;
        _isLoading = false;
      },
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isLoading && _predictions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_predictions.isEmpty && query.length >= 2) {
      return _buildNoResults();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _predictions.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppTheme.neutral100,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final prediction = _predictions[index];
        return _buildPredictionTile(context, prediction);
      },
    );
  }

  Widget _buildPredictionTile(BuildContext context, PlacePrediction prediction) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: () => _selectPlace(context, prediction),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            prediction.typeIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(
        prediction.mainText,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: prediction.secondaryText.isNotEmpty
          ? Text(
              prediction.secondaryText,
              style: TextStyle(
                color: AppTheme.neutral500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.north_east,
        size: 18,
        color: AppTheme.neutral400,
      ),
    );
  }

  Future<void> _selectPlace(BuildContext context, PlacePrediction prediction) async {
    HapticFeedback.selectionClick();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get full place details (with caching)
      final details = await _cacheService.getPlaceDetails(prediction.placeId);

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (details != null && context.mounted) {
        close(context, details);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load place details'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 64, color: AppTheme.neutral300),
              const SizedBox(height: 16),
              Text(
                'Search for a destination',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter at least 2 characters',
                style: TextStyle(fontSize: 14, color: AppTheme.neutral400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 64, color: AppTheme.neutral300),
              const SizedBox(height: 16),
              Text(
                'No destinations found',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(fontSize: 14, color: AppTheme.neutral400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _placesService.dispose();
    _cacheService.dispose();
    super.dispose();
  }
}
