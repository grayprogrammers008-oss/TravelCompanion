import 'dart:async';
import 'dart:collection';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Message Deduplication Service
/// Prevents duplicate messages from multiple sync sources (Server, BLE, WiFi Direct, etc.)
/// Uses content-based hashing and temporal ordering
class MessageDeduplicationService {
  static final MessageDeduplicationService _instance = MessageDeduplicationService._internal();
  factory MessageDeduplicationService() => _instance;
  MessageDeduplicationService._internal();

  // Deduplication cache with expiry
  final Map<String, DeduplicationEntry> _messageCache = {};
  final Map<String, String> _contentHashToId = {}; // Content hash -> Message ID

  // LRU cache for performance
  final LinkedHashMap<String, DateTime> _accessOrder = LinkedHashMap();

  // Configuration
  static const int MAX_CACHE_SIZE = 10000;
  static const Duration CACHE_TTL = Duration(hours: 24);
  static const Duration CLEANUP_INTERVAL = Duration(hours: 1);

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  // Statistics
  int _totalChecks = 0;
  int _duplicatesFound = 0;
  int _uniqueMessages = 0;

  /// Initialize the deduplication service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(CLEANUP_INTERVAL, (_) => _cleanupExpiredEntries());

    _isInitialized = true;
    debugPrint('Message Deduplication Service initialized');
  }

  /// Check if a message is a duplicate
  /// Returns the canonical message ID if duplicate, null if unique
  Future<String?> checkDuplicate({
    required String messageId,
    required String tripId,
    required String senderId,
    required String content,
    required DateTime timestamp,
    String? attachmentUrl,
  }) async {
    _totalChecks++;

    // Generate content hash for deduplication
    final contentHash = _generateContentHash(
      tripId: tripId,
      senderId: senderId,
      content: content,
      attachmentUrl: attachmentUrl,
    );

    // Check if we've seen this exact content before
    final existingMessageId = _contentHashToId[contentHash];
    if (existingMessageId != null) {
      final entry = _messageCache[existingMessageId];
      if (entry != null && !_isExpired(entry)) {
        // Found duplicate - return canonical message ID
        _duplicatesFound++;
        _updateAccessOrder(existingMessageId);

        debugPrint('Duplicate message detected: $messageId -> $existingMessageId');
        return existingMessageId;
      }
    }

    // Check if this specific message ID exists
    if (_messageCache.containsKey(messageId)) {
      final entry = _messageCache[messageId]!;
      if (!_isExpired(entry)) {
        _duplicatesFound++;
        _updateAccessOrder(messageId);
        return messageId; // Already processed this exact message
      }
    }

    // New unique message - add to cache
    _addToCache(
      messageId: messageId,
      contentHash: contentHash,
      tripId: tripId,
      senderId: senderId,
      timestamp: timestamp,
    );

    _uniqueMessages++;
    return null; // Not a duplicate
  }

  /// Register a message in the deduplication cache
  /// Use this when receiving messages from sync sources
  void registerMessage({
    required String messageId,
    required String tripId,
    required String senderId,
    required String content,
    required DateTime timestamp,
    String? attachmentUrl,
  }) {
    final contentHash = _generateContentHash(
      tripId: tripId,
      senderId: senderId,
      content: content,
      attachmentUrl: attachmentUrl,
    );

    _addToCache(
      messageId: messageId,
      contentHash: contentHash,
      tripId: tripId,
      senderId: senderId,
      timestamp: timestamp,
    );
  }

  /// Get the canonical message ID for a content hash
  String? getCanonicalMessageId(String contentHash) {
    return _contentHashToId[contentHash];
  }

  /// Check if a message ID is in the cache
  bool isMessageKnown(String messageId) {
    final entry = _messageCache[messageId];
    return entry != null && !_isExpired(entry);
  }

  /// Remove a message from the cache
  void removeMessage(String messageId) {
    final entry = _messageCache.remove(messageId);
    if (entry != null) {
      _contentHashToId.remove(entry.contentHash);
      _accessOrder.remove(messageId);
    }
  }

  /// Clear all cached messages for a trip
  void clearTripCache(String tripId) {
    final toRemove = <String>[];

    _messageCache.forEach((messageId, entry) {
      if (entry.tripId == tripId) {
        toRemove.add(messageId);
      }
    });

    for (final messageId in toRemove) {
      removeMessage(messageId);
    }

    debugPrint('Cleared cache for trip: $tripId (${toRemove.length} messages)');
  }

  /// Get deduplication statistics
  DeduplicationStats getStatistics() {
    return DeduplicationStats(
      totalChecks: _totalChecks,
      duplicatesFound: _duplicatesFound,
      uniqueMessages: _uniqueMessages,
      cacheSize: _messageCache.length,
      maxCacheSize: MAX_CACHE_SIZE,
      duplicateRate: _totalChecks > 0 ? _duplicatesFound / _totalChecks : 0.0,
    );
  }

  /// Reset statistics
  void resetStatistics() {
    _totalChecks = 0;
    _duplicatesFound = 0;
    _uniqueMessages = 0;
  }

  /// Clear entire cache
  void clearCache() {
    _messageCache.clear();
    _contentHashToId.clear();
    _accessOrder.clear();
    resetStatistics();
    debugPrint('Deduplication cache cleared');
  }

  // Private methods

  String _generateContentHash({
    required String tripId,
    required String senderId,
    required String content,
    String? attachmentUrl,
  }) {
    // Create deterministic hash of message content
    final buffer = StringBuffer();
    buffer.write(tripId);
    buffer.write('|');
    buffer.write(senderId);
    buffer.write('|');
    buffer.write(content.trim()); // Trim whitespace for consistency
    if (attachmentUrl != null) {
      buffer.write('|');
      buffer.write(attachmentUrl);
    }

    final bytes = utf8.encode(buffer.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _addToCache({
    required String messageId,
    required String contentHash,
    required String tripId,
    required String senderId,
    required DateTime timestamp,
  }) {
    // Check cache size and evict if necessary
    if (_messageCache.length >= MAX_CACHE_SIZE) {
      _evictOldest();
    }

    final entry = DeduplicationEntry(
      messageId: messageId,
      contentHash: contentHash,
      tripId: tripId,
      senderId: senderId,
      timestamp: timestamp,
      addedAt: DateTime.now(),
    );

    _messageCache[messageId] = entry;
    _contentHashToId[contentHash] = messageId;
    _updateAccessOrder(messageId);
  }

  void _updateAccessOrder(String messageId) {
    // Move to end (most recently used)
    _accessOrder.remove(messageId);
    _accessOrder[messageId] = DateTime.now();
  }

  void _evictOldest() {
    if (_accessOrder.isEmpty) return;

    // Remove least recently used
    final oldestKey = _accessOrder.keys.first;
    removeMessage(oldestKey);

    debugPrint('Evicted oldest message: $oldestKey');
  }

  bool _isExpired(DeduplicationEntry entry) {
    final age = DateTime.now().difference(entry.addedAt);
    return age > CACHE_TTL;
  }

  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    final toRemove = <String>[];

    _messageCache.forEach((messageId, entry) {
      if (_isExpired(entry)) {
        toRemove.add(messageId);
      }
    });

    for (final messageId in toRemove) {
      removeMessage(messageId);
    }

    if (toRemove.isNotEmpty) {
      debugPrint('Cleaned up ${toRemove.length} expired entries');
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    clearCache();
    _isInitialized = false;
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Deduplication cache entry
class DeduplicationEntry {
  final String messageId;
  final String contentHash;
  final String tripId;
  final String senderId;
  final DateTime timestamp;
  final DateTime addedAt;

  DeduplicationEntry({
    required this.messageId,
    required this.contentHash,
    required this.tripId,
    required this.senderId,
    required this.timestamp,
    required this.addedAt,
  });
}

/// Deduplication statistics
class DeduplicationStats {
  final int totalChecks;
  final int duplicatesFound;
  final int uniqueMessages;
  final int cacheSize;
  final int maxCacheSize;
  final double duplicateRate;

  const DeduplicationStats({
    required this.totalChecks,
    required this.duplicatesFound,
    required this.uniqueMessages,
    required this.cacheSize,
    required this.maxCacheSize,
    required this.duplicateRate,
  });

  double get cacheUsage => maxCacheSize > 0 ? cacheSize / maxCacheSize : 0.0;
}
