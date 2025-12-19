/// Parses Google Maps URLs and extracts location data
class GoogleMapsUrlParser {
  /// Parsed location data from a Google Maps URL
  static ParsedLocation? parse(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      // Handle different Google Maps URL formats

      // Format 1: https://maps.google.com/maps?q=lat,lng
      // Format 2: https://www.google.com/maps?q=lat,lng
      // Format 3: https://goo.gl/maps/xxxxx (short URL - just return the URL for name extraction)
      // Format 4: https://maps.app.goo.gl/xxxxx (new short URL format)
      // Format 5: https://www.google.com/maps/place/Name/@lat,lng,zoom
      // Format 6: https://www.google.com/maps/@lat,lng,zoom
      // Format 7: https://maps.google.com/?q=lat,lng
      // Format 8: https://www.google.com/maps/search/?api=1&query=lat,lng

      final host = uri.host.toLowerCase();

      // Check if it's a Google Maps URL
      if (!_isGoogleMapsUrl(host)) {
        return null;
      }

      // Try to extract coordinates from query parameters
      final queryCoords = _extractFromQueryParams(uri);
      if (queryCoords != null) return queryCoords;

      // Try to extract from path (place URLs)
      final pathCoords = _extractFromPath(uri);
      if (pathCoords != null) return pathCoords;

      // For short URLs, we can't extract coordinates directly
      // But we can still use the URL for reference
      if (host.contains('goo.gl')) {
        return ParsedLocation(
          originalUrl: url,
          isShortUrl: true,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static bool _isGoogleMapsUrl(String host) {
    return host.contains('google.com') ||
        host.contains('google.co') ||
        host.contains('goo.gl') ||
        host.contains('maps.app');
  }

  static ParsedLocation? _extractFromQueryParams(Uri uri) {
    // Check 'q' parameter (most common)
    final q = uri.queryParameters['q'] ?? uri.queryParameters['query'];
    if (q != null) {
      final coords = _parseCoordinateString(q);
      if (coords != null) {
        return ParsedLocation(
          latitude: coords.$1,
          longitude: coords.$2,
          originalUrl: uri.toString(),
        );
      }
      // If q is not coordinates, it might be a place name
      return ParsedLocation(
        placeName: q,
        originalUrl: uri.toString(),
      );
    }

    // Check 'll' parameter (latitude,longitude)
    final ll = uri.queryParameters['ll'];
    if (ll != null) {
      final coords = _parseCoordinateString(ll);
      if (coords != null) {
        return ParsedLocation(
          latitude: coords.$1,
          longitude: coords.$2,
          originalUrl: uri.toString(),
        );
      }
    }

    return null;
  }

  static ParsedLocation? _extractFromPath(Uri uri) {
    final path = uri.path;

    // Format: /maps/place/PlaceName/@lat,lng,zoom
    final placeMatch = RegExp(r'/place/([^/@]+)/@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(path);
    if (placeMatch != null) {
      final placeName = Uri.decodeComponent(placeMatch.group(1)!).replaceAll('+', ' ');
      final lat = double.tryParse(placeMatch.group(2)!);
      final lng = double.tryParse(placeMatch.group(3)!);
      if (lat != null && lng != null) {
        return ParsedLocation(
          latitude: lat,
          longitude: lng,
          placeName: placeName,
          originalUrl: uri.toString(),
        );
      }
    }

    // Format: /maps/@lat,lng,zoom
    final coordMatch = RegExp(r'/@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(path);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(2)!);
      if (lat != null && lng != null) {
        return ParsedLocation(
          latitude: lat,
          longitude: lng,
          originalUrl: uri.toString(),
        );
      }
    }

    // Format: /maps/place/PlaceName (without coordinates)
    final placeOnlyMatch = RegExp(r'/place/([^/@?]+)').firstMatch(path);
    if (placeOnlyMatch != null) {
      final placeName = Uri.decodeComponent(placeOnlyMatch.group(1)!).replaceAll('+', ' ');
      return ParsedLocation(
        placeName: placeName,
        originalUrl: uri.toString(),
      );
    }

    return null;
  }

  static (double, double)? _parseCoordinateString(String str) {
    // Try to parse "lat,lng" format
    final parts = str.split(',');
    if (parts.length >= 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
        return (lat, lng);
      }
    }
    return null;
  }

  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Check if a string is likely a Google Maps URL
  static bool isGoogleMapsUrl(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('google.com/maps') ||
        lowerText.contains('maps.google.com') ||
        lowerText.contains('goo.gl/maps') ||
        lowerText.contains('maps.app.goo.gl');
  }

  /// Extract Google Maps URL from shared text (may contain other text around the URL)
  static String? extractUrl(String sharedText) {
    // Common URL patterns for Google Maps
    final patterns = [
      RegExp(r'https?://(?:www\.)?google\.com/maps[^\s]*'),
      RegExp(r'https?://maps\.google\.com[^\s]*'),
      RegExp(r'https?://goo\.gl/maps/[^\s]*'),
      RegExp(r'https?://maps\.app\.goo\.gl/[^\s]*'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(sharedText);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }
}

/// Represents a parsed location from a Google Maps URL
class ParsedLocation {
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? placeId;
  final String originalUrl;
  final bool isShortUrl;

  ParsedLocation({
    this.latitude,
    this.longitude,
    this.placeName,
    this.placeId,
    required this.originalUrl,
    this.isShortUrl = false,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  String toString() {
    return 'ParsedLocation(lat: $latitude, lng: $longitude, name: $placeName, url: $originalUrl)';
  }
}
