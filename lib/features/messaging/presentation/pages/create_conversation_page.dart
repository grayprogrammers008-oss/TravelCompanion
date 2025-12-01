import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/conversation_providers.dart';

/// Page for creating a new group conversation or direct message
class CreateConversationPage extends ConsumerStatefulWidget {
  final String tripId;
  final String currentUserId;
  final String? preselectedUserId; // For starting a DM directly

  const CreateConversationPage({
    super.key,
    required this.tripId,
    required this.currentUserId,
    this.preselectedUserId,
  });

  @override
  ConsumerState<CreateConversationPage> createState() =>
      _CreateConversationPageState();
}

class _CreateConversationPageState
    extends ConsumerState<CreateConversationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isLoading = false;

  /// Returns true if this should be a direct message (only 1 other person selected)
  bool get _isDirectMessage =>
      _selectedMemberIds.length == 2 &&
      _selectedMemberIds.contains(widget.currentUserId);

  @override
  void initState() {
    super.initState();
    // Auto-select the current user
    _selectedMemberIds.add(widget.currentUserId);
    // If there's a preselected user (for DM), add them
    if (widget.preselectedUserId != null) {
      _selectedMemberIds.add(widget.preselectedUserId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createConversation() async {
    // For group chats, validate form. For DMs, skip name validation
    if (!_isDirectMessage && !_formKey.currentState!.validate()) return;

    if (_selectedMemberIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one other member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isDirectMessage) {
        // Create/find DM
        await _createDirectMessage();
      } else {
        // Create group chat
        await _createGroupChat();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createDirectMessage() async {
    final otherUserId = _selectedMemberIds
        .firstWhere((id) => id != widget.currentUserId);

    final repository = ref.read(conversationRepositoryProvider);
    final result = await repository.findOrCreateDirectMessage(
      tripId: widget.tripId,
      currentUserId: widget.currentUserId,
      otherUserId: otherUserId,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      result.fold(
        onSuccess: (conversation) {
          context.go(
            '/trips/${widget.tripId}/conversations/${conversation.id}?userId=${widget.currentUserId}',
          );
        },
        onFailure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create chat: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }

  Future<void> _createGroupChat() async {
    final notifier = ref.read(createConversationNotifierProvider.notifier);
    final result = await notifier.createConversation(
      tripId: widget.tripId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      memberUserIds: _selectedMemberIds.toList(),
      createdBy: widget.currentUserId,
      isDirectMessage: false,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result != null) {
        context.go(
          '/trips/${widget.tripId}/conversations/${result.id}?userId=${widget.currentUserId}',
        );
      }
    }
  }

  void _toggleMember(String userId) {
    // Don't allow deselecting current user
    if (userId == widget.currentUserId) return;

    setState(() {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isDirectMessage ? 'New Chat' : 'New Group Chat'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createConversation,
              child: Text(
                _isDirectMessage ? 'Start Chat' : 'Create',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // Chat Type Indicator
            _buildChatTypeIndicator(),

            const SizedBox(height: AppTheme.spacingMd),

            // Group Name (only for group chats)
            if (!_isDirectMessage) ...[
              _buildSectionTitle('Group Name'),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 3) {
                    return 'Group name must be at least 3 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Description (Optional)
              _buildSectionTitle('Description (Optional)'),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'What is this group about?',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: AppTheme.spacingXl),
            ],

            // Member Selection
            _buildSectionTitle(
              _isDirectMessage ? 'Select Person to Chat With' : 'Select Members',
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              _isDirectMessage
                  ? 'Select one person for a direct message'
                  : '${_selectedMemberIds.length} member${_selectedMemberIds.length == 1 ? '' : 's'} selected (3+ for group)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Members List
            tripAsync.when(
              data: (tripWithMembers) => _buildMembersList(tripWithMembers.members),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXl),
                  child: AppLoadingIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorState(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTypeIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: _isDirectMessage
            ? Colors.blue.shade50
            : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _isDirectMessage
              ? Colors.blue.shade200
              : Colors.purple.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isDirectMessage ? Icons.person : Icons.groups,
            color: _isDirectMessage
                ? Colors.blue.shade600
                : Colors.purple.shade600,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDirectMessage ? 'Direct Message' : 'Group Chat',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isDirectMessage
                            ? Colors.blue.shade700
                            : Colors.purple.shade700,
                      ),
                ),
                Text(
                  _isDirectMessage
                      ? 'Private conversation with one person'
                      : 'Chat with multiple trip members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isDirectMessage
                            ? Colors.blue.shade600
                            : Colors.purple.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
    );
  }

  Widget _buildMembersList(List<TripMemberModel> members) {
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'No trip members found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: members.map((member) {
        final isSelected = _selectedMemberIds.contains(member.userId);
        final isCurrentUser = member.userId == widget.currentUserId;

        return _MemberTile(
          member: member,
          isSelected: isSelected,
          isCurrentUser: isCurrentUser,
          onTap: () => _toggleMember(member.userId),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Failed to load members',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual member tile for selection
class _MemberTile extends StatelessWidget {
  final TripMemberModel member;
  final bool isSelected;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.isSelected,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = member.fullName ?? 'Unknown User';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: isSelected
            ? BorderSide(color: context.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isCurrentUser ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Avatar
              UserAvatarWidget(
                imageUrl: member.avatarUrl,
                userName: displayName,
                size: 48,
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              'You',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (member.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _buildRoleBadge(context),
                  ],
                ),
              ),

              // Selection indicator
              if (!isCurrentUser)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: context.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Icon(
                  Icons.check_circle,
                  color: context.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (member.role.toLowerCase()) {
      case 'owner':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        break;
      case 'admin':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        member.role.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
