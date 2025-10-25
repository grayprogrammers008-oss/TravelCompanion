import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ble_service.dart';
import '../../data/services/encryption_service.dart';
import '../../data/services/mesh_coordinator.dart';

// ============================================================================
// BLE P2P SERVICE PROVIDERS (Phase 1B)
// ============================================================================

/// Provider for BLE Service
/// Singleton instance that handles Bluetooth LE device discovery and communication
final bleServiceProvider = Provider<BLEService>((ref) {
  return BLEService();
});

/// Provider for Encryption Service
/// Singleton instance that handles end-to-end encryption for P2P messages
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Provider for Mesh Coordinator
/// Singleton instance that handles mesh network routing and message relay
final meshCoordinatorProvider = Provider<MeshCoordinator>((ref) {
  return MeshCoordinator();
});

// ============================================================================
// BLE STATE PROVIDERS
// ============================================================================

/// Stream Provider: Discovered BLE Peers
/// Provides a realtime stream of discovered nearby peers
/// Usage: ref.watch(discoveredPeersProvider)
final discoveredPeersProvider = StreamProvider<List<BLEPeer>>((ref) {
  final bleService = ref.read(bleServiceProvider);
  return bleService.peersStream;
});

/// Stream Provider: BLE Messages
/// Provides a realtime stream of received BLE messages
/// Usage: ref.watch(bleMessagesProvider)
final bleMessagesProvider = StreamProvider<BLEMessage>((ref) {
  final bleService = ref.read(bleServiceProvider);
  return bleService.messagesStream;
});

/// Stream Provider: BLE Connection State
/// Provides a realtime stream of peer connection state changes
/// Usage: ref.watch(bleConnectionStateProvider)
final bleConnectionStateProvider = StreamProvider<BLEConnectionState>((ref) {
  final bleService = ref.read(bleServiceProvider);
  return bleService.connectionStateStream;
});

/// Stream Provider: Mesh Messages
/// Provides a realtime stream of mesh network messages (direct + relayed)
/// Usage: ref.watch(meshMessagesProvider)
final meshMessagesProvider = StreamProvider<MeshMessage>((ref) {
  final meshCoordinator = ref.read(meshCoordinatorProvider);
  return meshCoordinator.messagesStream;
});

/// State Provider: BLE Initialized Status
/// Tracks whether the BLE service has been initialized
/// Usage: ref.watch(bleInitializedProvider)
final bleInitializedProvider = NotifierProvider<BleInitializedNotifier, bool>(
  BleInitializedNotifier.new,
);

class BleInitializedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// State Provider: BLE Scanning Status
/// Tracks whether BLE scanning is currently active
/// Usage: ref.watch(bleScanningProvider)
final bleScanningProvider = NotifierProvider<BleScanningNotifier, bool>(
  BleScanningNotifier.new,
);

class BleScanningNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// State Provider: Mesh Statistics
/// Tracks current mesh network statistics
/// Usage: ref.watch(meshStatisticsProvider)
final meshStatisticsProvider = NotifierProvider<MeshStatisticsNotifier, MeshStatistics?>(
  MeshStatisticsNotifier.new,
);

class MeshStatisticsNotifier extends Notifier<MeshStatistics?> {
  @override
  MeshStatistics? build() => null;

  void set(MeshStatistics? value) => state = value;
}

// ============================================================================
// BLE NOTIFIER PROVIDERS
// ============================================================================

/// Notifier for BLE Service initialization and management
class BLEServiceNotifier extends Notifier<BLEServiceState> {
  late final BLEService _bleService;
  late final EncryptionService _encryptionService;
  late final MeshCoordinator _meshCoordinator;

  @override
  BLEServiceState build() {
    _bleService = ref.read(bleServiceProvider);
    _encryptionService = ref.read(encryptionServiceProvider);
    _meshCoordinator = ref.read(meshCoordinatorProvider);
    return BLEServiceState.initial();
  }

  /// Initialize all BLE services
  Future<void> initialize({
    required String userId,
    required String userName,
  }) async {
    state = state.copyWith(status: BLEServiceStatus.initializing);

    try {
      // Initialize encryption service
      await _encryptionService.initialize();

      // Initialize BLE service
      final bleInitialized = await _bleService.initialize();
      if (!bleInitialized) {
        // Get detailed error message from BLE service
        final errorMsg = _bleService.lastError ?? 'Bluetooth initialization failed';
        state = state.copyWith(
          status: BLEServiceStatus.error,
          errorMessage: errorMsg,
        );
        return;
      }

      // Initialize mesh coordinator
      await _meshCoordinator.initialize(
        userId: userId,
        userName: userName,
      );

      state = state.copyWith(
        status: BLEServiceStatus.ready,
        userId: userId,
        userName: userName,
      );
    } catch (e) {
      state = state.copyWith(
        status: BLEServiceStatus.error,
        errorMessage: 'Initialization failed: $e',
      );
    }
  }

  /// Start scanning for nearby peers
  Future<void> startScanning() async {
    if (state.status != BLEServiceStatus.ready) return;

    state = state.copyWith(isScanning: true);

    try {
      await _bleService.startScanning(
        userId: state.userId!,
        userName: state.userName!,
        timeout: const Duration(seconds: 30),
      );
    } catch (e) {
      state = state.copyWith(
        status: BLEServiceStatus.error,
        errorMessage: 'Scanning failed: $e',
      );
    } finally {
      state = state.copyWith(isScanning: false);
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    await _bleService.stopScanning();
    state = state.copyWith(isScanning: false);
  }

  /// Connect to a peer
  Future<bool> connectToPeer(String peerId) async {
    final success = await _bleService.connectToPeer(peerId);
    if (success) {
      final updatedConnected = Set<String>.from(state.connectedPeerIds)..add(peerId);
      state = state.copyWith(connectedPeerIds: updatedConnected);
    }
    return success;
  }

  /// Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    await _bleService.disconnectFromPeer(peerId);
    final updatedConnected = Set<String>.from(state.connectedPeerIds)..remove(peerId);
    state = state.copyWith(connectedPeerIds: updatedConnected);
  }

  /// Send encrypted message through mesh network
  Future<bool> sendMeshMessage({
    required String tripId,
    required String recipientId,
    required String message,
  }) async {
    try {
      return await _meshCoordinator.sendMeshMessage(
        tripId: tripId,
        recipientId: recipientId,
        senderId: state.userId ?? '',
        message: message,
      );
    } catch (e) {
      state = state.copyWith(
        status: BLEServiceStatus.error,
        errorMessage: 'Failed to send message: $e',
      );
      return false;
    }
  }

  /// Update mesh statistics
  void updateMeshStatistics() {
    final stats = _meshCoordinator.getStatistics();
    state = state.copyWith(meshStats: stats);
  }

  /// Dispose services
  void dispose() {
    _bleService.dispose();
    _meshCoordinator.dispose();
  }
}

/// Provider for BLE Service Notifier
final bleServiceNotifierProvider = NotifierProvider<BLEServiceNotifier, BLEServiceState>(
  BLEServiceNotifier.new,
);

// ============================================================================
// STATE CLASSES
// ============================================================================

/// Status of the BLE service
enum BLEServiceStatus {
  initial,
  initializing,
  ready,
  error,
}

/// State for BLE Service Notifier
class BLEServiceState {
  final BLEServiceStatus status;
  final String? userId;
  final String? userName;
  final bool isScanning;
  final Set<String> connectedPeerIds;
  final MeshStatistics? meshStats;
  final String? errorMessage;

  BLEServiceState({
    required this.status,
    this.userId,
    this.userName,
    this.isScanning = false,
    this.connectedPeerIds = const {},
    this.meshStats,
    this.errorMessage,
  });

  factory BLEServiceState.initial() {
    return BLEServiceState(status: BLEServiceStatus.initial);
  }

  BLEServiceState copyWith({
    BLEServiceStatus? status,
    String? userId,
    String? userName,
    bool? isScanning,
    Set<String>? connectedPeerIds,
    MeshStatistics? meshStats,
    String? errorMessage,
  }) {
    return BLEServiceState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isScanning: isScanning ?? this.isScanning,
      connectedPeerIds: connectedPeerIds ?? this.connectedPeerIds,
      meshStats: meshStats ?? this.meshStats,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isInitialized => status == BLEServiceStatus.ready;
  bool get hasError => status == BLEServiceStatus.error;
}

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Provider: Get connected peers list
/// Returns the list of currently connected peer IDs
/// Usage: ref.watch(connectedPeersProvider)
final connectedPeersProvider = Provider<List<String>>((ref) {
  final bleService = ref.read(bleServiceProvider);
  return bleService.connectedPeerIds;
});

/// Provider: Check if connected to specific peer
/// Returns whether a specific peer is currently connected
/// Usage: ref.watch(isConnectedToPeerProvider(peerId))
final isConnectedToPeerProvider = Provider.family<bool, String>((ref, peerId) {
  final bleService = ref.read(bleServiceProvider);
  return bleService.isConnectedTo(peerId);
});

/// Provider: Get peer by ID
/// Returns the BLEPeer object for a specific peer ID
/// Usage: ref.watch(peerByIdProvider(peerId))
final peerByIdProvider = Provider.family<BLEPeer?, String>((ref, peerId) {
  final bleService = ref.read(bleServiceProvider);
  return bleService.getPeer(peerId);
});
