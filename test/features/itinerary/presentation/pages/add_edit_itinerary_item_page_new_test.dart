import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:pathio/features/itinerary/presentation/pages/add_edit_itinerary_item_page_new.dart';
import 'package:pathio/features/itinerary/presentation/providers/itinerary_providers.dart';
import 'package:pathio/shared/models/itinerary_model.dart';

/// Hand-rolled fake — no codegen, no Supabase. Only `getItineraryItem`
/// is used by the page (when editing an existing item).
class _FakeRepo implements ItineraryRepository {
  ItineraryItemModel? itemToReturn;
  Object? getError;

  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) async {
    if (getError != null) throw getError!;
    return itemToReturn!;
  }

  @override
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) =>
      const Stream.empty();

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

ItineraryItemModel _existingItem({
  String id = 'item-1',
  String title = 'Visit Eiffel Tower',
  String? description = 'Skip the line',
  String? location = 'Paris',
  DateTime? startTime,
  DateTime? endTime,
  int? dayNumber = 2,
}) {
  return ItineraryItemModel(
    id: id,
    tripId: 'trip-1',
    title: title,
    description: description,
    location: location,
    startTime: startTime,
    endTime: endTime,
    dayNumber: dayNumber,
  );
}

Widget _wrap({
  String? itemId,
  String? prefillTitle,
  String? prefillLocation,
  String? prefillDescription,
  ItineraryRepository? repo,
}) {
  final router = GoRouter(
    initialLocation: '/page',
    routes: [
      GoRoute(
        path: '/page',
        builder: (context, state) => AddEditItineraryItemPageNew(
          tripId: 'trip-1',
          itemId: itemId,
          prefillTitle: prefillTitle,
          prefillLocation: prefillLocation,
          prefillDescription: prefillDescription,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (repo != null) itineraryRepositoryProvider.overrideWithValue(repo),
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
  // Allow staggered FadeSlide entrance animations to complete.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('AddEditItineraryItemPageNew — Add (no itemId)', () {
    testWidgets('shows "Add Activity" app-bar title in add mode',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Add Activity'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows "Plan Your Day" header text in add mode',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Plan Your Day'), findsOneWidget);
    });

    testWidgets('renders title, description, location form fields',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Activity Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('renders Day dropdown', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Day'), findsOneWidget);
    });

    testWidgets('renders start time and end time pickers', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Start Time'), findsAtLeastNWidgets(1));
      expect(find.text('End Time'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders cancel button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders "* Required fields" help text', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('* Required fields'), findsOneWidget);
    });

    testWidgets('pre-fills title from prefillTitle', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(prefillTitle: 'Beach Visit'));
      await _settle(tester);

      // Beach Visit appears in a TextFormField (PremiumTextField).
      expect(find.text('Beach Visit'), findsAtLeastNWidgets(1));
    });

    testWidgets('pre-fills location from prefillLocation', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(prefillLocation: 'Marina Beach'));
      await _settle(tester);

      expect(find.text('Marina Beach'), findsAtLeastNWidgets(1));
    });

    testWidgets('pre-fills description from prefillDescription',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(prefillDescription: 'Sunset stroll'));
      await _settle(tester);

      expect(find.text('Sunset stroll'), findsAtLeastNWidgets(1));
    });
  });

  group('AddEditItineraryItemPageNew — Edit (with itemId)', () {
    testWidgets('shows "Loading..." in app-bar while fetching item',
        (tester) async {
      useTallViewport(tester);
      // Repo never resolves
      await tester.pumpWidget(
        _wrap(
          itemId: 'item-1',
          repo: _NeverResolveRepo(),
        ),
      );
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Loading activity...'), findsOneWidget);
    });

    testWidgets('shows "Edit Activity" app-bar after item loads',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo()..itemToReturn = _existingItem();
      await tester.pumpWidget(_wrap(itemId: 'item-1', repo: repo));
      await _settle(tester);

      expect(find.text('Edit Activity'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows "Update Activity" header text in edit mode',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo()..itemToReturn = _existingItem();
      await tester.pumpWidget(_wrap(itemId: 'item-1', repo: repo));
      await _settle(tester);

      expect(find.text('Update Activity'), findsAtLeastNWidgets(1));
    });

    testWidgets('pre-fills loaded title in title field', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo()
        ..itemToReturn = _existingItem(title: 'Visit Eiffel Tower');
      await tester.pumpWidget(_wrap(itemId: 'item-1', repo: repo));
      await _settle(tester);

      expect(find.text('Visit Eiffel Tower'), findsAtLeastNWidgets(1));
    });

    testWidgets('pre-fills loaded description in description field',
        (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo()
        ..itemToReturn = _existingItem(description: 'Buy skip-the-line');
      await tester.pumpWidget(_wrap(itemId: 'item-1', repo: repo));
      await _settle(tester);

      expect(find.text('Buy skip-the-line'), findsAtLeastNWidgets(1));
    });

    testWidgets('pre-fills loaded location in location field', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo()
        ..itemToReturn = _existingItem(location: 'Champ de Mars');
      await tester.pumpWidget(_wrap(itemId: 'item-1', repo: repo));
      await _settle(tester);

      expect(find.text('Champ de Mars'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error SnackBar when repository fails', (tester) async {
      useTallViewport(tester);
      final repo = _FakeRepo()..getError = Exception('not found');
      await tester.pumpWidget(_wrap(itemId: 'item-1', repo: repo));
      await _settle(tester);

      // The error SnackBar contains "Error loading activity"
      expect(find.textContaining('Error loading activity'), findsOneWidget);
    });
  });

  group('AddEditItineraryItemPageNew — interactions', () {
    testWidgets('cancel button widget renders', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await _settle(tester);
      // Just verify the button is reachable; tapping it would pop the
      // route, which has unrelated routing side effects in this harness.
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}

/// A repo whose getItineraryItem never resolves — useful for testing
/// the "Loading…" branch.
class _NeverResolveRepo implements ItineraryRepository {
  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) {
    return Completer<ItineraryItemModel>().future;
  }

  @override
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) =>
      const Stream.empty();

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
