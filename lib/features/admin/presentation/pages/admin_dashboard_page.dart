import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/admin/presentation/widgets/admin_stats_overview.dart';
import 'package:travel_crew/features/admin/presentation/widgets/admin_user_list.dart';
import 'package:travel_crew/features/admin/presentation/widgets/admin_activity_log_list.dart';

/// Admin Dashboard Page
/// Main admin panel with three tabs: Overview, Users, Activity
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: TEMPORARILY DISABLED - Restore admin check before production
    // TEMPORARY: Show dashboard to everyone for development
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Activity',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
          const AdminStatsOverview(),

          // Users Tab
          const AdminUserList(),

          // Activity Tab
          const AdminActivityLogList(),
        ],
      ),
    );
  }
}
