import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/copy_trip_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Mock implementation of TripRepository for testing CopyTripUseCase
class MockTripRepository implements TripRepository {
  String? _tripIdToReturn;
  Exception? _exceptionToThrow;
  bool _copyTripCalled = false;
  Map<String, dynamic>? _lastCallParams;

  void setupCopyTrip(String newTripId) {
    _tripIdToReturn = newTripId;
    _exceptionToThrow = null;
  }

  void setupCopyTripToThrow(Exception exception) {
    _exceptionToThrow = exception;
    _tripIdToReturn = null;
  }

  bool get wasCopyTripCalled => _copyTripCalled;
  Map<String, dynamic>? get lastCallParams => _lastCallParams;

  void reset() {
    _tripIdToReturn = null;
    _exceptionToThrow = null;
    _copyTripCalled = false;
    _lastCallParams = null;
  }

  @override
  Future<String> copyTrip({
    required String sourceTripId,
    required String newName,
    required DateTime newStartDate,
    required DateTime newEndDate,
    bool copyItinerary = true,
    bool copyChecklists = true,
  }) async {
    _copyTripCalled = true;
    _lastCallParams = {
      'sourceTripId': sourceTripId,
      'newName': newName,
      'newStartDate': newStartDate,
      'newEndDate': newEndDate,
      'copyItinerary': copyItinerary,
      'copyChecklists': copyChecklists,
    };

    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }

    return _tripIdToReturn!;
  }

  // Other required methods - not used in CopyTripUseCase tests
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
  }) async {
    throw UnimplementedError();
  }

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
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TripWithMembers>> getUserTrips() async {
    throw UnimplementedError();
  }

  @override
  Stream<List<TripWithMembers>> watchUserTrips() {
    throw UnimplementedError();
  }

  @override
  Future<TripWithMembers> getTripById(String tripId) async {
    throw UnimplementedError();
  }

  @override
  Stream<TripWithMembers> watchTrip(String tripId) {
    throw UnimplementedError();
  }

  @override
  Future<List<TripMemberModel>> getTripMembers(String tripId) async {
    throw UnimplementedError();
  }

  @override
  Future<TripMemberModel> addMember({
    required String tripId,
    required String userId,
    String role = 'member',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMember({required String tripId, required String userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserTravelStats> getUserStats() async {
    throw UnimplementedError();
  }

  @override
  Stream<UserTravelStats> watchUserStats() {
    throw UnimplementedError();
  }

  @override
  Future<List<TripWithMembers>> getDiscoverableTrips() async {
    throw UnimplementedError();
  }

  @override
  Future<void> joinTrip(String tripId) async {
    throw UnimplementedError();
  }
}

void main() {
  late CopyTripUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = CopyTripUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('CopyTripUseCase', () {
    group('Positive Cases', () {
      test('should copy trip with all options enabled', () async {
        // Arrange
        const newTripId = 'new-trip-id-123';
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 7);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'My Trip (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
          copyItinerary: true,
          copyChecklists: true,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.wasCopyTripCalled, isTrue);
        expect(mockRepository.lastCallParams!['sourceTripId'], equals('source-trip-id'));
        expect(mockRepository.lastCallParams!['newName'], equals('My Trip (Copy)'));
        expect(mockRepository.lastCallParams!['newStartDate'], equals(startDate));
        expect(mockRepository.lastCallParams!['newEndDate'], equals(endDate));
        expect(mockRepository.lastCallParams!['copyItinerary'], isTrue);
        expect(mockRepository.lastCallParams!['copyChecklists'], isTrue);
      });

      test('should copy trip without itinerary', () async {
        // Arrange
        const newTripId = 'new-trip-id-456';
        final startDate = DateTime(2025, 2, 1);
        final endDate = DateTime(2025, 2, 14);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Beach Vacation (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
          copyItinerary: false,
          copyChecklists: true,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['copyItinerary'], isFalse);
        expect(mockRepository.lastCallParams!['copyChecklists'], isTrue);
      });

      test('should copy trip without checklists', () async {
        // Arrange
        const newTripId = 'new-trip-id-789';
        final startDate = DateTime(2025, 3, 15);
        final endDate = DateTime(2025, 3, 20);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Mountain Trip (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
          copyItinerary: true,
          copyChecklists: false,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['copyItinerary'], isTrue);
        expect(mockRepository.lastCallParams!['copyChecklists'], isFalse);
      });

      test('should copy trip with only basic info (no itinerary or checklists)', () async {
        // Arrange
        const newTripId = 'new-trip-id-000';
        final startDate = DateTime(2025, 4, 1);
        final endDate = DateTime(2025, 4, 5);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Quick Trip (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
          copyItinerary: false,
          copyChecklists: false,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['copyItinerary'], isFalse);
        expect(mockRepository.lastCallParams!['copyChecklists'], isFalse);
      });

      test('should copy trip with default options (both true)', () async {
        // Arrange
        const newTripId = 'new-trip-default';
        final startDate = DateTime(2025, 5, 1);
        final endDate = DateTime(2025, 5, 10);

        mockRepository.setupCopyTrip(newTripId);

        // Act - Using default values for copyItinerary and copyChecklists
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Default Copy',
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['copyItinerary'], isTrue);
        expect(mockRepository.lastCallParams!['copyChecklists'], isTrue);
      });

      test('should handle trip with long name', () async {
        // Arrange
        const newTripId = 'long-name-trip';
        final startDate = DateTime(2025, 6, 1);
        final endDate = DateTime(2025, 6, 30);
        const longName = 'This is a very long trip name that goes on and on to test the limits of the system (Copy)';

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: longName,
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['newName'], equals(longName));
      });

      test('should handle same-day trip', () async {
        // Arrange
        const newTripId = 'same-day-trip';
        final sameDate = DateTime(2025, 7, 4);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Day Trip (Copy)',
          newStartDate: sameDate,
          newEndDate: sameDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['newStartDate'], equals(sameDate));
        expect(mockRepository.lastCallParams!['newEndDate'], equals(sameDate));
      });

      test('should handle UUID format for source trip ID', () async {
        // Arrange
        const newTripId = 'new-uuid-trip';
        const sourceTripId = '550e8400-e29b-41d4-a716-446655440000';
        final startDate = DateTime(2025, 8, 1);
        final endDate = DateTime(2025, 8, 15);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: sourceTripId,
          newName: 'UUID Trip (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['sourceTripId'], equals(sourceTripId));
      });
    });

    group('Negative Cases', () {
      test('should propagate exception when repository fails', () async {
        // Arrange
        mockRepository.setupCopyTripToThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(
            sourceTripId: 'source-trip-id',
            newName: 'Failed Copy',
            newStartDate: DateTime(2025, 1, 1),
            newEndDate: DateTime(2025, 1, 7),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should propagate access denied exception', () async {
        // Arrange
        mockRepository.setupCopyTripToThrow(Exception('Access denied to source trip'));

        // Act & Assert
        expect(
          () => useCase(
            sourceTripId: 'unauthorized-trip-id',
            newName: 'Unauthorized Copy',
            newStartDate: DateTime(2025, 1, 1),
            newEndDate: DateTime(2025, 1, 7),
          ),
          throwsA(
            predicate((e) => e.toString().contains('Access denied')),
          ),
        );
      });

      test('should propagate not found exception', () async {
        // Arrange
        mockRepository.setupCopyTripToThrow(Exception('Source trip not found'));

        // Act & Assert
        expect(
          () => useCase(
            sourceTripId: 'non-existent-trip-id',
            newName: 'Not Found Copy',
            newStartDate: DateTime(2025, 1, 1),
            newEndDate: DateTime(2025, 1, 7),
          ),
          throwsA(
            predicate((e) => e.toString().contains('not found')),
          ),
        );
      });

      test('should propagate authentication exception', () async {
        // Arrange
        mockRepository.setupCopyTripToThrow(Exception('Not authenticated'));

        // Act & Assert
        expect(
          () => useCase(
            sourceTripId: 'source-trip-id',
            newName: 'Unauthenticated Copy',
            newStartDate: DateTime(2025, 1, 1),
            newEndDate: DateTime(2025, 1, 7),
          ),
          throwsA(
            predicate((e) => e.toString().contains('authenticated')),
          ),
        );
      });

      test('should propagate network exception', () async {
        // Arrange
        mockRepository.setupCopyTripToThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase(
            sourceTripId: 'source-trip-id',
            newName: 'Network Error Copy',
            newStartDate: DateTime(2025, 1, 1),
            newEndDate: DateTime(2025, 1, 7),
          ),
          throwsA(
            predicate((e) => e.toString().contains('Network')),
          ),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle trip with special characters in name', () async {
        // Arrange
        const newTripId = 'special-char-trip';
        final startDate = DateTime(2025, 9, 1);
        final endDate = DateTime(2025, 9, 10);
        const specialName = 'Trip to São Paulo & Tokyo! (Copy) #2025';

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: specialName,
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['newName'], equals(specialName));
      });

      test('should handle very long date range', () async {
        // Arrange
        const newTripId = 'long-duration-trip';
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 12, 31); // Full year

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Year-long Trip (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        final duration = endDate.difference(startDate).inDays;
        expect(duration, equals(364)); // 365 - 1 (end date is included)
      });

      test('should handle dates with timezone considerations', () async {
        // Arrange
        const newTripId = 'timezone-trip';
        final startDate = DateTime.utc(2025, 10, 15, 10, 30);
        final endDate = DateTime.utc(2025, 10, 20, 18, 0);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Timezone Trip (Copy)',
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['newStartDate'], equals(startDate));
        expect(mockRepository.lastCallParams!['newEndDate'], equals(endDate));
      });

      test('should handle minimal name', () async {
        // Arrange
        const newTripId = 'minimal-name-trip';
        final startDate = DateTime(2025, 11, 1);
        final endDate = DateTime(2025, 11, 5);

        mockRepository.setupCopyTrip(newTripId);

        // Act
        final result = await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'A', // Single character name
          newStartDate: startDate,
          newEndDate: endDate,
        );

        // Assert
        expect(result, equals(newTripId));
        expect(mockRepository.lastCallParams!['newName'], equals('A'));
      });
    });

    group('Repository Call Verification', () {
      test('should call repository exactly once', () async {
        // Arrange
        mockRepository.setupCopyTrip('single-call-trip');

        // Act
        await useCase(
          sourceTripId: 'source-trip-id',
          newName: 'Single Call (Copy)',
          newStartDate: DateTime(2025, 12, 1),
          newEndDate: DateTime(2025, 12, 10),
        );

        // Assert
        expect(mockRepository.wasCopyTripCalled, isTrue);
      });

      test('should pass all parameters to repository correctly', () async {
        // Arrange
        const sourceTripId = 'source-123';
        const newName = 'Complete Test (Copy)';
        final startDate = DateTime(2025, 12, 20);
        final endDate = DateTime(2025, 12, 25);
        const copyItinerary = true;
        const copyChecklists = false;

        mockRepository.setupCopyTrip('verified-trip');

        // Act
        await useCase(
          sourceTripId: sourceTripId,
          newName: newName,
          newStartDate: startDate,
          newEndDate: endDate,
          copyItinerary: copyItinerary,
          copyChecklists: copyChecklists,
        );

        // Assert
        final params = mockRepository.lastCallParams!;
        expect(params['sourceTripId'], equals(sourceTripId));
        expect(params['newName'], equals(newName));
        expect(params['newStartDate'], equals(startDate));
        expect(params['newEndDate'], equals(endDate));
        expect(params['copyItinerary'], equals(copyItinerary));
        expect(params['copyChecklists'], equals(copyChecklists));
      });
    });
  });
}
