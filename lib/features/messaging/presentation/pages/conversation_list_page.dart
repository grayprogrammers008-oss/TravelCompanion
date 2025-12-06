import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/conversation_providers.dart';

/// Page displaying group chats for a trip (Groups Only - No DMs)
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
  @override
  Widget build(BuildContext context) {
    // Use stream provider for real-time updates when messages change
    final conversationsAsync = ref.watch(
      tripConversationsStreamProvider(TripConversationsParams(
        tripId: widget.tripId,
        userId: widget.currentUserId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Chats'),
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
            tooltip: 'Search groups',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tripConversationsStreamProvider(TripConversationsParams(
            tripId: widget.tripId,
            userId: widget.currentUserId,
          )));
        },
        child: conversationsAsync.when(
          data: (conversations) {
            // Filter to show only group chats (exclude DMs)
            final groupChats = conversations
                .where((c) => !c.isDirectMessage)
                .toList();

            if (groupChats.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildGroupList(context, groupChats);
          },
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (error, stack) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Group Chats Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'The "All Members" group is created automatically when a trip is made.',
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

  Widget _buildGroupList(
    BuildContext context,
    List<ConversationEntity> groups,
  ) {
    // Sort: Default group first, then by last message time
    groups.sort((a, b) {
      // Default group always first
      if (a.isDefaultGroup && !b.isDefaultGroup) return -1;
      if (b.isDefaultGroup && !a.isDefaultGroup) return 1;

      // Then by last message time (most recent first)
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _GroupChatTile(
          group: group,
          currentUserId: widget.currentUserId,
          onTap: () => _navigateToChat(context, group),
        );
      },
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
              'Failed to load group chats',
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
                ref.invalidate(tripConversationsStreamProvider(TripConversationsParams(
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

  void _navigateToChat(BuildContext context, ConversationEntity conversation) {
    context.push(
      '/trips/${widget.tripId}/conversations/${conversation.id}?userId=${widget.currentUserId}',
    );
  }
}

/// Individual group chat tile widget
class _GroupChatTile extends StatelessWidget {
  final ConversationEntity group;
  final String currentUserId;
  final VoidCallback onTap;

  const _GroupChatTile({
    required this.group,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = group.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      leading: _buildAvatar(context),
      title: Row(
        children: [
          // Default group badge
          if (group.isDefaultGroup)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ALL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          Expanded(
            child: Text(
              group.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (group.lastMessageAt != null)
            Text(
              _formatTime(group.lastMessageAt!),
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
                group.unreadCount > 99
                    ? '99+'
                    : group.unreadCount.toString(),
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
    // Show group avatar or default icon
    if (group.avatarUrl != null) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(group.avatarUrl!),
      );
    }

    // Different color for default "All Members" group
    final bgColor = group.isDefaultGroup
        ? Colors.green.shade100
        : Colors.purple.shade100;
    final iconColor = group.isDefaultGroup
        ? Colors.green.shade600
        : Colors.purple.shade600;
    final icon = group.isDefaultGroup
        ? Icons.campaign // Megaphone for announcements
        : Icons.groups;

    return CircleAvatar(
      radius: 25,
      backgroundColor: bgColor,
      child: Icon(
        icon,
        color: iconColor,
        size: 28,
      ),
    );
  }

  String _getSubtitleText() {
    if (group.lastMessageText != null) {
      final sender = group.lastMessageSenderName ?? 'Someone';
      return '$sender: ${group.lastMessageText}';
    }
    return '${group.memberCount} members';
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
