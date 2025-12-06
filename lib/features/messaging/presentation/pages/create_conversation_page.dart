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

/// Page for creating a new group chat (Groups Only - No DMs)
class CreateConversationPage extends ConsumerStatefulWidget {
  final String tripId;
  final String currentUserId;
  final String? preselectedUserId; // Kept for compatibility but not used

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

  @override
  void initState() {
    super.initState();
    // Auto-select the current user
    _selectedMemberIds.add(widget.currentUserId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    // Require at least 2 members (including current user) for a group
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _selectAllMembers(List<TripMemberModel> members) {
    setState(() {
      for (final member in members) {
        _selectedMemberIds.add(member.userId);
      }
    });
  }

  void _clearSelection(List<TripMemberModel> members) {
    setState(() {
      _selectedMemberIds.clear();
      _selectedMemberIds.add(widget.currentUserId); // Keep current user
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group Chat'),
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
              onPressed: _createGroup,
              child: const Text(
                'Create',
                style: TextStyle(
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
            // Group Info Card
            _buildGroupInfoCard(),

            const SizedBox(height: AppTheme.spacingLg),

            // Group Name
            _buildSectionTitle('Group Name *'),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Planning Team, Adventure Squad',
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

            // Member Selection Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Select Members'),
                tripAsync.maybeWhen(
                  data: (trip) => Row(
                    children: [
                      TextButton(
                        onPressed: () => _selectAllMembers(trip.members),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () => _clearSelection(trip.members),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              '${_selectedMemberIds.length} member${_selectedMemberIds.length == 1 ? '' : 's'} selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _selectedMemberIds.length < 2
                        ? Colors.orange
                        : Colors.green.shade600,
                    fontWeight: FontWeight.w500,
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

  Widget _buildGroupInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.purple.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups,
              color: Colors.purple.shade600,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Group Chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start a conversation with multiple trip members. All selected members can send and receive messages.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade600,
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
