import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Service for fetching destination images from Unsplash API
///
/// Features:
/// - Fetches high-quality travel destination images
/// - Caches image URLs to reduce API calls
/// - Falls back to gradients on error
/// - Rate limiting aware (50 requests/hour on free tier)
class ImageService {
  // Unsplash Access Key - In production, move to environment variables
  // Get your key at: https://unsplash.com/developers
  static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY_HERE';
  static const String _baseUrl = 'https://api.unsplash.com';

  // Cache duration (7 days)
  static const Duration _cacheDuration = Duration(days: 7);

  // Singleton pattern
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // In-memory cache
  final Map<String, CachedImage> _memoryCache = {};

  /// Get image URL for a destination
  /// Returns null if API fails (caller should fallback to gradient)
  Future<String?> getDestinationImage(String destination) async {
    try {
      // Check in-memory cache first
      if (_memoryCache.containsKey(destination)) {
        final cached = _memoryCache[destination]!;
        if (!cached.isExpired) {
          return cached.url;
        } else {
          _memoryCache.remove(destination);
        }
      }

      // Check persistent cache
      final cachedUrl = await _getCachedUrl(destination);
      if (cachedUrl != null) {
        // Add to memory cache
        _memoryCache[destination] = CachedImage(
          url: cachedUrl,
          cachedAt: DateTime.now(),
        );
        return cachedUrl;
      }

      // If no API key configured, return null (use gradient fallback)
      if (_accessKey == 'YOUR_UNSPLASH_ACCESS_KEY_HERE') {
        print('⚠️  Unsplash API key not configured. Using gradient fallback.');
        return null;
      }

      // Fetch from Unsplash API
      final url = await _fetchFromUnsplash(destination);
      if (url != null) {
        // Cache the result
        await _cacheUrl(destination, url);
        _memoryCache[destination] = CachedImage(
          url: url,
          cachedAt: DateTime.now(),
        );
      }

      return url;
    } catch (e) {
      print('❌ Error fetching image for $destination: $e');
      return null; // Fallback to gradient
    }
  }

  /// Fetch image from Unsplash API
  Future<String?> _fetchFromUnsplash(String destination) async {
    try {
      // Create search query with travel-related keywords
      final query = _buildSearchQuery(destination);

      final uri = Uri.parse('$_baseUrl/photos/random').replace(
        queryParameters: {
          'query': query,
          'orientation': 'landscape',
          'content_filter': 'high', // Family-friendly content only
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Client-ID $_accessKey',
          'Accept-Version': 'v1',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Get regular size image (suitable for cards)
        final imageUrl = data['urls']['regular'] as String?;

        // Log attribution (Unsplash requires attribution)
        final photographerName = data['user']['name'] as String?;
        print('📸 Image by $photographerName on Unsplash');

        return imageUrl;
      } else if (response.statusCode == 403) {
        print('⚠️  Unsplash API rate limit reached. Using cached/gradient images.');
        return null;
      } else {
        print('⚠️  Unsplash API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Unsplash API call failed: $e');
      return null;
    }
  }

  /// Build search query for destination
  String _buildSearchQuery(String destination) {
    // Normalize destination name
    final normalized = destination.toLowerCase().trim();

    // Map common destination patterns to better search queries
    final queryMap = {
      'bali': 'bali indonesia temple beach',
      'paris': 'paris eiffel tower france',
      'tokyo': 'tokyo japan skyline',
      'new york': 'new york city manhattan',
      'london': 'london big ben uk',
      'rome': 'rome colosseum italy',
      'dubai': 'dubai burj khalifa',
      'singapore': 'singapore marina bay',
      'maldives': 'maldives beach resort',
      'switzerland': 'switzerland alps mountains',
      'iceland': 'iceland landscape',
      'amsterdam': 'amsterdam canal netherlands',
      'barcelona': 'barcelona spain sagrada',
      'santorini': 'santorini greece blue dome',
      'machu picchu': 'machu picchu peru',
      'taj mahal': 'taj mahal india agra',
      'great wall': 'great wall china',
      'kyoto': 'kyoto japan temple',
      'venice': 'venice italy canal',
      'sydney': 'sydney opera house australia',
    };

    // Check if we have a specific query mapping
    for (final entry in queryMap.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default: use destination name + travel keywords
    return '$destination travel landmark';
  }

  /// Cache image URL in SharedPreferences
  Future<void> _cacheUrl(String destination, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(destination);

      final cacheData = json.encode({
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString(cacheKey, cacheData);
    } catch (e) {
      print('⚠️  Failed to cache image URL: $e');
    }
  }

  /// Get cached image URL from SharedPreferences
  Future<String?> _getCachedUrl(String destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(destination);

      final cacheData = prefs.getString(cacheKey);
      if (cacheData == null) return null;

      final data = json.decode(cacheData) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(data['cachedAt'] as String);

      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) < _cacheDuration) {
        return data['url'] as String;
      } else {
        // Cache expired, remove it
        await prefs.remove(cacheKey);
        return null;
      }
    } catch (e) {
      print('⚠️  Failed to read cached image URL: $e');
      return null;
    }
  }

  /// Generate cache key for destination
  String _getCacheKey(String destination) {
    // Use MD5 hash for consistent key naming
    final bytes = utf8.encode(destination.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return 'destination_image_$digest';
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove all destination image cache keys
      for (final key in keys) {
        if (key.startsWith('destination_image_')) {
          await prefs.remove(key);
        }
      }

      // Clear memory cache
      _memoryCache.clear();

      print('✅ Image cache cleared');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
    }
  }

  /// Preload images for common destinations
  Future<void> preloadCommonDestinations() async {
    final commonDestinations = [
      'Bali',
      'Paris',
      'Tokyo',
      'New York',
      'London',
      'Rome',
      'Dubai',
      'Singapore',
    ];

    for (final destination in commonDestinations) {
      await getDestinationImage(destination);
      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

/// Cached image data
class CachedImage {
  final String url;
  final DateTime cachedAt;

  CachedImage({
    required this.url,
    required this.cachedAt,
  });

  bool get isExpired {
    return DateTime.now().difference(cachedAt) > const Duration(days: 7);
  }
}
