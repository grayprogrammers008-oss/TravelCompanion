import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';  // Package available but may have compatibility issues

// Stub classes for WiFi Direct P2P Connection
// TODO: Replace with actual implementation when package is fully compatible
class FlutterP2pConnection {
  Future<bool> createGroup() async => false;
  Future<bool> startScan() async => false;
  Future<void> stopScan() async {}
  Future<bool> connectWithDevice(P2pDevice device) async => false;
  Future<void> removeGroup() async {}
  Future<void> disconnect() async {}
  Future<void> broadcastText(String message) async {}
  Future<void> broadcastFile({required File file, required String fileName}) async {}
  Future<File?> downloadFile({required int fileId, required String savePath, Function(double)? onProgress}) async => null;
  Stream<dynamic> streamHotspotState() => const Stream.empty();
  Stream<List<P2pDevice>> streamClientList() => const Stream.empty();
  Stream<List<P2pDevice>> streamScanResults() => const Stream.empty();
  Stream<TextData> streamReceivedTexts() => const Stream.empty();
  Stream<FileInfo> streamReceivedFilesInfo() => const Stream.empty();
}

class HotspotEnabled {}

class P2pDevice {
  final String? deviceAddress;
  final String? deviceName;

  P2pDevice({this.deviceAddress, this.deviceName});
}

class TextData {
  final String? senderAddress;
  final String? text;

  TextData({this.senderAddress, this.text});
}

class FileInfo {
  final String? senderAddress;
  final String? fileName;
  final int? fileId;

  FileInfo({this.senderAddress, this.fileName, this.fileId});
}

/// WiFi Direct P2P Service for Android
/// Provides high-bandwidth peer-to-peer communication using WiFi Direct
/// Supports up to 8 simultaneous device connections
class WiFiDirectService {
  static final WiFiDirectService _instance = WiFiDirectService._internal();
  factory WiFiDirectService() => _instance;
  WiFiDirectService._internal();

  // Platform-specific instances
  FlutterP2pConnection? _p2pConnection;
  bool _isHost = false;
  bool _isInitialized = false;

  // Current user info
  String? _userId;
  String? _userName;

  // State tracking
  final Map<String, WifiDirectPeer> _discoveredPeers = {};
  final Map<String, WifiDirectPeer> _connectedPeers = {};
  final StreamController<List<WifiDirectPeer>> _peersController =
      StreamController<List<WifiDirectPeer>>.broadcast();
  final StreamController<WifiDirectMessage> _messagesController =
      StreamController<WifiDirectMessage>.broadcast();
  final StreamController<WifiDirectConnectionState> _connectionStateController =
      StreamController<WifiDirectConnectionState>.broadcast();
  final StreamController<FileTransferProgress> _fileProgressController =
      StreamController<FileTransferProgress>.broadcast();

  // WiFi Direct constants
  static const int MAX_CONNECTIONS = 8;
  static const Duration DISCOVERY_TIMEOUT = Duration(seconds: 45);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isHost => _isHost;
  List<WifiDirectPeer> get discoveredPeers => _discoveredPeers.values.toList();
  List<WifiDirectPeer> get connectedPeers => _connectedPeers.values.toList();
  Stream<List<WifiDirectPeer>> get peersStream => _peersController.stream;
  Stream<WifiDirectMessage> get messagesStream => _messagesController.stream;
  Stream<WifiDirectConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<FileTransferProgress> get fileProgressStream =>
      _fileProgressController.stream;

  /// Initialize WiFi Direct service (Android only)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    if (!Platform.isAndroid) {
      debugPrint('WiFi Direct is only supported on Android');
      return false;
    }

    try {
      _p2pConnection = FlutterP2pConnection();
      _isInitialized = true;
      debugPrint('WiFi Direct service initialized');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize WiFi Direct: $e');
      return false;
    }
  }

  /// Create WiFi Direct group (become host/server)
  Future<bool> createGroup({
    required String userId,
    required String userName,
  }) async {
    if (!_isInitialized || _p2pConnection == null) {
      debugPrint('WiFi Direct not initialized');
      return false;
    }

    try {
      _userId = userId;
      _userName = userName;

      // Create group
      final success = await _p2pConnection!.createGroup();
      if (!success) {
        debugPrint('Failed to create WiFi Direct group');
        return false;
      }

      _isHost = true;

      // Subscribe to host events
      _subscribeToHostEvents();

      debugPrint('WiFi Direct group created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating WiFi Direct group: $e');
      return false;
    }
  }

  /// Subscribe to host-specific events
  void _subscribeToHostEvents() {
    if (_p2pConnection == null) return;

    // Listen for hotspot state changes
    _p2pConnection!.streamHotspotState().listen((state) {
      debugPrint('Hotspot state: ${state.runtimeType}');
      if (state is! HotspotEnabled) {
        _connectionStateController.add(WifiDirectConnectionState(
          peerId: 'host',
          isConnected: false,
          errorMessage: 'Hotspot disabled',
        ));
      }
    });

    // Listen for connected clients
    _p2pConnection!.streamClientList().listen((clients) {
      debugPrint('Connected clients: ${clients.length}');
      _updateConnectedClients(clients);
    });

    // Listen for received text messages
    _p2pConnection!.streamReceivedTexts().listen((textData) {
      _handleReceivedText(textData);
    });

    // Listen for received file info
    _p2pConnection!.streamReceivedFilesInfo().listen((fileInfo) {
      _handleReceivedFileInfo(fileInfo);
    });
  }

  /// Start discovery (client mode)
  Future<bool> startDiscovery({
    required String userId,
    required String userName,
    Duration timeout = DISCOVERY_TIMEOUT,
  }) async {
    if (!_isInitialized || _p2pConnection == null) {
      debugPrint('WiFi Direct not initialized');
      return false;
    }

    try {
      _userId = userId;
      _userName = userName;
      _isHost = false;

      // Start BLE scanning for discovery
      final success = await _p2pConnection!.startScan();
      if (!success) {
        debugPrint('Failed to start WiFi Direct discovery');
        return false;
      }

      // Subscribe to client events
      _subscribeToClientEvents();

      debugPrint('WiFi Direct discovery started');

      // Auto-stop after timeout
      Future.delayed(timeout, () async {
        await stopDiscovery();
      });

      return true;
    } catch (e) {
      debugPrint('Error starting WiFi Direct discovery: $e');
      return false;
    }
  }

  /// Subscribe to client-specific events
  void _subscribeToClientEvents() {
    if (_p2pConnection == null) return;

    // Listen for scanned devices
    _p2pConnection!.streamScanResults().listen((devices) {
      debugPrint('Discovered devices: ${devices.length}');
      _updateDiscoveredPeers(devices);
    });

    // Listen for received text messages
    _p2pConnection!.streamReceivedTexts().listen((textData) {
      _handleReceivedText(textData);
    });

    // Listen for received file info
    _p2pConnection!.streamReceivedFilesInfo().listen((fileInfo) {
      _handleReceivedFileInfo(fileInfo);
    });
  }

  /// Stop discovery
  Future<void> stopDiscovery() async {
    if (_p2pConnection == null) return;

    try {
      await _p2pConnection!.stopScan();
      debugPrint('WiFi Direct discovery stopped');
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
    }
  }

  /// Connect to a discovered peer
  Future<bool> connectToPeer(String peerId) async {
    if (_p2pConnection == null || _isHost) return false;

    final peer = _discoveredPeers[peerId];
    if (peer == null) {
      debugPrint('Peer not found: $peerId');
      return false;
    }

    try {
      // Connect using the device info
      final success = await _p2pConnection!.connectWithDevice(
        peer.deviceInfo!,
      );

      if (success) {
        _connectedPeers[peerId] = peer;
        _connectionStateController.add(WifiDirectConnectionState(
          peerId: peerId,
          isConnected: true,
        ));
        debugPrint('Connected to peer: $peerId');
      }

      return success;
    } catch (e) {
      debugPrint('Error connecting to peer: $e');
      _connectionStateController.add(WifiDirectConnectionState(
        peerId: peerId,
        isConnected: false,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Disconnect from peer or remove group
  Future<void> disconnect() async {
    if (_p2pConnection == null) return;

    try {
      if (_isHost) {
        await _p2pConnection!.removeGroup();
        debugPrint('WiFi Direct group removed');
      } else {
        await _p2pConnection!.disconnect();
        debugPrint('Disconnected from WiFi Direct group');
      }

      _connectedPeers.clear();
      _discoveredPeers.clear();
      _isHost = false;

      _peersController.add([]);
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Send text message to connected peers
  Future<bool> sendMessage({
    required String message,
    String? targetPeerId,
  }) async {
    if (_p2pConnection == null) return false;

    try {
      // Broadcast to all connected peers
      await _p2pConnection!.broadcastText(message);
      debugPrint('Message sent: $message');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Send file to connected peers
  Future<bool> sendFile({
    required File file,
    required String fileName,
    String? targetPeerId,
    Function(double progress)? onProgress,
  }) async {
    if (_p2pConnection == null) return false;

    try {
      // Broadcast file to all connected peers
      await _p2pConnection!.broadcastFile(
        file: file,
        fileName: fileName,
      );

      debugPrint('File sent: $fileName');
      return true;
    } catch (e) {
      debugPrint('Error sending file: $e');
      return false;
    }
  }

  /// Download received file
  Future<File?> downloadFile({
    required String fileId,
    required String savePath,
    Function(double progress)? onProgress,
  }) async {
    if (_p2pConnection == null) return null;

    try {
      final file = await _p2pConnection!.downloadFile(
        fileId: int.parse(fileId),
        savePath: savePath,
        onProgress: (progress) {
          _fileProgressController.add(FileTransferProgress(
            fileId: fileId,
            fileName: '',
            progress: progress,
            isDownload: true,
          ));
          onProgress?.call(progress);
        },
      );

      debugPrint('File downloaded: ${file?.path}');
      return file;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  /// Update discovered peers from scan results
  void _updateDiscoveredPeers(List<P2pDevice> devices) {
    _discoveredPeers.clear();

    for (final device in devices) {
      final peer = WifiDirectPeer(
        id: device.deviceAddress ?? device.deviceName ?? '',
        name: device.deviceName ?? 'Unknown Device',
        deviceInfo: device,
        lastSeen: DateTime.now(),
        isConnected: false,
      );
      _discoveredPeers[peer.id] = peer;
    }

    _peersController.add(discoveredPeers);
  }

  /// Update connected clients (host mode)
  void _updateConnectedClients(List<P2pDevice> clients) {
    _connectedPeers.clear();

    for (final client in clients) {
      final peer = WifiDirectPeer(
        id: client.deviceAddress ?? client.deviceName ?? '',
        name: client.deviceName ?? 'Unknown Client',
        deviceInfo: client,
        lastSeen: DateTime.now(),
        isConnected: true,
      );
      _connectedPeers[peer.id] = peer;
    }

    _peersController.add(connectedPeers);
  }

  /// Handle received text message
  void _handleReceivedText(TextData textData) {
    final message = WifiDirectMessage(
      peerId: textData.senderAddress ?? 'unknown',
      content: textData.text ?? '',
      timestamp: DateTime.now(),
      messageType: WifiDirectMessageType.text,
    );

    _messagesController.add(message);
    debugPrint('Received text: ${message.content}');
  }

  /// Handle received file info
  void _handleReceivedFileInfo(FileInfo fileInfo) {
    final message = WifiDirectMessage(
      peerId: fileInfo.senderAddress ?? 'unknown',
      content: fileInfo.fileName ?? 'unknown.file',
      timestamp: DateTime.now(),
      messageType: WifiDirectMessageType.file,
      fileInfo: fileInfo,
    );

    _messagesController.add(message);
    debugPrint('Received file info: ${fileInfo.fileName}');
  }

  /// Check if connected to specific peer
  bool isConnectedTo(String peerId) {
    return _connectedPeers.containsKey(peerId);
  }

  /// Get peer by ID
  WifiDirectPeer? getPeer(String peerId) {
    return _connectedPeers[peerId] ?? _discoveredPeers[peerId];
  }

  /// Get connection statistics
  WifiDirectStatistics getStatistics() {
    return WifiDirectStatistics(
      connectedPeers: _connectedPeers.length,
      discoveredPeers: _discoveredPeers.length,
      isHost: _isHost,
      maxConnections: MAX_CONNECTIONS,
    );
  }

  /// Dispose resources
  void dispose() {
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

/// WiFi Direct Peer
class WifiDirectPeer {
  final String id;
  final String name;
  final P2pDevice? deviceInfo;
  final DateTime lastSeen;
  final bool isConnected;

  WifiDirectPeer({
    required this.id,
    required this.name,
    this.deviceInfo,
    required this.lastSeen,
    this.isConnected = false,
  });

  String get status {
    if (isConnected) return 'Connected';
    return 'Available';
  }
}

/// WiFi Direct Message
class WifiDirectMessage {
  final String peerId;
  final String content;
  final DateTime timestamp;
  final WifiDirectMessageType messageType;
  final FileInfo? fileInfo;

  WifiDirectMessage({
    required this.peerId,
    required this.content,
    required this.timestamp,
    required this.messageType,
    this.fileInfo,
  });
}

enum WifiDirectMessageType { text, file }

/// WiFi Direct Connection State
class WifiDirectConnectionState {
  final String peerId;
  final bool isConnected;
  final String? errorMessage;

  WifiDirectConnectionState({
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

/// WiFi Direct Statistics
class WifiDirectStatistics {
  final int connectedPeers;
  final int discoveredPeers;
  final bool isHost;
  final int maxConnections;

  const WifiDirectStatistics({
    required this.connectedPeers,
    required this.discoveredPeers,
    required this.isHost,
    required this.maxConnections,
  });
}
