import 'package:flutter/foundation.dart';
import '../../domain/entities/message_entity.dart';

/// Conflict Resolution Engine
/// Resolves conflicts when same message comes from multiple sources with different states
/// Uses Last-Write-Wins (LWW) with tie-breaking rules
class ConflictResolutionEngine {
  static final ConflictResolutionEngine _instance = ConflictResolutionEngine._internal();
  factory ConflictResolutionEngine() => _instance;
  ConflictResolutionEngine._internal();

  // Conflict resolution strategies
  final Map<String, ConflictResolutionStrategy> _strategies = {};

  // Statistics
  int _totalConflicts = 0;
  int _resolvedByTimestamp = 0;
  int _resolvedBySource = 0;
  int _resolvedByContent = 0;
  int _manualResolution = 0;

  /// Initialize with default strategies
  void initialize() {
    // Register default strategies
    registerStrategy('message', MessageConflictStrategy());
    registerStrategy('reaction', ReactionConflictStrategy());
    registerStrategy('read_status', ReadStatusConflictStrategy());
    registerStrategy('deletion', DeletionConflictStrategy());

    debugPrint('Conflict Resolution Engine initialized');
  }

  /// Register a conflict resolution strategy
  void registerStrategy(String type, ConflictResolutionStrategy strategy) {
    _strategies[type] = strategy;
  }

  /// Resolve conflict between two message versions
  Future<MessageConflictResolution> resolveMessageConflict({
    required MessageEntity localVersion,
    required MessageEntity remoteVersion,
    required String source, // 'server', 'ble', 'wifi_direct', etc.
  }) async {
    _totalConflicts++;

    // If messages are identical, no conflict
    if (_areMessagesIdentical(localVersion, remoteVersion)) {
      return MessageConflictResolution.noConflict(localVersion);
    }

    // Get strategy
    final strategy = _strategies['message'] ?? MessageConflictStrategy();

    // Resolve conflict
    final result = await strategy.resolve(
      local: localVersion,
      remote: remoteVersion,
      source: source,
    );

    // Track resolution method
    _updateStatistics(result.resolutionMethod);

    debugPrint(
      'Message conflict resolved: ${localVersion.id} '
      '(method: ${result.resolutionMethod.name}, winner: ${result.winner.name})',
    );

    return result;
  }

  /// Resolve reaction conflicts
  Future<List<MessageReaction>> resolveReactionConflict({
    required List<MessageReaction> localReactions,
    required List<MessageReaction> remoteReactions,
    required String source,
  }) async {
    _totalConflicts++;

    final strategy = _strategies['reaction'] ?? ReactionConflictStrategy();

    // Merge reactions using strategy
    final resolved = await (strategy as ReactionConflictStrategy).mergeReactions(
      local: localReactions,
      remote: remoteReactions,
      source: source,
    );

    _resolvedByContent++;

    return resolved;
  }

  /// Resolve read status conflicts
  Future<List<String>> resolveReadStatusConflict({
    required List<String> localReadBy,
    required List<String> remoteReadBy,
  }) async {
    // Union of all readers (additive merge)
    final allReaders = <String>{...localReadBy, ...remoteReadBy};
    return allReaders.toList();
  }

  /// Resolve deletion conflicts
  Future<bool> resolveDeletionConflict({
    required bool localDeleted,
    required bool remoteDeleted,
    required DateTime? localDeletedAt,
    required DateTime? remoteDeletedAt,
  }) async {
    // If either version is deleted, message is deleted
    // Deletion wins over non-deletion
    if (localDeleted || remoteDeleted) {
      return true;
    }
    return false;
  }

  /// Check if two messages are identical
  bool _areMessagesIdentical(MessageEntity msg1, MessageEntity msg2) {
    return msg1.id == msg2.id &&
        msg1.message == msg2.message &&
        msg1.messageType == msg2.messageType &&
        msg1.attachmentUrl == msg2.attachmentUrl &&
        msg1.reactions.length == msg2.reactions.length &&
        msg1.readBy.length == msg2.readBy.length;
  }

  void _updateStatistics(ResolutionMethod method) {
    switch (method) {
      case ResolutionMethod.timestamp:
        _resolvedByTimestamp++;
        break;
      case ResolutionMethod.source:
        _resolvedBySource++;
        break;
      case ResolutionMethod.content:
        _resolvedByContent++;
        break;
      case ResolutionMethod.manual:
        _manualResolution++;
        break;
    }
  }

  /// Get conflict resolution statistics
  ConflictResolutionStats getStatistics() {
    return ConflictResolutionStats(
      totalConflicts: _totalConflicts,
      resolvedByTimestamp: _resolvedByTimestamp,
      resolvedBySource: _resolvedBySource,
      resolvedByContent: _resolvedByContent,
      manualResolution: _manualResolution,
    );
  }

  /// Reset statistics
  void resetStatistics() {
    _totalConflicts = 0;
    _resolvedByTimestamp = 0;
    _resolvedBySource = 0;
    _resolvedByContent = 0;
    _manualResolution = 0;
  }
}

// ============================================================================
// CONFLICT RESOLUTION STRATEGIES
// ============================================================================

/// Base conflict resolution strategy
abstract class ConflictResolutionStrategy {
  Future<MessageConflictResolution> resolve({
    required MessageEntity local,
    required MessageEntity remote,
    required String source,
  });
}

/// Message conflict strategy - Last Write Wins with source priority
class MessageConflictStrategy extends ConflictResolutionStrategy {
  @override
  Future<MessageConflictResolution> resolve({
    required MessageEntity local,
    required MessageEntity remote,
    required String source,
  }) async {
    // 1. Compare timestamps (Last Write Wins)
    final comparison = remote.updatedAt.compareTo(local.updatedAt);

    if (comparison > 0) {
      // Remote is newer
      return MessageConflictResolution(
        winner: ConflictWinner.remote,
        resolvedMessage: remote,
        resolutionMethod: ResolutionMethod.timestamp,
        explanation: 'Remote version is newer',
      );
    } else if (comparison < 0) {
      // Local is newer
      return MessageConflictResolution(
        winner: ConflictWinner.local,
        resolvedMessage: local,
        resolutionMethod: ResolutionMethod.timestamp,
        explanation: 'Local version is newer',
      );
    }

    // 2. If timestamps are equal, use source priority
    // Priority: server > wifi_direct > ble > local
    final sourcePriority = _getSourcePriority(source);

    if (sourcePriority > 0) {
      // Remote source has priority
      return MessageConflictResolution(
        winner: ConflictWinner.remote,
        resolvedMessage: remote,
        resolutionMethod: ResolutionMethod.source,
        explanation: 'Remote source ($source) has priority',
      );
    }

    // 3. Default to local version
    return MessageConflictResolution(
      winner: ConflictWinner.local,
      resolvedMessage: local,
      resolutionMethod: ResolutionMethod.source,
      explanation: 'Local version retained as fallback',
    );
  }

  int _getSourcePriority(String source) {
    switch (source.toLowerCase()) {
      case 'server':
        return 3;
      case 'wifi_direct':
      case 'multipeer':
        return 2;
      case 'ble':
        return 1;
      default:
        return 0;
    }
  }
}

/// Reaction conflict strategy - Merge all unique reactions
class ReactionConflictStrategy extends ConflictResolutionStrategy {
  @override
  Future<MessageConflictResolution> resolve({
    required MessageEntity local,
    required MessageEntity remote,
    required String source,
  }) async {
    // Merge reactions
    final mergedReactions = await mergeReactions(
      local: local.reactions,
      remote: remote.reactions,
      source: source,
    );

    // Create merged message
    final mergedMessage = local.copyWith(reactions: mergedReactions);

    return MessageConflictResolution(
      winner: ConflictWinner.merged,
      resolvedMessage: mergedMessage,
      resolutionMethod: ResolutionMethod.content,
      explanation: 'Reactions merged from both versions',
    );
  }

  Future<List<MessageReaction>> mergeReactions({
    required List<MessageReaction> local,
    required List<MessageReaction> remote,
    required String source,
  }) async {
    // Create map for deduplication
    final Map<String, MessageReaction> reactionMap = {};

    // Add local reactions
    for (final reaction in local) {
      final key = '${reaction.userId}_${reaction.emoji}';
      reactionMap[key] = reaction;
    }

    // Merge remote reactions
    for (final reaction in remote) {
      final key = '${reaction.userId}_${reaction.emoji}';
      final existing = reactionMap[key];

      if (existing == null) {
        // New reaction
        reactionMap[key] = reaction;
      } else {
        // Keep the newer one
        if (reaction.createdAt.isAfter(existing.createdAt)) {
          reactionMap[key] = reaction;
        }
      }
    }

    return reactionMap.values.toList();
  }
}

/// Read status conflict strategy - Union of all readers
class ReadStatusConflictStrategy extends ConflictResolutionStrategy {
  @override
  Future<MessageConflictResolution> resolve({
    required MessageEntity local,
    required MessageEntity remote,
    required String source,
  }) async {
    // Union of readers
    final allReaders = <String>{...local.readBy, ...remote.readBy};

    final mergedMessage = local.copyWith(readBy: allReaders.toList());

    return MessageConflictResolution(
      winner: ConflictWinner.merged,
      resolvedMessage: mergedMessage,
      resolutionMethod: ResolutionMethod.content,
      explanation: 'Read status merged from both versions',
    );
  }
}

/// Deletion conflict strategy - Deletion always wins
class DeletionConflictStrategy extends ConflictResolutionStrategy {
  @override
  Future<MessageConflictResolution> resolve({
    required MessageEntity local,
    required MessageEntity remote,
    required String source,
  }) async {
    // If either is deleted, use the deleted version
    if (remote.isDeleted || local.isDeleted) {
      final deletedVersion = remote.isDeleted ? remote : local;

      return MessageConflictResolution(
        winner: remote.isDeleted ? ConflictWinner.remote : ConflictWinner.local,
        resolvedMessage: deletedVersion,
        resolutionMethod: ResolutionMethod.content,
        explanation: 'Deletion state propagated',
      );
    }

    // Neither deleted, use timestamp
    return MessageConflictStrategy().resolve(
      local: local,
      remote: remote,
      source: source,
    );
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Conflict resolution result
class MessageConflictResolution {
  final ConflictWinner winner;
  final MessageEntity resolvedMessage;
  final ResolutionMethod resolutionMethod;
  final String explanation;

  MessageConflictResolution({
    required this.winner,
    required this.resolvedMessage,
    required this.resolutionMethod,
    required this.explanation,
  });

  factory MessageConflictResolution.noConflict(MessageEntity message) {
    return MessageConflictResolution(
      winner: ConflictWinner.noConflict,
      resolvedMessage: message,
      resolutionMethod: ResolutionMethod.content,
      explanation: 'No conflict detected',
    );
  }

  bool get hasConflict => winner != ConflictWinner.noConflict;
}

/// Conflict winner
enum ConflictWinner {
  local,
  remote,
  merged,
  noConflict,
}

/// Resolution method
enum ResolutionMethod {
  timestamp, // Last Write Wins
  source, // Source priority
  content, // Content-based merge
  manual, // Manual resolution
}

/// Conflict resolution statistics
class ConflictResolutionStats {
  final int totalConflicts;
  final int resolvedByTimestamp;
  final int resolvedBySource;
  final int resolvedByContent;
  final int manualResolution;

  const ConflictResolutionStats({
    required this.totalConflicts,
    required this.resolvedByTimestamp,
    required this.resolvedBySource,
    required this.resolvedByContent,
    required this.manualResolution,
  });

  double get timestampRate => totalConflicts > 0
      ? resolvedByTimestamp / totalConflicts
      : 0.0;

  double get sourceRate => totalConflicts > 0
      ? resolvedBySource / totalConflicts
      : 0.0;

  double get contentRate => totalConflicts > 0
      ? resolvedByContent / totalConflicts
      : 0.0;
}
