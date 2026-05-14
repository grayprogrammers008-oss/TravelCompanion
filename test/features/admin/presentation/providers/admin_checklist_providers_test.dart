import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathio/core/providers/supabase_provider.dart';
import 'package:pathio/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:pathio/features/admin/domain/entities/admin_checklist.dart';
import 'package:pathio/features/admin/presentation/providers/admin_checklist_providers.dart';
import 'package:pathio/features/admin/presentation/providers/admin_providers.dart';

class _StubSupabaseClient extends Mock implements SupabaseClient {}

class _FakeChecklistDataSource extends AdminRemoteDataSource {
  _FakeChecklistDataSource() : super(_StubSupabaseClient());

  List<AdminChecklistModel> checklistsToReturn = const [];
  AdminChecklistStatsModel statsToReturn =
      const AdminChecklistStatsModel();
  Object? checklistError;
  Object? statsError;
  final List<Map<String, dynamic>> getCalls = [];
  int statsCalls = 0;

  bool deleteResult = true;
  bool updateResult = true;
  int bulkResult = 0;
  final List<String> deleteCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];
  final List<Map<String, dynamic>> bulkCalls = [];

  @override
  Future<List<AdminChecklistModel>> getAllChecklists({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
    String? tripId,
  }) async {
    getCalls.add({
      'limit': limit,
      'offset': offset,
      'search': search,
      'status': status,
      'tripId': tripId,
    });
    if (checklistError != null) throw checklistError!;
    return checklistsToReturn;
  }

  @override
  Future<AdminChecklistStatsModel> getChecklistStats() async {
    statsCalls++;
    if (statsError != null) throw statsError!;
    return statsToReturn;
  }

  @override
  Future<bool> deleteChecklist(String checklistId) async {
    deleteCalls.add(checklistId);
    return deleteResult;
  }

  @override
  Future<bool> updateChecklist(String checklistId, {String? name}) async {
    updateCalls.add({'id': checklistId, 'name': name});
    return updateResult;
  }

  @override
  Future<int> bulkUpdateChecklistItems(
    String checklistId, {
    required bool isCompleted,
  }) async {
    bulkCalls.add({'id': checklistId, 'isCompleted': isCompleted});
    return bulkResult;
  }
}

void main() {
  group('admin_checklist_providers', () {
    late _FakeChecklistDataSource fake;
    late ProviderContainer container;

    setUp(() {
      fake = _FakeChecklistDataSource();
      container = ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(_StubSupabaseClient()),
        adminRemoteDataSourceProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('adminChecklistsProvider returns checklists with default params',
        () async {
      fake.checklistsToReturn = const [
        AdminChecklistModel(
          id: 'c1',
          tripId: 't1',
          tripName: 'Trip',
          name: 'List',
        ),
      ];
      final result = await container
          .read(adminChecklistsProvider(const ChecklistListParams()).future);
      expect(result, hasLength(1));
      expect(result.first.id, 'c1');
      expect(fake.getCalls.single['limit'], 50);
    });

    test('adminChecklistsProvider passes filter params through', () async {
      fake.checklistsToReturn = const [];
      const params = ChecklistListParams(
        limit: 5,
        offset: 10,
        search: 'pack',
        status: 'completed',
        tripId: 'trip-1',
      );
      await container.read(adminChecklistsProvider(params).future);
      final call = fake.getCalls.single;
      expect(call['limit'], 5);
      expect(call['offset'], 10);
      expect(call['search'], 'pack');
      expect(call['status'], 'completed');
      expect(call['tripId'], 'trip-1');
    });

    test('adminChecklistStatsProvider returns stats from datasource', () async {
      fake.statsToReturn = const AdminChecklistStatsModel(
        totalChecklists: 7,
        totalItems: 25,
        completedItems: 10,
        pendingItems: 15,
        completionRate: 40.0,
        checklistsWithAllCompleted: 1,
        emptyChecklists: 2,
      );
      final stats = await container.read(adminChecklistStatsProvider.future);
      expect(stats.totalChecklists, 7);
      expect(stats.completionRate, 40.0);
      expect(fake.statsCalls, 1);
    });

    test('adminChecklistStatsProvider propagates errors',
        skip:
            'Riverpod 3.x: .future on a FutureProvider with a throwing override hangs indefinitely. Same skip as elsewhere.',
        () async {
      fake.statsError = Exception('boom');
      try {
        await container.read(adminChecklistStatsProvider.future);
        fail('expected an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('adminChecklistRepositoryProvider exposes deleteChecklist', () async {
      final repo = container.read(adminChecklistRepositoryProvider);
      final result = await repo.deleteChecklist('c1');
      expect(result, true);
      expect(fake.deleteCalls.single, 'c1');
    });

    test('adminChecklistRepositoryProvider exposes updateChecklist', () async {
      final repo = container.read(adminChecklistRepositoryProvider);
      final result = await repo.updateChecklist('c1', name: 'New');
      expect(result, true);
      expect(fake.updateCalls.single['id'], 'c1');
      expect(fake.updateCalls.single['name'], 'New');
    });

    test('adminChecklistRepositoryProvider exposes bulk update', () async {
      fake.bulkResult = 4;
      final repo = container.read(adminChecklistRepositoryProvider);
      final result =
          await repo.bulkUpdateChecklistItems('c1', isCompleted: true);
      expect(result, 4);
      expect(fake.bulkCalls.single['id'], 'c1');
      expect(fake.bulkCalls.single['isCompleted'], true);
    });

    test('adminChecklistsProvider propagates errors',
        skip:
            'Riverpod 3.x: .future on a FutureProvider.family with a throwing override hangs indefinitely. Same skip as elsewhere.',
        () async {
      fake.checklistError = Exception('checklist failed');
      try {
        await container
            .read(adminChecklistsProvider(const ChecklistListParams()).future);
        fail('expected an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
