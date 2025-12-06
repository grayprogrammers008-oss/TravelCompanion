import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/conversation_remote_datasource.dart';
import '../../data/repositories/conversation_repository_impl.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../../domain/usecases/get_trip_conversations_usecase.dart';

// ============================================================================
// DATA SOURCE PROVIDERS
// ============================================================================

/// Provider for Conversation Remote Data Source
final conversationRemoteDataSourceProvider =
    Provider<ConversationRemoteDataSource>((ref) {
  return ConversationRemoteDataSource();
});

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

/// Provider for Conversation Repository
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(
    remoteDataSource: ref.read(conversationRemoteDataSourceProvider),
  );
});

// ============================================================================
// USE CASE PROVIDERS
// ============================================================================

/// Provider for Create Conversation Use Case
final createConversationUseCaseProvider = Provider<CreateConversationUseCase>((ref) {
  return CreateConversationUseCase(ref.read(conversationRepositoryProvider));
});

/// Provider for Get Trip Conversations Use Case
final getTripConversationsUseCaseProvider =
    Provider<GetTripConversationsUseCase>((ref) {
  return GetTripConversationsUseCase(ref.read(conversationRepositoryProvider));
});

/// Provider for Leave Conversation Use Case
final leaveConversationUseCaseProvider = Provider<LeaveConversationUseCase>((ref) {
  return LeaveConversationUseCase(ref.read(conversationRepositoryProvider));
});

/// Provider for Add Conversation Members Use Case
final addConversationMembersUseCaseProvider =
    Provider<AddConversationMembersUseCase>((ref) {
  return AddConversationMembersUseCase(ref.read(conversationRepositoryProvider));
});

/// Provider for Mark Conversation As Read Use Case
final markConversationAsReadUseCaseProvider =
    Provider<MarkConversationAsReadUseCase>((ref) {
  return MarkConversationAsReadUseCase(ref.read(conversationRepositoryProvider));
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Parameters for trip conversations provider
class TripConversationsParams {
  final String tripId;
  final String userId;

  const TripConversationsParams({
    required this.tripId,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripConversationsParams &&
        other.tripId == tripId &&
        other.userId == userId;
  }

  @override
  int get hashCode => tripId.hashCode ^ userId.hashCode;
}

/// Provider for trip conversations list
/// Usage: ref.watch(tripConversationsProvider(TripConversationsParams(...)))
final tripConversationsProvider = FutureProvider.autoDispose
    .family<List<ConversationEntity>, TripConversationsParams>((ref, params) async {
  final repository = ref.read(conversationRepositoryProvider);
  final result = await repository.getTripConversations(
    tripId: params.tripId,
    userId: params.userId,
  );

  return result.fold(
    onSuccess: (conversations) => conversations,
    onFailure: (error) => throw Exception(error),
  );
});

/// Stream provider for trip conversations with real-time updates
/// Listens to message changes and refreshes conversation list automatically
/// Usage: ref.watch(tripConversationsStreamProvider(TripConversationsParams(...)))
final tripConversationsStreamProvider = StreamProvider.autoDispose
    .family<List<ConversationEntity>, TripConversationsParams>((ref, params) {
  final dataSource = ref.read(conversationRemoteDataSourceProvider);
  final repository = ref.read(conversationRepositoryProvider);

  // Listen to trip messages stream and refresh conversations on any change
  return dataSource.subscribeToTripMessages(params.tripId).asyncMap((_) async {
    final result = await repository.getTripConversations(
      tripId: params.tripId,
      userId: params.userId,
    );
    return result.fold(
      onSuccess: (conversations) => conversations,
      onFailure: (error) => throw Exception(error),
    );
  });
});

/// Parameters for single conversation provider
class ConversationParams {
  final String conversationId;
  final String userId;

  const ConversationParams({
    required this.conversationId,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationParams &&
        other.conversationId == conversationId &&
        other.userId == userId;
  }

  @override
  int get hashCode => conversationId.hashCode ^ userId.hashCode;
}

/// Provider for a single conversation with details
/// Usage: ref.watch(conversationProvider(ConversationParams(...)))
final conversationProvider = FutureProvider.autoDispose
    .family<ConversationEntity, ConversationParams>((ref, params) async {
  final repository = ref.read(conversationRepositoryProvider);
  final result = await repository.getConversation(
    conversationId: params.conversationId,
    userId: params.userId,
  );

  return result.fold(
    onSuccess: (conversation) => conversation,
    onFailure: (error) => throw Exception(error),
  );
});

/// Provider for conversation messages
/// Usage: ref.watch(conversationMessagesProvider(conversationId))
final conversationMessagesProvider = FutureProvider.autoDispose
    .family<List<MessageEntity>, String>((ref, conversationId) async {
  final repository = ref.read(conversationRepositoryProvider);
  final result = await repository.getConversationMessages(
    conversationId: conversationId,
  );

  return result.fold(
    onSuccess: (messages) => messages,
    onFailure: (error) => throw Exception(error),
  );
});

/// Stream provider for conversation messages (real-time)
/// Usage: ref.watch(conversationMessagesStreamProvider(conversationId))
final conversationMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<MessageEntity>, String>((ref, conversationId) {
  final repository = ref.read(conversationRepositoryProvider);
  return repository.watchConversationMessages(conversationId);
});

/// Provider for conversation members
/// Usage: ref.watch(conversationMembersProvider(conversationId))
final conversationMembersProvider = FutureProvider.autoDispose
    .family<List<ConversationMemberEntity>, String>((ref, conversationId) async {
  final repository = ref.read(conversationRepositoryProvider);
  final result = await repository.getConversationMembers(conversationId);

  return result.fold(
    onSuccess: (members) => members,
    onFailure: (error) => throw Exception(error),
  );
});

// ============================================================================
// NOTIFIER FOR CREATE CONVERSATION
// ============================================================================

/// State for create conversation
class CreateConversationState {
  final bool isLoading;
  final String? error;
  final ConversationEntity? createdConversation;

  const CreateConversationState({
    this.isLoading = false,
    this.error,
    this.createdConversation,
  });

  CreateConversationState copyWith({
    bool? isLoading,
    String? error,
    ConversationEntity? createdConversation,
  }) {
    return CreateConversationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdConversation: createdConversation,
    );
  }
}

/// Notifier for creating conversations
class CreateConversationNotifier extends Notifier<CreateConversationState> {
  @override
  CreateConversationState build() => const CreateConversationState();

  Future<ConversationEntity?> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(conversationRepositoryProvider);
    final result = await repository.createConversation(
      tripId: tripId,
      name: name,
      description: description,
      memberUserIds: memberUserIds,
      createdBy: createdBy,
      isDirectMessage: isDirectMessage,
    );

    ConversationEntity? created;
    result.fold(
      onSuccess: (conversation) {
        created = conversation;
        state = state.copyWith(
          isLoading: false,
          createdConversation: conversation,
        );
      },
      onFailure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
      },
    );
    return created;
  }

  void reset() {
    state = const CreateConversationState();
  }
}

/// Provider for create conversation notifier
final createConversationNotifierProvider =
    NotifierProvider.autoDispose<CreateConversationNotifier, CreateConversationState>(
  CreateConversationNotifier.new,
);

// ============================================================================
// DEFAULT GROUP PROVIDER
// ============================================================================

/// Provider to get the default "All Members" group for a trip
/// Usage: ref.watch(defaultGroupProvider(TripConversationsParams(...)))
final defaultGroupProvider = FutureProvider.autoDispose
    .family<ConversationEntity, TripConversationsParams>((ref, params) async {
  final repository = ref.read(conversationRepositoryProvider);
  final result = await repository.getDefaultGroup(
    tripId: params.tripId,
    userId: params.userId,
  );

  return result.fold(
    onSuccess: (conversation) => conversation,
    onFailure: (error) => throw Exception(error),
  );
});

// ============================================================================
// UNREAD COUNT PROVIDER
// ============================================================================

/// Provider to get total unread message count for a trip (all conversations)
/// Usage: ref.watch(tripUnreadCountProvider(TripConversationsParams(...)))
final tripUnreadCountProvider = StreamProvider.autoDispose
    .family<int, TripConversationsParams>((ref, params) {
  // Guard against empty userId or tripId to prevent PostgreSQL UUID errors
  if (params.userId.isEmpty || params.tripId.isEmpty) {
    return Stream.value(0);
  }

  final dataSource = ref.read(conversationRemoteDataSourceProvider);
  final repository = ref.read(conversationRepositoryProvider);

  // Listen to trip messages stream and calculate total unread count
  return dataSource.subscribeToTripMessages(params.tripId).asyncMap((_) async {
    final result = await repository.getTripConversations(
      tripId: params.tripId,
      userId: params.userId,
    );
    return result.fold(
      onSuccess: (conversations) {
        // Sum up all unread counts from all conversations
        return conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      },
      onFailure: (error) => 0,
    );
  });
});
