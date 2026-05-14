import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/itinerary/presentation/widgets/timeline_view.dart';
import 'package:pathio/shared/models/itinerary_model.dart';

ItineraryItemModel _item({
  String id = 'i1',
  String title = 'Visit Eiffel Tower',
  String? description,
  String? location,
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
    startTime: start,
    endTime: end,
    dayNumber: dayNumber,
    orderIndex: orderIndex,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1976D2),
        onSurface: Color(0xFF111111),
      ),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TimelineView empty/initial states', () {
    testWidgets('shows "No activities yet" when days list is empty', (tester) async {
      await tester.pumpWidget(_wrap(const TimelineView(days: [])));
      expect(find.text('No activities yet'), findsOneWidget);
    });

    testWidgets('shows empty-day message when current day has no items', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('No activities for Day 1'), findsOneWidget);
      expect(find.byIcon(Icons.event_note_outlined), findsOneWidget);
    });

    testWidgets('renders day navigation header with the day number', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('Day 1'), findsOneWidget);
    });
  });

  group('TimelineView day navigation', () {
    testWidgets('initialDay positions correctly when matching dayNumber exists', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
        ItineraryDay(dayNumber: 3, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days, initialDay: 2)));
      expect(find.text('Day 2'), findsOneWidget);
    });

    testWidgets('falls back to first day when initialDay is not present', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days, initialDay: 99)));
      expect(find.text('Day 1'), findsOneWidget);
    });

    testWidgets('left arrow disabled on first day, right arrow enabled', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days, initialDay: 1)));

      final leftBtn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      final rightBtn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(leftBtn.onPressed, isNull);
      expect(rightBtn.onPressed, isNotNull);
    });

    testWidgets('right arrow disabled on last day', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days, initialDay: 2)));
      final rightBtn = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(rightBtn.onPressed, isNull);
    });

    testWidgets('tapping right arrow advances to next day', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days, initialDay: 1)));
      expect(find.text('Day 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('Day 2'), findsOneWidget);
    });

    testWidgets('tapping left arrow returns to previous day', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days, initialDay: 2)));
      expect(find.text('Day 2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Day 1'), findsOneWidget);
    });
  });

  group('TimelineView TODAY badge & date display', () {
    testWidgets('shows TODAY badge when todaysDayNumber matches current day', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        todaysDayNumber: 1,
      )));
      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('does not show TODAY badge when todaysDayNumber is null', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('TODAY'), findsNothing);
    });

    testWidgets('shows formatted date when tripStartDate is provided', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        tripStartDate: DateTime(2024, 1, 15),
      )));
      // Day 1 is the start date itself. Jan 15 2024 is a Monday.
      expect(find.text('Monday, January 15'), findsOneWidget);
    });

    testWidgets('day 2 uses tripStartDate + 1 day', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: const []),
        ItineraryDay(dayNumber: 2, items: const []),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        initialDay: 2,
        tripStartDate: DateTime(2024, 1, 15),
      )));
      expect(find.text('Tuesday, January 16'), findsOneWidget);
    });
  });

  group('TimelineView item rendering', () {
    testWidgets('renders an item title and start time formatted as HH:mm', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(start: DateTime(2024, 1, 15, 9, 30)),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('Visit Eiffel Tower'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);
    });

    testWidgets('renders em-dash placeholder when item has no start time', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows location when present', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(location: 'Paris, France'),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('Paris, France'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('omits location row when location is null', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [_item()]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('shows description text when present', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(description: 'Skip the line tour'),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('Skip the line tour'), findsOneWidget);
    });

    testWidgets('shows "Until HH:mm" when endTime is present', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(
            start: DateTime(2024, 1, 15, 9, 0),
            end: DateTime(2024, 1, 15, 11, 30),
          ),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('Until 11:30'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('renders multiple items in a single day', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(id: 'a', title: 'Breakfast', start: DateTime(2024, 1, 15, 8, 0)),
          _item(id: 'b', title: 'Lunch', start: DateTime(2024, 1, 15, 12, 0)),
          _item(id: 'c', title: 'Dinner', start: DateTime(2024, 1, 15, 19, 0)),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    });

    testWidgets('items are sorted by start time', (tester) async {
      // Provide them out of order; ListView should render in time order.
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(id: 'late', title: 'Dinner', start: DateTime(2024, 1, 15, 19, 0)),
          _item(id: 'early', title: 'Breakfast', start: DateTime(2024, 1, 15, 8, 0)),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));

      final breakfastY = tester.getCenter(find.text('Breakfast')).dy;
      final dinnerY = tester.getCenter(find.text('Dinner')).dy;
      expect(breakfastY, lessThan(dinnerY));
    });

    testWidgets('items without start time appear after timed items', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(id: 'no-time', title: 'Untimed'),
          _item(id: 'timed', title: 'Breakfast', start: DateTime(2024, 1, 15, 8, 0)),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));
      final timedY = tester.getCenter(find.text('Breakfast')).dy;
      final untimedY = tester.getCenter(find.text('Untimed')).dy;
      expect(timedY, lessThan(untimedY));
    });
  });

  group('TimelineView onItemTap callback', () {
    testWidgets('invokes onItemTap with the tapped item', (tester) async {
      ItineraryItemModel? tapped;
      final item = _item(title: 'Visit Eiffel Tower');
      final days = [
        ItineraryDay(dayNumber: 1, items: [item]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        onItemTap: (i) => tapped = i,
      )));

      await tester.tap(find.text('Visit Eiffel Tower'));
      await tester.pump();
      expect(tapped, isNotNull);
      expect(tapped!.id, item.id);
    });

    testWidgets('does not throw when onItemTap is null', (tester) async {
      final days = [
        ItineraryDay(dayNumber: 1, items: [_item()]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(days: days)));

      await tester.tap(find.text('Visit Eiffel Tower'));
      await tester.pump();
      // Test passes if no exception was thrown.
    });
  });

  group('TimelineView activity status (NOW badge)', () {
    testWidgets('shows NOW badge when current time is within an item window on today', (tester) async {
      final now = DateTime.now();
      // Item that started 30 min ago and ends 30 min from now → currently happening.
      final start = now.subtract(const Duration(minutes: 30));
      final end = now.add(const Duration(minutes: 30));
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(title: 'Happening Now', start: start, end: end),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        todaysDayNumber: 1,
      )));
      expect(find.text('NOW'), findsOneWidget);
    });

    testWidgets('does not show NOW badge for upcoming items today', (tester) async {
      final start = DateTime.now().add(const Duration(hours: 2));
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(title: 'Later today', start: start),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        todaysDayNumber: 1,
      )));
      expect(find.text('NOW'), findsNothing);
    });

    testWidgets('shows completed-style strike-through when item is in the past on today', (tester) async {
      final start = DateTime.now().subtract(const Duration(hours: 3));
      final end = DateTime.now().subtract(const Duration(hours: 1));
      final days = [
        ItineraryDay(dayNumber: 1, items: [
          _item(title: 'Done already', start: start, end: end),
        ]),
      ];
      await tester.pumpWidget(_wrap(TimelineView(
        days: days,
        todaysDayNumber: 1,
      )));

      final textWidget = tester.widget<Text>(find.text('Done already'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
      // Completed activities also render the check icon in the timeline dot.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
