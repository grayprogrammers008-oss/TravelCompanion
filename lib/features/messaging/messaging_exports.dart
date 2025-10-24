/// Messaging Module Exports
/// Barrel file for easy importing of messaging module components
library messaging_exports;

// ============================================================================
// DOMAIN LAYER
// ============================================================================

// Entities
export 'domain/entities/message_entity.dart';
export 'domain/entities/notification_payload.dart';

// Repositories
export 'domain/repositories/message_repository.dart';

// Use Cases
export 'domain/usecases/send_message_usecase.dart';
export 'domain/usecases/get_trip_messages_usecase.dart';
export 'domain/usecases/mark_message_as_read_usecase.dart';
export 'domain/usecases/add_reaction_usecase.dart';
export 'domain/usecases/remove_reaction_usecase.dart';
export 'domain/usecases/delete_message_usecase.dart';
export 'domain/usecases/sync_pending_messages_usecase.dart';
export 'domain/usecases/get_unread_count_usecase.dart';

// ============================================================================
// DATA LAYER
// ============================================================================

// Models
export '../../shared/models/message_model.dart';

// Data Sources
export 'data/datasources/message_local_datasource.dart';
export 'data/datasources/message_remote_datasource.dart';

// Services
export 'data/services/fcm_service.dart';
export 'data/services/image_picker_service.dart';
export 'data/services/storage_service.dart';

// Repositories Implementation
export 'data/repositories/message_repository_impl.dart';

// Initialization
export 'data/initialization/messaging_initialization.dart';

// ============================================================================
// PRESENTATION LAYER
// ============================================================================

// Providers
export 'presentation/providers/messaging_providers.dart';
export 'presentation/providers/notification_provider.dart';

// Pages
export 'presentation/pages/chat_screen.dart';
export 'presentation/pages/message_queue_screen.dart';

// Widgets
export 'presentation/widgets/message_bubble.dart';
export 'presentation/widgets/message_input.dart';
export 'presentation/widgets/sync_status_banner.dart';
export 'presentation/widgets/sync_fab.dart';
export 'presentation/widgets/in_app_notification.dart';
export 'presentation/widgets/attachment_picker.dart';
export 'presentation/widgets/image_viewer.dart';
export 'presentation/widgets/reaction_picker.dart';
export 'presentation/widgets/who_reacted_sheet.dart';

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example: Initialize messaging module in main()
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize messaging module
///   await MessagingInitialization.initialize();
///
///   runApp(
///     ProviderScope(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```

/// Example: Send a message
/// ```dart
/// class ChatScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ElevatedButton(
///       onPressed: () async {
///         final useCase = ref.read(sendMessageUseCaseProvider);
///         final result = await useCase.execute(
///           tripId: 'trip-123',
///           senderId: 'user-456',
///           message: 'Hello!',
///           messageType: MessageType.text,
///         );
///
///         result.fold(
///           onSuccess: (message) => print('Message sent: ${message.id}'),
///           onFailure: (error) => print('Error: $error'),
///         );
///       },
///       child: Text('Send'),
///     );
///   }
/// }
/// ```

/// Example: Watch messages stream
/// ```dart
/// class MessagesList extends ConsumerWidget {
///   final String tripId;
///
///   const MessagesList({required this.tripId});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final messagesAsync = ref.watch(tripMessagesProvider(tripId));
///
///     return messagesAsync.when(
///       data: (messages) {
///         return ListView.builder(
///           itemCount: messages.length,
///           itemBuilder: (context, index) {
///             final message = messages[index];
///             return ListTile(
///               title: Text(message.message ?? ''),
///               subtitle: Text(message.senderName ?? 'Unknown'),
///             );
///           },
///         );
///       },
///       loading: () => CircularProgressIndicator(),
///       error: (error, stack) => Text('Error: $error'),
///     );
///   }
/// }
/// ```

/// Example: Get unread count
/// ```dart
/// class UnreadBadge extends ConsumerWidget {
///   final String tripId;
///   final String userId;
///
///   const UnreadBadge({required this.tripId, required this.userId});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final params = UnreadCountParams(tripId, userId);
///     final unreadAsync = ref.watch(unreadCountProvider(params));
///
///     return unreadAsync.when(
///       data: (count) {
///         if (count == 0) return SizedBox.shrink();
///         return Badge(
///           label: Text('$count'),
///           child: Icon(Icons.message),
///         );
///       },
///       loading: () => SizedBox.shrink(),
///       error: (error, stack) => SizedBox.shrink(),
///     );
///   }
/// }
/// ```

/// Example: Sync pending messages
/// ```dart
/// class SyncButton extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return ElevatedButton(
///       onPressed: () async {
///         final useCase = ref.read(syncPendingMessagesUseCaseProvider);
///         final result = await useCase.execute();
///
///         result.fold(
///           onSuccess: (syncResult) {
///             if (syncResult.allSynced) {
///               ScaffoldMessenger.of(context).showSnackBar(
///                 SnackBar(content: Text('All messages synced!')),
///               );
///             } else if (syncResult.someFailed) {
///               ScaffoldMessenger.of(context).showSnackBar(
///                 SnackBar(
///                   content: Text('${syncResult.syncedMessages} synced, '
///                       '${syncResult.failedMessages} failed'),
///                 ),
///               );
///             }
///           },
///           onFailure: (error) {
///             ScaffoldMessenger.of(context).showSnackBar(
///               SnackBar(content: Text('Sync failed: $error')),
///             );
///           },
///         );
///       },
///       child: Text('Sync Messages'),
///     );
///   }
/// }
/// ```

/// Example: Add reaction
/// ```dart
/// class MessageReactionButton extends ConsumerWidget {
///   final String messageId;
///   final String userId;
///   final String emoji;
///
///   const MessageReactionButton({
///     required this.messageId,
///     required this.userId,
///     required this.emoji,
///   });
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     return IconButton(
///       icon: Text(emoji),
///       onPressed: () async {
///         final useCase = ref.read(addReactionUseCaseProvider);
///         final result = await useCase.execute(
///           messageId: messageId,
///           userId: userId,
///           emoji: emoji,
///         );
///
///         result.fold(
///           onSuccess: (_) => print('Reaction added'),
///           onFailure: (error) => print('Error: $error'),
///         );
///       },
///     );
///   }
/// }
/// ```
