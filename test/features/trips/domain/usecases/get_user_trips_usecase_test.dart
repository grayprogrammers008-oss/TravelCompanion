import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_trips_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'get_user_trips_usecase_test.mocks.dart';

@GenerateMocks([TripRepository])
void main() {
  late GetUserTripsUseCase useCase;
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
    useCase = GetUserTripsUseCase(mockRepository);
  });

  group('GetUserTripsUseCase', () {
    final testTrip = TripModel(
      id: 'trip1',
      name: 'Paris Trip',
      description: 'Summer vacation in Paris',
      destination: 'Paris, France',
      startDate: DateTime(2024, 7, 1),
      endDate: DateTime(2024, 7, 15),
      coverImageUrl: 'https://example.com/paris.jpg',
      createdBy: 'user1',
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

    final testTripWithMembers = TripWithMembers(
      trip: testTrip,
      members: [
        TripMemberModel(
          id: 'member1',
          tripId: 'trip1',
          userId: 'user1',
          role: 'owner',
          joinedAt: DateTime(2024, 6, 1),
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/john.jpg',
        ),
      ],
    );

    test('should return list of trips from repository', () async {
      // Arrange
      final tripsList = [testTripWithMembers];
      when(mockRepository.getUserTrips()).thenAnswer((_) async => tripsList);

      // Act
      final result = await useCase();

      // Assert
      expect(result, tripsList);
      verify(mockRepository.getUserTrips()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when user has no trips', () async {
      // Arrange
      when(mockRepository.getUserTrips()).thenAnswer((_) async => []);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.getUserTrips()).called(1);
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.getUserTrips())
          .thenThrow(Exception('Failed to fetch trips'));

      // Act & Assert
      expect(() => useCase(), throwsException);
      verify(mockRepository.getUserTrips()).called(1);
    });

    test('should return multiple trips ordered correctly', () async {
      // Arrange
      final trip2 = TripModel(
        id: 'trip2',
        name: 'Tokyo Trip',
        description: 'Spring in Tokyo',
        destination: 'Tokyo, Japan',
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 10),
        coverImageUrl: 'https://example.com/tokyo.jpg',
        createdBy: 'user1',
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      final tripWithMembers2 = TripWithMembers(
        trip: trip2,
        members: [
          TripMemberModel(
            id: 'member2',
            tripId: 'trip2',
            userId: 'user1',
            role: 'owner',
            joinedAt: DateTime(2024, 2, 1),
            fullName: 'John Doe',
            avatarUrl: 'https://example.com/john.jpg',
          ),
        ],
      );

      final tripsList = [testTripWithMembers, tripWithMembers2];
      when(mockRepository.getUserTrips()).thenAnswer((_) async => tripsList);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 2);
      expect(result[0].trip.id, 'trip1');
      expect(result[1].trip.id, 'trip2');
      verify(mockRepository.getUserTrips()).called(1);
    });

    test('should handle trips with multiple members', () async {
      // Arrange
      final tripWithMultipleMembers = TripWithMembers(
        trip: testTrip,
        members: [
          TripMemberModel(
            id: 'member3',
            tripId: 'trip1',
            userId: 'user1',
            role: 'owner',
            joinedAt: DateTime(2024, 6, 1),
            fullName: 'John Doe',
            avatarUrl: 'https://example.com/john.jpg',
          ),
          TripMemberModel(
            id: 'member4',
            tripId: 'trip1',
            userId: 'user2',
            role: 'member',
            joinedAt: DateTime(2024, 6, 2),
            fullName: 'Jane Smith',
            avatarUrl: 'https://example.com/jane.jpg',
          ),
          TripMemberModel(
            id: 'member5',
            tripId: 'trip1',
            userId: 'user3',
            role: 'member',
            joinedAt: DateTime(2024, 6, 3),
            fullName: 'Bob Wilson',
            avatarUrl: 'https://example.com/bob.jpg',
          ),
        ],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [tripWithMultipleMembers]);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 1);
      expect(result[0].members.length, 3);
      expect(result[0].members[0].role, 'owner');
      expect(result[0].members[1].role, 'member');
      verify(mockRepository.getUserTrips()).called(1);
    });

    test('should handle trips with no dates', () async {
      // Arrange
      final tripWithoutDates = TripModel(
        id: 'trip3',
        name: 'Undated Trip',
        description: 'Trip without dates',
        destination: 'Somewhere',
        startDate: null,
        endDate: null,
        coverImageUrl: null,
        createdBy: 'user1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final tripWithMembers = TripWithMembers(
        trip: tripWithoutDates,
        members: [
          TripMemberModel(
            id: 'member6',
            tripId: 'trip3',
            userId: 'user1',
            role: 'owner',
            joinedAt: DateTime(2024, 1, 1),
            fullName: 'John Doe',
            avatarUrl: null,
          ),
        ],
      );

      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [tripWithMembers]);

      // Act
      final result = await useCase();

      // Assert
      expect(result.length, 1);
      expect(result[0].trip.startDate, isNull);
      expect(result[0].trip.endDate, isNull);
      verify(mockRepository.getUserTrips()).called(1);
    });
  });
}
