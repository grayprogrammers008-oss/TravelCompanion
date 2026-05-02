import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/mesh_coordinator.dart';
import 'package:travel_crew/features/messaging/domain/entities/message_entity.dart';

void main() {
  group('MeshMessage', () {
    test('should create mesh message with all fields', () {
      // Arrange
      final timestamp = DateTime.now();

      // Act
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Hello via mesh!',
        messageType: MessageType.text,
        hops: ['peer-1', 'peer-2'],
        timestamp: timestamp,
        ttl: const Duration(minutes: 10),
      );

      // Assert
      expect(message.id, 'msg-123');
      expect(message.tripId, 'trip-456');
      expect(message.senderId, 'user-alice');
      expect(message.recipientId, 'user-bob');
      expect(message.content, 'Hello via mesh!');
      expect(message.hops, ['peer-1', 'peer-2']);
      expect(message.timestamp, timestamp);
      expect(message.ttl, const Duration(minutes: 10));
    });

    test('should serialize to JSON', () {
      // Arrange
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Test message',
        messageType: MessageType.text,
        hops: ['peer-1'],
        timestamp: DateTime(2025, 1, 24, 10, 30),
        ttl: const Duration(minutes: 10),
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['id'], 'msg-123');
      expect(json['tripId'], 'trip-456');
      expect(json['senderId'], 'user-alice');
      expect(json['recipientId'], 'user-bob');
      expect(json['content'], 'Test message');
      expect(json['hops'], ['peer-1']);
      expect(json['timestamp'], isNotNull);
      expect(json['ttlSeconds'], 600); // 10 minutes
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'id': 'msg-123',
        'tripId': 'trip-456',
        'senderId': 'user-alice',
        'recipientId': 'user-bob',
        'content': 'Test message',
        'hops': ['peer-1', 'peer-2'],
        'timestamp': DateTime(2025, 1, 24, 10, 30).toIso8601String(),
        'ttlSeconds': 600,
      };

      // Act
      final message = MeshMessage.fromJson(json);

      // Assert
      expect(message.id, 'msg-123');
      expect(message.tripId, 'trip-456');
      expect(message.senderId, 'user-alice');
      expect(message.recipientId, 'user-bob');
      expect(message.content, 'Test message');
      expect(message.hops, ['peer-1', 'peer-2']);
      expect(message.ttl, const Duration(seconds: 600));
    });

    test('should copy with updated hops', () {
      // Arrange
      final original = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Test message',
        messageType: MessageType.text,
        hops: ['peer-1'],
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 10),
      );

      // Act
      final updated = original.copyWith(hops: ['peer-1', 'peer-2', 'peer-3']);

      // Assert
      expect(updated.id, original.id);
      expect(updated.content, original.content);
      expect(updated.hops, ['peer-1', 'peer-2', 'peer-3']);
      expect(original.hops, ['peer-1']); // Original unchanged
    });

    test('should handle empty hops list', () {
      // Act
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Direct message',
        messageType: MessageType.text,
        hops: [],
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 10),
      );

      // Assert
      expect(message.hops, isEmpty);
    });

    test('should handle maximum hops', () {
      // Arrange
      final maxHops = List.generate(5, (i) => 'peer-$i');

      // Act
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Multi-hop message',
        messageType: MessageType.text,
        hops: maxHops,
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 10),
      );

      // Assert
      expect(message.hops.length, 5);
    });
  });

  group('MeshStatistics', () {
    test('should create statistics with all fields', () {
      // Act
      final stats = MeshStatistics(
        connectedNodes: 5,
        cachedMessages: 12,
        knownRoutes: 8,
      );

      // Assert
      expect(stats.connectedNodes, 5);
      expect(stats.cachedMessages, 12);
      expect(stats.knownRoutes, 8);
    });

    test('should handle zero values', () {
      // Act
      final stats = MeshStatistics(
        connectedNodes: 0,
        cachedMessages: 0,
        knownRoutes: 0,
      );

      // Assert
      expect(stats.connectedNodes, 0);
      expect(stats.cachedMessages, 0);
      expect(stats.knownRoutes, 0);
    });

    test('should handle large values', () {
      // Act
      final stats = MeshStatistics(
        connectedNodes: 100,
        cachedMessages: 1000,
        knownRoutes: 500,
      );

      // Assert
      expect(stats.connectedNodes, 100);
      expect(stats.cachedMessages, 1000);
      expect(stats.knownRoutes, 500);
    });
  });

  group('MeshCoordinator constants', () {
    test('should have correct MAX_HOPS', () {
      expect(MeshCoordinator.maxHops, 5);
    });

    test('should have correct MESSAGE_TTL', () {
      expect(MeshCoordinator.messageTtl, const Duration(minutes: 10));
    });
  });

  group('MeshCoordinator singleton', () {
    test('should return same instance', () {
      // Act
      final instance1 = MeshCoordinator();
      final instance2 = MeshCoordinator();

      // Assert
      expect(identical(instance1, instance2), true);
    });
  });

  group('Message TTL calculations', () {
    test('should calculate correct TTL in seconds', () {
      // Arrange
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Test',
        messageType: MessageType.text,
        hops: [],
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 5),
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['ttlSeconds'], 300); // 5 minutes = 300 seconds
    });

    test('should handle fractional TTL', () {
      // Arrange
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Test',
        messageType: MessageType.text,
        hops: [],
        timestamp: DateTime.now(),
        ttl: const Duration(seconds: 90), // 1.5 minutes
      );

      // Act
      final json = message.toJson();

      // Assert
      expect(json['ttlSeconds'], 90);
    });
  });

  group('Hop validation', () {
    test('should track multi-hop path correctly', () {
      // Arrange
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Multi-hop test',
        messageType: MessageType.text,
        hops: ['peer-1', 'peer-2', 'peer-3'],
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 10),
      );

      // Assert - Verify hop sequence
      expect(message.hops[0], 'peer-1');
      expect(message.hops[1], 'peer-2');
      expect(message.hops[2], 'peer-3');
    });

    test('should maintain hop order', () {
      // Arrange
      final originalHops = ['peer-1', 'peer-2', 'peer-3', 'peer-4'];
      final message = MeshMessage(
        id: 'msg-123',
        tripId: 'trip-456',
        senderId: 'user-alice',
        recipientId: 'user-bob',
        content: 'Order test',
        messageType: MessageType.text,
        hops: originalHops,
        timestamp: DateTime.now(),
        ttl: const Duration(minutes: 10),
      );

      // Act
      final serialized = message.toJson();
      final deserialized = MeshMessage.fromJson(serialized);

      // Assert
      expect(deserialized.hops, equals(originalHops));
    });
  });
}
