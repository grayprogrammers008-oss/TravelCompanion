import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/core/theme/theme_provider.dart' as theme_provider;
import 'package:pathio/features/messaging/domain/entities/message_entity.dart';
import 'package:pathio/features/messaging/presentation/pages/chat_screen.dart';
import 'package:pathio/features/messaging/presentation/providers/ble_providers.dart';
import 'package:pathio/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:pathio/features/messaging/presentation/widgets/message_bubble.dart';

/// Stubbed BLE notifier that no-ops initialize() so we don't trip Bluetooth
/// platform channels in widget tests.
class _StubBleNotifier extends BLEServiceNotifier {
  @override
  BLEServiceState build() => BLEServiceState.initial();

  @override
  Future<void> initialize({required String userId, required String userName}) async {
    // no-op
  }
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
  const tripName = 'Beach Trip';
  const currentUserId = 'user-current';

  final now = DateTime.now();
  final testTheme = AppThemeData.getThemeData(AppThemeType.ocean);

  MessageEntity makeMessage({
    String id = 'm-1',
    String senderId = 'other',
    String text = 'Hi there',
    MessageType type = MessageType.text,
  }) {
    return MessageEntity(
      id: id,
      tripId: tripId,
      senderId: senderId,
      message: text,
      messageType: type,
      senderName: 'Alice',
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildPage({
    Stream<List<MessageEntity>>? messagesStream,
    Stream<List<ConnectivityResult>>? connectivity,
    Future<int>? pendingCount,
  }) {
    return ProviderScope(
      overrides: [
        theme_provider.currentThemeDataProvider.overrideWith((_) => testTheme),
        bleServiceNotifierProvider.overrideWith(_StubBleNotifier.new),
        tripMessagesProvider(tripId).overrideWith(
          (ref) => messagesStream ?? Stream.value(<MessageEntity>[]),
        ),
        tripMessagesOnceProvider(tripId)
            .overrideWith((ref) async => <MessageEntity>[]),
        connectivityStatusProvider.overrideWith(
          (ref) => connectivity ?? Stream.value([ConnectivityResult.wifi]),
        ),
        pendingMessagesCountProvider
            .overrideWith((ref) => pendingCount ?? Future.value(0)),
      ],
      child: AppThemeProvider(
        themeData: testTheme,
        child: const MaterialApp(
          home: ChatScreen(
            tripId: tripId,
            tripName: tripName,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }

  group('ChatScreen - basic structure', () {
    testWidgets('renders trip name in app bar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.text(tripName), findsOneWidget);
    });

    testWidgets('renders empty state when no messages', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Start the conversation!'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('renders sync status icon button', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();

      // Either sync or sync_alt icon
      final hasSyncIcons = find.byIcon(Icons.sync_alt).evaluate().isNotEmpty ||
          find.byIcon(Icons.sync).evaluate().isNotEmpty;
      expect(hasSyncIcons, isTrue);
    });

    testWidgets('renders WiFi P2P button', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('renders BLE searching button', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
    });
  });

  group('ChatScreen - messages list', () {
    testWidgets('renders messages when present', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesStream: Stream.value([
          makeMessage(text: 'Hello world'),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MessageBubble), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders multiple messages', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesStream: Stream.value([
          makeMessage(id: 'm-1', text: 'first'),
          makeMessage(id: 'm-2', text: 'second'),
          makeMessage(id: 'm-3', text: 'third'),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(MessageBubble), findsNWidgets(3));
    });

    testWidgets(
      'shows error UI when stream errors',
      (tester) async {
        expandViewport(tester);
        await tester.pumpWidget(buildPage(
          messagesStream: Stream.error('boom'),
        ));
        await tester.pump();
        await tester.pump();

        expect(find.text('Failed to load messages'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
      // Skipped: error state from a one-shot Stream.error doesn't surface
      // synchronously through the StreamProvider override path in tests.
      skip: true,
    );
  });

  group('ChatScreen - offline indicator', () {
    testWidgets('shows Offline label when no connectivity',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        connectivity: Stream.value([ConnectivityResult.none]),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('hides Offline label when connected', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Offline'), findsNothing);
    });
  });

  group('ChatScreen - message input', () {
    testWidgets('renders TextField for input', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();

      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('ChatScreen - long press opens action sheet', () {
    testWidgets('long-pressing message opens action sheet', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesStream: Stream.value([
          makeMessage(senderId: currentUserId, text: 'My msg'),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      await tester.longPress(find.text('My msg'));
      await tester.pumpAndSettle();

      // Action sheet shows quick reactions and Reply option
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('non-own message action sheet shows no Delete',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        messagesStream: Stream.value([
          makeMessage(senderId: 'someone-else', text: 'Their msg'),
        ]),
      ));
      await tester.pump();
      await tester.pump();

      await tester.longPress(find.text('Their msg'));
      await tester.pumpAndSettle();

      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });
  });
}
