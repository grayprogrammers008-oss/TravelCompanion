// Tests for MapLauncherService and MapApp enum.
//
// The url_launcher plugin channel is mocked so we can drive launchUrl /
// canLaunchUrl deterministically. SharedPreferences is initialised in-memory.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pathio/core/services/map_launcher_service.dart';

const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
const _urlLauncherAndroidChannel =
    MethodChannel('plugins.flutter.io/url_launcher_android');
const _urlLauncherIosChannel =
    MethodChannel('plugins.flutter.io/url_launcher_ios');

class _UrlLauncherStub {
  bool canLaunch = true;
  bool launchSucceeds = true;
  final List<String> canLaunchCalls = [];
  final List<String> launchCalls = [];

  Future<dynamic> _handle(MethodCall call) async {
    final args = call.arguments;
    final url = (args is Map ? args['url'] : args).toString();
    switch (call.method) {
      case 'canLaunch':
        canLaunchCalls.add(url);
        return canLaunch;
      case 'launch':
        launchCalls.add(url);
        return launchSucceeds;
      default:
        return null;
    }
  }

  void install() {
    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger;
    for (final ch in [
      _urlLauncherChannel,
      _urlLauncherAndroidChannel,
      _urlLauncherIosChannel,
    ]) {
      messenger.setMockMethodCallHandler(ch, _handle);
    }
  }

  void uninstall() {
    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger;
    for (final ch in [
      _urlLauncherChannel,
      _urlLauncherAndroidChannel,
      _urlLauncherIosChannel,
    ]) {
      messenger.setMockMethodCallHandler(ch, null);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapApp enum', () {
    test('googleMaps has expected display name and key', () {
      expect(MapApp.googleMaps.displayName, equals('Google Maps'));
      expect(MapApp.googleMaps.key, equals('google_maps'));
    });

    test('appleMaps has expected display name and key', () {
      expect(MapApp.appleMaps.displayName, equals('Apple Maps'));
      expect(MapApp.appleMaps.key, equals('apple_maps'));
    });

    test('there are exactly two map app values', () {
      expect(MapApp.values.length, equals(2));
    });

    test('keys are unique', () {
      final keys = MapApp.values.map((m) => m.key).toSet();
      expect(keys.length, equals(MapApp.values.length));
    });

    test('display names are unique', () {
      final names = MapApp.values.map((m) => m.displayName).toSet();
      expect(names.length, equals(MapApp.values.length));
    });
  });

  group('MapApp.fromKey', () {
    test('returns googleMaps for "google_maps"', () {
      expect(MapApp.fromKey('google_maps'), equals(MapApp.googleMaps));
    });

    test('returns appleMaps for "apple_maps"', () {
      expect(MapApp.fromKey('apple_maps'), equals(MapApp.appleMaps));
    });

    test('returns a sensible default for unknown key', () {
      final result = MapApp.fromKey('not_a_real_app');
      expect(MapApp.values.contains(result), isTrue);
    });
  });

  group('MapLauncherService preferences', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('preferredMapApp defaults to platform-appropriate app', () {
      final svc = MapLauncherService(prefs);
      final app = svc.preferredMapApp;
      // Platform default: iOS -> AppleMaps, others -> GoogleMaps.
      if (Platform.isIOS) {
        expect(app, MapApp.appleMaps);
      } else {
        expect(app, MapApp.googleMaps);
      }
    });

    test('setPreferredMapApp persists the choice', () async {
      final svc = MapLauncherService(prefs);
      await svc.setPreferredMapApp(MapApp.googleMaps);
      expect(svc.preferredMapApp, MapApp.googleMaps);
      await svc.setPreferredMapApp(MapApp.appleMaps);
      expect(svc.preferredMapApp, MapApp.appleMaps);
    });

    test('reading after manual write returns same value', () async {
      SharedPreferences.setMockInitialValues({
        'preferred_map_app': 'google_maps',
      });
      final p = await SharedPreferences.getInstance();
      expect(MapLauncherService(p).preferredMapApp, MapApp.googleMaps);
    });

    test('getAvailableMapApps depends on platform', () {
      final svc = MapLauncherService(prefs);
      final apps = svc.getAvailableMapApps();
      expect(apps, isNotEmpty);
      expect(apps, contains(MapApp.googleMaps));
      if (Platform.isIOS) {
        expect(apps, contains(MapApp.appleMaps));
      }
    });
  });

  group('MapLauncherService.openLocation', () {
    late SharedPreferences prefs;
    late _UrlLauncherStub stub;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      stub = _UrlLauncherStub();
      stub.install();
    });

    tearDown(() {
      stub.uninstall();
    });

    test('launches Google Maps URL for given coordinates', () async {
      final svc = MapLauncherService(prefs);
      final ok = await svc.openLocation(
        latitude: 12.34,
        longitude: 56.78,
        useApp: MapApp.googleMaps,
      );
      expect(ok, isTrue);
      // The launched URL should reference the coordinates.
      expect(stub.launchCalls.last, contains('12.34'));
      expect(stub.launchCalls.last, contains('56.78'));
      expect(stub.launchCalls.last, contains('google.com/maps'));
    });

    test('launches Apple Maps URL when requested', () async {
      final svc = MapLauncherService(prefs);
      final ok = await svc.openLocation(
        latitude: 1.0,
        longitude: 2.0,
        useApp: MapApp.appleMaps,
      );
      expect(ok, isTrue);
      expect(stub.launchCalls.last, contains('maps.apple.com'));
      expect(stub.launchCalls.last, contains('1.0'));
      expect(stub.launchCalls.last, contains('2.0'));
    });

    test('encodes the place name in Google Maps URL', () async {
      final svc = MapLauncherService(prefs);
      await svc.openLocation(
        latitude: 1.0,
        longitude: 2.0,
        placeName: 'Cafe Coffee Day',
        useApp: MapApp.googleMaps,
      );
      // 'Cafe%20Coffee%20Day' is the URL-encoded version.
      expect(stub.launchCalls.last, contains('Cafe%20Coffee%20Day'));
    });

    test('encodes place name in Apple Maps URL', () async {
      final svc = MapLauncherService(prefs);
      await svc.openLocation(
        latitude: 1.0,
        longitude: 2.0,
        placeName: 'Eiffel Tower',
        useApp: MapApp.appleMaps,
      );
      expect(stub.launchCalls.last, contains('Eiffel%20Tower'));
    });

    test('returns false when canLaunch returns false for both apps',
        () async {
      stub.canLaunch = false;
      final svc = MapLauncherService(prefs);
      final ok = await svc.openLocation(
        latitude: 1,
        longitude: 2,
        useApp: MapApp.googleMaps,
      );
      expect(ok, isFalse);
    });

    test('returns false when launchUrl throws', () async {
      // Replace the handler with one that throws to force the catch path.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
        throw PlatformException(code: 'fail');
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherIosChannel, (call) async {
        throw PlatformException(code: 'fail');
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherAndroidChannel, (call) async {
        throw PlatformException(code: 'fail');
      });
      final svc = MapLauncherService(prefs);
      final ok = await svc.openLocation(
        latitude: 1,
        longitude: 2,
        useApp: MapApp.googleMaps,
      );
      expect(ok, isFalse);
    });
  });

  group('MapLauncherService.openGoogleMapsUrl', () {
    late SharedPreferences prefs;
    late _UrlLauncherStub stub;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      stub = _UrlLauncherStub();
      stub.install();
    });

    tearDown(() => stub.uninstall());

    test('launches the URL when canLaunch succeeds', () async {
      final svc = MapLauncherService(prefs);
      final ok = await svc.openGoogleMapsUrl('https://maps.google.com/?q=test');
      expect(ok, isTrue);
      expect(stub.launchCalls.single, contains('test'));
    });

    test('returns false when canLaunch returns false', () async {
      stub.canLaunch = false;
      final svc = MapLauncherService(prefs);
      final ok = await svc.openGoogleMapsUrl('https://maps.google.com/');
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
        throw PlatformException(code: 'boom');
      });
      final svc = MapLauncherService(prefs);
      final ok = await svc.openGoogleMapsUrl('not a uri at all');
      expect(ok, isFalse);
    });
  });

  group('MapLauncherService.openDirections', () {
    late SharedPreferences prefs;
    late _UrlLauncherStub stub;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      stub = _UrlLauncherStub();
      stub.install();
    });

    tearDown(() => stub.uninstall());

    test('Google Maps directions URL contains origin and destination',
        () async {
      final svc = MapLauncherService(prefs);
      final ok = await svc.openDirections(
        destinationLat: 10,
        destinationLng: 20,
        originLat: 1,
        originLng: 2,
        destinationName: 'Beach',
        useApp: MapApp.googleMaps,
      );
      expect(ok, isTrue);
      final url = stub.launchCalls.last;
      expect(url, contains('origin=1.0,2.0'));
      expect(url, contains('destination=10.0,20.0'));
      expect(url, contains('Beach'));
    });

    test('Google Maps directions URL omits origin when missing', () async {
      final svc = MapLauncherService(prefs);
      await svc.openDirections(
        destinationLat: 10,
        destinationLng: 20,
        useApp: MapApp.googleMaps,
      );
      final url = stub.launchCalls.last;
      expect(url, isNot(contains('origin=')));
      expect(url, contains('destination=10.0,20.0'));
    });

    test('Apple Maps directions URL contains saddr/daddr', () async {
      final svc = MapLauncherService(prefs);
      await svc.openDirections(
        destinationLat: 10,
        destinationLng: 20,
        originLat: 1,
        originLng: 2,
        useApp: MapApp.appleMaps,
      );
      final url = stub.launchCalls.last;
      expect(url, contains('dirflg=d'));
      expect(url, contains('saddr=1.0,2.0'));
      expect(url, contains('daddr=10.0,20.0'));
    });

    test('returns false when canLaunch is false', () async {
      stub.canLaunch = false;
      final svc = MapLauncherService(prefs);
      final ok = await svc.openDirections(
        destinationLat: 10,
        destinationLng: 20,
        useApp: MapApp.googleMaps,
      );
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
        throw PlatformException(code: 'boom');
      });
      final svc = MapLauncherService(prefs);
      final ok = await svc.openDirections(
        destinationLat: 10,
        destinationLng: 20,
        useApp: MapApp.googleMaps,
      );
      expect(ok, isFalse);
    });
  });
}
