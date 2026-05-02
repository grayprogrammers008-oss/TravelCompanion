import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/update_trip_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

@GenerateMocks([TripRepository])
import 'trip_edit_integration_test.mocks.dart';

void main() {
  late MockTripRepository mockRepository;
  late UpdateTripUseCase updateTripUseCase;

  setUp(() {
    mockRepository = MockTripRepository();
    updateTripUseCase = UpdateTripUseCase(mockRepository);
  });

  group('Trip Edit Integration Tests', () {
    final testTrip = TripModel(
      id: 'trip123',
      name: 'Original Trip',
      description: 'Original description',
      destination: 'Original Destination',
      startDate: DateTime(2025, 6, 1),
      endDate: DateTime(2025, 6, 10),
      createdBy: 'user123',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Should successfully update trip name', () async {
      // Arrange
      final updatedTrip = testTrip.copyWith(name: 'Updated Trip');
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        name: 'Updated Trip',
      );

      // Assert
      expect(result.name, 'Updated Trip');
      expect(result.description, testTrip.description);
      expect(result.destination, testTrip.destination);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).called(1);
    });

    test('Should successfully update trip description', () async {
      // Arrange
      final updatedTrip = testTrip.copyWith(description: 'Updated description');
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        description: 'Updated description',
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        description: 'Updated description',
      );

      // Assert
      expect(result.description, 'Updated description');
      expect(result.name, testTrip.name);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        description: 'Updated description',
      )).called(1);
    });

    test('Should successfully update trip destination', () async {
      // Arrange
      final updatedTrip = testTrip.copyWith(destination: 'New Destination');
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        destination: 'New Destination',
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        destination: 'New Destination',
      );

      // Assert
      expect(result.destination, 'New Destination');
      expect(result.name, testTrip.name);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        destination: 'New Destination',
      )).called(1);
    });

    test('Should successfully update trip dates', () async {
      // Arrange
      final newStartDate = DateTime(2025, 7, 1);
      final newEndDate = DateTime(2025, 7, 15);
      final updatedTrip = testTrip.copyWith(
        startDate: newStartDate,
        endDate: newEndDate,
      );
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        startDate: newStartDate,
        endDate: newEndDate,
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        startDate: newStartDate,
        endDate: newEndDate,
      );

      // Assert
      expect(result.startDate, newStartDate);
      expect(result.endDate, newEndDate);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        startDate: newStartDate,
        endDate: newEndDate,
      )).called(1);
    });

    test('Should successfully update multiple fields at once', () async {
      // Arrange
      final newStartDate = DateTime(2025, 7, 1);
      final newEndDate = DateTime(2025, 7, 15);
      final updatedTrip = testTrip.copyWith(
        name: 'Completely Updated Trip',
        description: 'New description',
        destination: 'New Destination',
        startDate: newStartDate,
        endDate: newEndDate,
      );
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Completely Updated Trip',
        description: 'New description',
        destination: 'New Destination',
        startDate: newStartDate,
        endDate: newEndDate,
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        name: 'Completely Updated Trip',
        description: 'New description',
        destination: 'New Destination',
        startDate: newStartDate,
        endDate: newEndDate,
      );

      // Assert
      expect(result.name, 'Completely Updated Trip');
      expect(result.description, 'New description');
      expect(result.destination, 'New Destination');
      expect(result.startDate, newStartDate);
      expect(result.endDate, newEndDate);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Completely Updated Trip',
        description: 'New description',
        destination: 'New Destination',
        startDate: newStartDate,
        endDate: newEndDate,
      )).called(1);
    });

    test('Should throw exception when trip name is empty', () async {
      // Act & Assert
      expect(
        () => updateTripUseCase(tripId: 'trip123', name: ''),
        throwsException,
      );
      verifyNever(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
      ));
    });

    test('Should throw exception when trip name is only whitespace', () async {
      // Act & Assert
      expect(
        () => updateTripUseCase(tripId: 'trip123', name: '   '),
        throwsException,
      );
      verifyNever(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
      ));
    });

    test('Should throw exception when end date is before start date', () async {
      // Arrange
      final startDate = DateTime(2025, 7, 10);
      final endDate = DateTime(2025, 7, 5); // Before start date

      // Act & Assert
      expect(
        () => updateTripUseCase(
          tripId: 'trip123',
          startDate: startDate,
          endDate: endDate,
        ),
        throwsException,
      );
      verifyNever(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ));
    });

    test('Should allow updating with null description (clearing description)', () async {
      // Arrange — construct directly so description is actually null (copyWith cannot clear to null)
      final updatedTrip = TripModel(
        id: testTrip.id,
        name: testTrip.name,
        description: null,
        destination: testTrip.destination,
        startDate: testTrip.startDate,
        endDate: testTrip.endDate,
        createdBy: testTrip.createdBy,
        createdAt: testTrip.createdAt,
        updatedAt: testTrip.updatedAt,
      );
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        description: null,
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        description: null,
      );

      // Assert
      expect(result.description, isNull);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        description: null,
      )).called(1);
    });

    test('Should allow updating with null destination (clearing destination)', () async {
      // Arrange — construct directly so destination is actually null (copyWith cannot clear to null)
      final updatedTrip = TripModel(
        id: testTrip.id,
        name: testTrip.name,
        description: testTrip.description,
        destination: null,
        startDate: testTrip.startDate,
        endDate: testTrip.endDate,
        createdBy: testTrip.createdBy,
        createdAt: testTrip.createdAt,
        updatedAt: testTrip.updatedAt,
      );
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        destination: null,
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        destination: null,
      );

      // Assert
      expect(result.destination, isNull);
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        destination: null,
      )).called(1);
    });

    test('Should handle repository errors gracefully', () async {
      // Arrange
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => updateTripUseCase(tripId: 'trip123', name: 'Updated Trip'),
        throwsException,
      );
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).called(1);
    });

    test('Should handle network errors during update', () async {
      // Arrange
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => updateTripUseCase(tripId: 'trip123', name: 'Updated Trip'),
        throwsException,
      );
    });

    test('Should trim whitespace from trip name before validation', () async {
      // Arrange
      final updatedTrip = testTrip.copyWith(name: 'Updated Trip');
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        name: '  Updated Trip  ', // With leading/trailing spaces
      );

      // Assert
      expect(result.name, 'Updated Trip');
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Updated Trip',
      )).called(1);
    });

    test('Should update cover image URL', () async {
      // Arrange
      final updatedTrip = testTrip.copyWith(
        coverImageUrl: 'https://example.com/new-image.jpg',
      );
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        coverImageUrl: 'https://example.com/new-image.jpg',
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        coverImageUrl: 'https://example.com/new-image.jpg',
      );

      // Assert
      expect(result.coverImageUrl, 'https://example.com/new-image.jpg');
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        coverImageUrl: 'https://example.com/new-image.jpg',
      )).called(1);
    });
  });

  group('End-to-End Update Flow Tests', () {
    test('Complete update flow: Fetch -> Edit -> Save -> Verify', () async {
      // Arrange
      final originalTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Family trip',
        destination: 'Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedTrip = originalTrip.copyWith(
        name: 'Summer Adventure',
        description: 'Epic family trip',
        destination: 'Maui, Hawaii',
      );

      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Summer Adventure',
        description: 'Epic family trip',
        destination: 'Maui, Hawaii',
      )).thenAnswer((_) async => updatedTrip);

      // Act
      final result = await updateTripUseCase(
        tripId: 'trip123',
        name: 'Summer Adventure',
        description: 'Epic family trip',
        destination: 'Maui, Hawaii',
      );

      // Assert - Verify all changes were applied
      expect(result.id, originalTrip.id); // ID should not change
      expect(result.name, 'Summer Adventure');
      expect(result.description, 'Epic family trip');
      expect(result.destination, 'Maui, Hawaii');
      expect(result.startDate, originalTrip.startDate); // Unchanged fields preserved
      expect(result.endDate, originalTrip.endDate);
      expect(result.createdBy, originalTrip.createdBy);
    });
  });
}
