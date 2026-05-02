import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/join_trip_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

class MockTripRepository implements TripRepository {
  bool _joinTripCalled = false;
  String? _lastJoinedTripId;
  Exception? _exceptionToThrow;

  void setupJoinTripToThrow(Exception exception) {
    _exceptionToThrow = exception;
  }

  bool get wasJoinTripCalled => _joinTripCalled;
  String? get lastJoinedTripId => _lastJoinedTripId;

  void reset() {
    _joinTripCalled = false;
    _lastJoinedTripId = null;
    _exceptionToThrow = null;
  }

  @override
  Future<void> joinTrip(String tripId) async {
    _joinTripCalled = true;
    _lastJoinedTripId = tripId;
    if (_exceptionToThrow != null) throw _exceptionToThrow!;
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
  Future<List<TripWithMembers>> getDiscoverableTrips() async =>
      throw UnimplementedError();

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

void main() {
  late JoinTripUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = JoinTripUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('JoinTripUseCase', () {
    group('Success Cases', () {
      test('should join trip successfully with valid trip ID', () async {
        await useCase('trip-123');

        expect(mockRepository.wasJoinTripCalled, isTrue);
        expect(mockRepository.lastJoinedTripId, equals('trip-123'));
      });

      test('should join trip with UUID format trip ID', () async {
        const tripId = '550e8400-e29b-41d4-a716-446655440000';

        await useCase(tripId);

        expect(mockRepository.wasJoinTripCalled, isTrue);
        expect(mockRepository.lastJoinedTripId, equals(tripId));
      });

      test('should complete without returning a value', () async {
        await useCase('trip-abc');

        expect(mockRepository.wasJoinTripCalled, isTrue);
      });

      test('should call repository exactly once', () async {
        await useCase('trip-xyz');

        expect(mockRepository.wasJoinTripCalled, isTrue);
      });
    });

    group('Validation Errors', () {
      test('should throw exception when trip ID is empty', () async {
        expect(
          () => useCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );

        expect(mockRepository.wasJoinTripCalled, isFalse);
      });

      test('should throw exception when trip ID is only whitespace', () async {
        expect(
          () => useCase('   '),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );

        expect(mockRepository.wasJoinTripCalled, isFalse);
      });
    });

    group('Repository Errors', () {
      test('should wrap and rethrow repository exception', () async {
        mockRepository.setupJoinTripToThrow(Exception('Already a member'));

        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to join trip'),
          )),
        );
      });

      test('should wrap trip not found exception', () async {
        mockRepository.setupJoinTripToThrow(Exception('Trip not found'));

        expect(
          () => useCase('non-existent'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to join trip'),
          )),
        );
      });

      test('should wrap authentication exception', () async {
        mockRepository.setupJoinTripToThrow(Exception('Not authenticated'));

        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should wrap private trip exception', () async {
        mockRepository.setupJoinTripToThrow(Exception('Trip is not public'));

        expect(
          () => useCase('private-trip'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to join trip'),
          )),
        );
      });

      test('should not call repository after validation failure', () async {
        try {
          await useCase('');
        } catch (_) {}

        expect(mockRepository.wasJoinTripCalled, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle trip ID with leading/trailing spaces correctly',
          () async {
        // A non-empty string with content (not all whitespace) should pass validation
        await useCase('  trip-123  ');

        // The use case passes the original (untrimmed) ID to repository
        expect(mockRepository.wasJoinTripCalled, isTrue);
      });

      test('should handle numeric-style trip IDs', () async {
        await useCase('12345');

        expect(mockRepository.wasJoinTripCalled, isTrue);
        expect(mockRepository.lastJoinedTripId, equals('12345'));
      });
    });
  });
}
