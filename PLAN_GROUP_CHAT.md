# Group Chat Implementation Plan

## Overview
Implement group chat functionality within trips, allowing trip members to create and participate in group conversations for better communication.

## Current State
- **Existing**: Trip-based messaging where all messages belong to a single trip chat
- **Missing**: Ability to create subgroups/conversations within a trip

## Design Approach: Trip-Scoped Group Chats
Group chats will be scoped within trips - trip members can create group conversations with selected trip members.

---

## Phase 1: Database Schema

### 1.1 Create `conversations` Table
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id),
    is_direct_message BOOLEAN DEFAULT false,  -- For 1:1 chats
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 1.2 Create `conversation_members` Table
```sql
CREATE TABLE conversation_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member',  -- 'admin', 'member'
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_muted BOOLEAN DEFAULT false,
    last_read_at TIMESTAMPTZ,
    UNIQUE(conversation_id, user_id)
);
```

### 1.3 Update `messages` Table
```sql
-- Add conversation_id column (nullable for backward compatibility)
ALTER TABLE messages ADD COLUMN conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE;

-- Create index for conversation queries
CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
```

### 1.4 RLS Policies
- Users can read conversations they're members of
- Users can create conversations in trips they're members of
- Conversation admins can update conversation settings
- Users can add/remove members if they're admins

---

## Phase 2: Domain Layer

### 2.1 Entities
**File**: `lib/features/messaging/domain/entities/conversation_entity.dart`

```dart
class ConversationEntity {
  final String id;
  final String tripId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String createdBy;
  final bool isDirectMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ConversationMemberEntity> members;
  final MessageEntity? lastMessage;
  final int unreadCount;
}

class ConversationMemberEntity {
  final String id;
  final String conversationId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime? lastReadAt;
  // Joined profile data
  final String? userName;
  final String? userAvatarUrl;
}
```

### 2.2 Repository Interface Extensions
**File**: `lib/features/messaging/domain/repositories/conversation_repository.dart`

```dart
abstract class ConversationRepository {
  // CRUD
  Future<Result<ConversationEntity>> createConversation(CreateConversationParams params);
  Future<Result<List<ConversationEntity>>> getTripConversations(String tripId);
  Future<Result<ConversationEntity>> getConversation(String conversationId);
  Future<Result<void>> updateConversation(UpdateConversationParams params);
  Future<Result<void>> deleteConversation(String conversationId);

  // Members
  Future<Result<void>> addMembers(String conversationId, List<String> userIds);
  Future<Result<void>> removeMember(String conversationId, String userId);
  Future<Result<void>> updateMemberRole(String conversationId, String userId, String role);
  Future<Result<void>> muteConversation(String conversationId, bool mute);

  // Messages (extends existing)
  Future<Result<List<MessageEntity>>> getConversationMessages(String conversationId, {int limit, int offset});
  Stream<MessageEntity> subscribeToConversationMessages(String conversationId);

  // Real-time
  Stream<List<ConversationEntity>> watchTripConversations(String tripId);
}
```

### 2.3 Use Cases
1. `CreateConversationUseCase` - Create new group chat
2. `GetTripConversationsUseCase` - List all conversations in a trip
3. `GetConversationMessagesUseCase` - Get messages for a conversation
4. `AddConversationMembersUseCase` - Add members to conversation
5. `LeaveConversationUseCase` - Leave a conversation
6. `UpdateConversationUseCase` - Update conversation settings

---

## Phase 3: Data Layer

### 3.1 Models
**File**: `lib/shared/models/conversation_model.dart`
- ConversationModel with fromJson/toJson
- ConversationMemberModel with fromJson/toJson

### 3.2 Remote Data Source Extensions
**File**: `lib/features/messaging/data/datasources/conversation_remote_datasource.dart`

```dart
class ConversationRemoteDataSource {
  // Conversation CRUD
  Future<ConversationModel> createConversation(Map<String, dynamic> data);
  Future<List<ConversationModel>> getTripConversations(String tripId);
  Future<ConversationModel> getConversation(String conversationId);
  Future<void> updateConversation(String id, Map<String, dynamic> data);
  Future<void> deleteConversation(String id);

  // Members
  Future<void> addMembers(String conversationId, List<String> userIds);
  Future<void> removeMember(String conversationId, String userId);

  // Real-time subscriptions
  Stream<ConversationModel> subscribeToConversation(String conversationId);
  Stream<List<ConversationModel>> subscribeToTripConversations(String tripId);
}
```

### 3.3 Repository Implementation
**File**: `lib/features/messaging/data/repositories/conversation_repository_impl.dart`

---

## Phase 4: Presentation Layer

### 4.1 Providers
**File**: `lib/features/messaging/presentation/providers/conversation_providers.dart`

```dart
// Conversation list for a trip
final tripConversationsProvider = StreamProvider.family<List<ConversationEntity>, String>(...);

// Single conversation with messages
final conversationProvider = FutureProvider.family<ConversationEntity, String>(...);

// Conversation messages stream
final conversationMessagesProvider = StreamProvider.family<List<MessageEntity>, String>(...);

// Create conversation state
final createConversationProvider = StateNotifierProvider<CreateConversationNotifier, AsyncValue<void>>(...);
```

### 4.2 Pages

#### 4.2.1 Conversation List Page
**File**: `lib/features/messaging/presentation/pages/conversation_list_page.dart`

```
┌─────────────────────────────────┐
│ ← Trip Chats           [+ New] │
├─────────────────────────────────┤
│ 🔍 Search conversations...      │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 👥 Planning Team           │ │
│ │ John: Let's meet at 9 AM   │ │
│ │ 2m ago            🔵 3     │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 👥 Food Committee          │ │
│ │ You: I'll handle lunch     │ │
│ │ 1h ago                     │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 👤 Sarah (DM)              │ │
│ │ Sarah: Thanks!             │ │
│ │ Yesterday                  │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

#### 4.2.2 Create Conversation Page
**File**: `lib/features/messaging/presentation/pages/create_conversation_page.dart`

```
┌─────────────────────────────────┐
│ ← New Group Chat        [Done] │
├─────────────────────────────────┤
│ Group Name                      │
│ ┌─────────────────────────────┐ │
│ │ Planning Team               │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Add Members (2 selected)        │
├─────────────────────────────────┤
│ ☑ John Smith                   │
│ ☑ Sarah Johnson                │
│ ☐ Mike Wilson                  │
│ ☐ Emily Brown                  │
└─────────────────────────────────┘
```

#### 4.2.3 Group Chat Screen (Reuse/Extend ChatScreen)
**File**: `lib/features/messaging/presentation/pages/group_chat_screen.dart`

- Extend existing ChatScreen to support conversation_id
- Add group info header with member avatars
- Add "Group Info" action button

#### 4.2.4 Conversation Info Page
**File**: `lib/features/messaging/presentation/pages/conversation_info_page.dart`

```
┌─────────────────────────────────┐
│ ← Group Info            [Edit] │
├─────────────────────────────────┤
│        👥                       │
│    Planning Team                │
│    4 members                    │
├─────────────────────────────────┤
│ Members                         │
│ ┌─────────────────────────────┐ │
│ │ 👤 John (Admin)             │ │
│ │ 👤 Sarah                    │ │
│ │ 👤 Mike                     │ │
│ │ 👤 You                      │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ [+ Add Members]                 │
│ [🔕 Mute Notifications]         │
│ [🚪 Leave Group]                │
│ [🗑️ Delete Group] (admin only)  │
└─────────────────────────────────┘
```

### 4.3 Widgets
1. **ConversationTile** - List item for conversation
2. **MemberSelector** - Checkbox list of trip members
3. **MemberAvatarStack** - Overlapping member avatars
4. **ConversationHeader** - Group info in chat screen

---

## Phase 5: Navigation & Routes

### 5.1 Add Routes
```dart
// In app_router.dart
static const String conversations = '/trips/:tripId/conversations';
static const String createConversation = '/trips/:tripId/conversations/create';
static const String conversationChat = '/trips/:tripId/conversations/:conversationId';
static const String conversationInfo = '/trips/:tripId/conversations/:conversationId/info';
```

### 5.2 Integration Points
- Add "Group Chats" button in Trip Detail page
- Add conversation list in Trip navigation
- Quick action to create DM from member list

---

## File Structure

```
lib/features/messaging/
├── domain/
│   ├── entities/
│   │   ├── message_entity.dart (existing)
│   │   └── conversation_entity.dart (NEW)
│   ├── repositories/
│   │   ├── message_repository.dart (existing)
│   │   └── conversation_repository.dart (NEW)
│   └── usecases/
│       ├── (existing usecases)
│       ├── create_conversation_usecase.dart (NEW)
│       ├── get_trip_conversations_usecase.dart (NEW)
│       ├── get_conversation_messages_usecase.dart (NEW)
│       ├── add_conversation_members_usecase.dart (NEW)
│       └── leave_conversation_usecase.dart (NEW)
├── data/
│   ├── datasources/
│   │   ├── message_remote_datasource.dart (existing)
│   │   ├── message_local_datasource.dart (existing)
│   │   └── conversation_remote_datasource.dart (NEW)
│   └── repositories/
│       ├── message_repository_impl.dart (existing)
│       └── conversation_repository_impl.dart (NEW)
├── presentation/
│   ├── providers/
│   │   ├── messaging_providers.dart (existing)
│   │   └── conversation_providers.dart (NEW)
│   ├── pages/
│   │   ├── chat_screen.dart (existing - extend)
│   │   ├── conversation_list_page.dart (NEW)
│   │   ├── create_conversation_page.dart (NEW)
│   │   ├── group_chat_screen.dart (NEW)
│   │   └── conversation_info_page.dart (NEW)
│   └── widgets/
│       ├── (existing widgets)
│       ├── conversation_tile.dart (NEW)
│       ├── member_selector.dart (NEW)
│       ├── member_avatar_stack.dart (NEW)
│       └── conversation_header.dart (NEW)
└── shared/models/
    ├── message_model.dart (existing)
    └── conversation_model.dart (NEW)

supabase/migrations/
└── 20251202_group_chat.sql (NEW)
```

---

## Implementation Order

1. **Database Migration** - Create tables and RLS policies
2. **Models** - ConversationModel, ConversationMemberModel
3. **Entities** - ConversationEntity, ConversationMemberEntity
4. **Data Sources** - ConversationRemoteDataSource
5. **Repository** - ConversationRepository interface and impl
6. **Use Cases** - Core use cases for CRUD operations
7. **Providers** - Riverpod providers for state management
8. **Conversation List Page** - Main conversations list
9. **Create Conversation Page** - Create new group
10. **Group Chat Screen** - Chat UI for conversations
11. **Conversation Info Page** - Group settings and members
12. **Routes** - Add navigation routes
13. **Integration** - Add entry points in Trip Detail

---

## Estimated Files to Create/Modify

### New Files (14)
1. `supabase/migrations/20251202_group_chat.sql`
2. `lib/shared/models/conversation_model.dart`
3. `lib/features/messaging/domain/entities/conversation_entity.dart`
4. `lib/features/messaging/domain/repositories/conversation_repository.dart`
5. `lib/features/messaging/domain/usecases/create_conversation_usecase.dart`
6. `lib/features/messaging/domain/usecases/get_trip_conversations_usecase.dart`
7. `lib/features/messaging/data/datasources/conversation_remote_datasource.dart`
8. `lib/features/messaging/data/repositories/conversation_repository_impl.dart`
9. `lib/features/messaging/presentation/providers/conversation_providers.dart`
10. `lib/features/messaging/presentation/pages/conversation_list_page.dart`
11. `lib/features/messaging/presentation/pages/create_conversation_page.dart`
12. `lib/features/messaging/presentation/pages/group_chat_screen.dart`
13. `lib/features/messaging/presentation/pages/conversation_info_page.dart`
14. `lib/features/messaging/presentation/widgets/conversation_tile.dart`

### Modified Files (3)
1. `lib/core/router/app_router.dart` - Add routes
2. `lib/features/trips/presentation/pages/trip_detail_page.dart` - Add "Group Chats" button
3. `lib/features/messaging/messaging_exports.dart` - Export new files
