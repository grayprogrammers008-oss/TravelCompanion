import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/discover/presentation/widgets/discover_header.dart';

class _FakeDiscoverStateNotifier extends DiscoverStateNotifier {
  _FakeDiscoverStateNotifier(this._initialState);
  final DiscoverState _initialState;

  @override
  DiscoverState build() => _initialState;
}

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

  group('DiscoverHeader', () {
    testWidgets('shows "Getting location..." when isGettingLocation is true',
        (tester) async {
      const state = DiscoverState(isGettingLocation: true);

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Getting location...'), findsOneWidget);
      // Loading uses the location_searching icon
      expect(find.byIcon(Icons.location_searching), findsOneWidget);
    });

    testWidgets(
        'shows "Current Location" placeholder when no location name & not loading',
        (tester) async {
      const state = DiscoverState();

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Near You'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('renders provided locationName when available', (tester) async {
      const state = DiscoverState(
        locationName: 'Bengaluru',
        userLatitude: 12.97,
        userLongitude: 77.59,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Bengaluru'), findsOneWidget);
      expect(find.text('Near You'), findsOneWidget);
    });

    testWidgets('shows "Exploring" label and globe icon when a country is selected',
        (tester) async {
      const state = DiscoverState(
        selectedCountry: 'India',
        locationName: 'Goa, India',
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Exploring'), findsOneWidget);
      expect(find.text('Goa, India'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('hides distance indicator when a country is selected',
        (tester) async {
      const state = DiscoverState(
        selectedCountry: 'Thailand',
        locationName: 'Bangkok',
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      // Distance indicator shows the kilometer number; it should not appear
      // when a country is selected.
      expect(find.text('${DiscoverDistance.nearby.kilometers}'), findsNothing);
      expect(find.text('km'), findsNothing);
    });

    testWidgets('shows distance indicator when no country is selected',
        (tester) async {
      const state = DiscoverState(
        userLatitude: 12.97,
        userLongitude: 77.59,
        selectedDistance: DiscoverDistance.nearby,
      );

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('${DiscoverDistance.nearby.kilometers}'), findsOneWidget);
      expect(find.text('km'), findsOneWidget);
    });

    testWidgets('invokes onSearchTap when search icon is tapped',
        (tester) async {
      var searchTaps = 0;
      const state = DiscoverState();

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () => searchTaps++,
          onLocationTap: () {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      expect(searchTaps, 1);
    });

    testWidgets('invokes onLocationTap when location pill is tapped',
        (tester) async {
      var locationTaps = 0;
      const state = DiscoverState(locationName: 'Test City');

      await tester.pumpWidget(buildScope(
        state: state,
        child: DiscoverHeader(
          onSearchTap: () {},
          onLocationTap: () => locationTaps++,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Test City'));
      await tester.pump();
      expect(locationTaps, 1);
    });
  });
}
