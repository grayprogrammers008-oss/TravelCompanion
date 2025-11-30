import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Place model for location search results
class Place {
  final String displayName;
  final String name;
  final String? city;
  final String? state;
  final String? country;
  final double latitude;
  final double longitude;
  final String type;

  const Place({
    required this.displayName,
    required this.name,
    this.city,
    this.state,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  /// Get a formatted short name for display
  String get shortName {
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (city != null && city!.isNotEmpty && city != name) parts.add(city!);
    if (state != null && state!.isNotEmpty && state != city) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.take(3).join(', ');
  }

  /// Get icon based on place type
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
      case 'village':
        return '🏙️';
      case 'country':
        return '🌍';
      case 'state':
      case 'region':
        return '📍';
      case 'island':
        return '🏝️';
      case 'beach':
        return '🏖️';
      case 'mountain':
        return '⛰️';
      default:
        return '📍';
    }
  }

  factory Place.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    // Extract name from various fields
    String name = json['name'] as String? ?? '';
    if (name.isEmpty) {
      name = address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['municipality'] as String? ??
          address['county'] as String? ??
          address['state'] as String? ??
          address['country'] as String? ??
          '';
    }

    return Place(
      displayName: json['display_name'] as String? ?? '',
      name: name,
      city: address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['municipality'] as String?,
      state: address['state'] as String? ?? address['region'] as String?,
      country: address['country'] as String?,
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
      type: json['type'] as String? ?? 'place',
    );
  }

  @override
  String toString() => shortName;
}

/// Service for searching places using OpenStreetMap Nominatim API
///
/// Features:
/// - Search cities, towns, countries, regions
/// - Debounced API calls to respect rate limits
/// - Caching for repeated searches
/// - No API key required (free service)
class PlaceSearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  final http.Client _client;
  final Map<String, List<Place>> _cache = {};
  Timer? _debounceTimer;

  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for places matching the query
  ///
  /// Returns a list of [Place] objects matching the search query.
  /// Results are filtered to show cities, towns, countries, and regions.
  /// Debounces requests to respect Nominatim's 1 request/second limit.
  Future<List<Place>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final trimmedQuery = query.trim().toLowerCase();

    // Check cache first
    if (_cache.containsKey(trimmedQuery)) {
      return _cache[trimmedQuery]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        // Filter to show relevant place types for travel destinations
        'featuretype': 'city,town,village,country,state,island',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'TravelCompanion/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final places = data
            .map((json) => Place.fromNominatim(json as Map<String, dynamic>))
            .where((place) => place.name.isNotEmpty)
            .toList();

        // Cache the results
        _cache[trimmedQuery] = places;

        return places;
      } else {
        if (kDebugMode) {
          debugPrint('Place search failed: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Place search error: $e');
      }
      return [];
    }
  }

  /// Search with debouncing for real-time typing
  ///
  /// Use this when searching as user types to avoid hitting rate limits.
  /// Returns results via callback to handle async nature of debouncing.
  void searchPlacesDebounced(
    String query,
    void Function(List<Place> places) onResults,
  ) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      onResults([]);
      return;
    }

    _debounceTimer = Timer(_debounceDelay, () async {
      final results = await searchPlaces(query);
      onResults(results);
    });
  }

  /// Clear the search cache
  void clearCache() {
    _cache.clear();
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _client.close();
  }
}
