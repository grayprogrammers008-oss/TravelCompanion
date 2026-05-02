import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_discoverable_trips_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

class MockTripRepository implements TripRepository {
  List<TripWithMembers>? _tripsToReturn;
  Exception? _exceptionToThrow;
  bool _getDiscoverableTripsCalled = false;

  void setupGetDiscoverableTrips(List<TripWithMembers> trips) {
    _tripsToReturn = trips;
    _exceptionToThrow = null;
  }

  void setupGetDiscoverableTripsToThrow(Exception exception) {
    _exceptionToThrow = exception;
    _tripsToReturn = null;
  }

  bool get wasGetDiscoverableTripsCalled => _getDiscoverableTripsCalled;

  void reset() {
    _tripsToReturn = null;
    _exceptionToThrow = null;
    _getDiscoverableTripsCalled = false;
  }

  @override
  Future<List<TripWithMembers>> getDiscoverableTrips() async {
    _getDiscoverableTripsCalled = true;
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
    return _tripsToReturn!;
  }

  @override
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    double? cost,
    String? currency,
    bool isPublic = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<TripModel> updateTrip({
    required String tripId,
    String? name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    double? cost,
    String? currency,
    bool? isPublic,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteTrip(String tripId) async => throw UnimplementedError();

  @override
  Future<List<TripWithMembers>> getUserTrips() async =>
      throw UnimplementedError();

  @override
  Stream<List<TripWithMembers>> watchUserTrips() => throw UnimplementedError();

  @override
  Future<TripWithMembers> getTripById(String tripId) async =>
      throw UnimplementedError();

  @override
  Stream<TripWithMembers> watchTrip(String tripId) =>
      throw UnimplementedError();

  @override
  Future<List<TripMemberModel>> getTripMembers(String tripId) async =>
      throw UnimplementedError();

  @override
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UserTravelStats> getUserStats() async => throw UnimplementedError();

  @override
  Stream<UserTravelStats> watchUserStats() => throw UnimplementedError();

  @override
  Future<void> joinTrip(String tripId) async => throw UnimplementedError();

  @override
  Future<String> copyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> toggleFavorite(String tripId) async =>
      throw UnimplementedError();

  @override
  Future<List<String>> getFavoriteTripIds() async =>
      throw UnimplementedError();
}

TripWithMembers _makePublicTrip({
  required String id,
  required String name,
  String destination = 'Test City',
  String createdBy = 'other-user',
}) {
  final now = DateTime(2025, 1, 1);
  return TripWithMembers(
    trip: TripModel(
      id: id,
      name: name,
      destination: destination,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      isPublic: true,
    ),
    members: [
      TripMemberModel(
        id: 'member-$id',
        tripId: id,
        userId: createdBy,
        role: 'admin',
        joinedAt: now,
      ),
    ],
  );
}

void main() {
  late GetDiscoverableTripsUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = GetDiscoverableTripsUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('GetDiscoverableTripsUseCase', () {
    group('Success Cases', () {
      test('should return list of discoverable trips', () async {
        final trips = [
          _makePublicTrip(id: 'trip-1', name: 'Goa Beach Trip'),
          _makePublicTrip(id: 'trip-2', name: 'Manali Snow Trek'),
          _makePublicTrip(id: 'trip-3', name: 'Ladakh Road Trip'),
        ];
        mockRepository.setupGetDiscoverableTrips(trips);

        final result = await useCase();

        expect(result.length, equals(3));
        expect(result[0].trip.name, equals('Goa Beach Trip'));
        expect(result[1].trip.name, equals('Manali Snow Trek'));
        expect(result[2].trip.name, equals('Ladakh Road Trip'));
        expect(mockRepository.wasGetDiscoverableTripsCalled, isTrue);
      });

      test('should return empty list when no trips are available', () async {
        mockRepository.setupGetDiscoverableTrips([]);

        final result = await useCase();

        expect(result, isEmpty);
        expect(mockRepository.wasGetDiscoverableTripsCalled, isTrue);
      });

      test('should return single trip', () async {
        final trips = [_makePublicTrip(id: 'solo', name: 'Solo Adventure')];
        mockRepository.setupGetDiscoverableTrips(trips);

        final result = await useCase();

        expect(result.length, equals(1));
        expect(result[0].trip.id, equals('solo'));
      });

      test('should preserve trip order returned by repository', () async {
        final trips = [
          _makePublicTrip(id: 'z', name: 'Z Trip'),
          _makePublicTrip(id: 'a', name: 'A Trip'),
          _makePublicTrip(id: 'm', name: 'M Trip'),
        ];
        mockRepository.setupGetDiscoverableTrips(trips);

        final result = await useCase();

        expect(result[0].trip.id, equals('z'));
        expect(result[1].trip.id, equals('a'));
        expect(result[2].trip.id, equals('m'));
      });

      test('should return trips with their members', () async {
        final now = DateTime(2025, 1, 1);
        final trip = TripWithMembers(
          trip: TripModel(
            id: 'group-trip',
            name: 'Group Trek',
            createdBy: 'user-1',
            createdAt: now,
            isPublic: true,
          ),
          members: [
            TripMemberModel(
                id: 'm1',
                tripId: 'group-trip',
                userId: 'user-1',
                role: 'admin',
                joinedAt: now),
            TripMemberModel(
                id: 'm2',
                tripId: 'group-trip',
                userId: 'user-2',
                role: 'member',
                joinedAt: now),
            TripMemberModel(
                id: 'm3',
                tripId: 'group-trip',
                userId: 'user-3',
                role: 'member',
                joinedAt: now),
          ],
        );
        mockRepository.setupGetDiscoverableTrips([trip]);

        final result = await useCase();

        expect(result[0].members.length, equals(3));
      });

      test('should handle large list of discoverable trips', () async {
        final trips = List.generate(
          100,
          (i) => _makePublicTrip(id: 'trip-$i', name: 'Trip $i'),
        );
        mockRepository.setupGetDiscoverableTrips(trips);

        final result = await useCase();

        expect(result.length, equals(100));
      });

      test('should return trips with destination info', () async {
        final trips = [
          _makePublicTrip(
              id: 't1', name: 'Beach Trip', destination: 'Goa, India'),
          _makePublicTrip(
              id: 't2', name: 'Hill Trip', destination: 'Manali, India'),
        ];
        mockRepository.setupGetDiscoverableTrips(trips);

        final result = await useCase();

        expect(result[0].trip.destination, equals('Goa, India'));
        expect(result[1].trip.destination, equals('Manali, India'));
      });
    });

    group('Error Cases', () {
      test('should wrap and rethrow repository exception', () async {
        mockRepository
            .setupGetDiscoverableTripsToThrow(Exception('Network error'));

        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get discoverable trips'),
          )),
        );
      });

      test('should wrap authentication error', () async {
        mockRepository
            .setupGetDiscoverableTripsToThrow(Exception('Not authenticated'));

        expect(
          () => useCase(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get discoverable trips'),
          )),
        );
      });

      test('should wrap database error', () async {
        mockRepository
            .setupGetDiscoverableTripsToThrow(Exception('Database unavailable'));

        expect(
          () => useCase(),
          throwsA(isA<Exception>()),
        );
      });

      test('should still call repository before wrapping exception', () async {
        mockRepository.setupGetDiscoverableTripsToThrow(Exception('Error'));

        try {
          await useCase();
        } catch (_) {}

        expect(mockRepository.wasGetDiscoverableTripsCalled, isTrue);
      });
    });

    group('Data Integrity', () {
      test('should return all trip fields intact', () async {
        final startDate = DateTime(2025, 6, 1);
        final endDate = DateTime(2025, 6, 10);
        final createdAt = DateTime(2025, 5, 1);
        final trip = TripWithMembers(
          trip: TripModel(
            id: 'full-trip',
            name: 'Full Data Trip',
            description: 'A trip with all fields',
            destination: 'Bali, Indonesia',
            startDate: startDate,
            endDate: endDate,
            coverImageUrl: 'https://example.com/cover.jpg',
            createdBy: 'user-99',
            createdAt: createdAt,
            isPublic: true,
            cost: 50000.0,
            currency: 'INR',
          ),
          members: [],
        );
        mockRepository.setupGetDiscoverableTrips([trip]);

        final result = await useCase();

        final returnedTrip = result[0].trip;
        expect(returnedTrip.id, equals('full-trip'));
        expect(returnedTrip.name, equals('Full Data Trip'));
        expect(returnedTrip.description, equals('A trip with all fields'));
        expect(returnedTrip.destination, equals('Bali, Indonesia'));
        expect(returnedTrip.startDate, equals(startDate));
        expect(returnedTrip.endDate, equals(endDate));
        expect(returnedTrip.coverImageUrl,
            equals('https://example.com/cover.jpg'));
        expect(returnedTrip.cost, equals(50000.0));
        expect(returnedTrip.currency, equals('INR'));
        expect(returnedTrip.isPublic, isTrue);
      });

      test('should handle trips with null optional fields', () async {
        final trip = TripWithMembers(
          trip: TripModel(
            id: 'minimal',
            name: 'Minimal Trip',
            createdBy: 'user-1',
            createdAt: DateTime(2025, 1, 1),
            description: null,
            destination: null,
            startDate: null,
            endDate: null,
            coverImageUrl: null,
            isPublic: true,
          ),
          members: [],
        );
        mockRepository.setupGetDiscoverableTrips([trip]);

        final result = await useCase();

        expect(result[0].trip.description, isNull);
        expect(result[0].trip.destination, isNull);
        expect(result[0].trip.startDate, isNull);
        expect(result[0].trip.endDate, isNull);
        expect(result[0].trip.coverImageUrl, isNull);
      });
    });
  });
}
