import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../messaging/domain/entities/message_entity.dart';
import 'ble_service.dart';
import 'encryption_service.dart';

/// Mesh Network Coordinator
/// Manages message routing, relay, and mesh topology
class MeshCoordinator {
  static final MeshCoordinator _instance = MeshCoordinator._internal();
  factory MeshCoordinator() => _instance;
  MeshCoordinator._internal();

  final BLEService _bleService = BLEService();
  final EncryptionService _encryptionService = EncryptionService();

  // Mesh state
  final Map<String, MeshNode> _meshNodes = {};
  final Map<String, MeshMessage> _messageCache = {}; // For deduplication
  final Map<String, List<String>> _routingTable = {}; // peerId -> [hopIds]

  // Streams
  final _meshMessageController = StreamController<MeshMessage>.broadcast();
  Stream<MeshMessage> get meshMessageStream => _meshMessageController.stream;
  Stream<MeshMessage> get messagesStream => _meshMessageController.stream;

  // Callbacks
  Function(MeshMessage message)? onMeshMessageReceived;
  Function(String messageId, MeshDeliveryStatus status)? onDeliveryStatusChanged;

  // Configuration
  static const int maxHops = 5; // Maximum relay hops
  static const Duration messageTtl = Duration(minutes: 10);
  static const Duration cacheCleanupInterval = Duration(minutes: 5);

  Timer? _cacheCleanupTimer;

  /// Initialize mesh coordinator
  Future<void> initialize({
    required String userId,
    required String userName,
  }) async {
    try {
      debugPrint('🕸️ [MeshCoordinator] Initializing...');

      // Initialize encryption
      await _encryptionService.initialize();

      // Initialize BLE
      await _bleService.initialize();

      // Setup message listener
      _bleService.onMessageReceived = _handleBLEMessage;

      // Setup connection listener
      _bleService.onPeerConnectionChanged = _handlePeerConnectionChanged;

      // Start cache cleanup timer
      _startCacheCleanup();

      debugPrint('✅ [MeshCoordinator] Initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [MeshCoordinator] Initialization failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// Send message through mesh network
  Future<bool> sendMeshMessage({
    required String tripId,
    required String recipientId,
    required String senderId,
    required String message,
    MessageType messageType = MessageType.text,
    String? attachmentUrl,
  }) async {
    try {
      debugPrint('📤 [MeshCoordinator] Sending mesh message to: $recipientId');

      // Create mesh message
      final meshMessage = MeshMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_$senderId',
        tripId: tripId,
        senderId: senderId,
        recipientId: recipientId,
        content: message,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
        hops: [],
        timestamp: DateTime.now(),
        ttl: messageTtl,
      );

      // Check if recipient is directly connected
      if (_bleService.isConnectedTo(recipientId)) {
        return await _sendDirectMessage(meshMessage, recipientId);
      }

      // Find route through mesh
      final route = _findRoute(recipientId);
      if (route.isEmpty) {
        debugPrint('❌ [MeshCoordinator] No route to recipient: $recipientId');
        _notifyDeliveryStatus(meshMessage.id, MeshDeliveryStatus.noRoute);
        return false;
      }

      // Send via first hop
      final firstHop = route.first;
      return await _sendViaRelay(meshMessage, firstHop);
    } catch (e, stackTrace) {
      debugPrint('❌ [MeshCoordinator] Send mesh message failed: $e');
      debugPrint('   Stack Trace: $stackTrace');
      return false;
    }
  }

  /// Send message directly to connected peer
  Future<bool> _sendDirectMessage(MeshMessage message, String peerId) async {
    try {
      // Encrypt message
      final publicKeyPEM = _encryptionService.getPublicKeyPEM();
      if (publicKeyPEM == null) {
        debugPrint('❌ [MeshCoordinator] Public key not available');
        return false;
      }

      // Exchange keys if needed
      if (!_encryptionService.hasPeerKey(peerId)) {
        await _exchangePublicKeys(peerId, publicKeyPEM);
      }

      // Encrypt message content
      final encryptedMessage = await _encryptionService.encryptMessage(
        peerId: peerId,
        message: message.content,
      );

      if (encryptedMessage == null) {
        debugPrint('❌ [MeshCoordinator] Encryption failed');
        return false;
      }

      // Create P2P protocol message
      final p2pMessage = {
        'type': 'direct',
        'id': message.id,
        'tripId': message.tripId,
        'senderId': message.senderId,
        'recipientId': message.recipientId,
        'encrypted': encryptedMessage.toJson(),
        'messageType': message.messageType.name,
        'attachmentUrl': message.attachmentUrl,
        'timestamp': message.timestamp.toIso8601String(),
      };

      // Send via BLE
      final success = await _bleService.sendMessage(
        peerId: peerId,
        message: jsonEncode(p2pMessage),
      );

      if (success) {
        _addToCache(message);
        _notifyDeliveryStatus(message.id, MeshDeliveryStatus.delivered);
      } else {
        _notifyDeliveryStatus(message.id, MeshDeliveryStatus.failed);
      }

      return success;
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Direct send failed: $e');
      return false;
    }
  }

  /// Send message via relay (mesh routing)
  Future<bool> _sendViaRelay(MeshMessage message, String relayPeerId) async {
    try {
      debugPrint('🔀 [MeshCoordinator] Relaying via: $relayPeerId');

      // Check hop count
      if (message.hops.length >= maxHops) {
        debugPrint('❌ [MeshCoordinator] Max hops reached');
        _notifyDeliveryStatus(message.id, MeshDeliveryStatus.maxHopsReached);
        return false;
      }

      // Add relay to hops
      final updatedMessage = message.copyWith(
        hops: [...message.hops, relayPeerId],
      );

      // Create relay message
      final relayMessage = {
        'type': 'relay',
        'message': updatedMessage.toJson(),
      };

      // Send to relay
      final success = await _bleService.sendMessage(
        peerId: relayPeerId,
        message: jsonEncode(relayMessage),
      );

      if (success) {
        _addToCache(updatedMessage);
        _notifyDeliveryStatus(message.id, MeshDeliveryStatus.relaying);
      }

      return success;
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Relay send failed: $e');
      return false;
    }
  }

  /// Handle received BLE message
  void _handleBLEMessage(BLEMessage bleMessage) {
    try {
      debugPrint('📨 [MeshCoordinator] Processing BLE message from: ${bleMessage.peerId}');

      final data = jsonDecode(bleMessage.content) as Map<String, dynamic>;
      final messageType = data['type'] as String;

      switch (messageType) {
        case 'direct':
          _handleDirectMessage(data, bleMessage.peerId);
          break;
        case 'relay':
          _handleRelayMessage(data);
          break;
        case 'key_exchange':
          _handleKeyExchange(data, bleMessage.peerId);
          break;
        case 'ack':
          _handleAcknowledgment(data);
          break;
        default:
          debugPrint('⚠️ [MeshCoordinator] Unknown message type: $messageType');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [MeshCoordinator] Failed to handle BLE message: $e');
      debugPrint('   Stack Trace: $stackTrace');
    }
  }

  /// Handle direct message
  void _handleDirectMessage(Map<String, dynamic> data, String fromPeerId) async {
    try {
      final messageId = data['id'] as String;

      // Check if already processed (deduplication)
      if (_messageCache.containsKey(messageId)) {
        debugPrint('⚠️ [MeshCoordinator] Duplicate message ignored: $messageId');
        return;
      }

      // Decrypt message
      final encryptedData = data['encrypted'] as Map<String, dynamic>;
      final decryptedContent = await _encryptionService.decryptMessage(
        encryptedData: encryptedData['data'] as String,
        encryptedKey: encryptedData['key'] as String,
        ivBase64: encryptedData['iv'] as String,
      );

      if (decryptedContent == null) {
        debugPrint('❌ [MeshCoordinator] Decryption failed');
        return;
      }

      // Create mesh message
      final meshMessage = MeshMessage(
        id: messageId,
        tripId: data['tripId'] as String,
        senderId: data['senderId'] as String,
        recipientId: data['recipientId'] as String,
        content: decryptedContent,
        messageType: MessageType.values.firstWhere(
          (e) => e.name == data['messageType'],
          orElse: () => MessageType.text,
        ),
        attachmentUrl: data['attachmentUrl'] as String?,
        hops: [],
        timestamp: DateTime.parse(data['timestamp'] as String),
        ttl: messageTtl,
      );

      _addToCache(meshMessage);
      _meshMessageController.add(meshMessage);
      onMeshMessageReceived?.call(meshMessage);

      // Send acknowledgment
      _sendAcknowledgment(messageId, fromPeerId);

      debugPrint('✅ [MeshCoordinator] Direct message processed successfully');
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Direct message handling failed: $e');
    }
  }

  /// Handle relay message
  void _handleRelayMessage(Map<String, dynamic> data) async {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final meshMessage = MeshMessage.fromJson(messageData);

      // Check if already processed
      if (_messageCache.containsKey(meshMessage.id)) {
        return;
      }

      // Check if message is for us
      final currentUserId = meshMessage.senderId; // TODO: Get from auth service
      if (meshMessage.recipientId == currentUserId) {
        // Message reached destination
        _meshMessageController.add(meshMessage);
        onMeshMessageReceived?.call(meshMessage);
        return;
      }

      // Continue relaying
      final route = _findRoute(meshMessage.recipientId);
      if (route.isNotEmpty) {
        final nextHop = route.first;
        await _sendViaRelay(meshMessage, nextHop);
      }
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Relay message handling failed: $e');
    }
  }

  /// Exchange public keys with peer
  Future<void> _exchangePublicKeys(String peerId, String myPublicKey) async {
    try {
      final keyExchangeMessage = {
        'type': 'key_exchange',
        'publicKey': myPublicKey,
      };

      await _bleService.sendMessage(
        peerId: peerId,
        message: jsonEncode(keyExchangeMessage),
      );

      debugPrint('🔑 [MeshCoordinator] Public key sent to: $peerId');
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Key exchange failed: $e');
    }
  }

  /// Handle key exchange
  void _handleKeyExchange(Map<String, dynamic> data, String fromPeerId) {
    try {
      final publicKey = data['publicKey'] as String;
      _encryptionService.storePeerPublicKey(fromPeerId, publicKey);
      debugPrint('🔑 [MeshCoordinator] Public key received from: $fromPeerId');
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Key exchange handling failed: $e');
    }
  }

  /// Send acknowledgment
  Future<void> _sendAcknowledgment(String messageId, String peerId) async {
    try {
      final ackMessage = {
        'type': 'ack',
        'messageId': messageId,
      };

      await _bleService.sendMessage(
        peerId: peerId,
        message: jsonEncode(ackMessage),
      );
    } catch (e) {
      debugPrint('❌ [MeshCoordinator] Send ACK failed: $e');
    }
  }

  /// Handle acknowledgment
  void _handleAcknowledgment(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    debugPrint('✅ [MeshCoordinator] ACK received for: $messageId');
    _notifyDeliveryStatus(messageId, MeshDeliveryStatus.acknowledged);
  }

  /// Handle peer connection changed
  void _handlePeerConnectionChanged(String peerId, bool isConnected) {
    if (isConnected) {
      _meshNodes[peerId] = MeshNode(
        id: peerId,
        lastSeen: DateTime.now(),
        isConnected: true,
      );
      _updateRoutingTable();
    } else {
      _meshNodes.remove(peerId);
      _updateRoutingTable();
    }
  }

  /// Find route to destination using mesh topology
  List<String> _findRoute(String destinationId) {
    // Simple routing: BFS to find shortest path
    if (_meshNodes.isEmpty) return [];

    final visited = <String>{};
    final queue = <List<String>>[];

    // Start with directly connected peers
    for (final nodeId in _meshNodes.keys) {
      queue.add([nodeId]);
    }

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final currentNode = path.last;

      if (currentNode == destinationId) {
        return path;
      }

      if (visited.contains(currentNode)) continue;
      visited.add(currentNode);

      // Add neighbors to queue (simplified - in real implementation,
      // you'd query each node for its neighbors)
      // For now, we assume direct connections only
    }

    return [];
  }

  /// Update routing table based on mesh topology
  void _updateRoutingTable() {
    _routingTable.clear();
    // TODO: Implement routing table updates based on mesh topology
    // This would involve periodic topology discovery and route optimization
  }

  /// Add message to cache for deduplication
  void _addToCache(MeshMessage message) {
    _messageCache[message.id] = message;
  }

  /// Start cache cleanup timer
  void _startCacheCleanup() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer.periodic(cacheCleanupInterval, (_) {
      _cleanupCache();
    });
  }

  /// Clean up expired messages from cache
  void _cleanupCache() {
    final now = DateTime.now();
    _messageCache.removeWhere((id, message) {
      return now.difference(message.timestamp) > message.ttl;
    });
    debugPrint('🧹 [MeshCoordinator] Cache cleaned up. Size: ${_messageCache.length}');
  }

  /// Notify delivery status changed
  void _notifyDeliveryStatus(String messageId, MeshDeliveryStatus status) {
    onDeliveryStatusChanged?.call(messageId, status);
  }

  /// Get mesh statistics
  MeshStatistics getStatistics() {
    return MeshStatistics(
      connectedNodes: _meshNodes.length,
      cachedMessages: _messageCache.length,
      knownRoutes: _routingTable.length,
    );
  }

  /// Dispose resources
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _meshMessageController.close();
    _bleService.dispose();
    debugPrint('🗑️ [MeshCoordinator] Disposed');
  }
}

/// Mesh node information
class MeshNode {
  final String id;
  final DateTime lastSeen;
  final bool isConnected;

  MeshNode({
    required this.id,
    required this.lastSeen,
    required this.isConnected,
  });
}

/// Mesh message with routing information
class MeshMessage {
  final String id;
  final String tripId;
  final String senderId;
  final String recipientId;
  final String content;
  final MessageType messageType;
  final String? attachmentUrl;
  final List<String> hops; // List of peer IDs that relayed the message
  final DateTime timestamp;
  final Duration ttl;

  MeshMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.messageType,
    this.attachmentUrl,
    required this.hops,
    required this.timestamp,
    required this.ttl,
  });

  MeshMessage copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? recipientId,
    String? content,
    MessageType? messageType,
    String? attachmentUrl,
    List<String>? hops,
    DateTime? timestamp,
    Duration? ttl,
  }) {
    return MeshMessage(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      hops: hops ?? this.hops,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'messageType': messageType.name,
      'attachmentUrl': attachmentUrl,
      'hops': hops,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      content: json['content'] as String,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.text,
      ),
      attachmentUrl: json['attachmentUrl'] as String?,
      hops: (json['hops'] as List<dynamic>).cast<String>(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      ttl: MeshCoordinator.messageTtl,
    );
  }
}

/// Mesh delivery status
enum MeshDeliveryStatus {
  sending,
  relaying,
  delivered,
  acknowledged,
  failed,
  noRoute,
  maxHopsReached,
}

/// Mesh network statistics
class MeshStatistics {
  final int connectedNodes;
  final int cachedMessages;
  final int knownRoutes;

  MeshStatistics({
    required this.connectedNodes,
    required this.cachedMessages,
    required this.knownRoutes,
  });
}
