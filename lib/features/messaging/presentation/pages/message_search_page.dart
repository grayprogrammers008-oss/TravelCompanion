import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/conversation_providers.dart';

/// Message Search Page - Search through messages in a conversation
class MessageSearchPage extends ConsumerStatefulWidget {
  final String tripId;
  final String conversationId;
  final String conversationName;
  final String currentUserId;

  const MessageSearchPage({
    super.key,
    required this.tripId,
    required this.conversationId,
    required this.conversationName,
    required this.currentUserId,
  });

  @override
  ConsumerState<MessageSearchPage> createState() => _MessageSearchPageState();
}

class _MessageSearchPageState extends ConsumerState<MessageSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';
  String _filterType = 'all'; // all, text, image, document

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search Messages'),
            Text(
              widget.conversationName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              0,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search for messages...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All', Icons.chat_bubble_outline),
            const SizedBox(width: AppTheme.spacingSm),
            _buildFilterChip('text', 'Text', Icons.text_fields),
            const SizedBox(width: AppTheme.spacingSm),
            _buildFilterChip('image', 'Images', Icons.image_outlined),
            const SizedBox(width: AppTheme.spacingSm),
            _buildFilterChip('document', 'Documents', Icons.attach_file),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, IconData icon) {
    final isSelected = _filterType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _filterType = type;
        });
      },
      selectedColor: context.primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptyState();
    }

    // Watch messages stream
    final messagesAsync = ref.watch(
      conversationMessagesStreamProvider(widget.conversationId),
    );

    return messagesAsync.when(
      data: (messages) {
        // Filter messages based on search query and type filter
        final filteredMessages = _filterMessages(messages);

        if (filteredMessages.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
          itemCount: filteredMessages.length,
          itemBuilder: (context, index) {
            final message = filteredMessages[index];
            return _MessageSearchResultTile(
              message: message,
              searchQuery: _searchQuery,
              currentUserId: widget.currentUserId,
              onTap: () => _navigateToMessage(message),
            );
          },
        );
      },
      loading: () => const Center(child: AppLoadingIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  List<MessageEntity> _filterMessages(List<MessageEntity> messages) {
    return messages.where((message) {
      // Skip deleted messages
      if (message.isDeleted) return false;

      // Apply type filter
      if (_filterType != 'all') {
        switch (_filterType) {
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

      // Apply search query filter
      final query = _searchQuery.toLowerCase();

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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Search Messages',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Type to search through messages in this conversation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'No messages match "$_searchQuery".\nTry a different search term.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Failed to search messages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMessage(MessageEntity message) {
    // Navigate back to chat and scroll to this message
    // For now, just pop back with the message ID
    context.pop(message.id);
  }
}

/// Individual search result tile
class _MessageSearchResultTile extends StatelessWidget {
  final MessageEntity message;
  final String searchQuery;
  final String currentUserId;
  final VoidCallback onTap;

  const _MessageSearchResultTile({
    required this.message,
    required this.searchQuery,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOwnMessage = message.senderId == currentUserId;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      leading: _buildAvatar(context),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isOwnMessage ? 'You' : (message.senderName ?? 'Unknown'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildMessagePreview(context),
          if (_getMessageTypeIcon() != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getMessageTypeIcon(),
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  _getMessageTypeLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (message.senderAvatarUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(message.senderAvatarUrl!),
      );
    }

    final initial = (message.senderName ?? 'U')[0].toUpperCase();
    return CircleAvatar(
      radius: 24,
      backgroundColor: context.primaryColor.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          color: context.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessagePreview(BuildContext context) {
    final text = message.message ?? '';

    // Highlight matching text
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: _buildHighlightedText(context, text),
    );
  }

  TextSpan _buildHighlightedText(BuildContext context, String text) {
    if (searchQuery.isEmpty) {
      return TextSpan(
        text: text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
      );
    }

    final query = searchQuery.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(query, start);
      if (index == -1) {
        // Add remaining text
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ));
        }
        break;
      }

      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.bold,
              backgroundColor: context.primaryColor.withValues(alpha: 0.1),
            ),
      ));

      start = index + query.length;
    }

    return TextSpan(children: spans);
  }

  IconData? _getMessageTypeIcon() {
    switch (message.messageType) {
      case MessageType.image:
        return Icons.image;
      case MessageType.document:
        return Icons.attach_file;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.expenseLink:
        return Icons.receipt_long;
      default:
        return null;
    }
  }

  String _getMessageTypeLabel() {
    switch (message.messageType) {
      case MessageType.image:
        return 'Image';
      case MessageType.document:
        return 'Document';
      case MessageType.location:
        return 'Location';
      case MessageType.expenseLink:
        return 'Expense';
      default:
        return '';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
