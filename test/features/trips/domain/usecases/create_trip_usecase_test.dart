import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/create_trip_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

// Manual Mock for TripRepository
class MockTripRepository implements TripRepository {
  TripModel? _tripToReturn;
  Exception? _exceptionToThrow;
  bool _createTripCalled = false;
  Map<String, dynamic>? _lastCallParams;

  void setupCreateTrip(TripModel trip) {
    _tripToReturn = trip;
  }

  void setupCreateTripToThrow(Exception exception) {
    _exceptionToThrow = exception;
  }

  bool get wasCreateTripCalled => _createTripCalled;
  Map<String, dynamic>? get lastCallParams => _lastCallParams;

  void reset() {
    _tripToReturn = null;
    _exceptionToThrow = null;
    _createTripCalled = false;
    _lastCallParams = null;
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
  }) async {
    _createTripCalled = true;
    _lastCallParams = {
      'name': name,
      'description': description,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'coverImageUrl': coverImageUrl,
      'cost': cost,
      'currency': currency,
      'isPublic': isPublic,
    };

    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }

    return _tripToReturn!;
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
  Future<bool> toggleFavorite(String tripId) async => throw UnimplementedError();

  @override
  Future<List<String>> getFavoriteTripIds() async => throw UnimplementedError();
}

void main() {
  late CreateTripUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = CreateTripUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('CreateTripUseCase', () {
    final testTrip = TripModel(
      id: 'test-trip-1',
      name: 'Summer Vacation',
      description: 'A great summer trip',
      destination: 'Bali, Indonesia',
      createdBy: 'user-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      startDate: DateTime(2025, 6, 1),
      endDate: DateTime(2025, 6, 10),
      coverImageUrl: null,
    );

    group('Success Cases', () {
      test('should create trip successfully with all fields', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        final result = await useCase(
          name: 'Summer Vacation',
          description: 'A great summer trip',
          destination: 'Bali, Indonesia',
          startDate: DateTime(2025, 6, 1),
          endDate: DateTime(2025, 6, 10),
        );

        // Assert
        expect(result, equals(testTrip));
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['name'], equals('Summer Vacation'));
        expect(mockRepository.lastCallParams?['description'], equals('A great summer trip'));
        expect(mockRepository.lastCallParams?['destination'], equals('Bali, Indonesia'));
      });

      test('should create trip with only required fields (name)', () async {
        // Arrange
        final minimalTrip = TripModel(
          id: 'test-trip-2',
          name: 'Summer Vacation',
          description: null,
          destination: null,
          createdBy: 'user-1',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          startDate: null,
          endDate: null,
          coverImageUrl: null,
        );
        mockRepository.setupCreateTrip(minimalTrip);

        // Act
        final result = await useCase(name: 'Summer Vacation');

        // Assert
        expect(result.name, equals('Summer Vacation'));
        expect(result.description, isNull);
        expect(result.destination, isNull);
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['name'], equals('Summer Vacation'));
        expect(mockRepository.lastCallParams?['description'], isNull);
        expect(mockRepository.lastCallParams?['destination'], isNull);
      });

      test('should trim whitespace from trip name', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        await useCase(name: '  Summer Vacation  ');

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['name'], equals('Summer Vacation'));
      });

      test('should create trip with cover image URL', () async {
        // Arrange
        final tripWithImage = testTrip.copyWith(
          coverImageUrl: 'https://example.com/image.jpg',
        );
        mockRepository.setupCreateTrip(tripWithImage);

        // Act
        final result = await useCase(
          name: 'Summer Vacation',
          coverImageUrl: 'https://example.com/image.jpg',
        );

        // Assert
        expect(result.coverImageUrl, equals('https://example.com/image.jpg'));
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['coverImageUrl'],
            equals('https://example.com/image.jpg'));
      });

      test('should create trip with cost and currency', () async {
        // Arrange
        final tripWithCost = testTrip.copyWith(
          cost: 50000.0,
          currency: 'INR',
        );
        mockRepository.setupCreateTrip(tripWithCost);

        // Act
        final result = await useCase(
          name: 'Summer Vacation',
          cost: 50000.0,
          currency: 'INR',
        );

        // Assert
        expect(result.cost, equals(50000.0));
        expect(result.currency, equals('INR'));
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['cost'], equals(50000.0));
        expect(mockRepository.lastCallParams?['currency'], equals('INR'));
      });

      test('should create trip with cost only (currency defaults to INR)', () async {
        // Arrange
        final tripWithCost = testTrip.copyWith(
          cost: 1000.0,
        );
        mockRepository.setupCreateTrip(tripWithCost);

        // Act
        final result = await useCase(
          name: 'Summer Vacation',
          cost: 1000.0,
        );

        // Assert
        expect(result.cost, equals(1000.0));
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['cost'], equals(1000.0));
      });

      test('should create trip with zero cost', () async {
        // Arrange
        final tripWithZeroCost = testTrip.copyWith(
          cost: 0.0,
        );
        mockRepository.setupCreateTrip(tripWithZeroCost);

        // Act
        final result = await useCase(
          name: 'Summer Vacation',
          cost: 0.0,
        );

        // Assert
        expect(result.cost, equals(0.0));
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['cost'], equals(0.0));
      });

      test('should create trip without cost (null cost)', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        await useCase(
          name: 'Summer Vacation',
          cost: null,
        );

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['cost'], isNull);
      });

      test('should create public trip by default', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        await useCase(name: 'Summer Vacation');

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['isPublic'], isTrue);
      });

      test('should create private trip when isPublic is false', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        await useCase(name: 'Summer Vacation', isPublic: false);

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['isPublic'], isFalse);
      });
    });

    group('Validation Errors', () {
      test('should throw exception when trip name is empty', () async {
        // Act & Assert
        expect(
          () => useCase(name: ''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip name is required'),
          )),
        );

        expect(mockRepository.wasCreateTripCalled, isFalse);
      });

      test('should throw exception when trip name is only whitespace', () async {
        // Act & Assert
        expect(
          () => useCase(name: '   '),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip name is required'),
          )),
        );

        expect(mockRepository.wasCreateTripCalled, isFalse);
      });

      test('should throw exception when start date is after end date', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'Summer Vacation',
            startDate: DateTime(2025, 6, 10),
            endDate: DateTime(2025, 6, 1),
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('End date must be after start date'),
          )),
        );

        expect(mockRepository.wasCreateTripCalled, isFalse);
      });

      test('should allow start date that equals end date', () async {
        // Arrange - same-day trips should be allowed
        mockRepository.setupCreateTrip(testTrip);

        // Act
        final sameDate = DateTime(2025, 6, 1);
        await useCase(
          name: 'Summer Vacation',
          startDate: sameDate,
          endDate: sameDate,
        );

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
      });

      test('should allow start date without end date', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        await useCase(
          name: 'Summer Vacation',
          startDate: DateTime(2025, 6, 1),
          endDate: null,
        );

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['startDate'], equals(DateTime(2025, 6, 1)));
        expect(mockRepository.lastCallParams?['endDate'], isNull);
      });

      test('should allow end date without start date', () async {
        // Arrange
        mockRepository.setupCreateTrip(testTrip);

        // Act
        await useCase(
          name: 'Summer Vacation',
          startDate: null,
          endDate: DateTime(2025, 6, 10),
        );

        // Assert
        expect(mockRepository.wasCreateTripCalled, isTrue);
        expect(mockRepository.lastCallParams?['startDate'], isNull);
        expect(mockRepository.lastCallParams?['endDate'], equals(DateTime(2025, 6, 10)));
      });

      test('should throw exception when cost is negative', () async {
        // Act & Assert
        expect(
          () => useCase(
            name: 'Summer Vacation',
            cost: -100.0,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cost must be a positive number'),
          )),
        );

        expect(mockRepository.wasCreateTripCalled, isFalse);
      });
    });

    group('Repository Errors', () {
      test('should propagate repository exceptions', () async {
        // Arrange
        mockRepository.setupCreateTripToThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => useCase(name: 'Summer Vacation'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Database error'),
          )),
        );
      });

      test('should propagate network errors from repository', () async {
        // Arrange
        mockRepository.setupCreateTripToThrow(Exception('Network error'));

        // Act & Assert
        try {
          await useCase(name: 'Summer Vacation');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains('Network error'));
        }
      });
    });
  });
}
