import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:travel_crew/features/messaging/presentation/widgets/sync_fab.dart';

void main() {
  void expandViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  QueuedMessageEntity buildQueued({String id = 'q-1'}) {
    return QueuedMessageEntity(
      id: id,
      tripId: 'trip-1',
      senderId: 'user-1',
      messageData: const {'message': 'queued text'},
      transmissionMethod: TransmissionMethod.internet,
      syncStatus: MessageSyncStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  group('SyncFab', () {
    testWidgets('renders nothing when no pending messages (with tripId)',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pendingMessagesByTripProvider('trip-1')
              .overrideWith((ref) async => <QueuedMessageEntity>[]),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            floatingActionButton: SyncFab(tripId: 'trip-1'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders nothing when no pending messages (without tripId)',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pendingMessagesCountProvider.overrideWith((ref) async => 0),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            floatingActionButton: SyncFab(),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders FAB with count when there are pending messages',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pendingMessagesByTripProvider('trip-1').overrideWith(
              (ref) async => [buildQueued(), buildQueued(id: 'q2')]),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            floatingActionButton: SyncFab(tripId: 'trip-1'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('2 pending'), findsOneWidget);
    });

    testWidgets('shows offline icon when offline', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pendingMessagesByTripProvider('trip-1')
              .overrideWith((ref) async => [buildQueued()]),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.none]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            floatingActionButton: SyncFab(tripId: 'trip-1'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows upload icon when online', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pendingMessagesByTripProvider('trip-1')
              .overrideWith((ref) async => [buildQueued()]),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            floatingActionButton: SyncFab(tripId: 'trip-1'),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('count provider variant works without tripId', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          pendingMessagesCountProvider.overrideWith((ref) async => 5),
          connectivityStatusProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            floatingActionButton: SyncFab(),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('5 pending'), findsOneWidget);
    });
  });
}
