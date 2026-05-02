import 'package:flutter_test/flutter_test.dart';

/// These widgets call into platform / network / Supabase services in their
/// initState or first build, which is impractical to test without heavy
/// mocking. They are listed here so the rationale is recorded next to the
/// rest of the core/widgets test suite.
void main() {
  group('Skipped (require live services / platform channels)', () {
    test(
      'DestinationAutocomplete (lib/core/widgets/destination_autocomplete.dart)',
      () {},
      skip:
          'Calls GooglePlacesService + PlaceCacheService (network + cache). '
          'Needs HTTP / SharedPreferences mocks to test rendering.',
    );

    test(
      'GooglePlaceSearchDelegate (lib/core/widgets/google_place_search_delegate.dart)',
      () {},
      skip:
          'SearchDelegate that drives GooglePlacesService for live autocomplete.',
    );

    test(
      'PlaceSearchDelegate (lib/core/widgets/place_search_delegate.dart)',
      () {},
      skip:
          'SearchDelegate that drives PlaceSearchService (Nominatim/OSM). '
          'Initial empty state is renderable but full coverage requires '
          'network mocks.',
    );

    test(
      'VoiceInputBottomSheet (lib/core/widgets/voice_input_bottom_sheet.dart)',
      () {},
      skip:
          'Initialises VoiceInputService in initState, which uses the '
          'speech_to_text plugin (microphone platform channel).',
    );
  });
}
