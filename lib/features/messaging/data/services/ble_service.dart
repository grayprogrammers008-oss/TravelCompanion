import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// BLE Service for Peer-to-Peer Messaging
/// Handles device discovery, connection, and data transmission via Bluetooth LE
class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  // UUIDs for Travel Companion P2P Messaging
  static const String SERVICE_UUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String TX_CHARACTERISTIC_UUID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // Write
  static const String RX_CHARACTERISTIC_UUID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // Notify

  // State
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isAdvertising = false;

  // Discovered peers
  final Map<String, BLEPeer> _discoveredPeers = {};
  final Map<String, BluetoothDevice> _connectedDevices = {};

  // Streams
  final _peersController = StreamController<List<BLEPeer>>.broadcast();
  final _messagesController = StreamController<BLEMessage>.broadcast();
  final _connectionStateController = StreamController<BLEConnectionState>.broadcast();

  Stream<List<BLEPeer>> get peersStream => _peersController.stream;
  Stream<BLEMessage> get messagesStream => _messagesController.stream;
  Stream<BLEConnectionState> get connectionStateStream => _connectionStateController.stream;

  // Callbacks
  Function(BLEMessage message)? onMessageReceived;
  Function(String peerId, bool isConnected)? onPeerConnectionChanged;

  /// Initialize BLE service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('📡 [BLEService] Initializing...');

      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        debugPrint('❌ [BLEService] Bluetooth not supported on this device');
        return false;
      }

      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        debugPrint('❌ [BLEService] Required permissions not granted');
        return false;
      }

      // Check if Bluetooth is enabled
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('⚠️ [BLEService] Bluetooth is turned off');
        // You might want to prompt user to turn on Bluetooth
        return false;
      }

      _isInitialized = true;
      debugPrint('✅ [BLEService] Initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [BLEService] Initialization failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return false;
    }
  }

  /// Request necessary permissions for BLE
  Future<bool> _requestPermissions() async {
    try {
      // Android 12+ requires additional permissions
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location, // Required for BLE scan on Android
      ];

      final statuses = await permissions.request();

      final allGranted = statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );

      if (allGranted) {
        debugPrint('✅ [BLEService] All permissions granted');
        return true;
      } else {
        debugPrint('❌ [BLEService] Some permissions denied');
        statuses.forEach((permission, status) {
          debugPrint('   $permission: $status');
        });
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BLEService] Permission request failed: $e');
      return false;
    }
  }

  /// Start scanning for nearby peers
  Future<void> startScanning({
    required String userId,
    required String userName,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ [BLEService] Not initialized');
      return;
    }

    if (_isScanning) {
      debugPrint('⚠️ [BLEService] Already scanning');
      return;
    }

    try {
      debugPrint('🔍 [BLEService] Starting scan for nearby peers...');
      _isScanning = true;

      // Clear old peers
      _discoveredPeers.clear();
      _notifyPeersChanged();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          _processScanResult(result);
        }
      });

      // Auto-stop after timeout
      Future.delayed(timeout, () {
        if (_isScanning) {
          stopScanning();
        }
      });
    } catch (e) {
      debugPrint('❌ [BLEService] Scan failed: $e');
      _isScanning = false;
    }
  }

  /// Process scan result and extract peer info
  void _processScanResult(ScanResult result) {
    try {
      final device = result.device;
      final advertisementData = result.advertisementData;

      // Check if device advertises our service
      if (!advertisementData.serviceUuids.contains(SERVICE_UUID)) {
        return; // Not a Travel Companion peer
      }

      // Extract peer info from manufacturer data or service data
      final peerInfo = _extractPeerInfo(advertisementData);
      if (peerInfo == null) return;

      final peer = BLEPeer(
        id: peerInfo['id'] as String,
        name: peerInfo['name'] as String,
        device: device,
        rssi: result.rssi,
        lastSeen: DateTime.now(),
      );

      _discoveredPeers[peer.id] = peer;
      _notifyPeersChanged();

      debugPrint('📱 [BLEService] Discovered peer: ${peer.name} (${peer.id})');
      debugPrint('   RSSI: ${peer.rssi} dBm');
    } catch (e) {
      debugPrint('❌ [BLEService] Failed to process scan result: $e');
    }
  }

  /// Extract peer info from advertisement data
  Map<String, dynamic>? _extractPeerInfo(AdvertisementData advertisementData) {
    try {
      // Try to extract from service data
      final serviceData = advertisementData.serviceData[SERVICE_UUID];
      if (serviceData != null && serviceData.isNotEmpty) {
        final json = utf8.decode(serviceData);
        return jsonDecode(json) as Map<String, dynamic>;
      }

      // Fallback: Use device name
      final deviceName = advertisementData.advName;
      if (deviceName.startsWith('TC_')) {
        // Format: TC_userId_userName
        final parts = deviceName.split('_');
        if (parts.length >= 3) {
          return {
            'id': parts[1],
            'name': parts.sublist(2).join('_'),
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [BLEService] Failed to extract peer info: $e');
      return null;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      debugPrint('⏹️ [BLEService] Scan stopped');
    } catch (e) {
      debugPrint('❌ [BLEService] Failed to stop scan: $e');
    }
  }

  /// Connect to a peer
  Future<bool> connectToPeer(String peerId) async {
    try {
      final peer = _discoveredPeers[peerId];
      if (peer == null) {
        debugPrint('❌ [BLEService] Peer not found: $peerId');
        return false;
      }

      debugPrint('🔗 [BLEService] Connecting to peer: ${peer.name}');

      // Connect to device
      await peer.device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Discover services
      final services = await peer.device.discoverServices();

      // Find our service
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase(),
        orElse: () => throw Exception('Service not found'),
      );

      // Find characteristics
      final rxChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == RX_CHARACTERISTIC_UUID.toLowerCase(),
      );

      // Subscribe to notifications
      await rxChar.setNotifyValue(true);
      rxChar.onValueReceived.listen((value) {
        _handleReceivedData(peerId, value);
      });

      _connectedDevices[peerId] = peer.device;
      _notifyConnectionStateChanged(peerId, true);

      debugPrint('✅ [BLEService] Connected to peer: ${peer.name}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [BLEService] Connection failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return false;
    }
  }

  /// Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    try {
      final device = _connectedDevices[peerId];
      if (device == null) return;

      await device.disconnect();
      _connectedDevices.remove(peerId);
      _notifyConnectionStateChanged(peerId, false);

      debugPrint('🔌 [BLEService] Disconnected from peer: $peerId');
    } catch (e) {
      debugPrint('❌ [BLEService] Disconnect failed: $e');
    }
  }

  /// Send message to a peer
  Future<bool> sendMessage({
    required String peerId,
    required String message,
  }) async {
    try {
      final device = _connectedDevices[peerId];
      if (device == null) {
        debugPrint('❌ [BLEService] Not connected to peer: $peerId');
        return false;
      }

      debugPrint('📤 [BLEService] Sending message to peer: $peerId');

      // Get TX characteristic
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase(),
      );

      final txChar = service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == TX_CHARACTERISTIC_UUID.toLowerCase(),
      );

      // Split message into chunks (BLE MTU limit is typically 20-512 bytes)
      const maxChunkSize = 512;
      final messageBytes = utf8.encode(message);

      for (int i = 0; i < messageBytes.length; i += maxChunkSize) {
        final end = (i + maxChunkSize < messageBytes.length)
            ? i + maxChunkSize
            : messageBytes.length;
        final chunk = messageBytes.sublist(i, end);

        await txChar.write(chunk, withoutResponse: false);
      }

      debugPrint('✅ [BLEService] Message sent successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [BLEService] Send message failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return false;
    }
  }

  /// Handle received data from peer
  void _handleReceivedData(String peerId, List<int> data) {
    try {
      final message = utf8.decode(data);
      debugPrint('📥 [BLEService] Received message from peer: $peerId');

      final bleMessage = BLEMessage(
        peerId: peerId,
        content: message,
        timestamp: DateTime.now(),
      );

      _messagesController.add(bleMessage);
      onMessageReceived?.call(bleMessage);
    } catch (e) {
      debugPrint('❌ [BLEService] Failed to handle received data: $e');
    }
  }

  /// Notify peers list changed
  void _notifyPeersChanged() {
    _peersController.add(_discoveredPeers.values.toList());
  }

  /// Notify connection state changed
  void _notifyConnectionStateChanged(String peerId, bool isConnected) {
    _connectionStateController.add(
      BLEConnectionState(peerId: peerId, isConnected: isConnected),
    );
    onPeerConnectionChanged?.call(peerId, isConnected);
  }

  /// Get discovered peers
  List<BLEPeer> get discoveredPeers => _discoveredPeers.values.toList();

  /// Get connected peers
  List<String> get connectedPeerIds => _connectedDevices.keys.toList();

  /// Check if connected to a peer
  bool isConnectedTo(String peerId) => _connectedDevices.containsKey(peerId);

  /// Get peer by ID
  BLEPeer? getPeer(String peerId) => _discoveredPeers[peerId];

  /// Dispose resources
  void dispose() {
    stopScanning();
    _connectedDevices.values.forEach((device) => device.disconnect());
    _connectedDevices.clear();
    _discoveredPeers.clear();
    _peersController.close();
    _messagesController.close();
    _connectionStateController.close();
    debugPrint('🗑️ [BLEService] Disposed');
  }
}

/// BLE Peer information
class BLEPeer {
  final String id;
  final String name;
  final BluetoothDevice device;
  final int rssi; // Signal strength
  final DateTime lastSeen;

  BLEPeer({
    required this.id,
    required this.name,
    required this.device,
    required this.rssi,
    required this.lastSeen,
  });

  /// Get signal strength category
  String get signalStrength {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Weak';
  }

  /// Get estimated distance in meters (rough approximation)
  double get estimatedDistance {
    // Free space path loss formula (simplified)
    // RSSI = -10n * log10(d) - A
    // Where: n = 2 (path loss exponent), A = -50 (reference RSSI at 1m)
    final ratio = (-50 - rssi) / 20.0;
    return 10.0 * ratio;
  }
}

/// BLE Message received from peer
class BLEMessage {
  final String peerId;
  final String content;
  final DateTime timestamp;

  BLEMessage({
    required this.peerId,
    required this.content,
    required this.timestamp,
  });
}

/// BLE Connection state change event
class BLEConnectionState {
  final String peerId;
  final bool isConnected;

  BLEConnectionState({
    required this.peerId,
    required this.isConnected,
  });
}
