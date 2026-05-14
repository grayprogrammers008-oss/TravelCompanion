import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathio/core/providers/supabase_provider.dart';
import 'package:pathio/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:pathio/features/admin/domain/entities/admin_trip.dart';
import 'package:pathio/features/admin/presentation/providers/admin_providers.dart';
import 'package:pathio/features/admin/presentation/providers/admin_trip_providers.dart';

class _StubSupabaseClient extends Mock implements SupabaseClient {}

class _FakeTripDataSource extends AdminRemoteDataSource {
  _FakeTripDataSource() : super(_StubSupabaseClient());

  List<AdminTripModel> tripsToReturn = const [];
  Object? error;
  final List<Map<String, dynamic>> getAllTripsCalls = [];

  bool deleteResult = true;
  bool updateResult = true;
  final List<String> deleteCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<List<AdminTripModel>> getAllTrips({
    int limit = 50,
    int offset = 0,
    String? search,
    String? status,
  }) async {
    getAllTripsCalls.add({
      'limit': limit,
      'offset': offset,
      'search': search,
      'status': status,
    });
    if (error != null) throw error!;
    return tripsToReturn;
  }

  @override
  Future<bool> deleteTrip(String tripId) async {
    deleteCalls.add(tripId);
    return deleteResult;
  }

  @override
  Future<bool> updateTrip(
    String tripId, {
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? currency,
    bool? isCompleted,
  }) async {
    updateCalls.add({
      'tripId': tripId,
      'name': name,
      'description': description,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'budget': budget,
      'currency': currency,
      'isCompleted': isCompleted,
    });
    return updateResult;
  }
}

void main() {
  group('admin_trip_providers', () {
    late _FakeTripDataSource fake;
    late ProviderContainer container;

    setUp(() {
      fake = _FakeTripDataSource();
      container = ProviderContainer(overrides: [
        supabaseClientProvider.overrideWithValue(_StubSupabaseClient()),
        adminRemoteDataSourceProvider.overrideWithValue(fake),
      ]);
    });

    tearDown(() => container.dispose());

    test('adminTripsProvider returns trips with default params', () async {
      fake.tripsToReturn = const [
        AdminTripModel(
          id: 't1',
          name: 'Trip 1',
          createdBy: 'u1',
          creatorName: 'A',
          creatorEmail: 'a@a.com',
        ),
      ];
      final trips =
          await container.read(adminTripsProvider(const TripListParams()).future);
      expect(trips, hasLength(1));
      expect(trips.first.id, 't1');
      expect(fake.getAllTripsCalls.single['limit'], 50);
      expect(fake.getAllTripsCalls.single['offset'], 0);
    });

    test('adminTripsProvider passes through filter params', () async {
      fake.tripsToReturn = const [];
      const params = TripListParams(
        limit: 25,
        offset: 5,
        search: 'beach',
        status: 'completed',
      );
      await container.read(adminTripsProvider(params).future);
      final call = fake.getAllTripsCalls.single;
      expect(call['limit'], 25);
      expect(call['offset'], 5);
      expect(call['search'], 'beach');
      expect(call['status'], 'completed');
    });

    test('adminTripsProvider returns empty list when datasource returns empty',
        () async {
      fake.tripsToReturn = [];
      final trips = await container
          .read(adminTripsProvider(const TripListParams()).future);
      expect(trips, isEmpty);
    });

    test('adminTripsProvider propagates errors',
        skip:
            'Riverpod 3.x: .future on a FutureProvider.family with a throwing override hangs indefinitely instead of completing as a rejected future. Same skip as elsewhere in this codebase.',
        () async {
      fake.error = Exception('failed');
      try {
        await container.read(adminTripsProvider(const TripListParams()).future);
        fail('expected an exception');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('adminTripRepositoryProvider returns the same datasource instance',
        () {
      final repo = container.read(adminTripRepositoryProvider);
      expect(repo, same(fake));
    });

    test('adminTripRepositoryProvider exposes deleteTrip', () async {
      final repo = container.read(adminTripRepositoryProvider);
      final result = await repo.deleteTrip('t1');
      expect(result, true);
      expect(fake.deleteCalls.single, 't1');
    });

    test('adminTripRepositoryProvider exposes updateTrip with passed args',
        () async {
      final repo = container.read(adminTripRepositoryProvider);
      final result = await repo.updateTrip(
        't1',
        name: 'New',
        budget: 1234.5,
        currency: 'USD',
        isCompleted: true,
      );
      expect(result, true);
      final call = fake.updateCalls.single;
      expect(call['tripId'], 't1');
      expect(call['name'], 'New');
      expect(call['budget'], 1234.5);
      expect(call['currency'], 'USD');
      expect(call['isCompleted'], true);
    });

    test('adminTripsProvider caches per-params (same params reused)', () async {
      fake.tripsToReturn = const [];
      const params = TripListParams(limit: 10);

      await container.read(adminTripsProvider(params).future);
      await container.read(adminTripsProvider(params).future);

      // Riverpod family caches per equal params, so only one call.
      expect(fake.getAllTripsCalls.length, 1);
    });
  });
}
