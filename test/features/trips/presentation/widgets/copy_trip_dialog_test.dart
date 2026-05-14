import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/core/theme/theme_provider.dart' as theme_provider;
import 'package:pathio/features/auth/presentation/providers/auth_providers.dart';
import 'package:pathio/features/trips/domain/repositories/trip_repository.dart';
import 'package:pathio/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:pathio/features/trips/presentation/providers/trip_providers.dart';
import 'package:pathio/features/trips/presentation/widgets/copy_trip_dialog.dart';
import 'package:pathio/shared/models/trip_model.dart';

/// Hand-rolled fake trip repository.
class _FakeTripRepository implements TripRepository {
  String? lastSourceId;
  String? lastNewName;
  DateTime? lastStart;
  DateTime? lastEnd;
  bool? lastCopyItin;
  bool? lastCopyCheck;

  /// If non-null, copyTrip throws this.
  Object? error;

  /// The new trip ID returned by copyTrip.
  String newTripId = 'new-trip-1';

  @override
  Future<String> copyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  }) async {
    lastSourceId = sourceTripId;
    lastNewName = newName;
    lastStart = newStartDate;
    lastEnd = newEndDate;
    lastCopyItin = copyItinerary;
    lastCopyCheck = copyChecklists;
    if (error != null) throw error!;
    return newTripId;
  }

  // Methods we don't exercise in these tests:
  @override
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) =>
      throw UnimplementedError();

  @override
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? cost,
    String? currency,
    bool isPublic = true,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTrip(String tripId) async {}

  @override
  Future<List<TripWithMembers>> getDiscoverableTrips() async => [];

  @override
  Future<List<String>> getFavoriteTripIds() async => [];

  @override
  Future<TripWithMembers> getTripById(String tripId) =>
      throw UnimplementedError();

  @override
  Future<List<TripMemberModel>> getTripMembers(String tripId) async => [];

  @override
  Future<UserTravelStats> getUserStats() => throw UnimplementedError();

  @override
  Future<List<TripWithMembers>> getUserTrips() async => [];

  @override
  Future<void> joinTrip(String tripId) async {}

  @override
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async {}

  @override
  Future<bool> toggleFavorite(String tripId) async => false;

  @override
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    double? cost,
    String? currency,
    bool? isPublic,
  }) =>
      throw UnimplementedError();

  @override
  Stream<TripWithMembers> watchTrip(String tripId) =>
      const Stream.empty();

  @override
  Stream<List<TripWithMembers>> watchUserTrips() => const Stream.empty();

  @override
  Stream<UserTravelStats> watchUserStats() => const Stream.empty();
}

TripModel _makeTrip({
  String id = 'trip-1',
  String name = 'Source Trip',
  DateTime? startDate,
  DateTime? endDate,
}) {
  return TripModel(
    id: id,
    name: name,
    destination: 'Goa',
    startDate: startDate,
    endDate: endDate,
    createdBy: 'user-1',
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required _FakeTripRepository repo,
  required TripModel trip,
  int itineraryCount = 0,
  int checklistCount = 0,
  int checklistItemsCount = 0,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final theme = AppThemeData.getThemeData(AppThemeType.ocean);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(repo),
        theme_provider.currentThemeDataProvider.overrideWith((_) => theme),
        // Stub auth so userTripsProvider re-fetch (after invalidate) won't
        // hit Supabase. authStateProvider is a StreamProvider — its .value
        // becomes null when the stream emits null.
        authStateProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: AppThemeProvider(
        themeData: theme,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => CopyTripDialog.show(
                    context,
                    trip: trip,
                    itineraryCount: itineraryCount,
                    checklistCount: checklistCount,
                    checklistItemsCount: checklistItemsCount,
                  ),
                  child: const Text('Open Copy Dialog'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Copy Dialog'));
  await tester.pumpAndSettle();
}

void main() {
  group('CopyTripDialog Widget Tests', () {
    testWidgets('renders Copy Trip title and icon', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      expect(find.text('Copy Trip'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('Trip Name field is pre-filled with "(Copy)" suffix',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(
        tester,
        repo: repo,
        trip: _makeTrip(name: 'Goa Trip'),
      );

      final tf = tester.widget<TextField>(find.byType(TextField).first);
      expect(tf.controller!.text, 'Goa Trip (Copy)');
    });

    testWidgets('shows Start Date and End Date labels', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
    });

    testWidgets('shows "What to copy:" section', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      expect(find.text('What to copy:'), findsOneWidget);
      expect(find.text('Copy Itinerary'), findsOneWidget);
      expect(find.text('Copy Checklists'), findsOneWidget);
    });

    testWidgets('shows itinerary count when > 0', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(
        tester,
        repo: repo,
        trip: _makeTrip(),
        itineraryCount: 7,
      );
      expect(find.text('7 activities'), findsOneWidget);
    });

    testWidgets('shows "No activities to copy" when itineraryCount is 0',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      expect(find.text('No activities to copy'), findsOneWidget);
    });

    testWidgets('shows checklist count when > 0', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(
        tester,
        repo: repo,
        trip: _makeTrip(),
        checklistCount: 2,
        checklistItemsCount: 12,
      );
      expect(
        find.textContaining('2 lists, 12 items'),
        findsOneWidget,
      );
    });

    testWidgets('shows "No checklists to copy" when checklistCount is 0',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      expect(find.text('No checklists to copy'), findsOneWidget);
    });

    testWidgets('itinerary checkbox is disabled when count is 0',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      final checkboxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checkboxes[0].onChanged, isNull);
    });

    testWidgets('itinerary checkbox is enabled when count > 0',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(
        tester,
        repo: repo,
        trip: _makeTrip(),
        itineraryCount: 3,
      );
      final checkboxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checkboxes[0].onChanged, isNotNull);
    });

    testWidgets('checklist checkbox is disabled when count is 0',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      final checkboxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(checkboxes[1].onChanged, isNull);
    });

    testWidgets('Cancel button pops dialog with null', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Copy Trip'), findsNothing);
    });

    testWidgets('Create Copy button calls use case with trimmed name',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(
        tester,
        repo: repo,
        trip: _makeTrip(id: 'trip-src', name: 'Original'),
      );

      await tester.enterText(find.byType(TextField).first, '  My New Trip  ');
      await tester.pump();

      await tester.tap(find.text('Create Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repo.lastSourceId, 'trip-src');
      expect(repo.lastNewName, 'My New Trip');
    });

    testWidgets('Create Copy includes copyItinerary=true and copyChecklists=true by default',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      await tester.tap(find.text('Create Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repo.lastCopyItin, true);
      expect(repo.lastCopyCheck, true);
    });

    testWidgets('Create Copy shows error SnackBar on use case failure',
        (tester) async {
      final repo = _FakeTripRepository()..error = Exception('boom');
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      await tester.tap(find.text('Create Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Failed to copy trip'), findsOneWidget);
    });

    testWidgets('Empty name shows error SnackBar on Create Copy',
        (tester) async {
      // Note: the dialog doesn't listen to TextField changes for _canSubmit,
      // so the button stays enabled even when the name is cleared. The dialog
      // catches the empty name in _copyTrip() and shows a SnackBar instead.
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump();

      await tester.tap(find.text('Create Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Use case should NOT be called
      expect(repo.lastSourceId, isNull);
      // SnackBar prompt is shown
      expect(find.text('Please enter a trip name'), findsOneWidget);
    });

    testWidgets('Create Copy button enabled with valid name', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Copy'),
      );
      // Default state: name is "Source Trip (Copy)" so button should be enabled.
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('static show() opens the dialog', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('toggling itinerary checkbox flips _copyItinerary',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(
        tester,
        repo: repo,
        trip: _makeTrip(),
        itineraryCount: 2,
      );

      // Initially true → tap to set false
      await tester.tap(find.text('Copy Itinerary'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Copy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repo.lastCopyItin, false);
    });

    testWidgets('renders SingleChildScrollView for content', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('shows lock icon for disabled End Date field',
        (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      // End date is disabled - shows lock icon
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('TextField has prefix edit icon', (tester) async {
      final repo = _FakeTripRepository();
      await _pumpDialog(tester, repo: repo, trip: _makeTrip());
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });
  });
}
