import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_crew/core/presentation/main_scaffold.dart';

/// Widget tests for [MainScaffold] and its bottom-nav routing.
///
/// We don't render the production Shell wrappers (`TripsShell`,
/// `ExploreShell`, etc.) because those instantiate full feature pages
/// pulling in every Riverpod dependency. We test only the scaffold
/// itself with a stub child, which is what the shells share.

void main() {
  Widget app({
    int currentIndex = 0,
    GoRouter? router,
  }) {
    return MaterialApp.router(
      routerConfig: router ??
          GoRouter(
            initialLocation: '/start',
            routes: [
              GoRoute(
                path: '/start',
                builder: (context, state) => MainScaffold(
                  currentIndex: currentIndex,
                  child: const Center(child: Text('CHILD')),
                ),
              ),
              GoRoute(
                path: '/trips',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('TRIPS'))),
              ),
              GoRoute(
                path: '/explore',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('EXPLORE'))),
              ),
              GoRoute(
                path: '/discover',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('DISCOVER'))),
              ),
            ],
          ),
    );
  }

  group('MainScaffold — render', () {
    testWidgets('renders the supplied child widget', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.text('CHILD'), findsOneWidget);
    });

    testWidgets('renders 3 BottomNavigationBarItems with the expected labels',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
    });

    testWidgets('renders the outlined icon for non-active tabs', (tester) async {
      await tester.pumpWidget(app(currentIndex: 0));
      await tester.pump();
      // Trips active → luggage filled visible. Explore + Discover outlined.
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    });

    testWidgets('uses BottomNavigationBarType.fixed', (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.type, BottomNavigationBarType.fixed);
    });

    testWidgets('passes currentIndex through to BottomNavigationBar',
        (tester) async {
      await tester.pumpWidget(app(currentIndex: 2));
      await tester.pump();
      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 2);
    });
  });

  group('MainScaffold — onItemTapped routing', () {
    testWidgets('tapping My Trips navigates to /trips', (tester) async {
      await tester.pumpWidget(app(currentIndex: 1));
      await tester.pump();

      await tester.tap(find.text('My Trips'));
      await tester.pumpAndSettle();

      expect(find.text('TRIPS'), findsOneWidget);
    });

    testWidgets('tapping Explore navigates to /explore', (tester) async {
      await tester.pumpWidget(app(currentIndex: 0));
      await tester.pump();

      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      expect(find.text('EXPLORE'), findsOneWidget);
    });

    testWidgets('tapping Discover navigates to /discover', (tester) async {
      await tester.pumpWidget(app(currentIndex: 0));
      await tester.pump();

      await tester.tap(find.text('Discover'));
      await tester.pumpAndSettle();

      expect(find.text('DISCOVER'), findsOneWidget);
    });
  });
}
