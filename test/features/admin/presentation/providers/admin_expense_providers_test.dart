import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_expense.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_expense_providers.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';

class _StubSupabaseClient extends Mock implements SupabaseClient {}

class _FakeExpenseDataSource extends AdminRemoteDataSource {
  _FakeExpenseDataSource() : super(_StubSupabaseClient());

  List<AdminExpenseModel> expensesToReturn = const [];
  Object? expensesError;
  final List<Map<String, dynamic>> getAllExpensesCalls = [];

  AdminExpenseStatsModel? statsToReturn;
  Object? statsError;
  int statsCalls = 0;

  @override
  Future<List<AdminExpenseModel>> getAllExpenses({
    int limit = 50,
    int offset = 0,
    String? search,
    String? category,
    String? tripId,
  }) async {
    getAllExpensesCalls.add({
      'limit': limit,
      'offset': offset,
      'search': search,
      'category': category,
      'tripId': tripId,
    });
    if (expensesError != null) throw expensesError!;
    return expensesToReturn;
  }

  @override
  Future<AdminExpenseStatsModel> getExpenseStats() async {
    statsCalls++;
    if (statsError != null) throw statsError!;
    return statsToReturn ??
        const AdminExpenseStatsModel(
          totalExpenses: 0,
          totalAmount: 0,
          totalSettled: 0,
          totalPending: 0,
          settlementRate: 0,
          expensesWithReceipts: 0,
          standaloneExpenses: 0,
          tripExpenses: 0,
          categoryBreakdown: {},
        );
  }
}

AdminExpenseModel _expense(String id) => AdminExpenseModel(
      id: id,
      title: 'Expense $id',
      amount: 100.0,
      currency: 'INR',
      paidBy: 'u1',
      splitType: 'equal',
      createdAt: DateTime(2024, 1, 1),
      splitCount: 0,
      settledCount: 0,
      pendingAmount: 0,
    );

void main() {
  group('admin_expense_providers', () {
    late _FakeExpenseDataSource fake;
    late ProviderContainer container;

    setUp(() {
      fake = _FakeExpenseDataSource();
      container = ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(_StubSupabaseClient()),
        adminRemoteDataSourceProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('adminExpensesProvider returns expenses for default params', () async {
      fake.expensesToReturn = [_expense('e1'), _expense('e2')];
      final list = await container
          .read(adminExpensesProvider(const ExpenseListParams()).future);
      expect(list, hasLength(2));
      expect(list.first.id, 'e1');
      expect(fake.getAllExpensesCalls.single['limit'], 50);
      expect(fake.getAllExpensesCalls.single['offset'], 0);
    });

    test('adminExpensesProvider passes filter params through', () async {
      fake.expensesToReturn = [];
      const params = ExpenseListParams(
        limit: 25,
        offset: 10,
        search: 'lunch',
        category: 'food',
        tripId: 't1',
      );
      await container.read(adminExpensesProvider(params).future);
      final call = fake.getAllExpensesCalls.single;
      expect(call['limit'], 25);
      expect(call['offset'], 10);
      expect(call['search'], 'lunch');
      expect(call['category'], 'food');
      expect(call['tripId'], 't1');
    });

    test('adminExpensesProvider returns empty list', () async {
      fake.expensesToReturn = [];
      final list = await container
          .read(adminExpensesProvider(const ExpenseListParams()).future);
      expect(list, isEmpty);
    });

    test('adminExpensesProvider caches per-params', () async {
      fake.expensesToReturn = [];
      const params = ExpenseListParams(limit: 10);
      await container.read(adminExpensesProvider(params).future);
      await container.read(adminExpensesProvider(params).future);
      expect(fake.getAllExpensesCalls.length, 1);
    });

    test('adminExpenseStatsProvider returns stats from datasource', () async {
      fake.statsToReturn = const AdminExpenseStatsModel(
        totalExpenses: 5,
        totalAmount: 500,
        totalSettled: 200,
        totalPending: 300,
        settlementRate: 40.0,
        expensesWithReceipts: 1,
        standaloneExpenses: 2,
        tripExpenses: 3,
        categoryBreakdown: {'food': 3},
      );
      final stats = await container.read(adminExpenseStatsProvider.future);
      expect(stats.totalExpenses, 5);
      expect(stats.totalAmount, 500);
      expect(stats.settlementRate, 40.0);
      expect(fake.statsCalls, 1);
    });

    test('adminExpenseRepositoryProvider returns the same datasource instance',
        () {
      final repo = container.read(adminExpenseRepositoryProvider);
      expect(repo, same(fake));
    });
  });
}
