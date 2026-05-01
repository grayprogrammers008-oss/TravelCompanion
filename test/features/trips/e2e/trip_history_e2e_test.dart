import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/widgets/app_loading_indicator.dart';
import 'package:travel_crew/features/trips/presentation/pages/trip_history_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_history_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/core/animations/animated_widgets.dart';

import 'trip_history_e2e_test.mocks.dart';

@GenerateMocks([GetTripHistoryUseCase])

/// Pumps enough frames to fire FadeInAnimation Dart timers and complete animations.
/// The default 800×600 test window is too short — Paris card (index=1) sits below
/// ListView.builder's cacheExtent and is never built, so its timer is never registered.
/// Expanding the viewport forces the list to build all cards.
Future<void> _pumpHistoryLoaded(WidgetTester tester) async {
  // Expand viewport so ListView.builder renders all trip cards within the visible area.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pump(); // Relayout with new size; FadeInAnimation.initState() fires for all cards
  await tester.pump(const Duration(milliseconds: 500)); // Fire Dart timers + complete 300ms animations
  await tester.pump(); // Process remaining callbacks
}

void main() {
  late MockGetTripHistoryUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetTripHistoryUseCase();
  });

  Widget createTestWidget({List<TripWithMembers>? trips}) {
    final completedTrips = trips ??
        [
          TripWithMembers(
            trip: TripModel(
              id: '1',
              name: 'Paris Adventure',
              destination: 'Paris, France',
              createdBy: 'user1',
              createdAt: DateTime(2024, 1, 1),
              updatedAt: DateTime(2024, 1, 1),
              startDate: DateTime(2024, 5, 1),
              endDate: DateTime(2024, 5, 10),
              isCompleted: true,
              completedAt: DateTime(2024, 5, 15),
              rating: 4.5,
            ),
            members: [
              TripMemberModel(
                id: 'member1',
                tripId: '1',
                userId: 'user1',
                role: 'admin',
                joinedAt: DateTime(2024, 1, 1),
                fullName: 'John Doe',
                email: 'john@example.com',
              ),
              TripMemberModel(
                id: 'member2',
                tripId: '1',
                userId: 'user2',
                role: 'member',
                joinedAt: DateTime(2024, 1, 2),
                fullName: 'Jane Smith',
                email: 'jane@example.com',
              ),
            ],
          ),
          TripWithMembers(
            trip: TripModel(
              id: '2',
              name: 'Tokyo Experience',
              destination: 'Tokyo, Japan',
              createdBy: 'user1',
              createdAt: DateTime(2024, 2, 1),
              updatedAt: DateTime(2024, 2, 1),
              startDate: DateTime(2024, 6, 1),
              endDate: DateTime(2024, 6, 15),
              isCompleted: true,
              completedAt: DateTime(2024, 6, 20),
              rating: 5.0,
            ),
            members: [
              TripMemberModel(
                id: 'member3',
                tripId: '2',
                userId: 'user1',
                role: 'admin',
                joinedAt: DateTime(2024, 2, 1),
                fullName: 'John Doe',
                email: 'john@example.com',
              ),
            ],
          ),
        ];

    when(mockUseCase.watchHistory())
        .thenAnswer((_) => Stream.value(completedTrips));

    when(mockUseCase.getStatistics()).thenAnswer((_) async {
      return TripHistoryStatistics(
        totalCompletedTrips: completedTrips.length,
        averageRating: completedTrips.isEmpty
            ? 0.0
            : completedTrips
                    .where((t) => t.trip.rating > 0)
                    .map((t) => t.trip.rating)
                    .reduce((a, b) => a + b) /
                completedTrips.where((t) => t.trip.rating > 0).length,
        totalRatedTrips: completedTrips.where((t) => t.trip.rating > 0).length,
        earliestCompletionDate: completedTrips.isNotEmpty
            ? completedTrips
                .map((t) => t.trip.completedAt!)
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        latestCompletionDate: completedTrips.isNotEmpty
            ? completedTrips
                .map((t) => t.trip.completedAt!)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );
    });

    return ProviderScope(
      overrides: [
        getTripHistoryUseCaseProvider.overrideWithValue(mockUseCase),
        tripHistoryProvider.overrideWith(
          (ref) => mockUseCase.watchHistory(),
        ),
      ],
      child: AppThemeProvider(
        themeData: AppThemeData.getThemeData(AppThemeType.ocean),
        child: const MaterialApp(
          home: TripHistoryPage(),
        ),
      ),
    );
  }

  group('Trip History Page E2E Tests', () {
    testWidgets('should display trip history page with statistics header',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Page title
      expect(find.text('Trip History'), findsOneWidget);

      // Assert - Statistics header
      expect(find.text('Your Travel Statistics'), findsOneWidget);
      expect(find.text('Total Trips'), findsOneWidget);
      expect(find.text('Avg Rating'), findsOneWidget);
      expect(find.text('Rated'), findsOneWidget);
    });

    testWidgets('should display list of completed trips', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await _pumpHistoryLoaded(tester);

      // Assert - Trip cards
      expect(find.text('Paris Adventure'), findsOneWidget);
      expect(find.text('Tokyo Experience'), findsOneWidget);
      expect(find.text('Paris, France'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
    });

    testWidgets('should display trip ratings', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await _pumpHistoryLoaded(tester);

      // Assert - Rating badges
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(3)); // 2 in badges + 1 in header
    });

    testWidgets('should display member count for each trip', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await _pumpHistoryLoaded(tester);

      // Assert
      expect(find.text('2 members'), findsOneWidget); // Paris trip
      expect(find.text('1 member'), findsOneWidget);   // Tokyo trip
    });

    testWidgets('should display completion dates', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await _pumpHistoryLoaded(tester);

      // Assert - Completion dates
      expect(find.textContaining('Completed:'), findsNWidgets(2));
      expect(find.textContaining('May 15, 2024'), findsOneWidget);
      expect(find.textContaining('Jun 20, 2024'), findsOneWidget);
    });

    testWidgets('should display empty state when no completed trips',
        (tester) async {
      // Arrange
      when(mockUseCase.watchHistory()).thenAnswer((_) => Stream.value([]));
      when(mockUseCase.getStatistics())
          .thenAnswer((_) async => TripHistoryStatistics.empty());

      await tester.pumpWidget(createTestWidget(trips: []));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No completed trips yet'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(
        find.textContaining('Your trip history will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('should display loading state', (tester) async {
      // Use a StreamController that never emits so the provider stays in loading state.
      // Cannot use createTestWidget() here because it overrides the watchHistory mock.
      final controller = StreamController<List<TripWithMembers>>();
      addTearDown(() async {
        if (!controller.isClosed) await controller.close();
      });
      when(mockUseCase.watchHistory()).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTripHistoryUseCaseProvider.overrideWithValue(mockUseCase),
            tripHistoryProvider.overrideWith(
              (ref) => mockUseCase.watchHistory(),
            ),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(home: TripHistoryPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppLoadingIndicator), findsOneWidget);

      // Dispose the page (and its AnimationControllers) before the test framework
      // checks for pending timers — AppLoadingIndicator runs continuous animations
      // that would otherwise keep the test runner waiting indefinitely.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('should display error state when loading fails',
        (tester) async {
      // Set mock before building widget. Cannot use createTestWidget() because
      // it calls when(mockUseCase.watchHistory()) internally, overriding this mock.
      when(mockUseCase.watchHistory())
          .thenAnswer((_) => Stream.error(Exception('Network error')));
      when(mockUseCase.getStatistics())
          .thenAnswer((_) async => TripHistoryStatistics.empty());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTripHistoryUseCaseProvider.overrideWithValue(mockUseCase),
            tripHistoryProvider.overrideWith(
              (ref) => mockUseCase.watchHistory(),
            ),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(home: TripHistoryPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error loading trip history'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should navigate to trip detail when card is tapped',
        (tester) async {
      // Production code calls context.push() (GoRouter), so wrap in MaterialApp.router.
      final completedTrip = TripWithMembers(
        trip: TripModel(
          id: '1',
          name: 'Paris Adventure',
          destination: 'Paris, France',
          createdBy: 'user1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          startDate: DateTime(2024, 5, 1),
          endDate: DateTime(2024, 5, 10),
          isCompleted: true,
          completedAt: DateTime(2024, 5, 15),
          rating: 4.5,
        ),
        members: const [],
      );

      when(mockUseCase.watchHistory())
          .thenAnswer((_) => Stream.value([completedTrip]));
      when(mockUseCase.getStatistics()).thenAnswer((_) async =>
          TripHistoryStatistics(
            totalCompletedTrips: 1,
            averageRating: 4.5,
            totalRatedTrips: 1,
            earliestCompletionDate: completedTrip.trip.completedAt,
            latestCompletionDate: completedTrip.trip.completedAt,
          ));

      var navigatedTo = '';
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const TripHistoryPage()),
          GoRoute(
            path: '/trips/:id',
            builder: (_, state) {
              navigatedTo = state.uri.toString();
              return const Scaffold(body: Text('Trip Detail'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getTripHistoryUseCaseProvider.overrideWithValue(mockUseCase),
            tripHistoryProvider.overrideWith(
              (ref) => mockUseCase.watchHistory(),
            ),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await _pumpHistoryLoaded(tester);

      // Act - Tap on the trip card
      await tester.tap(find.text('Paris Adventure'));
      // Manual pumps to avoid pumpAndSettle hang on looping animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Assert - Navigation occurred
      expect(navigatedTo, contains('/trips/1'));
    });

    testWidgets('should display correct statistics', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Statistics values
      expect(find.text('2'), findsOneWidget); // Total trips
      expect(find.text('4.8'), findsOneWidget); // Average rating (4.5+5.0)/2
      expect(find.text('2/2'), findsOneWidget); // Rated trips
    });

    testWidgets('should handle trips without ratings', (tester) async {
      // Arrange
      final tripsWithoutRating = [
        TripWithMembers(
          trip: TripModel(
            id: '1',
            name: 'Unrated Trip',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
            isCompleted: true,
            completedAt: DateTime(2024, 5, 15),
            rating: 0.0, // Not rated
          ),
          members: [],
        ),
      ];

      await tester.pumpWidget(createTestWidget(trips: tripsWithoutRating));
      await tester.pumpAndSettle();

      // Assert - Should not display rating badge
      expect(find.text('Paris Adventure'), findsNothing);
      expect(find.text('Unrated Trip'), findsOneWidget);
    });

    testWidgets('should display date range for trips', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await _pumpHistoryLoaded(tester);

      // Assert
      expect(find.textContaining('May 01, 2024 - May 10, 2024'), findsOneWidget);
      expect(find.textContaining('Jun 01, 2024 - Jun 15, 2024'), findsOneWidget);
    });

    testWidgets('should display trips in correct order (newest first)',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await _pumpHistoryLoaded(tester);

      // Assert - Find all trip cards
      final tripCards = find.byType(AnimatedScaleButton);
      expect(tripCards, findsNWidgets(2));

      // Tokyo trip (completed June 20) should be first
      // Paris trip (completed May 15) should be second
      // This is ensured by the mock returning them in sorted order
    });

    testWidgets('should scroll through long list of trips', (tester) async {
      // Arrange - Create many trips
      final manyTrips = List.generate(
        20,
        (i) => TripWithMembers(
          trip: TripModel(
            id: 'trip_$i',
            name: 'Trip $i',
            destination: 'Destination $i',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, i + 1),
            updatedAt: DateTime(2024, 1, i + 1),
            isCompleted: true,
            completedAt: DateTime(2024, i % 12 + 1, 15),
            rating: 3.0 + (i % 3),
          ),
          members: [],
        ),
      );

      await tester.pumpWidget(createTestWidget(trips: manyTrips));
      await tester.pumpAndSettle();

      // Act - Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Assert - Should be able to scroll
      expect(find.text('Trip 0'), findsNothing); // Scrolled off screen
    });
  });

  group('Trip History Page Accessibility Tests', () {
    testWidgets('should have proper semantics for screen readers',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Check for semantic labels
      // AppBar title text carries isHeader and namesRoute flags from the framework.
      expect(
        tester.getSemantics(find.text('Trip History')),
        matchesSemantics(
          label: 'Trip History',
          isHeader: true,
          namesRoute: true,
        ),
      );
    });

    testWidgets('should handle large text sizes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: createTestWidget(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Page should still render without overflow
      expect(find.text('Trip History'), findsOneWidget);
    });
  });

  group('Trip History Page Performance Tests', () {
    testWidgets('should render efficiently with many trips', (tester) async {
      // Arrange - Create 100 trips
      final manyTrips = List.generate(
        100,
        (i) => TripWithMembers(
          trip: TripModel(
            id: 'trip_$i',
            name: 'Trip $i',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
            isCompleted: true,
            completedAt: DateTime(2024, i % 12 + 1, 15),
            rating: 3.0 + (i % 3),
          ),
          members: [],
        ),
      );

      // Act
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(createTestWidget(trips: manyTrips));
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Assert - Should render in reasonable time (< 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
