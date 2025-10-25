# Messaging Module - Bug Fixes

**Date:** 2025-10-25
**Issues:** 4 critical bugs in messaging module
**Status:** 🔧 IN PROGRESS

---

## Issues Identified

### 1. Bluetooth Initialization Failed ❌
**Error:** Bluetooth fails to initialize silently
**Impact:** P2P messaging unavailable
**Root Cause:** BLE service initialization wrapped in try-catch but errors not shown to user

### 2. Emoji Reaction Error ❌
**Error:** "Unknown error" when long-pressing message and selecting emoji
**Impact:** Users cannot add reactions
**Root Cause:** Likely permission error or null userId in reaction use case

### 3. Message Sending Stuck on Loading ❌
**Error:** Message input shows default loading screen forever
**Impact:** Users cannot send messages
**Root Cause:** Async operation not awaited properly or error not caught

### 4. WiFi Page Loading Forever ❌
**Error:** P2P peers sheet shows only loading indicator
**Impact:** WiFi Direct P2P unavailable
**Root Cause:** P2P initialization failing or peers stream error

---

## Analysis

### Issue #1: Bluetooth Initialization

**Location:** `chat_screen.dart:56-67`

```dart
Future<void> _initializeBLE() async {
  try {
    final bleNotifier = ref.read(bleServiceNotifierProvider.notifier);
    await bleNotifier.initialize(
      userId: widget.currentUserId,
      userName: widget.tripName, // Using trip name as user display name
    );
  } catch (e) {
    debugPrint('BLE initialization failed: $e');
    // Non-critical error - P2P messaging will be unavailable
  }
}
```

**Problem:**
- Errors caught but not shown to user
- No feedback if BLE fails
- Silent failure means users don't know P2P is unavailable

**Solution:**
- Check BLE state and show proper error message
- Inform user if permissions denied
- Provide action to retry or go to settings

---

### Issue #2: Emoji Reaction Error

**Location:** `chat_screen.dart:346-363`

```dart
Future<void> _handleAddReaction(String messageId, String emoji) async {
  try {
    final addReactionUseCase = ref.read(addReactionUseCaseProvider);

    final result = await addReactionUseCase.execute(
      messageId: messageId,
      userId: widget.currentUserId,
      emoji: emoji,
    );

    result.fold(
      onSuccess: (_) {},
      onFailure: (error) => _showError(error),
    );
  } catch (e) {
    _showError('Failed to add reaction: $e');
  }
}
```

**Problem:**
- Uses `Result.success(null)` but `Result<void>` might not handle null properly
- Error message is generic "unknown error"
- No specific handling for permission or network errors

**Potential Causes:**
1. `currentUserId` is empty/null
2. Network error not caught properly
3. Repository method throws exception
4. Null safety issue with void return type

**Solution:**
- Add null check for userId before calling use case
- Better error handling in repository
- Show specific error messages

---

### Issue #3: Message Sending Loading

**Location:** `chat_screen.dart:97-128` and `message_input.dart`

**Problem:**
- Loading state set but never cleared on error
- No timeout for send operation
- Optimistic UI update missing

**Expected Flow:**
1. User types message and taps send
2. UI shows loading indicator
3. Message sent to repository
4. On success: Clear input, hide loading, scroll to bottom
5. On failure: Show error, keep message in input, hide loading

**Current Issue:**
- Loading state not managed in `MessageInput` widget
- If send fails silently, loading never clears

**Solution:**
- Add proper loading state management
- Add timeout (30 seconds)
- Add optimistic UI update
- Handle all error cases

---

### Issue #4: WiFi Page Loading Forever

**Location:** `p2p_peers_sheet.dart:59-65` and `p2p_providers.dart`

```dart
Future<void> _initializeP2P() async {
  final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
  await notifier.initialize(
    userId: widget.userId,
    userName: widget.userName,
  );
}
```

**Problem:**
- P2P initialization may be failing
- Stream provider showing loading state indefinitely
- No error state handling

**Potential Causes:**
1. P2P connection manager not properly initialized
2. Platform-specific service (WiFi Direct/Multipeer) failing
3. Permissions not granted
4. Peers stream never emits data

**Solution:**
- Add error handling for initialization
- Show error state if initialization fails
- Provide retry mechanism
- Check permissions before initializing

---

## Fixes to Apply

### Fix #1: Better BLE Error Handling

**File:** `lib/features/messaging/presentation/pages/chat_screen.dart`

**Changes:**
1. Show snackbar if BLE initialization fails
2. Check adapter state before initializing
3. Provide actionable error messages

```dart
Future<void> _initializeBLE() async {
  try {
    // Check if Bluetooth is supported
    if (!await FlutterBluePlus.isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth not supported on this device'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
      return;
    }

    final bleNotifier = ref.read(bleServiceNotifierProvider.notifier);
    await bleNotifier.initialize(
      userId: widget.currentUserId,
      userName: widget.tripName,
    );

    // Check if initialization succeeded
    final state = ref.read(bleServiceNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Bluetooth initialization failed'),
          backgroundColor: AppTheme.error,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initializeBLE,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('BLE initialization failed: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bluetooth error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
```

---

### Fix #2: Better Reaction Error Handling

**File:** `lib/features/messaging/presentation/pages/chat_screen.dart`

**Changes:**
1. Validate userId before adding reaction
2. Better error messages
3. Log more details for debugging

```dart
Future<void> _handleAddReaction(String messageId, String emoji) async {
  try {
    // Validate userId
    if (widget.currentUserId.isEmpty) {
      _showError('User not logged in. Cannot add reaction.');
      return;
    }

    debugPrint('Adding reaction: messageId=$messageId, userId=${widget.currentUserId}, emoji=$emoji');

    final addReactionUseCase = ref.read(addReactionUseCaseProvider);

    final result = await addReactionUseCase.execute(
      messageId: messageId,
      userId: widget.currentUserId,
      emoji: emoji,
    );

    result.fold(
      onSuccess: (_) {
        debugPrint('✅ Reaction added successfully');
        // Show success feedback (optional)
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Reaction added'), duration: Duration(seconds: 1)),
        // );
      },
      onFailure: (error) {
        debugPrint('❌ Reaction failed: $error');
        _showError('Failed to add reaction: $error');
      },
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Exception adding reaction: $e');
    debugPrint('Stack trace: $stackTrace');
    _showError('Failed to add reaction: ${e.toString()}');
  }
}
```

**Additional Fix in Use Case:**

**File:** `lib/features/messaging/domain/usecases/add_reaction_usecase.dart`

```dart
/// Execute the use case
Future<Result<void>> execute({
  required String messageId,
  required String userId,
  required String emoji,
}) async {
  try {
    debugPrint('🔵 [AddReactionUseCase] execute START');
    debugPrint('   Message ID: $messageId');
    debugPrint('   User ID: $userId');
    debugPrint('   Emoji: $emoji');

    // Validate inputs
    final validationError = _validate(
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );

    if (validationError != null) {
      debugPrint('❌ [AddReactionUseCase] Validation failed: $validationError');
      return Result.failure(validationError);
    }

    // Add reaction through repository
    await repository.addReaction(
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );

    debugPrint('✅ [AddReactionUseCase] Reaction added');
    // Fix: Return success with void explicitly
    return Result.success(null as void);
  } catch (e, stackTrace) {
    debugPrint('❌ [AddReactionUseCase] execute FAILED');
    debugPrint('   Exception: $e');
    debugPrint('   Stack Trace: $stackTrace');
    return Result.failure('Failed to add reaction: ${e.toString()}');
  }
}
```

---

### Fix #3: Message Sending Loading State

**File:** `lib/features/messaging/presentation/pages/chat_screen.dart`

**Add timeout and better error handling:**

```dart
Future<void> _handleSendMessage(String messageText) async {
  try {
    debugPrint('Sending message: $messageText');

    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);

    // Add timeout to prevent infinite loading
    final result = await sendMessageUseCase.execute(
      tripId: widget.tripId,
      senderId: widget.currentUserId,
      message: messageText,
      messageType: MessageType.text,
      replyToId: _replyToMessage?.id,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('❌ Send message timeout');
        return Result.failure('Message send timed out. Please try again.');
      },
    );

    result.fold(
      onSuccess: (message) {
        debugPrint('✅ Message sent successfully: ${message.id}');
        // Clear reply state
        if (_replyToMessage != null) {
          setState(() {
            _replyToMessage = null;
          });
        }

        // Scroll to bottom
        _scrollToBottom();
      },
      onFailure: (error) {
        debugPrint('❌ Message send failed: $error');
        _showError(error);
      },
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Exception sending message: $e');
    debugPrint('Stack trace: $stackTrace');
    _showError('Failed to send message: ${e.toString()}');
  }
}
```

**MessageInput Widget Fix:**

Need to check if `MessageInput` widget properly manages loading state. The widget should:
1. Show loading indicator when sending
2. Clear loading on success OR error
3. Keep message text on error (don't clear input)

---

### Fix #4: WiFi/P2P Loading State

**File:** `lib/features/messaging/presentation/widgets/p2p_peers_sheet.dart`

**Add error handling:**

```dart
@override
void initState() {
  super.initState();
  _initializeP2P();
}

Future<void> _initializeP2P() async {
  try {
    debugPrint('Initializing P2P...');

    final notifier = ref.read(p2pConnectionNotifierProvider.notifier);
    await notifier.initialize(
      userId: widget.userId,
      userName: widget.userName,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('P2P initialization timed out');
      },
    );

    // Check if initialization succeeded
    final state = ref.read(p2pConnectionNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Failed to initialize P2P'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initializeP2P,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ P2P initialization failed: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('P2P initialization failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initializeP2P,
          ),
        ),
      );
    }
  }
}

@override
Widget build(BuildContext context) {
  final state = ref.watch(p2pConnectionNotifierProvider);
  final peersAsync = ref.watch(p2pPeersProvider);

  return Container(
    height: MediaQuery.of(context).size.height * 0.75,
    padding: const EdgeInsets.all(AppTheme.spacingLg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(state),
        const SizedBox(height: AppTheme.spacingMd),

        // Show error if initialization failed
        if (state.hasError) ...[
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    state.errorMessage ?? 'Initialization failed',
                    style: TextStyle(color: Colors.red.shade900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  ElevatedButton.icon(
                    onPressed: _initializeP2P,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (!state.isInitialized) ...[
          // Show loading during initialization
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spacingMd),
                  Text('Initializing P2P connection...'),
                ],
              ),
            ),
          ),
        ] else ...[
          // Normal UI when initialized
          _buildModeSelector(state),
          const SizedBox(height: AppTheme.spacingMd),

          _buildStatistics(state),
          const SizedBox(height: AppTheme.spacingMd),

          Expanded(
            child: peersAsync.when(
              data: (peers) => _buildPeersList(peers, state),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Error loading peers',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      error.toString(),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
```

---

## Summary of Changes

### Files to Modify:

1. **`lib/features/messaging/presentation/pages/chat_screen.dart`**
   - Better BLE initialization error handling
   - Better reaction error handling
   - Add timeout to message sending
   - Better logging

2. **`lib/features/messaging/domain/usecases/add_reaction_usecase.dart`**
   - Fix `Result.success(null as void)` for proper void handling

3. **`lib/features/messaging/presentation/widgets/p2p_peers_sheet.dart`**
   - Add error state handling
   - Add retry mechanism
   - Better loading states
   - Timeout for initialization

### Testing Checklist:

- [ ] Test BLE initialization with Bluetooth off
- [ ] Test BLE initialization with permissions denied
- [ ] Test adding reaction to message
- [ ] Test sending text message
- [ ] Test sending message timeout (airplane mode)
- [ ] Test WiFi Direct/P2P peers discovery
- [ ] Test error recovery (retry buttons)

---

**Status:** Ready to implement fixes
