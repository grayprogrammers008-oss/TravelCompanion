import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../data/services/image_picker_service.dart';
import '../../data/services/storage_service.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/conversation_providers.dart';

/// Group Chat Page - Main chat interface for a conversation
class GroupChatPage extends ConsumerStatefulWidget {
  final String tripId;
  final String conversationId;
  final String currentUserId;

  const GroupChatPage({
    super.key,
    required this.tripId,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  ConsumerState<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends ConsumerState<GroupChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePickerService = ImagePickerService();
  final _storageService = StorageService();
  bool _isSending = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation as read when entering
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final useCase = ref.read(markConversationAsReadUseCaseProvider);
    await useCase.execute(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
    );
  }

  /// Show attachment options bottom sheet
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Photo Gallery'),
                subtitle: const Text('Choose from your photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              if (!kIsWeb) // Camera not available on web
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.camera_alt, color: Colors.green),
                  ),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a new photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from gallery and send
  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _imagePickerService.pickImageFromGallery();
      if (file != null) {
        await _sendImageMessage(file);
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick image from camera and send
  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _imagePickerService.pickImageFromCamera();
      if (file != null) {
        await _sendImageMessage(file);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload image and send as message
  Future<void> _sendImageMessage(File imageFile) async {
    if (_isUploadingImage) return;

    setState(() => _isUploadingImage = true);

    try {
      // Generate message ID for storage path
      final messageId = const Uuid().v4();

      // Upload image to Supabase Storage
      debugPrint('Uploading image...');
      final imageUrl = await _storageService.uploadImage(
        file: imageFile,
        tripId: widget.tripId,
        messageId: messageId,
      );

      debugPrint('Image uploaded: $imageUrl');

      // Send message with image URL
      final repository = ref.read(conversationRepositoryProvider);
      await repository.sendConversationMessage(
        conversationId: widget.conversationId,
        tripId: widget.tripId,
        senderId: widget.currentUserId,
        message: '📷 Photo',
        messageType: MessageType.image,
        attachmentUrl: imageUrl,
      );

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image sent!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final repository = ref.read(conversationRepositoryProvider);
      await repository.sendConversationMessage(
        conversationId: widget.conversationId,
        tripId: widget.tripId,
        senderId: widget.currentUserId,
        message: text,
        messageType: MessageType.text,
      );

      _messageController.clear();

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationProvider(ConversationParams(
        conversationId: widget.conversationId,
        userId: widget.currentUserId,
      )),
    );
    final messagesAsync = ref.watch(
      conversationMessagesStreamProvider(widget.conversationId),
    );

    return Scaffold(
      appBar: _buildAppBar(context, conversationAsync),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => const Center(child: AppLoadingIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
          // Message Input
          _buildMessageInput(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AsyncValue<ConversationEntity> conversationAsync,
  ) {
    return AppBar(
      titleSpacing: 0,
      title: conversationAsync.when(
        data: (conversation) => InkWell(
          onTap: () => _navigateToInfo(context),
          child: Row(
            children: [
              _buildConversationAvatar(conversation),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.getDisplayName(widget.currentUserId),
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${conversation.memberCount} members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Text('Loading...'),
        error: (error, stackTrace) => const Text('Chat'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _navigateToInfo(context),
          tooltip: 'Group Info',
        ),
      ],
    );
  }

  Widget _buildConversationAvatar(ConversationEntity conversation) {
    if (conversation.avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(conversation.avatarUrl!),
      );
    }

    if (conversation.isDirectMessage && conversation.members.isNotEmpty) {
      final otherMember = conversation.members.firstWhere(
        (m) => m.userId != widget.currentUserId,
        orElse: () => conversation.members.first,
      );
      return UserAvatarWidget(
        imageUrl: otherMember.userAvatarUrl,
        userName: otherMember.userName ?? 'User',
        size: 40,
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: context.primaryColor.withValues(alpha: 0.2),
      child: Icon(
        Icons.group,
        color: context.primaryColor,
        size: 24,
      ),
    );
  }

  Widget _buildMessagesList(List<MessageEntity> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Be the first to say something!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    // Messages are displayed in reverse order (newest at bottom)
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == widget.currentUserId;

        // Check if we should show date header
        final showDateHeader = index == messages.length - 1 ||
            !_isSameDay(
              message.createdAt,
              messages[index + 1].createdAt,
            );

        // Check if we should show sender name (for group chats)
        final showSenderName = !isMe &&
            (index == messages.length - 1 ||
                messages[index + 1].senderId != message.senderId);

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(message.createdAt),
            _MessageBubble(
              message: message,
              isMe: isMe,
              showSenderName: showSenderName,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Text(
            _formatDateHeader(date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        top: AppTheme.spacingSm,
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            icon: _isUploadingImage
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade600,
                      ),
                    ),
                  )
                : const Icon(Icons.attach_file),
            onPressed: _isUploadingImage ? null : _showAttachmentOptions,
            color: Colors.grey.shade600,
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: AppTheme.spacingSm),

          // Send button
          Material(
            color: context.primaryColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Failed to load messages',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(
                conversationMessagesStreamProvider(widget.conversationId),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToInfo(BuildContext context) {
    context.push(
      '/trips/${widget.tripId}/conversations/${widget.conversationId}/info',
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Individual message bubble widget
class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool showSenderName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSenderName,
  });

  bool get _isImageMessage =>
      message.messageType == MessageType.image && message.attachmentUrl != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Sender avatar for group chats
            if (showSenderName)
              UserAvatarWidget(
                imageUrl: message.senderAvatarUrl,
                userName: message.senderName ?? 'User',
                size: 28,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: AppTheme.spacingXs),
          ],

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingXs,
                      bottom: 2,
                    ),
                    child: Text(
                      message.senderName ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.primaryColor,
                          ),
                    ),
                  ),
                if (_isImageMessage)
                  _buildImageBubble(context)
                else
                  _buildTextBubble(context),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: AppTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isMe ? context.primaryColor : Colors.grey.shade200,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppTheme.radiusMd),
          topRight: const Radius.circular(AppTheme.radiusMd),
          bottomLeft: Radius.circular(
            isMe ? AppTheme.radiusMd : AppTheme.radiusXs,
          ),
          bottomRight: Radius.circular(
            isMe ? AppTheme.radiusXs : AppTheme.radiusMd,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.message ?? '',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? context.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusMd),
            topRight: const Radius.circular(AppTheme.radiusMd),
            bottomLeft: Radius.circular(
              isMe ? AppTheme.radiusMd : AppTheme.radiusXs,
            ),
            bottomRight: Radius.circular(
              isMe ? AppTheme.radiusXs : AppTheme.radiusMd,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTheme.radiusMd),
                topRight: const Radius.circular(AppTheme.radiusMd),
                bottomLeft: Radius.circular(
                  isMe ? AppTheme.radiusMd : AppTheme.radiusXs,
                ),
                bottomRight: Radius.circular(
                  isMe ? AppTheme.radiusXs : AppTheme.radiusMd,
                ),
              ),
              child: Stack(
                children: [
                  Image.network(
                    message.attachmentUrl!,
                    width: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 250,
                        height: 150,
                        color: Colors.grey.shade300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 250,
                        height: 150,
                        color: Colors.grey.shade300,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Time overlay on image
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatTime(message.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          imageUrl: message.attachmentUrl!,
          senderName: message.senderName ?? 'Unknown',
          timestamp: message.createdAt,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Full screen image viewer
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String senderName;
  final DateTime timestamp;

  const _FullScreenImageView({
    required this.imageUrl,
    required this.senderName,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              _formatDateTime(timestamp),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }
}
