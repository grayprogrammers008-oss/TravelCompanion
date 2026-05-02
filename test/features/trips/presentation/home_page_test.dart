import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/easy_mode_provider.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/trips/presentation/pages/home_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/trips/presentation/providers/ai_suggestions_provider.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/itinerary/presentation/providers/itinerary_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

final _defaultTheme = AppThemeData.getThemeData(AppThemeType.ocean);

/// Builds a test app wrapping [HomePage] with all required providers and the
/// mandatory [AppThemeProvider] InheritedWidget.
Widget _buildTestApp({
  List<TripWithMembers> trips = const [],
  bool tripsLoading = false,
  bool tripsError = false,
}) {
  return ProviderScope(
    overrides: [
      userTripsProvider.overrideWith((ref) {
        if (tripsError) return Future.error(Exception('Network failure'));
        if (tripsLoading) {
          // Completer that never resolves — no pending Timer, just a hanging Future.
          return Completer<List<TripWithMembers>>().future;
        }
        return Future.value(trips);
      }),
      theme_provider.currentThemeDataProvider
          .overrideWith((_) => _defaultTheme),
      easyModeConfigProvider.overrideWith((_) => const EasyModeConfig()),
      currentUserProvider.overrideWith((ref) async => null),
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      aiSuggestionsProvider.overrideWith((ref) async => null),
      discoverStateProvider.overrideWith(() => DiscoverStateNotifier()),
      tripItineraryProvider.overrideWith((ref, _) => Stream.value(const [])),
    ],
    child: AppThemeProvider(
      themeData: _defaultTheme,
      child: const MaterialApp(
        home: HomePage(),
      ),
    ),
  );
}

TripWithMembers _makeTrip({
  required String id,
  required String name,
  String destination = 'Bali, Indonesia',
  DateTime? startDate,
  DateTime? endDate,
  int memberCount = 1,
  bool isCompleted = false,
  double? cost,
  bool isFavorite = false,
  String createdBy = 'user-1',
}) {
  final now = DateTime.now();
  final members = List.generate(
    memberCount,
    (i) => TripMemberModel(
      id: 'mem-$id-$i',
      tripId: id,
      userId: i == 0 ? createdBy : 'user-other-$i',
      role: i == 0 ? 'admin' : 'member',
      joinedAt: now,
      fullName: 'Member $i',
      email: 'member$i@test.com',
    ),
  );
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      isCompleted: isCompleted,
      cost: cost,
      // Provide a dummy URL so DestinationImage skips its async
      // SharedPreferences / Places-API fetch and avoids pending timers.
      coverImageUrl: 'https://test.invalid/img.jpg',
    ),
    members: members,
    isFavorite: isFavorite,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

/// Pumps enough to resolve immediate futures and rebuild the widget tree, but
/// does NOT call pumpAndSettle — which hangs because DestinationImage starts
/// a disk-cache/network fetch that never completes in tests.
Future<void> _pumpTripsLoaded(WidgetTester tester) async {
  await tester.pump(); // flush microtasks → FutureProvider resolves
  await tester.pump(); // rebuild widget tree with trip data
  // Advance fake time so 0ms Future.delayed timers (FadeSlideAnimation,
  // ScaleAnimation) fire, then let those animations fully complete.
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 600));
}

/// Taps the status-filter chip with [label] (e.g. 'Active', 'Upcoming',
/// 'Completed') to switch the list to flat-list mode, then advances fake time
/// so that all FadeSlideAnimation stagger timers fire and complete.
///
/// Uses an ancestor GestureDetector finder to avoid matching the stats-header
/// text widgets that also show the same labels (e.g. 'Active', 'Upcoming').
Future<void> _tapFilter(WidgetTester tester, String label) async {
  final chipFinder = find
      .ancestor(
        of: find.text(label),
        matching: find.byType(GestureDetector),
      )
      .first;
  await tester.ensureVisible(chipFinder);
  await tester.pump();
  await tester.tap(chipFinder);
  await tester.pump(); // setState → switches to flat list
  // Drain 0ms Future.delayed timers from newly-mounted FadeSlideAnimation
  // widgets, then let all stagger animations (100ms * index) complete.
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('HomePage Widget Tests', () {
    // ── Empty state ───────────────────────────────────────────────────────────

    group('Empty State', () {
      testWidgets('shows "No trips yet" when trip list is empty',
          (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('No trips yet'), findsOneWidget);
      });

      testWidgets('shows "Plan a Trip" CTA button in empty state',
          (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Plan a Trip'), findsOneWidget);
      });

      testWidgets('shows luggage icon in empty state', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.luggage_outlined), findsOneWidget);
      });

      testWidgets('does not show edit or delete buttons in empty state',
          (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('shows subtitle text with AI prompt in empty state',
          (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.textContaining('AI'), findsWidgets);
      });
    });

    // ── Loading state ─────────────────────────────────────────────────────────

    group('Loading State', () {
      /// Pumps the loading state enough to drain 0ms Future.delayed timers
      /// (e.g. ScaleAnimation on the FAB) without resolving the FutureProvider.
      Future<void> pumpLoading(WidgetTester tester) async {
        await tester.pump(); // first frame
        await tester.pump(const Duration(milliseconds: 1)); // fire 0ms timers
        await tester.pump(const Duration(milliseconds: 600)); // complete animations
      }

      testWidgets('shows packing animation text while loading',
          (tester) async {
        await tester.pumpWidget(_buildTestApp(tripsLoading: true));
        await pumpLoading(tester);

        expect(find.text('Packing your trips...'), findsOneWidget);
      });

      testWidgets('hides trip cards while loading', (tester) async {
        await tester.pumpWidget(_buildTestApp(tripsLoading: true));
        await pumpLoading(tester);

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('loading state does not show empty-state message',
          (tester) async {
        await tester.pumpWidget(_buildTestApp(tripsLoading: true));
        await pumpLoading(tester);

        expect(find.text('No trips yet'), findsNothing);
      });
    });

    // ── Trip card display ─────────────────────────────────────────────────────

    group('Trip Card Display', () {
      testWidgets('renders trip name', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(trips: [_makeTrip(id: 't1', name: 'Goa Beach Escape')]),
        );
        await _pumpTripsLoaded(tester);

        expect(find.text('Goa Beach Escape'), findsWidgets);
      });

      testWidgets('renders trip destination', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Trip', destination: 'Goa, India'),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        expect(find.text('Goa, India'), findsWidgets);
      });

      testWidgets('renders all trip names when multiple trips exist',
          (tester) async {
        final now = DateTime.now();
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Trip One'), // active (no dates)
              _makeTrip(
                id: 't2',
                name: 'Trip Two',
                startDate: now.add(const Duration(days: 5)),
                endDate: now.add(const Duration(days: 10)),
              ), // upcoming → compact row shows name
              _makeTrip(
                id: 't3',
                name: 'Trip Three',
                startDate: now.add(const Duration(days: 15)),
                endDate: now.add(const Duration(days: 20)),
              ), // upcoming → compact row shows name
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        // Grouped view: Trip One in "Happening Now", Trip Two/Three in "Coming Up" rows
        expect(find.text('Trip One'), findsWidgets);
        expect(find.text('Trip Two'), findsWidgets);
        expect(find.text('Trip Three'), findsWidgets);
      });

      testWidgets('shows cost chip with payment icon when cost is set',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [_makeTrip(id: 't1', name: 'Luxury', cost: 50000)],
          ),
        );
        await _pumpTripsLoaded(tester);
        // Switch to flat list so TripCard (with cost chip) is rendered
        await _tapFilter(tester, 'Active');

        expect(find.byIcon(Icons.payments_outlined), findsWidgets);
      });

      testWidgets('does not show cost chip when trip has no cost',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [_makeTrip(id: 't1', name: 'Free Trip', cost: null)],
          ),
        );
        await _pumpTripsLoaded(tester);

        expect(find.byIcon(Icons.payments_outlined), findsNothing);
      });
    });

    // ── Edit & Delete buttons ─────────────────────────────────────────────────

    group('Edit and Delete Buttons', () {
      testWidgets('edit button is visible on trip card', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(trips: [_makeTrip(id: 't1', name: 'My Trip')]),
        );
        await _pumpTripsLoaded(tester);
        // Tap 'Active' to switch to flat list (TripCard has edit/delete buttons)
        await _tapFilter(tester, 'Active');

        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
      });

      testWidgets('delete button is visible on trip card', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(trips: [_makeTrip(id: 't1', name: 'My Trip')]),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Active');

        expect(find.byIcon(Icons.delete_outline), findsWidgets);
      });

      testWidgets('both edit and delete buttons exist in flat list view',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [_makeTrip(id: 't1', name: 'Trip A')],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Active');

        expect(find.byIcon(Icons.edit_outlined), findsWidgets);
        expect(find.byIcon(Icons.delete_outline), findsWidgets);
      });
    });

    // ── Days-left status badge ────────────────────────────────────────────────

    // Status badges ('X days left', 'Starts tomorrow', 'Ended', etc.) are
    // shown inside TripCard, which is only rendered in flat-list mode.
    // Each test switches to the correct filter so TripCard is rendered.
    group('Days-Left Status Badge', () {
      testWidgets('shows "X days left" for trip starting in 5 days',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(
                id: 't1',
                name: 'Trek',
                startDate: DateTime.now().add(const Duration(days: 5)),
                endDate: DateTime.now().add(const Duration(days: 10)),
              ),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Upcoming');

        expect(find.textContaining('days left'), findsWidgets);
      });

      testWidgets('shows "X days to go!" for trip starting in 2 days',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(
                id: 't1',
                name: 'Goa',
                startDate: DateTime.now().add(const Duration(days: 2)),
                endDate: DateTime.now().add(const Duration(days: 7)),
              ),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Upcoming');

        expect(find.textContaining('days to go'), findsWidgets);
      });

      testWidgets('shows "Starts tomorrow" for trip starting in 1 day',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(
                id: 't1',
                name: 'Quick Trip',
                startDate: DateTime.now().add(const Duration(days: 1)),
                endDate: DateTime.now().add(const Duration(days: 5)),
              ),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Upcoming');

        expect(find.textContaining('tomorrow'), findsWidgets);
      });

      testWidgets('shows "In X days" for trip starting more than 7 days away',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(
                id: 't1',
                name: 'Far Trip',
                startDate: DateTime.now().add(const Duration(days: 30)),
                endDate: DateTime.now().add(const Duration(days: 37)),
              ),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Upcoming');

        expect(find.textContaining('In '), findsWidgets);
      });

      testWidgets('shows "Completed" label for completed trips', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(
                id: 't1',
                name: 'Done Trip',
                startDate: DateTime.now().subtract(const Duration(days: 10)),
                endDate: DateTime.now().subtract(const Duration(days: 5)),
                isCompleted: true,
              ),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Completed');

        expect(find.textContaining('Completed'), findsWidgets);
      });

      testWidgets('shows "Ended" for trip whose end date has passed',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(
                id: 't1',
                name: 'Past Trip',
                startDate: DateTime.now().subtract(const Duration(days: 10)),
                endDate: DateTime.now().subtract(const Duration(days: 3)),
              ),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);
        await _tapFilter(tester, 'Completed');

        expect(find.textContaining('Ended'), findsWidgets);
      });
    });

    // ── Member count display ──────────────────────────────────────────────────

    group('Member Count Display', () {
      testWidgets('shows member count number for a trip', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [_makeTrip(id: 't1', name: 'Solo', memberCount: 1)],
          ),
        );
        await _pumpTripsLoaded(tester);

        // Compact badge shows the count as a number
        expect(find.text('1'), findsWidgets);
      });

      testWidgets('shows people icon alongside member count', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [_makeTrip(id: 't1', name: 'Group', memberCount: 4)],
          ),
        );
        await _pumpTripsLoaded(tester);

        expect(find.byIcon(Icons.people), findsWidgets);
      });

      testWidgets('shows correct count for large group', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [_makeTrip(id: 't1', name: 'Big Group', memberCount: 8)],
          ),
        );
        await _pumpTripsLoaded(tester);
        // TripCard (flat list) shows numeric count via formatCount()
        await _tapFilter(tester, 'Active');

        expect(find.text('8'), findsWidgets);
      });
    });

    // ── Search bar ────────────────────────────────────────────────────────────

    // Search bar only appears when trips.length > 3.
    group('Search Bar', () {
      testWidgets('search TextField is present when more than 3 trips exist',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Beach Trip'),
              _makeTrip(id: 't2', name: 'Mountain Trek'),
              _makeTrip(id: 't3', name: 'City Tour'),
              _makeTrip(id: 't4', name: 'Safari Adventure'),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('typing in search keeps matching trips visible',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Goa Beach'),
              _makeTrip(id: 't2', name: 'Manali Trek'),
              _makeTrip(id: 't3', name: 'Kerala Tour'),
              _makeTrip(id: 't4', name: 'Rajasthan Drive'),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        await tester.enterText(find.byType(TextField).first, 'Goa');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.textContaining('Goa'), findsWidgets);
      });

      testWidgets('unmatched search shows search_off icon', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Goa Beach'),
              _makeTrip(id: 't2', name: 'Manali Trek'),
              _makeTrip(id: 't3', name: 'Kerala Tour'),
              _makeTrip(id: 't4', name: 'Rajasthan Drive'),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        await tester.enterText(
            find.byType(TextField).first, 'xyznotfound999');
        await tester.pump();

        expect(find.byIcon(Icons.search_off), findsOneWidget);
      });

      testWidgets('clearing search restores grouped view', (tester) async {
        final now = DateTime.now();
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Goa Beach'), // active
              _makeTrip(
                id: 't2',
                name: 'Manali Trek',
                startDate: now.add(const Duration(days: 5)),
                endDate: now.add(const Duration(days: 10)),
              ), // upcoming → shown in compact row by name
              _makeTrip(id: 't3', name: 'Kerala Tour'),
              _makeTrip(id: 't4', name: 'Rajasthan Drive'),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        await tester.enterText(find.byType(TextField).first, 'Goa');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Clear the search by entering empty text — more reliable than tapping
        // the suffixIcon button, which can be obscured by a collapsed FlexibleSpaceBar.
        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Grouped view is restored: the HAPPENING NOW and COMING UP section
        // headers should be present in the tree (they live in SliverToBoxAdapter
        // so they are always built, regardless of scroll position).
        expect(find.text('HAPPENING NOW', skipOffstage: false), findsWidgets);
        expect(find.text('COMING UP', skipOffstage: false), findsWidgets);
      });
    });

    // ── Favorite toggle ───────────────────────────────────────────────────────

    group('Favorite Toggle', () {
      testWidgets('unfavorited trip shows heart_border icon', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Trip', isFavorite: false),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        expect(find.byIcon(Icons.favorite_border), findsWidgets);
      });

      testWidgets('favorited trip shows filled heart icon', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            trips: [
              _makeTrip(id: 't1', name: 'Trip', isFavorite: true),
            ],
          ),
        );
        await _pumpTripsLoaded(tester);

        expect(find.byIcon(Icons.favorite), findsWidgets);
      });
    });

    // ── Pull-to-Refresh ───────────────────────────────────────────────────────

    group('Pull-to-Refresh', () {
      testWidgets('RefreshIndicator exists in the widget tree', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('CustomScrollView is wrapped by RefreshIndicator',
          (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        final refreshFinder = find.byType(RefreshIndicator);
        final scrollFinder = find.descendant(
          of: refreshFinder,
          matching: find.byType(CustomScrollView),
        );
        expect(scrollFinder, findsOneWidget);
      });
    });

    // ── Error state ───────────────────────────────────────────────────────────

    group('Error State', () {
      testWidgets('shows error icon when provider throws an error',
          (tester) async {
        await tester.pumpWidget(_buildTestApp(tripsError: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('does not show trip cards in error state', (tester) async {
        await tester.pumpWidget(_buildTestApp(tripsError: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      });
    });

    // ── Scaffold structure ────────────────────────────────────────────────────

    group('Scaffold Structure', () {
      testWidgets('page renders a Scaffold', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('SliverAppBar is present when trips are loaded',
          (tester) async {
        await tester.pumpWidget(
          _buildTestApp(trips: [_makeTrip(id: 't1', name: 'Trip')]),
        );
        await _pumpTripsLoaded(tester);

        expect(find.byType(SliverAppBar), findsOneWidget);
      });
    });
  });
}
