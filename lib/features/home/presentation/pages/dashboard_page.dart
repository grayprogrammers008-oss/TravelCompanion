import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../../shared/models/itinerary_model.dart';
import '../../../../shared/models/expense_model.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../../../messaging/presentation/providers/conversation_providers.dart';
import '../providers/dashboard_providers.dart';

/// Model for suggested settlement between two users
class SuggestedSettlement {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;

  SuggestedSettlement({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final activeTripAsync = ref.watch(activeTripProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userTripsProvider);
            ref.invalidate(activeTripProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar with greeting
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: themeData.primaryGradient,
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
                                GestureDetector(
                                  onTap: () => context.push('/profile'),
                                  child: UserAvatarWidget(
                                    imageUrl: currentUser.value?.avatarUrl,
                                    userName: currentUser.value?.fullName,
                                    size: 48,
                                    showBorder: true,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getGreeting(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                      ),
                                      Text(
                                        currentUser.value?.fullName?.split(' ').first ?? 'Traveler',
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
                                // Menu (3-dot)
                                IconButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                  onPressed: () => _showProfileMenu(context, ref),
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

              // Dashboard Content
              activeTripAsync.when(
                data: (activeTrip) {
                  if (activeTrip == null) {
                    return SliverFillRemaining(
                      child: _buildNoActiveTripState(context),
                    );
                  }
                  return _buildDashboardContent(context, activeTrip);
                },
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: AppLoadingIndicator(
                      message: 'Loading your trip...',
                      size: 60,
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(context, error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildDashboardContent(BuildContext context, TripWithMembers activeTrip) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Active Trip Hero Card
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall,
            child: _buildActiveTripCard(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Quick Actions Section (at top for easy access)
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 2,
            child: _buildQuickActionsSection(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Today's Itinerary Section
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 3,
            child: _buildTodayItinerarySection(context, activeTrip.trip.id),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Unified Expenses Section (Current Trip + Global Summary)
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 4,
            child: _buildUnifiedExpensesSection(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Trip Members Section
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 5,
            child: _buildTripMembersSection(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacing3xl),
        ]),
      ),
    );
  }

  Widget _buildActiveTripCard(BuildContext context, TripWithMembers tripWithMembers) {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final now = DateTime.now();
    final startDate = trip.startDate;
    final endDate = trip.endDate;
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    // Calculate countdown info
    int? daysUntil;
    int? dayNumber;
    int? totalDays;
    bool isUpcoming = false;
    bool isOngoing = false;

    if (startDate != null && now.isBefore(startDate)) {
      daysUntil = startDate.difference(now).inDays;
      isUpcoming = true;
    } else if (startDate != null && endDate != null && now.isAfter(startDate) && now.isBefore(endDate)) {
      dayNumber = now.difference(startDate).inDays + 1;
      totalDays = endDate.difference(startDate).inDays + 1;
      isOngoing = true;
    }

    return GestureDetector(
      onTap: () => context.push('/trips/${trip.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: themeData.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                // Background Image - Taller for more impact
                Positioned.fill(
                  child: DestinationImage(
                    tripName: trip.destination ?? trip.name,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              // Gradient Overlay - More dramatic
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Countdown Badge - Top Left with glassmorphism
              if (isUpcoming && daysUntil != null)
                Positioned(
                  left: AppTheme.spacingMd,
                  top: AppTheme.spacingMd,
                  child: _buildCountdownBadge(context, daysUntil, themeData),
                ),
              // Ongoing Trip Progress - Top Left
              if (isOngoing && dayNumber != null && totalDays != null)
                Positioned(
                  left: AppTheme.spacingMd,
                  top: AppTheme.spacingMd,
                  child: _buildProgressBadge(context, dayNumber, totalDays, themeData),
                ),
              // Member Avatars - Top Right (aligned with Day badge on left)
              Positioned(
                right: AppTheme.spacingMd,
                top: AppTheme.spacingMd, // Same as left badge
                child: _buildMemberAvatars(members),
              ),
              // Content card (optimized - no blur for performance)
              Positioned(
                left: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                bottom: AppTheme.spacingMd,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trip Name
                      Text(
                        trip.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Location and Date Row
                      Row(
                        children: [
                          if (trip.destination != null) ...[
                            Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trip.destination!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (startDate != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              '${startDate.day}/${startDate.month}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // View Trip Button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'View Trip',
                                    style: TextStyle(
                                      color: themeData.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: themeData.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  /// Countdown badge for upcoming trips (optimized - no blur, no perpetual animation)
  Widget _buildCountdownBadge(BuildContext context, int daysUntil, dynamic themeData) {
    // Removed TweenAnimationBuilder and BackdropFilter for performance
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeData.primaryColor.withValues(alpha: 0.9),
            themeData.primaryColor.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: themeData.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight_takeoff, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                daysUntil == 0 ? 'TODAY!' : '$daysUntil',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (daysUntil > 0)
                Text(
                  daysUntil == 1 ? 'day to go' : 'days to go',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Progress badge for ongoing trips (optimized - no blur)
  Widget _buildProgressBadge(BuildContext context, int dayNumber, int totalDays, dynamic themeData) {
    final progress = dayNumber / totalDays;

    // Removed BackdropFilter for performance
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day $dayNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              // Mini progress bar
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Member avatars stack
  Widget _buildMemberAvatars(List<TripMemberModel> members) {
    final displayMembers = members.take(3).toList();
    final remainingCount = members.length - 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stacked avatars
        SizedBox(
          // Calculate width: first avatar + (overlap * remaining avatars) + optional +N badge
          width: 36.0 + (displayMembers.length - 1) * 26.0 + (remainingCount > 0 ? 26.0 : 0),
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < displayMembers.length; i++)
                Positioned(
                  left: i * 26.0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: UserAvatarWidget(
                        imageUrl: displayMembers[i].avatarUrl,
                        userName: displayMembers[i].fullName ?? displayMembers[i].email,
                        size: 32,
                        showBorder: false,
                      ),
                    ),
                  ),
                ),
              // +N indicator
              if (remainingCount > 0)
                Positioned(
                  left: displayMembers.length * 26.0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '+$remainingCount',
                        style: TextStyle(
                          color: AppTheme.neutral700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayItinerarySection(BuildContext context, String tripId) {
    final itineraryAsync = ref.watch(itineraryByDaysProvider(tripId));

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.today,
                      color: context.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    "Today's Plan",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/trips/$tripId/itinerary'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          itineraryAsync.when(
            data: (days) {
              final todayItems = _getTodayItinerary(days);
              if (todayItems.isEmpty) {
                return _buildEmptyItinerary(context, tripId);
              }
              return Column(
                children: todayItems.take(3).map((item) => _buildItineraryItem(context, item)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Center(
              child: Text('Failed to load itinerary'),
            ),
          ),
        ],
      ),
    );
  }

  List<ItineraryItemModel> _getTodayItinerary(List<ItineraryDay> days) {
    // For now, return items from day 1 or first available day
    // In a real app, you'd calculate based on trip start date
    if (days.isEmpty) return [];
    return days.first.items;
  }

  Widget _buildEmptyItinerary(BuildContext context, String tripId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 40,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'No activities planned for today',
            style: TextStyle(color: AppTheme.neutral600),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextButton.icon(
            onPressed: () => context.push('/trips/$tripId/itinerary/add'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(BuildContext context, ItineraryItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Time
          if (item.startTime != null)
            SizedBox(
              width: 50,
              child: Text(
                '${item.startTime!.hour.toString().padLeft(2, '0')}:${item.startTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: AppTheme.neutral600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: AppTheme.spacingSm),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.location != null)
                  Text(
                    item.location!,
                    style: TextStyle(
                      color: AppTheme.neutral500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Unified Expenses Section showing both current trip and global summary
  Widget _buildUnifiedExpensesSection(BuildContext context, TripWithMembers tripWithMembers) {
    final trip = tripWithMembers.trip;
    final tripExpensesAsync = ref.watch(tripExpensesProvider(trip.id));
    final userExpensesAsync = ref.watch(userExpensesProvider);
    final balancesAsync = ref.watch(tripBalancesProvider(trip.id));
    final currentUserId = SupabaseClientWrapper.currentUserId;
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'My Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/expenses'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Current Trip Expenses
          tripExpensesAsync.when(
            data: (tripExpenses) {
              final tripTotalSpent = tripExpenses.fold<double>(
                0,
                (sum, e) => sum + e.expense.amount,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Trip Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeData.primaryColor.withValues(alpha: 0.1),
                          themeData.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: themeData.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flight_takeoff,
                              size: 16,
                              color: themeData.primaryColor,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Expanded(
                              child: Text(
                                trip.name,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: themeData.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Group Chat button for this trip - opens default "All Members" group
                            Consumer(
                              builder: (context, ref, child) {
                                final unreadAsync = ref.watch(tripUnreadCountProvider(
                                  TripConversationsParams(tripId: trip.id, userId: currentUserId ?? ''),
                                ));
                                final unreadCount = unreadAsync.value ?? 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _openDefaultGroupChat(trip.id),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                        child: Container(
                                          padding: const EdgeInsets.all(AppTheme.spacingXs),
                                          decoration: BoxDecoration(
                                            color: themeData.primaryColor.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble_outline,
                                            size: 16,
                                            color: themeData.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trip Expenses',
                                    style: TextStyle(
                                      color: AppTheme.neutral500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${trip.currency} ${tripTotalSpent.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.neutral900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Balance for this trip
                            balancesAsync.when(
                              data: (balances) {
                                final userBalance = balances.where(
                                  (b) => b.userId == currentUserId,
                                ).firstOrNull;

                                if (userBalance == null || userBalance.balance == 0) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSm,
                                      vertical: AppTheme.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    ),
                                    child: Text(
                                      'Settled',
                                      style: TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }

                                final balance = userBalance.balance;
                                final isOwed = balance > 0;
                                final color = isOwed ? AppTheme.success : AppTheme.error;
                                final text = isOwed
                                    ? 'Owed ${trip.currency} ${balance.abs().toStringAsFixed(0)}'
                                    : 'Owe ${trip.currency} ${balance.abs().toStringAsFixed(0)}';

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: AppTheme.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        // Trip-specific Who Owes Whom section
                        balancesAsync.when(
                          data: (balances) {
                            if (balances.isEmpty) return const SizedBox.shrink();

                            // Calculate suggested settlements from balances
                            final settlements = _calculateSuggestedSettlements(balances);

                            if (settlements.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppTheme.spacingMd),
                                Divider(color: themeData.primaryColor.withValues(alpha: 0.2)),
                                const SizedBox(height: AppTheme.spacingSm),
                                Text(
                                  'Settle Up',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.neutral700,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingSm),
                                ...settlements.take(4).map((settlement) => _buildSettlementRow(context, settlement, trip.currency)),
                                if (settlements.length > 4)
                                  Center(
                                    child: TextButton(
                                      onPressed: () => context.push('/trips/${trip.id}/expenses'),
                                      child: Text(
                                        '+${settlements.length - 4} more',
                                        style: TextStyle(
                                          color: themeData.primaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Personal Expenses Card
                  userExpensesAsync.when(
                    data: (allExpenses) {
                      // Filter for personal expenses (no trip_id)
                      final personalExpenses = allExpenses.where((e) => e.expense.tripId == null).toList();

                      if (personalExpenses.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final personalTotal = personalExpenses.fold<double>(
                        0,
                        (sum, e) => sum + e.expense.amount,
                      );

                      return Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.1),
                              Colors.orange.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: AppTheme.spacingXs),
                                Text(
                                  'Personal Expenses',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    '${personalExpenses.length} expense${personalExpenses.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Spent',
                                        style: TextStyle(
                                          color: AppTheme.neutral500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        personalTotal.toINR(),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.orange.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quick add personal expense button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push('/expenses/add'),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingSm,
                                        vertical: AppTheme.spacingXs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 16,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Global Summary - Who Owes What
                  userExpensesAsync.when(
                    data: (allExpenses) {
                      if (allExpenses.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final totalAcrossAllTrips = allExpenses.fold<double>(
                        0,
                        (sum, e) => sum + e.expense.amount,
                      );

                      final balances = _calculateBalancesFromExpenses(allExpenses);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total across all trips
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral50,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.neutral200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: AppTheme.warning,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Across All Trips',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.neutral600,
                                        ),
                                      ),
                                      Text(
                                        totalAcrossAllTrips.toINR(),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.neutral900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: AppTheme.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neutral200,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    '${allExpenses.length} expenses',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.neutral600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Who Owes What section - using settlements format
                          if (balances.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              'Settle Up',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.neutral900,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Builder(
                              builder: (context) {
                                final settlements = _calculateSuggestedSettlements(balances);
                                if (settlements.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                                        const SizedBox(width: AppTheme.spacingSm),
                                        Text(
                                          'All settled up!',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Column(
                                  children: [
                                    ...settlements.take(3).map((settlement) => _buildSettlementRow(context, settlement, '₹')),
                                    if (settlements.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: AppTheme.spacingXs),
                                        child: Center(
                                          child: TextButton(
                                            onPressed: () => context.go('/expenses'),
                                            child: Text(
                                              '+${settlements.length - 3} more',
                                              style: TextStyle(
                                                color: themeData.primaryColor,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: AppTheme.spacingMd),
                  // Quick add expense button - shows trip name for clarity
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/trips/${trip.id}/expenses/add'),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Add Expense to ${trip.name}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const Center(
              child: Text('Failed to load expenses'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripMembersSection(BuildContext context, TripWithMembers tripWithMembers) {
    final members = tripWithMembers.members;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: AppTheme.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Trip Members',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${members.length} members',
                  style: TextStyle(
                    color: AppTheme.neutral600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Member avatars row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...members.take(6).map((member) => Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                      child: Column(
                        children: [
                          UserAvatarWidget(
                            imageUrl: member.avatarUrl,
                            userName: member.fullName ?? member.email,
                            size: 48,
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          SizedBox(
                            width: 56,
                            child: Text(
                              member.fullName?.split(' ').first ?? 'User',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.neutral600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (members.length > 6)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '+${members.length - 6}',
                        style: TextStyle(
                          color: AppTheme.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate balances from expenses data
  List<BalanceSummary> _calculateBalancesFromExpenses(List<ExpenseWithSplits> expenses) {
    final Map<String, BalanceSummary> balances = {};

    for (var expenseWithSplits in expenses) {
      final expense = expenseWithSplits.expense;
      final splits = expenseWithSplits.splits;

      // Track payer - they paid this amount
      final payerId = expense.paidBy;
      final payerName = expense.payerName ?? payerId;

      if (!balances.containsKey(payerId)) {
        balances[payerId] = BalanceSummary(
          userId: payerId,
          userName: payerName,
          totalPaid: 0,
          totalOwed: 0,
          balance: 0,
        );
      }
      balances[payerId] = BalanceSummary(
        userId: payerId,
        userName: payerName,
        totalPaid: balances[payerId]!.totalPaid + expense.amount,
        totalOwed: balances[payerId]!.totalOwed,
        balance: 0,
      );

      // Track splits - each person owes their split amount
      for (var split in splits) {
        final userName = split.userName ?? split.userId;
        if (!balances.containsKey(split.userId)) {
          balances[split.userId] = BalanceSummary(
            userId: split.userId,
            userName: userName,
            totalPaid: 0,
            totalOwed: 0,
            balance: 0,
          );
        }
        balances[split.userId] = BalanceSummary(
          userId: split.userId,
          userName: userName,
          totalPaid: balances[split.userId]!.totalPaid,
          totalOwed: balances[split.userId]!.totalOwed + split.amount,
          balance: 0,
        );
      }
    }

    // Calculate final balances (paid - owed)
    return balances.values.map((b) {
      return BalanceSummary(
        userId: b.userId,
        userName: b.userName,
        totalPaid: b.totalPaid,
        totalOwed: b.totalOwed,
        balance: b.totalPaid - b.totalOwed,
      );
    }).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // Sort by balance (highest first)
  }

  /// Calculate suggested settlements to minimize transactions
  /// Returns a list of "who pays whom how much" suggestions
  List<SuggestedSettlement> _calculateSuggestedSettlements(List<BalanceSummary> balances) {
    final settlements = <SuggestedSettlement>[];

    // Separate into creditors (positive balance - owed money) and debtors (negative balance - owe money)
    final creditors = balances.where((b) => b.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance)); // Highest first
    final debtors = balances.where((b) => b.balance < 0).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance)); // Most negative first

    // Create mutable copies of balances
    final creditorBalances = {for (var c in creditors) c.userId: c.balance};
    final debtorBalances = {for (var d in debtors) d.userId: d.balance.abs()};
    final userNames = {for (var b in balances) b.userId: b.userName};

    // Match debtors with creditors
    for (var debtor in debtors) {
      var remaining = debtorBalances[debtor.userId]!;

      for (var creditor in creditors) {
        if (remaining <= 0) break;

        final creditorRemaining = creditorBalances[creditor.userId]!;
        if (creditorRemaining <= 0) continue;

        final settlementAmount = remaining < creditorRemaining ? remaining : creditorRemaining;

        if (settlementAmount > 0.01) { // Ignore tiny amounts
          settlements.add(SuggestedSettlement(
            fromUserId: debtor.userId,
            fromUserName: userNames[debtor.userId] ?? debtor.userId,
            toUserId: creditor.userId,
            toUserName: userNames[creditor.userId] ?? creditor.userId,
            amount: settlementAmount,
          ));

          remaining -= settlementAmount;
          creditorBalances[creditor.userId] = creditorRemaining - settlementAmount;
        }
      }
    }

    return settlements;
  }

  /// Build a settlement row showing "Vinoth owes Priya ₹250"
  Widget _buildSettlementRow(BuildContext context, SuggestedSettlement settlement, String currency) {
    final fromName = settlement.fromUserName.split(' ').first;
    final toName = settlement.toUserName.split(' ').first;
    final amount = '$currency ${settlement.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.neutral50,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Row(
          children: [
            // From user avatar
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  settlement.fromUserName.isNotEmpty ? settlement.fromUserName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Text: "Vinoth owes Priya"
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutral700,
                  ),
                  children: [
                    TextSpan(
                      text: fromName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral800,
                      ),
                    ),
                    const TextSpan(text: ' owes '),
                    TextSpan(
                      text: toName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral800,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Amount badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                amount,
                style: TextStyle(
                  color: AppTheme.warning.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveTripState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flight_takeoff,
                size: 64,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'No Active Trips',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neutral900,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Start planning your next adventure!\nCreate a trip to see your dashboard.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trips/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                  vertical: AppTheme.spacingMd,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextButton(
              onPressed: () => context.go('/trips'),
              child: const Text('View My Trips'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
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
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(userTripsProvider);
                ref.invalidate(activeTripProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, TripWithMembers tripWithMembers) {
    final trip = tripWithMembers.trip;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with trip context
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'for ${trip.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.neutral500,
                    ),
              ),
            ],
          ),
        ),
        // Horizontal scrollable circular action buttons
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _buildActionButton(
                context,
                icon: Icons.receipt_long,
                label: 'Expense',
                color: AppTheme.success,
                onTap: () => context.push('/trips/${trip.id}/expenses/add'),
              ),
              _buildActionButton(
                context,
                icon: Icons.event,
                label: 'Itinerary',
                color: AppTheme.info,
                onTap: () => context.push('/trips/${trip.id}/itinerary/add'),
              ),
              _buildActionButton(
                context,
                icon: Icons.checklist,
                label: 'Checklist',
                color: AppTheme.warning,
                onTap: () => context.push('/trips/${trip.id}/checklists'),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final userId = ref.watch(currentUserProvider).value?.id ?? '';
                  final unreadAsync = ref.watch(tripUnreadCountProvider(
                    TripConversationsParams(tripId: trip.id, userId: userId),
                  ));
                  return _buildActionButton(
                    context,
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    color: context.primaryColor,
                    badgeCount: unreadAsync.value,
                    onTap: () => _openDefaultGroupChat(trip.id),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.person_add_outlined,
                label: 'Invite',
                color: context.accentColor,
                onTap: () => context.push('/trips/${trip.id}'),
              ),
              _buildActionButton(
                context,
                icon: Icons.add_circle_outline,
                label: 'New Trip',
                color: AppTheme.neutral600,
                onTap: () => context.push('/trips/create'),
              ),
              _buildActionButton(
                context,
                icon: Icons.qr_code_scanner,
                label: 'Join',
                color: AppTheme.neutral500,
                onTap: () => context.push('/join-trip'),
              ),
              _buildActionButton(
                context,
                icon: Icons.auto_awesome,
                label: 'AI Wizard',
                color: Colors.deepPurple,
                onTap: () => context.push('/trips/ai-wizard'),
              ),
              _buildActionButton(
                context,
                icon: Icons.emergency,
                label: 'SOS',
                color: AppTheme.error,
                onTap: () => context.push('/emergency?tripId=${trip.id}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingMd),
      child: _AnimatedActionButton(
        icon: icon,
        label: label,
        color: color,
        badgeCount: badgeCount,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  /// Navigate directly to the default "All Members" group chat for a trip
  /// Uses fast getDefaultGroupId method to avoid loading full conversation details
  Future<void> _openDefaultGroupChat(String tripId) async {
    final currentUserId = ref.read(currentUserProvider).value?.id ?? '';

    try {
      final repository = ref.read(conversationRepositoryProvider);
      // Use fast method that only fetches the ID (no heavy RPC call)
      final result = await repository.getDefaultGroupId(tripId: tripId);

      result.fold(
        onSuccess: (conversationId) {
          if (conversationId != null && mounted) {
            context.push(
              '/trips/$tripId/conversations/$conversationId?userId=$currentUserId',
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No group chat found for this trip'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        onFailure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open chat: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: context.primaryColor,
                    ),
                  ),
                  title: const Text('Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/profile');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: AppTheme.fitonistPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.card_membership,
                      color: AppTheme.fitonistPurple,
                    ),
                  ),
                  title: const Text('Join Trip by Code'),
                  subtitle: const Text('Enter an invite code'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/join-trip');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: AppTheme.success,
                    ),
                  ),
                  title: const Text('Trip History'),
                  subtitle: const Text('View completed trips'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/trip-history');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: AppTheme.error,
                    ),
                  ),
                  title: const Text('Emergency Services'),
                  subtitle: const Text('SOS, hospitals & emergency help'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/emergency');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: context.accentColor,
                    ),
                  ),
                  title: const Text('Theme'),
                  subtitle: const Text('Customize app colors'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/settings/theme');
                    }
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
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/settings');
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text('Control Room'),
                  subtitle: const Text('User management & analytics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (parentContext.mounted) {
                      parentContext.push('/settings/admin');
                    }
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
                    Navigator.pop(bottomSheetContext);
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (parentContext.mounted) {
                      parentContext.go('/');
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated action button with scale effect and haptic feedback
class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _scale = 0.92);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon button with glow effect and optional badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.color,
                          widget.color.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  // Badge for unread count
                  if (widget.badgeCount != null && widget.badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Center(
                          child: Text(
                            widget.badgeCount! > 99 ? '99+' : widget.badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Label below
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
