import 'package:flutter/material.dart';
import '../services/place_search_service.dart';
import '../theme/app_theme.dart';

/// Search delegate for place/location autocomplete
///
/// Uses OpenStreetMap Nominatim API to search for cities, towns,
/// countries, and other travel destinations.
class PlaceSearchDelegate extends SearchDelegate<Place?> {
  final PlaceSearchService _searchService;
  List<Place> _suggestions = [];
  bool _isLoading = false;

  PlaceSearchDelegate({PlaceSearchService? searchService})
      : _searchService = searchService ?? PlaceSearchService(),
        super(
          searchFieldLabel: 'Search city, town, or country...',
          searchFieldStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _suggestions = [];
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
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
      return _buildEmptyState(context);
    }

    // Trigger debounced search
    _searchService.searchPlacesDebounced(query, (places) {
      _suggestions = places;
      _isLoading = false;
      // Rebuild suggestions
      if (context.mounted) {
        showSuggestions(context);
      }
    });

    _isLoading = true;

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (_isLoading && _suggestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_suggestions.isEmpty && query.length >= 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.neutral400,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'No places found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.neutral600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Try a different search term',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neutral500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final place = _suggestions[index];
        return _buildPlaceListTile(context, place);
      },
    );
  }

  Widget _buildPlaceListTile(BuildContext context, Place place) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Center(
          child: Text(
            place.typeIcon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        place.name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _getSubtitle(place),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.neutral600,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.north_west,
        size: 16,
        color: AppTheme.neutral400,
      ),
      onTap: () => close(context, place),
    );
  }

  String _getSubtitle(Place place) {
    final parts = <String>[];
    if (place.city != null && place.city != place.name) {
      parts.add(place.city!);
    }
    if (place.state != null && place.state != place.name && place.state != place.city) {
      parts.add(place.state!);
    }
    if (place.country != null) {
      parts.add(place.country!);
    }
    return parts.join(', ');
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Search for a destination',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Enter a city, town, or country name',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            // Popular destinations
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(context, '🗼 Paris'),
                _buildSuggestionChip(context, '🗽 New York'),
                _buildSuggestionChip(context, '🗾 Tokyo'),
                _buildSuggestionChip(context, '🏝️ Bali'),
                _buildSuggestionChip(context, '🌴 Dubai'),
                _buildSuggestionChip(context, '🏔️ Switzerland'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    // Remove emoji for search query
    final searchText = text.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    return ActionChip(
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 13,
      ),
      side: BorderSide.none,
      onPressed: () {
        query = searchText;
        showResults(context);
      },
    );
  }

  @override
  void dispose() {
    _searchService.dispose();
    super.dispose();
  }
}
