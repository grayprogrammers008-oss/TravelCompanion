import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/trips/presentation/pages/home_page.dart';
import '../../features/expenses/presentation/pages/expenses_home_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';

/// Main scaffold with bottom navigation - 4 tabs: Home, Trips, Expenses, Profile
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
        context.go('/expenses');
        break;
      case 3:
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

/// Shell route for dashboard tab (Home)
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 0, child: DashboardPage());
  }
}

/// Shell route for trips tab
class TripsShell extends StatelessWidget {
  const TripsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 1, child: HomePage());
  }
}

/// Shell route for expenses tab
class ExpensesShell extends StatelessWidget {
  const ExpensesShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 2, child: ExpensesHomePage());
  }
}

/// Shell route for profile tab
class ProfileShell extends StatelessWidget {
  const ProfileShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 3, child: ProfilePage());
  }
}

// Legacy alias for backward compatibility
typedef HomeShell = DashboardShell;
