import 'package:flutter/material.dart';
import 'discover_place.dart';
import 'place_category.dart';

/// Weather condition types
enum WeatherCondition {
  sunny,
  rainy,
  stormy,
  snowy,
  foggy,
  windy,
  hot,
  cold;

  String get displayName {
    switch (this) {
      case WeatherCondition.sunny:
        return 'Sunny';
      case WeatherCondition.rainy:
        return 'Rainy';
      case WeatherCondition.stormy:
        return 'Stormy';
      case WeatherCondition.snowy:
        return 'Snowy';
      case WeatherCondition.foggy:
        return 'Foggy';
      case WeatherCondition.windy:
        return 'Windy';
      case WeatherCondition.hot:
        return 'Hot';
      case WeatherCondition.cold:
        return 'Cold';
    }
  }

  IconData get icon {
    switch (this) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny;
      case WeatherCondition.rainy:
        return Icons.water_drop;
      case WeatherCondition.stormy:
        return Icons.thunderstorm;
      case WeatherCondition.snowy:
        return Icons.ac_unit;
      case WeatherCondition.foggy:
        return Icons.foggy;
      case WeatherCondition.windy:
        return Icons.air;
      case WeatherCondition.hot:
        return Icons.whatshot;
      case WeatherCondition.cold:
        return Icons.severe_cold;
    }
  }

  Color get color {
    switch (this) {
      case WeatherCondition.sunny:
        return Colors.orange;
      case WeatherCondition.rainy:
        return Colors.blue;
      case WeatherCondition.stormy:
        return Colors.deepPurple;
      case WeatherCondition.snowy:
        return Colors.lightBlue;
      case WeatherCondition.foggy:
        return Colors.grey;
      case WeatherCondition.windy:
        return Colors.teal;
      case WeatherCondition.hot:
        return Colors.red;
      case WeatherCondition.cold:
        return Colors.indigo;
    }
  }

  /// Get suggested categories for this weather condition
  /// Using actual PlaceCategory values: beach, hillStation, heritage, adventure, wildlife, religious, nature, urban
  List<PlaceCategory> get suggestedCategories {
    switch (this) {
      case WeatherCondition.sunny:
        return [
          PlaceCategory.beach,
          PlaceCategory.nature,
          PlaceCategory.hillStation,
          PlaceCategory.adventure,
          PlaceCategory.wildlife,
        ];
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
        return [
          PlaceCategory.heritage, // Museums, indoor sites
          PlaceCategory.urban, // Shopping malls, indoor entertainment
          PlaceCategory.religious, // Indoor temples, churches
        ];
      case WeatherCondition.snowy:
        return [
          PlaceCategory.hillStation, // Mountain retreats
          PlaceCategory.heritage, // Indoor heritage sites
          PlaceCategory.urban, // City indoor activities
        ];
      case WeatherCondition.foggy:
        return [
          PlaceCategory.heritage, // Museums
          PlaceCategory.urban, // Indoor city activities
          PlaceCategory.religious, // Indoor worship places
        ];
      case WeatherCondition.windy:
        return [
          PlaceCategory.heritage, // Indoor sites
          PlaceCategory.urban, // Sheltered activities
          PlaceCategory.religious, // Indoor places
        ];
      case WeatherCondition.hot:
        return [
          PlaceCategory.beach, // Water activities
          PlaceCategory.hillStation, // Cool mountain air
          PlaceCategory.urban, // Air-conditioned places
        ];
      case WeatherCondition.cold:
        return [
          PlaceCategory.heritage, // Indoor sites
          PlaceCategory.urban, // Warm indoor places
          PlaceCategory.religious, // Indoor worship
        ];
    }
  }

  /// Get activities NOT recommended for this weather
  List<PlaceCategory> get notRecommendedCategories {
    switch (this) {
      case WeatherCondition.rainy:
      case WeatherCondition.stormy:
        return [
          PlaceCategory.beach,
          PlaceCategory.adventure,
          PlaceCategory.wildlife, // Safari not recommended in rain
          PlaceCategory.nature, // Outdoor nature spots
        ];
      case WeatherCondition.snowy:
        return [
          PlaceCategory.beach,
        ];
      case WeatherCondition.foggy:
        return [
          PlaceCategory.hillStation, // Dangerous mountain driving
          PlaceCategory.adventure, // Reduced visibility
        ];
      case WeatherCondition.hot:
        return [
          PlaceCategory.adventure, // Too hot for strenuous activities
        ];
      case WeatherCondition.cold:
        return [
          PlaceCategory.beach,
        ];
      default:
        return [];
    }
  }
}

/// Current weather data
class WeatherData {
  final double temperature; // in Celsius
  final double feelsLike;
  final WeatherCondition condition;
  final int humidity;
  final double windSpeed;
  final String description;
  final String locationName;
  final DateTime timestamp;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.locationName,
    required this.timestamp,
  });

  /// Get temperature category for suggestions
  WeatherCondition get temperatureCondition {
    if (temperature >= 35) return WeatherCondition.hot;
    if (temperature <= 10) return WeatherCondition.cold;
    return WeatherCondition.sunny;
  }

  /// Get the primary condition considering both weather and temperature
  WeatherCondition get effectiveCondition {
    // Extreme temperatures override other conditions
    if (temperature >= 38) return WeatherCondition.hot;
    if (temperature <= 5) return WeatherCondition.cold;
    return condition;
  }

  String get temperatureText => '${temperature.round()}°C';
  String get feelsLikeText => '${feelsLike.round()}°C';
  String get humidityText => '$humidity%';
  String get windSpeedText => '${windSpeed.round()} km/h';

  /// Create mock weather data for testing/demo
  factory WeatherData.mock({
    double? temperature,
    WeatherCondition? condition,
  }) {
    final temp = temperature ?? 28.0;
    return WeatherData(
      temperature: temp,
      feelsLike: temp + 2,
      condition: condition ?? WeatherCondition.sunny,
      humidity: 65,
      windSpeed: 12,
      description: 'Clear sky',
      locationName: 'Current Location',
      timestamp: DateTime.now(),
    );
  }

  /// Parse from OpenWeatherMap API response
  factory WeatherData.fromOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;

    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      condition: _parseWeatherCondition(weather['id'] as int),
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble() * 3.6, // m/s to km/h
      description: weather['description'] as String,
      locationName: json['name'] as String? ?? 'Unknown',
      timestamp: DateTime.now(),
    );
  }

  static WeatherCondition _parseWeatherCondition(int weatherId) {
    // OpenWeatherMap weather condition codes
    // https://openweathermap.org/weather-conditions
    if (weatherId >= 200 && weatherId < 300) return WeatherCondition.stormy;
    if (weatherId >= 300 && weatherId < 400) return WeatherCondition.rainy;
    if (weatherId >= 500 && weatherId < 600) return WeatherCondition.rainy;
    if (weatherId >= 600 && weatherId < 700) return WeatherCondition.snowy;
    if (weatherId >= 700 && weatherId < 800) {
      if (weatherId == 741) return WeatherCondition.foggy;
      if (weatherId == 781) return WeatherCondition.stormy; // Tornado
      return WeatherCondition.foggy;
    }
    if (weatherId == 800) return WeatherCondition.sunny;
    if (weatherId > 800) return WeatherCondition.sunny; // Map cloudy to sunny for better UX
    return WeatherCondition.sunny;
  }
}

/// Weather-based place suggestion
class WeatherSuggestion {
  final DiscoverPlace place;
  final WeatherCondition weather;
  final String reason;
  final bool isIndoorActivity;
  final double relevanceScore;

  const WeatherSuggestion({
    required this.place,
    required this.weather,
    required this.reason,
    required this.isIndoorActivity,
    required this.relevanceScore,
  });
}

/// Engine for generating weather-based suggestions
class WeatherSuggestionEngine {
  /// Generate weather-appropriate place suggestions
  static List<WeatherSuggestion> generateSuggestions({
    required List<DiscoverPlace> allPlaces,
    required WeatherData weather,
    int limit = 10,
  }) {
    final effectiveCondition = weather.effectiveCondition;
    final suggestedCategories = effectiveCondition.suggestedCategories;
    final notRecommended = effectiveCondition.notRecommendedCategories;

    final suggestions = <WeatherSuggestion>[];

    for (final place in allPlaces) {
      // Skip places in not recommended categories
      if (notRecommended.contains(place.category)) continue;

      double score = 0.0;
      String reason = '';
      bool isIndoor = false;

      // Check if the place category is suggested for this weather
      if (suggestedCategories.contains(place.category)) {
        score += 0.5;
        isIndoor = _isIndoorCategory(place.category);

        reason = _generateReason(
          weather: effectiveCondition,
          category: place.category,
          isIndoor: isIndoor,
        );
      } else {
        // Still viable but not optimal
        score += 0.2;
        reason = 'Available nearby';
      }

      // Bonus for highly rated places
      if (place.rating != null && place.rating! >= 4.5) {
        score += 0.2;
      } else if (place.rating != null && place.rating! >= 4.0) {
        score += 0.1;
      }

      // Bonus for open places
      if (place.openNow == true) {
        score += 0.1;
      }

      // Only add places with good scores
      if (score >= 0.3) {
        suggestions.add(WeatherSuggestion(
          place: place,
          weather: effectiveCondition,
          reason: reason,
          isIndoorActivity: isIndoor,
          relevanceScore: score.clamp(0.0, 1.0),
        ));
      }
    }

    // Sort by relevance score
    suggestions.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return suggestions.take(limit).toList();
  }

  /// Indoor categories are: heritage (museums), urban (malls, entertainment), religious (temples, churches)
  static bool _isIndoorCategory(PlaceCategory category) {
    return [
      PlaceCategory.heritage, // Museums, monuments often have indoor areas
      PlaceCategory.urban, // Shopping malls, entertainment centers
      PlaceCategory.religious, // Temples, churches, mosques
    ].contains(category);
  }

  static String _generateReason({
    required WeatherCondition weather,
    required PlaceCategory category,
    required bool isIndoor,
  }) {
    switch (weather) {
      case WeatherCondition.sunny:
        if (isIndoor) {
          return 'Great weather to explore or stay cool inside';
        }
        return 'Perfect weather for outdoor activities';

      case WeatherCondition.rainy:
        return isIndoor ? 'Stay dry while having fun' : 'Covered area available';

      case WeatherCondition.stormy:
        return 'Safe indoor activity during the storm';

      case WeatherCondition.snowy:
        if (category == PlaceCategory.hillStation) {
          return 'Enjoy the winter wonderland';
        }
        return isIndoor ? 'Warm and cozy destination' : 'Beautiful snowy scenery';

      case WeatherCondition.foggy:
        return 'Great visibility for indoor activities';

      case WeatherCondition.windy:
        return 'Sheltered from the wind';

      case WeatherCondition.hot:
        if (category == PlaceCategory.beach) {
          return 'Cool off at the beach';
        }
        if (category == PlaceCategory.hillStation) {
          return 'Escape the heat in the mountains';
        }
        return isIndoor ? 'Air-conditioned comfort' : 'Refreshing activities';

      case WeatherCondition.cold:
        return 'Warm and comfortable environment';
    }
  }

  /// Get a summary message for current weather
  static String getWeatherSummary(WeatherData weather) {
    final condition = weather.effectiveCondition;

    switch (condition) {
      case WeatherCondition.sunny:
        return "It's a beautiful sunny day! Perfect for outdoor adventures.";
      case WeatherCondition.rainy:
        return "Rainy weather ahead. We recommend indoor activities.";
      case WeatherCondition.stormy:
        return "Storm warning! Best to stay indoors and safe.";
      case WeatherCondition.snowy:
        return "Snow is falling! Time for cozy indoor activities or mountain fun.";
      case WeatherCondition.foggy:
        return "Foggy conditions. Indoor activities are recommended.";
      case WeatherCondition.windy:
        return "Windy day! Consider sheltered places.";
      case WeatherCondition.hot:
        return "It's hot outside! Head to the beach or find air-conditioned spots.";
      case WeatherCondition.cold:
        return "Bundle up! It's cold outside. We recommend warm indoor spots.";
    }
  }
}
