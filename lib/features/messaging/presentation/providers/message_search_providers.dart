import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message_entity.dart';
import 'conversation_providers.dart';

/// Parameters for message search
class MessageSearchParams {
  final String conversationId;
  final String query;
  final String? filterType; // null = all, 'text', 'image', 'document'

  const MessageSearchParams({
    required this.conversationId,
    required this.query,
    this.filterType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageSearchParams &&
        other.conversationId == conversationId &&
        other.query == query &&
        other.filterType == filterType;
  }

  @override
  int get hashCode =>
      conversationId.hashCode ^ query.hashCode ^ filterType.hashCode;
}

/// Provider for searching messages in a conversation
/// Usage: ref.watch(messageSearchProvider(MessageSearchParams(...)))
final messageSearchProvider = FutureProvider.autoDispose
    .family<List<MessageEntity>, MessageSearchParams>((ref, params) async {
  if (params.query.isEmpty) {
    return [];
  }

  // Get all messages from the conversation
  final messagesAsync = await ref.watch(
    conversationMessagesProvider(params.conversationId).future,
  );

  final query = params.query.toLowerCase();

  // Filter messages
  return messagesAsync.where((message) {
    // Skip deleted messages
    if (message.isDeleted) return false;

    // Apply type filter
    if (params.filterType != null) {
      switch (params.filterType) {
        case 'text':
          if (message.messageType != MessageType.text) return false;
          break;
        case 'image':
          if (message.messageType != MessageType.image) return false;
          break;
        case 'document':
          if (message.messageType != MessageType.document) return false;
          break;
      }
    }

    // Search in message content
    if (message.message?.toLowerCase().contains(query) ?? false) {
      return true;
    }

    // Search in sender name
    if (message.senderName?.toLowerCase().contains(query) ?? false) {
      return true;
    }

    return false;
  }).toList();
});

/// State class for message search
class MessageSearchState {
  final String query;
  final String? filterType;
  final bool isSearching;
  final List<MessageEntity> results;
  final String? error;

  const MessageSearchState({
    this.query = '',
    this.filterType,
    this.isSearching = false,
    this.results = const [],
    this.error,
  });

  MessageSearchState copyWith({
    String? query,
    String? filterType,
    bool? isSearching,
    List<MessageEntity>? results,
    String? error,
  }) {
    return MessageSearchState(
      query: query ?? this.query,
      filterType: filterType ?? this.filterType,
      isSearching: isSearching ?? this.isSearching,
      results: results ?? this.results,
      error: error,
    );
  }
}

/// Notifier for message search state management
class MessageSearchNotifier extends Notifier<MessageSearchState> {
  @override
  MessageSearchState build() => const MessageSearchState();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setFilterType(String? filterType) {
    state = state.copyWith(filterType: filterType);
  }

  void setResults(List<MessageEntity> results) {
    state = state.copyWith(results: results, isSearching: false);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isSearching: false);
  }

  void startSearch() {
    state = state.copyWith(isSearching: true, error: null);
  }

  void clear() {
    state = const MessageSearchState();
  }
}

/// Provider for message search notifier
final messageSearchNotifierProvider =
    NotifierProvider<MessageSearchNotifier, MessageSearchState>(
  MessageSearchNotifier.new,
);
