# 💬 Messaging Module - Complete Design Document

**Status**: Planned for Phase 1
**Estimated Time**: 34 days (~7 weeks)
**Last Updated**: October 21, 2025

---

## 🎯 Overview

The Travel Crew messaging module enables real-time and **offline** communication between trip crew members through multiple channels:

1. **Internet** - Supabase Realtime (primary, most reliable)
2. **WiFi Direct** - High-bandwidth P2P for images/files
3. **Bluetooth LE** - Low-power device-to-device messaging
4. **Hybrid Sync** - Intelligent deduplication and conflict resolution

### Key Differentiator

Unlike most travel apps, Travel Crew works **completely offline** using Bluetooth and WiFi Direct peer-to-peer messaging. Perfect for:
- Remote hiking trips without cell service
- International travel with limited data
- Group coordination in areas with poor connectivity
- Battery-conscious travelers who disable mobile data

---

## 🚀 Features Breakdown

### Core Features (Issues 1-6) - 20 days
**Essential for MVP, internet-based messaging**

#### 1. Core Messaging Infrastructure (3 days)
- Supabase database schema (messages, message_queue tables)
- Domain entities and repository pattern
- Local cache with Hive for offline-first experience
- RLS policies for security

**Key Files**:
- `lib/shared/models/message_model.dart`
- `lib/features/messaging/domain/repositories/message_repository.dart`
- `scripts/database/messaging_schema.sql`

#### 2. Real-time Chat UI (4 days)
- WhatsApp-style message bubbles
- Typing indicators and online status
- Emoji picker and reactions
- Pull-to-refresh for older messages
- Unread message badges

**Key Files**:
- `lib/features/messaging/presentation/pages/trip_chat_page.dart`
- `lib/features/messaging/presentation/widgets/message_bubble.dart`

#### 3. Offline Message Queue & Sync (3 days)
- Queue messages when internet unavailable
- Auto-retry with exponential backoff
- Connectivity monitoring
- Background sync (WorkManager/BackgroundTasks)

**Key Files**:
- `lib/features/messaging/domain/services/message_sync_service.dart`
- `lib/features/messaging/data/datasources/message_queue_datasource.dart`

#### 4. Message Notifications & Unread Counts (3 days)
- Firebase Cloud Messaging integration
- Push notifications (only when app backgrounded)
- Unread count badges on trip cards
- Read receipt tracking

**Key Files**:
- `lib/core/services/notification_service.dart`
- `supabase/functions/send-message-notification/index.ts`

#### 5. Message Attachments (4 days)
- Image upload to Supabase Storage
- Image compression and thumbnails
- Location sharing with map preview
- Full-screen image viewer

**Key Files**:
- `lib/features/messaging/domain/services/image_upload_service.dart`
- `lib/features/messaging/presentation/widgets/image_message_bubble.dart`

#### 6. Message Reactions & Threading (3 days)
- Emoji reactions (👍 ❤️ 😂 😮 😢 🎉)
- Threaded replies (swipe to reply)
- Real-time reaction updates

**Key Files**:
- `lib/features/messaging/presentation/widgets/reaction_picker.dart`
- `lib/features/messaging/presentation/widgets/threaded_message.dart`

---

### Offline P2P Features (Issues 7-9) - 14 days
**Advanced, enables true offline communication**

#### 7. Bluetooth Low Energy P2P Messaging (5 days)
- Device discovery via BLE advertising
- GATT server/client for message exchange
- Mesh networking (relay messages through intermediate devices)
- Trip-based filtering (only discover crew members)
- End-to-end encryption

**Technical Details**:
```dart
// BLE Service UUID
Travel Crew BLE Service: 0000TCMSG-0000-1000-8000-00805F9B34FB

Characteristics:
├─ MESSAGE_TX (Write, Notify) - Send/receive messages
├─ MESSAGE_ACK (Read, Notify) - Delivery acknowledgment
├─ USER_INFO (Read) - User ID and name
└─ TRIP_VERIFY (Read, Write) - Verify trip membership
```

**Battery Impact**: < 5% per hour with active BLE
**Range**: ~10-30 meters
**Speed**: ~1KB/s (text messages only)
**Devices**: Up to 5 simultaneous connections

**Key Files**:
- `lib/core/services/ble_service.dart`
- `lib/features/messaging/data/datasources/ble_message_datasource.dart`
- `lib/features/messaging/domain/services/ble_encryption_service.dart`

**Packages**:
- `flutter_blue_plus: ^1.32.0`
- `nearby_connections: ^3.0.0`

#### 8. WiFi Direct P2P Messaging (5 days)
- WiFi Direct (Android) / Multipeer Connectivity (iOS)
- High-bandwidth transfer (5MB/s+)
- Group owner auto-selection
- Image and file sharing support
- TCP/UDP socket connections

**Technical Details**:
```dart
// Message Transfer Protocol
{
  "protocol_version": "1.0",
  "message_type": "chat_message",
  "payload": {
    "message_id": "uuid",
    "trip_id": "uuid",
    "message_text": "Hello!",
    "attachments": [],
    "encryption": { "algorithm": "AES-256-GCM" }
  }
}
```

**Battery Impact**: < 8% per hour
**Range**: ~50-100 meters
**Speed**: ~5MB/s (supports images/files)
**Devices**: Up to 8 simultaneous connections

**Key Files**:
- `lib/core/services/wifi_direct_service.dart` (Android)
- `lib/core/services/multipeer_service.dart` (iOS)
- `android/app/src/main/kotlin/WiFiDirectPlugin.kt`
- `ios/Runner/MultipeerPlugin.swift`

**Packages**:
- `nearby_connections: ^3.0.0`
- Native platform channels

#### 9. Hybrid Sync Strategy & Conflict Resolution (4 days)
- Message deduplication across all channels
- Priority-based sync (Internet > WiFi > Bluetooth)
- Timestamp conflict resolution
- Merge read receipts from multiple sources
- Background sync queue management

**Sync Flow**:
```
Sending Priority:
1. If online → Supabase (fastest, permanent)
2. If WiFi available → WiFi Direct to nearby devices
3. If Bluetooth available → BLE to nearby devices
4. Queue for later sync

Always queue offline messages for cloud sync when internet returns
```

**Deduplication**:
- Unique message ID assigned at creation
- Track message across all transmission methods
- Merge metadata when duplicate detected
- Update UI only if delivery status changes

**Key Files**:
- `lib/features/messaging/domain/services/message_deduplicator.dart`
- `lib/features/messaging/domain/services/hybrid_sync_service.dart`
- `lib/features/messaging/data/datasources/sync_queue_datasource.dart`

---

## 📊 Database Schema

### `messages` Table
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  trip_id UUID REFERENCES trips(id),
  sender_id UUID REFERENCES profiles(id),
  message TEXT CHECK (LENGTH(message) <= 2000),
  message_type VARCHAR(20) DEFAULT 'text',  -- text, image, location, expense_link
  reply_to_id UUID REFERENCES messages(id),
  attachment_url TEXT,
  reactions JSONB DEFAULT '[]'::jsonb,
  read_by JSONB DEFAULT '[]'::jsonb,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_messages_trip ON messages(trip_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);

-- RLS Policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read messages for their trips"
  ON messages FOR SELECT
  USING (trip_id IN (SELECT trip_id FROM trip_members WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert messages for their trips"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    trip_id IN (SELECT trip_id FROM trip_members WHERE user_id = auth.uid())
  );
```

### `message_queue` Table (Offline Messages)
```sql
CREATE TABLE message_queue (
  id UUID PRIMARY KEY,
  trip_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  message_data JSONB NOT NULL,
  transmission_method VARCHAR(20) DEFAULT 'internet',  -- internet, bluetooth, wifi_direct, relay
  relay_path JSONB DEFAULT '[]'::jsonb,
  sync_status VARCHAR(20) NOT NULL,  -- pending, syncing, synced, failed
  retry_count INTEGER DEFAULT 0,
  last_attempt_at TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_queue_status ON message_queue(sync_status, created_at);
```

### `sync_queue` Table (Hybrid Sync)
```sql
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
```

---

## 🔐 Security

### Encryption
- **Internet**: HTTPS + Supabase TLS
- **WiFi Direct**: WPA2 + AES-256-GCM message encryption
- **Bluetooth**: AES-256-GCM message encryption

### Authentication
- Trip membership verification before message exchange
- User ID validation via Supabase Auth
- Message signing to prevent spoofing

### Privacy
- Strip EXIF data from images
- End-to-end encryption for P2P messages
- Local storage encrypted (Hive secure box)

---

## 🎨 UI/UX Design

### Message Bubble Design
```
┌────────────────────────────────────┐
│  Own Messages:                     │
│                                    │
│                    ┌──────────────┐│
│                    │ Hey! Where   ││
│                    │ are you?     ││
│                    └──────────────┘│
│                    10:30 AM  ✓✓   │
│                                    │
│  Others' Messages:                 │
│  👤                                │
│  ┌──────────────┐                 │
│  │ Near the     │                 │
│  │ hotel        │                 │
│  └──────────────┘                 │
│  Sarah • 10:32 AM                 │
└────────────────────────────────────┘
```

### Connection Status Indicators
```
Online Mode:
🌐 Connected to internet

WiFi Direct Mode:
📡 WiFi Direct: 3 nearby devices

Bluetooth Mode:
📶 Bluetooth: 2 nearby devices

Offline Mode:
⚠️ Offline - Messages will send when online
```

### Message Status Icons
- ⏳ **Pending** - Queued for sending
- ✈️ **Sending** - Currently transmitting
- 📶 **Sent via BLE** - Delivered via Bluetooth
- 📡 **Sent via WiFi** - Delivered via WiFi Direct
- ✓ **Sent** - Delivered to server
- ✓✓ **Delivered** - Received by recipient
- 💙 **Read** - Read by recipient

---

## 📱 Platform Support

| Feature | Android | iOS | Web |
|---------|---------|-----|-----|
| Internet Messaging | ✅ | ✅ | ✅ |
| Offline Queue | ✅ | ✅ | ✅ |
| Push Notifications | ✅ | ✅ | ❌ |
| Image Attachments | ✅ | ✅ | ✅ |
| Bluetooth LE | ✅ | ✅ | ❌ |
| WiFi Direct | ✅ | ✅ (Multipeer) | ❌ |
| Background Sync | ✅ | ⚠️ (limited) | ❌ |

---

## 🧪 Testing Strategy

### Unit Tests
- Message repository (CRUD operations)
- Deduplication logic
- Conflict resolution algorithms
- Encryption/decryption

### Integration Tests
- Message sending flow (all channels)
- Offline queue sync
- Read receipt updates
- Notification delivery

### Device Tests
- 2 Android devices (BLE + WiFi Direct)
- 2 iOS devices (BLE + Multipeer)
- Cross-platform (Android ↔ iOS via BLE)
- Mesh relay (3+ devices)

### Load Tests
- 1000 messages sync performance
- 100+ queued messages
- 8 simultaneous connections
- Battery drain over 1 hour

---

## 📈 Performance Targets

| Metric | Target |
|--------|--------|
| Message delivery (online) | < 1 second |
| Message delivery (BLE) | < 5 seconds |
| Message delivery (WiFi) | < 2 seconds |
| Image upload (10MB) | < 30 seconds |
| Battery drain (BLE active) | < 5% per hour |
| Battery drain (WiFi active) | < 8% per hour |
| Background sync frequency | Every 15 minutes |
| Max queued messages | 1000 |

---

## 🎯 MVP Recommendation

### Phase 1A (Essential - 20 days)
**Internet-based messaging only**
- ✅ Issues 1-6 (Core messaging, UI, notifications, attachments)
- Provides full chat functionality for most use cases
- Works anywhere with internet connection

### Phase 1B (Advanced - 14 days)
**Add offline P2P capabilities**
- ✅ Issues 7-9 (Bluetooth, WiFi, Hybrid Sync)
- Differentiates from competitors
- Critical for remote/adventure travelers

### Phase 2 (Polish)
- Message search
- Message editing/deletion
- Voice messages
- Video attachments
- Message translation
- Message pinning

---

## 📦 Dependencies

### Flutter Packages
```yaml
dependencies:
  # Core messaging
  supabase_flutter: ^2.0.0
  hive: ^2.2.0
  hive_flutter: ^1.1.0

  # Real-time & notifications
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^18.0.0

  # Attachments
  image_picker: ^1.0.0
  image: ^4.0.0
  geolocator: ^13.0.0
  google_maps_flutter: ^2.0.0

  # Offline P2P (Issues 7-8)
  flutter_blue_plus: ^1.32.0  # Bluetooth LE
  nearby_connections: ^3.0.0  # WiFi Direct (Android)

  # Utilities
  connectivity_plus: ^6.0.0
  workmanager: ^0.5.0  # Android background sync
  background_fetch: ^1.0.0  # iOS background sync
  pointycastle: ^3.7.0  # Encryption
  emoji_picker_flutter: ^2.0.0
```

---

## 🚀 Implementation Order

1. **Week 1-2**: Issues 1-3 (Infrastructure, UI, Offline Queue)
2. **Week 2-3**: Issues 4-6 (Notifications, Attachments, Reactions)
3. **Week 4**: Issue 7 (Bluetooth P2P)
4. **Week 5**: Issue 8 (WiFi Direct P2P)
5. **Week 6**: Issue 9 (Hybrid Sync)
6. **Week 7**: Testing, bug fixes, polish

---

## 📝 GitHub Issues

All 9 issues are ready to be created via:
```bash
./scripts/create_messaging_issues.sh
```

This will create issues with:
- Detailed requirements and acceptance criteria
- Technical implementation details
- Estimated time
- Files to create
- Testing checklists
- Dependencies

---

## 🎊 Success Criteria

The messaging module is complete when:

✅ Users can send/receive messages in real-time
✅ Messages work offline with auto-sync
✅ Images and locations can be shared
✅ Push notifications work reliably
✅ Bluetooth messaging works between nearby devices
✅ WiFi Direct enables fast image sharing
✅ No duplicate messages appear in UI
✅ Battery usage is acceptable (< 8% per hour)
✅ Works on Android and iOS
✅ All tests pass with 80%+ coverage

---

**Ready to implement?** Run the script to create all GitHub issues and add them to your project board! 🚀
