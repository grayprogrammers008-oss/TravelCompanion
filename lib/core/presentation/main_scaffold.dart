import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/trips/presentation/pages/home_page.dart';
import '../../features/trips/presentation/pages/browse_trips_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/expenses/presentation/pages/expenses_home_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';

/// Main scaffold with bottom navigation - 5 tabs: Home, Trips, Explore, Expenses, Profile
class MainScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/trips');
        break;
      case 2:
        context.go('/explore');
        break;
      case 3:
        context.go('/expenses');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff_outlined),
            activeIcon: Icon(Icons.flight_takeoff),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

/// Shell route for dashboard tab (Home) - Index 0
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 0, child: DashboardPage());
  }
}

/// Shell route for trips tab - Index 1
class TripsShell extends StatelessWidget {
  const TripsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 1, child: HomePage());
  }
}

/// Shell route for explore tab - Index 2
class ExploreShell extends StatelessWidget {
  const ExploreShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 2, child: BrowseTripsPage());
  }
}

/// Shell route for expenses tab - Index 3
class ExpensesShell extends StatelessWidget {
  const ExpensesShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 3, child: ExpensesHomePage());
  }
}

/// Shell route for profile tab - Index 4
class ProfileShell extends StatelessWidget {
  const ProfileShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 4, child: ProfilePage());
  }
}

/// Shell route for trip detail page - keeps bottom nav visible
class TripDetailShell extends StatelessWidget {
  final String tripId;

  const TripDetailShell({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1, // Trips tab
      child: TripDetailPage(tripId: tripId),
    );
  }
}

// Legacy alias for backward compatibility
typedef HomeShell = DashboardShell;
