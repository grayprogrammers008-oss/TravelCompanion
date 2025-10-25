import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/itinerary_model.dart';
import 'package:travel_crew/features/itinerary/domain/repositories/itinerary_repository.dart';
import 'package:travel_crew/features/itinerary/domain/usecases/create_itinerary_item_usecase.dart';

// Manual Mock Repository
class MockItineraryRepository implements ItineraryRepository {
  ItineraryItemModel? _itemToReturn;
  Exception? _exceptionToThrow;
  bool _createCalled = false;
  Map<String, dynamic>? _lastCallParams;

  // Setup methods
  void setupCreateItem(ItineraryItemModel item) {
    _itemToReturn = item;
    _exceptionToThrow = null;
  }

  void setupCreateToThrow(Exception e) {
    _exceptionToThrow = e;
    _itemToReturn = null;
  }

  // Verification
  bool get wasCreateCalled => _createCalled;
  Map<String, dynamic>? get lastCallParams => _lastCallParams;

  // Reset
  void reset() {
    _itemToReturn = null;
    _exceptionToThrow = null;
    _createCalled = false;
    _lastCallParams = null;
  }

  @override
  Future<ItineraryItemModel> createItineraryItem({
    required String tripId,
    required String title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int orderIndex = 0,
  }) async {
    _createCalled = true;
    _lastCallParams = {
      'tripId': tripId,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
      'dayNumber': dayNumber,
      'orderIndex': orderIndex,
    };

    if (_exceptionToThrow != null) {
      throw _exceptionToThrow!;
    }

    return _itemToReturn!;
  }

  // Other methods throw UnimplementedError
  @override
  Future<void> deleteItineraryItem(String itemId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItineraryItemModel>> getDayItinerary({
    required String tripId,
    required int dayNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItineraryDay>> getItineraryByDays(String tripId) {
    throw UnimplementedError();
  }

  @override
  Future<ItineraryItemModel> getItineraryItem(String itemId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItineraryItemModel>> getTripItinerary(String tripId) {
    throw UnimplementedError();
  }

  @override
  Future<void> moveItemToDay({
    required String itemId,
    required int newDayNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> reorderItems({
    required String tripId,
    required int dayNumber,
    required List<String> itemIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ItineraryItemModel> updateItineraryItem({
    required String itemId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? dayNumber,
    int? orderIndex,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ItineraryItemModel>> watchTripItinerary(String tripId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ItineraryDay>> watchItineraryByDays(String tripId) {
    throw UnimplementedError();
  }
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
    final testItem = ItineraryItemModel(
      id: 'test-id',
      tripId: 'trip-123',
      title: 'Visit Eiffel Tower',
      description: 'Amazing landmark',
      location: 'Paris, France',
      startTime: DateTime(2024, 1, 1, 10, 0),
      endTime: DateTime(2024, 1, 1, 12, 0),
      dayNumber: 1,
      orderIndex: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'user-123',
    );

    test('should create item with all fields successfully', () async {
      // Arrange
      mockRepository.setupCreateItem(testItem);

      // Act
      final result = await useCase(
        tripId: 'trip-123',
        title: 'Visit Eiffel Tower',
        description: 'Amazing landmark',
        location: 'Paris, France',
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 12, 0),
        dayNumber: 1,
        orderIndex: 0,
      );

      // Assert
      expect(result, equals(testItem));
      expect(mockRepository.wasCreateCalled, isTrue);
      expect(mockRepository.lastCallParams?['tripId'], equals('trip-123'));
      expect(mockRepository.lastCallParams?['title'], equals('Visit Eiffel Tower'));
      expect(mockRepository.lastCallParams?['description'], equals('Amazing landmark'));
    });

    test('should create item with minimal required fields', () async {
      // Arrange
      final minimalItem = testItem.copyWith(
        description: null,
        location: null,
        startTime: null,
        endTime: null,
      );
      mockRepository.setupCreateItem(minimalItem);

      // Act
      final result = await useCase(
        tripId: 'trip-123',
        title: 'Visit Eiffel Tower',
      );

      // Assert
      expect(result, equals(minimalItem));
      expect(mockRepository.wasCreateCalled, isTrue);
    });

    test('should trim whitespace from title', () async {
      // Arrange
      mockRepository.setupCreateItem(testItem);

      // Act
      await useCase(
        tripId: 'trip-123',
        title: '  Visit Eiffel Tower  ',
      );

      // Assert
      expect(mockRepository.lastCallParams?['title'], equals('Visit Eiffel Tower'));
    });

    test('should trim whitespace from description', () async {
      // Arrange
      mockRepository.setupCreateItem(testItem);

      // Act
      await useCase(
        tripId: 'trip-123',
        title: 'Visit Eiffel Tower',
        description: '  Amazing landmark  ',
      );

      // Assert
      expect(mockRepository.lastCallParams?['description'], equals('Amazing landmark'));
    });

    test('should trim whitespace from location', () async {
      // Arrange
      mockRepository.setupCreateItem(testItem);

      // Act
      await useCase(
        tripId: 'trip-123',
        title: 'Visit Eiffel Tower',
        location: '  Paris, France  ',
      );

      // Assert
      expect(mockRepository.lastCallParams?['location'], equals('Paris, France'));
    });

    test('should throw exception when trip ID is empty', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: '',
          title: 'Visit Eiffel Tower',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Trip ID is required'),
        )),
      );
      expect(mockRepository.wasCreateCalled, isFalse);
    });

    test('should throw exception when trip ID is whitespace', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: '   ',
          title: 'Visit Eiffel Tower',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Trip ID is required'),
        )),
      );
    });

    test('should throw exception when title is empty', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: '',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Title is required'),
        )),
      );
    });

    test('should throw exception when title is whitespace', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: '   ',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Title is required'),
        )),
      );
    });

    test('should throw exception when title is less than 3 characters', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'ab',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('at least 3 characters'),
        )),
      );
    });

    test('should throw exception when end time is before start time', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'Visit Eiffel Tower',
          startTime: DateTime(2024, 1, 1, 12, 0),
          endTime: DateTime(2024, 1, 1, 10, 0),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('End time must be after start time'),
        )),
      );
    });

    test('should throw exception when end time equals start time', () async {
      // Act & Assert
      final time = DateTime(2024, 1, 1, 10, 0);
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'Visit Eiffel Tower',
          startTime: time,
          endTime: time,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('End time must be after start time'),
        )),
      );
    });

    test('should throw exception when day number is zero', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'Visit Eiffel Tower',
          dayNumber: 0,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Day number must be positive'),
        )),
      );
    });

    test('should throw exception when day number is negative', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'Visit Eiffel Tower',
          dayNumber: -1,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Day number must be positive'),
        )),
      );
    });

    test('should throw exception when order index is negative', () async {
      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'Visit Eiffel Tower',
          orderIndex: -1,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Order index cannot be negative'),
        )),
      );
    });

    test('should accept zero as valid order index', () async {
      // Arrange
      mockRepository.setupCreateItem(testItem);

      // Act
      await useCase(
        tripId: 'trip-123',
        title: 'Visit Eiffel Tower',
        orderIndex: 0,
      );

      // Assert
      expect(mockRepository.lastCallParams?['orderIndex'], equals(0));
    });

    test('should wrap repository exceptions with context', () async {
      // Arrange
      mockRepository.setupCreateToThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => useCase(
          tripId: 'trip-123',
          title: 'Visit Eiffel Tower',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to create itinerary item'),
        )),
      );
    });

    test('should handle null optional fields correctly', () async {
      // Arrange
      mockRepository.setupCreateItem(testItem);

      // Act
      await useCase(
        tripId: 'trip-123',
        title: 'Visit Eiffel Tower',
        description: null,
        location: null,
        startTime: null,
        endTime: null,
        dayNumber: null,
      );

      // Assert
      expect(mockRepository.lastCallParams?['description'], isNull);
      expect(mockRepository.lastCallParams?['location'], isNull);
      expect(mockRepository.lastCallParams?['startTime'], isNull);
      expect(mockRepository.lastCallParams?['endTime'], isNull);
      expect(mockRepository.lastCallParams?['dayNumber'], isNull);
    });
  });
}
