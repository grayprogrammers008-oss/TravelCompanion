import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../shared/models/trip_model.dart';
import '../providers/trip_providers.dart';

/// Bottom sheet for managing trip members
///
/// Features:
/// - Single unified list of all system users
/// - Checkboxes to add/remove members
/// - Search bar to filter users
/// - Current members shown with checkmarks
class AddMemberBottomSheet extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;

  const AddMemberBottomSheet({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  /// Show the manage members bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String tripId,
    required String tripName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMemberBottomSheet(
        tripId: tripId,
        tripName: tripName,
      ),
    );
  }

  @override
  ConsumerState<AddMemberBottomSheet> createState() => _AddMemberBottomSheetState();
}

class _AddMemberBottomSheetState extends ConsumerState<AddMemberBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // Track loading state per user for optimistic updates
  final Set<String> _loadingUserIds = {};
  Set<String> _currentMemberIds = {};
  String? _organizerId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  Future<void> _toggleMember(String userId, bool isCurrentlyMember) async {
    // Skip if already processing this user
    if (_loadingUserIds.contains(userId)) return;

    // Don't allow removing the organizer
    if (userId == _organizerId && isCurrentlyMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: AppTheme.spacingMd),
              Text('Cannot remove the trip organizer'),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
      return;
    }

    // Optimistic update: immediately update UI
    setState(() {
      _loadingUserIds.add(userId);
      if (isCurrentlyMember) {
        _currentMemberIds.remove(userId);
      } else {
        _currentMemberIds.add(userId);
      }
    });

    try {
      final tripController = ref.read(tripControllerProvider.notifier);

      if (isCurrentlyMember) {
        // Remove member
        await tripController.removeMember(
          tripId: widget.tripId,
          userId: userId,
        );
      } else {
        // Add member
        await tripController.addMember(
          tripId: widget.tripId,
          userId: userId,
          role: 'member',
        );
      }
      // Success - loading indicator will be removed below
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          if (isCurrentlyMember) {
            _currentMemberIds.add(userId); // Restore
          } else {
            _currentMemberIds.remove(userId); // Restore
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingUserIds.remove(userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    // Get all system users (without excluding existing members)
    final allUsersAsync = ref.watch(
      allSystemUsersProvider(_searchQuery.isEmpty ? null : _searchQuery),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXl),
              topRight: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: FadeSlideAnimation(
                  delay: Duration.zero,
                  child: _buildHeader(themeData, tripAsync),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: FadeSlideAnimation(
                  delay: AppAnimations.staggerTiny,
                  child: _buildSearchBar(themeData),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // User List
              Expanded(
                child: tripAsync.when(
                  data: (trip) {
                    // Initialize current member IDs and organizer
                    if (_currentMemberIds.isEmpty) {
                      _currentMemberIds = trip.members.map((m) => m.userId).toSet();
                      // Find organizer
                      final organizer = trip.members.where((m) => m.role == 'organizer').firstOrNull;
                      _organizerId = organizer?.userId;
                    }

                    return allUsersAsync.when(
                      data: (users) => _buildUserList(users, trip, scrollController, themeData),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _buildErrorState(error.toString()),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(dynamic themeData, AsyncValue<TripWithMembers> tripAsync) {
    final memberCount = tripAsync.when(
      data: (trip) => _currentMemberIds.length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: themeData.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: themeData.primaryShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  '$memberCount member${memberCount == 1 ? '' : 's'} • ${widget.tripName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(dynamic themeData) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(color: AppTheme.neutral500),
          prefixIcon: Icon(Icons.search, color: themeData.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.neutral500),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.neutral100,
          contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
        ),
      ),
    );
  }

  Widget _buildUserList(
    List<SystemUserModel> users,
    TripWithMembers trip,
    ScrollController scrollController,
    dynamic themeData,
  ) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    // Sort users: current members first, then alphabetically
    final sortedUsers = List<SystemUserModel>.from(users);
    sortedUsers.sort((a, b) {
      final aIsMember = _currentMemberIds.contains(a.id);
      final bIsMember = _currentMemberIds.contains(b.id);

      if (aIsMember && !bIsMember) return -1;
      if (!aIsMember && bIsMember) return 1;

      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        final isMember = _currentMemberIds.contains(user.id);
        final isOrganizer = user.id == _organizerId;

        return FadeSlideAnimation(
          delay: Duration(milliseconds: 30 * (index % 15)),
          child: _buildUserTile(user, isMember, isOrganizer, themeData),
        );
      },
    );
  }

  Widget _buildUserTile(SystemUserModel user, bool isMember, bool isOrganizer, dynamic themeData) {
    final isLoading = _loadingUserIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: isMember
            ? themeData.primaryColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isMember ? themeData.primaryColor.withValues(alpha: 0.3) : AppTheme.neutral200,
        ),
      ),
      child: ListTile(
        onTap: () => _toggleMember(user.id, isMember),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        leading: UserAvatarWidget(
          imageUrl: user.avatarUrl,
          userName: user.displayName,
          size: 44,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: isMember ? FontWeight.w600 : FontWeight.w500,
                  color: AppTheme.neutral900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOrganizer) ...[
              const SizedBox(width: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: themeData.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text(
                  'Organizer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: user.email != null
            ? Text(
                user.email!,
                style: TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: themeData.primaryColor,
                ),
              )
            : Checkbox(
                value: isMember,
                onChanged: isOrganizer
                    ? null // Disable checkbox for organizer
                    : (value) => _toggleMember(user.id, isMember),
                activeColor: themeData.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                size: 48,
                color: AppTheme.neutral400,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              _searchQuery.isNotEmpty ? 'No users found' : 'No users available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'No users in the system yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Error loading users',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
