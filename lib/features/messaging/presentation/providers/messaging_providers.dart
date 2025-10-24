import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/message_local_datasource.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/add_reaction_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/get_trip_messages_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_message_as_read_usecase.dart';
import '../../domain/usecases/remove_reaction_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/sync_pending_messages_usecase.dart';

// ============================================================================
// DATA SOURCE PROVIDERS
// ============================================================================

/// Provider for Message Local Data Source (Hive)
final messageLocalDataSourceProvider = Provider<MessageLocalDataSource>((ref) {
  return MessageLocalDataSource();
});

/// Provider for Message Remote Data Source (Supabase)
final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((ref) {
  return MessageRemoteDataSource();
});

/// Provider for Connectivity
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

/// Provider for Message Repository
/// Coordinates between local and remote data sources
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(
    localDataSource: ref.read(messageLocalDataSourceProvider),
    remoteDataSource: ref.read(messageRemoteDataSourceProvider),
    connectivity: ref.read(connectivityProvider),
  );
});

// ============================================================================
// USE CASE PROVIDERS
// ============================================================================

/// Provider for Send Message Use Case
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Get Trip Messages Use Case
final getTripMessagesUseCaseProvider = Provider<GetTripMessagesUseCase>((ref) {
  return GetTripMessagesUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Mark Message as Read Use Case
final markMessageAsReadUseCaseProvider = Provider<MarkMessageAsReadUseCase>((ref) {
  return MarkMessageAsReadUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Add Reaction Use Case
final addReactionUseCaseProvider = Provider<AddReactionUseCase>((ref) {
  return AddReactionUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Remove Reaction Use Case
final removeReactionUseCaseProvider = Provider<RemoveReactionUseCase>((ref) {
  return RemoveReactionUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Delete Message Use Case
final deleteMessageUseCaseProvider = Provider<DeleteMessageUseCase>((ref) {
  return DeleteMessageUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Sync Pending Messages Use Case
final syncPendingMessagesUseCaseProvider = Provider<SyncPendingMessagesUseCase>((ref) {
  return SyncPendingMessagesUseCase(ref.read(messageRepositoryProvider));
});

/// Provider for Get Unread Count Use Case
final getUnreadCountUseCaseProvider = Provider<GetUnreadCountUseCase>((ref) {
  return GetUnreadCountUseCase(ref.read(messageRepositoryProvider));
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Stream Provider: Trip Messages
/// Provides a realtime stream of messages for a specific trip
/// Usage: ref.watch(tripMessagesProvider(tripId))
final tripMessagesProvider = StreamProvider.family<List<MessageEntity>, String>((ref, tripId) {
  final repository = ref.read(messageRepositoryProvider);
  return repository.subscribeToTripMessages(tripId);
});

/// Future Provider: Trip Messages (One-time fetch)
/// Use this for initial load or when you don't need realtime updates
/// Usage: ref.watch(tripMessagesOnceProvider(tripId))
final tripMessagesOnceProvider = FutureProvider.family<List<MessageEntity>, String>((ref, tripId) async {
  final repository = ref.read(messageRepositoryProvider);
  return repository.getTripMessages(tripId: tripId);
});

/// Future Provider: Unread Count
/// Gets the count of unread messages for a trip
/// Usage: ref.watch(unreadCountProvider(UnreadCountParams(tripId, userId)))
final unreadCountProvider = FutureProvider.family<int, UnreadCountParams>(
  (ref, params) async {
    final repository = ref.read(messageRepositoryProvider);
    return repository.getUnreadCount(
      tripId: params.tripId,
      userId: params.userId,
    );
  },
);

/// Future Provider: Pending Messages Count
/// Gets the count of pending messages in the offline queue
/// Usage: ref.watch(pendingMessagesCountProvider)
final pendingMessagesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(messageRepositoryProvider);
  final pending = await repository.getPendingMessages();
  return pending.length;
});

/// Future Provider: Pending Messages by Trip
/// Gets pending messages for a specific trip
/// Usage: ref.watch(pendingMessagesByTripProvider(tripId))
final pendingMessagesByTripProvider = FutureProvider.family<List<QueuedMessageEntity>, String>(
  (ref, tripId) async {
    final repository = ref.read(messageRepositoryProvider);
    return repository.getPendingMessagesByTrip(tripId);
  },
);

/// Stream Provider: Message Updates
/// Provides a realtime stream for a specific message
/// Usage: ref.watch(messageUpdatesProvider(messageId))
final messageUpdatesProvider = StreamProvider.family<MessageEntity, String>((ref, messageId) {
  final repository = ref.read(messageRepositoryProvider);
  return repository.subscribeToMessageUpdates(messageId);
});

/// State Provider: Connectivity Status
/// Tracks the current connectivity status
/// Usage: ref.watch(connectivityStatusProvider)
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  final connectivity = ref.read(connectivityProvider);
  return connectivity.onConnectivityChanged;
});

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Parameters for unread count provider
class UnreadCountParams {
  final String tripId;
  final String userId;

  UnreadCountParams(this.tripId, this.userId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnreadCountParams &&
        other.tripId == tripId &&
        other.userId == userId;
  }

  @override
  int get hashCode => tripId.hashCode ^ userId.hashCode;
}
