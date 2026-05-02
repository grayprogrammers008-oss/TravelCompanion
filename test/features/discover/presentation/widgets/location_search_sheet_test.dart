import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/google_places_service.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/location_search_sheet.dart';

class _FakeGooglePlacesService extends GooglePlacesService {
  _FakeGooglePlacesService();

  /// Map of (lower-cased) query => predictions to return.
  final Map<String, List<PlacePrediction>> autocompleteResponses = {};

  /// Map of placeId => details to return from getPlaceDetails.
  final Map<String, PlaceDetails?> detailsResponses = {};

  @override
  void getAutocompleteDebounced({
    required String query,
    required void Function(List<PlacePrediction> predictions) onResults,
    String? types,
    String? components,
    String? sessionToken,
  }) {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) {
      onResults([]);
      return;
    }
    final predictions = autocompleteResponses[key] ?? [];
    // Invoke synchronously so the test sees the result on the next pump.
    onResults(predictions);
  }

  @override
  Future<PlaceDetails?> getPlaceDetails({
    required String placeId,
    String? sessionToken,
    List<String>? fields,
  }) async {
    return detailsResponses[placeId];
  }
}

PlacePrediction makePrediction({
  String placeId = 'pred-1',
  String mainText = 'Paris',
  String secondaryText = 'France',
  List<String> types = const ['locality'],
}) =>
    PlacePrediction(
      placeId: placeId,
      description: '$mainText, $secondaryText',
      mainText: mainText,
      secondaryText: secondaryText,
      types: types,
    );

void main() {
  Widget buildScope({
    required _FakeGooglePlacesService fake,
  }) {
    return ProviderScope(
      overrides: [
        googlePlacesServiceProvider.overrideWithValue(fake),
      ],
      child: const MaterialApp(
        home: Scaffold(body: LocationSearchSheet()),
      ),
    );
  }

  group('LocationSearchSheet', () {
    testWidgets('renders title, search field, and Use Current Location tile',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fake = _FakeGooglePlacesService();
      await tester.pumpWidget(buildScope(fake: fake));
      await tester.pump();

      expect(find.text('Search Location'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Use Current Location'), findsOneWidget);
      expect(find.text('Popular Destinations'), findsOneWidget);
    });

    testWidgets('lists popular quick-access locations when query is empty',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fake = _FakeGooglePlacesService();
      await tester.pumpWidget(buildScope(fake: fake));
      await tester.pump();

      // The widget hardcodes a list of popular destinations including
      // "Paris, France" and "Tokyo, Japan".
      expect(find.text('Paris, France'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
    });

    testWidgets('renders search results when service returns predictions',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fake = _FakeGooglePlacesService();
      fake.autocompleteResponses['paris'] = [
        makePrediction(
          placeId: 'paris-id',
          mainText: 'Paris',
          secondaryText: 'Île-de-France, France',
        ),
        makePrediction(
          placeId: 'paris-tx-id',
          mainText: 'Paris',
          secondaryText: 'Texas, USA',
        ),
      ];

      await tester.pumpWidget(buildScope(fake: fake));
      await tester.pump();

      // Type "paris" into the search field
      await tester.enterText(find.byType(TextField), 'paris');
      await tester.pump();

      // Search Results header appears
      expect(find.text('Search Results'), findsOneWidget);
      // Both predictions should be visible (mainText shown as title)
      expect(find.text('Île-de-France, France'), findsOneWidget);
      expect(find.text('Texas, USA'), findsOneWidget);
      // 'Paris' main text appears for both predictions
      expect(find.text('Paris'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when query yields no predictions',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fake = _FakeGooglePlacesService();
      // No entries => returns empty list
      await tester.pumpWidget(buildScope(fake: fake));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzznotaplace');
      await tester.pump();

      expect(find.text('No locations found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets(
        'clear button resets predictions and re-shows quick destinations',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fake = _FakeGooglePlacesService();
      fake.autocompleteResponses['paris'] = [
        makePrediction(
          placeId: 'paris-id',
          mainText: 'Paris',
          secondaryText: 'France',
        ),
      ];

      await tester.pumpWidget(buildScope(fake: fake));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'paris');
      await tester.pump();

      expect(find.text('Search Results'), findsOneWidget);
      // Clear icon should be visible now
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Search results gone, popular destinations re-appear
      expect(find.text('Search Results'), findsNothing);
      expect(find.text('Popular Destinations'), findsOneWidget);
      expect(find.text('Paris, France'), findsOneWidget);
    });
  });
}
