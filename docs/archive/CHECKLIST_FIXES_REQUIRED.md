# CHECKLIST FIXES & IMPLEMENTATION PLAN

**Status**: Checkbox still not working - requires final fixes
**Date**: 2025-10-20

---

## 🐛 CRITICAL ISSUE: Checkbox Not Working

### Root Cause Analysis

The checkbox is **not responding** because:
1. We're using `FutureProvider` which caches the result
2. `ref.invalidate()` may not be triggering a full rebuild
3. The database update is happening but the UI isn't reflecting it

### ✅ SOLUTION: Use StateNotifier Pattern

Instead of using providers with invalidation, we need to use a **StateNotifier** that holds the checklist data and updates immediately when toggled.

### Implementation Steps

#### 1. Update ChecklistController to hold state

File: `lib/features/checklists/presentation/providers/checklist_providers.dart`

Change from:
```dart
class ChecklistController extends Notifier<ChecklistState> {
  // Current implementation
}
```

To:
```dart
// Add a state notifier for the checklist items
class ChecklistDataNotifier extends StateNotifier<ChecklistWithItemsEntity?> {
  final ChecklistRepository _repository;
  final String checklistId;

  ChecklistDataNotifier(this._repository, this.checklistId) : super(null) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _repository.getChecklistWithItems(checklistId);
      state = data;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleItem(String itemId, bool isCompleted, String userId) async {
    try {
      await _repository.toggleItemCompletion(
        itemId: itemId,
        isCompleted: isCompleted,
        userId: userId,
      );
      // Immediately reload data
      await _loadData();
    } catch (e) {
      // Handle error
    }
  }
}

// Provider for checklist data
final checklistDataProvider = StateNotifierProvider.family<ChecklistDataNotifier, ChecklistWithItemsEntity?, String>(
  (ref, checklistId) {
    final repository = ref.watch(checklistRepositoryProvider);
    return ChecklistDataNotifier(repository, checklistId);
  },
);
```

#### 2. Update ChecklistDetailPage to use new provider

File: `lib/features/checklists/presentation/pages/checklist_detail_page.dart`

Change from:
```dart
final checklistAsync = ref.watch(checklistWithItemsProvider(checklistId));
```

To:
```dart
final checklistData = ref.watch(checklistDataProvider(checklistId));
```

Then update the UI to handle nullable state:
```dart
if (checklistData == null) {
  return Center(child: CircularProgressIndicator());
}

final checklist = checklistData.checklist;
final items = checklistData.items;
```

#### 3. Update toggle handler

Change from:
```dart
onToggle: () async {
  final controller = ref.read(checklistControllerProvider.notifier);
  await controller.toggleItemCompletion(...);
  ref.invalidate(checklistWithItemsProvider(checklistId));
}
```

To:
```dart
onToggle: () async {
  final authDataSource = ref.read(authLocalDataSourceProvider);
  final userId = authDataSource.currentUserId;
  if (userId == null) return;

  final notifier = ref.read(checklistDataProvider(checklistId).notifier);
  await notifier.toggleItem(item.id, !item.isCompleted, userId);
}
```

---

## ✨ EDIT FUNCTIONALITY

### Status: Partially Implemented

**What's Done**:
- ✅ EditItemDialog widget created
- ✅ onEdit parameter added to ChecklistItemTile
- ✅ Long-press handler added to tile

**What's Missing**:
- Need to wire up the edit dialog in ChecklistDetailPage

### Implementation

File: `lib/features/checklists/presentation/pages/checklist_detail_page.dart`

Add import:
```dart
import '../widgets/edit_item_dialog.dart';
```

Add onEdit handler to ChecklistItemTile:
```dart
ChecklistItemTile(
  item: item,
  onToggle: () async { ... },
  onEdit: () async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
    if (result == true) {
      // Refresh data
      ref.read(checklistDataProvider(checklistId).notifier)._loadData();
    }
  },
  onDelete: () async { ... },
)
```

---

## 🗑️ DELETE FUNCTIONALITY

### Status: Already Implemented

Swipe-to-delete is already working via the `Dismissible` widget in ChecklistItemTile.

**To verify**: Swipe item from right to left → confirmation dialog → delete

---

## 🧪 END-TO-END UNIT TESTS

### Tests Required

Create file: `test/features/checklists/e2e/checklist_complete_workflow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Checklist E2E Tests', () {
    test('Complete workflow: Create → Add Items → Toggle → Delete', () async {
      // 1. Create checklist
      // 2. Add 3 items
      // 3. Toggle item 1 to complete
      // 4. Verify progress = 33%
      // 5. Toggle item 2 to complete
      // 6. Verify progress = 67%
      // 7. Delete item 3
      // 8. Verify progress = 100% (2/2 items)
    });

    test('Edit item functionality', () async {
      // 1. Create checklist with item
      // 2. Edit item title
      // 3. Verify title updated
    });

    test('Multiple users completing different items', () async {
      // 1. Create checklist
      // 2. Add 2 items assigned to different users
      // 3. User 1 completes their item
      // 4. User 2 completes their item
      // 5. Verify both completions tracked correctly
    });
  });
}
```

---

## 📋 TODO LIST

### High Priority (Fix Checkbox)
1. ✅ Create EditItemDialog widget
2. ⏳ Implement StateNotifier pattern for checklist data
3. ⏳ Update ChecklistDetailPage to use StateNotifier
4. ⏳ Wire up edit dialog
5. ⏳ Test checkbox toggle - MUST WORK!

### Medium Priority (Features)
6. ⏳ Write comprehensive E2E tests
7. ⏳ Test edit functionality
8. ⏳ Test delete functionality
9. ⏳ Build final APK

### Testing Checklist
- [ ] Checkbox toggles immediately
- [ ] Progress bar updates in real-time
- [ ] Counter updates (0/2 → 1/2 → 2/2)
- [ ] Long-press opens edit dialog
- [ ] Edit saves and refreshes
- [ ] Swipe-to-delete works
- [ ] All E2E tests pass

---

## 🔨 QUICK FIX SCRIPT

To implement the StateNotifier solution immediately:

1. **Update providers** (checklist_providers.dart)
2. **Update detail page** (checklist_detail_page.dart)
3. **Test checkbox** - tap and verify immediate update
4. **Build APK**
5. **Run E2E tests**

---

## ⚠️ IMPORTANT NOTES

**Why FutureProvider isn't working:**
- FutureProvider caches the result
- `ref.invalidate()` schedules a rebuild but doesn't happen immediately
- The UI reads the cached data before the new fetch completes

**Why StateNotifier will work:**
- Holds the data in memory
- Can update state immediately after database write
- UI rebuilds instantly when state changes
- No caching delays

**Alternative simpler fix:**
- Use `ref.refresh()` instead of `ref.invalidate()`
- This forces an immediate refetch
- May work with current FutureProvider approach

---

## 📝 FILES TO MODIFY

1. `lib/features/checklists/presentation/providers/checklist_providers.dart` - Add StateNotifier
2. `lib/features/checklists/presentation/pages/checklist_detail_page.dart` - Use StateNotifier, wire edit dialog
3. `test/features/checklists/e2e/checklist_complete_workflow_test.dart` - Create E2E tests

---

**Next Step**: Implement StateNotifier pattern OR try `ref.refresh()` as quick fix
