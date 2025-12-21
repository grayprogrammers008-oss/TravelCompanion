import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_places_service.dart';
import '../services/place_cache_service.dart';

/// Provider for Google Places Service
final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  final service = GooglePlacesService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for Place Cache Service
final placeCacheServiceProvider = Provider<PlaceCacheService>((ref) {
  final service = PlaceCacheService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State class for autocomplete results
class AutocompleteState {
  final List<PlacePrediction> predictions;
  final bool isLoading;
  final String? error;

  const AutocompleteState({
    this.predictions = const [],
    this.isLoading = false,
    this.error,
  });

  AutocompleteState copyWith({
    List<PlacePrediction>? predictions,
    bool? isLoading,
    String? error,
  }) {
    return AutocompleteState(
      predictions: predictions ?? this.predictions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for autocomplete search using Riverpod 2.0 pattern
class AutocompleteNotifier extends Notifier<AutocompleteState> {
  @override
  AutocompleteState build() {
    return const AutocompleteState();
  }

  void search(String query, {String? types, String? components}) {
    if (query.isEmpty) {
      state = const AutocompleteState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final placesService = ref.read(googlePlacesServiceProvider);
    placesService.getAutocompleteDebounced(
      query: query,
      types: types,
      components: components,
      onResults: (predictions) {
        state = AutocompleteState(predictions: predictions, isLoading: false);
      },
    );
  }

  void clear() {
    state = const AutocompleteState();
  }
}

/// Provider for autocomplete state
final autocompleteProvider =
    NotifierProvider<AutocompleteNotifier, AutocompleteState>(() {
  return AutocompleteNotifier();
});

/// Provider to get place details (with caching)
final placeDetailsProvider =
    FutureProvider.family.autoDispose<PlaceDetails?, String>((ref, placeId) async {
  final cacheService = ref.watch(placeCacheServiceProvider);
  return cacheService.getPlaceDetails(placeId);
});
