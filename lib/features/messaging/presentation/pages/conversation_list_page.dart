import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/conversation_providers.dart';

/// Filter type for conversations
enum ConversationFilter { all, directMessages, groups }

/// Page displaying all conversations (DMs and Groups) for a trip
class ConversationListPage extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;
  final String currentUserId;

  const ConversationListPage({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.currentUserId,
  });

  @override
  ConsumerState<ConversationListPage> createState() =>
      _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage> {
  ConversationFilter _filter = ConversationFilter.all;

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(
      tripConversationsProvider(TripConversationsParams(
        tripId: widget.tripId,
        userId: widget.currentUserId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chats'),
            Text(
              widget.tripName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
            tooltip: 'Search conversations',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Conversation list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tripConversationsProvider(TripConversationsParams(
                  tripId: widget.tripId,
                  userId: widget.currentUserId,
                )));
              },
              child: conversationsAsync.when(
                data: (conversations) {
                  final filteredConversations = _filterConversations(conversations);
                  if (filteredConversations.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildConversationList(context, filteredConversations);
                },
                loading: () => const Center(child: AppLoadingIndicator()),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            filter: ConversationFilter.all,
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          _buildFilterChip(
            label: 'Direct',
            filter: ConversationFilter.directMessages,
            icon: Icons.person_outline,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          _buildFilterChip(
            label: 'Groups',
            filter: ConversationFilter.groups,
            icon: Icons.groups_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required ConversationFilter filter,
    required IconData icon,
  }) {
    final isSelected = _filter == filter;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = filter;
        });
      },
      selectedColor: context.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  List<ConversationEntity> _filterConversations(List<ConversationEntity> conversations) {
    switch (_filter) {
      case ConversationFilter.all:
        return conversations;
      case ConversationFilter.directMessages:
        return conversations.where((c) => c.isDirectMessage).toList();
      case ConversationFilter.groups:
        return conversations.where((c) => !c.isDirectMessage).toList();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    String title;
    String subtitle;
    String buttonText;
    VoidCallback onButtonPressed;

    switch (_filter) {
      case ConversationFilter.all:
        title = 'No Chats Yet';
        subtitle = 'Start a conversation with your trip members';
        buttonText = 'Start Chatting';
        onButtonPressed = () => _showNewChatOptions(context);
        break;
      case ConversationFilter.directMessages:
        title = 'No Direct Messages';
        subtitle = 'Start a private conversation with a trip member';
        buttonText = 'New Direct Message';
        onButtonPressed = () => _navigateToCreateConversation(context);
        break;
      case ConversationFilter.groups:
        title = 'No Group Chats';
        subtitle = 'Create a group to chat with multiple members at once';
        buttonText = 'Create Group';
        onButtonPressed = () => _navigateToCreateConversation(context);
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == ConversationFilter.directMessages
                  ? Icons.person_outline
                  : _filter == ConversationFilter.groups
                      ? Icons.groups_outlined
                      : Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    List<ConversationEntity> conversations,
  ) {
    // Separate DMs and Groups for better organization
    final dms = conversations.where((c) => c.isDirectMessage).toList();
    final groups = conversations.where((c) => !c.isDirectMessage).toList();

    if (_filter != ConversationFilter.all) {
      // Just show filtered list without sections
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        itemCount: conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _ConversationTile(
            conversation: conversation,
            currentUserId: widget.currentUserId,
            onTap: () => _navigateToChat(context, conversation),
          );
        },
      );
    }

    // Show with sections for "All" filter
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      children: [
        if (dms.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Direct Messages',
            Icons.person,
            Colors.blue,
            dms.length,
          ),
          ...dms.map((conversation) => Column(
                children: [
                  _ConversationTile(
                    conversation: conversation,
                    currentUserId: widget.currentUserId,
                    onTap: () => _navigateToChat(context, conversation),
                  ),
                  const Divider(height: 1),
                ],
              )),
        ],
        if (groups.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            'Group Chats',
            Icons.groups,
            Colors.purple,
            groups.length,
          ),
          ...groups.map((conversation) => Column(
                children: [
                  _ConversationTile(
                    conversation: conversation,
                    currentUserId: widget.currentUserId,
                    onTap: () => _navigateToChat(context, conversation),
                  ),
                  const Divider(height: 1),
                ],
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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
              'Failed to load conversations',
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
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(tripConversationsProvider(TripConversationsParams(
                  tripId: widget.tripId,
                  userId: widget.currentUserId,
                )));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Chat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, color: Colors.blue.shade700),
                ),
                title: const Text('Direct Message'),
                subtitle: const Text('Chat privately with one person'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCreateConversation(context);
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(Icons.groups, color: Colors.purple.shade700),
                ),
                title: const Text('Group Chat'),
                subtitle: const Text('Chat with multiple trip members'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToCreateConversation(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateConversation(BuildContext context) {
    context.push(
      '/trips/${widget.tripId}/conversations/create?userId=${widget.currentUserId}',
    );
  }

  void _navigateToChat(BuildContext context, ConversationEntity conversation) {
    context.push(
      '/trips/${widget.tripId}/conversations/${conversation.id}?userId=${widget.currentUserId}',
    );
  }
}

/// Individual conversation tile widget
class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final displayName = conversation.getDisplayName(currentUserId);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      leading: _buildAvatar(context),
      title: Row(
        children: [
          // Chat type indicator
          if (conversation.isDirectMessage)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.person,
                size: 14,
                color: Colors.blue.shade400,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.groups,
                size: 14,
                color: Colors.purple.shade400,
              ),
            ),
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasUnread
                        ? context.primaryColor
                        : Colors.grey.shade500,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              _getSubtitleText(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: AppTheme.spacingSm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (conversation.isDirectMessage && conversation.members.isNotEmpty) {
      // For DM, show the other person's avatar
      final otherMember = conversation.members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => conversation.members.first,
      );
      return UserAvatarWidget(
        imageUrl: otherMember.userAvatarUrl,
        userName: otherMember.userName ?? 'User',
        size: 50,
      );
    }

    // For group chat, show group icon or avatar
    if (conversation.avatarUrl != null) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(conversation.avatarUrl!),
      );
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.purple.shade100,
      child: Icon(
        Icons.groups,
        color: Colors.purple.shade600,
        size: 28,
      ),
    );
  }

  String _getSubtitleText() {
    if (conversation.lastMessageText != null) {
      if (conversation.isDirectMessage) {
        // For DM, don't show sender name prefix
        return conversation.lastMessageText!;
      }
      final sender = conversation.lastMessageSenderName ?? 'Someone';
      return '$sender: ${conversation.lastMessageText}';
    }

    if (conversation.isDirectMessage) {
      return 'Start a conversation';
    }
    return '${conversation.memberCount} members';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
