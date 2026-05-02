import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/smart_suggestions_section.dart';

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
  int userRatingsTotal = 500,
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

  group('SmartSuggestionsSection', () {
    testWidgets('renders nothing when state has no places', (tester) async {
      await tester.pumpWidget(buildScope(
        state: const DiscoverState(),
        child: SmartSuggestionsSection(
          onPlaceTapped: (_) {},
          onQuickAdd: (_) {},
          onCategoryTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('For You'), findsNothing);
    });

    testWidgets('renders nothing when places exist but hasLocation is false',
        (tester) async {
      final state = DiscoverState(
        places: [_place(id: '1')],
        // No userLatitude/userLongitude => hasLocation = false
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: SmartSuggestionsSection(
          onPlaceTapped: (_) {},
          onQuickAdd: (_) {},
          onCategoryTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('For You'), findsNothing);
    });

    testWidgets('renders "For You" header and time-based banner when populated',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = DiscoverState(
        places: [
          _place(id: '1', name: 'Alpha', rating: 4.7, userRatingsTotal: 200),
          _place(id: '2', name: 'Beta', rating: 4.8, userRatingsTotal: 800),
        ],
        userLatitude: 12.9716,
        userLongitude: 77.5946,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: SmartSuggestionsSection(
          onPlaceTapped: (_) {},
          onQuickAdd: (_) {},
          onCategoryTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Smart suggestions just for you'), findsOneWidget);
      // Popular Nearby section header
      expect(find.text('Popular Nearby'), findsOneWidget);
      expect(find.text('Highly rated places close to you'), findsOneWidget);
    });

    testWidgets('renders Trending section when places have many reviews',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = DiscoverState(
        places: [
          _place(id: 't1', rating: 4.6, userRatingsTotal: 500),
          _place(id: 't2', rating: 4.7, userRatingsTotal: 700),
        ],
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: SmartSuggestionsSection(
          onPlaceTapped: (_) {},
          onQuickAdd: (_) {},
          onCategoryTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Most visited this week'), findsOneWidget);
    });

    testWidgets(
        'does not render "Similar to Your Favorites" when there are no favorites',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = DiscoverState(
        places: [_place(id: '1', rating: 4.5, userRatingsTotal: 200)],
        favoriteIds: const {},
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: SmartSuggestionsSection(
          onPlaceTapped: (_) {},
          onQuickAdd: (_) {},
          onCategoryTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Similar to Your Favorites'), findsNothing);
    });
  });
}
