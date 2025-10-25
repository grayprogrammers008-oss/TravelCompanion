import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/conflict_resolution_engine.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';

void main() {
  late ConflictResolutionEngine engine;

  setUp(() {
    engine = ConflictResolutionEngine();
    engine.initialize();
  });

  tearDown(() {
    engine.resetStatistics();
  });

  group('ConflictResolutionEngine - Initialization', () {
    test('✅ Positive: Engine initializes with default strategies', () {
      final newEngine = ConflictResolutionEngine();
      newEngine.initialize();

      // Verify statistics start at zero
      final stats = newEngine.getStatistics();
      expect(stats.totalConflicts, 0);
      expect(stats.resolvedByTimestamp, 0);
      expect(stats.resolvedBySource, 0);
      expect(stats.resolvedByContent, 0);
      expect(stats.manualResolution, 0);
    });

    test('✅ Positive: Engine is singleton', () {
      final engine1 = ConflictResolutionEngine();
      final engine2 = ConflictResolutionEngine();

      expect(engine1, same(engine2));
    });
  });

  group('ConflictResolutionEngine - resolveConflict() Latest Timestamp', () {
    final baseDate = DateTime(2025, 1, 24, 10, 0);

    test('✅ Positive: Remote version wins with newer timestamp', () async {
      final localMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Local version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate, // Older timestamp
      );

      final remoteMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Remote version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(minutes: 5)), // Newer timestamp
      );

      final result = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'server',
      );

      expect(result.winner, ConflictWinner.remote);
      expect(result.resolvedMessage.message, 'Remote version');
      expect(result.resolutionMethod, ResolutionMethod.timestamp);
      expect(result.explanation, contains('Remote version is newer'));
      expect(result.hasConflict, true);
    });

    test('✅ Positive: Local version wins with newer timestamp', () async {
      final localMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Local version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(minutes: 10)), // Newer timestamp
      );

      final remoteMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Remote version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate, // Older timestamp
      );

      final result = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'server',
      );

      expect(result.winner, ConflictWinner.local);
      expect(result.resolvedMessage.message, 'Local version');
      expect(result.resolutionMethod, ResolutionMethod.timestamp);
      expect(result.explanation, contains('Local version is newer'));
    });

    test('✅ Positive: No conflict when messages are identical', () async {
      final message = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Same message',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final result = await engine.resolveMessageConflict(
        localVersion: message,
        remoteVersion: message,
        source: 'server',
      );

      expect(result.winner, ConflictWinner.noConflict);
      expect(result.hasConflict, false);
      expect(result.explanation, contains('No conflict detected'));
    });
  });

  group('ConflictResolutionEngine - Source Priority', () {
    final baseDate = DateTime(2025, 1, 24, 10, 0);

    test('✅ Positive: Server source has highest priority', () async {
      final localMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Local version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate, // Same timestamp
      );

      final remoteMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Server version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate, // Same timestamp
      );

      final result = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'server',
      );

      expect(result.winner, ConflictWinner.remote);
      expect(result.resolutionMethod, ResolutionMethod.source);
      expect(result.explanation, contains('server'));
    });

    test('✅ Positive: WiFi Direct has priority over BLE', () async {
      final localMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Local version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remoteMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'WiFi Direct version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final result = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'wifi_direct',
      );

      expect(result.winner, ConflictWinner.remote);
      expect(result.resolutionMethod, ResolutionMethod.source);
    });

    test('✅ Positive: Multipeer has priority over BLE', () async {
      final localMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Local version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remoteMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Multipeer version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final result = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'multipeer',
      );

      expect(result.winner, ConflictWinner.remote);
      expect(result.resolutionMethod, ResolutionMethod.source);
    });

    test('✅ Positive: Local version retained when source has no priority', () async {
      final localMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Local version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remoteMessage = MessageEntity(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-789',
        message: 'Unknown source version',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final result = await engine.resolveMessageConflict(
        localVersion: localMessage,
        remoteVersion: remoteMessage,
        source: 'unknown_source',
      );

      expect(result.winner, ConflictWinner.local);
      expect(result.resolutionMethod, ResolutionMethod.source);
      expect(result.explanation, contains('Local version retained'));
    });
  });

  group('ConflictResolutionEngine - mergeMessages() Reactions', () {
    final baseDate = DateTime(2025, 1, 24, 10, 0);

    test('✅ Positive: Merge combines non-conflicting reactions', () async {
      final localReactions = [
        MessageReaction(
          emoji: '👍',
          userId: 'user-001',
          createdAt: baseDate,
        ),
      ];

      final remoteReactions = [
        MessageReaction(
          emoji: '❤️',
          userId: 'user-002',
          createdAt: baseDate,
        ),
      ];

      final merged = await engine.resolveReactionConflict(
        localReactions: localReactions,
        remoteReactions: remoteReactions,
        source: 'server',
      );

      expect(merged.length, 2);
      expect(merged.any((r) => r.emoji == '👍' && r.userId == 'user-001'), true);
      expect(merged.any((r) => r.emoji == '❤️' && r.userId == 'user-002'), true);
    });

    test('✅ Positive: Merge removes duplicate reactions', () async {
      final localReactions = [
        MessageReaction(
          emoji: '👍',
          userId: 'user-001',
          createdAt: baseDate,
        ),
      ];

      final remoteReactions = [
        MessageReaction(
          emoji: '👍',
          userId: 'user-001',
          createdAt: baseDate.add(const Duration(seconds: 5)), // Newer
        ),
      ];

      final merged = await engine.resolveReactionConflict(
        localReactions: localReactions,
        remoteReactions: remoteReactions,
        source: 'server',
      );

      // Should only have one reaction, the newer one
      expect(merged.length, 1);
      expect(merged.first.emoji, '👍');
      expect(merged.first.userId, 'user-001');
      expect(merged.first.createdAt, baseDate.add(const Duration(seconds: 5)));
    });

    test('❌ Negative: Conflicting reaction edits are resolved (newer wins)', () async {
      final olderReaction = MessageReaction(
        emoji: '👍',
        userId: 'user-001',
        createdAt: baseDate,
      );

      final newerReaction = MessageReaction(
        emoji: '👍',
        userId: 'user-001',
        createdAt: baseDate.add(const Duration(minutes: 1)),
      );

      final merged = await engine.resolveReactionConflict(
        localReactions: [olderReaction],
        remoteReactions: [newerReaction],
        source: 'server',
      );

      expect(merged.length, 1);
      expect(merged.first.createdAt, newerReaction.createdAt);
    });

    test('❌ Negative: Null/empty reaction lists handled', () async {
      final merged = await engine.resolveReactionConflict(
        localReactions: [],
        remoteReactions: [],
        source: 'server',
      );

      expect(merged, isEmpty);
    });
  });

  group('ConflictResolutionEngine - Read Status Conflicts', () {
    test('✅ Positive: Read status merge creates union of readers', () async {
      final localReadBy = ['user-001', 'user-002'];
      final remoteReadBy = ['user-002', 'user-003'];

      final merged = await engine.resolveReadStatusConflict(
        localReadBy: localReadBy,
        remoteReadBy: remoteReadBy,
      );

      expect(merged.length, 3);
      expect(merged.contains('user-001'), true);
      expect(merged.contains('user-002'), true);
      expect(merged.contains('user-003'), true);
    });

    test('✅ Positive: Read status merge handles empty local list', () async {
      final localReadBy = <String>[];
      final remoteReadBy = ['user-001', 'user-002'];

      final merged = await engine.resolveReadStatusConflict(
        localReadBy: localReadBy,
        remoteReadBy: remoteReadBy,
      );

      expect(merged.length, 2);
      expect(merged.contains('user-001'), true);
      expect(merged.contains('user-002'), true);
    });

    test('✅ Positive: Read status merge handles empty remote list', () async {
      final localReadBy = ['user-001', 'user-002'];
      final remoteReadBy = <String>[];

      final merged = await engine.resolveReadStatusConflict(
        localReadBy: localReadBy,
        remoteReadBy: remoteReadBy,
      );

      expect(merged.length, 2);
      expect(merged.contains('user-001'), true);
      expect(merged.contains('user-002'), true);
    });

    test('✅ Positive: Read status merge removes duplicates', () async {
      final localReadBy = ['user-001', 'user-002', 'user-001']; // Duplicate
      final remoteReadBy = ['user-002', 'user-003'];

      final merged = await engine.resolveReadStatusConflict(
        localReadBy: localReadBy,
        remoteReadBy: remoteReadBy,
      );

      expect(merged.length, 3);
      expect(merged.where((id) => id == 'user-001').length, 1);
    });
  });

  group('ConflictResolutionEngine - Deletion Conflicts', () {
    test('✅ Positive: Deletion always wins over non-deletion', () async {
      final deleted = await engine.resolveDeletionConflict(
        localDeleted: true,
        remoteDeleted: false,
        localDeletedAt: DateTime.now(),
        remoteDeletedAt: null,
      );

      expect(deleted, true);
    });

    test('✅ Positive: Remote deletion propagates to local', () async {
      final deleted = await engine.resolveDeletionConflict(
        localDeleted: false,
        remoteDeleted: true,
        localDeletedAt: null,
        remoteDeletedAt: DateTime.now(),
      );

      expect(deleted, true);
    });

    test('✅ Positive: Both deleted remains deleted', () async {
      final deleted = await engine.resolveDeletionConflict(
        localDeleted: true,
        remoteDeleted: true,
        localDeletedAt: DateTime.now(),
        remoteDeletedAt: DateTime.now(),
      );

      expect(deleted, true);
    });

    test('✅ Positive: Neither deleted remains not deleted', () async {
      final deleted = await engine.resolveDeletionConflict(
        localDeleted: false,
        remoteDeleted: false,
        localDeletedAt: null,
        remoteDeletedAt: null,
      );

      expect(deleted, false);
    });
  });

  group('ConflictResolutionEngine - Statistics', () {
    final baseDate = DateTime(2025, 1, 24, 10, 0);

    test('✅ Positive: Statistics track resolution methods', () async {
      engine.resetStatistics();

      // Create conflict resolved by timestamp
      final local1 = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Local',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remote1 = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Remote',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(minutes: 1)),
      );

      await engine.resolveMessageConflict(
        localVersion: local1,
        remoteVersion: remote1,
        source: 'server',
      );

      final stats = engine.getStatistics();
      expect(stats.totalConflicts, 1);
      expect(stats.resolvedByTimestamp, 1);
    });

    test('✅ Positive: Statistics rates are calculated correctly', () async {
      engine.resetStatistics();

      final local = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Local',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remote = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Remote',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(minutes: 1)),
      );

      // Resolve 2 conflicts
      await engine.resolveMessageConflict(
        localVersion: local,
        remoteVersion: remote,
        source: 'server',
      );

      await engine.resolveMessageConflict(
        localVersion: local,
        remoteVersion: remote,
        source: 'server',
      );

      final stats = engine.getStatistics();
      expect(stats.totalConflicts, 2);
      expect(stats.timestampRate, 1.0); // 2/2 = 100%
    });

    test('✅ Positive: Reset statistics clears all counters', () {
      final local = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Local',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remote = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Remote',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(minutes: 1)),
      );

      engine.resolveMessageConflict(
        localVersion: local,
        remoteVersion: remote,
        source: 'server',
      );

      engine.resetStatistics();

      final stats = engine.getStatistics();
      expect(stats.totalConflicts, 0);
      expect(stats.resolvedByTimestamp, 0);
      expect(stats.resolvedBySource, 0);
      expect(stats.resolvedByContent, 0);
    });
  });

  group('ConflictResolutionEngine - Edge Cases', () {
    final baseDate = DateTime(2025, 1, 24, 10, 0);

    test('❌ Negative: Different message IDs should still resolve', () async {
      final local = MessageEntity(
        id: 'msg-local',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Message',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remote = MessageEntity(
        id: 'msg-remote', // Different ID
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Message',
        messageType: MessageType.text,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(minutes: 1)),
      );

      final result = await engine.resolveMessageConflict(
        localVersion: local,
        remoteVersion: remote,
        source: 'server',
      );

      // Should resolve by timestamp even with different IDs
      expect(result.winner, ConflictWinner.remote);
      expect(result.resolutionMethod, ResolutionMethod.timestamp);
    });

    test('❌ Negative: Complex message with all fields', () async {
      final local = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Complex message',
        messageType: MessageType.image,
        replyToId: 'msg-parent',
        attachmentUrl: 'https://example.com/image.jpg',
        reactions: [
          MessageReaction(emoji: '👍', userId: 'user-2', createdAt: baseDate),
        ],
        readBy: ['user-1', 'user-2'],
        isDeleted: false,
        createdAt: baseDate,
        updatedAt: baseDate,
        senderName: 'John Doe',
        senderAvatarUrl: 'https://example.com/avatar.jpg',
      );

      final remote = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Complex message updated',
        messageType: MessageType.image,
        replyToId: 'msg-parent',
        attachmentUrl: 'https://example.com/image.jpg',
        reactions: [
          MessageReaction(emoji: '❤️', userId: 'user-3', createdAt: baseDate),
        ],
        readBy: ['user-1', 'user-3'],
        isDeleted: false,
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(seconds: 30)),
        senderName: 'John Doe',
        senderAvatarUrl: 'https://example.com/avatar.jpg',
      );

      final result = await engine.resolveMessageConflict(
        localVersion: local,
        remoteVersion: remote,
        source: 'server',
      );

      expect(result.winner, ConflictWinner.remote);
      expect(result.resolvedMessage.message, 'Complex message updated');
    });

    test('❌ Negative: Null message fields handled correctly', () async {
      final local = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: null, // Null message
        messageType: MessageType.image,
        replyToId: null,
        attachmentUrl: null,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      final remote = MessageEntity(
        id: 'msg-1',
        tripId: 'trip-1',
        senderId: 'user-1',
        message: 'Updated',
        messageType: MessageType.image,
        replyToId: null,
        attachmentUrl: null,
        reactions: const [],
        readBy: const [],
        createdAt: baseDate,
        updatedAt: baseDate.add(const Duration(seconds: 10)),
      );

      final result = await engine.resolveMessageConflict(
        localVersion: local,
        remoteVersion: remote,
        source: 'server',
      );

      expect(result.winner, ConflictWinner.remote);
      expect(result.resolvedMessage.message, 'Updated');
    });
  });

  group('ConflictResolutionEngine - Custom Strategies', () {
    test('✅ Positive: Can register custom strategy', () {
      final customStrategy = MessageConflictStrategy();
      engine.registerStrategy('custom', customStrategy);

      // Strategy is registered (no easy way to verify without accessing private field)
      // But we can verify it doesn't throw
      expect(() => engine.registerStrategy('custom', customStrategy), returnsNormally);
    });
  });
}
