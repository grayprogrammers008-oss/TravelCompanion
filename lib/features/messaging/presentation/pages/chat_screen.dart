import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/image_picker_service.dart';
import '../../data/services/storage_service.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../providers/messaging_providers.dart';
import '../providers/ble_providers.dart';
import '../providers/p2p_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/sync_fab.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/who_reacted_sheet.dart';
import '../widgets/nearby_peers_sheet.dart';
import '../widgets/p2p_peers_sheet.dart';
import '../widgets/sync_status_sheet.dart';
import '../providers/sync_providers.dart';

/// Chat Screen
/// Main messaging interface with realtime updates
class ChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  MessageEntity? _replyToMessage;

  @override
  void initState() {
    super.initState();
    // Mark all messages as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
      _initializeBLE();
    });
  }

  /// Initialize BLE services for P2P messaging
  Future<void> _initializeBLE() async {
    try {
      final bleNotifier = ref.read(bleServiceNotifierProvider.notifier);
      await bleNotifier.initialize(
        userId: widget.currentUserId,
        userName: widget.tripName, // Using trip name as user display name
      );
    } catch (e) {
      debugPrint('BLE initialization failed: $e');
      // Non-critical error - P2P messaging will be unavailable
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Mark all messages as read
  Future<void> _markAllAsRead() async {
    try {
      final markAsReadUseCase = ref.read(markMessageAsReadUseCaseProvider);
      final messages = await ref.read(
        tripMessagesOnceProvider(widget.tripId).future,
      );

      for (final message in messages) {
        if (!message.isReadBy(widget.currentUserId)) {
          await markAsReadUseCase.execute(
            messageId: message.id,
            userId: widget.currentUserId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Send a message
  Future<void> _handleSendMessage(String messageText) async {
    try {
      final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);

      final result = await sendMessageUseCase.execute(
        tripId: widget.tripId,
        senderId: widget.currentUserId,
        message: messageText,
        messageType: MessageType.text,
        replyToId: _replyToMessage?.id,
      );

      result.fold(
        onSuccess: (message) {
          // Clear reply state
          if (_replyToMessage != null) {
            setState(() {
              _replyToMessage = null;
            });
          }

          // Scroll to bottom
          _scrollToBottom();
        },
        onFailure: (error) {
          _showError(error);
        },
      );
    } catch (e) {
      _showError('Failed to send message: $e');
    }
  }

  /// Scroll to bottom of list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Show error snackbar
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handle attachment button tap
  Future<void> _handleAttachmentTap() async {
    // Show options: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryTeal),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.accentCoral),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Pick image
    final imagePickerService = ImagePickerService();
    File? imageFile;

    if (source == ImageSource.camera) {
      imageFile = await imagePickerService.pickImageFromCamera();
    } else {
      imageFile = await imagePickerService.pickImageFromGallery();
    }

    if (imageFile == null) return;

    // Validate image
    if (!imagePickerService.validateImage(imageFile)) {
      _showError('Invalid image. Please select a valid image file (max 10MB)');
      return;
    }

    // Upload and send
    await _uploadAndSendImage(imageFile);
  }

  /// Upload image and send message
  Future<void> _uploadAndSendImage(File imageFile) async {
    try {
      // Show uploading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spacingMd),
                  Text('Uploading image...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload to storage
      final storageService = StorageService();
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      final imageUrl = await storageService.uploadImage(
        file: imageFile,
        tripId: widget.tripId,
        messageId: messageId,
      );

      // Close uploading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Send message with image attachment
      final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
      final result = await sendMessageUseCase.execute(
        tripId: widget.tripId,
        senderId: widget.currentUserId,
        message: '', // Empty text for image-only message
        messageType: MessageType.image,
        attachmentUrl: imageUrl,
        replyToId: _replyToMessage?.id,
      );

      result.fold(
        onSuccess: (message) {
          if (_replyToMessage != null) {
            setState(() {
              _replyToMessage = null;
            });
          }
          _scrollToBottom();
        },
        onFailure: (error) {
          _showError(error);
        },
      );
    } catch (e) {
      // Close uploading dialog if still open
      if (mounted) {
        Navigator.pop(context);
      }
      _showError('Failed to upload image: $e');
    }
  }

  /// Show message actions bottom sheet
  void _showMessageActions(MessageEntity message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => _MessageActionsSheet(
        message: message,
        currentUserId: widget.currentUserId,
        onReply: () {
          Navigator.pop(context);
          setState(() {
            _replyToMessage = message;
          });
        },
        onReact: (emoji) {
          Navigator.pop(context);
          _handleAddReaction(message.id, emoji);
        },
        onReactMore: () {
          Navigator.pop(context);
          _showReactionPicker(message.id);
        },
        onDelete: () {
          Navigator.pop(context);
          _handleDeleteMessage(message.id);
        },
      ),
    );
  }

  /// Show enhanced reaction picker
  void _showReactionPicker(String messageId) {
    ReactionPicker.show(
      context,
      onEmojiSelected: (emoji) {
        _handleAddReaction(messageId, emoji);
      },
    );
  }

  /// Show who reacted sheet
  void _showWhoReacted(MessageEntity message, {String? selectedEmoji}) {
    // Build user names map from reactions
    final userNames = <String, String>{};
    for (final reaction in message.reactions) {
      // In a real app, you would fetch user names from a user service
      // For now, use sender name as a placeholder
      userNames[reaction.userId] = 'User ${reaction.userId.substring(0, 6)}';
    }

    WhoReactedSheet.show(
      context,
      reactions: message.reactions,
      userNames: userNames,
      selectedEmoji: selectedEmoji,
    );
  }

  /// Handle add reaction
  Future<void> _handleAddReaction(String messageId, String emoji) async {
    try {
      final addReactionUseCase = ref.read(addReactionUseCaseProvider);

      final result = await addReactionUseCase.execute(
        messageId: messageId,
        userId: widget.currentUserId,
        emoji: emoji,
      );

      result.fold(
        onSuccess: (_) {},
        onFailure: (error) => _showError(error),
      );
    } catch (e) {
      _showError('Failed to add reaction: $e');
    }
  }

  /// Handle delete message
  Future<void> _handleDeleteMessage(String messageId) async {
    try {
      final deleteMessageUseCase = ref.read(deleteMessageUseCaseProvider);

      final result = await deleteMessageUseCase.execute(
        messageId: messageId,
        userId: widget.currentUserId,
      );

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onFailure: (error) => _showError(error),
      );
    } catch (e) {
      _showError('Failed to delete message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch messages stream
    final messagesAsync = ref.watch(tripMessagesProvider(widget.tripId));

    // Watch connectivity status
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    // Watch pending messages count
    final pendingAsync = ref.watch(pendingMessagesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tripName),
            // Connectivity indicator
            connectivityAsync.whenOrNull(
              data: (connectivity) {
                final isOffline = connectivity.name == 'none';
                if (!isOffline) return null;

                return Text(
                  'Offline',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.warning,
                      ),
                );
              },
            ) ??
                const SizedBox.shrink(),
          ],
        ),
        actions: [
          // Sync Status button
          Consumer(
            builder: (context, ref, child) {
              final isSyncing = ref.watch(isSyncingProvider);
              final queueSize = ref.watch(queueSizeProvider);

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isSyncing ? Icons.sync : Icons.sync_alt,
                      color: isSyncing ? Colors.blue : null,
                    ),
                    tooltip: 'Sync Status',
                    onPressed: () => SyncStatusSheet.show(context),
                  ),
                  if (queueSize > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          queueSize > 99 ? '99+' : queueSize.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // WiFi Direct/Multipeer High-Speed P2P button
          IconButton(
            icon: const Icon(Icons.wifi),
            tooltip: 'High-Speed P2P (WiFi/Multipeer)',
            onPressed: () {
              P2PPeersSheet.show(
                context,
                userId: widget.currentUserId,
                userName: widget.tripName,
              );
            },
          ),
          // BLE P2P Nearby Peers button
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            tooltip: 'Nearby Peers (BLE)',
            onPressed: () {
              NearbyPeersSheet.show(
                context,
                userId: widget.currentUserId,
                userName: widget.tripName,
              );
            },
          ),
          // Pending messages indicator
          pendingAsync.whenOrNull(
            data: (count) {
              if (count == 0) return null;

              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingMd),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXs,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Latest messages at bottom
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingMd,
                    bottom: AppTheme.spacingMd,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    return MessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                      currentUserId: widget.currentUserId,
                      onLongPress: () => _showMessageActions(message),
                      onReactionTap: () => _showReactionPicker(message.id),
                      onReactionLongPress: (emoji) => _showWhoReacted(message, selectedEmoji: emoji),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Failed to load messages',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Message input
          MessageInput(
            onSend: _handleSendMessage,
            onAttachmentTap: _handleAttachmentTap,
            replyToMessage: _replyToMessage?.message,
            onCancelReply: () {
              setState(() {
                _replyToMessage = null;
              });
            },
          ),
        ],
      ),
      floatingActionButton: SyncFab(tripId: widget.tripId),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.shadowTeal,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.neutral900,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Start the conversation!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Message Actions Bottom Sheet
class _MessageActionsSheet extends StatelessWidget {
  final MessageEntity message;
  final String currentUserId;
  final VoidCallback onReply;
  final Function(String emoji) onReact;
  final VoidCallback onReactMore;
  final VoidCallback onDelete;

  const _MessageActionsSheet({
    required this.message,
    required this.currentUserId,
    required this.onReply,
    required this.onReact,
    required this.onReactMore,
    required this.onDelete,
  });

  bool get _isOwnMessage => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Quick reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ReactionButton(emoji: '👍', onTap: () => onReact('👍')),
                  _ReactionButton(emoji: '❤️', onTap: () => onReact('❤️')),
                  _ReactionButton(emoji: '😂', onTap: () => onReact('😂')),
                  _ReactionButton(emoji: '😮', onTap: () => onReact('😮')),
                  _ReactionButton(emoji: '🎉', onTap: () => onReact('🎉')),
                  _ReactionButton(
                    emoji: '➕',
                    onTap: onReactMore,
                    isMore: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),
            const Divider(),

            // Actions
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: onReply,
            ),

            if (_isOwnMessage)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.error),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// Reaction Button
class _ReactionButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  final bool isMore;

  const _ReactionButton({
    required this.emoji,
    required this.onTap,
    this.isMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isMore ? AppTheme.primaryPale : AppTheme.neutral100,
          shape: BoxShape.circle,
          border: Border.all(
            color: isMore ? AppTheme.primaryTeal : AppTheme.neutral200,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              color: isMore ? AppTheme.primaryTeal : null,
            ),
          ),
        ),
      ),
    );
  }
}
