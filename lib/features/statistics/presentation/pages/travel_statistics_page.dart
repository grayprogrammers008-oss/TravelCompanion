import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../providers/statistics_providers.dart';

/// Travel Statistics Dashboard - Shows comprehensive travel analytics
class TravelStatisticsPage extends ConsumerWidget {
  const TravelStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(travelStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Statistics'),
        centerTitle: true,
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TravelStatistics stats) {
    return RefreshIndicator(
      onRefresh: () async {
        // Stats will automatically refresh through StreamProvider
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Overview Section
            _buildSectionHeader(context, 'Trip Overview', Icons.flight_takeoff),
            const SizedBox(height: AppTheme.spacingSm),
            _buildTripOverview(context, stats),
            const SizedBox(height: AppTheme.spacingLg),

            // Expense Summary Section
            _buildSectionHeader(context, 'Expense Summary', Icons.account_balance_wallet),
            const SizedBox(height: AppTheme.spacingSm),
            _buildExpenseSummary(context, stats),
            const SizedBox(height: AppTheme.spacingLg),

            // Travel Achievements Section
            _buildSectionHeader(context, 'Travel Achievements', Icons.emoji_events),
            const SizedBox(height: AppTheme.spacingSm),
            _buildAchievements(context, stats),
            const SizedBox(height: AppTheme.spacingLg),

            // Trip Ratings Section
            if (stats.hasRatedTrips) ...[
              _buildSectionHeader(context, 'Trip Ratings', Icons.star),
              const SizedBox(height: AppTheme.spacingSm),
              _buildRatingsSection(context, stats),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // Trip Status Breakdown
            _buildSectionHeader(context, 'Trip Status', Icons.pie_chart),
            const SizedBox(height: AppTheme.spacingSm),
            _buildTripStatusBreakdown(context, stats),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: context.primaryColor,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTripOverview(BuildContext context, TravelStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Trips',
            value: stats.totalTrips.toString(),
            icon: Icons.luggage,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _StatCard(
            label: 'Days Traveled',
            value: stats.totalDaysTraveled.toString(),
            icon: Icons.calendar_today,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseSummary(BuildContext context, TravelStatistics stats) {
    final currencySymbol = stats.primaryCurrency == 'INR' ? '₹' : '\$';

    return Column(
      children: [
        // Total spent card (full width)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade400,
                Colors.purple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments, color: Colors.white, size: 24),
                  SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Total Spent',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                '$currencySymbol${_formatAmount(stats.totalExpenses)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                '${stats.expenseCount} expenses recorded',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // Average per trip
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Avg per Trip',
                value: '$currencySymbol${_formatAmount(stats.averageExpensePerTrip)}',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _StatCard(
                label: 'Trips with Expenses',
                value: stats.tripsWithExpenses.toString(),
                icon: Icons.receipt_long,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievements(BuildContext context, TravelStatistics stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AchievementCard(
                icon: Icons.location_on,
                label: 'Destinations',
                value: stats.uniqueDestinations.toString(),
                subtitle: 'places visited',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _AchievementCard(
                icon: Icons.group,
                label: 'Travel Crew',
                value: stats.uniqueCrewMembers.toString(),
                subtitle: 'people traveled with',
                color: Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: _AchievementCard(
                icon: Icons.check_circle,
                label: 'Completed',
                value: stats.completedTrips.toString(),
                subtitle: 'trips finished',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _AchievementCard(
                icon: Icons.checklist,
                label: 'Tasks Done',
                value: stats.checklistItemsCompleted.toString(),
                subtitle: 'items checked off',
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingsSection(BuildContext context, TravelStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      final rating = stats.averageRating;
                      if (index < rating.floor()) {
                        return const Icon(Icons.star, color: Colors.amber, size: 20);
                      } else if (index < rating.ceil() && rating % 1 >= 0.5) {
                        return const Icon(Icons.star_half, color: Colors.amber, size: 20);
                      } else {
                        return const Icon(Icons.star_border, color: Colors.amber, size: 20);
                      }
                    }),
                  ),
                  Text(
                    '${stats.ratedTrips} trips rated',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatusBreakdown(BuildContext context, TravelStatistics stats) {
    final total = stats.totalTrips;
    if (total == 0) {
      return _buildEmptyTripsMessage(context);
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          _buildStatusRow(
            context,
            label: 'Active',
            count: stats.activeTrips,
            total: total,
            color: Colors.blue,
            icon: Icons.play_circle,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStatusRow(
            context,
            label: 'Upcoming',
            count: stats.upcomingTrips,
            total: total,
            color: Colors.orange,
            icon: Icons.schedule,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildStatusRow(
            context,
            label: 'Completed',
            count: stats.completedTrips,
            total: total,
            color: Colors.green,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spacingSm),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        SizedBox(
          width: 50,
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTripsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flight_takeoff,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'No trips yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Start planning your first adventure!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Failed to load statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
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
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}

/// Achievement card widget
class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _AchievementCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
