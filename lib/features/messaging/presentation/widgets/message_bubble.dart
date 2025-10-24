import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';
import 'image_viewer.dart';

/// Message Bubble Widget
/// Displays a single message with sender/receiver styling
class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final String currentUserId;
  final VoidCallback? onLongPress;
  final VoidCallback? onReactionTap;
  final Function(String emoji)? onReactionLongPress;
  final VoidCallback? onReplyTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onLongPress,
    this.onReactionTap,
    this.onReactionLongPress,
    this.onReplyTap,
  });

  bool get _isOwnMessage => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacing2xs,
        ),
        child: Row(
          mainAxisAlignment:
              _isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for received messages
            if (!_isOwnMessage) ...[
              _buildAvatar(),
              const SizedBox(width: AppTheme.spacingXs),
            ],

            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: _isOwnMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (for received messages)
                  if (!_isOwnMessage && message.senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppTheme.spacingXs,
                        bottom: 2,
                      ),
                      child: Text(
                        message.senderName!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.neutral600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: _isOwnMessage
                          ? AppTheme.primaryTeal
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppTheme.radiusLg),
                        topRight: const Radius.circular(AppTheme.radiusLg),
                        bottomLeft: Radius.circular(
                          _isOwnMessage ? AppTheme.radiusLg : AppTheme.radiusSm,
                        ),
                        bottomRight: Radius.circular(
                          _isOwnMessage ? AppTheme.radiusSm : AppTheme.radiusLg,
                        ),
                      ),
                      boxShadow: _isOwnMessage
                          ? AppTheme.shadowTeal
                          : AppTheme.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message content
                        _buildMessageContent(context),

                        // Reactions
                        if (message.reactions.isNotEmpty)
                          _buildReactions(context),
                      ],
                    ),
                  ),

                  // Timestamp and read status
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingXs,
                      right: AppTheme.spacingXs,
                      top: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(message.createdAt),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.neutral400,
                                    fontSize: 10,
                                  ),
                        ),
                        if (_isOwnMessage) ...[
                          const SizedBox(width: 4),
                          _buildReadStatus(context),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Spacing for sent messages
            if (_isOwnMessage) const SizedBox(width: AppTheme.spacingXs),
          ],
        ),
      ),
    );
  }

  /// Build avatar for received messages
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.neutral200,
      backgroundImage: message.senderAvatarUrl != null
          ? NetworkImage(message.senderAvatarUrl!)
          : null,
      child: message.senderAvatarUrl == null
          ? Text(
              message.senderName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral600,
              ),
            )
          : null,
    );
  }

  /// Build message content based on message type
  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.text:
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Text(
            message.message ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isOwnMessage ? Colors.white : AppTheme.neutral900,
                  height: 1.4,
                ),
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachmentUrl != null)
              GestureDetector(
                onTap: () {
                  ImageViewer.show(
                    context,
                    imageUrl: message.attachmentUrl!,
                    heroTag: 'message_image_${message.id}',
                  );
                },
                child: Hero(
                  tag: 'message_image_${message.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: message.attachmentUrl!,
                      fit: BoxFit.cover,
                      maxHeightDiskCache: 800,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppTheme.neutral100,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppTheme.neutral100,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (message.message != null && message.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Text(
                  message.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            _isOwnMessage ? Colors.white : AppTheme.neutral900,
                      ),
                ),
              ),
          ],
        );

      case MessageType.location:
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: _isOwnMessage ? Colors.white : AppTheme.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  message.message ?? 'Location shared',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            _isOwnMessage ? Colors.white : AppTheme.neutral900,
                      ),
                ),
              ),
            ],
          ),
        );

      case MessageType.expenseLink:
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Icon(
                Icons.attach_money,
                color: _isOwnMessage ? Colors.white : AppTheme.accentGold,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  message.message ?? 'Expense shared',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            _isOwnMessage ? Colors.white : AppTheme.neutral900,
                      ),
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Build reactions display
  Widget _buildReactions(BuildContext context) {
    // Group reactions by emoji
    final reactionMap = <String, int>{};
    for (final reaction in message.reactions) {
      final emoji = reaction.emoji;
      reactionMap[emoji] = (reactionMap[emoji] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
        bottom: AppTheme.spacingXs,
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionMap.entries.map((entry) {
          final hasReacted = message.hasReaction(currentUserId, entry.key);

          return _AnimatedReactionBubble(
            emoji: entry.key,
            count: entry.value,
            hasReacted: hasReacted,
            isOwnMessage: _isOwnMessage,
            onTap: () => onReactionTap?.call(),
            onLongPress: () => onReactionLongPress?.call(entry.key),
          );
        }).toList(),
      ),
    );
  }

  /// Build read status indicator
  Widget _buildReadStatus(BuildContext context) {
    final readByCount = message.readBy.length;

    if (readByCount <= 1) {
      // Only sender has read (sent but not delivered)
      return const Icon(
        Icons.check,
        size: 14,
        color: AppTheme.neutral400,
      );
    } else {
      // Read by others
      return const Icon(
        Icons.done_all,
        size: 14,
        color: AppTheme.primaryTeal,
      );
    }
  }

  /// Format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today: show time only
      return DateFormat.jm().format(timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${DateFormat.jm().format(timestamp)}';
    } else if (now.difference(timestamp).inDays < 7) {
      // This week: show day name
      return DateFormat('EEE, h:mm a').format(timestamp);
    } else {
      // Older: show date
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}

/// Animated Reaction Bubble Widget
/// Shows reaction emoji with count, animated on tap
class _AnimatedReactionBubble extends StatefulWidget {
  final String emoji;
  final int count;
  final bool hasReacted;
  final bool isOwnMessage;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AnimatedReactionBubble({
    required this.emoji,
    required this.count,
    required this.hasReacted,
    required this.isOwnMessage,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_AnimatedReactionBubble> createState() =>
      _AnimatedReactionBubbleState();
}

class _AnimatedReactionBubbleState extends State<_AnimatedReactionBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: widget.onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: widget.hasReacted
                ? (widget.isOwnMessage
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppTheme.primaryPale)
                : (widget.isOwnMessage
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.neutral100),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: widget.hasReacted
                ? Border.all(
                    color: widget.isOwnMessage
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.primaryTeal,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 12),
              ),
              if (widget.count > 1) ...[
                const SizedBox(width: 2),
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: widget.isOwnMessage
                        ? Colors.white
                        : AppTheme.neutral700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
