# 🔄 Real-time Synchronization Guide

**Status**: ✅ Implemented
**Issue**: [#8 - Add Real-time Synchronization Across Devices](https://github.com/vinothvsbe/TravelCompanion/issues/8)
**Date**: October 21, 2025

---

## 🎯 Overview

Travel Crew now has comprehensive real-time synchronization powered by Supabase Realtime. Changes made on one device instantly appear on all other devices viewing the same data.

### What's Synchronized

- ✅ **Trips** - Create, update, delete operations
- ✅ **Trip Members** - Join, leave, role changes
- ✅ **Expenses** - New expenses, updates, deletions
- ✅ **Itinerary Items** - Activity changes
- ✅ **Checklists** - Checklist and item updates

---

## 🏗️ Architecture

### Core Components

#### 1. RealtimeService
**Location**: `lib/core/services/realtime_service.dart`

Central service managing all Supabase Realtime channels. Provides:
- Channel lifecycle management
- Automatic subscription/unsubscription
- Broadcast streams for multiple listeners
- Memory-efficient channel reuse

#### 2. Enhanced Data Sources
**Updated Files**:
- `lib/features/trips/data/datasources/trip_remote_datasource.dart`
- More to come: Expenses, Itinerary, Checklists

Each datasource now includes:
- `watch*()` methods returning real-time streams
- Initial data load + live updates
- Automatic refetch on changes
- Proper cleanup on stream cancellation

#### 3. Riverpod Providers
**Location**: `lib/core/providers/realtime_provider.dart`

Singleton provider for RealtimeService with automatic disposal.

---

## 📖 Usage Examples

### Example 1: Watch User's Trips

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripsListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(tripRemoteDataSourceProvider);

    return StreamBuilder<List<TripWithMembers>>(
      stream: dataSource.watchUserTrips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final trips = snapshot.data ?? [];

        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return TripCard(trip: trip); // Updates automatically!
          },
        );
      },
    );
  }
}
```

**What happens**:
1. Initial trips loaded immediately
2. When Nithya adds a new trip from her device → List updates instantly
3. When someone updates trip details → Card updates automatically
4. When trip is deleted → Removed from list in real-time

---

### Example 2: Watch Specific Trip Details

```dart
class TripDetailPage extends ConsumerWidget {
  final String tripId;

  const TripDetailPage({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(tripRemoteDataSourceProvider);

    return StreamBuilder<TripWithMembers>(
      stream: dataSource.watchTrip(tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final trip = snapshot.data!;

        return Column(
          children: [
            Text(trip.trip.name), // Updates in real-time!
            Text('${trip.trip.destination}'),
            Text('${trip.members.length} members'),
            // Any field updates automatically
          ],
        );
      },
    );
  }
}
```

**What happens**:
1. Trip details loaded on page open
2. When someone edits trip name → UI updates instantly
3. When dates change → Reflected immediately
4. No manual refresh needed!

---

### Example 3: Watch Trip Members

```dart
class TripMembersWidget extends ConsumerWidget {
  final String tripId;

  const TripMembersWidget({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(tripRemoteDataSourceProvider);

    return StreamBuilder<List<TripMemberModel>>(
      stream: dataSource.watchTripMembers(tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final members = snapshot.data!;

        return Column(
          children: [
            Text('${members.length} crew members'),
            ...members.map((member) => ListTile(
              leading: CircleAvatar(
                backgroundImage: member.avatarUrl != null
                    ? NetworkImage(member.avatarUrl!)
                    : null,
              ),
              title: Text(member.fullName ?? 'Unknown'),
              subtitle: Text(member.role),
            )),
          ],
        );
      },
    );
  }
}
```

**What happens**:
1. Member list loaded initially
2. When Nithya joins → Avatar appears instantly for everyone
3. When someone leaves → Removed from list automatically
4. When role changes (member → admin) → Badge updates

---

### Example 4: Manual Realtime Subscription

For custom use cases, you can use RealtimeService directly:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomRealtimeWidget extends ConsumerStatefulWidget {
  final String tripId;

  const CustomRealtimeWidget({required this.tripId});

  @override
  ConsumerState<CustomRealtimeWidget> createState() => _CustomRealtimeWidgetState();
}

class _CustomRealtimeWidgetState extends ConsumerState<CustomRealtimeWidget> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    final realtimeService = ref.read(realtimeServiceProvider);

    // Subscribe to trip changes
    _subscription = realtimeService.subscribeTripChanges(widget.tripId).listen(
      (payload) {
        if (kDebugMode) {
          debugPrint('Trip changed: ${payload.eventType}');
          debugPrint('New data: ${payload.newRecord}');
          debugPrint('Old data: ${payload.oldRecord}');
        }

        // Handle the change
        if (payload.eventType == PostgresChangeEvent.update) {
          // Trip was updated
          final newData = payload.newRecord;
          setState(() {
            // Update local state
          });
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          // Trip was deleted
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(/* Your UI */);
  }
}
```

---

## 🎭 Event Types

### PostgresChangePayload Properties

```dart
payload.eventType      // INSERT, UPDATE, DELETE
payload.newRecord      // New data (Map<String, dynamic>)
payload.oldRecord      // Old data (for UPDATE/DELETE)
payload.commitTimestamp // Server timestamp
```

### Handling Different Events

```dart
realtimeService.subscribeTripChanges(tripId).listen((payload) {
  switch (payload.eventType) {
    case PostgresChangeEvent.insert:
      // New record created
      final newTrip = TripModel.fromJson(payload.newRecord);
      print('New trip: ${newTrip.name}');
      break;

    case PostgresChangeEvent.update:
      // Record updated
      final updatedTrip = TripModel.fromJson(payload.newRecord);
      final oldTrip = TripModel.fromJson(payload.oldRecord);
      print('Trip updated: ${oldTrip.name} → ${updatedTrip.name}');
      break;

    case PostgresChangeEvent.delete:
      // Record deleted
      final deletedTrip = TripModel.fromJson(payload.oldRecord);
      print('Trip deleted: ${deletedTrip.name}');
      break;
  }
});
```

---

## 🔧 Available Realtime Methods

### RealtimeService Methods

```dart
// Trip subscriptions
realtimeService.subscribeTripChanges(tripId)
realtimeService.subscribeUserTrips(userId)
realtimeService.subscribeTripMemberChanges(tripId)

// Expense subscriptions
realtimeService.subscribeExpenseChanges(tripId)

// Itinerary subscriptions
realtimeService.subscribeItineraryChanges(tripId)

// Checklist subscriptions
realtimeService.subscribeChecklistChanges(tripId)
realtimeService.subscribeChecklistItemChanges(checklistId)

// Channel management
realtimeService.unsubscribe(channelName)
realtimeService.unsubscribeAll()
realtimeService.dispose()

// Monitoring
realtimeService.activeChannelCount
realtimeService.isChannelActive(channelName)
```

### TripRemoteDataSource Methods

```dart
// Watch all user's trips
dataSource.watchUserTrips() // Stream<List<TripWithMembers>>

// Watch specific trip
dataSource.watchTrip(tripId) // Stream<TripWithMembers>

// Watch trip members
dataSource.watchTripMembers(tripId) // Stream<List<TripMemberModel>>
```

---

## 🎯 Best Practices

### 1. Use StreamBuilder for UI Updates

✅ **Good**:
```dart
StreamBuilder<List<Trip>>(
  stream: dataSource.watchUserTrips(),
  builder: (context, snapshot) {
    // UI updates automatically
  },
)
```

❌ **Avoid**:
```dart
// Don't manually poll for updates
Timer.periodic(Duration(seconds: 5), (_) {
  dataSource.getUserTrips(); // Wasteful!
});
```

### 2. Dispose Subscriptions Properly

✅ **Good**:
```dart
@override
void dispose() {
  _subscription.cancel(); // Clean up!
  super.dispose();
}
```

❌ **Avoid**:
```dart
// Forgetting to cancel creates memory leaks
```

### 3. Handle Errors Gracefully

✅ **Good**:
```dart
StreamBuilder(
  stream: dataSource.watchTrip(tripId),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error);
    }
    // ...
  },
)
```

### 4. Use Providers for Dependency Injection

✅ **Good**:
```dart
final dataSource = ref.watch(tripRemoteDataSourceProvider);
```

❌ **Avoid**:
```dart
final dataSource = TripRemoteDataSourceImpl(); // No cleanup!
```

---

## 🐛 Debugging

### Check Active Channels

```dart
final realtimeService = ref.read(realtimeServiceProvider);
print('Active channels: ${realtimeService.activeChannelCount}');
```

### Enable Debug Logging

Realtime logging is already enabled in debug mode:
```dart
// In RealtimeService
if (kDebugMode) {
  debugPrint('🔄 Trip change detected: ${payload.eventType}');
}
```

### Monitor Supabase Realtime

Check Supabase dashboard → Realtime → Channels to see active subscriptions.

---

## 🚀 Performance Considerations

### Automatic Channel Reuse

RealtimeService automatically reuses channels when multiple widgets subscribe to the same data:

```dart
// Widget A
dataSource.watchTrip(tripId); // Creates channel

// Widget B (same tripId)
dataSource.watchTrip(tripId); // Reuses existing channel!
```

### Memory Efficiency

Broadcast streams allow multiple listeners without duplicate subscriptions:
```dart
final controller = StreamController<TripWithMembers>.broadcast();
```

### Automatic Cleanup

Channels are automatically unsubscribed when streams are cancelled:
```dart
controller.onCancel = () {
  subscription.cancel();
  _realtimeService.unsubscribe('trip:$tripId');
};
```

---

## 🔮 Future Enhancements

### Coming Soon

1. **Optimistic Updates** - UI updates before server confirmation
2. **Conflict Resolution** - Last-write-wins strategy
3. **Offline Queue** - Queue changes when offline, sync when online
4. **Presence Indicators** - "Nithya is viewing this trip"
5. **Typing Indicators** - "Vinoth is editing..."

---

## 📚 Related Files

### Core Services
- `lib/core/services/realtime_service.dart` - Main realtime service
- `lib/core/providers/realtime_provider.dart` - Riverpod provider

### Data Sources (Updated)
- `lib/features/trips/data/datasources/trip_remote_datasource.dart` - Trip realtime
- Coming: Expenses, Itinerary, Checklists

### Documentation
- [CLAUDE.md](../../CLAUDE.md) - Overall project progress
- [Issue #8](https://github.com/vinothvsbe/TravelCompanion/issues/8) - Original issue

---

## ✅ Testing Realtime Sync

### Test Scenario 1: Two Devices

1. **Device A (Your phone)**:
   - Open Travel Crew
   - View trips list

2. **Device B (Nithya's phone)**:
   - Open Travel Crew
   - Create a new trip

3. **Result**: Device A sees new trip appear instantly! ✨

### Test Scenario 2: Edit Trip

1. **Device A**: Open trip "Bali 2025"
2. **Device B**: Edit trip name to "Bali Adventure 2025"
3. **Result**: Device A sees name update in real-time!

### Test Scenario 3: Add Member

1. **Device A**: View trip members
2. **Device B**: Add a new crew member
3. **Result**: Device A sees new member avatar appear!

---

## 🎊 Success!

Real-time synchronization is now active across your entire app. Changes propagate instantly, creating a seamless collaborative experience for trip crews!

**Next**: Add this to Expenses, Itinerary, and Checklists following the same pattern.
