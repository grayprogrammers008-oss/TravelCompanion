import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:nearby_service/nearby_service.dart';  // Package not available on pub.dev

// Stub classes for iOS Multipeer Connectivity
// TODO: Replace with actual implementation when package is available
class NearbyService {
  Future<void> initialize({
    required String userName,
    required Strategy strategy,
    required String serviceType,
    required Callbacks callback,
  }) async {
    // Stub implementation
  }

  Future<void> startAdvertising() async {}
  Future<void> stopAdvertising() async {}
  Future<void> startBrowsing() async {}
  Future<void> stopBrowsing() async {}
  Future<void> sendMessage(String peerId, String message) async {}
  Future<void> sendFile(String peerId, String filePath) async {}
  Future<void> disconnect(String peerId) async {}
  Future<void> dispose() async {}
}

enum Strategy { p2pCluster, p2pStar, p2pPointToPoint }

class Callbacks {
  final Function(String peerId, int status)? onConnected;
  final Function(String peerId)? onDisconnected;
  final Function(String peerId, String message)? onMessageReceived;
  final Function(String peerId, String filePath)? onFileReceived;
  final Function(String peerId, String peerName)? onConnectionRequest;

  Callbacks({
    this.onConnected,
    this.onDisconnected,
    this.onMessageReceived,
    this.onFileReceived,
    this.onConnectionRequest,
  });
}

/// Multipeer Connectivity P2P Service for iOS/macOS
/// Provides high-bandwidth peer-to-peer communication using Apple's Multipeer Connectivity
/// Automatically selects Wi-Fi, peer-to-peer Wi-Fi, or Bluetooth
class MultipeerService {
  static final MultipeerService _instance = MultipeerService._internal();
  factory MultipeerService() => _instance;
  MultipeerService._internal();

  // Platform-specific instance
  final NearbyService _nearbyService = NearbyService();
  bool _isInitialized = false;
  bool _isBrowsing = false;
  bool _isAdvertising = false;

  // Current user info
  String? _userName;

  // State tracking
  final Map<String, MultipeerPeer> _discoveredPeers = {};
  final Map<String, MultipeerPeer> _connectedPeers = {};
  final StreamController<List<MultipeerPeer>> _peersController =
      StreamController<List<MultipeerPeer>>.broadcast();
  final StreamController<MultipeerMessage> _messagesController =
      StreamController<MultipeerMessage>.broadcast();
  final StreamController<MultipeerConnectionState> _connectionStateController =
      StreamController<MultipeerConnectionState>.broadcast();
  final StreamController<FileTransferProgress> _fileProgressController =
      StreamController<FileTransferProgress>.broadcast();

  // Multipeer constants
  static const String serviceType = 'travel-companion';
  static const int maxConnections = 8;
  static const Duration discoveryTimeout = Duration(seconds: 45);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isBrowsing => _isBrowsing;
  bool get isAdvertising => _isAdvertising;
  List<MultipeerPeer> get discoveredPeers => _discoveredPeers.values.toList();
  List<MultipeerPeer> get connectedPeers => _connectedPeers.values.toList();
  Stream<List<MultipeerPeer>> get peersStream => _peersController.stream;
  Stream<MultipeerMessage> get messagesStream => _messagesController.stream;
  Stream<MultipeerConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<FileTransferProgress> get fileProgressStream =>
      _fileProgressController.stream;

  /// Initialize Multipeer service (iOS/macOS only)
  Future<bool> initialize({
    required String userId,
    required String userName,
  }) async {
    if (_isInitialized) return true;

    if (!Platform.isIOS && !Platform.isMacOS) {
      debugPrint('Multipeer Connectivity is only supported on iOS/macOS');
      return false;
    }

    try {
      _userName = userName;

      // Initialize NearbyService
      await _nearbyService.initialize(
        userName: userName,
        strategy: Strategy.p2pCluster,
        serviceType: serviceType,
        callback: Callbacks(
          onConnected: (String peerId, int status) => _onConnected(peerId, userName),
          onDisconnected: _onDisconnected,
          onMessageReceived: _onMessageReceived,
          onFileReceived: _onFileReceived,
          onConnectionRequest: _onConnectionRequest,
        ),
      );

      _isInitialized = true;
      debugPrint('Multipeer service initialized for user: $userName');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize Multipeer service: $e');
      return false;
    }
  }

  /// Start advertising (make device discoverable)
  Future<bool> startAdvertising() async {
    if (!_isInitialized) {
      debugPrint('Multipeer service not initialized');
      return false;
    }

    try {
      await _nearbyService.startAdvertising();
      _isAdvertising = true;
      debugPrint('Started advertising as: $_userName');
      return true;
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    if (!_isInitialized) return;

    try {
      await _nearbyService.stopAdvertising();
      _isAdvertising = false;
      debugPrint('Stopped advertising');
    } catch (e) {
      debugPrint('Error stopping advertising: $e');
    }
  }

  /// Start browsing for nearby peers
  Future<bool> startBrowsing({Duration timeout = discoveryTimeout}) async {
    if (!_isInitialized) {
      debugPrint('Multipeer service not initialized');
      return false;
    }

    try {
      await _nearbyService.startBrowsing();
      _isBrowsing = true;
      debugPrint('Started browsing for peers');

      // Auto-stop after timeout
      Future.delayed(timeout, () async {
        await stopBrowsing();
      });

      return true;
    } catch (e) {
      debugPrint('Error starting browsing: $e');
      return false;
    }
  }

  /// Stop browsing
  Future<void> stopBrowsing() async {
    if (!_isInitialized) return;

    try {
      await _nearbyService.stopBrowsing();
      _isBrowsing = false;
      debugPrint('Stopped browsing');
    } catch (e) {
      debugPrint('Error stopping browsing: $e');
    }
  }

  /// Invite peer to connect
  Future<bool> invitePeer(String peerId) async {
    if (!_isInitialized) return false;

    final peer = _discoveredPeers[peerId];
    if (peer == null) {
      debugPrint('Peer not found: $peerId');
      return false;
    }

    try {
      // Note: invitePeer method is not available in the stub implementation
      // This would need to be implemented when the actual nearby_service package is integrated
      debugPrint('⚠️ invitePeer not implemented in stub - peer invitation skipped: $peerId');
      return true;
    } catch (e) {
      debugPrint('Error inviting peer: $e');
      return false;
    }
  }

  /// Accept connection request from peer
  Future<bool> acceptConnection(String peerId) async {
    if (!_isInitialized) return false;

    // Note: acceptConnection method is not available in the stub implementation
    // This would need to be implemented when the actual nearby_service package is integrated
    debugPrint('⚠️ acceptConnection not implemented in stub - auto-accepted: $peerId');
    return true;
  }

  /// Reject connection request from peer
  Future<bool> rejectConnection(String peerId) async {
    if (!_isInitialized) return false;

    // Note: rejectConnection method is not available in the stub implementation
    // This would need to be implemented when the actual nearby_service package is integrated
    debugPrint('⚠️ rejectConnection not implemented in stub - rejection skipped: $peerId');
    return true;
  }

  /// Disconnect from peer
  Future<void> disconnect(String peerId) async {
    if (!_isInitialized) return;

    await _nearbyService.disconnect(peerId);
    _connectedPeers.remove(peerId);
    debugPrint('Disconnected from peer: $peerId');

    _connectionStateController.add(MultipeerConnectionState(
      peerId: peerId,
      isConnected: false,
    ));
  }

  /// Disconnect from all peers
  Future<void> disconnectAll() async {
    if (!_isInitialized) return;

    // Disconnect from each peer individually
    for (final peerId in _connectedPeers.keys.toList()) {
      await _nearbyService.disconnect(peerId);
    }
    _connectedPeers.clear();
    _discoveredPeers.clear();
    debugPrint('Disconnected from all peers');

    _peersController.add([]);
  }

  /// Send text message to specific peer or all connected peers
  Future<bool> sendMessage({
    required String message,
    String? targetPeerId,
  }) async {
    if (!_isInitialized) return false;

    try {
      if (targetPeerId != null) {
        // Send to specific peer
        await _nearbyService.sendMessage(targetPeerId, message);
      } else {
        // Broadcast to all connected peers
        for (final peerId in _connectedPeers.keys) {
          await _nearbyService.sendMessage(peerId, message);
        }
      }

      debugPrint('Message sent: $message');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Send file to specific peer or all connected peers
  Future<bool> sendFile({
    required String filePath,
    required String fileName,
    String? targetPeerId,
    Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized) return false;

    try {
      if (targetPeerId != null) {
        // Send to specific peer
        await _nearbyService.sendFile(targetPeerId, filePath);
      } else {
        // Broadcast to all connected peers
        for (final peerId in _connectedPeers.keys) {
          await _nearbyService.sendFile(peerId, filePath);
        }
      }

      debugPrint('File sent: $fileName');
      return true;
    } catch (e) {
      debugPrint('Error sending file: $e');
      return false;
    }
  }

  // Callback handlers

  void _onConnected(String peerId, String peerName) {
    debugPrint('Connected to peer: $peerName ($peerId)');

    final peer = MultipeerPeer(
      id: peerId,
      name: peerName,
      lastSeen: DateTime.now(),
      isConnected: true,
    );

    _connectedPeers[peerId] = peer;
    _discoveredPeers.remove(peerId);

    _connectionStateController.add(MultipeerConnectionState(
      peerId: peerId,
      isConnected: true,
    ));

    _peersController.add(connectedPeers);
  }

  void _onDisconnected(String peerId) {
    debugPrint('Disconnected from peer: $peerId');

    _connectedPeers.remove(peerId);

    _connectionStateController.add(MultipeerConnectionState(
      peerId: peerId,
      isConnected: false,
    ));

    _peersController.add(connectedPeers);
  }

  void _onMessageReceived(String peerId, String message) {
    debugPrint('Received message from $peerId: $message');

    final msg = MultipeerMessage(
      peerId: peerId,
      content: message,
      timestamp: DateTime.now(),
      messageType: MultipeerMessageType.text,
    );

    _messagesController.add(msg);
  }

  void _onFileReceived(String peerId, String filePath) {
    debugPrint('Received file from $peerId: $filePath');

    final fileName = filePath.split('/').last;

    final msg = MultipeerMessage(
      peerId: peerId,
      content: fileName,
      timestamp: DateTime.now(),
      messageType: MultipeerMessageType.file,
      filePath: filePath,
    );

    _messagesController.add(msg);
  }

  void _onConnectionRequest(String peerId, String peerName) {
    debugPrint('Connection request from: $peerName ($peerId)');

    final peer = MultipeerPeer(
      id: peerId,
      name: peerName,
      lastSeen: DateTime.now(),
      isConnected: false,
      isPending: true,
    );

    _discoveredPeers[peerId] = peer;
    _peersController.add(discoveredPeers);

    // Auto-accept connection (can be changed to manual approval)
    acceptConnection(peerId);
  }

  /// Check if connected to specific peer
  bool isConnectedTo(String peerId) {
    return _connectedPeers.containsKey(peerId);
  }

  /// Get peer by ID
  MultipeerPeer? getPeer(String peerId) {
    return _connectedPeers[peerId] ?? _discoveredPeers[peerId];
  }

  /// Get connection statistics
  MultipeerStatistics getStatistics() {
    return MultipeerStatistics(
      connectedPeers: _connectedPeers.length,
      discoveredPeers: _discoveredPeers.length,
      isAdvertising: _isAdvertising,
      isBrowsing: _isBrowsing,
      maxConnections: maxConnections,
    );
  }

  /// Dispose resources
  void dispose() {
    stopAdvertising();
    stopBrowsing();
    disconnectAll();
    _peersController.close();
    _messagesController.close();
    _connectionStateController.close();
    _fileProgressController.close();
    _discoveredPeers.clear();
    _connectedPeers.clear();
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Multipeer Peer
class MultipeerPeer {
  final String id;
  final String name;
  final DateTime lastSeen;
  final bool isConnected;
  final bool isPending;

  MultipeerPeer({
    required this.id,
    required this.name,
    required this.lastSeen,
    this.isConnected = false,
    this.isPending = false,
  });

  String get status {
    if (isPending) return 'Pending';
    if (isConnected) return 'Connected';
    return 'Available';
  }
}

/// Multipeer Message
class MultipeerMessage {
  final String peerId;
  final String content;
  final DateTime timestamp;
  final MultipeerMessageType messageType;
  final String? filePath;

  MultipeerMessage({
    required this.peerId,
    required this.content,
    required this.timestamp,
    required this.messageType,
    this.filePath,
  });
}

enum MultipeerMessageType { text, file }

/// Multipeer Connection State
class MultipeerConnectionState {
  final String peerId;
  final bool isConnected;
  final String? errorMessage;

  MultipeerConnectionState({
    required this.peerId,
    required this.isConnected,
    this.errorMessage,
  });
}

/// File Transfer Progress
class FileTransferProgress {
  final String fileId;
  final String fileName;
  final double progress; // 0.0 to 1.0
  final bool isDownload;

  FileTransferProgress({
    required this.fileId,
    required this.fileName,
    required this.progress,
    this.isDownload = false,
  });

  int get progressPercent => (progress * 100).round();
}

/// Multipeer Statistics
class MultipeerStatistics {
  final int connectedPeers;
  final int discoveredPeers;
  final bool isAdvertising;
  final bool isBrowsing;
  final int maxConnections;

  const MultipeerStatistics({
    required this.connectedPeers,
    required this.discoveredPeers,
    required this.isAdvertising,
    required this.isBrowsing,
    required this.maxConnections,
  });
}
