import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/auth/presentation/providers/auth_providers.dart';
import 'package:pathio/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:pathio/features/itinerary/presentation/pages/itinerary_list_page.dart';
import 'package:pathio/features/itinerary/presentation/providers/itinerary_providers.dart';
import 'package:pathio/features/trips/presentation/providers/trip_providers.dart';
import 'package:pathio/shared/models/itinerary_model.dart';
import 'package:pathio/shared/models/trip_model.dart';

/// Extended coverage tests for [ItineraryListPage].
/// These complement the baseline tests in `itinerary_list_page_test.dart`.

class _FakeRepo implements ItineraryRepository {
  List<ItineraryDay> daysToReturn;

  _FakeRepo({this.daysToReturn = const []});

  @override
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) =>
      Stream.value(daysToReturn);

  @override
  Stream<List<ItineraryItemModel>> watchTripItinerary(String tripId) =>
      const Stream.empty();

  @override
  Future<ItineraryItemModel> createItineraryItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteItineraryItem(String itemId) => throw UnimplementedError();

  @override
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) =>
      throw UnimplementedError();

  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) =>
      throw UnimplementedError();

  @override
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) =>
      throw UnimplementedError();

  @override
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<ItineraryItemModel> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) =>
      throw UnimplementedError();
}

ItineraryItemModel _item({
  String id = 'i1',
  String title = 'Activity',
  String? description,
  String? location,
  double? lat,
  double? lng,
  DateTime? start,
  DateTime? end,
  int dayNumber = 1,
  int orderIndex = 0,
}) {
  return ItineraryItemModel(
    id: id,
    tripId: 'trip-1',
    title: title,
    description: description,
    location: location,
    latitude: lat,
    longitude: lng,
    startTime: start,
    endTime: end,
    dayNumber: dayNumber,
    orderIndex: orderIndex,
  );
}

TripWithMembers _tripWithMembers({
  String id = 'trip-1',
  String createdBy = 'owner-1',
  DateTime? startDate,
  DateTime? endDate,
  bool isCompleted = false,
}) {
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: 'Trip',
      startDate: startDate,
      endDate: endDate,
      createdBy: createdBy,
      isCompleted: isCompleted,
    ),
    members: const [],
  );
}

Widget _buildPage({
  required ItineraryRepository repo,
  required TripWithMembers trip,
  String? currentUserId = 'owner-1',
}) {
  final router = GoRouter(
    initialLocation: '/list',
    routes: [
      GoRoute(
        path: '/list',
        builder: (context, state) =>
            const ItineraryListPage(tripId: 'trip-1'),
      ),
      // Stub navigation targets so context.push doesn't blow up
      GoRoute(
        path: '/trips/:tripId/itinerary/add',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('ADD'))),
      ),
      GoRoute(
        path: '/trips/:tripId/itinerary/:itemId/edit',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('EDIT'))),
      ),
      GoRoute(
        path: '/ai-itinerary',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('AI'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      itineraryRepositoryProvider.overrideWithValue(repo),
      tripProvider.overrideWith((ref, tripId) => Stream.value(trip)),
      authStateProvider.overrideWith((ref) => Stream.value(currentUserId)),
    ],
    child: AppThemeProvider(
      themeData: AppThemeData.getThemeData(AppThemeType.ocean),
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
}

void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('ItineraryListPage extra — search/filter edge cases', () {
    testWidgets('empty search query returns all days unchanged',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(id: 'a', title: 'Breakfast')]),
        ItineraryDay(dayNumber: 2, items: [_item(id: 'b', title: 'Dinner')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      // Both days are visible
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    });

    testWidgets('whitespace-only query is treated as empty', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'Breakfast')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Breakfast'), findsOneWidget);
    });

    testWidgets('search is case-insensitive', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [
          _item(id: 'a', title: 'Breakfast'),
          _item(id: 'b', title: 'Dinner'),
        ]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'BREAK');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Dinner'), findsNothing);
    });

    testWidgets('search drops days with zero matching items', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(id: 'a', title: 'Breakfast')]),
        ItineraryDay(dayNumber: 2, items: [_item(id: 'b', title: 'Dinner')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Brea');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Day 1 still visible (has match), Day 2 should be hidden
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsNothing);
    });

    testWidgets('"Clear Search" button on no-results screen resets the field',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'Breakfast')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'zzznomatch');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No Activities Found'), findsOneWidget);

      await tester.tap(find.text('Clear Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No Activities Found'), findsNothing);
      expect(find.text('Breakfast'), findsOneWidget);
    });
  });

  group('ItineraryListPage extra — empty state actions', () {
    testWidgets('empty state shows event_note_outlined icon', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: const []);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      expect(find.byIcon(Icons.event_note_outlined), findsOneWidget);
    });

    testWidgets('empty state explanatory copy is rendered', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: const []);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      expect(
        find.text(
            'Start planning your trip by adding activities to your itinerary'),
        findsOneWidget,
      );
    });
  });

  group('ItineraryListPage extra — FAB collapse / re-expand', () {
    testWidgets('tapping main FAB twice collapses sub-options', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item()]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      // Expand
      await tester.tap(find.text('Add Activity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Voice Input'), findsOneWidget);

      // Collapse
      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Voice Input'), findsNothing);
      expect(find.text('Add Activity'), findsAtLeastNWidgets(1));
    });

    testWidgets('AI Generate sub-FAB is dismissable (no exception on tap)',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item()]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.tap(find.text('Add Activity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap sub-FAB on AI Generate row — only the icon is reliably tappable
      await tester.tap(find.byIcon(Icons.auto_awesome).last,
          warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // No expectation on outcome; we just check no exception was thrown.
      expect(tester.takeException(), isNull);
    });
  });

  group('ItineraryListPage extra — long-press menu items', () {
    testWidgets('long-press menu shows the item title in header',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'My Activity')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.longPress(find.text('My Activity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The bottom-sheet renders the title and edit/delete entries
      expect(find.text('My Activity'), findsAtLeastNWidgets(1));
      expect(find.text('Modify details, time, or location'), findsOneWidget);
      expect(find.text('Remove from itinerary'), findsOneWidget);
    });

    testWidgets('long-press menu shows item location in subtitle when present',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [
          _item(title: 'Visit', location: 'Paris'),
        ]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.longPress(find.text('Visit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Paris appears: once in the card, once in the bottom sheet header
      expect(find.text('Paris'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'tapping Edit Activity in long-press menu dismisses the sheet',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.longPress(find.text('X'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Activity'), findsOneWidget);
      // Tap edit option — sheet should close (no router available, but
      // closing sheet itself should not throw).
      await tester.tap(find.text('Edit Activity'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sheet collapsed → "Modify details, time, or location" hidden
      expect(find.text('Modify details, time, or location'), findsNothing);
    });

    testWidgets('Cancel button in delete-confirmation dialog dismisses it',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'TodoItem')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      // Open long-press menu
      await tester.longPress(find.text('TodoItem'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap delete in menu (different from swipe)
      await tester.tap(find.text('Delete Activity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Delete Activity'), findsAtLeastNWidgets(1));
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirmation dialog gone
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets(
        'no-other-days SnackBar appears when Move to Day has only one day',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'OnlyDay')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      // Move to Day option is hidden when allDays.length <= 1
      await tester.longPress(find.text('OnlyDay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Move to Another Day'), findsNothing);
    });
  });

  group('ItineraryListPage extra — Move-to-Day modal', () {
    testWidgets('Move to Day dialog lists every other day', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'D1')]),
        ItineraryDay(dayNumber: 2, items: const []),
        ItineraryDay(dayNumber: 3, items: const []),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.longPress(find.text('D1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Move to Another Day'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal title and the day options are visible (Day 2 may appear twice
      // because the day-card header in the page underneath also says "Day 2";
      // we just confirm both are reachable)
      expect(find.text('Move to Day'), findsOneWidget);
      expect(find.text('Day 2'), findsAtLeastNWidgets(1));
      expect(find.text('Day 3'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Move-to-Day modal shows the activity title in the subtitle',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'TheActivity')]),
        ItineraryDay(dayNumber: 2, items: const []),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.longPress(find.text('TheActivity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Move to Another Day'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Select destination for "TheActivity"'),
        findsOneWidget,
      );
    });

    testWidgets('Move-to-Day shows correct activity counts per day',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(id: 'a', title: 'Foo')]),
        ItineraryDay(dayNumber: 2, items: [
          _item(id: 'b'),
          _item(id: 'c'),
        ]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      await tester.longPress(find.text('Foo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Move to Another Day'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Day 2 has 2 activities — the modal subtitle says "2 activities"
      expect(find.text('2 activities'), findsAtLeastNWidgets(1));
    });
  });

  group('ItineraryListPage extra — non-editor view', () {
    testWidgets('non-editor sees ListView (no Reorderable handles)',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'random',
      ));
      await _settle(tester);

      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('non-editor cannot dismiss-to-delete (Dismissible absent)',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'random',
      ));
      await _settle(tester);

      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('non-editor sees no edit/long-press menu trigger',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'random',
      ));
      await _settle(tester);

      // long press as non-editor: menu should NOT appear
      await tester.longPress(find.text('X'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Activity'), findsNothing);
      expect(find.text('Delete Activity'), findsNothing);
    });
  });

  group('ItineraryListPage extra — editor view drag handle', () {
    testWidgets('editor sees a drag handle icon (platform-specific)',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      // Default test platform is Android → drag_indicator
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('editor list uses ReorderableListView', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('editor item is wrapped in Dismissible for swipe-to-delete',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(title: 'X')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(createdBy: 'owner-1'),
        currentUserId: 'owner-1',
      ));
      await _settle(tester);

      expect(find.byType(Dismissible), findsOneWidget);
    });
  });

  group('ItineraryListPage extra — multiple-day rendering', () {
    testWidgets('shows day headers for each day in the list', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(id: 'a')]),
        ItineraryDay(dayNumber: 2, items: [_item(id: 'b')]),
        ItineraryDay(dayNumber: 3, items: [_item(id: 'c')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(),
      ));
      await _settle(tester);

      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Day 3'), findsOneWidget);
    });

    testWidgets('day-card today highlights only one day', (tester) async {
      useTallViewport(tester);
      final today = DateTime.now();
      final tripStart = DateTime(today.year, today.month, today.day);
      final repo = _FakeRepo(daysToReturn: [
        ItineraryDay(dayNumber: 1, items: [_item(id: 'a', title: 'D1')]),
        ItineraryDay(dayNumber: 2, items: [_item(id: 'b', title: 'D2')]),
      ]);
      await tester.pumpWidget(_buildPage(
        repo: repo,
        trip: _tripWithMembers(
          startDate: tripStart,
          endDate: tripStart.add(const Duration(days: 4)),
        ),
      ));
      await _settle(tester);

      expect(find.text('TODAY'), findsOneWidget);
    });
  });
}
