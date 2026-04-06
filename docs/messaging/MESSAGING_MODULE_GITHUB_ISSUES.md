# Messaging Module - GitHub Issues to Create

**Total**: 9 Issues
**Estimated Time**: 34 days (~7 weeks)
**Labels to use**: `enhancement`, `messaging`, `phase-1`, and specific labels per issue

---

## How to Create These Issues

### Option 1: Manual Creation (Recommended)
1. Go to: https://github.com/grayprogrammers008-oss/TravelCompanion/issues
2. Click "New Issue"
3. Copy the title and body from each issue below
4. Add the specified labels
5. Assign to yourself
6. Click "Submit new issue"

### Option 2: Use GitHub CLI (if available)
```bash
cd "d:\Nithya\Travel Companion\TravelCompanion"
bash scripts/create_messaging_issues.sh
```

---

## Issue #1: Core Messaging Infrastructure

**Title**: `Feature: Core Messaging Infrastructure`

**Labels**: `enhancement`, `messaging`, `phase-1`

**Assignee**: @me

**Body**:
```markdown
## 📱 Core Messaging Infrastructure

### Description
Implement the foundational messaging system for Travel Crew with real-time and offline capabilities.

### Requirements

#### Data Model
- [ ] Create `messages` table in Supabase
  - `id` (UUID, primary key)
  - `trip_id` (UUID, foreign key to trips)
  - `sender_id` (UUID, foreign key to profiles)
  - `message` (text, max 2000 chars)
  - `message_type` (enum: text, image, location, expense_link)
  - `reply_to_id` (UUID, nullable, for threaded replies)
  - `attachment_url` (text, nullable)
  - `created_at` (timestamp)
  - `updated_at` (timestamp)
  - `is_deleted` (boolean)
  - `read_by` (jsonb, array of user IDs who read the message)

- [ ] Create `message_queue` table for offline messages
  - `id` (UUID, primary key)
  - `trip_id` (UUID)
  - `sender_id` (UUID)
  - `message_data` (jsonb)
  - `sync_status` (enum: pending, syncing, synced, failed)
  - `retry_count` (integer)
  - `created_at` (timestamp)

#### Database Features
- [ ] Add RLS policies for message access (users can only read messages for trips they're members of)
- [ ] Add indexes for performance (trip_id, created_at)
- [ ] Add trigger for updating `updated_at` timestamp
- [ ] Add trigger for real-time notifications

#### Domain Layer
- [ ] Create `Message` entity with Freezed
- [ ] Create `MessageRepository` interface
- [ ] Create use cases:
  - `SendMessageUseCase`
  - `GetTripMessagesUseCase`
  - `MarkMessageAsReadUseCase`
  - `DeleteMessageUseCase`

#### Data Layer
- [ ] Create `MessageModel` with JSON serialization
- [ ] Implement `MessageRemoteDataSource` (Supabase)
- [ ] Implement `MessageLocalDataSource` (Hive/SQLite for offline)
- [ ] Implement `MessageRepositoryImpl` with offline-first strategy

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
```
lib/shared/models/message_model.dart
lib/features/messaging/domain/entities/message_entity.dart
lib/features/messaging/domain/repositories/message_repository.dart
lib/features/messaging/domain/usecases/send_message_usecase.dart
lib/features/messaging/domain/usecases/get_trip_messages_usecase.dart
lib/features/messaging/data/models/message_model.dart
lib/features/messaging/data/datasources/message_remote_datasource.dart
lib/features/messaging/data/datasources/message_local_datasource.dart
lib/features/messaging/data/repositories/message_repository_impl.dart
```

### SQL Schema
```sql
-- See scripts/database/messaging_schema.sql
```
```

---

## Issue #2: Real-time Chat UI

**Title**: `Feature: Real-time Chat UI for Trips`

**Labels**: `enhancement`, `messaging`, `ui`, `phase-1`

**Assignee**: @me

**Body**:
```markdown
## 💬 Real-time Chat UI

### Description
Create a beautiful, real-time chat interface for trip crew members to communicate.

### Requirements

#### Chat Screen
- [ ] Create `TripChatPage` (full-screen chat)
- [ ] Display messages in chronological order
- [ ] Show sender avatar and name
- [ ] Show timestamp (with smart formatting: "Just now", "5m ago", "Yesterday")
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
- [ ] Show "typing..." indicator when someone is typing
- [ ] Show "online" status for crew members
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
```
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
```

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
```
lib/features/messaging/presentation/pages/trip_chat_page.dart
lib/features/messaging/presentation/widgets/message_bubble.dart
lib/features/messaging/presentation/widgets/message_input.dart
lib/features/messaging/presentation/widgets/typing_indicator.dart
lib/features/messaging/presentation/widgets/date_divider.dart
lib/features/messaging/presentation/widgets/offline_banner.dart
lib/features/messaging/presentation/providers/messaging_providers.dart
```

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires emoji_picker_flutter package
- Requires image_picker package
```

---

## Issue #3: Offline Message Queue & Sync

**Title**: `Feature: Offline Message Queue & Sync`

**Labels**: `enhancement`, `messaging`, `offline`, `phase-1`

**Assignee**: @me

**Body**:
```markdown
## 📤 Offline Message Queue & Sync

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
```dart
// Offline-first approach:
1. Save message to local DB immediately
2. Show message in UI with 'pending' status
3. If online: Send to Supabase
4. On success: Update status to 'sent'
5. If offline: Add to queue
6. When online: Sync queue automatically
```

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
```dart
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
```

### Estimated Time: 3 days

### Files to Create
```
lib/features/messaging/data/datasources/message_queue_datasource.dart
lib/features/messaging/domain/services/message_sync_service.dart
lib/features/messaging/presentation/providers/connectivity_provider.dart
lib/features/messaging/presentation/widgets/sync_status_indicator.dart
```

### Dependencies
- Requires Issue #1 (Core Messaging Infrastructure)
- Requires connectivity_plus: ^6.0.0
- Requires workmanager: ^0.5.0 (Android)
- Requires background_fetch: ^1.0.0 (iOS)
```

---

_Due to character limits, I'll create a summary document with links to create the remaining 6 issues..._

---

## Quick Summary of Remaining Issues

### Issue #4: Message Notifications & Unread Counts (3 days)
- Push notifications via Firebase Cloud Messaging
- Unread count badges on trip cards
- Read receipts and status tracking
- Notification settings (mute trips, quiet hours)

### Issue #5: Message Attachments (Images & Location) (4 days)
- Image upload to Supabase Storage
- Image compression and thumbnails
- Location sharing with map preview
- Full-screen image viewer

### Issue #6: Message Reactions & Threaded Replies (3 days)
- Emoji reactions (👍 ❤️ 😂 😮 😢 🎉)
- Threaded replies (swipe to reply)
- Real-time reaction updates
- Interaction animations

### Issue #7: Bluetooth Low Energy P2P Messaging (5 days)
- Device discovery via BLE advertising
- GATT server/client for message exchange
- Mesh networking (relay messages)
- End-to-end encryption
- Battery optimization

### Issue #8: WiFi Direct P2P Messaging (5 days)
- WiFi Direct (Android) / Multipeer Connectivity (iOS)
- High-bandwidth transfer (images, files)
- Group messaging up to 8 devices
- Auto-fallback to Bluetooth

### Issue #9: Hybrid Sync Strategy & Conflict Resolution (4 days)
- Message deduplication across all channels
- Priority-based sync (Internet > WiFi > Bluetooth)
- Timestamp conflict resolution
- Background sync queue management

---

## Creating All Issues at Once

If you want the complete bodies for issues #4-#9, I can provide them. However, they are VERY long (the script is 1429 lines).

### Recommended Approach:

1. **Start with Issues #1-3** (Core functionality - 10 days)
   - These are essential and give you a working messaging system

2. **Add Issues #4-6** (Enhancements - 10 days)
   - These add polish and features users expect

3. **Consider Issues #7-9** (Offline P2P - 14 days)
   - These are advanced features for offline use cases
   - Can be implemented in Phase 2

---

## Next Steps

1. ✅ Create Issue #1: Core Messaging Infrastructure (copy body above)
2. ✅ Create Issue #2: Real-time Chat UI (copy body above)
3. ✅ Create Issue #3: Offline Message Queue (copy body above)
4. ⏳ Create Issues #4-#9 (I can provide full bodies if needed)
5. 📋 Add all issues to your GitHub Project board
6. 🎯 Prioritize: Start with #1, then #2, then #3...

**Would you like me to provide the full bodies for Issues #4-#9?**
