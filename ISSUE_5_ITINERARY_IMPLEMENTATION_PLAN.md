# Issue #5: Itinerary Builder Implementation Plan

**Feature**: Itinerary Builder with Day-wise Organization
**Status**: 📋 **READY TO IMPLEMENT**
**Estimated Effort**: 6-8 hours
**Files to Create**: 35+ files (~4,000+ lines of code)

---

## 🎯 Overview

Build a complete itinerary management system that allows users to:
- Create daily activity schedules for trips
- Organize activities by day with time slots
- Add locations, descriptions, and timing
- Reorder activities within days
- View itinerary grouped by days
- Edit and delete activities

---

## ✅ What Already Exists

### Database Schema ✅
- **Table**: `itinerary_items` (already created in `database_helper.dart`)
- **Fields**: id, trip_id, title, description, location, start_time, end_time, day_number, order_index, created_by, created_at, updated_at
- **Index**: `idx_itinerary_trip_id` on trip_id

### Models ✅
- **File**: `lib/shared/models/itinerary_model.dart`
- **Models**: `ItineraryItemModel`, `ItineraryDay`
- **Features**: JSON serialization, copyWith, equality, day grouping helper

### Folder Structure ✅
- `lib/features/itinerary/domain/`
- `lib/features/itinerary/data/`
- `lib/features/itinerary/presentation/`

### Repository Interface ✅
- **File**: `lib/features/itinerary/domain/repositories/itinerary_repository.dart`
- **Methods**: CRUD + day grouping + reordering

---

## 📦 Implementation Checklist

### Phase 1: Domain Layer (6 files)

#### 1.1 Use Cases (`lib/features/itinerary/domain/usecases/`)

**create_itinerary_item_usecase.dart** (~70 lines)
```dart
class CreateItineraryItemUseCase {
  final ItineraryRepository repository;

  Future<ItineraryItemModel> call({
    required String tripId,
    required String title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    // Validations:
    // - Title required, min 3 chars
    // - End time > start time
    // - Day number > 0
    // - Order index >= 0
  }
}
```

**update_itinerary_item_usecase.dart** (~65 lines)
```dart
class UpdateItineraryItemUseCase {
  // Similar validations as create
  // Update existing item
}
```

**delete_itinerary_item_usecase.dart** (~30 lines)
```dart
class DeleteItineraryItemUseCase {
  Future<void> call(String itemId) async {
    // Delete with validation
  }
}
```

**get_trip_itinerary_usecase.dart** (~25 lines)
```dart
class GetTripItineraryUseCase {
  Future<List<ItineraryItemModel>> call(String tripId) async {
    // Get all items for trip, ordered by day and order_index
  }
}
```

**get_itinerary_by_days_usecase.dart** (~40 lines)
```dart
class GetItineraryByDaysUseCase {
  Future<List<ItineraryDay>> call(String tripId) async {
    // Get items grouped by days
    // Each day has date and list of items
  }
}
```

**reorder_items_usecase.dart** (~35 lines)
```dart
class ReorderItemsUseCase {
  Future<void> call({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) async {
    // Reorder items within a day
    // Update order_index for each
  }
}
```

---

### Phase 2: Data Layer (3 files)

#### 2.1 Local Data Source

**`lib/features/itinerary/data/datasources/itinerary_local_datasource.dart`** (~500 lines)

```dart
class ItineraryLocalDataSource {
  static final _instance = ItineraryLocalDataSource._internal();
  factory ItineraryLocalDataSource() => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();
  String? _currentUserId;

  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }

  Future<ItineraryItemModel> createItineraryItem({...}) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final db = await _dbHelper.database;
    final itemId = _uuid.v4();
    final now = DateTime.now();

    final itemData = {
      'id': itemId,
      'trip_id': tripId,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'day_number': dayNumber,
      'order_index': orderIndex,
      'created_by': _currentUserId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    await db.insert('itinerary_items', itemData);
    return ItineraryItemModel.fromJson(itemData);
  }

  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'itinerary_items',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'day_number ASC, order_index ASC, start_time ASC',
    );

    return results.map((json) => ItineraryItemModel.fromJson(json)).toList();
  }

  Future<List<ItineraryDay>> getItineraryByDays(String tripId) async {
    final items = await getTripItinerary(tripId);

    // Group by day number
    final Map<int, List<ItineraryItemModel>> dayGroups = {};

    for (final item in items) {
      final day = item.dayNumber ?? 0;
      dayGroups.putIfAbsent(day, () => []);
      dayGroups[day]!.add(item);
    }

    // Convert to ItineraryDay objects
    final days = dayGroups.entries.map((entry) {
      return ItineraryDay(
        dayNumber: entry.key,
        items: entry.value,
      );
    }).toList();

    days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return days;
  }

  Future<ItineraryItemModel> updateItineraryItem({...}) async {
    // Update logic
  }

  Future<void> deleteItineraryItem(String itemId) async {
    // Delete logic
  }

  Future<void> reorderItems({...}) async {
    // Reorder logic - update order_index for each item
  }
}
```

#### 2.2 Repository Implementation

**`lib/features/itinerary/data/repositories/itinerary_repository_impl.dart`** (~200 lines)

```dart
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryLocalDataSource localDataSource;

  ItineraryRepositoryImpl(this.localDataSource);

  @override
  Future<ItineraryItemModel> createItineraryItem({...}) async {
    try {
      return await localDataSource.createItineraryItem(...);
    } catch (e) {
      throw Exception('Failed to create itinerary item: $e');
    }
  }

  // Implement all other methods...
}
```

---

### Phase 3: Presentation Layer (5 files)

#### 3.1 Providers & Controller

**`lib/features/itinerary/presentation/providers/itinerary_providers.dart`** (~280 lines)

```dart
// Data source provider
final itineraryLocalDataSourceProvider = Provider<ItineraryLocalDataSource>((ref) {
  final dataSource = ItineraryLocalDataSource();
  final authDataSource = ref.watch(authLocalDataSourceProvider);
  dataSource.setCurrentUserId(authDataSource.currentUserId);
  return dataSource;
});

// Repository provider
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  final localDataSource = ref.watch(itineraryLocalDataSourceProvider);
  return ItineraryRepositoryImpl(localDataSource);
});

// Use case providers
final createItineraryItemUseCaseProvider = Provider<CreateItineraryItemUseCase>((ref) {
  final repository = ref.watch(itineraryRepositoryProvider);
  return CreateItineraryItemUseCase(repository);
});

// ... other use case providers

// Trip itinerary provider
final tripItineraryProvider = FutureProvider.family<List<ItineraryItemModel>, String>((
  ref,
  tripId,
) async {
  final useCase = ref.watch(getTripItineraryUseCaseProvider);
  return await useCase(tripId);
});

// Itinerary by days provider
final itineraryByDaysProvider = FutureProvider.family<List<ItineraryDay>, String>((
  ref,
  tripId,
) async {
  final useCase = ref.watch(getItineraryByDaysUseCaseProvider);
  return await useCase(tripId);
});

// Controller State
class ItineraryState {
  final bool isLoading;
  final String? error;
  final ItineraryItemModel? lastCreatedItem;
  final String? successMessage;

  const ItineraryState({...});
  ItineraryState copyWith({...}) {...}
}

// Controller
class ItineraryController extends Notifier<ItineraryState> {
  late final CreateItineraryItemUseCase _createUseCase;
  late final UpdateItineraryItemUseCase _updateUseCase;
  late final DeleteItineraryItemUseCase _deleteUseCase;
  late final ReorderItemsUseCase _reorderUseCase;

  @override
  ItineraryState build() {
    _createUseCase = ref.read(createItineraryItemUseCaseProvider);
    _updateUseCase = ref.read(updateItineraryItemUseCaseProvider);
    _deleteUseCase = ref.read(deleteItineraryItemUseCaseProvider);
    _reorderUseCase = ref.read(reorderItemsUseCaseProvider);
    return const ItineraryState();
  }

  Future<ItineraryItemModel?> createItem({...}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final item = await _createUseCase(...);
      state = state.copyWith(
        isLoading: false,
        lastCreatedItem: item,
        successMessage: 'Item added to itinerary!',
      );
      return item;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  // ... other methods
}

final itineraryControllerProvider = NotifierProvider<ItineraryController, ItineraryState>(() {
  return ItineraryController();
});
```

#### 3.2 UI Pages

**`lib/features/itinerary/presentation/pages/itinerary_list_page.dart`** (~600 lines)

```dart
class ItineraryListPage extends ConsumerStatefulWidget {
  final String tripId;

  const ItineraryListPage({super.key, required this.tripId});

  @override
  ConsumerState<ItineraryListPage> createState() => _ItineraryListPageState();
}

class _ItineraryListPageState extends ConsumerState<ItineraryListPage> {
  @override
  Widget build(BuildContext context) {
    final itineraryAsync = ref.watch(itineraryByDaysProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: itineraryAsync.when(
        data: (days) => days.isEmpty
            ? _buildEmptyState()
            : _buildDaysList(days),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddItem(),
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDaysList(List<ItineraryDay> days) {
    return StaggeredListAnimation(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _buildDayCard(day);
      },
    );
  }

  Widget _buildDayCard(ItineraryDay day) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLg),
                topRight: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  'Day ${day.dayNumber}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (day.date != null) ...[
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    ' - ${DateFormat('MMM dd').format(day.date!)}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
                Spacer(),
                Chip(
                  label: Text('${day.itemCount} items'),
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),

          // Items list
          ...day.items.map((item) => _buildItineraryItem(item)),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(ItineraryItemModel item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLg),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPale,
          child: Icon(Icons.event, color: AppTheme.primaryTeal),
        ),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.startTime != null || item.endTime != null)
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppTheme.neutral600),
                  const SizedBox(width: 4),
                  Text(_formatTimeRange(item.startTime, item.endTime)),
                ],
              ),
            if (item.location != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.neutral600),
                  const SizedBox(width: 4),
                  Text(item.location!),
                ],
              ),
            if (item.description != null)
              Text(
                item.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEditItem(item),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 100, color: AppTheme.neutral300),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'No itinerary items yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Tap + to add your first activity',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}
```

**`lib/features/itinerary/presentation/pages/add_edit_itinerary_item_page.dart`** (~500 lines)

```dart
class AddEditItineraryItemPage extends ConsumerStatefulWidget {
  final String tripId;
  final String? itemId; // null for add, set for edit

  const AddEditItineraryItemPage({
    super.key,
    required this.tripId,
    this.itemId,
  });

  @override
  ConsumerState<AddEditItineraryItemPage> createState() => _AddEditItineraryItemPageState();
}

class _AddEditItineraryItemPageState extends ConsumerState<AddEditItineraryItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  int? _dayNumber;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    // Load existing item data if editing
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEditMode = widget.itemId != null;

      if (isEditMode) {
        await ref.read(itineraryControllerProvider.notifier).updateItem(
          itemId: widget.itemId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          dayNumber: _dayNumber,
        );
      } else {
        await ref.read(itineraryControllerProvider.notifier).createItem(
          tripId: widget.tripId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          dayNumber: _dayNumber,
        );
      }

      if (mounted) {
        ref.invalidate(itineraryByDaysProvider(widget.tripId));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Item updated!' : 'Item added!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.itemId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Activity' : 'Add Activity'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Visit Eiffel Tower',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Add details about this activity',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Location field
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Where will this take place?',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Day number picker
            _buildDayPicker(),
            const SizedBox(height: AppTheme.spacingMd),

            // Start time picker
            _buildTimePicker(
              label: 'Start Time',
              time: _startTime,
              onChanged: (time) => setState(() => _startTime = time),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // End time picker
            _buildTimePicker(
              label: 'End Time',
              time: _endTime,
              onChanged: (time) => setState(() => _endTime = time),
            ),
            const SizedBox(height: AppTheme.spacing2xl),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEditMode ? 'Save Changes' : 'Add to Itinerary'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Phase 4: Routing & Integration (2 files)

#### 4.1 Router Updates

**Update `lib/core/router/app_router.dart`:**

```dart
// Add these routes
GoRoute(
  path: '/trips/:tripId/itinerary',
  name: 'itinerary',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return ItineraryListPage(tripId: tripId);
  },
),
GoRoute(
  path: '/trips/:tripId/itinerary/add',
  name: 'addItineraryItem',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    return AddEditItineraryItemPage(tripId: tripId);
  },
),
GoRoute(
  path: '/trips/:tripId/itinerary/:itemId/edit',
  name: 'editItineraryItem',
  builder: (context, state) {
    final tripId = state.pathParameters['tripId']!;
    final itemId = state.pathParameters['itemId']!;
    return AddEditItineraryItemPage(tripId: tripId, itemId: itemId);
  },
),
```

#### 4.2 Trip Detail Page Integration

**Update `lib/features/trips/presentation/pages/trip_detail_page.dart`:**

Add "Itinerary" tab/button that navigates to itinerary page.

---

### Phase 5: Comprehensive Testing (10+ files)

#### 5.1 Use Case Tests

Create test files in `test/features/itinerary/domain/usecases/`:

**create_itinerary_item_usecase_test.dart** (15+ tests)
- Success cases (with all fields, minimal fields)
- Validation errors (empty title, short title, invalid times, negative day, etc.)
- Repository errors

**update_itinerary_item_usecase_test.dart** (18+ tests)
- Update all fields, update specific fields
- Validation errors
- Repository errors

**get_itinerary_by_days_usecase_test.dart** (12+ tests)
- Empty itinerary
- Single day
- Multiple days
- Items without day numbers
- Proper sorting

**delete_itinerary_item_usecase_test.dart** (8+ tests)
- Delete existing
- Delete non-existent
- Repository errors

**reorder_items_usecase_test.dart** (10+ tests)
- Reorder within day
- Invalid item IDs
- Repository errors

#### 5.2 Example Test Structure

```dart
// create_itinerary_item_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/create_itinerary_item_usecase.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';

class MockItineraryRepository implements ItineraryRepository {
  ItineraryItemModel? _itemToReturn;
  Exception? _exceptionToThrow;
  bool _createCalled = false;
  Map<String, dynamic>? _lastCallParams;

  void setupCreateItem(ItineraryItemModel item) {
    _itemToReturn = item;
  }

  void setupCreateToThrow(Exception exception) {
    _exceptionToThrow = exception;
  }

  bool get wasCreateCalled => _createCalled;
  Map<String, dynamic>? get lastCallParams => _lastCallParams;

  void reset() {
    _itemToReturn = null;
    _exceptionToThrow = null;
    _createCalled = false;
    _lastCallParams = null;
  }

  @override
  Future<ItineraryItemModel> createItineraryItem({...}) async {
    _createCalled = true;
    _lastCallParams = {...};

    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _itemToReturn!;
  }

  // ... implement other methods with UnimplementedError
}

void main() {
  late CreateItineraryItemUseCase useCase;
  late MockItineraryRepository mockRepository;

  setUp(() {
    mockRepository = MockItineraryRepository();
    useCase = CreateItineraryItemUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('CreateItineraryItemUseCase', () {
    final testItem = ItineraryItemModel(...);

    group('Success Cases', () {
      test('should create item with all fields', () async {
        mockRepository.setupCreateItem(testItem);

        final result = await useCase(
          tripId: 'trip-1',
          title: 'Visit Tower',
          description: 'Great view',
          location: 'Paris',
          startTime: DateTime(2025, 6, 1, 10, 0),
          endTime: DateTime(2025, 6, 1, 12, 0),
          dayNumber: 1,
          orderIndex: 0,
        );

        expect(result, equals(testItem));
        expect(mockRepository.wasCreateCalled, isTrue);
        expect(mockRepository.lastCallParams?['title'], equals('Visit Tower'));
      });

      test('should create item with minimal fields', () async {
        // ... test
      });

      test('should trim whitespace from title', () async {
        // ... test
      });
    });

    group('Validation Errors', () {
      test('should throw when title is empty', () async {
        expect(
          () => useCase(tripId: 'trip-1', title: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Title is required'),
          )),
        );
        expect(mockRepository.wasCreateCalled, isFalse);
      });

      test('should throw when title is too short', () async {
        // ... test
      });

      test('should throw when end time is before start time', () async {
        // ... test
      });

      test('should throw when day number is negative', () async {
        // ... test
      });

      test('should throw when order index is negative', () async {
        // ... test
      });
    });

    group('Repository Errors', () {
      test('should wrap repository exceptions', () async {
        // ... test
      });
    });
  });
}
```

#### 5.3 Run Tests

```bash
# Run all itinerary tests
flutter test test/features/itinerary/

# Expected output:
# 00:02 +63: All tests passed!
```

---

## 📊 Success Criteria

### Functionality ✅
- [x] Create itinerary items
- [x] View items grouped by days
- [x] Edit existing items
- [x] Delete items
- [x] Reorder items within days
- [x] Time scheduling
- [x] Location tracking
- [x] Day-wise organization

### Technical ✅
- [x] Clean architecture (Domain/Data/Presentation)
- [x] Riverpod state management
- [x] SQLite local storage
- [x] Proper error handling
- [x] Form validation
- [x] Loading states
- [x] Success/error feedback

### Testing ✅
- [x] 60+ unit tests
- [x] 100% test pass rate
- [x] All use cases tested
- [x] Validation tested
- [x] Error handling tested

### UI/UX ✅
- [x] Material Design 3
- [x] Premium animations
- [x] Empty states
- [x] Error states
- [x] Loading states
- [x] Intuitive navigation
- [x] Responsive layout

---

## 🚀 Implementation Order

1. **Domain Layer** (2-3 hours)
   - Repository interface ✅ (done)
   - 6 use cases with validation

2. **Data Layer** (2-3 hours)
   - Local datasource with SQLite
   - Repository implementation
   - Day grouping logic

3. **Presentation Layer** (2-3 hours)
   - Providers & controller
   - List page with day grouping
   - Add/edit page with forms
   - Animations

4. **Testing** (1-2 hours)
   - Create 60+ unit tests
   - Run and verify 100% pass
   - Fix any issues

5. **Integration** (30 mins)
   - Router updates
   - Trip detail integration
   - End-to-end testing

---

## 📝 File Summary

### Files to Create: 35+ files

**Domain Layer (7 files):**
1. itinerary_repository.dart ✅
2. create_itinerary_item_usecase.dart
3. update_itinerary_item_usecase.dart
4. delete_itinerary_item_usecase.dart
5. get_trip_itinerary_usecase.dart
6. get_itinerary_by_days_usecase.dart
7. reorder_items_usecase.dart

**Data Layer (2 files):**
8. itinerary_local_datasource.dart
9. itinerary_repository_impl.dart

**Presentation Layer (3 files):**
10. itinerary_providers.dart
11. itinerary_list_page.dart
12. add_edit_itinerary_item_page.dart

**Tests (20+ files):**
13-32. Use case test files (1 per use case with mocks)

**Total Lines**: ~4,000+ lines

---

## 🎯 Next Steps

1. Start with **Domain Layer** - Create all 6 use cases
2. Move to **Data Layer** - Implement datasource and repository
3. Build **Presentation Layer** - Providers, controller, UI pages
4. Write **Comprehensive Tests** - 60+ tests covering all scenarios
5. **Integrate** with trip detail page and router
6. **Test End-to-End** - Manual testing of complete flow
7. **Document** - Create ISSUE_5_COMPLETE.md with results

---

**Ready to implement?** Follow this plan systematically, and you'll have a production-ready Itinerary Builder with full test coverage!

---

_Implementation Plan Generated by Claude Code_
_Date: 2025-10-17_
