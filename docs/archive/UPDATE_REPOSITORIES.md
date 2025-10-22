# Repository Update Script - Remove SQLite, Use Supabase Only

This document tracks the conversion of all repositories from hybrid (Supabase + SQLite) to Supabase-only mode.

## Files to Update

1. ✅ auth_repository_impl.dart - COMPLETED
2. ✅ auth_providers.dart - COMPLETED  
3. ⏳ trip_repository_impl.dart - IN PROGRESS
4. ⏳ trip_providers.dart - PENDING
5. ⏳ expense_repository_impl.dart - PENDING
6. ⏳ expense_providers.dart - PENDING
7. ⏳ itinerary_repository_impl.dart - PENDING
8. ⏳ itinerary_providers.dart - PENDING
9. ⏳ checklist_repository_impl.dart - PENDING
10. ⏳ invite_repository_impl.dart - PENDING
11. ⏳ invite_providers.dart - PENDING
12. ⏳ main.dart - PENDING

## Pattern for Repository Updates

### Remove:
- Import of `data_source_config.dart`
- Import of `*_local_datasource.dart`
- `_localDataSource` field
- All `DataSourceConfig` checks
- All fallback logic
- All sync logic

### Keep:
- Import of `*_remote_datasource.dart`
- `_remoteDataSource` field
- Direct calls to `_remoteDataSource` methods
- Debug logging (kDebugMode)

### Update Constructor:
From:
```dart
TripRepositoryImpl(this._remoteDataSource, this._localDataSource);
```

To:
```dart
TripRepositoryImpl(this._remoteDataSource);
```

## Pattern for Provider Updates

### Remove:
- `*LocalDataSourceProvider`
- LocalDataSource from repository provider

### Update Repository Provider:
From:
```dart
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final remoteDataSource = ref.watch(tripRemoteDataSourceProvider);
  final localDataSource = ref.watch(tripLocalDataSourceProvider);
  return TripRepositoryImpl(remoteDataSource, localDataSource);
});
```

To:
```dart
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final remoteDataSource = ref.watch(tripRemoteDataSourceProvider);
  return TripRepositoryImpl(remoteDataSource);
});
```

