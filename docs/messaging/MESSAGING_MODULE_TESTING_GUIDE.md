# Messaging Module - Testing Guide

## Overview

Comprehensive guide to test all features of the messaging module including text messaging, reactions, image attachments, BLE P2P, WiFi Direct/Multipeer P2P, and Hybrid Sync Strategy.

## Prerequisites

### 1. Setup Requirements

**For Basic Testing:**
- Flutter SDK installed
- Android device/emulator or iOS device/simulator
- Firebase/Supabase backend configured
- Internet connection

**For P2P Testing:**
- 2+ physical devices (BLE, WiFi Direct, Multipeer require real devices)
- Android devices for WiFi Direct testing
- iOS devices for Multipeer testing
- Bluetooth enabled on devices
- WiFi enabled on devices
- Location permissions granted (required for BLE on Android)

### 2. Build and Install

```bash
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build for Android
flutter build apk --debug
# or run directly
flutter run

# Build for iOS
flutter build ios --debug
# or run directly
flutter run
```

## Testing Scenarios

### 1. Basic Messaging (Server-Based)

#### Test 1.1: Send Text Message

**Steps:**
1. Open the app and sign in
2. Navigate to a trip
3. Tap on the Messages/Chat tab
4. Type a message in the input field
5. Tap send button

**Expected Result:**
- ✅ Message appears in chat immediately
- ✅ Message shows sender name and timestamp
- ✅ Message syncs to server
- ✅ Other users in trip see the message

**Verification:**
- Check message appears in local chat
- Verify message exists in backend database
- Confirm other users receive the message

---

#### Test 1.2: Receive Messages

**Steps:**
1. Have another user send a message to the trip
2. Observe your chat screen

**Expected Result:**
- ✅ Message appears automatically (real-time)
- ✅ Notification received if app is in background
- ✅ Unread count updates
- ✅ Message shows correct sender info

---

#### Test 1.3: Reply to Message

**Steps:**
1. Long press or swipe on any message
2. Tap "Reply" option
3. Type your reply
4. Send the message

**Expected Result:**
- ✅ Reply indicator shows original message
- ✅ Reply is visually connected to original message
- ✅ Reply includes reference to quoted message

---

### 2. Reactions

#### Test 2.1: Add Reaction

**Steps:**
1. Long press on any message
2. Tap reaction icon or select from emoji picker
3. Choose an emoji (👍, ❤️, 😂, etc.)

**Expected Result:**
- ✅ Reaction appears below the message
- ✅ Reaction count updates
- ✅ Your reaction is highlighted
- ✅ Other users see your reaction

**Verification:**
```dart
// Check in code or database
message.reactions.any((r) => r.userId == currentUserId && r.emoji == '👍')
```

---

#### Test 2.2: View Who Reacted

**Steps:**
1. Tap on a reaction count/emoji
2. View the "Who Reacted" sheet

**Expected Result:**
- ✅ Sheet shows list of users who reacted
- ✅ Shows user names and emojis
- ✅ Grouped by emoji type
- ✅ Your reactions are highlighted

---

#### Test 2.3: Remove Reaction

**Steps:**
1. Tap on an emoji you previously added
2. Or long-press message and deselect emoji

**Expected Result:**
- ✅ Reaction is removed immediately
- ✅ Reaction count decreases
- ✅ Change syncs to other users

---

### 3. Image Attachments

#### Test 3.1: Send Image from Gallery

**Steps:**
1. Tap attachment icon (📎) in message input
2. Select "Gallery"
3. Choose an image
4. Add optional caption
5. Send

**Expected Result:**
- ✅ Upload progress shows
- ✅ Image uploads to storage (Firebase/Supabase)
- ✅ Message with image appears in chat
- ✅ Image is downloadable/viewable by others

---

#### Test 3.2: Send Image from Camera

**Steps:**
1. Tap attachment icon
2. Select "Camera"
3. Take a photo
4. Send the image

**Expected Result:**
- ✅ Camera opens correctly
- ✅ Photo is captured
- ✅ Image uploads successfully
- ✅ Image appears in chat

---

#### Test 3.3: View Full-Size Image

**Steps:**
1. Tap on an image in chat
2. Image viewer opens

**Expected Result:**
- ✅ Full-size image displayed
- ✅ Can pinch to zoom
- ✅ Can swipe to close
- ✅ Shows sender info and timestamp

---

### 4. BLE P2P Messaging (Offline/Nearby)

#### Test 4.1: Initialize BLE Service

**Steps:**
1. Open chat screen
2. BLE should auto-initialize
3. Check for bluetooth icon in app bar

**Expected Result:**
- ✅ BLE service initializes successfully
- ✅ No errors in debug console
- ✅ Bluetooth icon visible (if available)

**Debug Log:**
```
BLE initialization started
BLE Service initialized successfully
```

---

#### Test 4.2: Discover Nearby Peers (BLE)

**Prerequisites:** 2 devices with Bluetooth enabled, close proximity (< 10m)

**Steps:**
1. **Device A:** Tap bluetooth icon → "Start Advertising"
2. **Device B:** Tap bluetooth icon → "Start Scanning"
3. Wait for peer discovery

**Expected Result:**
- ✅ Device A appears in Device B's peer list
- ✅ Shows device name and signal strength (RSSI)
- ✅ Distance indicator (Near/Medium/Far)
- ✅ Can see connection status

**Verification:**
- Check "Nearby Peers" sheet shows discovered devices
- RSSI values update (stronger when closer)

---

#### Test 4.3: Connect to BLE Peer

**Steps:**
1. In "Nearby Peers" sheet, tap on a discovered peer
2. Tap "Connect"
3. Wait for connection

**Expected Result:**
- ✅ Connection status changes to "Connecting..."
- ✅ Then changes to "Connected"
- ✅ Peer shows in "Connected" section
- ✅ Connection is encrypted (E2EE)

---

#### Test 4.4: Send Message via BLE

**Steps:**
1. Ensure at least one BLE peer is connected
2. Type a message
3. Send (will broadcast to all BLE peers)

**Expected Result:**
- ✅ Message sent via BLE immediately
- ✅ Connected peer receives message offline
- ✅ Message also queues for server sync
- ✅ No duplicates when back online

**Verification:**
- Turn off internet on both devices
- Send message via BLE
- Message should still be received
- When back online, message syncs to server (only once)

---

#### Test 4.5: Mesh Networking (Multi-Hop)

**Prerequisites:** 3+ devices (A, B, C)

**Setup:**
- Device A ↔ Device B (connected)
- Device B ↔ Device C (connected)
- Device A and C out of BLE range

**Steps:**
1. **Device A:** Send message
2. **Device B:** Receives and relays
3. **Device C:** Should receive via mesh

**Expected Result:**
- ✅ Message hops through Device B
- ✅ Device C receives message
- ✅ No duplicates
- ✅ Mesh routing works automatically

---

### 5. WiFi Direct P2P (Android High-Bandwidth)

#### Test 5.1: Create WiFi Direct Group (Host)

**Prerequisites:** Android device with WiFi Direct support

**Steps:**
1. Tap WiFi icon (📶) in chat app bar
2. Tap "Start as Host"
3. Wait for group creation

**Expected Result:**
- ✅ WiFi Direct group created
- ✅ Shows group info (name, passphrase)
- ✅ Device is discoverable
- ✅ Can accept connections

**Debug Log:**
```
WiFi Direct group created successfully
Host mode activated
Group Name: DIRECT-XX-TravelCrew
```

---

#### Test 5.2: Join WiFi Direct Group (Client)

**Prerequisites:** Another Android device

**Steps:**
1. **Device B:** Tap WiFi icon → "Find Peers"
2. Wait for host to appear in peer list
3. Tap on host device
4. Connect

**Expected Result:**
- ✅ Host device discovered
- ✅ Connection request sent
- ✅ Host accepts connection
- ✅ Connected status shown

---

#### Test 5.3: Send Large File via WiFi Direct

**Steps:**
1. Ensure WiFi Direct connection established
2. Tap attachment icon
3. Select a large image (>5MB)
4. Send

**Expected Result:**
- ✅ File transfers via WiFi Direct (fast)
- ✅ Progress indicator shows transfer
- ✅ Transfer speed: 10-250 Mbps
- ✅ Receiver gets file successfully

**Performance:**
- Small files (<1MB): < 1 second
- Medium files (1-5MB): 1-5 seconds
- Large files (>5MB): ~5-10 seconds

---

### 6. Multipeer Connectivity (iOS/macOS)

#### Test 6.1: Start Multipeer Advertising

**Prerequisites:** iOS device or Mac

**Steps:**
1. Tap WiFi icon
2. Tap "Start as Host"
3. Service advertises on local network

**Expected Result:**
- ✅ Multipeer service starts
- ✅ Device advertises with service type "travel-companion"
- ✅ Other iOS/Mac devices can discover

---

#### Test 6.2: Browse and Connect (Multipeer)

**Prerequisites:** 2 iOS/Mac devices

**Steps:**
1. **Device A:** Start advertising
2. **Device B:** Start browsing
3. Device A appears in browse list
4. Tap to connect

**Expected Result:**
- ✅ Devices discover each other
- ✅ Connection invitation sent/received
- ✅ Connection established
- ✅ Automatic transport selection (WiFi/Bluetooth)

---

#### Test 6.3: Send Message via Multipeer

**Steps:**
1. Connect two iOS devices via Multipeer
2. Send a message
3. Verify receipt

**Expected Result:**
- ✅ Message sent instantly
- ✅ Works without internet
- ✅ Encrypted communication
- ✅ Syncs to server when online

---

### 7. Hybrid Sync Strategy

#### Test 7.1: Message Deduplication

**Scenario:** Same message arrives from multiple sources

**Steps:**
1. **Setup:** Connect via both BLE and Server
2. Send a message
3. Message arrives via both BLE and Server
4. Observe behavior

**Expected Result:**
- ✅ Message appears only once in UI
- ✅ Duplicate detected by content hash
- ✅ Statistics show 1 unique, 1 duplicate
- ✅ No duplicate storage

**Verification:**
```dart
// Check sync statistics
final stats = syncCoordinator.getStatistics();
expect(stats.deduplicationStats.duplicatesFound, greaterThan(0));
```

---

#### Test 7.2: Priority Queue

**Scenario:** Multiple messages with different priorities

**Steps:**
1. **Setup:** Queue multiple operations:
   - User sends message (HIGH priority)
   - Background sync runs (LOW priority)
   - Auto-sync messages (MEDIUM priority)
2. Observe processing order

**Expected Result:**
- ✅ HIGH priority processes first
- ✅ MEDIUM priority processes second
- ✅ LOW priority processes last
- ✅ User actions never blocked

**Check Queue:**
1. Tap Sync icon (🔄) in app bar
2. Open sync status sheet
3. Go to "Queue" tab
4. Verify priority ordering

---

#### Test 7.3: Conflict Resolution

**Scenario:** Same message modified on different devices

**Setup:**
1. **Device A:** Has message with timestamp T1
2. **Device B:** Has same message with timestamp T2 (T2 > T1)
3. Devices sync

**Steps:**
1. Turn off network on both devices
2. **Device A:** Add reaction to message
3. **Device B:** Edit same message
4. Turn on network
5. Wait for sync

**Expected Result:**
- ✅ Last-Write-Wins (LWW) applied
- ✅ Newer timestamp wins (Device B)
- ✅ Reactions merged (Device A's reaction kept)
- ✅ Read status merged
- ✅ No data loss

**Verification:**
- Check conflict resolution statistics
- Tap Sync icon → "Statistics" tab
- Should show conflicts resolved by timestamp/content

---

#### Test 7.4: Source Priority

**Scenario:** Conflict with same timestamp from different sources

**Priority Order:** Server > WiFi Direct > BLE > Local

**Steps:**
1. Message arrives simultaneously from:
   - BLE (source priority: 1)
   - Server (source priority: 3)
2. Observe which version is kept

**Expected Result:**
- ✅ Server version wins
- ✅ Source priority used as tie-breaker
- ✅ Statistics show "resolved by source"

---

#### Test 7.5: Offline Queue & Sync

**Scenario:** Send messages while offline, sync when online

**Steps:**
1. Turn off internet/data
2. Send 5-10 messages
3. Messages queue locally
4. Turn on internet
5. Observe sync

**Expected Result:**
- ✅ Messages queued with LOW priority
- ✅ Queue shows pending tasks
- ✅ When online, messages sync to server
- ✅ Queue processes in background
- ✅ No message loss

**Check Queue:**
- Tap Sync icon → "Queue" tab
- Should show queued tasks
- Watch them process one by one

---

### 8. Sync Status Dashboard

#### Test 8.1: View Sync Statistics

**Steps:**
1. Tap Sync icon (🔄) in app bar
2. Sync Status Sheet opens
3. Explore three tabs

**Tab 1 - Overview:**
- ✅ Shows sync status (Idle/Ready/Syncing)
- ✅ Queue size badge
- ✅ Active sources count
- ✅ Quick stats (messages synced, duplicates, conflicts, efficiency)
- ✅ Last sync time

**Tab 2 - Queue:**
- ✅ Priority queue breakdown (High/Medium/Low)
- ✅ Current task being processed
- ✅ Queue performance metrics
- ✅ Success/failure rates

**Tab 3 - Statistics:**
- ✅ Deduplication stats (total checks, duplicates found, cache usage)
- ✅ Conflict resolution stats (by timestamp, source, content)
- ✅ Visual progress bars
- ✅ Reset statistics button

---

#### Test 8.2: Sync Controls

**Steps:**
1. Open Sync Status Sheet
2. Try sync controls

**Available Controls:**
- ✅ Initialize Sync (if not initialized)
- ✅ Start/Stop Auto Sync
- ✅ Pause/Resume Queue
- ✅ Reset Statistics

**Testing:**
1. Click "Start Auto Sync"
   - Status changes to "Syncing..."
   - Sync icon animates
2. Click "Pause Queue"
   - Queue stops processing
   - Tasks remain queued
3. Click "Resume Queue"
   - Processing continues

---

### 9. End-to-End Scenarios

#### Scenario 9.1: Group Trip Chat (4 Users)

**Setup:**
- User A: Android, WiFi Direct
- User B: Android, BLE only
- User C: iOS, Multipeer
- User D: Server only (no P2P)

**Test Flow:**
1. All users join same trip chat
2. User A sends message
3. Message propagates via:
   - WiFi Direct to nearby Android users
   - BLE to nearby users
   - Server to User D
   - Multipeer to nearby iOS users

**Expected:**
- ✅ All users receive message
- ✅ Each user sees message only once
- ✅ No duplicates
- ✅ Delivery within 1-2 seconds

---

#### Scenario 9.2: Network Switch During Chat

**Setup:** User on WiFi with BLE enabled

**Test Flow:**
1. Start chatting on WiFi
2. Turn off WiFi (switch to cellular)
3. Continue chatting
4. BLE should maintain connectivity
5. Turn WiFi back on

**Expected:**
- ✅ Seamless transition
- ✅ No message loss
- ✅ Messages sync when back online
- ✅ No duplicates

---

#### Scenario 9.3: Offline Collaboration

**Setup:** 3 users in airplane mode, close proximity

**Test Flow:**
1. All users enable BLE/WiFi Direct
2. Turn on airplane mode (no internet)
3. Send messages to each other
4. Share images
5. Add reactions
6. Turn off airplane mode after 10 mins

**Expected:**
- ✅ All messages exchanged via P2P
- ✅ Images transferred successfully
- ✅ Reactions synced locally
- ✅ When online, all syncs to server
- ✅ No duplicates or conflicts

---

## Debug & Monitoring

### Enable Debug Logging

Add to main.dart:
```dart
void main() {
  // Enable debug logging
  debugPrint('=== Messaging Module Debug Mode ===');

  runApp(MyApp());
}
```

### Monitor Sync Events

```dart
// Listen to sync events
ref.listen(syncEventStreamProvider, (previous, next) {
  next.whenData((event) {
    print('Sync Event: ${event.type}');
    print('Message ID: ${event.messageId}');
    print('Source: ${event.source}');
  });
});
```

### Check Statistics Programmatically

```dart
// Get sync statistics
final syncCoordinator = ref.read(syncCoordinatorProvider);
final stats = syncCoordinator.getStatistics();

print('Messages Synced: ${stats.totalMessagesSynced}');
print('Duplicates: ${stats.totalDuplicatesSkipped}');
print('Conflicts: ${stats.totalConflictsResolved}');
print('Efficiency: ${(stats.overallEfficiency * 100).toStringAsFixed(1)}%');
```

### Monitor Queue

```dart
// Watch queue size
final queueSize = ref.watch(queueSizeProvider);
final isProcessing = ref.watch(queueIsProcessingProvider);

print('Queue Size: $queueSize');
print('Processing: $isProcessing');
```

## Performance Benchmarks

### Message Delivery Times

| Scenario | Expected Time | Acceptable Range |
|----------|--------------|------------------|
| Server (online) | 0.5-2s | < 3s |
| BLE (nearby) | 0.2-1s | < 2s |
| WiFi Direct | 0.1-0.5s | < 1s |
| Multipeer | 0.1-0.5s | < 1s |

### File Transfer Speeds

| Connection Type | Speed Range | Test File Size |
|----------------|-------------|----------------|
| Server Upload | 1-10 Mbps | 5MB image |
| BLE | 100-300 Kbps | < 1MB |
| WiFi Direct | 10-250 Mbps | 10MB+ |
| Multipeer | 10-100 Mbps | 5MB+ |

### Sync Performance

| Metric | Expected Value |
|--------|----------------|
| Deduplication Rate | 10-30% |
| Queue Success Rate | > 95% |
| Conflict Resolution (LWW) | > 80% |
| Overall Efficiency | > 85% |

## Troubleshooting

### Issue: BLE Not Discovering Peers

**Possible Causes:**
- Bluetooth not enabled
- Location permission not granted (Android)
- Devices too far apart (>10m)
- BLE not initialized

**Fix:**
1. Check Bluetooth is on
2. Grant location permission
3. Move devices closer
4. Restart BLE service

---

### Issue: WiFi Direct Connection Fails

**Possible Causes:**
- WiFi not enabled
- Permissions not granted
- Device doesn't support WiFi Direct
- Already in another group

**Fix:**
1. Enable WiFi
2. Grant all required permissions
3. Check device compatibility
4. Disconnect from other WiFi Direct groups

---

### Issue: Messages Appear Duplicated

**Diagnosis:**
- Check deduplication statistics
- Verify content hashing works

**Fix:**
1. Open Sync Status Sheet
2. Check "Statistics" tab
3. Should show duplicate detection
4. If not working, reset sync cache

---

### Issue: High Queue Size, Not Processing

**Diagnosis:**
- Queue may be paused
- Network issues preventing sync

**Fix:**
1. Open Sync Status Sheet → Queue tab
2. Check if queue is paused
3. Click "Resume Queue"
4. Check network connectivity

---

## Automated Testing

### Run All Tests

```bash
# Run all messaging tests
flutter test test/features/messaging/

# Run specific test suites
flutter test test/features/messaging/data/services/sync_services_test.dart
flutter test test/features/messaging/integration/hybrid_sync_integration_test.dart
flutter test test/features/messaging/e2e/hybrid_sync_e2e_test.dart

# Run with coverage
flutter test --coverage
```

### Test Coverage Report

```bash
# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Checklist: Complete Testing

### Basic Features
- [ ] Send text message
- [ ] Receive text message
- [ ] Reply to message
- [ ] Delete message
- [ ] Mark messages as read
- [ ] Unread count updates

### Reactions
- [ ] Add reaction
- [ ] Remove reaction
- [ ] View who reacted
- [ ] Multiple reactions on same message

### Attachments
- [ ] Send image from gallery
- [ ] Send image from camera
- [ ] View full-size image
- [ ] Download/share image

### BLE P2P
- [ ] Initialize BLE
- [ ] Discover nearby peers
- [ ] Connect to peer
- [ ] Send message via BLE
- [ ] Mesh networking (multi-hop)
- [ ] Disconnect gracefully

### WiFi Direct (Android)
- [ ] Create WiFi Direct group
- [ ] Join group as client
- [ ] Send message via WiFi Direct
- [ ] Transfer large file
- [ ] Multiple devices connected

### Multipeer (iOS)
- [ ] Start advertising
- [ ] Browse and connect
- [ ] Send message via Multipeer
- [ ] File transfer

### Hybrid Sync
- [ ] Deduplication works
- [ ] Priority queue processes correctly
- [ ] Conflicts resolved (LWW)
- [ ] Source priority used
- [ ] Offline queue syncs when online

### UI/UX
- [ ] Sync status indicator
- [ ] Queue badge shows count
- [ ] Statistics dashboard
- [ ] Sync controls work
- [ ] Real-time updates
- [ ] Smooth animations

### Performance
- [ ] Message delivery < 3s
- [ ] No UI lag
- [ ] Efficient battery usage
- [ ] Memory usage reasonable
- [ ] No crashes or ANRs

---

**Last Updated:** 2025-10-25
**Version:** 1.0.0
**Test Coverage:** 190+ automated tests
