import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/ble_service.dart';

void main() {
  group('BLEPeer', () {
    test('should calculate signal strength correctly', () {
      // Excellent signal
      final excellentPeer = BLEPeer(
        id: 'peer-1',
        name: 'Test Peer',
        device: null as dynamic, // Mock
        rssi: -45,
        lastSeen: DateTime.now(),
      );
      expect(excellentPeer.signalStrength, 'Excellent');

      // Good signal
      final goodPeer = BLEPeer(
        id: 'peer-2',
        name: 'Test Peer',
        device: null as dynamic,
        rssi: -55,
        lastSeen: DateTime.now(),
      );
      expect(goodPeer.signalStrength, 'Good');

      // Fair signal
      final fairPeer = BLEPeer(
        id: 'peer-3',
        name: 'Test Peer',
        device: null as dynamic,
        rssi: -65,
        lastSeen: DateTime.now(),
      );
      expect(fairPeer.signalStrength, 'Fair');

      // Weak signal
      final weakPeer = BLEPeer(
        id: 'peer-4',
        name: 'Test Peer',
        device: null as dynamic,
        rssi: -75,
        lastSeen: DateTime.now(),
      );
      expect(weakPeer.signalStrength, 'Weak');
    });

    test('should estimate distance from RSSI', () {
      // Arrange
      final closePeer = BLEPeer(
        id: 'peer-1',
        name: 'Close Peer',
        device: null as dynamic,
        rssi: -50, // At reference distance (1m)
        lastSeen: DateTime.now(),
      );

      final farPeer = BLEPeer(
        id: 'peer-2',
        name: 'Far Peer',
        device: null as dynamic,
        rssi: -90, // Much farther
        lastSeen: DateTime.now(),
      );

      // Act & Assert
      expect(closePeer.estimatedDistance, lessThan(farPeer.estimatedDistance));
      expect(closePeer.estimatedDistance, greaterThan(0));
      expect(farPeer.estimatedDistance, greaterThan(0));
    });

    test('should create BLEPeer with required fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final peer = BLEPeer(
        id: 'peer-123',
        name: 'Test User',
        device: null as dynamic,
        rssi: -60,
        lastSeen: now,
      );

      // Assert
      expect(peer.id, 'peer-123');
      expect(peer.name, 'Test User');
      expect(peer.rssi, -60);
      expect(peer.lastSeen, now);
    });
  });

  group('BLEMessage', () {
    test('should create BLEMessage with all fields', () {
      // Arrange
      final timestamp = DateTime.now();

      // Act
      final message = BLEMessage(
        peerId: 'peer-123',
        content: 'Hello, BLE!',
        timestamp: timestamp,
      );

      // Assert
      expect(message.peerId, 'peer-123');
      expect(message.content, 'Hello, BLE!');
      expect(message.timestamp, timestamp);
    });

    test('should handle empty content', () {
      // Act
      final message = BLEMessage(
        peerId: 'peer-123',
        content: '',
        timestamp: DateTime.now(),
      );

      // Assert
      expect(message.content, isEmpty);
    });

    test('should handle large content', () {
      // Arrange
      final largeContent = 'A' * 10000;

      // Act
      final message = BLEMessage(
        peerId: 'peer-123',
        content: largeContent,
        timestamp: DateTime.now(),
      );

      // Assert
      expect(message.content.length, 10000);
    });
  });

  group('BLEConnectionState', () {
    test('should create connection state for connected peer', () {
      // Act
      final state = BLEConnectionState(
        peerId: 'peer-123',
        isConnected: true,
      );

      // Assert
      expect(state.peerId, 'peer-123');
      expect(state.isConnected, true);
    });

    test('should create connection state for disconnected peer', () {
      // Act
      final state = BLEConnectionState(
        peerId: 'peer-456',
        isConnected: false,
      );

      // Assert
      expect(state.peerId, 'peer-456');
      expect(state.isConnected, false);
    });
  });

  group('BLEService UUIDs', () {
    test('should have correct service UUID', () {
      expect(BLEService.serviceUuid, '6e400001-b5a3-f393-e0a9-e50e24dcca9e');
    });

    test('should have correct TX characteristic UUID', () {
      expect(
        BLEService.txCharacteristicUuid,
        '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
      );
    });

    test('should have correct RX characteristic UUID', () {
      expect(
        BLEService.rxCharacteristicUuid,
        '6e400003-b5a3-f393-e0a9-e50e24dcca9e',
      );
    });

    test('UUIDs should be unique', () {
      final uuids = {
        BLEService.serviceUuid,
        BLEService.txCharacteristicUuid,
        BLEService.rxCharacteristicUuid,
      };

      expect(uuids.length, 3);
    });
  });

  group('BLEService singleton', () {
    test('should return same instance', () {
      // Act
      final instance1 = BLEService();
      final instance2 = BLEService();

      // Assert
      expect(identical(instance1, instance2), true);
    });
  });
}
