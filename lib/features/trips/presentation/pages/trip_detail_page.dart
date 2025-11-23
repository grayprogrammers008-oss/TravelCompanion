import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../providers/trip_providers.dart';
import '../../../trip_invites/presentation/widgets/invite_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
    final themeData = context.appThemeData;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: tripAsync.when(
        data: (trip) => DiagonalGradientBackground(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
            // Premium App Bar with Parallax Hero Image
            SliverAppBar(
              expandedHeight: 280,
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
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                      Shadow(
                        color: Colors.black54,
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
                    if (!trip.trip.isCompleted)
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
                              child: const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            const Text('Mark as Completed'),
                          ],
                        ),
                      ),
                    if (trip.trip.isCompleted)
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
                              child: const Icon(Icons.refresh, color: AppTheme.info, size: 18),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            const Text('Reopen Trip'),
                          ],
                        ),
                      ),
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
                    if (value == 'complete') {
                      _showCompleteDialog(context, ref);
                    } else if (value == 'reopen') {
                      _showReopenDialog(context, ref);
                    } else if (value == 'delete') {
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
                      child: _buildInfoSection(context, trip, themeData),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

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
                      child: _buildMembersSection(context, trip, themeData),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Quick Actions
                    FadeSlideAnimation(
                      delay: AppAnimations.staggerSmall * 3,
                      child: _buildQuickActions(context, trip),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
        loading: () => const Center(
          child: AppLoadingIndicator(
            message: 'Loading trip details...',
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
                GlossyButton(
                  label: 'Go Back',
                  icon: Icons.arrow_back,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, dynamic trip, dynamic themeData) {
    final tripCostAsync = ref.watch(tripCostSummaryProvider(widget.tripId));

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
              iconColor: themeData.primaryColor,
              iconBg: themeData.primaryColor.withValues(alpha: 0.1),
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
              iconColor: context.accentColor,
              iconBg: context.accentColor.withValues(alpha: 0.1),
              label: 'Duration',
              value:
                  '${trip.trip.endDate!.difference(trip.trip.startDate!).inDays + 1} days',
            ),

          // Debug: Test if this section renders (ALWAYS VISIBLE)
          const Divider(height: AppTheme.spacingLg),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'DEBUG: Trip Cost Section Below',
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),

          // Trip Cost - Always show for debugging
          tripCostAsync.when(
            data: (costSummary) {
              if (kDebugMode) {
                debugPrint('✅ Trip cost loaded: ${costSummary.totalCost} ${costSummary.currency}, ${costSummary.expenseCount} expenses');
              }
              return Column(
                children: [
                  const Divider(height: AppTheme.spacingLg),
                  _buildInfoRow(
                    context,
                    icon: Icons.account_balance_wallet,
                    iconColor: costSummary.expenseCount > 0
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    iconBg: costSummary.expenseCount > 0
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    label: 'Trip Cost',
                    value: costSummary.expenseCount > 0
                        ? '${costSummary.currency} ${costSummary.totalCost.toStringAsFixed(2)}'
                        : 'No expenses yet',
                    subtitle: costSummary.expenseCount > 0
                        ? '${costSummary.expenseCount} expense${costSummary.expenseCount > 1 ? 's' : ''}'
                        : 'Add expenses to track costs',
                  ),
                ],
              );
            },
            loading: () {
              if (kDebugMode) {
                debugPrint('⏳ Loading trip cost...');
              }
              return Column(
                children: [
                  const Divider(height: AppTheme.spacingLg),
                  _buildInfoRow(
                    context,
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.grey.shade600,
                    iconBg: Colors.grey.shade100,
                    label: 'Trip Cost',
                    value: 'Loading...',
                  ),
                ],
              );
            },
            error: (error, stackTrace) {
              if (kDebugMode) {
                debugPrint('❌ Error loading trip cost: $error');
                debugPrint('Stack trace: $stackTrace');
              }
              return Column(
                children: [
                  const Divider(height: AppTheme.spacingLg),
                  _buildInfoRow(
                    context,
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.red.shade700,
                    iconBg: Colors.red.shade50,
                    label: 'Trip Cost',
                    value: 'Error loading',
                    subtitle: kDebugMode ? error.toString() : 'Unable to load cost',
                  ),
                ],
              );
            },
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
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
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
                'Description',
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

  Widget _buildMembersSection(BuildContext context, dynamic trip, dynamic themeData) {
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
                  color: context.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.group,
                  size: 20,
                  color: context.accentColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Members',
                style: context.titleStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${trip.members.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: themeData.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Member Avatars Stack (only if there are members)
          if (trip.members.isNotEmpty) ...[
            SizedBox(
              height: 40,
              child: Stack(
                children: [
                  ...trip.members.take(5).toList().asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final member = entry.value;
                      return Positioned(
                        left: index * 28.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: themeData.primaryColor,
                            child: Text(
                              (member.fullName ?? member.email ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (trip.members.length > 5)
                    Positioned(
                      left: 5 * 28.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.neutral300,
                          child: Text(
                            '+${trip.members.length - 5}',
                            style: TextStyle(
                              color: AppTheme.neutral800,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          if (trip.members.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add_outlined, color: context.textColor.withValues(alpha: 0.7)),
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
                      decoration: BoxDecoration(
                        color: context.backgroundColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: context.textColor.withValues(alpha: 0.2)),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Check if it's the current user
                          final currentUserId = ref.read(authStateProvider).value ?? '';
                          if (entry.value.userId == currentUserId) {
                            // Navigate to own profile
                            context.push('/profile');
                          } else {
                            // Navigate to user's profile with all member data
                            context.push('/profile'
                                '?userId=${Uri.encodeComponent(entry.value.userId)}'
                                '&fullName=${Uri.encodeComponent(entry.value.fullName ?? '')}'
                                '&email=${Uri.encodeComponent(entry.value.email ?? '')}'
                                '&role=${Uri.encodeComponent(entry.value.role)}');
                          }
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: themeData.primaryColor,
                                child: Text(
                                  (entry.value.fullName ?? entry.value.email ?? 'U')[0].toUpperCase(),
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
                                      entry.value.fullName ?? entry.value.email ?? 'Unknown Member',
                                      style: context.bodyStyle.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      entry.value.role.substring(0, 1).toUpperCase() + entry.value.role.substring(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: context.textColor.withValues(alpha: 0.7),
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
                                    gradient: themeData.primaryGradient,
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
                              const SizedBox(width: AppTheme.spacingXs),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: context.textColor.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic trip) {
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
              style: context.titleStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
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
                  color: context.accentColor,
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
                  color: context.primaryColor,
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
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: AppTheme.info,
                  onTap: () {
                    final currentUserId = ref.read(authStateProvider).value ?? '';
                    context.push(
                      '/trips/${widget.tripId}/chat'
                      '?tripName=${Uri.encodeComponent(trip.trip.name)}'
                      '&userId=$currentUserId',
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
                  icon: Icons.checklist,
                  label: 'Checklist',
                  color: AppTheme.success,
                  onTap: () {
                    context.push('/trips/${widget.tripId}/checklists');
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
                delay: AppAnimations.staggerTiny * 4,
                child: _ActionCard(
                  icon: Icons.payments,
                  label: 'Expenses',
                  color: AppTheme.warning,
                  onTap: () {
                    context.push('/trips/${widget.tripId}/expenses');
                  },
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: FadeSlideAnimation(
                delay: AppAnimations.staggerTiny * 5,
                child: _ActionCard(
                  icon: Icons.emergency,
                  label: 'Emergency',
                  color: AppTheme.error,
                  onTap: () {
                    context.push('/emergency?tripId=${widget.tripId}');
                  },
                ),
              ),
            ),
          ],
        ),
      ],
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
                  await ref.read(tripControllerProvider.notifier).markTripAsCompleted(
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
                await ref.read(tripControllerProvider.notifier).unmarkTripAsCompleted(
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
              style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
