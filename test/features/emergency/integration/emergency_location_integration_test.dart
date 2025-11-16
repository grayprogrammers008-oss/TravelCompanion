import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/core/services/location_service.dart';
import 'package:travel_crew/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:travel_crew/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

import 'emergency_location_integration_test.mocks.dart';

@GenerateMocks([EmergencyRemoteDataSource, LocationService])
void main() {
  late EmergencyRepositoryImpl repository;
  late MockEmergencyRemoteDataSource mockRemoteDataSource;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRemoteDataSource = MockEmergencyRemoteDataSource();
    mockLocationService = MockLocationService();
    repository = EmergencyRepositoryImpl(
      mockRemoteDataSource,
      mockLocationService,
    );
  });

  group('Emergency Location Integration Tests', () {
    group('Location Service Integration', () {
      test('should use real GPS coordinates when location is available',
          () async {
        // Arrange - Mock San Francisco coordinates
        final sanFranciscoCoords = {
          'latitude': 37.7749,
          'longitude': -122.4194,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => sanFranciscoCoords);

        when(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
          tripId: 'trip123',
          duration: null,
          message: 'Sharing my location',
          latitude: 37.7749,
          longitude: -122.4194,
        )).thenAnswer((_) async => LocationShareModel(
              id: 'share1',
              userId: 'user1',
              sharedWithContactIds: ['contact1', 'contact2'],
              tripId: 'trip123',
              latitude: 37.7749,
              longitude: -122.4194,
              message: 'Sharing my location',
              status: LocationShareStatus.active,
              startedAt: DateTime(2024, 1, 1),
              lastUpdatedAt: DateTime(2024, 1, 1),
            ));

        // Act
        final result = await repository.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
          tripId: 'trip123',
          message: 'Sharing my location',
        );

        // Assert
        expect(result.latitude, 37.7749);
        expect(result.longitude, -122.4194);
        verify(mockLocationService.getCurrentCoordinates()).called(1);
        verify(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
          tripId: 'trip123',
          latitude: 37.7749,
          longitude: -122.4194,
          duration: null,
          message: 'Sharing my location',
        )).called(1);
      });

      test('should fallback to (0.0, 0.0) when location permission is denied',
          () async {
        // Arrange - Location service returns null (permission denied)
        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => null);

        when(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1'],
          tripId: null,
          duration: null,
          message: null,
          latitude: 0.0,
          longitude: 0.0,
        )).thenAnswer((_) async => LocationShareModel(
              id: 'share1',
              userId: 'user1',
              sharedWithContactIds: ['contact1'],
              latitude: 0.0,
              longitude: 0.0,
              status: LocationShareStatus.active,
              startedAt: DateTime(2024, 1, 1),
              lastUpdatedAt: DateTime(2024, 1, 1),
            ));

        // Act
        final result = await repository.startLocationSharing(
          contactIds: ['contact1'],
        );

        // Assert
        expect(result.latitude, 0.0);
        expect(result.longitude, 0.0);
        verify(mockLocationService.getCurrentCoordinates()).called(1);
        verify(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1'],
          tripId: null,
          duration: null,
          message: null,
          latitude: 0.0,
          longitude: 0.0,
        )).called(1);
      });

      test('should handle location service errors gracefully', () async {
        // Arrange - Location service throws exception
        when(mockLocationService.getCurrentCoordinates())
            .thenThrow(Exception('Location services disabled'));

        // Act & Assert
        expect(
          () => repository.startLocationSharing(contactIds: ['contact1']),
          throwsException,
        );

        verify(mockLocationService.getCurrentCoordinates()).called(1);
      });

      test('should use different coordinates for different locations',
          () async {
        // Arrange - Test multiple locations
        final locations = [
          {'latitude': 40.7128, 'longitude': -74.0060}, // New York
          {'latitude': 51.5074, 'longitude': -0.1278}, // London
          {'latitude': 35.6762, 'longitude': 139.6503}, // Tokyo
        ];

        for (var i = 0; i < locations.length; i++) {
          final coords = locations[i];
          when(mockLocationService.getCurrentCoordinates())
              .thenAnswer((_) async => coords);

          when(mockRemoteDataSource.startLocationSharing(
            contactIds: ['contact$i'],
            tripId: null,
            duration: null,
            message: null,
            latitude: coords['latitude']!,
            longitude: coords['longitude']!,
          )).thenAnswer((_) async => LocationShareModel(
                id: 'share$i',
                userId: 'user1',
                sharedWithContactIds: ['contact$i'],
                latitude: coords['latitude']!,
                longitude: coords['longitude']!,
                status: LocationShareStatus.active,
                startedAt: DateTime(2024, 1, 1),
                lastUpdatedAt: DateTime(2024, 1, 1),
              ));

          // Act
          final result = await repository.startLocationSharing(
            contactIds: ['contact$i'],
          );

          // Assert
          expect(result.latitude, coords['latitude']);
          expect(result.longitude, coords['longitude']);
        }

        verify(mockLocationService.getCurrentCoordinates()).called(3);
      });
    });

    group('Location Coordinates Validation', () {
      test('should handle edge case coordinates correctly', () async {
        // Arrange - Test boundary values
        final edgeCases = [
          {'latitude': 90.0, 'longitude': 180.0}, // North Pole, Date Line
          {'latitude': -90.0, 'longitude': -180.0}, // South Pole
          {'latitude': 0.0, 'longitude': 0.0}, // Null Island
        ];

        for (var coords in edgeCases) {
          when(mockLocationService.getCurrentCoordinates())
              .thenAnswer((_) async => coords);

          when(mockRemoteDataSource.startLocationSharing(
            contactIds: ['contact1'],
            tripId: null,
            duration: null,
            message: null,
            latitude: coords['latitude']!,
            longitude: coords['longitude']!,
          )).thenAnswer((_) async => LocationShareModel(
                id: 'share1',
                userId: 'user1',
                sharedWithContactIds: ['contact1'],
                latitude: coords['latitude']!,
                longitude: coords['longitude']!,
                status: LocationShareStatus.active,
                startedAt: DateTime(2024, 1, 1),
                lastUpdatedAt: DateTime(2024, 1, 1),
              ));

          // Act
          final result = await repository.startLocationSharing(
            contactIds: ['contact1'],
          );

          // Assert
          expect(result.latitude, coords['latitude']);
          expect(result.longitude, coords['longitude']);
        }
      });

      test('should handle high precision coordinates', () async {
        // Arrange - Test precise GPS coordinates
        final preciseCoords = {
          'latitude': 37.77492830,
          'longitude': -122.41941550,
        };

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => preciseCoords);

        when(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1'],
          tripId: null,
          duration: null,
          message: null,
          latitude: 37.77492830,
          longitude: -122.41941550,
        )).thenAnswer((_) async => LocationShareModel(
              id: 'share1',
              userId: 'user1',
              sharedWithContactIds: ['contact1'],
              latitude: 37.77492830,
              longitude: -122.41941550,
              status: LocationShareStatus.active,
              startedAt: DateTime(2024, 1, 1),
              lastUpdatedAt: DateTime(2024, 1, 1),
            ));

        // Act
        final result = await repository.startLocationSharing(
          contactIds: ['contact1'],
        );

        // Assert
        expect(result.latitude, 37.77492830);
        expect(result.longitude, -122.41941550);
      });
    });

    group('Location Sharing with Trip Context', () {
      test('should include trip ID when sharing location', () async {
        // Arrange
        final coords = {'latitude': 34.0522, 'longitude': -118.2437}; // LA

        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => coords);

        when(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
          tripId: 'beach-trip-2024',
          duration: const Duration(hours: 2),
          message: 'On our way to the beach!',
          latitude: 34.0522,
          longitude: -118.2437,
        )).thenAnswer((_) async => LocationShareModel(
              id: 'share1',
              userId: 'user1',
              sharedWithContactIds: ['contact1', 'contact2'],
              tripId: 'beach-trip-2024',
              latitude: 34.0522,
              longitude: -118.2437,
              message: 'On our way to the beach!',
              status: LocationShareStatus.active,
              startedAt: DateTime(2024, 1, 1),
              lastUpdatedAt: DateTime(2024, 1, 1),
              expiresAt: DateTime(2024, 1, 1).add(const Duration(hours: 2)),
            ));

        // Act
        final result = await repository.startLocationSharing(
          contactIds: ['contact1', 'contact2'],
          tripId: 'beach-trip-2024',
          duration: const Duration(hours: 2),
          message: 'On our way to the beach!',
        );

        // Assert
        expect(result.tripId, 'beach-trip-2024');
        expect(result.latitude, 34.0522);
        expect(result.longitude, -118.2437);
        expect(result.message, 'On our way to the beach!');
      });
    });

    group('Error Scenarios', () {
      test('should propagate repository errors with context', () async {
        // Arrange
        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => {'latitude': 0.0, 'longitude': 0.0});

        when(mockRemoteDataSource.startLocationSharing(
          contactIds: anyNamed('contactIds'),
          tripId: anyNamed('tripId'),
          duration: anyNamed('duration'),
          message: anyNamed('message'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.startLocationSharing(contactIds: ['contact1']),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Failed to start location sharing'))),
        );
      });

      test('should handle empty coordinates map from location service',
          () async {
        // Arrange - Empty map (shouldn't happen but defensive programming)
        when(mockLocationService.getCurrentCoordinates())
            .thenAnswer((_) async => <String, double>{});

        when(mockRemoteDataSource.startLocationSharing(
          contactIds: ['contact1'],
          tripId: null,
          duration: null,
          message: null,
          latitude: 0.0, // Should fallback
          longitude: 0.0, // Should fallback
        )).thenAnswer((_) async => LocationShareModel(
              id: 'share1',
              userId: 'user1',
              sharedWithContactIds: ['contact1'],
              latitude: 0.0,
              longitude: 0.0,
              status: LocationShareStatus.active,
              startedAt: DateTime(2024, 1, 1),
              lastUpdatedAt: DateTime(2024, 1, 1),
            ));

        // Act
        final result = await repository.startLocationSharing(
          contactIds: ['contact1'],
        );

        // Assert
        expect(result.latitude, 0.0);
        expect(result.longitude, 0.0);
      });
    });
  });
}
