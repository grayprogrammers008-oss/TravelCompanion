#!/bin/bash

# Create GitHub issues for Messaging Module (Phase 1)
# Run this script to add messaging features to the GitHub project

REPO_OWNER="vinothvsbe"  # GitHub username
REPO_NAME="TravelCompanion"
PROJECT_NAME="Travel Crew MVP - 8 Week Sprint"

echo "🚀 Creating Messaging Module Issues for Phase 1..."
echo ""

# Issue 1: Core Messaging Infrastructure
gh issue create \
  --title "Feature: Core Messaging Infrastructure" \
  --label "enhancement,messaging,phase-1" \
  --body "## 📱 Core Messaging Infrastructure

### Description
Implement the foundational messaging system for Travel Crew with real-time and offline capabilities.

### Requirements

#### Data Model
- [ ] Create \`messages\` table in Supabase
  - \`id\` (UUID, primary key)
  - \`trip_id\` (UUID, foreign key to trips)
  - \`sender_id\` (UUID, foreign key to profiles)
  - \`message\` (text, max 2000 chars)
  - \`message_type\` (enum: text, image, location, expense_link)
  - \`reply_to_id\` (UUID, nullable, for threaded replies)
  - \`attachment_url\` (text, nullable)
  - \`created_at\` (timestamp)
  - \`updated_at\` (timestamp)
  - \`is_deleted\` (boolean)
  - \`read_by\` (jsonb, array of user IDs who read the message)

- [ ] Create \`message_queue\` table for offline messages
  - \`id\` (UUID, primary key)
  - \`trip_id\` (UUID)
  - \`sender_id\` (UUID)
  - \`message_data\` (jsonb)
  - \`sync_status\` (enum: pending, syncing, synced, failed)
  - \`retry_count\` (integer)
  - \`created_at\` (timestamp)

#### Database Features
- [ ] Add RLS policies for message access (users can only read messages for trips they're members of)
- [ ] Add indexes for performance (trip_id, created_at)
- [ ] Add trigger for updating \`updated_at\` timestamp
- [ ] Add trigger for real-time notifications

#### Domain Layer
- [ ] Create \`Message\` entity with Freezed
- [ ] Create \`MessageRepository\` interface
- [ ] Create use cases:
  - \`SendMessageUseCase\`
  - \`GetTripMessagesUseCase\`
  - \`MarkMessageAsReadUseCase\`
  - \`DeleteMessageUseCase\`

#### Data Layer
- [ ] Create \`MessageModel\` with JSON serialization
- [ ] Implement \`MessageRemoteDataSource\` (Supabase)
- [ ] Implement \`MessageLocalDataSource\` (Hive/SQLite for offline)
- [ ] Implement \`MessageRepositoryImpl\` with offline-first strategy

### Technical Specs
- Use Supabase Realtime for instant message delivery
- Use Hive for local message cache
- Implement message queue for offline sending
- Auto-retry failed messages when online

### Acceptance Criteria
- [ ] Database schema deployed to Supabase
- [ ] All models and entities created with code generation
- [ ] Repository implemented with offline support
- [ ] Messages sync when going online
- [ ] Unit tests for use cases
- [ ] Integration tests for repository

### Estimated Time: 3 days

### Dependencies
- Requires existing Trip and User models
- Requires Supabase Realtime setup

### Files to Create
\`\`\`
lib/shared/models/message_model.dart
lib/features/messaging/domain/entities/message_entity.dart
lib/features/messaging/domain/repositories/message_repository.dart
lib/features/messaging/domain/usecases/send_message_usecase.dart
lib/features/messaging/domain/usecases/get_trip_messages_usecase.dart
lib/features/messaging/data/models/message_model.dart
lib/features/messaging/data/datasources/message_remote_datasource.dart
lib/features/messaging/data/datasources/message_local_datasource.dart
lib/features/messaging/data/repositories/message_repository_impl.dart
\`\`\`

### SQL Schema
\`\`\`sql
-- See scripts/database/messaging_schema.sql
\`\`\`
" \
  --assignee "@me"

echo "✅ Issue 1: Core Messaging Infrastructure created"
echo ""

# Issue 2: Real-time Chat UI
gh issue create \
  --title "Feature: Real-time Chat UI for Trips" \
  --label "enhancement,messaging,ui,phase-1" \
  --body "## 💬 Real-time Chat UI

### Description
Create a beautiful, real-time chat interface for trip crew members to communicate.

### Requirements

#### Chat Screen
- [ ] Create \`TripChatPage\` (full-screen chat)
- [ ] Display messages in chronological order
- [ ] Show sender avatar and name
- [ ] Show timestamp (with smart formatting: \"Just now\", \"5m ago\", \"Yesterday\")
- [ ] Group messages by date with date dividers
- [ ] Differentiate own messages vs others (different alignment/color)

#### Message Input
- [ ] Text input field at bottom (sticky)
- [ ] Send button (disabled when empty)
- [ ] Character counter (max 2000 chars)
- [ ] Multi-line support (auto-expand up to 4 lines)
- [ ] Emoji picker integration
- [ ] Attachment button (image, location)

#### Real-time Updates
- [ ] Auto-scroll to bottom on new message
- [ ] Show \"typing...\" indicator when someone is typing
- [ ] Show \"online\" status for crew members
- [ ] Unread message counter in trip detail screen
- [ ] Badge on bottom navigation when new messages

#### Message Features
- [ ] Long press to copy message
- [ ] Swipe right to reply (threaded messages)
- [ ] Double-tap to like/react
- [ ] Pull down to load older messages (pagination)
- [ ] Show message delivery status (sending, sent, read)

#### Offline Indicators
- [ ] Show offline banner when no connection
- [ ] Show pending messages with retry option
- [ ] Gray out send button when offline (with tooltip)

### UI/UX Design

#### Message Bubbles
\`\`\`
Own messages:
- Right-aligned
- Primary teal gradient background
- White text
- Rounded corners (more on left)

Others' messages:
- Left-aligned
- Light gray background
- Dark text
- Avatar on left
- Rounded corners (more on right)
\`\`\`

#### Smart Features
- [ ] Tap on expense mention to open expense details
- [ ] Tap on location to open map
- [ ] Tap on image to view full screen
- [ ] Detect and linkify URLs

### Acceptance Criteria
- [ ] Messages load instantly from cache (offline-first)
- [ ] New messages appear in real-time (< 1 second)
- [ ] Smooth scrolling with 60 FPS
- [ ] Typing indicators work
- [ ] Offline messages show in queue
- [ ] Works perfectly on small screens (iPhone SE)
- [ ] Follows Travel Crew design system

### Estimated Time: 4 days

### Design References
- WhatsApp chat UI (familiar UX)
- Telegram bubbles (clean design)
- Travel Crew glossy design system

### Files to Create
\`\`\`
lib/features/messaging/presentation/pages/trip_chat_page.dart
lib/features/messaging/presentation/widgets/message_bubble.dart
lib/features/messaging/presentation/widgets/message_input.dart
lib/features/messaging/presentation/widgets/typing_indicator.dart
lib/features/messaging/presentation/widgets/date_divider.dart
lib/features/messaging/presentation/widgets/offline_banner.dart
lib/features/messaging/presentation/providers/messaging_providers.dart
\`\`\`

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires emoji_picker_flutter package
- Requires image_picker package
" \
  --assignee "@me"

echo "✅ Issue 2: Real-time Chat UI created"
echo ""

# Issue 3: Offline Message Queue
gh issue create \
  --title "Feature: Offline Message Queue & Sync" \
  --label "enhancement,messaging,offline,phase-1" \
  --body "## 📤 Offline Message Queue & Sync

### Description
Implement robust offline messaging with automatic sync when connection returns.

### Requirements

#### Offline Detection
- [ ] Monitor network connectivity in real-time
- [ ] Use connectivity_plus package
- [ ] Show connection status in UI (banner/snackbar)
- [ ] Debounce connection changes (avoid flicker)

#### Message Queue
- [ ] Queue messages locally when offline
- [ ] Store in Hive/SQLite with retry metadata
- [ ] Show queued messages in chat (with pending indicator)
- [ ] Preserve message order

#### Auto-Sync
- [ ] Detect when connection restored
- [ ] Automatically retry queued messages
- [ ] Update UI with sync progress
- [ ] Handle sync conflicts (timestamp-based resolution)
- [ ] Remove from queue after successful sync

#### Retry Logic
- [ ] Exponential backoff for failed messages
  - 1st retry: Immediately
  - 2nd retry: After 5 seconds
  - 3rd retry: After 30 seconds
  - 4th retry: After 2 minutes
  - 5th retry: Manual retry only
- [ ] Show retry status in message bubble
- [ ] Allow manual retry for failed messages
- [ ] Option to delete failed messages

#### Sync Strategy
\`\`\`dart
// Offline-first approach:
1. Save message to local DB immediately
2. Show message in UI with 'pending' status
3. If online: Send to Supabase
4. On success: Update status to 'sent'
5. If offline: Add to queue
6. When online: Sync queue automatically
\`\`\`

#### Error Handling
- [ ] Handle message too long error
- [ ] Handle invalid attachment error
- [ ] Handle user removed from trip error
- [ ] Handle Supabase quota exceeded
- [ ] Show user-friendly error messages

### Background Sync
- [ ] Use WorkManager for Android background sync
- [ ] Use background_fetch for iOS
- [ ] Sync even when app is closed (if possible)
- [ ] Respect battery/data saving modes

### Acceptance Criteria
- [ ] Messages sent while offline appear in chat
- [ ] Messages auto-sync when connection returns
- [ ] Failed messages show retry button
- [ ] No duplicate messages after sync
- [ ] Works after app restart
- [ ] Handles 100+ queued messages gracefully
- [ ] Battery-efficient (no constant polling)

### Technical Implementation

#### State Management
\`\`\`dart
enum MessageSyncStatus {
  pending,    // Queued, not sent
  syncing,    // Currently uploading
  synced,     // Successfully sent
  failed,     // Failed after retries
}

class QueuedMessage {
  final String localId;  // UUID for local tracking
  final Message message;
  final MessageSyncStatus status;
  final int retryCount;
  final DateTime lastAttempt;
  final String? errorMessage;
}
\`\`\`

### Estimated Time: 3 days

### Files to Create
\`\`\`
lib/features/messaging/data/datasources/message_queue_datasource.dart
lib/features/messaging/domain/services/message_sync_service.dart
lib/features/messaging/presentation/providers/connectivity_provider.dart
lib/features/messaging/presentation/widgets/sync_status_indicator.dart
\`\`\`

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires connectivity_plus: ^6.0.0
- Requires workmanager: ^0.5.0 (Android)
- Requires background_fetch: ^1.0.0 (iOS)
" \
  --assignee "@me"

echo "✅ Issue 3: Offline Message Queue created"
echo ""

# Issue 4: Message Notifications
gh issue create \
  --title "Feature: Message Notifications & Unread Counts" \
  --label "enhancement,messaging,notifications,phase-1" \
  --body "## 🔔 Message Notifications & Unread Counts

### Description
Implement push notifications for new messages and unread message tracking.

### Requirements

#### Unread Counts
- [ ] Track which messages each user has read
- [ ] Store in \`read_by\` JSONB field in messages table
- [ ] Update \`read_by\` when user views message
- [ ] Calculate unread count per trip
- [ ] Show badge on trip card with unread count
- [ ] Show badge on bottom nav Chat icon

#### Mark as Read
- [ ] Auto-mark as read when message is visible on screen
- [ ] Use IntersectionObserver (Flutter: visibility_detector)
- [ ] Debounce read status updates (batch updates)
- [ ] Mark all as read when opening chat
- [ ] Sync read status across devices

#### Push Notifications
- [ ] Send push notification when new message arrives
- [ ] Only if app is in background/closed
- [ ] Only if user has notifications enabled
- [ ] Don't send for own messages
- [ ] Group notifications by trip

#### Notification Content
\`\`\`
Title: [Sender Name] in [Trip Name]
Body: [Message preview - first 100 chars]
Icon: Sender's avatar
Action: Open chat for that trip
\`\`\`

#### Notification Settings
- [ ] Allow users to mute specific trips
- [ ] Allow users to disable all message notifications
- [ ] Allow users to set quiet hours (e.g., 10 PM - 7 AM)
- [ ] Settings UI in Profile → Notifications

#### Database Trigger
\`\`\`sql
-- Supabase Edge Function to send push notifications
CREATE TRIGGER on_message_created
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION send_message_notification();
\`\`\`

#### In-App Notifications
- [ ] Show banner notification when in app (different trip)
- [ ] Play subtle sound (optional, user setting)
- [ ] Vibrate on Android (optional)

### Firebase Cloud Messaging
- [ ] Setup FCM for Android
- [ ] Setup APNs for iOS
- [ ] Store FCM tokens in profiles table
- [ ] Handle token refresh
- [ ] Send notifications via Supabase Edge Function

### Acceptance Criteria
- [ ] Unread counts update in real-time
- [ ] Badge shows on trip card when unread
- [ ] Push notification received when app closed
- [ ] Notification opens correct chat
- [ ] No notification for own messages
- [ ] Muted trips don't send notifications
- [ ] Read status syncs across devices
- [ ] Works offline (updates when sync)

### Estimated Time: 3 days

### Files to Create
\`\`\`
lib/core/services/notification_service.dart
lib/features/messaging/domain/usecases/mark_message_read_usecase.dart
lib/features/messaging/domain/usecases/get_unread_count_usecase.dart
lib/features/messaging/presentation/widgets/unread_badge.dart
supabase/functions/send-message-notification/index.ts
\`\`\`

### SQL Schema Addition
\`\`\`sql
-- Add to profiles table
ALTER TABLE profiles
ADD COLUMN fcm_token TEXT,
ADD COLUMN notification_settings JSONB DEFAULT '{
  \"messages_enabled\": true,
  \"quiet_hours_start\": null,
  \"quiet_hours_end\": null,
  \"muted_trips\": []
}'::jsonb;
\`\`\`

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires firebase_messaging: ^15.0.0
- Requires flutter_local_notifications: ^18.0.0
" \
  --assignee "@me"

echo "✅ Issue 4: Message Notifications created"
echo ""

# Issue 5: Message Attachments
gh issue create \
  --title "Feature: Message Attachments (Images & Location)" \
  --label "enhancement,messaging,attachments,phase-1" \
  --body "## 📎 Message Attachments

### Description
Allow users to send images and location in trip chat.

### Requirements

#### Image Attachments
- [ ] Pick image from gallery
- [ ] Capture photo from camera
- [ ] Compress images before upload (max 2MB)
- [ ] Upload to Supabase Storage
- [ ] Generate thumbnail (200x200)
- [ ] Show image preview in chat bubble
- [ ] Full-screen image viewer on tap
- [ ] Support multiple images in one message (up to 5)

#### Location Sharing
- [ ] Share current location
- [ ] Show location on map in chat bubble
- [ ] Tap to open full map view
- [ ] Include address/place name if available
- [ ] Show distance from user's current location

#### Upload Progress
- [ ] Show upload progress bar
- [ ] Allow canceling upload
- [ ] Queue uploads when offline
- [ ] Retry failed uploads

#### Storage Organization
\`\`\`
Supabase Storage Structure:
/messages
  /[trip_id]
    /images
      /[message_id]_original.jpg
      /[message_id]_thumb.jpg
    /locations
      /[message_id]_map.png  (optional static map)
\`\`\`

#### Image Optimization
- [ ] Resize images to max 1920x1080
- [ ] Compress to 85% quality
- [ ] Convert HEIC to JPEG
- [ ] Strip EXIF data (privacy)
- [ ] Generate blur hash for progressive loading

#### Security
- [ ] Validate file type (only images)
- [ ] Check file size (max 10MB original)
- [ ] Scan for malware (if using Supabase Edge Functions)
- [ ] Set proper RLS policies on storage bucket

### UI Components

#### Attachment Picker
- [ ] Bottom sheet with options:
  - 📷 Camera
  - 🖼️ Gallery
  - 📍 Location
  - ❌ Cancel
- [ ] Preview selected images before sending
- [ ] Add caption to images

#### Image Message Bubble
- [ ] Show thumbnail in bubble
- [ ] Lazy load images
- [ ] Blur hash while loading
- [ ] Download indicator
- [ ] Retry download on failure

#### Location Message Bubble
- [ ] Show static map preview
- [ ] Display address text
- [ ] \"View on Map\" button
- [ ] Distance from current location

### Acceptance Criteria
- [ ] Images upload successfully
- [ ] Images display in chat
- [ ] Full-screen viewer works
- [ ] Location sharing works
- [ ] Offline queue supports attachments
- [ ] Upload progress shown
- [ ] Images compressed appropriately
- [ ] No privacy leaks (EXIF stripped)

### Estimated Time: 4 days

### Files to Create
\`\`\`
lib/features/messaging/domain/services/image_upload_service.dart
lib/features/messaging/presentation/widgets/image_picker_sheet.dart
lib/features/messaging/presentation/widgets/image_message_bubble.dart
lib/features/messaging/presentation/widgets/location_message_bubble.dart
lib/features/messaging/presentation/pages/image_viewer_page.dart
\`\`\`

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires image_picker: ^1.0.0
- Requires image: ^4.0.0 (compression)
- Requires geolocator: ^13.0.0
- Requires google_maps_flutter: ^2.0.0
" \
  --assignee "@me"

echo "✅ Issue 5: Message Attachments created"
echo ""

# Issue 6: Message Reactions & Threading
gh issue create \
  --title "Feature: Message Reactions & Threaded Replies" \
  --label "enhancement,messaging,interactions,phase-1" \
  --body "## 🎭 Message Reactions & Threaded Replies

### Description
Add emoji reactions and threaded replies to make conversations more engaging and organized.

### Requirements

#### Quick Reactions
- [ ] Long-press message to show reaction picker
- [ ] Common reactions: 👍 ❤️ 😂 😮 😢 🎉
- [ ] Show reactions below message bubble
- [ ] Stack reactions (e.g., \"👍 3\")
- [ ] Tap reaction to add/remove your reaction
- [ ] Show who reacted (tooltip or bottom sheet)

#### Data Model
\`\`\`sql
-- Add to messages table
ALTER TABLE messages
ADD COLUMN reactions JSONB DEFAULT '[]'::jsonb;

-- Structure:
{
  \"reactions\": [
    {\"emoji\": \"👍\", \"user_id\": \"...\", \"created_at\": \"...\"},
    {\"emoji\": \"❤️\", \"user_id\": \"...\", \"created_at\": \"...\"}
  ]
}
\`\`\`

#### Threaded Replies
- [ ] Swipe right on message to reply
- [ ] Show original message preview in input area
- [ ] Link reply to parent message (\`reply_to_id\`)
- [ ] Show reply indicator on parent message
- [ ] Tap reply indicator to jump to parent
- [ ] Indent threaded messages slightly

#### Reply UI
\`\`\`
┌─────────────────────────────┐
│ Original Message            │
│ \"When are we leaving?\"      │
│   ↓ 2 replies               │  ← Tap to expand thread
└─────────────────────────────┘

Expanded:
┌─────────────────────────────┐
│ Original Message            │
│ \"When are we leaving?\"      │
│   ├─ \"8 AM tomorrow\"        │
│   └─ \"Don't be late!\"       │
└─────────────────────────────┘
\`\`\`

#### Interaction Features
- [ ] Double-tap message to quick-react with ❤️
- [ ] Shake device to send random reaction (fun!)
- [ ] Animate reactions when added
- [ ] Haptic feedback on interactions

### Real-time Updates
- [ ] Reactions appear instantly via Realtime
- [ ] Update reaction counts in real-time
- [ ] Show \"User is replying...\" for threads

### Acceptance Criteria
- [ ] Reactions work on all message types
- [ ] Threaded replies maintain conversation context
- [ ] Real-time reaction updates
- [ ] UI animations are smooth
- [ ] Works offline (sync when online)
- [ ] Can remove own reactions
- [ ] Reaction limit per user per message (1 type)

### Estimated Time: 3 days

### Files to Create
\`\`\`
lib/features/messaging/presentation/widgets/reaction_picker.dart
lib/features/messaging/presentation/widgets/reaction_counter.dart
lib/features/messaging/presentation/widgets/reply_indicator.dart
lib/features/messaging/presentation/widgets/threaded_message.dart
lib/features/messaging/domain/usecases/add_reaction_usecase.dart
lib/features/messaging/domain/usecases/remove_reaction_usecase.dart
\`\`\`

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires Issue #2 (Real-time Chat UI)
" \
  --assignee "@me"

echo "✅ Issue 6: Message Reactions & Threading created"
echo ""

# Issue 7: Bluetooth Low Energy P2P Messaging
gh issue create \
  --title "Feature: Bluetooth Low Energy (BLE) Peer-to-Peer Messaging" \
  --label "enhancement,messaging,offline,bluetooth,phase-1" \
  --body "## 📶 Bluetooth Low Energy P2P Messaging

### Description
Enable true offline messaging between devices using Bluetooth Low Energy when internet is unavailable. Messages automatically sync to Supabase when connection is restored.

### User Story
> As a user traveling in remote areas without internet, I want to send messages to my trip crew members using Bluetooth so we can stay coordinated even completely offline.

### Requirements

#### Device Discovery
- [ ] Advertise device presence via BLE advertising
- [ ] Scan for nearby trip crew members
- [ ] Filter by trip ID (only discover members of same trip)
- [ ] Show \"Nearby\" indicator on crew member avatars
- [ ] Auto-connect to discovered devices
- [ ] Handle multiple simultaneous connections

#### BLE Communication
- [ ] Use GATT server/client architecture
- [ ] Create custom service UUID for Travel Crew
- [ ] Characteristics for:
  - Message exchange (write)
  - Message acknowledgment (notify)
  - User profile info (read)
  - Trip membership verification (read)
- [ ] Maximum message size: 512 bytes per characteristic
- [ ] Chunk larger messages across multiple writes

#### Message Flow (BLE)
\`\`\`
Device A (Sender):
1. Compose message in UI
2. Save to local queue with 'ble_pending' status
3. Scan for nearby crew members
4. Connect to Device B via BLE
5. Verify trip membership
6. Send message via GATT write
7. Wait for acknowledgment
8. Mark as 'ble_sent'
9. When internet available: Sync to Supabase

Device B (Receiver):
1. BLE advertising enabled
2. Accept connection from Device A
3. Verify trip membership
4. Receive message via GATT characteristic
5. Send acknowledgment
6. Save to local DB with 'ble_received' status
7. Show notification to user
8. Display in chat UI
9. When internet available: Sync to Supabase
\`\`\`

#### Mesh Networking (Bonus)
- [ ] Message relay through intermediate devices
- [ ] Device A → Device B → Device C
- [ ] TTL (Time To Live) to prevent infinite loops
- [ ] Duplicate detection via message ID
- [ ] Route discovery algorithm
- [ ] Store-and-forward for offline users

#### Data Model Updates
\`\`\`sql
-- Add to message_queue table
ALTER TABLE message_queue
ADD COLUMN transmission_method VARCHAR(20) DEFAULT 'internet',
  -- Values: 'internet', 'bluetooth', 'wifi_direct', 'relay'
ADD COLUMN relay_path JSONB DEFAULT '[]'::jsonb,
  -- Track which devices relayed this message
ADD COLUMN ble_metadata JSONB DEFAULT '{}'::jsonb;
  -- Store BLE-specific data (rssi, device_name, etc.)
\`\`\`

#### Security
- [ ] Encrypt messages before BLE transmission
- [ ] Use trip-specific encryption key
- [ ] Verify sender's identity (user_id check)
- [ ] Prevent message tampering (HMAC)
- [ ] Rate limiting (prevent spam)

#### Battery Optimization
- [ ] Only advertise when chat screen is open
- [ ] Stop advertising after 15 minutes of inactivity
- [ ] Use low-power BLE mode
- [ ] Background scanning with intervals (30s on, 5min off)
- [ ] User setting to disable BLE messaging

#### UI Indicators
- [ ] \"Nearby\" badge on crew member avatars
- [ ] BLE connection status icon in chat header
- [ ] \"Sent via Bluetooth\" indicator on message bubbles
- [ ] \"Waiting to sync to cloud\" status for BLE messages
- [ ] List of nearby devices in chat menu

### Acceptance Criteria
- [ ] Messages sent via BLE when no internet
- [ ] BLE messages appear in chat instantly on receiver
- [ ] Auto-sync to Supabase when internet returns
- [ ] No duplicate messages after sync
- [ ] Works with up to 5 simultaneous connections
- [ ] Battery drain < 5% per hour with active BLE
- [ ] Messages encrypted end-to-end
- [ ] Mesh relay works through 3+ hops

### Technical Implementation

#### BLE Service Structure
\`\`\`
Travel Crew BLE Service
UUID: 0000TCMSG-0000-1000-8000-00805F9B34FB

Characteristics:
├─ MESSAGE_TX (Write, Notify)
│  └─ Send/receive message data
├─ MESSAGE_ACK (Read, Notify)
│  └─ Acknowledgment and delivery status
├─ USER_INFO (Read)
│  └─ User ID, name, avatar hash
├─ TRIP_VERIFY (Read, Write)
│  └─ Verify both users are in same trip
└─ RSSI_MONITOR (Notify)
   └─ Signal strength for proximity detection
\`\`\`

#### Packages Required
- \`flutter_blue_plus: ^1.32.0\` - BLE functionality
- \`nearby_connections: ^3.0.0\` - Fallback for Android P2P
- \`pointycastle: ^3.7.0\` - Message encryption

### Estimated Time: 5 days

### Files to Create
\`\`\`
lib/core/services/ble_service.dart
lib/features/messaging/data/datasources/ble_message_datasource.dart
lib/features/messaging/domain/services/ble_discovery_service.dart
lib/features/messaging/domain/services/ble_encryption_service.dart
lib/features/messaging/presentation/providers/ble_connection_provider.dart
lib/features/messaging/presentation/widgets/nearby_devices_indicator.dart
lib/features/messaging/presentation/widgets/ble_status_icon.dart
\`\`\`

### Testing Checklist
- [ ] Test with 2 devices (iPhone + Android)
- [ ] Test message sending both directions
- [ ] Test with internet disabled on both devices
- [ ] Test auto-sync when internet returns
- [ ] Test connection/disconnection handling
- [ ] Test with multiple trips (no cross-trip leakage)
- [ ] Test battery usage over 1 hour
- [ ] Test in airplane mode
- [ ] Test relay through 3 devices

### Platform Considerations

#### Android
- BLE permissions: \`BLUETOOTH_SCAN\`, \`BLUETOOTH_CONNECT\`, \`BLUETOOTH_ADVERTISE\`
- Location permission required for BLE scanning (Android < 12)
- Background scanning limited on Android 12+

#### iOS
- BLE permissions in Info.plist: \`NSBluetoothAlwaysUsageDescription\`
- Background modes: \`bluetooth-central\`, \`bluetooth-peripheral\`
- CoreBluetooth restrictions in background

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires Issue #3 (Offline Message Queue)
- Works alongside internet-based messaging

### User Documentation
- [ ] Create guide: \"How to Use Offline Messaging\"
- [ ] Explain when to enable Bluetooth
- [ ] Battery impact information
- [ ] Privacy considerations
" \
  --assignee "@me"

echo "✅ Issue 7: Bluetooth Low Energy P2P Messaging created"
echo ""

# Issue 8: WiFi Direct P2P Messaging
gh issue create \
  --title "Feature: WiFi Direct Peer-to-Peer Messaging" \
  --label "enhancement,messaging,offline,wifi,phase-1" \
  --body "## 📡 WiFi Direct P2P Messaging

### Description
Enable high-bandwidth offline messaging using WiFi Direct (Android) and Multipeer Connectivity (iOS) for fast, reliable communication without internet.

### User Story
> As a user in a location with no internet but WiFi enabled, I want to send messages (including photos) to nearby crew members using WiFi Direct for faster and more reliable offline messaging than Bluetooth.

### Requirements

#### WiFi Direct (Android)
- [ ] Discover nearby devices using WiFi Direct
- [ ] Create WiFi Direct group (one device as group owner)
- [ ] Establish socket connection between devices
- [ ] Transfer messages over TCP/UDP sockets
- [ ] Support up to 8 connected devices simultaneously
- [ ] Auto-reconnect on connection loss

#### Multipeer Connectivity (iOS)
- [ ] Use MCNearbyServiceAdvertiser for device discovery
- [ ] Use MCNearbyServiceBrowser for peer discovery
- [ ] Establish MCSession between devices
- [ ] Send messages via MCSession data streams
- [ ] Support up to 8 simultaneous peers
- [ ] Handle peer state changes

#### Unified API (Cross-Platform)
\`\`\`dart
abstract class P2PService {
  // Discovery
  Future<void> startAdvertising(String tripId);
  Future<void> startBrowsing(String tripId);
  Stream<P2PDevice> get discoveredDevices;

  // Connection
  Future<void> connectToDevice(P2PDevice device);
  Future<void> disconnectFromDevice(P2PDevice device);
  Stream<P2PConnectionState> get connectionState;

  // Messaging
  Future<void> sendMessage(P2PMessage message, P2PDevice device);
  Stream<P2PMessage> get receivedMessages;

  // Stop
  Future<void> stopAll();
}
\`\`\`

#### Message Transfer Protocol
\`\`\`json
{
  \"protocol_version\": \"1.0\",
  \"message_type\": \"chat_message\",
  \"payload\": {
    \"message_id\": \"uuid\",
    \"trip_id\": \"uuid\",
    \"sender_id\": \"uuid\",
    \"sender_name\": \"John Doe\",
    \"message_text\": \"Hey, where are you?\",
    \"attachments\": [],
    \"timestamp\": \"2025-01-20T10:30:00Z\",
    \"encryption\": {
      \"algorithm\": \"AES-256-GCM\",
      \"iv\": \"...\",
      \"auth_tag\": \"...\"
    }
  },
  \"checksum\": \"sha256_hash\"
}
\`\`\`

#### Features

**High Bandwidth Support**
- [ ] Transfer images up to 10MB
- [ ] Transfer multiple images in one message
- [ ] Progress indicator for large transfers
- [ ] Pause/resume transfers
- [ ] Cancel in-progress transfers

**Group Messaging**
- [ ] Broadcast message to all connected devices
- [ ] One-to-one private messages
- [ ] Group owner acts as message relay
- [ ] Ensure all devices receive messages

**Fallback Strategy**
\`\`\`
Priority order:
1. WiFi Direct (if available, fastest)
2. Bluetooth LE (if WiFi fails, medium speed)
3. Internet (if online, reliable)

Auto-select best available method
\`\`\`

#### Connection Management
- [ ] Auto-detect best device to be group owner (most battery, best signal)
- [ ] Handle group owner migration on disconnect
- [ ] Maintain connection list in local DB
- [ ] Auto-reconnect to known devices
- [ ] Connection timeout: 30 seconds
- [ ] Keep-alive pings every 15 seconds

#### UI Components

**WiFi Status Indicator**
\`\`\`
┌────────────────────────────────┐
│  Chat: Bali Trip 2025          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  📡 WiFi Direct: 3 devices      │  ← Status bar
│     • John (Group Owner)        │
│     • Sarah                     │
│     • Mike                      │
└────────────────────────────────┘
\`\`\`

**Connection Settings**
- [ ] Enable/disable WiFi Direct
- [ ] Set device name
- [ ] Auto-accept connections from trip members
- [ ] Require approval for new connections

#### Security
- [ ] WPA2 encryption for WiFi Direct connection
- [ ] End-to-end message encryption (AES-256)
- [ ] Trip membership verification before accepting messages
- [ ] Message signature verification (prevent spoofing)
- [ ] Automatic disconnection on trip leave

#### Platform Permissions

**Android**
\`\`\`xml
<uses-permission android:name=\"android.permission.ACCESS_WIFI_STATE\" />
<uses-permission android:name=\"android.permission.CHANGE_WIFI_STATE\" />
<uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\" />
<uses-permission android:name=\"android.permission.NEARBY_WIFI_DEVICES\" />
\`\`\`

**iOS**
\`\`\`xml
<key>NSLocalNetworkUsageDescription</key>
<string>Find nearby crew members for offline messaging</string>
<key>NSBonjourServices</key>
<array>
  <string>_travelcrew._tcp</string>
</array>
\`\`\`

### Acceptance Criteria
- [ ] WiFi Direct works on Android 4.0+
- [ ] Multipeer Connectivity works on iOS 7.0+
- [ ] Messages sent at 5MB/s+ (way faster than BLE)
- [ ] Images transfer successfully
- [ ] Group messaging works with 8 devices
- [ ] Auto-sync to Supabase when internet returns
- [ ] Graceful fallback to Bluetooth if WiFi fails
- [ ] Battery usage < 8% per hour
- [ ] No duplicate messages

### Technical Implementation

#### Android (WiFi Direct)
\`\`\`kotlin
// Platform channel implementation
class WiFiDirectPlugin {
  private val wifiP2pManager: WifiP2pManager
  private val channel: WifiP2pManager.Channel

  fun startDiscovery()
  fun createGroup()
  fun connectToDevice(device: WifiP2pDevice)
  fun sendMessage(data: ByteArray)
}
\`\`\`

#### iOS (Multipeer Connectivity)
\`\`\`swift
// Platform channel implementation
class MultipeerPlugin {
  private var session: MCSession
  private var advertiser: MCNearbyServiceAdvertiser
  private var browser: MCNearbyServiceBrowser

  func startAdvertising()
  func startBrowsing()
  func sendMessage(data: Data, to peer: MCPeerID)
}
\`\`\`

### Estimated Time: 5 days

### Files to Create
\`\`\`
lib/core/services/p2p_service.dart
lib/core/services/wifi_direct_service.dart  (Android wrapper)
lib/core/services/multipeer_service.dart  (iOS wrapper)
lib/features/messaging/data/datasources/wifi_message_datasource.dart
lib/features/messaging/domain/services/p2p_encryption_service.dart
lib/features/messaging/presentation/providers/wifi_connection_provider.dart
lib/features/messaging/presentation/widgets/p2p_connection_status.dart
lib/features/messaging/presentation/pages/p2p_devices_page.dart
android/app/src/main/kotlin/com/example/travelcrew/WiFiDirectPlugin.kt
ios/Runner/MultipeerPlugin.swift
\`\`\`

### Packages Required
- \`nearby_connections: ^3.0.0\` - Android WiFi Direct
- \`flutter_nearby_connections: ^1.1.0\` - Cross-platform P2P
- Native platform channels for fine-grained control

### Testing Checklist
- [ ] Test on 2+ Android devices
- [ ] Test on 2+ iOS devices
- [ ] Test cross-platform (Android ↔ iOS via fallback to BLE)
- [ ] Test image transfer (10MB file)
- [ ] Test group messaging (8 devices)
- [ ] Test connection loss recovery
- [ ] Test battery usage over 1 hour
- [ ] Test sync to Supabase after reconnection
- [ ] Test fallback to Bluetooth

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires Issue #3 (Offline Message Queue)
- Requires Issue #7 (BLE Messaging for iOS ↔ Android)
- Works alongside internet-based messaging

### User Documentation
- [ ] \"WiFi Direct vs Bluetooth\" comparison guide
- [ ] When to use which offline method
- [ ] Troubleshooting connection issues
- [ ] Battery optimization tips
" \
  --assignee "@me"

echo "✅ Issue 8: WiFi Direct P2P Messaging created"
echo ""

# Issue 9: Hybrid Sync Strategy & Conflict Resolution
gh issue create \
  --title "Feature: Hybrid Sync Strategy for Multi-Channel Messaging" \
  --label "enhancement,messaging,offline,sync,phase-1" \
  --body "## 🔄 Hybrid Sync Strategy & Conflict Resolution

### Description
Implement intelligent message synchronization across multiple transmission methods (Internet, Bluetooth, WiFi Direct) with conflict resolution and deduplication.

### User Story
> As a user who receives messages through multiple channels (BLE, WiFi, Internet), I want the app to intelligently merge and deduplicate messages so I see a clean, unified conversation without duplicates or conflicts.

### Problem Statement

**Scenario**: User A sends a message to User B

1. Message sent via Bluetooth at 10:00 AM (no internet)
2. User B receives via Bluetooth, displays in chat
3. At 10:15 AM, internet comes back
4. Message syncs to Supabase from User A
5. User B receives same message again via Realtime subscription
6. **Result**: Duplicate message in chat ❌

**Solution**: Intelligent deduplication and sync strategy ✅

### Requirements

#### Message Deduplication
- [ ] Assign unique \`message_id\` (UUID) at creation
- [ ] Track message by ID across all channels
- [ ] Detect duplicates before inserting to local DB
- [ ] Update transmission method if received via different channel
- [ ] Merge metadata from multiple sources

\`\`\`dart
class MessageDeduplicator {
  // Check if message already exists locally
  Future<bool> isDuplicate(String messageId);

  // Merge message received from multiple channels
  Future<Message> mergeMessage(Message existing, Message incoming);

  // Update sync status
  Future<void> updateSyncStatus(String messageId, SyncStatus status);
}
\`\`\`

#### Priority-Based Sync
\`\`\`
Transmission Method Priority:
1. Internet (Supabase) - Most reliable, permanent storage
2. WiFi Direct - Fast, high bandwidth
3. Bluetooth LE - Slow, low bandwidth

Sync Strategy:
- If online: Always prefer Supabase
- If offline: Try WiFi Direct → Bluetooth LE
- When switching online: Sync all pending messages
- Mark method used in message metadata
\`\`\`

#### Conflict Resolution

**Timestamp Conflict**
\`\`\`
Scenario: Message created at different times on different devices due to clock skew

Resolution:
1. Use Supabase server timestamp as source of truth
2. When syncing to cloud, update local timestamp
3. Re-sort chat messages after sync
4. Maintain original \`client_created_at\` for debugging
\`\`\`

**Content Conflict** (Edit/Delete)
\`\`\`
Scenario: User edits message offline, but it was deleted by sender online

Resolution:
1. Last-write-wins based on server timestamp
2. Store conflict history for debugging
3. Notify user if their edit was overwritten
4. Allow manual conflict resolution in settings
\`\`\`

**Read Status Conflict**
\`\`\`
Scenario: Message marked as read on Device A (offline), unread on Device B (online)

Resolution:
1. Merge read_by arrays from all sources
2. If user_id appears in any read_by, consider it read
3. Never unmark a message as read
4. Sync read status to all devices via Realtime
\`\`\`

#### Sync Flow

**Sending a Message**
\`\`\`dart
Future<void> sendMessage(Message message) async {
  // 1. Generate unique ID
  message.id = uuid.v4();

  // 2. Save to local DB immediately
  await localDB.insertMessage(message);

  // 3. Show in UI instantly
  emit(MessageSent(message));

  // 4. Try to sync via best available method
  if (await isOnline()) {
    await syncViaInternet(message);
  } else if (await isWiFiDirectAvailable()) {
    await syncViaWiFiDirect(message);
    queueForInternetSync(message);  // Still queue for cloud
  } else if (await isBluetoothAvailable()) {
    await syncViaBluetooth(message);
    queueForInternetSync(message);  // Still queue for cloud
  } else {
    queueForInternetSync(message);  // Queue only
  }

  // 5. When internet returns, sync to Supabase
  listenForConnectivity(message);
}
\`\`\`

**Receiving a Message**
\`\`\`dart
Future<void> onMessageReceived(Message message, TransmissionMethod method) async {
  // 1. Check if duplicate
  if (await deduplicator.isDuplicate(message.id)) {
    final existing = await localDB.getMessage(message.id);

    // 2. Merge metadata
    final merged = await deduplicator.mergeMessage(existing, message);
    await localDB.updateMessage(merged);

    // 3. Update UI if needed (e.g., delivery status changed)
    emit(MessageUpdated(merged));

    return;  // Don't show duplicate
  }

  // 4. New message - save and display
  await localDB.insertMessage(message);
  emit(MessageReceived(message));

  // 5. Send acknowledgment via same channel
  await sendAck(message.id, method);
}
\`\`\`

#### Sync Queue Management

**Database Schema**
\`\`\`sql
CREATE TABLE sync_queue (
  id UUID PRIMARY KEY,
  message_id UUID NOT NULL,
  sync_priority INTEGER NOT NULL,  -- 1=high, 2=medium, 3=low
  transmission_methods JSONB NOT NULL,  -- ['internet', 'wifi', 'bluetooth']
  sync_status VARCHAR(20) NOT NULL,  -- pending, syncing, partial, synced, failed
  retry_count INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sync_queue_status ON sync_queue(sync_status, sync_priority);
\`\`\`

**Sync Strategies**
- [ ] **Eager Sync**: Try all available methods simultaneously
- [ ] **Conservative Sync**: Try one method at a time (priority order)
- [ ] **Batch Sync**: Group messages and sync together (efficiency)
- [ ] **Incremental Sync**: Sync oldest messages first
- [ ] **Smart Sync**: Sync high-priority messages first (replies, mentions)

#### Background Sync
- [ ] Use WorkManager (Android) / BackgroundTasks (iOS)
- [ ] Sync every 15 minutes when app is closed
- [ ] Sync immediately when app opens
- [ ] Sync when connectivity changes (WiFi ↔ cellular)
- [ ] Respect battery saver mode (reduce frequency)

#### Delivery Receipts
\`\`\`
Message Status Lifecycle:
1. created → Message created locally
2. pending → Queued for sending
3. sending → Currently transmitting
4. sent_bluetooth → Sent via BLE
5. sent_wifi → Sent via WiFi Direct
6. sent_internet → Sent to Supabase
7. delivered → Received by recipient(s)
8. read → Read by recipient(s)

Show different icons for each status in message bubble
\`\`\`

#### Metrics & Monitoring
- [ ] Track sync success rate per method
- [ ] Track average sync latency
- [ ] Track number of conflicts resolved
- [ ] Track duplicate messages detected
- [ ] Display stats in debug settings

### Acceptance Criteria
- [ ] No duplicate messages in chat UI
- [ ] Messages sync across all channels seamlessly
- [ ] Conflicts resolved automatically (correct message wins)
- [ ] Sync works in background
- [ ] Message order correct after sync (by timestamp)
- [ ] Delivery status accurate
- [ ] Works with 100+ pending messages
- [ ] Battery-efficient (< 3% drain per hour)
- [ ] Handles offline → online → offline transitions

### Technical Implementation

#### Sync Service
\`\`\`dart
class HybridSyncService {
  final MessageDeduplicator deduplicator;
  final SyncQueue syncQueue;
  final ConnectivityMonitor connectivity;

  Future<void> syncMessage(Message message) async {
    // Determine best available method
    final methods = await getAvailableMethods();

    // Try each method in priority order
    for (final method in methods) {
      try {
        await _syncViaMethod(message, method);
        await syncQueue.markSynced(message.id, method);
        return;  // Success
      } catch (e) {
        await syncQueue.markFailed(message.id, method, e);
        // Try next method
      }
    }

    // All methods failed - queue for retry
    await syncQueue.scheduleRetry(message.id);
  }

  Future<void> syncPendingMessages() async {
    final pending = await syncQueue.getPendingMessages();

    for (final message in pending) {
      await syncMessage(message);
    }
  }
}
\`\`\`

### Estimated Time: 4 days

### Files to Create
\`\`\`
lib/features/messaging/domain/services/message_deduplicator.dart
lib/features/messaging/domain/services/hybrid_sync_service.dart
lib/features/messaging/domain/services/conflict_resolver.dart
lib/features/messaging/data/datasources/sync_queue_datasource.dart
lib/features/messaging/presentation/providers/sync_status_provider.dart
lib/features/messaging/presentation/widgets/message_status_icon.dart
lib/features/messaging/presentation/widgets/sync_debug_panel.dart
scripts/database/sync_queue_schema.sql
\`\`\`

### Testing Checklist
- [ ] Test duplicate detection (same message via BLE + Internet)
- [ ] Test sync when switching from offline to online
- [ ] Test conflict resolution (edited message)
- [ ] Test message ordering after sync
- [ ] Test with 100+ queued messages
- [ ] Test background sync (app closed)
- [ ] Test sync across 3 devices simultaneously
- [ ] Test read status sync
- [ ] Test delivery receipt accuracy
- [ ] Load test: 1000 messages syncing

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires Issue #3 (Offline Message Queue)
- Requires Issue #7 (Bluetooth P2P Messaging)
- Requires Issue #8 (WiFi Direct P2P Messaging)

### User Documentation
- [ ] How offline messaging works (transparent to user)
- [ ] Debugging sync issues (developer mode)
- [ ] Privacy: What data is stored locally vs cloud
" \
  --assignee "@me"

echo "✅ Issue 9: Hybrid Sync Strategy & Conflict Resolution created"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All 9 Messaging Module issues created successfully!"
echo ""
echo "📋 Summary:"
echo "  1. Core Messaging Infrastructure (3 days)"
echo "  2. Real-time Chat UI (4 days)"
echo "  3. Offline Message Queue & Sync (3 days)"
echo "  4. Message Notifications (3 days)"
echo "  5. Message Attachments (4 days)"
echo "  6. Message Reactions & Threading (3 days)"
echo "  7. 📶 Bluetooth Low Energy P2P Messaging (5 days)"
echo "  8. 📡 WiFi Direct P2P Messaging (5 days)"
echo "  9. 🔄 Hybrid Sync Strategy & Conflict Resolution (4 days)"
echo ""
echo "⏱️  Total Estimated Time: 34 days (~7 weeks)"
echo ""
echo "🎯 Offline Messaging Features:"
echo "  • Bluetooth LE for device-to-device messaging"
echo "  • WiFi Direct for high-bandwidth P2P (images, files)"
echo "  • Intelligent fallback: WiFi → Bluetooth → Internet"
echo "  • Auto-sync to cloud when connection returns"
echo "  • Mesh networking (message relay through intermediate devices)"
echo "  • Conflict resolution and deduplication"
echo ""
echo "🔗 Next Steps:"
echo "  1. Run this script to create all GitHub issues"
echo "  2. Add issues to 'Travel Crew MVP - 8 Week' project"
echo "  3. Prioritize based on MVP requirements"
echo "  4. Consider: Do you need ALL offline features for Phase 1?"
echo "     - Core messaging (Issues 1-6): Essential"
echo "     - Bluetooth (Issue 7): Nice-to-have for remote areas"
echo "     - WiFi Direct (Issue 8): Advanced, can be Phase 2"
echo "     - Hybrid sync (Issue 9): Required if implementing Issues 7-8"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
