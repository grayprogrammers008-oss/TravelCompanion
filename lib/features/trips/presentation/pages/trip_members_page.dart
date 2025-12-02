import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/trip_providers.dart';

/// Trip Members Page - Manage trip members (add/remove)
class TripMembersPage extends ConsumerStatefulWidget {
  final String tripId;

  const TripMembersPage({super.key, required this.tripId});

  @override
  ConsumerState<TripMembersPage> createState() => _TripMembersPageState();
}

class _TripMembersPageState extends ConsumerState<TripMembersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAddingMember = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final currentUserId = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Members'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isAddingMember ? Icons.close : Icons.person_add,
              color: context.appThemeData.primaryColor,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isAddingMember = !_isAddingMember;
                if (!_isAddingMember) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) => _buildContent(context, trip, currentUserId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Failed to load trip',
                style: TextStyle(color: context.textColor),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ElevatedButton(
                onPressed: () => ref.invalidate(tripProvider(widget.tripId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TripWithMembers trip,
    String? currentUserId,
  ) {
    final isCreator = trip.trip.createdBy == currentUserId;
    final isAdmin = trip.members.any(
      (m) => m.userId == currentUserId && m.role == 'admin',
    );
    final canManageMembers = isCreator || isAdmin;

    return Column(
      children: [
        // Add member section (shown when adding)
        if (_isAddingMember)
          _buildAddMemberSection(context, trip, canManageMembers),

        // Current members list
        Expanded(
          child: _buildMembersList(context, trip, currentUserId, canManageMembers),
        ),
      ],
    );
  }

  Widget _buildAddMemberSection(
    BuildContext context,
    TripWithMembers trip,
    bool canManageMembers,
  ) {
    final searchResults = ref.watch(
      systemUsersSearchProvider((search: _searchQuery, tripId: widget.tripId)),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Member',
            style: context.titleStyle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Search results
          searchResults.when(
            data: (users) {
              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Type to search for users'
                          : 'No users found',
                      style: TextStyle(color: AppTheme.neutral500),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: UserAvatarWidget(
                        imageUrl: user.avatarUrl,
                        userName: user.fullName ?? user.email,
                        size: 40,
                      ),
                      title: Text(
                        user.fullName ?? 'Unknown',
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        user.email ?? '',
                        style: TextStyle(
                          color: AppTheme.neutral500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: canManageMembers
                          ? IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: context.appThemeData.primaryColor,
                              ),
                              onPressed: () => _addMember(user.id),
                            )
                          : null,
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Center(
                child: Text(
                  'Error searching users',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    TripWithMembers trip,
    String? currentUserId,
    bool canManageMembers,
  ) {
    final members = trip.members;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: AppTheme.neutral300),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No members yet',
              style: TextStyle(
                color: AppTheme.neutral500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Tap + to add members to this trip',
              style: TextStyle(
                color: AppTheme.neutral400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isCurrentUser = member.userId == currentUserId;
        final isCreator = member.userId == trip.trip.createdBy;
        final memberRole = isCreator ? 'Creator' : (member.role == 'admin' ? 'Admin' : 'Member');

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowSm,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            leading: UserAvatarWidget(
              imageUrl: member.avatarUrl,
              userName: member.fullName ?? member.email,
              size: 48,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member.fullName ?? 'Unknown',
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.appThemeData.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      'You',
                      style: TextStyle(
                        color: context.appThemeData.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (member.email != null)
                  Text(
                    member.email!,
                    style: TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCreator
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : (member.role == 'admin'
                            ? Colors.amber.withValues(alpha: 0.1)
                            : AppTheme.neutral100),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    memberRole,
                    style: TextStyle(
                      color: isCreator
                          ? AppTheme.success
                          : (member.role == 'admin'
                              ? Colors.amber.shade700
                              : AppTheme.neutral600),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            trailing: canManageMembers && !isCreator && !isCurrentUser
                ? IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: AppTheme.error,
                    ),
                    onPressed: () => _showRemoveConfirmation(
                      context,
                      member,
                      trip.trip.name,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<void> _addMember(String userId) async {
    try {
      HapticFeedback.mediumImpact();
      await ref.read(tripControllerProvider.notifier).addMember(
            tripId: widget.tripId,
            userId: userId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        // Clear search and close add section
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _isAddingMember = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showRemoveConfirmation(
    BuildContext context,
    TripMemberModel member,
    String tripName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.fullName ?? 'this member'} from "$tripName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeMember(member.userId);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(String userId) async {
    try {
      HapticFeedback.mediumImpact();
      await ref.read(tripControllerProvider.notifier).removeMember(
            tripId: widget.tripId,
            userId: userId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
