import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../providers/dashboard_providers.dart';

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
                                UserAvatarWidget(
                                  imageUrl: currentUser.value?.avatarUrl,
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
                                // Notification bell
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                  onPressed: () {
                                    // TODO: Show notifications
                                  },
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

          // Today's Itinerary Section
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 2,
            child: _buildTodayItinerarySection(context, activeTrip.trip.id),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Expenses Summary Section
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 3,
            child: _buildExpensesSummarySection(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Trip Members Section
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 4,
            child: _buildTripMembersSection(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Quick Actions Section
          FadeSlideAnimation(
            delay: AppAnimations.staggerSmall * 5,
            child: _buildQuickActionsSection(context, activeTrip),
          ),
          const SizedBox(height: AppTheme.spacing3xl),
        ]),
      ),
    );
  }

  Widget _buildActiveTripCard(BuildContext context, TripWithMembers tripWithMembers) {
    final trip = tripWithMembers.trip;
    final now = DateTime.now();
    final startDate = trip.startDate;
    final endDate = trip.endDate;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (startDate != null && now.isBefore(startDate)) {
      final daysUntil = startDate.difference(now).inDays;
      statusText = '$daysUntil days until departure';
      statusColor = context.accentColor;
      statusIcon = Icons.flight_takeoff;
    } else if (startDate != null && endDate != null && now.isAfter(startDate) && now.isBefore(endDate)) {
      final dayNumber = now.difference(startDate).inDays + 1;
      final totalDays = endDate.difference(startDate).inDays + 1;
      statusText = 'Day $dayNumber of $totalDays';
      statusColor = AppTheme.success;
      statusIcon = Icons.explore;
    } else {
      statusText = 'Trip in progress';
      statusColor = AppTheme.success;
      statusIcon = Icons.explore;
    }

    return GestureDetector(
      onTap: () => context.push('/trips/${trip.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.shadowLg,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Stack(
            children: [
              // Background Image
              DestinationImage(
                tripName: trip.destination ?? trip.name,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                bottom: AppTheme.spacingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    // Trip Name
                    Text(
                      trip.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (trip.destination != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            trip.destination!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Tap indicator
              Positioned(
                right: AppTheme.spacingMd,
                top: AppTheme.spacingMd,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildExpensesSummarySection(BuildContext context, TripWithMembers tripWithMembers) {
    final trip = tripWithMembers.trip;
    final expensesAsync = ref.watch(tripExpensesProvider(trip.id));

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
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Expenses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/trips/${trip.id}/expenses'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          expensesAsync.when(
            data: (expenses) {
              final totalSpent = expenses.fold<double>(
                0,
                (sum, e) => sum + e.expense.amount,
              );
              final budget = trip.budget ?? 0;
              final percentage = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;

              return Column(
                children: [
                  // Budget progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                            '${trip.currency} ${totalSpent.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.neutral900,
                                ),
                          ),
                        ],
                      ),
                      if (budget > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Budget',
                              style: TextStyle(
                                color: AppTheme.neutral500,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${trip.currency} ${budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.neutral700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (budget > 0) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppTheme.neutral200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 0.9 ? AppTheme.error : AppTheme.success,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      '${(percentage * 100).toStringAsFixed(0)}% of budget used',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingMd),
                  // Quick add expense button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/trips/${trip.id}/expenses/add'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Expense'),
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
          const SizedBox(height: AppTheme.spacingMd),
          // Chat button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final trip = tripWithMembers.trip;
                final currentUserId = ref.read(currentUserProvider).value?.id ?? '';
                context.push('/trips/${trip.id}/chat?tripName=${Uri.encodeComponent(trip.name)}&userId=$currentUserId');
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Open Group Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              ),
            ),
          ),
        ],
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
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: context.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Action buttons grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: AppTheme.spacingSm,
            crossAxisSpacing: AppTheme.spacingSm,
            childAspectRatio: 0.85,
            children: [
              _buildActionButton(
                context,
                icon: Icons.receipt_long,
                label: 'Add\nExpense',
                color: AppTheme.success,
                onTap: () => context.push('/trips/${trip.id}/expenses/add'),
              ),
              _buildActionButton(
                context,
                icon: Icons.event,
                label: 'Add\nItinerary',
                color: AppTheme.info,
                onTap: () => context.push('/trips/${trip.id}/itinerary/add'),
              ),
              _buildActionButton(
                context,
                icon: Icons.checklist,
                label: 'View\nChecklists',
                color: AppTheme.warning,
                onTap: () => context.push('/trips/${trip.id}/checklists'),
              ),
              _buildActionButton(
                context,
                icon: Icons.chat_bubble_outline,
                label: 'Group\nChat',
                color: context.primaryColor,
                onTap: () {
                  final currentUserId = ref.read(currentUserProvider).value?.id ?? '';
                  context.push('/trips/${trip.id}/chat?tripName=${Uri.encodeComponent(trip.name)}&userId=$currentUserId');
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.person_add_outlined,
                label: 'Invite\nMember',
                color: context.accentColor,
                onTap: () => context.push('/trips/${trip.id}'),
              ),
              _buildActionButton(
                context,
                icon: Icons.flight_takeoff,
                label: 'New\nTrip',
                color: AppTheme.neutral600,
                onTap: () => context.push('/trips/create'),
              ),
              _buildActionButton(
                context,
                icon: Icons.qr_code_scanner,
                label: 'Join\nTrip',
                color: AppTheme.neutral500,
                onTap: () => context.push('/join-trip'),
              ),
              _buildActionButton(
                context,
                icon: Icons.emergency,
                label: 'Emergency',
                color: AppTheme.error,
                onTap: () => context.push('/emergency?tripId=${trip.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSm,
          horizontal: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutral700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
