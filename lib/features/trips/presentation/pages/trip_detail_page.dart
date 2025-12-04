import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../../core/services/share_service.dart';
import '../providers/trip_providers.dart';
import '../../../trip_invites/presentation/widgets/invite_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Member management state
  bool _showAddMember = false;
  bool _showAllMembers = false;
  final TextEditingController _memberSearchController = TextEditingController();
  String _memberSearchQuery = '';

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
    _memberSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final themeData = context.appThemeData;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: tripAsync.when(
        data: (trip) => CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Premium App Bar with Parallax Hero Image
                SliverAppBar(
                  expandedHeight: 260,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: themeData.primaryColor,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      trip.trip.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    background: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // Parallax Hero Image
                            Positioned.fill(
                              child: Transform.translate(
                                offset: Offset(0, _scrollOffset * 0.5),
                                child: DestinationImage(
                                  tripName: trip.trip.destination ?? trip.trip.name,
                                  height: constraints.maxHeight,
                                  width: constraints.maxWidth,
                                  fit: BoxFit.cover,
                                  showOverlay: false,
                                ),
                              ),
                            ),
                            // Enhanced gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.5, 1.0],
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Trip status badge (top left)
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 60,
                              left: AppTheme.spacingMd,
                              child: _buildTripStatusBadge(context, trip),
                            ),
                            // Glassmorphic info card at bottom
                            Positioned(
                              bottom: 50,
                              left: AppTheme.spacingMd,
                              right: AppTheme.spacingMd,
                              child: _buildHeroInfoCard(context, trip),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  actions: [
                    // Only show edit button for trip owner
                    if (TripPermissions.canEditTrip(
                      currentUserId: ref.watch(authStateProvider).value,
                      tripWithMembers: trip,
                    ))
                      Container(
                        margin: const EdgeInsets.only(right: AppTheme.spacingXs),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/trips/${widget.tripId}/edit');
                          },
                        ),
                      ),
                    _buildPopupMenu(context, trip),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards Row
                        FadeSlideAnimation(
                          delay: Duration.zero,
                          child: _buildStatsCards(context, trip),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Trip Info Card
                        FadeSlideAnimation(
                          delay: AppAnimations.staggerSmall,
                          child: _buildInfoSection(context, trip, themeData),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Description
                        if (trip.trip.description != null &&
                            trip.trip.description!.isNotEmpty) ...[
                          FadeSlideAnimation(
                            delay: AppAnimations.staggerSmall * 2,
                            child: _buildDescriptionCard(
                              context,
                              trip.trip.description!,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                        ],

                        // Members Section
                        FadeSlideAnimation(
                          delay: AppAnimations.staggerSmall * 3,
                          child: _buildMembersSection(context, trip, themeData),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Quick Actions Grid
                        FadeSlideAnimation(
                          delay: AppAnimations.staggerSmall * 4,
                          child: _buildQuickActionsGrid(context, trip),
                        ),

                        // Bottom padding
                        const SizedBox(height: AppTheme.spacingMd),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading trip details...'),
        ),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildTripStatusBadge(BuildContext context, dynamic trip) {
    final now = DateTime.now();
    final startDate = trip.trip.startDate;
    final endDate = trip.trip.endDate;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (trip.trip.isCompleted) {
      statusText = 'Completed';
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle;
    } else if (startDate != null && now.isBefore(startDate)) {
      final daysUntil = startDate.difference(now).inDays;
      statusText = daysUntil == 0 ? 'Starts Today!' : '$daysUntil days to go';
      statusColor = AppTheme.info;
      statusIcon = Icons.flight_takeoff;
    } else if (startDate != null && endDate != null && now.isAfter(startDate) && now.isBefore(endDate)) {
      final currentDay = now.difference(startDate).inDays + 1;
      final totalDays = endDate.difference(startDate).inDays + 1;
      statusText = 'Day $currentDay of $totalDays';
      statusColor = AppTheme.success;
      statusIcon = Icons.explore;
    } else {
      statusText = 'Upcoming';
      statusColor = AppTheme.warning;
      statusIcon = Icons.schedule;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: Colors.white, size: 16),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroInfoCard(BuildContext context, dynamic trip) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Destination
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXs),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        trip.trip.destination ?? 'No destination',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 30,
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              // Members
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 18),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    '${trip.members.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacingMd),
              // Dates
              if (trip.trip.startDate != null) ...[
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      DateFormat('MMM d').format(trip.trip.startDate!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, dynamic trip) {
    final expensesAsync = ref.watch(tripExpensesProvider(widget.tripId));
    final checklistsAsync = ref.watch(tripChecklistsProvider(widget.tripId));

    // Calculate trip day progress
    int currentDay = 0;
    int totalDays = 0;
    if (trip.trip.startDate != null && trip.trip.endDate != null) {
      totalDays = trip.trip.endDate!.difference(trip.trip.startDate!).inDays + 1;
      final now = DateTime.now();
      if (now.isAfter(trip.trip.startDate!) && now.isBefore(trip.trip.endDate!)) {
        currentDay = now.difference(trip.trip.startDate!).inDays + 1;
      } else if (now.isAfter(trip.trip.endDate!)) {
        currentDay = totalDays;
      }
    }

    return Row(
      children: [
        // Expenses Card
        Expanded(
          child: _StatCard(
            icon: Icons.payments,
            iconColor: AppTheme.warning,
            label: 'Expenses',
            value: expensesAsync.when(
              data: (expenses) {
                final total = expenses.fold<double>(
                  0,
                  (sum, e) => sum + e.expense.amount,
                );
                return '₹${_formatAmount(total)}';
              },
              loading: () => '...',
              error: (e, s) => '₹0',
            ),
            subtitle: expensesAsync.when(
              data: (expenses) => '${expenses.length} items',
              loading: () => 'Loading',
              error: (e, s) => 'Error',
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/trips/${widget.tripId}/expenses');
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),

        // Checklist Card
        Expanded(
          child: _StatCard(
            icon: Icons.checklist,
            iconColor: AppTheme.success,
            label: 'Checklists',
            value: checklistsAsync.when(
              data: (checklists) => '${checklists.length}',
              loading: () => '...',
              error: (e, s) => '0',
            ),
            subtitle: checklistsAsync.when(
              data: (checklists) => checklists.length == 1 ? '1 list' : '${checklists.length} lists',
              loading: () => 'Loading',
              error: (e, s) => 'Error',
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/trips/${widget.tripId}/checklists');
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),

        // Days Card
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today,
            iconColor: context.primaryColor,
            label: 'Trip Days',
            value: totalDays > 0 ? 'Day $currentDay' : '-',
            subtitle: totalDays > 0 ? 'of $totalDays days' : 'No dates',
            progress: totalDays > 0 ? currentDay / totalDays : 0.0,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/trips/${widget.tripId}/itinerary');
            },
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildInfoSection(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
  ) {
    final hasBudget = trip.trip.budget != null && trip.trip.budget! > 0;
    final budget = trip.trip.budget ?? 0.0;

    return GradientBorderCard(
      borderWidth: 2,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          // Destination
          if (trip.trip.destination != null)
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              iconColor: themeData.primaryColor,
              iconBg: themeData.primaryColor.withValues(alpha: 0.1),
              label: 'Destination',
              value: trip.trip.destination!,
            ),

          if (trip.trip.destination != null &&
              (trip.trip.startDate != null || trip.trip.endDate != null))
            const Divider(height: AppTheme.spacingLg),

          // Dates with Duration (consolidated into single row)
          if (trip.trip.startDate != null && trip.trip.endDate != null)
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              iconColor: AppTheme.success,
              iconBg: AppTheme.success.withValues(alpha: 0.1),
              label: 'Travel Dates',
              value:
                  '${DateFormat('MMM d').format(trip.trip.startDate!)} - ${DateFormat('MMM d, yyyy').format(trip.trip.endDate!)}',
              subtitle: '${trip.trip.endDate!.difference(trip.trip.startDate!).inDays + 1} days trip',
            ),

          // Trip Cost
          const Divider(height: AppTheme.spacingLg),
          _buildInfoRow(
            context,
            icon: hasBudget ? Icons.savings : Icons.savings_outlined,
            iconColor: hasBudget ? Colors.blue.shade700 : Colors.grey.shade400,
            iconBg: hasBudget ? Colors.blue.shade50 : Colors.grey.shade50,
            label: 'Trip Budget',
            value: hasBudget
                ? '${trip.trip.currency} ${budget.toStringAsFixed(2)}'
                : 'No budget set',
            subtitle: hasBudget ? 'Estimated trip cost' : null,
          ),

          // Trip Visibility
          const Divider(height: AppTheme.spacingLg),
          _buildInfoRow(
            context,
            icon: trip.trip.isPublic ? Icons.public : Icons.lock,
            iconColor: trip.trip.isPublic ? Colors.green.shade700 : Colors.orange.shade700,
            iconBg: trip.trip.isPublic ? Colors.green.shade50 : Colors.orange.shade50,
            label: 'Visibility',
            value: trip.trip.isPublic ? 'Public' : 'Private',
            subtitle: trip.trip.isPublic
                ? 'Anyone can discover this trip'
                : 'Only members can see this trip',
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
    String? subtitle,
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
                  color: context.textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, String description) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
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
                  color: context.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.description,
                  size: 20,
                  color: context.accentColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'About This Trip',
                style: context.titleStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            description,
            style: context.bodyStyle.copyWith(
              color: context.textColor.withValues(alpha: 0.87),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    dynamic trip,
    dynamic themeData,
  ) {
    final currentUserId = ref.watch(authStateProvider).value;
    final isCreator = trip.trip.createdBy == currentUserId;
    final isAdmin = trip.members.any(
      (m) => m.userId == currentUserId && m.role == 'admin',
    );
    final canManageMembers = isCreator || isAdmin;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
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
                  color: context.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(Icons.group, size: 20, color: context.accentColor),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Crew',
                      style: context.titleStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    Text(
                      '${trip.members.length} member${trip.members.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Add Member button (inline toggle)
              if (canManageMembers)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showAddMember = !_showAddMember;
                      if (!_showAddMember) {
                        _memberSearchController.clear();
                        _memberSearchQuery = '';
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: _showAddMember
                          ? AppTheme.neutral200
                          : AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.neutral300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showAddMember ? Icons.close : Icons.person_add,
                          size: 14,
                          color: AppTheme.neutral700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showAddMember ? 'Cancel' : 'Add',
                          style: TextStyle(
                            color: AppTheme.neutral700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: AppTheme.spacingSm),
              // Invite button (share link)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  InviteBottomSheet.show(
                    context: context,
                    tripId: widget.tripId,
                    tripName: trip.trip.name,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Invite',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Inline Add Member Section
          if (_showAddMember) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _buildInlineAddMemberSection(context, trip),
          ],

          const SizedBox(height: AppTheme.spacingMd),

          if (trip.members.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    color: context.textColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  const Expanded(child: Text('No members yet. Invite friends!')),
                ],
              ),
            )
          else ...[
            // Show limited members with expand option
            ...(_showAllMembers
                    ? trip.members.asMap().entries
                    : trip.members.asMap().entries.take(3))
                .map(
              (entry) => FadeSlideAnimation(
                delay: AppAnimations.staggerTiny * entry.key,
                child: _buildMemberCard(
                  context,
                  entry.value,
                  themeData,
                  trip,
                  canManageMembers,
                ),
              ),
            ),
            // Show "+X more" button if there are more than 3 members
            if (trip.members.length > 3)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showAllMembers = !_showAllMembers);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showAllMembers
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                        color: context.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showAllMembers
                            ? 'Show less'
                            : '+${trip.members.length - 3} more members',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineAddMemberSection(BuildContext context, dynamic trip) {
    final searchResults = ref.watch(
      systemUsersSearchProvider((search: _memberSearchQuery, tripId: widget.tripId)),
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _memberSearchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              hintStyle: TextStyle(color: AppTheme.neutral400, fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.neutral400),
              suffixIcon: _memberSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: AppTheme.neutral400),
                      onPressed: () {
                        _memberSearchController.clear();
                        setState(() => _memberSearchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.neutral300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.neutral300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: context.primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              setState(() => _memberSearchQuery = value);
            },
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Search results
          searchResults.when(
            data: (users) {
              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                  child: Center(
                    child: Text(
                      _memberSearchQuery.isEmpty
                          ? 'Type to search for users'
                          : 'No users found',
                      style: TextStyle(color: AppTheme.neutral500, fontSize: 13),
                    ),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: 0,
                        ),
                        leading: UserAvatarWidget(
                          imageUrl: user.avatarUrl,
                          userName: user.fullName ?? user.email ?? 'U',
                          size: 36,
                        ),
                        title: Text(
                          user.fullName ?? 'Unknown',
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          user.email ?? '',
                          style: TextStyle(
                            color: AppTheme.neutral500,
                            fontSize: 11,
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () => _addMemberToTrip(user.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 14, color: AppTheme.success),
                                const SizedBox(width: 2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Center(
                child: Text(
                  'Error searching users',
                  style: TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMemberToTrip(String userId) async {
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
            duration: Duration(seconds: 2),
          ),
        );
        // Clear search and close add section
        setState(() {
          _memberSearchController.clear();
          _memberSearchQuery = '';
          _showAddMember = false;
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

  Future<void> _removeMemberFromTrip(String userId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $memberName from this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
              duration: Duration(seconds: 2),
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

  Widget _buildMemberCard(
    BuildContext context,
    dynamic member,
    dynamic themeData,
    dynamic trip,
    bool canManageMembers,
  ) {
    final currentUserId = ref.read(authStateProvider).value ?? '';
    final isCurrentUser = member.userId == currentUserId;
    final isCreator = member.userId == trip.trip.createdBy;
    final canRemove = canManageMembers && !isCreator && !isCurrentUser;

    final card = Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: context.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isCurrentUser) {
            context.push('/profile');
          } else {
            context.push(
              '/profile'
              '?userId=${Uri.encodeComponent(member.userId)}'
              '&fullName=${Uri.encodeComponent(member.fullName ?? '')}'
              '&email=${Uri.encodeComponent(member.email ?? '')}'
              '&role=${Uri.encodeComponent(member.role)}',
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          child: Row(
            children: [
              UserAvatarWidget(
                imageUrl: member.avatarUrl,
                userName: member.fullName ?? member.email ?? 'U',
                size: 40,
                showBorder: true,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName ?? member.email ?? 'Unknown',
                            style: context.bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                color: context.primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
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
                            isCreator
                                ? 'Creator'
                                : (member.role == 'admin' ? 'Admin' : 'Member'),
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
                  ],
                ),
              ),
              if (isCreator)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Icon(Icons.star, size: 14, color: Colors.white),
                )
              else if (canRemove)
                GestureDetector(
                  onTap: () => _removeMemberFromTrip(
                    member.userId,
                    member.fullName ?? 'this member',
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Icon(
                      Icons.remove_circle_outline,
                      size: 16,
                      color: AppTheme.error,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: context.textColor.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );

    return card;
  }

  Widget _buildQuickActionsGrid(BuildContext context, dynamic trip) {
    final themeData = context.appThemeData;
    final isCompleted = trip.trip.isCompleted;

    // Build contextual actions based on trip status
    final List<Widget> actions = [];

    if (isCompleted) {
      // Completed trip: Show review/view focused actions
      actions.addAll([
        _QuickActionCard(
          icon: Icons.payments,
          label: 'Expenses',
          color: const Color(0xFF4CAF93), // Soft teal green
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/expenses');
          },
        ),
        _QuickActionCard(
          icon: Icons.photo_library,
          label: 'Memories',
          color: const Color(0xFF64B5F6), // Soft sky blue
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate to trip photos/memories
            context.push('/trips/${widget.tripId}/itinerary');
          },
        ),
        _QuickActionCard(
          icon: Icons.chat_bubble_rounded,
          label: 'Chats',
          color: const Color(0xFF7E57C2), // Soft purple
          onTap: () {
            HapticFeedback.mediumImpact();
            final currentUserId = ref.read(authStateProvider).value ?? '';
            context.push(
              '/trips/${widget.tripId}/conversations'
              '?tripName=${Uri.encodeComponent(trip.trip.name)}'
              '&userId=$currentUserId',
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.calendar_month,
          label: 'Itinerary',
          color: const Color(0xFFFFB74D), // Soft amber/orange
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/itinerary');
          },
        ),
        _QuickActionCard(
          icon: Icons.checklist_rounded,
          label: 'Checklists',
          color: const Color(0xFF4DB6AC), // Soft teal
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/checklists');
          },
        ),
        _QuickActionCard(
          icon: Icons.star_rate_rounded,
          label: 'Rate Trip',
          color: const Color(0xFFFFD54F), // Gold/yellow
          onTap: () {
            HapticFeedback.mediumImpact();
            _showCompleteDialog(context, ref);
          },
        ),
      ]);
    } else {
      // Active/Upcoming trip: Show add/action focused actions
      actions.addAll([
        _QuickActionCard(
          icon: Icons.add_card,
          label: 'Add Expense',
          color: const Color(0xFF4CAF93), // Soft teal green
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/expenses/add');
          },
        ),
        _QuickActionCard(
          icon: Icons.event_note,
          label: 'Add Activity',
          color: const Color(0xFF64B5F6), // Soft sky blue
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/itinerary/add');
          },
        ),
        _QuickActionCard(
          icon: Icons.chat_bubble_rounded,
          label: 'Chats',
          color: const Color(0xFF7E57C2), // Soft purple
          onTap: () {
            HapticFeedback.mediumImpact();
            final currentUserId = ref.read(authStateProvider).value ?? '';
            context.push(
              '/trips/${widget.tripId}/conversations'
              '?tripName=${Uri.encodeComponent(trip.trip.name)}'
              '&userId=$currentUserId',
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.calendar_month,
          label: 'Itinerary',
          color: const Color(0xFFFFB74D), // Soft amber/orange
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/itinerary');
          },
        ),
        _QuickActionCard(
          icon: Icons.checklist_rounded,
          label: 'Checklists',
          color: const Color(0xFF4DB6AC), // Soft teal
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/trips/${widget.tripId}/checklists');
          },
        ),
        _QuickActionCard(
          icon: Icons.emergency,
          label: 'Emergency',
          color: const Color(0xFFE57373), // Soft coral red
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/emergency?tripId=${widget.tripId}');
          },
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: themeData.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                Icons.dashboard_customize,
                size: 20,
                color: themeData.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text(
              'Quick Actions',
              style: context.titleStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: AppTheme.spacingMd,
          mainAxisSpacing: AppTheme.spacingMd,
          childAspectRatio: 0.95,
          children: actions,
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, dynamic trip) {
    final currentUserId = ref.watch(authStateProvider).value;
    final canEditTrip = TripPermissions.canEditTrip(
      currentUserId: currentUserId,
      tripWithMembers: trip,
    );
    final canDeleteTrip = TripPermissions.canDeleteTrip(
      currentUserId: currentUserId,
      tripWithMembers: trip,
    );

    // Build menu items based on permissions
    final menuItems = <PopupMenuEntry<String>>[];

    // Share options - available to all members
    menuItems.add(
      PopupMenuItem(
        value: 'share_whatsapp',
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXs),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: const Icon(
                Icons.chat,
                color: Color(0xFF25D366),
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Share via WhatsApp'),
          ],
        ),
      ),
    );
    menuItems.add(
      PopupMenuItem(
        value: 'share_general',
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXs),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: const Icon(
                Icons.share,
                color: AppTheme.info,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Share via...'),
          ],
        ),
      ),
    );
    menuItems.add(const PopupMenuDivider());

    // Complete/Reopen options - only for trip owner
    if (canEditTrip) {
      if (!trip.trip.isCompleted) {
        menuItems.add(
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                const Text('Mark as Completed'),
              ],
            ),
          ),
        );
      } else {
        menuItems.add(
          PopupMenuItem(
            value: 'reopen',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: AppTheme.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                const Text('Reopen Trip'),
              ],
            ),
          ),
        );
      }
    }

    // Delete option - only for trip owner
    if (canDeleteTrip) {
      menuItems.add(
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
                child: const Icon(
                  Icons.delete,
                  color: AppTheme.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              const Text('Delete Trip'),
            ],
          ),
        ),
      );
    }

    // Menu always has share options, so it's never empty
    return PopupMenuButton(
      icon: Container(
        padding: const EdgeInsets.all(AppTheme.spacingXs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: const Icon(Icons.more_vert),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder: (context) => menuItems,
      onSelected: (value) async {
        if (value == 'share_whatsapp') {
          final text = ShareService.formatTrip(trip.trip);
          final success = await ShareService.shareToWhatsApp(text);
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open WhatsApp. Please install WhatsApp to share.'),
              ),
            );
          }
        } else if (value == 'share_general') {
          final text = ShareService.formatTrip(trip.trip);
          await ShareService.shareGeneral(text, subject: 'Trip: ${trip.trip.name}');
        } else if (value == 'complete') {
          _showCompleteDialog(context, ref);
        } else if (value == 'reopen') {
          _showReopenDialog(context, ref);
        } else if (value == 'delete') {
          _showDeleteDialog(context, ref);
        }
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
              style: context.headlineStyle.copyWith(
                color: context.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    double rating = 0.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.success),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              const Text('Complete Trip?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mark this trip as completed and rate your experience.',
                style: context.bodyStyle,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              const Text('Rate your trip:'),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = (index + 1).toDouble();
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppTheme.warning,
                      size: 32,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final userId = ref.read(authStateProvider).value ?? '';
                  await ref
                      .read(tripControllerProvider.notifier)
                      .markTripAsCompleted(
                        tripId: widget.tripId,
                        userId: userId,
                        rating: rating > 0 ? rating : null,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip marked as completed!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReopenDialog(BuildContext context, WidgetRef ref) {
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
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.refresh, color: AppTheme.info),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Reopen Trip?'),
          ],
        ),
        content: const Text('This trip will be moved back to active trips.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = ref.read(authStateProvider).value ?? '';
                await ref
                    .read(tripControllerProvider.notifier)
                    .unmarkTripAsCompleted(
                      tripId: widget.tripId,
                      userId: userId,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip reopened successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Reopen'),
          ),
        ],
      ),
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
          style: context.bodyStyle.copyWith(
            color: context.textColor.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(tripControllerProvider.notifier)
                    .deleteTrip(widget.tripId);
                if (context.mounted) {
                  context.pop();
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
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Stat card widget with progress indicator
class _StatCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final double? progress;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.progress,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.iconColor,
                          widget.iconColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, size: 14, color: Colors.white),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppTheme.neutral400,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.neutral500,
                ),
              ),
              if (widget.progress != null) ...[
                const SizedBox(height: AppTheme.spacingXs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: widget.progress!,
                    backgroundColor: widget.iconColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(widget.iconColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action card with attractive gradient and icon design
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Stack(
              children: [
                // Decorative circle in top right
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Decorative circle in bottom left
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Content - centered
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon with glass background
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(widget.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
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
}

