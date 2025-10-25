import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/update_trip_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

// Manual Mock for TripRepository
class MockTripRepository implements TripRepository {
  TripModel? _tripToReturn;
  Exception? _exceptionToThrow;
  bool _updateTripCalled = false;
  Map<String, dynamic>? _lastCallParams;

  void setupUpdateTrip(TripModel trip) {
    _tripToReturn = trip;
  }

  void setupUpdateTripToThrow(Exception exception) {
    _exceptionToThrow = exception;
  }

  bool get wasUpdateTripCalled => _updateTripCalled;
  Map<String, dynamic>? get lastCallParams => _lastCallParams;

  void reset() {
    _tripToReturn = null;
    _exceptionToThrow = null;
    _updateTripCalled = false;
    _lastCallParams = null;
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
  }) async {
    _updateTripCalled = true;
    _lastCallParams = {
      'tripId': tripId,
      'name': name,
      'description': description,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'coverImageUrl': coverImageUrl,
    };

    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }

    return _tripToReturn!;
  }

  @override
  Future<TripModel> createTrip({
    required String name,
    String? description,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
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
  Future<TripWithMembers> getTripById(String tripId) async {
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
  Future<void> removeMember({
    required String tripId,
    required String userId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<TripWithMembers> watchTrip(String tripId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<TripWithMembers>> watchUserTrips() {
    throw UnimplementedError();
  }
}

void main() {
  late UpdateTripUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = UpdateTripUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('UpdateTripUseCase', () {
    final testTrip = TripModel(
      id: 'test-trip-1',
      name: 'Updated Summer Vacation',
      description: 'Updated description',
      destination: 'Updated Bali, Indonesia',
      createdBy: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 2),
      startDate: DateTime(2025, 6, 5),
      endDate: DateTime(2025, 6, 15),
      coverImageUrl: null,
    );

    group('Success Cases', () {
      test('should update trip successfully with all fields', () async {
        // Arrange
        mockRepository.setupUpdateTrip(testTrip);

        // Act
        final result = await useCase(
          tripId: 'test-trip-1',
          name: 'Updated Summer Vacation',
          description: 'Updated description',
          destination: 'Updated Bali, Indonesia',
          startDate: DateTime(2025, 6, 5),
          endDate: DateTime(2025, 6, 15),
        );

        // Assert
        expect(result, equals(testTrip));
        expect(mockRepository.wasUpdateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['tripId'], equals('test-trip-1'));
        expect(mockRepository.lastCallParams?['name'], equals('Updated Summer Vacation'));
        expect(mockRepository.lastCallParams?['description'], equals('Updated description'));
        expect(mockRepository.lastCallParams?['destination'], equals('Updated Bali, Indonesia'));
      });

      test('should update only name', () async {
        // Arrange
        mockRepository.setupUpdateTrip(testTrip);

        // Act
        await useCase(
          tripId: 'test-trip-1',
          name: 'Updated Summer Vacation',
        );

        // Assert
        expect(mockRepository.wasUpdateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['tripId'], equals('test-trip-1'));
        expect(mockRepository.lastCallParams?['name'], equals('Updated Summer Vacation'));
        expect(mockRepository.lastCallParams?['description'], isNull);
        expect(mockRepository.lastCallParams?['destination'], isNull);
      });

      test('should update only description', () async {
        // Arrange
        mockRepository.setupUpdateTrip(testTrip);

        // Act
        await useCase(
          tripId: 'test-trip-1',
          description: 'New description',
        );

        // Assert
        expect(mockRepository.wasUpdateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['tripId'], equals('test-trip-1'));
        expect(mockRepository.lastCallParams?['name'], isNull);
        expect(mockRepository.lastCallParams?['description'], equals('New description'));
      });

      test('should update only dates', () async {
        // Arrange
        mockRepository.setupUpdateTrip(testTrip);

        // Act
        await useCase(
          tripId: 'test-trip-1',
          startDate: DateTime(2025, 7, 1),
          endDate: DateTime(2025, 7, 10),
        );

        // Assert
        expect(mockRepository.wasUpdateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['startDate'], equals(DateTime(2025, 7, 1)));
        expect(mockRepository.lastCallParams?['endDate'], equals(DateTime(2025, 7, 10)));
      });

      test('should update cover image URL', () async {
        // Arrange
        final tripWithImage = testTrip.copyWith(
          coverImageUrl: 'https://example.com/new-image.jpg',
        );
        mockRepository.setupUpdateTrip(tripWithImage);

        // Act
        final result = await useCase(
          tripId: 'test-trip-1',
          coverImageUrl: 'https://example.com/new-image.jpg',
        );

        // Assert
        expect(result.coverImageUrl, equals('https://example.com/new-image.jpg'));
        expect(mockRepository.wasUpdateTripCalled, isTrue);
      });
    });

    group('Validation Errors', () {
      test('should throw exception when trip ID is empty', () async {
        // Act & Assert
        expect(
          () => useCase(tripId: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );

        expect(mockRepository.wasUpdateTripCalled, isFalse);
      });

      test('should throw exception when trip ID is only whitespace', () async {
        // Act & Assert
        expect(
          () => useCase(tripId: '   '),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );

        expect(mockRepository.wasUpdateTripCalled, isFalse);
      });

      test('should throw exception when name is empty string', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'test-trip-1',
            name: '',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip name cannot be empty'),
          )),
        );

        expect(mockRepository.wasUpdateTripCalled, isFalse);
      });

      test('should throw exception when name is only whitespace', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'test-trip-1',
            name: '   ',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip name cannot be empty'),
          )),
        );

        expect(mockRepository.wasUpdateTripCalled, isFalse);
      });

      test('should throw exception when start date is after end date', () async {
        // Act & Assert
        expect(
          () => useCase(
            tripId: 'test-trip-1',
            startDate: DateTime(2025, 6, 10),
            endDate: DateTime(2025, 6, 1),
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('End date must be after or equal to start date'),
          )),
        );

        expect(mockRepository.wasUpdateTripCalled, isFalse);
      });

      test('should allow start date that equals end date', () async {
        // Arrange
        mockRepository.setupUpdateTrip(testTrip);

        // Act
        final sameDate = DateTime(2025, 6, 1);
        await useCase(
          tripId: 'test-trip-1',
          startDate: sameDate,
          endDate: sameDate,
        );

        // Assert
        expect(mockRepository.wasUpdateTripCalled, isTrue);
      });

      test('should allow updating with no fields (no-op)', () async {
        // Arrange
        mockRepository.setupUpdateTrip(testTrip);

        // Act
        await useCase(tripId: 'test-trip-1');

        // Assert
        expect(mockRepository.wasUpdateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['name'], isNull);
        expect(mockRepository.lastCallParams?['description'], isNull);
      });
    });

    group('Repository Errors', () {
      test('should propagate repository exceptions', () async {
        // Arrange
        mockRepository.setupUpdateTripToThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(tripId: 'test-trip-1', name: 'Updated Name'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should propagate network errors from repository', () async {
        // Arrange
        mockRepository.setupUpdateTripToThrow(Exception('Network error'));

        // Act & Assert
        try {
          await useCase(tripId: 'test-trip-1', name: 'Updated Name');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('Network error'));
        }
      });

      test('should propagate trip not found errors', () async {
        // Arrange
        mockRepository.setupUpdateTripToThrow(Exception('Trip not found'));

        // Act & Assert
        try {
          await useCase(tripId: 'non-existent-trip', name: 'Updated Name');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('Trip not found'));
        }
      });
    });
  });
}
