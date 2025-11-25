import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

/// Admin Statistics Overview Widget
/// Displays key statistics and metrics on the admin dashboard
class AdminStatsOverview extends ConsumerWidget {
  const AdminStatsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return statsAsync.when(
      data: (stats) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dashboard Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Real-time statistics and metrics',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // User Statistics
              _buildSectionHeader(context, 'User Statistics'),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Users',
                      stats.totalUsers.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active Users',
                      stats.activeUsers.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Suspended',
                      stats.suspendedUsers.toString(),
                      Icons.block,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Admins',
                      stats.adminsCount.toString(),
                      Icons.admin_panel_settings,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Growth Metrics
              _buildSectionHeader(context, 'User Growth'),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Today',
                      stats.newUsersToday.toString(),
                      Icons.today,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'This Week',
                      stats.newUsersWeek.toString(),
                      Icons.date_range,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'This Month',
                      stats.newUsersMonth.toString(),
                      Icons.calendar_month,
                      Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Activity Metrics
              _buildSectionHeader(context, 'Platform Activity'),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Trips',
                      stats.totalTrips.toString(),
                      Icons.flight_takeoff,
                      Colors.cyan,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Messages',
                      stats.totalMessages.toString(),
                      Icons.message,
                      Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active Today',
                      stats.activeUsersToday.toString(),
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: _buildPercentageCard(
                      context,
                      'Active %',
                      stats.activeUserPercentage,
                      Icons.pie_chart,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Engagement Metrics
              _buildSectionHeader(context, 'Engagement Metrics'),
              const SizedBox(height: AppTheme.spacingMd),
              _buildEngagementCard(
                context,
                'Average Trips per User',
                stats.averageTripsPerUser,
                Icons.flight,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildEngagementCard(
                context,
                'Average Messages per User',
                stats.averageMessagesPerUser,
                Icons.chat_bubble_outline,
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Failed to load statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(adminDashboardStatsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageCard(
    BuildContext context,
    String label,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 40),
          const SizedBox(width: AppTheme.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  value.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
