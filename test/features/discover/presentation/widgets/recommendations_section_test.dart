import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/recommendations_section.dart';

/// A fake DiscoverStateNotifier that returns a predetermined state in build().
class _FakeDiscoverStateNotifier extends DiscoverStateNotifier {
  _FakeDiscoverStateNotifier(this._initialState);
  final DiscoverState _initialState;

  @override
  DiscoverState build() => _initialState;
}

DiscoverPlace _place({
  required String id,
  String name = 'Place',
  PlaceCategory category = PlaceCategory.heritage,
  double rating = 4.5,
  int userRatingsTotal = 200,
  double? lat = 12.97,
  double? lng = 77.59,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      latitude: lat,
      longitude: lng,
      types: const ['point_of_interest'],
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      photos: const [],
      category: category,
    );

void main() {
  Widget buildScope({
    required DiscoverState state,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        discoverStateProvider
            .overrideWith(() => _FakeDiscoverStateNotifier(state)),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('RecommendationsSection', () {
    testWidgets('renders nothing when state has no places', (tester) async {
      await tester.pumpWidget(buildScope(
        state: const DiscoverState(),
        child: RecommendationsSection(onPlaceTapped: (_) {}),
      ));
      await tester.pump();

      expect(find.text('For You'), findsNothing);
      expect(find.text('Personalized recommendations'), findsNothing);
    });

    testWidgets('renders nothing while loading even if places exist',
        (tester) async {
      final state = DiscoverState(
        places: [_place(id: '1')],
        isLoading: true,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: RecommendationsSection(onPlaceTapped: (_) {}),
      ));
      await tester.pump();

      expect(find.text('For You'), findsNothing);
    });

    testWidgets(
        'renders "For You" header when state has places that produce non-empty groups',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Use places with high rating + many reviews so the "Trending" group gets populated
      final places = [
        _place(id: '1', name: 'Trending One', rating: 4.6, userRatingsTotal: 500),
        _place(id: '2', name: 'Trending Two', rating: 4.8, userRatingsTotal: 800),
        _place(id: '3', name: 'Trending Three', rating: 4.5, userRatingsTotal: 300),
      ];

      final state = DiscoverState(
        places: places,
        userLatitude: 12.9716,
        userLongitude: 77.5946,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: RecommendationsSection(onPlaceTapped: (_) {}),
      ));
      await tester.pump();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Personalized recommendations'), findsOneWidget);
    });

    testWidgets(
        'renders nothing when places are loaded but no recommendation groups match',
        (tester) async {
      // Single place far from user, low rating, no reviews — none of the
      // recommendation strategies will pick it up.
      final places = [
        _place(
          id: 'low',
          rating: 2.0,
          userRatingsTotal: 0,
          lat: 0,
          lng: 0,
        ),
      ];

      final state = DiscoverState(
        places: places,
        userLatitude: 50.0, // very far from (0,0)
        userLongitude: 50.0,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: RecommendationsSection(onPlaceTapped: (_) {}),
      ));
      await tester.pump();

      expect(find.text('For You'), findsNothing);
    });
  });
}
