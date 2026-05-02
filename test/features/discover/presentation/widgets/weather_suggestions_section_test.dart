import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/domain/entities/weather_suggestion.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/weather_suggestions_section.dart';

class _FakeDiscoverStateNotifier extends DiscoverStateNotifier {
  _FakeDiscoverStateNotifier(this._initialState);
  final DiscoverState _initialState;

  @override
  DiscoverState build() => _initialState;
}

DiscoverPlace makePlace({
  required String id,
  String name = 'Test Place',
  PlaceCategory category = PlaceCategory.heritage,
  double rating = 4.5,
  int userRatingsTotal = 200,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      types: const ['point_of_interest'],
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      photos: const [],
      category: category,
    );

void main() {
  Widget buildScope({
    required DiscoverState state,
    WeatherData? weather,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        discoverStateProvider
            .overrideWith(() => _FakeDiscoverStateNotifier(state)),
        locationWeatherProvider.overrideWith((ref) async => weather),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('WeatherSuggestionsSection', () {
    testWidgets('renders nothing when discoverState has no places',
        (tester) async {
      await tester.pumpWidget(buildScope(
        state: const DiscoverState(),
        weather: WeatherData.mock(
          temperature: 28,
          condition: WeatherCondition.sunny,
        ),
        child: WeatherSuggestionsSection(
          onPlaceTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Perfect for Today'), findsNothing);
    });

    testWidgets('renders nothing when weather is null', (tester) async {
      final state = DiscoverState(
        places: [makePlace(id: '1')],
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        weather: null,
        child: WeatherSuggestionsSection(
          onPlaceTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Perfect for Today'), findsNothing);
    });

    testWidgets('renders nothing when state is loading', (tester) async {
      final state = DiscoverState(
        isLoading: true,
        places: [makePlace(id: '1')],
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        weather: WeatherData.mock(
          temperature: 28,
          condition: WeatherCondition.sunny,
        ),
        child: WeatherSuggestionsSection(
          onPlaceTapped: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Perfect for Today'), findsNothing);
    });

    testWidgets(
        'renders weather header with temperature and "Perfect for Today" when populated',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = DiscoverState(
        places: [
          makePlace(id: 'h1', category: PlaceCategory.heritage, rating: 4.7),
          makePlace(id: 'h2', category: PlaceCategory.nature, rating: 4.6),
        ],
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        weather: WeatherData.mock(
          temperature: 28,
          condition: WeatherCondition.sunny,
        ),
        child: WeatherSuggestionsSection(
          onPlaceTapped: (_) {},
        ),
      ));
      // Allow FutureProvider to resolve
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Perfect for Today'), findsOneWidget);
      // Temperature display: "28°C" (mock helper rounds via .round())
      expect(find.text('28°C'), findsOneWidget);
      // Sunny weather summary text appears (truncated with ellipsis allowed)
      expect(
        find.textContaining("sunny day", findRichText: false),
        findsOneWidget,
      );
    });

    testWidgets('renders place card name when populated and matching category',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final state = DiscoverState(
        places: [
          makePlace(
            id: 'h1',
            name: 'Heritage Castle',
            category: PlaceCategory.heritage,
            rating: 4.7,
          ),
        ],
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        weather: WeatherData.mock(
          temperature: 22,
          condition: WeatherCondition.rainy,
        ),
        child: WeatherSuggestionsSection(
          onPlaceTapped: (_) {},
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Heritage is in suggested categories for rainy weather
      expect(find.text('Heritage Castle'), findsOneWidget);
      // Indoor badge for rainy + heritage
      expect(find.text('Indoor'), findsOneWidget);
    });

    testWidgets(
        'invokes onPlaceTapped when a weather suggestion card is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      DiscoverPlace? tapped;

      final place = makePlace(
        id: 'h1',
        name: 'Tappable Place',
        category: PlaceCategory.heritage,
        rating: 4.6,
      );

      final state = DiscoverState(
        places: [place],
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        weather: WeatherData.mock(
          temperature: 24,
          condition: WeatherCondition.rainy,
        ),
        child: WeatherSuggestionsSection(
          onPlaceTapped: (p) => tapped = p,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Tappable Place'));
      await tester.pump();

      expect(tapped, isNotNull);
      expect(tapped!.placeId, 'h1');
    });
  });
}
