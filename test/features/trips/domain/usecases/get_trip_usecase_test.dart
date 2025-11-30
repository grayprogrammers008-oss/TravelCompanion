import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'get_trip_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late GetTripUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = GetTripUseCase(mockRepository);
  });

  final now = DateTime.now();
  final testTrip = TripModel(
    id: 'trip-123',
    name: 'Test Trip',
    description: 'A wonderful trip',
    destination: 'Paris',
    startDate: now,
    endDate: now.add(const Duration(days: 7)),
    coverImageUrl: 'https://example.com/cover.jpg',
    createdBy: 'user-123',
    createdAt: now,
    updatedAt: now,
    budget: 5000.0,
    currency: 'USD',
  );

  final testMember = TripMemberModel(
    id: 'member-1',
    tripId: 'trip-123',
    userId: 'user-123',
    role: 'admin',
    joinedAt: now,
    fullName: 'John Doe',
    avatarUrl: 'https://example.com/avatar.jpg',
    email: 'john@example.com',
  );

  final testTripWithMembers = TripWithMembers(
    trip: testTrip,
    members: [testMember],
    memberCount: 1,
  );

  group('GetTripUseCase', () {
    group('Positive Cases', () {
      test('should return trip with members for valid trip ID', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => testTripWithMembers);

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result, testTripWithMembers);
        expect(result.trip.id, 'trip-123');
        expect(result.trip.name, 'Test Trip');
        expect(result.members.length, 1);
        verify(mockRepository.getTripById('trip-123')).called(1);
      });

      test('should return trip with multiple members', () async {
        // Arrange
        final member2 = TripMemberModel(
          id: 'member-2',
          tripId: 'trip-123',
          userId: 'user-456',
          role: 'member',
          joinedAt: now,
          fullName: 'Jane Doe',
          email: 'jane@example.com',
        );

        final tripWithMultipleMembers = TripWithMembers(
          trip: testTrip,
          members: [testMember, member2],
          memberCount: 2,
        );

        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => tripWithMultipleMembers);

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.members.length, 2);
        expect(result.memberCount, 2);
      });

      test('should return trip with minimal data', () async {
        // Arrange
        final minimalTrip = TripModel(
          id: 'trip-minimal',
          name: 'Minimal Trip',
          createdBy: 'user-123',
        );

        final minimalTripWithMembers = TripWithMembers(
          trip: minimalTrip,
          members: [],
        );

        when(mockRepository.getTripById('trip-minimal'))
            .thenAnswer((_) async => minimalTripWithMembers);

        // Act
        final result = await useCase('trip-minimal');

        // Assert
        expect(result.trip.description, isNull);
        expect(result.trip.destination, isNull);
        expect(result.trip.startDate, isNull);
        expect(result.members, isEmpty);
      });

      test('should return completed trip', () async {
        // Arrange
        final completedTrip = testTrip.copyWith(
          isCompleted: true,
          completedAt: now,
          rating: 4.5,
        );

        final completedTripWithMembers = TripWithMembers(
          trip: completedTrip,
          members: [testMember],
        );

        when(mockRepository.getTripById('trip-123'))
            .thenAnswer((_) async => completedTripWithMembers);

        // Act
        final result = await useCase('trip-123');

        // Assert
        expect(result.trip.isCompleted, true);
        expect(result.trip.completedAt, isNotNull);
        expect(result.trip.rating, 4.5);
      });
    });

    group('Negative Cases - Validation Errors', () {
      test('should throw exception when trip ID is empty', () async {
        // Act & Assert
        expect(
          () => useCase(''),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip ID is required'),
          )),
        );
        verifyNever(mockRepository.getTripById(any));
      });
    });

    group('Negative Cases - Repository Errors', () {
      test('should propagate exception when trip not found', () async {
        // Arrange
        when(mockRepository.getTripById('non-existent'))
            .thenThrow(Exception('Trip not found'));

        // Act & Assert
        expect(
          () => useCase('non-existent'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trip not found'),
          )),
        );
      });

      test('should propagate exception for network error', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Network error'),
          )),
        );
      });

      test('should propagate exception for server error', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenThrow(Exception('Internal server error'));

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Internal server error'),
          )),
        );
      });

      test('should propagate exception for unauthorized access', () async {
        // Arrange
        when(mockRepository.getTripById('trip-123'))
            .thenThrow(Exception('Unauthorized'));

        // Act & Assert
        expect(
          () => useCase('trip-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unauthorized'),
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle trip ID with special characters', () async {
        // Arrange
        const specialTripId = 'trip-abc-123-def';
        when(mockRepository.getTripById(specialTripId))
            .thenAnswer((_) async => testTripWithMembers);

        // Act
        final result = await useCase(specialTripId);

        // Assert
        expect(result, testTripWithMembers);
        verify(mockRepository.getTripById(specialTripId)).called(1);
      });

      test('should handle UUID trip ID', () async {
        // Arrange
        const uuidTripId = '550e8400-e29b-41d4-a716-446655440000';
        when(mockRepository.getTripById(uuidTripId))
            .thenAnswer((_) async => testTripWithMembers);

        // Act
        final result = await useCase(uuidTripId);

        // Assert
        expect(result, testTripWithMembers);
      });

      test('should handle whitespace in trip ID (passes to repository)', () async {
        // Arrange - whitespace-only would fail isEmpty check, but single space would not
        const tripIdWithSpaces = ' trip-123 ';
        when(mockRepository.getTripById(tripIdWithSpaces))
            .thenThrow(Exception('Trip not found'));

        // Act & Assert
        expect(
          () => useCase(tripIdWithSpaces),
          throwsA(isA<Exception>()),
        );
        verify(mockRepository.getTripById(tripIdWithSpaces)).called(1);
      });
    });
  });
}
