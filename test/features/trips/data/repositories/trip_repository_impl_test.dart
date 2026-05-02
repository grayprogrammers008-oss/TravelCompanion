import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:travel_crew/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'trip_repository_impl_test.mocks.dart';

@GenerateMocks([TripRemoteDataSource])
void main() {
  late TripRepositoryImpl repository;
  late MockTripRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockTripRemoteDataSource();
    repository = TripRepositoryImpl(mockDataSource);
  });

  final now = DateTime.now();
  final testTrip = TripModel(
    id: 'trip-123',
    name: 'Test Trip',
    description: 'A test trip',
    destination: 'Paris',
    createdBy: 'user-123',
    createdAt: now,
    startDate: now,
    endDate: now.add(const Duration(days: 7)),
    cost: 5000.0,
    currency: 'USD',
  );

  final testMember = TripMemberModel(
    id: 'member-1',
    tripId: 'trip-123',
    userId: 'user-123',
    role: 'admin',
    joinedAt: now,
    fullName: 'John Doe',
    email: 'john@example.com',
  );

  final testTripWithMembers = TripWithMembers(
    trip: testTrip,
    members: [testMember],
    memberCount: 1,
  );

  final testUserStats = UserTravelStats(
    totalTrips: 5,
    totalExpenses: 20,
    totalSpent: 1500.0,
    uniqueCrewMembers: 8,
  );

  group('TripRepositoryImpl', () {
    group('createTrip', () {
      group('Positive Cases', () {
        test('should create trip with all fields successfully', () async {
          // Arrange
          when(mockDataSource.createTrip(any)).thenAnswer((_) async => testTrip);

          // Act
          final result = await repository.createTrip(
            name: 'Test Trip',
            description: 'A test trip',
            destination: 'Paris',
            startDate: now,
            endDate: now.add(const Duration(days: 7)),
            cost: 5000.0,
            currency: 'USD',
          );

          // Assert
          expect(result, testTrip);
          verify(mockDataSource.createTrip(any)).called(1);
        });

        test('should create trip with only required name field', () async {
          // Arrange
          final minimalTrip = TripModel(
            id: 'trip-456',
            name: 'Minimal Trip',
            createdBy: 'user-123',
          );
          when(mockDataSource.createTrip(any)).thenAnswer((_) async => minimalTrip);

          // Act
          final result = await repository.createTrip(name: 'Minimal Trip');

          // Assert
          expect(result.name, 'Minimal Trip');
          verify(mockDataSource.createTrip(any)).called(1);
        });

        test('should default currency to INR when not provided', () async {
          // Arrange
          when(mockDataSource.createTrip(any)).thenAnswer((_) async => testTrip);

          // Act
          await repository.createTrip(name: 'Test Trip');

          // Assert
          final captured = verify(mockDataSource.createTrip(captureAny)).captured.single as TripModel;
          expect(captured.currency, 'INR');
        });

        test('should create trip with cover image URL', () async {
          // Arrange
          final tripWithImage = testTrip.copyWith(coverImageUrl: 'https://example.com/image.jpg');
          when(mockDataSource.createTrip(any)).thenAnswer((_) async => tripWithImage);

          // Act
          final result = await repository.createTrip(
            name: 'Test Trip',
            coverImageUrl: 'https://example.com/image.jpg',
          );

          // Assert
          expect(result.coverImageUrl, 'https://example.com/image.jpg');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when data source fails', () async {
          // Arrange
          when(mockDataSource.createTrip(any)).thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.createTrip(name: 'Test Trip'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to create trip'),
            )),
          );
        });

        test('should wrap original exception message', () async {
          // Arrange
          when(mockDataSource.createTrip(any)).thenThrow(Exception('Network timeout'));

          // Act & Assert
          expect(
            () => repository.createTrip(name: 'Test Trip'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Network timeout'),
            )),
          );
        });
      });
    });

    group('getUserTrips', () {
      group('Positive Cases', () {
        test('should return list of trips with members', () async {
          // Arrange
          when(mockDataSource.getUserTrips()).thenAnswer((_) async => [testTripWithMembers]);

          // Act
          final result = await repository.getUserTrips();

          // Assert
          expect(result.length, 1);
          expect(result.first.trip, testTrip);
          expect(result.first.members, [testMember]);
          verify(mockDataSource.getUserTrips()).called(1);
        });

        test('should return empty list when user has no trips', () async {
          // Arrange
          when(mockDataSource.getUserTrips()).thenAnswer((_) async => []);

          // Act
          final result = await repository.getUserTrips();

          // Assert
          expect(result, isEmpty);
        });

        test('should return multiple trips', () async {
          // Arrange
          final trip2 = testTrip.copyWith(id: 'trip-456', name: 'Second Trip');
          final tripWithMembers2 = TripWithMembers(trip: trip2, members: []);
          when(mockDataSource.getUserTrips()).thenAnswer(
            (_) async => [testTripWithMembers, tripWithMembers2],
          );

          // Act
          final result = await repository.getUserTrips();

          // Assert
          expect(result.length, 2);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when data source fails', () async {
          // Arrange
          when(mockDataSource.getUserTrips()).thenThrow(Exception('Authentication error'));

          // Act & Assert
          expect(
            () => repository.getUserTrips(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get user trips'),
            )),
          );
        });

        test('should propagate network errors', () async {
          // Arrange
          when(mockDataSource.getUserTrips()).thenThrow(Exception('Network unavailable'));

          // Act & Assert
          try {
            await repository.getUserTrips();
            fail('Should have thrown exception');
          } catch (e) {
            expect(e.toString(), contains('Network unavailable'));
          }
        });
      });
    });

    group('getTripById', () {
      group('Positive Cases', () {
        test('should return trip with members when found', () async {
          // Arrange
          when(mockDataSource.getTripById('trip-123')).thenAnswer((_) async => testTripWithMembers);

          // Act
          final result = await repository.getTripById('trip-123');

          // Assert
          expect(result.trip, testTrip);
          expect(result.members, [testMember]);
          verify(mockDataSource.getTripById('trip-123')).called(1);
        });

        test('should return trip with multiple members', () async {
          // Arrange
          final member2 = TripMemberModel(
            id: 'member-2',
            tripId: 'trip-123',
            userId: 'user-456',
            role: 'member',
            joinedAt: now,
          );
          final tripWithMultipleMembers = TripWithMembers(
            trip: testTrip,
            members: [testMember, member2],
            memberCount: 2,
          );
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => tripWithMultipleMembers,
          );

          // Act
          final result = await repository.getTripById('trip-123');

          // Assert
          expect(result.members.length, 2);
          expect(result.memberCount, 2);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when trip not found', () async {
          // Arrange
          when(mockDataSource.getTripById('non-existent')).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () => repository.getTripById('non-existent'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Trip not found'),
            )),
          );
        });

        test('should throw exception when data source fails', () async {
          // Arrange
          when(mockDataSource.getTripById('trip-123')).thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.getTripById('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get trip'),
            )),
          );
        });
      });
    });

    group('updateTrip', () {
      group('Positive Cases', () {
        test('should update trip name successfully', () async {
          // Arrange
          final updatedTrip = testTrip.copyWith(name: 'Updated Name');
          final updatedTripWithMembers = TripWithMembers(trip: updatedTrip, members: [testMember]);
          when(mockDataSource.updateTrip('trip-123', any)).thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => updatedTripWithMembers,
          );

          // Act
          final result = await repository.updateTrip(tripId: 'trip-123', name: 'Updated Name');

          // Assert
          expect(result.name, 'Updated Name');
          verify(mockDataSource.updateTrip('trip-123', any)).called(1);
        });

        test('should update trip dates', () async {
          // Arrange
          final newStart = now.add(const Duration(days: 1));
          final newEnd = now.add(const Duration(days: 10));
          final updatedTrip = testTrip.copyWith(startDate: newStart, endDate: newEnd);
          final updatedTripWithMembers = TripWithMembers(trip: updatedTrip, members: [testMember]);
          when(mockDataSource.updateTrip('trip-123', any)).thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => updatedTripWithMembers,
          );

          // Act
          final result = await repository.updateTrip(
            tripId: 'trip-123',
            startDate: newStart,
            endDate: newEnd,
          );

          // Assert
          expect(result.startDate, newStart);
          expect(result.endDate, newEnd);
        });

        test('should update trip completion status', () async {
          // Arrange
          final completedTrip = testTrip.copyWith(isCompleted: true, completedAt: now);
          final completedTripWithMembers = TripWithMembers(trip: completedTrip, members: [testMember]);
          when(mockDataSource.updateTrip('trip-123', any)).thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => completedTripWithMembers,
          );

          // Act
          final result = await repository.updateTrip(
            tripId: 'trip-123',
            isCompleted: true,
            completedAt: now,
          );

          // Assert
          expect(result.isCompleted, true);
          expect(result.completedAt, now);
        });

        test('should update trip rating', () async {
          // Arrange
          final ratedTrip = testTrip.copyWith(rating: 4.5);
          final ratedTripWithMembers = TripWithMembers(trip: ratedTrip, members: [testMember]);
          when(mockDataSource.updateTrip('trip-123', any)).thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => ratedTripWithMembers,
          );

          // Act
          final result = await repository.updateTrip(tripId: 'trip-123', rating: 4.5);

          // Assert
          expect(result.rating, 4.5);
        });

        test('should update trip budget and currency', () async {
          // Arrange
          final updatedTrip = testTrip.copyWith(cost: 10000.0, currency: 'EUR');
          final updatedTripWithMembers = TripWithMembers(trip: updatedTrip, members: [testMember]);
          when(mockDataSource.updateTrip('trip-123', any)).thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => updatedTripWithMembers,
          );

          // Act
          final result = await repository.updateTrip(
            tripId: 'trip-123',
            cost: 10000.0,
            currency: 'EUR',
          );

          // Assert
          expect(result.cost, 10000.0);
          expect(result.currency, 'EUR');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when update fails', () async {
          // Arrange
          when(mockDataSource.updateTrip('trip-123', any)).thenThrow(Exception('Update failed'));

          // Act & Assert
          expect(
            () => repository.updateTrip(tripId: 'trip-123', name: 'New Name'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to update trip'),
            )),
          );
        });

        test('should throw exception when fetching updated trip fails', () async {
          // Arrange
          when(mockDataSource.updateTrip('trip-123', any)).thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () => repository.updateTrip(tripId: 'trip-123', name: 'New Name'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to fetch updated trip'),
            )),
          );
        });
      });
    });

    group('deleteTrip', () {
      group('Positive Cases', () {
        test('should delete trip successfully', () async {
          // Arrange
          when(mockDataSource.deleteTrip('trip-123')).thenAnswer((_) async {
            return;
          });

          // Act
          await repository.deleteTrip('trip-123');

          // Assert
          verify(mockDataSource.deleteTrip('trip-123')).called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when delete fails', () async {
          // Arrange
          when(mockDataSource.deleteTrip('trip-123')).thenThrow(Exception('Delete failed'));

          // Act & Assert
          expect(
            () => repository.deleteTrip('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to delete trip'),
            )),
          );
        });

        test('should propagate permission errors', () async {
          // Arrange
          when(mockDataSource.deleteTrip('trip-123'))
              .thenThrow(Exception('Permission denied'));

          // Act & Assert
          try {
            await repository.deleteTrip('trip-123');
            fail('Should have thrown exception');
          } catch (e) {
            expect(e.toString(), contains('Permission denied'));
          }
        });
      });
    });

    group('getTripMembers', () {
      group('Positive Cases', () {
        test('should return trip members', () async {
          // Arrange
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => testTripWithMembers,
          );

          // Act
          final result = await repository.getTripMembers('trip-123');

          // Assert
          expect(result, [testMember]);
          verify(mockDataSource.getTripById('trip-123')).called(1);
        });

        test('should return empty list when trip has no members', () async {
          // Arrange
          final tripNoMembers = TripWithMembers(trip: testTrip, members: []);
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => tripNoMembers,
          );

          // Act
          final result = await repository.getTripMembers('trip-123');

          // Assert
          expect(result, isEmpty);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when trip not found', () async {
          // Arrange
          when(mockDataSource.getTripById('non-existent')).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () => repository.getTripMembers('non-existent'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Trip not found'),
            )),
          );
        });

        test('should throw exception when data source fails', () async {
          // Arrange
          when(mockDataSource.getTripById('trip-123')).thenThrow(Exception('Network error'));

          // Act & Assert
          expect(
            () => repository.getTripMembers('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get trip members'),
            )),
          );
        });
      });
    });

    group('addMember', () {
      group('Positive Cases', () {
        test('should add member successfully', () async {
          // Arrange
          final newMember = TripMemberModel(
            id: 'member-new',
            tripId: 'trip-123',
            userId: 'user-new',
            role: 'member',
            joinedAt: now,
          );
          final updatedTripWithMembers = TripWithMembers(
            trip: testTrip,
            members: [testMember, newMember],
          );
          when(mockDataSource.addMember('trip-123', 'user-new', role: 'member'))
              .thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => updatedTripWithMembers,
          );

          // Act
          final result = await repository.addMember(
            tripId: 'trip-123',
            userId: 'user-new',
          );

          // Assert
          expect(result.userId, 'user-new');
          verify(mockDataSource.addMember('trip-123', 'user-new', role: 'member')).called(1);
        });

        test('should add member with admin role', () async {
          // Arrange
          final newAdmin = TripMemberModel(
            id: 'member-admin',
            tripId: 'trip-123',
            userId: 'user-admin',
            role: 'admin',
            joinedAt: now,
          );
          final updatedTripWithMembers = TripWithMembers(
            trip: testTrip,
            members: [testMember, newAdmin],
          );
          when(mockDataSource.addMember('trip-123', 'user-admin', role: 'admin'))
              .thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => updatedTripWithMembers,
          );

          // Act
          final result = await repository.addMember(
            tripId: 'trip-123',
            userId: 'user-admin',
            role: 'admin',
          );

          // Assert
          expect(result.role, 'admin');
        });
      });

      group('Negative Cases', () {
        test('should throw exception when add member fails', () async {
          // Arrange
          when(mockDataSource.addMember('trip-123', 'user-new', role: 'member'))
              .thenThrow(Exception('Database error'));

          // Act & Assert
          expect(
            () => repository.addMember(tripId: 'trip-123', userId: 'user-new'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to add member'),
            )),
          );
        });

        test('should throw exception when member not found after adding', () async {
          // Arrange
          when(mockDataSource.addMember('trip-123', 'user-new', role: 'member'))
              .thenAnswer((_) async {
            return;
          });
          when(mockDataSource.getTripById('trip-123')).thenAnswer(
            (_) async => testTripWithMembers, // original members, new one not there
          );

          // Act & Assert
          expect(
            () => repository.addMember(tripId: 'trip-123', userId: 'user-new'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to add member'),
            )),
          );
        });
      });
    });

    group('removeMember', () {
      group('Positive Cases', () {
        test('should remove member successfully', () async {
          // Arrange
          when(mockDataSource.removeMember('trip-123', 'user-456')).thenAnswer((_) async {
            return;
          });

          // Act
          await repository.removeMember(tripId: 'trip-123', userId: 'user-456');

          // Assert
          verify(mockDataSource.removeMember('trip-123', 'user-456')).called(1);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when remove fails', () async {
          // Arrange
          when(mockDataSource.removeMember('trip-123', 'user-456'))
              .thenThrow(Exception('Cannot remove creator'));

          // Act & Assert
          expect(
            () => repository.removeMember(tripId: 'trip-123', userId: 'user-456'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to remove member'),
            )),
          );
        });
      });
    });

    group('watchUserTrips', () {
      group('Positive Cases', () {
        test('should return stream from data source', () {
          // Arrange
          when(mockDataSource.watchUserTrips()).thenAnswer(
            (_) => Stream.value([testTripWithMembers]),
          );

          // Act
          final stream = repository.watchUserTrips();

          // Assert
          expect(stream, isA<Stream<List<TripWithMembers>>>());
          verify(mockDataSource.watchUserTrips()).called(1);
        });

        test('should emit trips from stream', () async {
          // Arrange
          when(mockDataSource.watchUserTrips()).thenAnswer(
            (_) => Stream.value([testTripWithMembers]),
          );

          // Act
          final result = await repository.watchUserTrips().first;

          // Assert
          expect(result.length, 1);
          expect(result.first.trip, testTrip);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when data source throws', () {
          // Arrange
          when(mockDataSource.watchUserTrips()).thenThrow(Exception('Stream error'));

          // Act & Assert
          expect(
            () => repository.watchUserTrips(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to watch user trips'),
            )),
          );
        });
      });
    });

    group('watchTrip', () {
      group('Positive Cases', () {
        test('should return stream for specific trip', () {
          // Arrange
          when(mockDataSource.watchTrip('trip-123')).thenAnswer(
            (_) => Stream.value(testTripWithMembers),
          );

          // Act
          final stream = repository.watchTrip('trip-123');

          // Assert
          expect(stream, isA<Stream<TripWithMembers>>());
          verify(mockDataSource.watchTrip('trip-123')).called(1);
        });

        test('should emit trip updates from stream', () async {
          // Arrange
          when(mockDataSource.watchTrip('trip-123')).thenAnswer(
            (_) => Stream.value(testTripWithMembers),
          );

          // Act
          final result = await repository.watchTrip('trip-123').first;

          // Assert
          expect(result.trip, testTrip);
          expect(result.members, [testMember]);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when data source throws', () {
          // Arrange
          when(mockDataSource.watchTrip('trip-123')).thenThrow(Exception('Stream error'));

          // Act & Assert
          expect(
            () => repository.watchTrip('trip-123'),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to watch trip'),
            )),
          );
        });
      });
    });

    group('getUserStats', () {
      group('Positive Cases', () {
        test('should return user travel stats', () async {
          // Arrange
          when(mockDataSource.getUserStats()).thenAnswer((_) async => testUserStats);

          // Act
          final result = await repository.getUserStats();

          // Assert
          expect(result.totalTrips, 5);
          expect(result.totalExpenses, 20);
          expect(result.totalSpent, 1500.0);
          expect(result.uniqueCrewMembers, 8);
          verify(mockDataSource.getUserStats()).called(1);
        });

        test('should return empty stats for new user', () async {
          // Arrange
          final emptyStats = UserTravelStats(
            totalTrips: 0,
            totalExpenses: 0,
            totalSpent: 0.0,
            uniqueCrewMembers: 0,
          );
          when(mockDataSource.getUserStats()).thenAnswer((_) async => emptyStats);

          // Act
          final result = await repository.getUserStats();

          // Assert
          expect(result.totalTrips, 0);
          expect(result.totalSpent, 0.0);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when data source fails', () async {
          // Arrange
          when(mockDataSource.getUserStats()).thenThrow(Exception('Stats error'));

          // Act & Assert
          expect(
            () => repository.getUserStats(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to get user stats'),
            )),
          );
        });
      });
    });

    group('watchUserStats', () {
      group('Positive Cases', () {
        test('should return stream from data source', () {
          // Arrange
          when(mockDataSource.watchUserStats()).thenAnswer(
            (_) => Stream.value(testUserStats),
          );

          // Act
          final stream = repository.watchUserStats();

          // Assert
          expect(stream, isA<Stream<UserTravelStats>>());
          verify(mockDataSource.watchUserStats()).called(1);
        });

        test('should emit stats updates from stream', () async {
          // Arrange
          when(mockDataSource.watchUserStats()).thenAnswer(
            (_) => Stream.value(testUserStats),
          );

          // Act
          final result = await repository.watchUserStats().first;

          // Assert
          expect(result.totalTrips, 5);
        });
      });

      group('Negative Cases', () {
        test('should throw exception when data source throws', () {
          // Arrange
          when(mockDataSource.watchUserStats()).thenThrow(Exception('Stream error'));

          // Act & Assert
          expect(
            () => repository.watchUserStats(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to watch user stats'),
            )),
          );
        });
      });
    });
  });

  group('UserTravelStats', () {
    test('should create instance with all fields', () {
      final stats = UserTravelStats(
        totalTrips: 10,
        totalExpenses: 50,
        totalSpent: 5000.0,
        uniqueCrewMembers: 15,
      );

      expect(stats.totalTrips, 10);
      expect(stats.totalExpenses, 50);
      expect(stats.totalSpent, 5000.0);
      expect(stats.uniqueCrewMembers, 15);
    });
  });
}
