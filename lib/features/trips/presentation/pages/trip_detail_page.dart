import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/trip_providers.dart';
import '../../../trip_invites/presentation/widgets/invite_bottom_sheet.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: tripAsync.when(
        data: (trip) => CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Premium App Bar with Parallax Hero Image
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  trip.trip.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Parallax Hero Image
                    Transform.translate(
                      offset: Offset(0, _scrollOffset * 0.5),
                      child: DestinationImage(
                        tripName: trip.trip.destination ?? trip.trip.name,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        showOverlay: true,
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.push('/trips/${widget.tripId}/edit');
                    },
                  ),
                ),
                PopupMenuButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingXs),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: const Icon(Icons.delete, color: AppTheme.error, size: 18),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          const Text('Delete Trip'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(context, ref);
                    }
                  },
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip Info Cards with Staggered Animation
                    FadeSlideAnimation(
                      delay: Duration.zero,
                      child: _buildInfoSection(context, trip),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Description
                    if (trip.trip.description != null &&
                        trip.trip.description!.isNotEmpty) ...[
                      FadeSlideAnimation(
                        delay: AppAnimations.staggerSmall,
                        child: _buildDescriptionCard(context, trip.trip.description!),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                    ],

                    // Members Section
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 2,
                      child: _buildMembersSection(context, trip),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Quick Actions
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 3,
                      child: _buildQuickActions(context),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => Center(
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
                'Loading trip details...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.neutral600,
                    ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
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
                  'Error loading trip',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.shadowTeal,
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingMd,
                      ),
                    ),
                    child: const Text(
                      'Go Back',
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
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, trip) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        children: [
          // Destination
          if (trip.trip.destination != null)
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              iconColor: AppTheme.primaryTeal,
              iconBg: AppTheme.primaryPale,
              label: 'Destination',
              value: trip.trip.destination!,
            ),

          if (trip.trip.destination != null &&
              (trip.trip.startDate != null || trip.trip.endDate != null))
            const Divider(height: AppTheme.spacingLg),

          // Dates
          if (trip.trip.startDate != null && trip.trip.endDate != null)
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              iconColor: AppTheme.success,
              iconBg: AppTheme.success.withValues(alpha: 0.1),
              label: 'Travel Dates',
              value:
                  '${DateFormat('MMM dd, yyyy').format(trip.trip.startDate!)} - ${DateFormat('MMM dd, yyyy').format(trip.trip.endDate!)}',
            ),

          if ((trip.trip.startDate != null && trip.trip.endDate != null))
            const Divider(height: AppTheme.spacingLg),

          // Duration
          if (trip.trip.startDate != null && trip.trip.endDate != null)
            _buildInfoRow(
              context,
              icon: Icons.access_time,
              iconColor: AppTheme.accentCoral,
              iconBg: AppTheme.accentCoral.withValues(alpha: 0.1),
              label: 'Duration',
              value:
                  '${trip.trip.endDate!.difference(trip.trip.startDate!).inDays + 1} days',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, String description) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.description,
                  size: 20,
                  color: AppTheme.accentPurple,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutral900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutral700,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, trip) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.group,
                  size: 20,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neutral900,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPale,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${trip.members.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (trip.members.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined, color: AppTheme.neutral600),
                  const SizedBox(width: AppTheme.spacingMd),
                  const Expanded(
                    child: Text('No other members yet'),
                  ),
                  TextButton(
                    onPressed: () {
                      InviteBottomSheet.show(
                        context: context,
                        tripId: trip.trip.id,
                        tripName: trip.trip.name,
                      );
                    },
                    child: const Text('Invite'),
                  ),
                ],
              ),
            )
          else
            ...trip.members.asMap().entries.map(
                  (entry) => FadeSlideAnimation(
                    delay: AppAnimations.staggerTiny * entry.key,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.neutral200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryTeal,
                            child: Text(
                              entry.value.userId.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Member ${entry.value.userId.substring(0, 8)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  'Role: ${entry.value.role.substring(0, 1).toUpperCase()}${entry.value.role.substring(1)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.neutral600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (entry.value.role == 'organizer')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: const Text(
                                'Organizer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.dashboard_customize,
                size: 20,
                color: AppTheme.info,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutral900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: FadeSlideAnimation(
                delay: Duration.zero,
                child: _ActionCard(
                  icon: Icons.person_add,
                  label: 'Invite',
                  color: AppTheme.accentGold,
                  onTap: () {
                    InviteBottomSheet.show(
                      context: context,
                      tripId: widget.tripId,
                      tripName: 'Trip', // Will be replaced with actual trip name
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: FadeSlideAnimation(
                delay: AppAnimations.staggerTiny,
                child: _ActionCard(
                  icon: Icons.list_alt,
                  label: 'Itinerary',
                  color: AppTheme.accentPurple,
                  onTap: () {
                    context.push('/trips/${widget.tripId}/itinerary');
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: FadeSlideAnimation(
                delay: AppAnimations.staggerTiny * 2,
                child: _ActionCard(
                  icon: Icons.checklist,
                  label: 'Checklist',
                  color: AppTheme.success,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Checklist feature coming in Phase 2!'),
                        backgroundColor: AppTheme.info,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: FadeSlideAnimation(
                delay: AppAnimations.staggerTiny * 3,
                child: _ActionCard(
                  icon: Icons.payments,
                  label: 'Expenses',
                  color: AppTheme.accentCoral,
                  onTap: () {
                    context.push('/trips/${widget.tripId}/expenses');
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
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
          'Are you sure you want to delete this trip? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutral600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await ref
                      .read(tripControllerProvider.notifier)
                      .deleteTrip(widget.tripId);
                  if (context.mounted) {
                    context.pop(); // Go back to trips list
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
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    );
                  }
                }
              },
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
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowMd,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutral900,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
