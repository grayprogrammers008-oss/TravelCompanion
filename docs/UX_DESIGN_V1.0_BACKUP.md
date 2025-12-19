# TravelCompanion UX Design V1.0 (Backup)

**Created:** December 18, 2025
**Status:** ARCHIVED - This is the backup of the design before the Trip-First UX redesign

---

## Overview

This document preserves the V1.0 design architecture before implementing the new "Trip-First" UX redesign. Use this document to rollback to V1.0 if needed.

---

## V1.0 Navigation Structure

### Bottom Navigation (5 Tabs)

```
[Home] [Trips] [Explore] [Expenses] [Profile]
  0       1        2         3         4
```

**File:** `lib/core/presentation/main_scaffold.dart`

```dart
BottomNavigationBar(
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
)
```

### Shell Routes

| Shell Class | Tab Index | Page |
|-------------|-----------|------|
| `DashboardShell` | 0 | `DashboardPage` |
| `TripsShell` | 1 | `HomePage` (trips list) |
| `ExploreShell` | 2 | `BrowseTripsPage` |
| `ExpensesShell` | 3 | `ExpensesHomePage` |
| `ProfileShell` | 4 | `ProfilePage` |
| `TripDetailShell` | 1 | `TripDetailPage` |

---

## V1.0 Dashboard Page (Tab 0 - Home)

**File:** `lib/features/home/presentation/pages/dashboard_page.dart`

### Structure
1. **App Bar** - Greeting with user avatar, 3-dot menu
2. **Active Trip Hero Card** - Large card with destination image, countdown, member avatars
3. **Quick Actions Section** - Horizontal scrollable action buttons
4. **Today's Itinerary Section** - Current day's activities
5. **Unified Expenses Section** - Trip expenses + personal expenses
6. **Trip Members Section** - Member avatars

### Quick Actions (V1.0 - Mixed Trip-scoped & Global)
```dart
// These actions are MIXED - some are trip-scoped, some are global
// This is the UX problem we're fixing in V2.0

_buildActionButton('Expense', ...)      // Trip-scoped
_buildActionButton('Itinerary', ...)    // Trip-scoped
_buildActionButton('Checklist', ...)    // Trip-scoped
_buildActionButton('Chat', ...)         // Trip-scoped
_buildActionButton('Invite', ...)       // Trip-scoped
_buildActionButton('New Trip', ...)     // GLOBAL
_buildActionButton('Join', ...)         // GLOBAL
_buildActionButton('AI Wizard', ...)    // GLOBAL
_buildActionButton('SOS', ...)          // Trip-scoped
```

### Active Trip Card Features
- Destination image background
- Countdown badge (days until trip)
- Progress badge (Day X of Y for ongoing trips)
- Member avatar stack
- Trip name, location, date
- "View Trip" button

---

## V1.0 Trips List Page (Tab 1 - Trips)

**File:** `lib/features/trips/presentation/pages/home_page.dart`

### Features
- Search bar
- Filter options (status, budget, date)
- Sort options (recent, name, startDate, budget)
- Trip cards with destination images
- Create trip bottom sheet with options:
  - Quick Trip
  - AI Trip Wizard
  - Start from Scratch
  - Use Template

### Create Trip Options (Bottom Sheet)
```dart
void _showCreateTripOptions(BuildContext context, AppThemeData themeData) {
  showModalBottomSheet(
    // Quick Trip - highlighted
    // AI Trip Wizard - highlighted with gradient
    // "or manual" divider
    // Start from Scratch
    // Use a Template
  );
}
```

---

## V1.0 Route Configuration

**File:** `lib/core/router/app_router.dart`

### Key Routes
```dart
static const String dashboard = '/dashboard';
static const String home = '/home'; // Legacy - redirects to dashboard
static const String trips = '/trips';
static const String explore = '/explore';
static const String expenses = '/expenses';
static const String profile = '/profile';
static const String tripDetail = '/trips/:tripId';
static const String createTrip = '/trips/create';
static const String quickTrip = '/trips/quick';
static const String voiceTrip = '/trips/voice';
static const String aiTripWizard = '/trips/ai-wizard';
static const String joinByCode = '/join-trip';
```

### Auth Redirect Logic (V1.0)
```dart
// New users (no trips) → Welcome Choice page
// Returning users (has trips) → Dashboard
return hasTrips ? AppRoutes.dashboard : AppRoutes.welcomeChoice;
```

---

## V1.0 Key Files Reference

### Core Navigation
- `lib/core/presentation/main_scaffold.dart` - 5-tab bottom nav
- `lib/core/router/app_router.dart` - All routes

### Dashboard (Tab 0)
- `lib/features/home/presentation/pages/dashboard_page.dart`
- `lib/features/home/presentation/providers/dashboard_providers.dart`

### Trips (Tab 1)
- `lib/features/trips/presentation/pages/home_page.dart` - Trip list
- `lib/features/trips/presentation/pages/trip_detail_page.dart`
- `lib/features/trips/presentation/pages/create_trip_page.dart`
- `lib/features/trips/presentation/pages/quick_trip_page.dart`
- `lib/features/trips/presentation/pages/voice_trip_page.dart`
- `lib/features/trips/presentation/pages/ai_trip_wizard_page.dart`
- `lib/features/trips/presentation/providers/trip_providers.dart`

### Explore (Tab 2)
- `lib/features/trips/presentation/pages/browse_trips_page.dart`

### Expenses (Tab 3)
- `lib/features/expenses/presentation/pages/expenses_home_page.dart`
- `lib/features/expenses/presentation/pages/expense_list_page.dart`
- `lib/features/expenses/presentation/pages/add_expense_page.dart`

### Profile (Tab 4)
- `lib/features/settings/presentation/pages/profile_page.dart`
- `lib/features/settings/presentation/pages/settings_page_enhanced.dart`

### Trip Join
- `lib/features/trip_invites/presentation/pages/join_trip_by_code_page.dart`
- `lib/features/trip_invites/presentation/pages/accept_invite_page.dart`

### Onboarding
- `lib/features/onboarding/presentation/pages/welcome_choice_page.dart`

---

## V1.0 User Flows

### Flow 1: New User First Launch
```
Splash → Login/Signup → Onboarding → Welcome Choice → Create/Join Trip
```

### Flow 2: Returning User with Trips
```
Splash → Dashboard (shows active trip) → Quick Actions → Trip-specific pages
```

### Flow 3: Creating a Trip (V1.0)
```
Trips Tab → FAB or Header + → Bottom Sheet → Choose method:
├── Quick Trip → Quick form → Trip created
├── AI Wizard → Voice input → AI generates → Review → Trip created
├── From Scratch → Full form → Trip created
└── Template → Browse → Select → Customize → Trip created
```

### Flow 4: Joining a Trip (V1.0)
```
Option A: Dashboard menu → Join Trip by Code → Enter code → Joined
Option B: Explore tab → Browse public trips → Tap Join → Joined
Option C: Deep link /invite/:code → Accept page → Joined
```

---

## V1.0 Known UX Issues (Why We're Redesigning)

### Issue 1: Mixed Quick Actions
The Dashboard Quick Actions mix trip-scoped actions (Expense, Checklist, Itinerary) with global actions (New Trip, Join). Users don't understand context.

### Issue 2: Dashboard vs Trips Confusion
- Dashboard (Tab 0) shows ONE active trip
- Trips (Tab 1) shows ALL trips
- Users confused about which tab to use

### Issue 3: 5 Tabs Cognitive Overload
- Home, Trips, Explore, Expenses, Profile
- Expenses tab duplicates what's in Trip Detail
- Too many entry points for same functionality

### Issue 4: No Summary for Joined Trips
When user joins a trip, they land on trip detail with no context about what's already planned or what needs their attention.

### Issue 5: Join Code Buried
Join trip by code is hidden in Dashboard menu, not discoverable.

---

## How to Rollback to V1.0

If the new design doesn't work out, restore these files:

1. **main_scaffold.dart** - Restore 5-tab navigation
2. **app_router.dart** - Restore /dashboard route as default
3. **dashboard_page.dart** - Keep as-is (not deleted)
4. **home_page.dart** - Restore original trip list without summary cards

### Git Commands
```bash
# If committed, find the commit hash before V2.0 changes
git log --oneline

# Checkout specific files from that commit
git checkout <commit-hash> -- lib/core/presentation/main_scaffold.dart
git checkout <commit-hash> -- lib/core/router/app_router.dart
# etc.
```

---

## V1.0 Screenshots (Reference)

### Dashboard (Home Tab)
```
┌─────────────────────────────────────────────────────────┐
│ Good morning,                               [⋮]        │
│ Vinoth                                                  │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐│
│ │                                                     ││
│ │  [Destination Image]                    👤👤👤 +2  ││
│ │                                                     ││
│ │  ┌─────────────┐                                   ││
│ │  │ 🛫 5 days   │                                   ││
│ │  │   to go     │                                   ││
│ │  └─────────────┘                                   ││
│ │  ┌─────────────────────────────────────────┐      ││
│ │  │ Goa Beach Getaway                       │      ││
│ │  │ 📍 Goa • 📅 Dec 20                      │      ││
│ │  │ [        View Trip        ]             │      ││
│ │  └─────────────────────────────────────────┘      ││
│ └─────────────────────────────────────────────────────┘│
│                                                         │
│ Quick Actions (for Goa Beach Getaway)                  │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐            │
│ │💰  │ │📅  │ │📝  │ │💬  │ │👥  │ │➕  │ →          │
│ │Exp │ │Itin│ │Chk │ │Chat│ │Inv │ │New │            │
│ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘            │
│                                                         │
│ Today's Plan                          [View All]       │
│ │ 09:00 Beach sunrise                                  │
│ │ 11:00 Water sports                                   │
│ │ 14:00 Lunch at Curlies                              │
│                                                         │
│ My Expenses                           [View All]       │
│ ┌─────────────────────────────────────────────────────┐│
│ │ 🛫 Goa Beach Getaway                                ││
│ │ Trip Expenses: ₹12,500         [Owed ₹3,125]       ││
│ │ ─────────────────────────────────────────────       ││
│ │ Settle Up:                                          ││
│ │ (V) Vinoth owes Priya           [₹250]              ││
│ └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
[Home] [Trips] [Explore] [Expenses] [Profile]
```

### Trips Tab
```
┌─────────────────────────────────────────────────────────┐
│ My Trips                      [🔍] [Filter] [+]        │
├─────────────────────────────────────────────────────────┤
│ [All] [Active] [Upcoming] [Completed]                  │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐│
│ │ [Image]  Goa Beach Getaway                          ││
│ │          📍 Goa • Dec 20-24                         ││
│ │          👥 4 members                               ││
│ └─────────────────────────────────────────────────────┘│
│                                                         │
│ ┌─────────────────────────────────────────────────────┐│
│ │ [Image]  Manali Adventure                           ││
│ │          📍 Manali • Jan 5-10                       ││
│ │          👥 6 members                               ││
│ └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
[Home] [Trips] [Explore] [Expenses] [Profile]
```

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| V1.0 | Dec 18, 2025 | Initial backup before V2.0 redesign |

---

**END OF V1.0 BACKUP DOCUMENT**
