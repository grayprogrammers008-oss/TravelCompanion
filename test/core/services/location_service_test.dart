// Tests for LocationService using a mocked Geolocator method channel.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pathio/core/services/location_service.dart';

const _geoChannel = MethodChannel('flutter.baseflow.com/geolocator');
const _eventChannelUpdates =
    'flutter.baseflow.com/geolocator_updates';

void _installGeolocatorMock({
  bool serviceEnabled = true,
  // Mirrors LocationPermission enum index (whileInUse = 3, always = 4).
  int permission = 3,
  double latitude = 12.0,
  double longitude = 77.0,
  bool openSettingsResult = true,
}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_geoChannel, (call) async {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return serviceEnabled;
      case 'checkPermission':
      case 'requestPermission':
        return permission;
      case 'getCurrentPosition':
      case 'getLastKnownPosition':
        return {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': 10.0,
          'altitude': 0.0,
          'altitudeAccuracy': 0.0,
          'heading': 0.0,
          'headingAccuracy': 0.0,
          'speed': 0.0,
          'speedAccuracy': 0.0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isMocked': false,
          'floor': null,
        };
      case 'openLocationSettings':
      case 'openAppSettings':
        return openSettingsResult;
      default:
        return null;
    }
  });
}

void _clearMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_geoChannel, null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(_eventChannelUpdates, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(_clearMock);

  group('LocationService.getCurrentLocation', () {
    test('returns position when service+permission OK', () async {
      _installGeolocatorMock(
        latitude: 11.5,
        longitude: 76.5,
        permission: LocationPermission.whileInUse.index,
      );
      final pos = await LocationService().getCurrentLocation();
      expect(pos.latitude, 11.5);
      expect(pos.longitude, 76.5);
    });

    test('throws when location services are disabled', () async {
      _installGeolocatorMock(serviceEnabled: false);
      await expectLater(
        LocationService().getCurrentLocation(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Location services are disabled'))),
      );
    });

    test('throws when permission is denied', () async {
      _installGeolocatorMock(
        permission: LocationPermission.denied.index,
      );
      await expectLater(
        LocationService().getCurrentLocation(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Location permission denied'))),
      );
    });

    test('throws when permission is denied forever', () async {
      _installGeolocatorMock(
        permission: LocationPermission.deniedForever.index,
      );
      await expectLater(
        LocationService().getCurrentLocation(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('permanently denied'))),
      );
    });
  });

  group('LocationService.getCurrentCoordinates', () {
    test('returns lat/lng map when location available', () async {
      _installGeolocatorMock(
        latitude: 1.1,
        longitude: 2.2,
        permission: LocationPermission.always.index,
      );
      final map = await LocationService().getCurrentCoordinates();
      expect(map, isNotNull);
      expect(map!['latitude'], 1.1);
      expect(map['longitude'], 2.2);
    });

    test('returns null when underlying call fails', () async {
      _installGeolocatorMock(serviceEnabled: false);
      expect(await LocationService().getCurrentCoordinates(), isNull);
    });
  });

  group('LocationService.hasLocationPermission', () {
    test('returns true for whileInUse', () async {
      _installGeolocatorMock(
        permission: LocationPermission.whileInUse.index,
      );
      expect(await LocationService().hasLocationPermission(), isTrue);
    });

    test('returns true for always', () async {
      _installGeolocatorMock(
        permission: LocationPermission.always.index,
      );
      expect(await LocationService().hasLocationPermission(), isTrue);
    });

    test('returns false for denied', () async {
      _installGeolocatorMock(
        permission: LocationPermission.denied.index,
      );
      expect(await LocationService().hasLocationPermission(), isFalse);
    });

    test('returns false for deniedForever', () async {
      _installGeolocatorMock(
        permission: LocationPermission.deniedForever.index,
      );
      expect(await LocationService().hasLocationPermission(), isFalse);
    });
  });

  group('LocationService.requestLocationPermission', () {
    test('returns true when granted whileInUse', () async {
      _installGeolocatorMock(
        permission: LocationPermission.whileInUse.index,
      );
      expect(await LocationService().requestLocationPermission(), isTrue);
    });

    test('returns false when denied', () async {
      _installGeolocatorMock(
        permission: LocationPermission.denied.index,
      );
      expect(await LocationService().requestLocationPermission(), isFalse);
    });
  });

  group('LocationService.openLocationSettings', () {
    test('returns true when platform reports success', () async {
      _installGeolocatorMock(openSettingsResult: true);
      expect(await LocationService().openLocationSettings(), isTrue);
    });

    test('returns false when platform reports failure', () async {
      _installGeolocatorMock(openSettingsResult: false);
      expect(await LocationService().openLocationSettings(), isFalse);
    });
  });

  group('LocationService distance/bearing helpers (pure math)', () {
    test('distance between identical points is ~0', () {
      final d = LocationService().getDistanceBetween(
        startLatitude: 10,
        startLongitude: 20,
        endLatitude: 10,
        endLongitude: 20,
      );
      expect(d, closeTo(0, 0.001));
    });

    test('distance between two distant points is positive', () {
      final d = LocationService().getDistanceBetween(
        startLatitude: 0,
        startLongitude: 0,
        endLatitude: 0,
        endLongitude: 1,
      );
      // ~111km along the equator
      expect(d, greaterThan(100000));
      expect(d, lessThan(115000));
    });

    test('bearing between points is in 0-360 range', () {
      final b = LocationService().getBearingBetween(
        startLatitude: 0,
        startLongitude: 0,
        endLatitude: 0,
        endLongitude: 1,
      );
      // Heading east (~90)
      expect(b, closeTo(90, 0.5));
    });
  });
}
