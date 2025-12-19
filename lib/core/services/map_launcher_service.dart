import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enum representing available map apps
enum MapApp {
  googleMaps('Google Maps', 'google_maps'),
  appleMaps('Apple Maps', 'apple_maps');

  final String displayName;
  final String key;

  const MapApp(this.displayName, this.key);

  static MapApp fromKey(String key) {
    return MapApp.values.firstWhere(
      (app) => app.key == key,
      orElse: () => Platform.isIOS ? MapApp.appleMaps : MapApp.googleMaps,
    );
  }
}

/// Service to launch maps and manage map app preference
class MapLauncherService {
  static const String _preferredMapAppKey = 'preferred_map_app';

  final SharedPreferences _prefs;

  MapLauncherService(this._prefs);

  /// Get the user's preferred map app
  MapApp get preferredMapApp {
    final key = _prefs.getString(_preferredMapAppKey);
    if (key != null) {
      return MapApp.fromKey(key);
    }
    // Default based on platform
    return Platform.isIOS ? MapApp.appleMaps : MapApp.googleMaps;
  }

  /// Set the user's preferred map app
  Future<void> setPreferredMapApp(MapApp app) async {
    await _prefs.setString(_preferredMapAppKey, app.key);
  }

  /// Get available map apps on this device
  List<MapApp> getAvailableMapApps() {
    if (Platform.isIOS) {
      return [MapApp.appleMaps, MapApp.googleMaps];
    } else {
      // Android - Google Maps is always available, Apple Maps is not
      return [MapApp.googleMaps];
    }
  }

  /// Open location in the preferred map app
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? placeName,
    MapApp? useApp,
  }) async {
    final app = useApp ?? preferredMapApp;

    try {
      final url = _buildMapUrl(
        app: app,
        latitude: latitude,
        longitude: longitude,
        placeName: placeName,
      );

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // Fallback to the other map app
      final fallbackApp = app == MapApp.googleMaps ? MapApp.appleMaps : MapApp.googleMaps;
      final fallbackUrl = _buildMapUrl(
        app: fallbackApp,
        latitude: latitude,
        longitude: longitude,
        placeName: placeName,
      );

      final fallbackUri = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(fallbackUri)) {
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      debugPrint('Error opening map: $e');
      return false;
    }
  }

  /// Open location using a Google Maps URL directly
  Future<bool> openGoogleMapsUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error opening Google Maps URL: $e');
      return false;
    }
  }

  String _buildMapUrl({
    required MapApp app,
    required double latitude,
    required double longitude,
    String? placeName,
  }) {
    switch (app) {
      case MapApp.googleMaps:
        // Google Maps URL with optional place name
        if (placeName != null && placeName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(placeName);
          return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedName';
        }
        return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      case MapApp.appleMaps:
        // Apple Maps URL
        if (placeName != null && placeName.isNotEmpty) {
          final encodedName = Uri.encodeComponent(placeName);
          return 'https://maps.apple.com/?q=$encodedName&ll=$latitude,$longitude';
        }
        return 'https://maps.apple.com/?ll=$latitude,$longitude';
    }
  }

  /// Build a directions URL to a location
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
    double? originLat,
    double? originLng,
    MapApp? useApp,
  }) async {
    final app = useApp ?? preferredMapApp;

    try {
      final url = _buildDirectionsUrl(
        app: app,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationName: destinationName,
        originLat: originLat,
        originLng: originLng,
      );

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error opening directions: $e');
      return false;
    }
  }

  String _buildDirectionsUrl({
    required MapApp app,
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
    double? originLat,
    double? originLng,
  }) {
    switch (app) {
      case MapApp.googleMaps:
        var url = 'https://www.google.com/maps/dir/?api=1';
        if (originLat != null && originLng != null) {
          url += '&origin=$originLat,$originLng';
        }
        url += '&destination=$destinationLat,$destinationLng';
        if (destinationName != null) {
          url += '&destination_place_id=${Uri.encodeComponent(destinationName)}';
        }
        return url;

      case MapApp.appleMaps:
        var url = 'https://maps.apple.com/?dirflg=d';
        if (originLat != null && originLng != null) {
          url += '&saddr=$originLat,$originLng';
        }
        url += '&daddr=$destinationLat,$destinationLng';
        return url;
    }
  }
}
