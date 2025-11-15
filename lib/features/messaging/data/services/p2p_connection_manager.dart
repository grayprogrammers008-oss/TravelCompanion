import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'wifi_direct_service.dart';
import 'multipeer_service.dart';
import 'encryption_service.dart';

/// Unified P2P Connection Manager
/// Manages both WiFi Direct (Android) and Multipeer Connectivity (iOS)
/// Provides platform-agnostic API for high-bandwidth P2P communication
class P2PConnectionManager {
  static final P2PConnectionManager _instance = P2PConnectionManager._internal();
  factory P2PConnectionManager() => _instance;
  P2PConnectionManager._internal();

  // Services
  final WiFiDirectService _wifiDirectService = WiFiDirectService();
  final MultipeerService _multipeerService = MultipeerService();
  final EncryptionService _encryptionService = EncryptionService();

  bool _isInitialized = false;
  String? _userId;
  String? _userName;

  // Unified streams
  final StreamController<List<P2PPeer>> _peersController =
      StreamController<List<P2PPeer>>.broadcast();
  final StreamController<P2PMessage> _messagesController =
      StreamController<P2PMessage>.broadcast();
  final StreamController<P2PConnectionState> _connectionStateController =
      StreamController<P2PConnectionState>.broadcast();
  final StreamController<P2PFileProgress> _fileProgressController =
      StreamController<P2PFileProgress>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS || Platform.isMacOS;
  P2PTransportType get transportType =>
      isAndroid ? P2PTransportType.wifiDirect : P2PTransportType.multipeer;

  Stream<List<P2PPeer>> get peersStream => _peersController.stream;
  Stream<P2PMessage> get messagesStream => _messagesController.stream;
  Stream<P2PConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<P2PFileProgress> get fileProgressStream =>
      _fileProgressController.stream;

  List<P2PPeer> get connectedPeers {
    if (isAndroid) {
      return _wifiDirectService.connectedPeers
          .map((p) => P2PPeer.fromWifiDirect(p))
          .toList();
    } else if (isIOS) {
      return _multipeerService.connectedPeers
          .map((p) => P2PPeer.fromMultipeer(p))
          .toList();
    }
    return [];
  }

  List<P2PPeer> get discoveredPeers {
    if (isAndroid) {
      return _wifiDirectService.discoveredPeers
          .map((p) => P2PPeer.fromWifiDirect(p))
          .toList();
    } else if (isIOS) {
      return _multipeerService.discoveredPeers
          .map((p) => P2PPeer.fromMultipeer(p))
          .toList();
    }
    return [];
  }

  /// Initialize P2P connection manager
  Future<bool> initialize({
    required String userId,
    required String userName,
  }) async {
    if (_isInitialized) return true;

    _userId = userId;
    _userName = userName;

    try {
      // Initialize encryption
      await _encryptionService.initialize();

      // Initialize platform-specific service
      bool success = false;

      if (Platform.isAndroid) {
        success = await _wifiDirectService.initialize();
        if (success) {
          _subscribeToWifiDirectEvents();
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        success = await _multipeerService.initialize(
          userId: userId,
          userName: userName,
        );
        if (success) {
          _subscribeToMultipeerEvents();
        }
      }

      _isInitialized = success;
      debugPrint('P2P Connection Manager initialized (${transportType.name})');
      return success;
    } catch (e) {
      debugPrint('Error initializing P2P Connection Manager: $e');
      return false;
    }
  }

  /// Subscribe to WiFi Direct events
  void _subscribeToWifiDirectEvents() {
    _wifiDirectService.peersStream.listen((peers) {
      final p2pPeers = peers.map((p) => P2PPeer.fromWifiDirect(p)).toList();
      _peersController.add(p2pPeers);
    });

    _wifiDirectService.messagesStream.listen((message) {
      final p2pMessage = P2PMessage.fromWifiDirect(message);
      _messagesController.add(p2pMessage);
    });

    _wifiDirectService.connectionStateStream.listen((state) {
      _connectionStateController.add(P2PConnectionState(
        peerId: state.peerId,
        isConnected: state.isConnected,
        errorMessage: state.errorMessage,
      ));
    });

    _wifiDirectService.fileProgressStream.listen((progress) {
      _fileProgressController.add(P2PFileProgress(
        fileId: progress.fileId,
        fileName: progress.fileName,
        progress: progress.progress,
        isDownload: progress.isDownload,
      ));
    });
  }

  /// Subscribe to Multipeer events
  void _subscribeToMultipeerEvents() {
    _multipeerService.peersStream.listen((peers) {
      final p2pPeers = peers.map((p) => P2PPeer.fromMultipeer(p)).toList();
      _peersController.add(p2pPeers);
    });

    _multipeerService.messagesStream.listen((message) {
      final p2pMessage = P2PMessage.fromMultipeer(message);
      _messagesController.add(p2pMessage);
    });

    _multipeerService.connectionStateStream.listen((state) {
      _connectionStateController.add(P2PConnectionState(
        peerId: state.peerId,
        isConnected: state.isConnected,
        errorMessage: state.errorMessage,
      ));
    });
  }

  /// Start as host/server (Android: create group, iOS: start advertising)
  Future<bool> startAsHost() async {
    if (!_isInitialized) return false;

    if (Platform.isAndroid) {
      return await _wifiDirectService.createGroup(
        userId: _userId!,
        userName: _userName!,
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      return await _multipeerService.startAdvertising();
    }

    return false;
  }

  /// Start discovery (Android: scan, iOS: browse)
  Future<bool> startDiscovery({Duration? timeout}) async {
    if (!_isInitialized) return false;

    if (Platform.isAndroid) {
      return await _wifiDirectService.startDiscovery(
        userId: _userId!,
        userName: _userName!,
        timeout: timeout ?? WiFiDirectService.discoveryTimeout,
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      return await _multipeerService.startBrowsing(
        timeout: timeout ?? MultipeerService.discoveryTimeout,
      );
    }

    return false;
  }

  /// Stop discovery
  Future<void> stopDiscovery() async {
    if (!_isInitialized) return;

    if (Platform.isAndroid) {
      await _wifiDirectService.stopDiscovery();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _multipeerService.stopBrowsing();
    }
  }

  /// Connect to a peer
  Future<bool> connectToPeer(String peerId) async {
    if (!_isInitialized) return false;

    if (Platform.isAndroid) {
      return await _wifiDirectService.connectToPeer(peerId);
    } else if (Platform.isIOS || Platform.isMacOS) {
      return await _multipeerService.invitePeer(peerId);
    }

    return false;
  }

  /// Disconnect from peer or stop hosting
  Future<void> disconnect({String? peerId}) async {
    if (!_isInitialized) return;

    if (Platform.isAndroid) {
      await _wifiDirectService.disconnect();
    } else if (Platform.isIOS || Platform.isMacOS) {
      if (peerId != null) {
        await _multipeerService.disconnect(peerId);
      } else {
        await _multipeerService.disconnectAll();
      }
    }
  }

  /// Send encrypted text message
  Future<bool> sendMessage({
    required String tripId,
    required String message,
    String? targetPeerId,
  }) async {
    if (!_isInitialized) return false;

    try {
      // Encrypt message if target peer specified
      String messageToSend = message;
      if (targetPeerId != null) {
        final encrypted = await _encryptionService.encryptMessage(
          peerId: targetPeerId,
          message: message,
        );

        if (encrypted != null) {
          messageToSend = '${encrypted.encryptedData}|${encrypted.encryptedKey}|${encrypted.iv}';
        }
      }

      // Send via platform-specific service
      if (Platform.isAndroid) {
        return await _wifiDirectService.sendMessage(
          message: messageToSend,
          targetPeerId: targetPeerId,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        return await _multipeerService.sendMessage(
          message: messageToSend,
          targetPeerId: targetPeerId,
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Send file with progress tracking
  Future<bool> sendFile({
    required File file,
    required String fileName,
    String? targetPeerId,
    Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized) return false;

    try {
      if (Platform.isAndroid) {
        return await _wifiDirectService.sendFile(
          file: file,
          fileName: fileName,
          targetPeerId: targetPeerId,
          onProgress: onProgress,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        return await _multipeerService.sendFile(
          filePath: file.path,
          fileName: fileName,
          targetPeerId: targetPeerId,
          onProgress: onProgress,
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error sending file: $e');
      return false;
    }
  }

  /// Download received file (Android WiFi Direct only)
  Future<File?> downloadFile({
    required String fileId,
    required String savePath,
    Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized || !Platform.isAndroid) return null;

    return await _wifiDirectService.downloadFile(
      fileId: fileId,
      savePath: savePath,
      onProgress: onProgress,
    );
  }

  /// Check if connected to specific peer
  bool isConnectedTo(String peerId) {
    if (Platform.isAndroid) {
      return _wifiDirectService.isConnectedTo(peerId);
    } else if (Platform.isIOS || Platform.isMacOS) {
      return _multipeerService.isConnectedTo(peerId);
    }
    return false;
  }

  /// Get peer by ID
  P2PPeer? getPeer(String peerId) {
    if (Platform.isAndroid) {
      final wifiPeer = _wifiDirectService.getPeer(peerId);
      return wifiPeer != null ? P2PPeer.fromWifiDirect(wifiPeer) : null;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final multipeerPeer = _multipeerService.getPeer(peerId);
      return multipeerPeer != null ? P2PPeer.fromMultipeer(multipeerPeer) : null;
    }
    return null;
  }

  /// Get connection statistics
  P2PStatistics getStatistics() {
    if (Platform.isAndroid) {
      final stats = _wifiDirectService.getStatistics();
      return P2PStatistics(
        connectedPeers: stats.connectedPeers,
        discoveredPeers: stats.discoveredPeers,
        transportType: P2PTransportType.wifiDirect,
        isHost: stats.isHost,
        maxConnections: stats.maxConnections,
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      final stats = _multipeerService.getStatistics();
      return P2PStatistics(
        connectedPeers: stats.connectedPeers,
        discoveredPeers: stats.discoveredPeers,
        transportType: P2PTransportType.multipeer,
        isAdvertising: stats.isAdvertising,
        isBrowsing: stats.isBrowsing,
        maxConnections: stats.maxConnections,
      );
    }

    return const P2PStatistics(
      connectedPeers: 0,
      discoveredPeers: 0,
      transportType: P2PTransportType.none,
      maxConnections: 0,
    );
  }

  /// Dispose resources
  void dispose() {
    _wifiDirectService.dispose();
    _multipeerService.dispose();
    _peersController.close();
    _messagesController.close();
    _connectionStateController.close();
    _fileProgressController.close();
  }
}

// ============================================================================
// UNIFIED DATA CLASSES
// ============================================================================

/// Unified P2P Peer
class P2PPeer {
  final String id;
  final String name;
  final DateTime lastSeen;
  final bool isConnected;
  final P2PTransportType transportType;

  P2PPeer({
    required this.id,
    required this.name,
    required this.lastSeen,
    required this.isConnected,
    required this.transportType,
  });

  factory P2PPeer.fromWifiDirect(WifiDirectPeer peer) {
    return P2PPeer(
      id: peer.id,
      name: peer.name,
      lastSeen: peer.lastSeen,
      isConnected: peer.isConnected,
      transportType: P2PTransportType.wifiDirect,
    );
  }

  factory P2PPeer.fromMultipeer(MultipeerPeer peer) {
    return P2PPeer(
      id: peer.id,
      name: peer.name,
      lastSeen: peer.lastSeen,
      isConnected: peer.isConnected,
      transportType: P2PTransportType.multipeer,
    );
  }

  String get status {
    if (isConnected) return 'Connected';
    return 'Available';
  }

  String get transportName {
    switch (transportType) {
      case P2PTransportType.wifiDirect:
        return 'WiFi Direct';
      case P2PTransportType.multipeer:
        return 'Multipeer';
      default:
        return 'Unknown';
    }
  }
}

/// Unified P2P Message
class P2PMessage {
  final String peerId;
  final String content;
  final DateTime timestamp;
  final P2PMessageType messageType;
  final String? filePath;

  P2PMessage({
    required this.peerId,
    required this.content,
    required this.timestamp,
    required this.messageType,
    this.filePath,
  });

  factory P2PMessage.fromWifiDirect(WifiDirectMessage message) {
    return P2PMessage(
      peerId: message.peerId,
      content: message.content,
      timestamp: message.timestamp,
      messageType: message.messageType == WifiDirectMessageType.text
          ? P2PMessageType.text
          : P2PMessageType.file,
      filePath: null,
    );
  }

  factory P2PMessage.fromMultipeer(MultipeerMessage message) {
    return P2PMessage(
      peerId: message.peerId,
      content: message.content,
      timestamp: message.timestamp,
      messageType: message.messageType == MultipeerMessageType.text
          ? P2PMessageType.text
          : P2PMessageType.file,
      filePath: message.filePath,
    );
  }
}

enum P2PMessageType { text, file }

/// P2P Connection State
class P2PConnectionState {
  final String peerId;
  final bool isConnected;
  final String? errorMessage;

  P2PConnectionState({
    required this.peerId,
    required this.isConnected,
    this.errorMessage,
  });
}

/// P2P File Transfer Progress
class P2PFileProgress {
  final String fileId;
  final String fileName;
  final double progress;
  final bool isDownload;

  P2PFileProgress({
    required this.fileId,
    required this.fileName,
    required this.progress,
    this.isDownload = false,
  });

  int get progressPercent => (progress * 100).round();
}

/// P2P Transport Type
enum P2PTransportType {
  none,
  wifiDirect, // Android
  multipeer, // iOS/macOS
}

/// P2P Connection Statistics
class P2PStatistics {
  final int connectedPeers;
  final int discoveredPeers;
  final P2PTransportType transportType;
  final bool? isHost; // WiFi Direct
  final bool? isAdvertising; // Multipeer
  final bool? isBrowsing; // Multipeer
  final int maxConnections;

  const P2PStatistics({
    required this.connectedPeers,
    required this.discoveredPeers,
    required this.transportType,
    this.isHost,
    this.isAdvertising,
    this.isBrowsing,
    required this.maxConnections,
  });
}
