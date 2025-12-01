import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../domain/entities/conversation_entity.dart';
import '../providers/conversation_providers.dart';

/// Page showing conversation details, members, and settings
class ConversationInfoPage extends ConsumerStatefulWidget {
  final String tripId;
  final String conversationId;
  final String currentUserId;

  const ConversationInfoPage({
    super.key,
    required this.tripId,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ConversationInfoPage> createState() =>
      _ConversationInfoPageState();
}

class _ConversationInfoPageState extends ConsumerState<ConversationInfoPage> {
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationProvider(ConversationParams(
        conversationId: widget.conversationId,
        userId: widget.currentUserId,
      )),
    );
    final membersAsync = ref.watch(
      conversationMembersProvider(widget.conversationId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          conversationAsync.maybeWhen(
            data: (conversation) {
              final isAdmin = conversation.isUserAdmin(widget.currentUserId);
              if (isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(context, conversation),
                  tooltip: 'Edit Group',
                );
              }
              return const SizedBox.shrink();
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: conversationAsync.when(
        data: (conversation) => _buildContent(context, conversation, membersAsync),
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ConversationEntity conversation,
    AsyncValue<List<ConversationMemberEntity>> membersAsync,
  ) {
    final isAdmin = conversation.isUserAdmin(widget.currentUserId);

    return ListView(
      children: [
        // Group Header
        _buildGroupHeader(context, conversation),

        const Divider(height: 1),

        // Description (if available)
        if (conversation.description != null &&
            conversation.description!.isNotEmpty) ...[
          _buildDescriptionSection(context, conversation.description!),
          const Divider(height: 1),
        ],

        // Members Section
        _buildMembersSection(context, membersAsync, isAdmin),

        const Divider(height: 1),

        // Actions Section
        _buildActionsSection(context, conversation, isAdmin),

        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  Widget _buildGroupHeader(BuildContext context, ConversationEntity conversation) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        children: [
          // Group Avatar
          _buildGroupAvatar(conversation),
          const SizedBox(height: AppTheme.spacingMd),

          // Group Name
          Text(
            conversation.getDisplayName(widget.currentUserId),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXs),

          // Member count
          Text(
            '${conversation.memberCount} members',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),

          // Created date
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Created ${_formatDate(conversation.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupAvatar(ConversationEntity conversation) {
    final size = 100.0;

    if (conversation.avatarUrl != null) {
      return CircleAvatar(
        radius: size / 2,
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
        size: size,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.primaryColor.withValues(alpha: 0.2),
      child: Icon(
        Icons.group,
        color: context.primaryColor,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, String description) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    AsyncValue<List<ConversationMemberEntity>> membersAsync,
    bool isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
              ),
              const Spacer(),
              if (isAdmin)
                TextButton.icon(
                  onPressed: () => _showAddMembersDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add'),
                ),
            ],
          ),
        ),
        membersAsync.when(
          data: (members) => Column(
            children: members.map((member) {
              final isCurrentUser = member.userId == widget.currentUserId;
              return _MemberTile(
                member: member,
                isCurrentUser: isCurrentUser,
                isAdmin: isAdmin,
                onRemove: isAdmin && !isCurrentUser
                    ? () => _removeMember(member)
                    : null,
              );
            }).toList(),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Text(
              'Failed to load members',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    ConversationEntity conversation,
    bool isAdmin,
  ) {
    return Column(
      children: [
        // Mute notifications (placeholder)
        ListTile(
          leading: Icon(
            Icons.notifications_off_outlined,
            color: Colors.grey.shade700,
          ),
          title: const Text('Mute Notifications'),
          trailing: Switch(
            value: false, // TODO: Implement mute state
            onChanged: (value) {
              // TODO: Implement mute toggle
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mute feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // Leave group
        ListTile(
          leading: Icon(
            Icons.exit_to_app,
            color: Colors.red.shade400,
          ),
          title: Text(
            'Leave Group',
            style: TextStyle(color: Colors.red.shade400),
          ),
          onTap: _isLeaving ? null : () => _confirmLeaveGroup(context),
          trailing: _isLeaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),

        // Delete group (admin only)
        if (isAdmin) ...[
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Colors.red.shade700,
            ),
            title: Text(
              'Delete Group',
              style: TextStyle(color: Colors.red.shade700),
            ),
            onTap: () => _confirmDeleteGroup(context),
          ),
        ],
      ],
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
            'Failed to load group info',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(
                conversationProvider(ConversationParams(
                  conversationId: widget.conversationId,
                  userId: widget.currentUserId,
                )),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ConversationEntity conversation) {
    final nameController = TextEditingController(text: conversation.name);
    final descController = TextEditingController(text: conversation.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateConversation(
                nameController.text.trim(),
                descController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context) {
    // TODO: Implement add members dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add members feature coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _updateConversation(String name, String description) async {
    if (name.isEmpty) return;

    try {
      final repository = ref.read(conversationRepositoryProvider);
      await repository.updateConversation(
        conversationId: widget.conversationId,
        name: name,
        description: description.isEmpty ? null : description,
      );

      // Refresh data
      ref.invalidate(
        conversationProvider(ConversationParams(
          conversationId: widget.conversationId,
          userId: widget.currentUserId,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(ConversationMemberEntity member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.userName ?? 'this member'} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(conversationRepositoryProvider);
        await repository.removeMember(
          conversationId: widget.conversationId,
          userId: member.userId,
        );

        ref.invalidate(conversationMembersProvider(widget.conversationId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmLeaveGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLeaving = true);

      try {
        final useCase = ref.read(leaveConversationUseCaseProvider);
        await useCase.execute(
          conversationId: widget.conversationId,
          userId: widget.currentUserId,
        );

        if (mounted) {
          // Go back to conversation list
          context.go('/trips/${widget.tripId}/conversations');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLeaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone and all messages will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(conversationRepositoryProvider);
        await repository.deleteConversation(widget.conversationId);

        if (mounted) {
          context.go('/trips/${widget.tripId}/conversations');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Member tile widget
class _MemberTile extends StatelessWidget {
  final ConversationMemberEntity member;
  final bool isCurrentUser;
  final bool isAdmin;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    required this.isAdmin,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = member.userName ?? 'Unknown User';

    return ListTile(
      leading: UserAvatarWidget(
        imageUrl: member.userAvatarUrl,
        userName: displayName,
        size: 40,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppTheme.spacingXs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'You',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ],
      ),
      subtitle: member.userEmail != null
          ? Text(
              member.userEmail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: member.role == 'admin'
                  ? Colors.blue.shade100
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              member.role.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: member.role == 'admin'
                        ? Colors.blue.shade700
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Remove button
          if (onRemove != null) ...[
            const SizedBox(width: AppTheme.spacingSm),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
              onPressed: onRemove,
              tooltip: 'Remove member',
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }
}
