import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/messaging/data/services/p2p_connection_manager.dart';

void main() {
  group('P2PPeer', () {
    test('should create P2PPeer with WiFi Direct transport', () {
      // Arrange & Act
      final peer = P2PPeer(
        id: 'peer-123',
        name: 'Test Peer',
        lastSeen: DateTime.now(),
        isConnected: true,
        transportType: P2PTransportType.wifiDirect,
      );

      // Assert
      expect(peer.id, 'peer-123');
      expect(peer.name, 'Test Peer');
      expect(peer.isConnected, true);
      expect(peer.transportType, P2PTransportType.wifiDirect);
      expect(peer.status, 'Connected');
      expect(peer.transportName, 'WiFi Direct');
    });

    test('should create P2PPeer with Multipeer transport', () {
      // Arrange & Act
      final peer = P2PPeer(
        id: 'peer-456',
        name: 'iOS Peer',
        lastSeen: DateTime.now(),
        isConnected: false,
        transportType: P2PTransportType.multipeer,
      );

      // Assert
      expect(peer.transportType, P2PTransportType.multipeer);
      expect(peer.status, 'Available');
      expect(peer.transportName, 'Multipeer');
    });

    test('should return correct status for connected peer', () {
      // Arrange
      final connectedPeer = P2PPeer(
        id: 'peer-1',
        name: 'Connected',
        lastSeen: DateTime.now(),
        isConnected: true,
        transportType: P2PTransportType.wifiDirect,
      );

      // Assert
      expect(connectedPeer.status, 'Connected');
    });

    test('should return correct status for available peer', () {
      // Arrange
      final availablePeer = P2PPeer(
        id: 'peer-2',
        name: 'Available',
        lastSeen: DateTime.now(),
        isConnected: false,
        transportType: P2PTransportType.wifiDirect,
      );

      // Assert
      expect(availablePeer.status, 'Available');
    });
  });

  group('P2PMessage', () {
    test('should create text message', () {
      // Arrange & Act
      final message = P2PMessage(
        peerId: 'peer-123',
        content: 'Hello P2P!',
        timestamp: DateTime.now(),
        messageType: P2PMessageType.text,
      );

      // Assert
      expect(message.peerId, 'peer-123');
      expect(message.content, 'Hello P2P!');
      expect(message.messageType, P2PMessageType.text);
      expect(message.filePath, isNull);
    });

    test('should create file message', () {
      // Arrange & Act
      final message = P2PMessage(
        peerId: 'peer-456',
        content: 'photo.jpg',
        timestamp: DateTime.now(),
        messageType: P2PMessageType.file,
        filePath: '/path/to/photo.jpg',
      );

      // Assert
      expect(message.messageType, P2PMessageType.file);
      expect(message.filePath, '/path/to/photo.jpg');
    });

    test('should handle empty message content', () {
      // Arrange & Act
      final message = P2PMessage(
        peerId: 'peer-789',
        content: '',
        timestamp: DateTime.now(),
        messageType: P2PMessageType.text,
      );

      // Assert
      expect(message.content, isEmpty);
    });

    test('should handle large message content', () {
      // Arrange
      final largeContent = 'A' * 10000;

      // Act
      final message = P2PMessage(
        peerId: 'peer-999',
        content: largeContent,
        timestamp: DateTime.now(),
        messageType: P2PMessageType.text,
      );

      // Assert
      expect(message.content.length, 10000);
    });
  });

  group('P2PConnectionState', () {
    test('should create connected state', () {
      // Arrange & Act
      final state = P2PConnectionState(
        peerId: 'peer-123',
        isConnected: true,
      );

      // Assert
      expect(state.peerId, 'peer-123');
      expect(state.isConnected, true);
      expect(state.errorMessage, isNull);
    });

    test('should create disconnected state with error', () {
      // Arrange & Act
      final state = P2PConnectionState(
        peerId: 'peer-456',
        isConnected: false,
        errorMessage: 'Connection timeout',
      );

      // Assert
      expect(state.isConnected, false);
      expect(state.errorMessage, 'Connection timeout');
    });
  });

  group('P2PFileProgress', () {
    test('should track file upload progress', () {
      // Arrange & Act
      final progress = P2PFileProgress(
        fileId: 'file-123',
        fileName: 'document.pdf',
        progress: 0.5,
        isDownload: false,
      );

      // Assert
      expect(progress.fileId, 'file-123');
      expect(progress.fileName, 'document.pdf');
      expect(progress.progress, 0.5);
      expect(progress.isDownload, false);
      expect(progress.progressPercent, 50);
    });

    test('should track file download progress', () {
      // Arrange & Act
      final progress = P2PFileProgress(
        fileId: 'file-456',
        fileName: 'image.jpg',
        progress: 0.75,
        isDownload: true,
      );

      // Assert
      expect(progress.isDownload, true);
      expect(progress.progressPercent, 75);
    });

    test('should handle 0% progress', () {
      // Arrange & Act
      final progress = P2PFileProgress(
        fileId: 'file-789',
        fileName: 'video.mp4',
        progress: 0.0,
        isDownload: true,
      );

      // Assert
      expect(progress.progressPercent, 0);
    });

    test('should handle 100% progress', () {
      // Arrange & Act
      final progress = P2PFileProgress(
        fileId: 'file-999',
        fileName: 'complete.zip',
        progress: 1.0,
        isDownload: false,
      );

      // Assert
      expect(progress.progressPercent, 100);
    });

    test('should round progress percentage correctly', () {
      // Arrange & Act
      final progress1 = P2PFileProgress(
        fileId: 'file-1',
        fileName: 'test.txt',
        progress: 0.334,
        isDownload: false,
      );

      final progress2 = P2PFileProgress(
        fileId: 'file-2',
        fileName: 'test.txt',
        progress: 0.336,
        isDownload: false,
      );

      // Assert
      expect(progress1.progressPercent, 33); // Rounds down
      expect(progress2.progressPercent, 34); // Rounds up
    });
  });

  group('P2PTransportType', () {
    test('should have correct transport types', () {
      // Assert
      expect(P2PTransportType.values.length, 3);
      expect(P2PTransportType.values, contains(P2PTransportType.none));
      expect(P2PTransportType.values, contains(P2PTransportType.wifiDirect));
      expect(P2PTransportType.values, contains(P2PTransportType.multipeer));
    });
  });

  group('P2PStatistics', () {
    test('should create WiFi Direct statistics', () {
      // Arrange & Act
      const stats = P2PStatistics(
        connectedPeers: 3,
        discoveredPeers: 5,
        transportType: P2PTransportType.wifiDirect,
        isHost: true,
        maxConnections: 8,
      );

      // Assert
      expect(stats.connectedPeers, 3);
      expect(stats.discoveredPeers, 5);
      expect(stats.transportType, P2PTransportType.wifiDirect);
      expect(stats.isHost, true);
      expect(stats.maxConnections, 8);
      expect(stats.isAdvertising, isNull);
      expect(stats.isBrowsing, isNull);
    });

    test('should create Multipeer statistics', () {
      // Arrange & Act
      const stats = P2PStatistics(
        connectedPeers: 2,
        discoveredPeers: 4,
        transportType: P2PTransportType.multipeer,
        isAdvertising: true,
        isBrowsing: false,
        maxConnections: 8,
      );

      // Assert
      expect(stats.transportType, P2PTransportType.multipeer);
      expect(stats.isAdvertising, true);
      expect(stats.isBrowsing, false);
      expect(stats.isHost, isNull);
    });

    test('should handle zero connections', () {
      // Arrange & Act
      const stats = P2PStatistics(
        connectedPeers: 0,
        discoveredPeers: 0,
        transportType: P2PTransportType.none,
        maxConnections: 0,
      );

      // Assert
      expect(stats.connectedPeers, 0);
      expect(stats.discoveredPeers, 0);
    });

    test('should handle maximum connections', () {
      // Arrange & Act
      const stats = P2PStatistics(
        connectedPeers: 8,
        discoveredPeers: 10,
        transportType: P2PTransportType.wifiDirect,
        isHost: true,
        maxConnections: 8,
      );

      // Assert
      expect(stats.connectedPeers, 8);
      expect(stats.connectedPeers, equals(stats.maxConnections));
    });
  });

  group('P2PConnectionManager singleton', () {
    test('should return same instance', () {
      // Act
      final instance1 = P2PConnectionManager();
      final instance2 = P2PConnectionManager();

      // Assert
      expect(identical(instance1, instance2), true);
    });
  });
}
