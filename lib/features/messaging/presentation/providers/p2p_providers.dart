import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/p2p_connection_manager.dart';

// ============================================================================
// P2P CONNECTION PROVIDERS
// ============================================================================

/// Provider for P2P Connection Manager
/// Singleton instance that handles WiFi Direct (Android) and Multipeer (iOS)
final p2pConnectionManagerProvider = Provider<P2PConnectionManager>((ref) {
  return P2PConnectionManager();
});

// ============================================================================
// P2P STATE PROVIDERS
// ============================================================================

/// Stream Provider: Discovered and Connected P2P Peers
/// Provides a realtime stream of nearby peers
/// Usage: ref.watch(p2pPeersProvider)
final p2pPeersProvider = StreamProvider<List<P2PPeer>>((ref) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.peersStream;
});

/// Stream Provider: P2P Messages
/// Provides a realtime stream of received P2P messages
/// Usage: ref.watch(p2pMessagesProvider)
final p2pMessagesProvider = StreamProvider<P2PMessage>((ref) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.messagesStream;
});

/// Stream Provider: P2P Connection State
/// Provides a realtime stream of connection state changes
/// Usage: ref.watch(p2pConnectionStateProvider)
final p2pConnectionStateProvider = StreamProvider<P2PConnectionState>((ref) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.connectionStateStream;
});

/// Stream Provider: P2P File Transfer Progress
/// Provides a realtime stream of file transfer progress
/// Usage: ref.watch(p2pFileProgressProvider)
final p2pFileProgressProvider = StreamProvider<P2PFileProgress>((ref) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.fileProgressStream;
});

/// State Provider: P2P Initialized Status
/// Tracks whether the P2P service has been initialized
/// Usage: ref.watch(p2pInitializedProvider)
final p2pInitializedProvider = StateProvider<bool>((ref) {
  return false;
});

/// State Provider: P2P Connection Mode
/// Tracks current mode (idle, host, discovering)
/// Usage: ref.watch(p2pConnectionModeProvider)
final p2pConnectionModeProvider = StateProvider<P2PConnectionMode>((ref) {
  return P2PConnectionMode.idle;
});

/// State Provider: P2P Statistics
/// Tracks current P2P connection statistics
/// Usage: ref.watch(p2pStatisticsProvider)
final p2pStatisticsProvider = StateProvider<P2PStatistics?>((ref) {
  return null;
});

// ============================================================================
// P2P NOTIFIER PROVIDERS
// ============================================================================

/// Notifier for P2P Connection Manager initialization and management
class P2PConnectionNotifier extends StateNotifier<P2PConnectionState> {
  final P2PConnectionManager _manager;

  P2PConnectionNotifier({
    required P2PConnectionManager manager,
  })  : _manager = manager,
        super(P2PConnectionState.initial());

  /// Initialize P2P services
  Future<void> initialize({
    required String userId,
    required String userName,
  }) async {
    state = state.copyWith(status: P2PStatus.initializing);

    try {
      final success = await _manager.initialize(
        userId: userId,
        userName: userName,
      );

      if (success) {
        state = state.copyWith(
          status: P2PStatus.ready,
          userId: userId,
          userName: userName,
          transportType: _manager.transportType,
        );
      } else {
        state = state.copyWith(
          status: P2PStatus.error,
          errorMessage: 'P2P initialization failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: P2PStatus.error,
        errorMessage: 'Initialization error: $e',
      );
    }
  }

  /// Start as host (Android: create group, iOS: advertise)
  Future<void> startAsHost() async {
    if (state.status != P2PStatus.ready) return;

    state = state.copyWith(
      status: P2PStatus.hosting,
      mode: P2PConnectionMode.host,
    );

    try {
      final success = await _manager.startAsHost();
      if (!success) {
        state = state.copyWith(
          status: P2PStatus.error,
          errorMessage: 'Failed to start as host',
          mode: P2PConnectionMode.idle,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: P2PStatus.error,
        errorMessage: 'Host error: $e',
        mode: P2PConnectionMode.idle,
      );
    }
  }

  /// Start discovery (Android: scan, iOS: browse)
  Future<void> startDiscovery() async {
    if (state.status != P2PStatus.ready) return;

    state = state.copyWith(
      status: P2PStatus.discovering,
      mode: P2PConnectionMode.discovering,
    );

    try {
      final success = await _manager.startDiscovery();
      if (!success) {
        state = state.copyWith(
          status: P2PStatus.error,
          errorMessage: 'Failed to start discovery',
          mode: P2PConnectionMode.idle,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: P2PStatus.error,
        errorMessage: 'Discovery error: $e',
        mode: P2PConnectionMode.idle,
      );
    }
  }

  /// Stop discovery
  Future<void> stopDiscovery() async {
    await _manager.stopDiscovery();
    state = state.copyWith(
      status: P2PStatus.ready,
      mode: P2PConnectionMode.idle,
    );
  }

  /// Connect to a peer
  Future<bool> connectToPeer(String peerId) async {
    try {
      final success = await _manager.connectToPeer(peerId);
      if (success) {
        final connectedPeers = Set<String>.from(state.connectedPeerIds)
          ..add(peerId);
        state = state.copyWith(connectedPeerIds: connectedPeers);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        status: P2PStatus.error,
        errorMessage: 'Connection error: $e',
      );
      return false;
    }
  }

  /// Disconnect from peer or stop hosting
  Future<void> disconnect({String? peerId}) async {
    await _manager.disconnect(peerId: peerId);

    if (peerId != null) {
      final connectedPeers = Set<String>.from(state.connectedPeerIds)
        ..remove(peerId);
      state = state.copyWith(connectedPeerIds: connectedPeers);
    } else {
      state = state.copyWith(
        status: P2PStatus.ready,
        mode: P2PConnectionMode.idle,
        connectedPeerIds: {},
      );
    }
  }

  /// Send message through P2P
  Future<bool> sendMessage({
    required String tripId,
    required String message,
    String? targetPeerId,
  }) async {
    try {
      return await _manager.sendMessage(
        tripId: tripId,
        message: message,
        targetPeerId: targetPeerId,
      );
    } catch (e) {
      state = state.copyWith(
        status: P2PStatus.error,
        errorMessage: 'Send error: $e',
      );
      return false;
    }
  }

  /// Send file through P2P
  Future<bool> sendFile({
    required String filePath,
    required String fileName,
    String? targetPeerId,
  }) async {
    try {
      final file = File(filePath);
      return await _manager.sendFile(
        file: file,
        fileName: fileName,
        targetPeerId: targetPeerId,
      );
    } catch (e) {
      state = state.copyWith(
        status: P2PStatus.error,
        errorMessage: 'File send error: $e',
      );
      return false;
    }
  }

  /// Update statistics
  void updateStatistics() {
    final stats = _manager.getStatistics();
    state = state.copyWith(statistics: stats);
  }

  /// Dispose P2P services
  void dispose() {
    _manager.dispose();
  }
}

/// Provider for P2P Connection Notifier
final p2pConnectionNotifierProvider =
    StateNotifierProvider<P2PConnectionNotifier, P2PConnectionState>((ref) {
  return P2PConnectionNotifier(
    manager: ref.read(p2pConnectionManagerProvider),
  );
});

// ============================================================================
// STATE CLASSES
// ============================================================================

/// Status of the P2P connection
enum P2PStatus {
  initial,
  initializing,
  ready,
  hosting,
  discovering,
  connected,
  error,
}

/// P2P Connection Mode
enum P2PConnectionMode {
  idle,
  host,
  discovering,
}

/// State for P2P Connection Notifier
class P2PConnectionState {
  final P2PStatus status;
  final P2PConnectionMode mode;
  final String? userId;
  final String? userName;
  final P2PTransportType? transportType;
  final Set<String> connectedPeerIds;
  final P2PStatistics? statistics;
  final String? errorMessage;

  P2PConnectionState({
    required this.status,
    required this.mode,
    this.userId,
    this.userName,
    this.transportType,
    this.connectedPeerIds = const {},
    this.statistics,
    this.errorMessage,
  });

  factory P2PConnectionState.initial() {
    return P2PConnectionState(
      status: P2PStatus.initial,
      mode: P2PConnectionMode.idle,
    );
  }

  P2PConnectionState copyWith({
    P2PStatus? status,
    P2PConnectionMode? mode,
    String? userId,
    String? userName,
    P2PTransportType? transportType,
    Set<String>? connectedPeerIds,
    P2PStatistics? statistics,
    String? errorMessage,
  }) {
    return P2PConnectionState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      transportType: transportType ?? this.transportType,
      connectedPeerIds: connectedPeerIds ?? this.connectedPeerIds,
      statistics: statistics ?? this.statistics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isInitialized => status != P2PStatus.initial && status != P2PStatus.initializing;
  bool get hasError => status == P2PStatus.error;
  bool get isHosting => status == P2PStatus.hosting;
  bool get isDiscovering => status == P2PStatus.discovering;
}

// ============================================================================
// HELPER PROVIDERS
// ============================================================================

/// Provider: Get connected peers list
/// Returns the list of currently connected peer IDs
/// Usage: ref.watch(p2pConnectedPeersProvider)
final p2pConnectedPeersProvider = Provider<List<P2PPeer>>((ref) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.connectedPeers;
});

/// Provider: Get discovered peers list
/// Returns the list of discovered but not connected peers
/// Usage: ref.watch(p2pDiscoveredPeersProvider)
final p2pDiscoveredPeersProvider = Provider<List<P2PPeer>>((ref) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.discoveredPeers;
});

/// Provider: Check if connected to specific peer
/// Returns whether a specific peer is currently connected
/// Usage: ref.watch(isConnectedToP2PPeerProvider(peerId))
final isConnectedToP2PPeerProvider = Provider.family<bool, String>((ref, peerId) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.isConnectedTo(peerId);
});

/// Provider: Get peer by ID
/// Returns the P2PPeer object for a specific peer ID
/// Usage: ref.watch(p2pPeerByIdProvider(peerId))
final p2pPeerByIdProvider = Provider.family<P2PPeer?, String>((ref, peerId) {
  final manager = ref.read(p2pConnectionManagerProvider);
  return manager.getPeer(peerId);
});
