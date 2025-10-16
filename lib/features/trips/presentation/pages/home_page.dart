import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/trip_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userTripsAsync = ref.watch(userTripsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: CustomScrollView(
        slivers: [
          // Premium App Bar with gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryTeal,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // User Avatar
                            UserAvatarWidget(
                              userName: currentUser.value?.fullName,
                              size: 48,
                              showBorder: true,
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                  ),
                                  Text(
                                    currentUser.value?.fullName
                                            ?.split(' ')
                                            .first ??
                                        'Traveler',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Profile Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onPressed: () => _showProfileMenu(context, ref),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          userTripsAsync.when(
            data: (trips) {
              if (trips.isEmpty) {
                return SliverFillRemaining(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildEmptyState(context),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tripWithMembers = trips[index];
                      // Staggered animation for each card
                      return FadeSlideAnimation(
                        delay: AppAnimations.staggerMedium * index,
                        duration: AppAnimations.medium,
                        child: TripCard(
                          key: ValueKey(tripWithMembers.trip.id),
                          tripWithMembers: tripWithMembers,
                          onTap: () => context.push('/trips/${tripWithMembers.trip.id}'),
                          onEdit: () => _editTrip(context, tripWithMembers.trip),
                          onDelete: () => _deleteTrip(context, ref, tripWithMembers.trip),
                        ),
                      );
                    },
                    childCount: trips.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.shadowTeal,
                      ),
                      child: const Icon(
                        Icons.flight_takeoff,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      'Loading your adventures...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.neutral600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: _buildErrorState(context, error.toString(), ref),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleAnimation(
        duration: AppAnimations.slow,
        curve: AppAnimations.spring,
        child: AnimatedScaleButton(
          onTap: () => context.push('/trips/create'),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.shadowTeal,
            ),
            child: FloatingActionButton.extended(
              onPressed: null, // Handled by AnimatedScaleButton
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Trip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      title: 'No trips yet',
      description:
          'Start your journey by creating your first trip.\nPlan, share, and explore together!',
      icon: Icons.explore,
      actionLabel: 'Create Your First Trip',
      onAction: () => context.push('/trips/create'),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.shadowTeal,
              ),
              child: ElevatedButton.icon(
                onPressed: () => ref.invalidate(userTripsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editTrip(BuildContext context, TripModel trip) {
    // TODO: Navigate to edit trip page
    context.push('/trips/${trip.id}/edit');
  }

  Future<void> _deleteTrip(
      BuildContext context, WidgetRef ref, TripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Delete Trip?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${trip.name}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutral600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(tripRepositoryProvider).deleteTrip(trip.id);
        ref.invalidate(userTripsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Trip deleted successfully'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete trip: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      }
    }
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: AppTheme.spacingLg),

              // Menu Items
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPale,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                title: const Text('Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppTheme.neutral600,
                  ),
                ),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppTheme.error,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium Trip Card Widget
class TripCard extends StatelessWidget {
  final TripWithMembers tripWithMembers;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.tripWithMembers,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final daysLeft = trip.startDate?.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image with Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLg),
                      topRight: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: DestinationImage(
                      tripName: trip.destination ?? trip.name,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      showOverlay: true,
                      overlayChild: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Actions Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Edit Button
                                _buildActionButton(
                                  context,
                                  Icons.edit_outlined,
                                  onEdit,
                                ),
                                const SizedBox(width: AppTheme.spacingXs),
                                // Delete Button
                                _buildActionButton(
                                  context,
                                  Icons.delete_outline,
                                  onDelete,
                                  isDestructive: true,
                                ),
                              ],
                            ),

                            // Trip Info Overlay
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Days Left Badge
                                if (daysLeft != null && daysLeft > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSm,
                                      vertical: AppTheme.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentCoral,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusFull),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$daysLeft days left',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: AppTheme.spacingXs),

                                // Trip Name
                                Text(
                                  trip.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          const Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Trip Details
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination
                    if (trip.destination != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPale,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              trip.destination!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.neutral700,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Dates
                    if (trip.startDate != null || trip.endDate != null) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral100,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              _formatDateRange(trip.startDate, trip.endDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.neutral600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingMd),
                    const Divider(height: 1),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Members
                    Row(
                      children: [
                        _buildMemberAvatars(members),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.neutral600,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppTheme.neutral400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive
            ? AppTheme.error.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.white : AppTheme.neutral700,
        ),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildMemberAvatars(List<TripMemberModel> members) {
    const maxVisible = 3;
    final visibleMembers = members.take(maxVisible).toList();
    final remainingCount = members.length - maxVisible;

    // Calculate total width needed
    final avatarCount = visibleMembers.length + (remainingCount > 0 ? 1 : 0);
    final totalWidth = (avatarCount * 24.0) + 8.0; // 24px overlap + 8px padding

    return SizedBox(
      width: totalWidth,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...List.generate(visibleMembers.length, (index) {
            final member = visibleMembers[index];
            return Positioned(
              left: index * 24.0,
              child: UserAvatarWidget(
                userName: member.email,
                size: 32,
                showBorder: true,
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: visibleMembers.length * 24.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.neutral200,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return 'Dates not set';
    if (startDate != null && endDate != null) {
      return '${startDate.toFormattedDate()} - ${endDate.toFormattedDate()}';
    }
    if (startDate != null) {
      return 'From ${startDate.toFormattedDate()}';
    }
    return 'Until ${endDate!.toFormattedDate()}';
  }
}
