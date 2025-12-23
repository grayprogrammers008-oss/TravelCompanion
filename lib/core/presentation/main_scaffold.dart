import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/trips/presentation/pages/home_page.dart';
import '../../features/trips/presentation/pages/browse_trips_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/expenses/presentation/pages/expenses_home_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';

/// Main scaffold with bottom navigation - V3.0: 3 tabs (Trips, Explore, Discover)
///
/// DESIGN RATIONALE (Trip-First UX):
/// - Tab 0: Trips - All your trips (created + joined) - the primary hub
/// - Tab 1: Explore - Browse/join public trips
/// - Tab 2: Discover - Find tourist places by category (Beach, Hill Station, etc.)
/// - Profile & Settings: Accessible via header icons (avatar for profile, gear for settings)
///
/// V3.0 adds the Discover tab for real-time tourist place discovery using Google Places API.
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
        context.go('/trips');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/discover');
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
            icon: Icon(Icons.luggage_outlined),
            activeIcon: Icon(Icons.luggage),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.place_outlined),
            activeIcon: Icon(Icons.place),
            label: 'Discover',
          ),
        ],
        currentIndex: widget.currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

/// Shell route for trips tab - V2.0 Index 0 (Primary tab)
/// This is now the main landing page for authenticated users
class TripsShell extends StatelessWidget {
  const TripsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 0, child: HomePage());
  }
}

/// Shell route for explore tab - V3.0 Index 1
class ExploreShell extends StatelessWidget {
  const ExploreShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 1, child: BrowseTripsPage());
  }
}

/// Shell route for discover tab - V3.0 Index 2
/// Displays tourist places by category using Google Places API
class DiscoverShell extends StatelessWidget {
  const DiscoverShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(currentIndex: 2, child: DiscoverPage());
  }
}

/// @deprecated Profile tab removed in V2.1 - access via header avatar instead
/// Kept for backward compatibility during transition
class ProfileShell extends StatelessWidget {
  const ProfileShell({super.key});

  @override
  Widget build(BuildContext context) {
    // V2.1: Profile accessed via header avatar, not bottom nav
    // Still render ProfilePage but without bottom nav highlight
    return const MainScaffold(currentIndex: 0, child: ProfilePage());
  }
}

/// Shell route for trip detail page - keeps bottom nav visible
class TripDetailShell extends StatelessWidget {
  final String tripId;

  const TripDetailShell({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0, // Trips tab (V2.0 index)
      child: TripDetailPage(tripId: tripId),
    );
  }
}

// ============================================================================
// LEGACY SHELLS (V1.0) - Kept for backward compatibility during transition
// These can be removed once all routes are updated to V2.0
// ============================================================================

/// @deprecated Use TripsShell instead - Dashboard is now merged into Trips
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    // V2.0: Dashboard functionality merged into Trips tab
    // Redirect to Trips shell
    return const MainScaffold(currentIndex: 0, child: HomePage());
  }
}

/// @deprecated Expenses tab removed in V2.0 - access via Trip Detail instead
class ExpensesShell extends StatelessWidget {
  const ExpensesShell({super.key});

  @override
  Widget build(BuildContext context) {
    // V2.0: Expenses accessed through Trip Detail page
    // For now, show expenses home but from Trips tab context
    return const MainScaffold(currentIndex: 0, child: ExpensesHomePage());
  }
}

// Legacy alias for backward compatibility
typedef HomeShell = TripsShell;
