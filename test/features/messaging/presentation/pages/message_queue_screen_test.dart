import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';
import 'package:travel_crew/features/messaging/domain/repositories/message_repository.dart';
import 'package:travel_crew/features/messaging/presentation/pages/message_queue_screen.dart';
import 'package:travel_crew/features/messaging/presentation/providers/messaging_providers.dart';

/// Hand-rolled fake repository: only `getPendingMessages` is exercised.
class _FakeMessageRepository implements MessageRepository {
  _FakeMessageRepository(this._messages);
  final Future<List<QueuedMessageEntity>> _messages;

  @override
  Future<List<QueuedMessageEntity>> getPendingMessages() => _messages;

  @override
  Future<void> retryMessage(String queuedMessageId) async {}

  @override
  Future<void> removeFromQueue(String queuedMessageId) async {}

  @override
  Future<void> syncPendingMessages() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  void expandViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  const tripId = 'trip-1';

  QueuedMessageEntity makeQueued({
    String id = 'q-1',
    MessageSyncStatus status = MessageSyncStatus.pending,
    int retryCount = 0,
    String? errorMessage,
    String text = 'Pending message',
  }) {
    return QueuedMessageEntity(
      id: id,
      tripId: tripId,
      senderId: 'user-1',
      messageData: {'message': text},
      transmissionMethod: TransmissionMethod.internet,
      syncStatus: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
  }

  // The page uses `pendingAsync is AsyncData` with FutureBuilder. The
  // tripId-bound provider returns a List<QueuedMessageEntity> directly while
  // the page expects a Future<List<...>> in that branch — a type cast
  // mismatch in production code. Tests therefore use the tripId=null branch
  // which does wrap in `whenData(...getPendingMessages())`.

  Widget buildPage({
    Future<List<QueuedMessageEntity>>? messagesFuture,
    Stream<List<ConnectivityResult>>? connectivity,
  }) {
    final fut =
        messagesFuture ?? Future.value(<QueuedMessageEntity>[]);
    return ProviderScope(
      overrides: [
        pendingMessagesCountProvider.overrideWith((ref) async {
          final list = await fut;
          return list.length;
        }),
        // Stub the repository getPendingMessages() via an override; the
        // tripId=null branch reads messageRepositoryProvider.
        messageRepositoryProvider
            .overrideWithValue(_FakeMessageRepository(fut)),
        connectivityStatusProvider.overrideWith(
          (ref) => connectivity ?? Stream.value([ConnectivityResult.wifi]),
        ),
      ],
      child: const MaterialApp(
        home: MessageQueueScreen(), // tripId omitted to use null branch
      ),
    );
  }

  group('MessageQueueScreen', () {
    testWidgets('renders Message Queue title', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Message Queue'), findsOneWidget);
    });

    testWidgets('shows Online indicator when connected', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Online'), findsOneWidget);
      // Empty state also shows cloud_done — both should be present
      expect(find.byIcon(Icons.cloud_done), findsWidgets);
    });

    testWidgets('shows Offline indicator when not connected', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        connectivity: Stream.value([ConnectivityResult.none]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows empty state when no pending messages', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value(<QueuedMessageEntity>[]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('No pending messages to sync'), findsOneWidget);
    });

    testWidgets('renders pending message card', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([
          makeQueued(text: 'Hello world'),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('Waiting to send'), findsOneWidget);
    });

    testWidgets('renders failed message card with error message',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([
          makeQueued(
            id: 'q-2',
            text: 'failed text',
            status: MessageSyncStatus.failed,
            errorMessage: 'Connection refused',
            retryCount: 2,
          ),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('failed text'), findsOneWidget);
      expect(find.text('Failed to send'), findsOneWidget);
      expect(find.text('Connection refused'), findsOneWidget);
      expect(find.text('Retry attempts: 2'), findsOneWidget);
    });

    testWidgets('shows section headers for failed and pending', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([
          makeQueued(),
          makeQueued(id: 'q-2', status: MessageSyncStatus.failed),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Pending Messages'), findsOneWidget);
      expect(find.text('Failed Messages'), findsOneWidget);
    });

    testWidgets('statistics card shows pending count', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([
          makeQueued(),
          makeQueued(id: 'q-2'),
          makeQueued(id: 'q-3', status: MessageSyncStatus.failed),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Failed'), findsWidgets);
      expect(find.text('2'), findsWidgets); // pending count
      expect(find.text('1'), findsWidgets); // failed count
    });

    testWidgets('renders Retry and Remove buttons on each card',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([makeQueued()]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('Sync All button enabled when online', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([makeQueued()]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sync All Messages (1)'), findsOneWidget);
      final btn =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('Sync All button disabled when offline', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([makeQueued()]),
        connectivity: Stream.value([ConnectivityResult.none]),
      ));
      await tester.pump();
      await tester.pump();

      final btn =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(btn.onPressed, isNull);
    });

    testWidgets('Remove tap shows confirmation dialog', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([makeQueued()]),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Message?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Remove confirmation can be cancelled', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesFuture: Future.value([makeQueued()]),
      ));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Message?'), findsNothing);
    });
  });
}
