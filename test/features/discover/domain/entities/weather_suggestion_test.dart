import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/discover_place.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';
import 'package:travel_crew/features/discover/domain/entities/weather_suggestion.dart';

DiscoverPlace _place({
  String id = 'p',
  String name = 'P',
  PlaceCategory category = PlaceCategory.nature,
  double? rating,
  bool? openNow,
}) =>
    DiscoverPlace(
      placeId: id,
      name: name,
      types: const [],
      photos: const [],
      category: category,
      rating: rating,
      openNow: openNow,
    );

void main() {
  group('WeatherCondition', () {
    test('has 8 values', () {
      expect(WeatherCondition.values, hasLength(8));
    });

    test('every condition has displayName, icon, color', () {
      for (final c in WeatherCondition.values) {
        expect(c.displayName, isNotEmpty);
        expect(c.icon, isA<IconData>());
        expect(c.color, isA<Color>());
      }
    });

    test('display names are unique', () {
      final names = WeatherCondition.values.map((c) => c.displayName).toSet();
      expect(names.length, WeatherCondition.values.length);
    });
  });

  group('WeatherCondition.suggestedCategories', () {
    test('sunny suggests outdoor activities', () {
      final cats = WeatherCondition.sunny.suggestedCategories;
      expect(cats, contains(PlaceCategory.beach));
      expect(cats, contains(PlaceCategory.nature));
      expect(cats, contains(PlaceCategory.hillStation));
    });

    test('rainy suggests indoor activities', () {
      final cats = WeatherCondition.rainy.suggestedCategories;
      expect(cats, contains(PlaceCategory.heritage));
      expect(cats, contains(PlaceCategory.urban));
      expect(cats, isNot(contains(PlaceCategory.beach)));
    });

    test('hot suggests beach and hillStation', () {
      final cats = WeatherCondition.hot.suggestedCategories;
      expect(cats, contains(PlaceCategory.beach));
      expect(cats, contains(PlaceCategory.hillStation));
    });
  });

  group('WeatherCondition.notRecommendedCategories', () {
    test('rainy avoids beach and outdoor adventure', () {
      final cats = WeatherCondition.rainy.notRecommendedCategories;
      expect(cats, contains(PlaceCategory.beach));
      expect(cats, contains(PlaceCategory.adventure));
    });

    test('hot avoids strenuous adventure', () {
      expect(
        WeatherCondition.hot.notRecommendedCategories,
        contains(PlaceCategory.adventure),
      );
    });

    test('cold avoids beach', () {
      expect(
        WeatherCondition.cold.notRecommendedCategories,
        contains(PlaceCategory.beach),
      );
    });

    test('sunny / windy have no excluded categories (or as configured)', () {
      // sunny has no special exclusions in switch (default is empty)
      expect(WeatherCondition.sunny.notRecommendedCategories, isEmpty);
    });
  });

  group('WeatherData', () {
    test('mock factory provides default values', () {
      final w = WeatherData.mock();
      expect(w.temperature, 28.0);
      expect(w.condition, WeatherCondition.sunny);
      expect(w.humidity, 65);
      expect(w.locationName, 'Current Location');
    });

    test('mock factory respects overrides', () {
      final w = WeatherData.mock(
        temperature: 5.0,
        condition: WeatherCondition.snowy,
      );
      expect(w.temperature, 5.0);
      expect(w.condition, WeatherCondition.snowy);
    });

    test('feelsLike is +2°C above temperature in mock', () {
      final w = WeatherData.mock(temperature: 20.0);
      expect(w.feelsLike, 22.0);
    });

    test('temperatureText / feelsLikeText / humidityText / windSpeedText format correctly', () {
      final w = WeatherData(
        temperature: 23.4,
        feelsLike: 24.6,
        condition: WeatherCondition.sunny,
        humidity: 70,
        windSpeed: 12.7,
        description: 'clear',
        locationName: 'X',
        timestamp: DateTime(2025),
      );
      expect(w.temperatureText, '23°C');
      expect(w.feelsLikeText, '25°C');
      expect(w.humidityText, '70%');
      expect(w.windSpeedText, '13 km/h');
    });

    group('temperatureCondition', () {
      test('>=35 is hot', () {
        expect(WeatherData.mock(temperature: 35).temperatureCondition,
            WeatherCondition.hot);
        expect(WeatherData.mock(temperature: 40).temperatureCondition,
            WeatherCondition.hot);
      });

      test('<=10 is cold', () {
        expect(WeatherData.mock(temperature: 10).temperatureCondition,
            WeatherCondition.cold);
        expect(WeatherData.mock(temperature: -5).temperatureCondition,
            WeatherCondition.cold);
      });

      test('mid-range returns sunny', () {
        expect(WeatherData.mock(temperature: 25).temperatureCondition,
            WeatherCondition.sunny);
      });
    });

    group('effectiveCondition', () {
      test('extreme heat (>=38) overrides reported condition', () {
        final w = WeatherData(
          temperature: 40,
          feelsLike: 42,
          condition: WeatherCondition.rainy,
          humidity: 50,
          windSpeed: 5,
          description: '',
          locationName: 'X',
          timestamp: DateTime(2025),
        );
        expect(w.effectiveCondition, WeatherCondition.hot);
      });

      test('extreme cold (<=5) overrides reported condition', () {
        final w = WeatherData(
          temperature: 2,
          feelsLike: 0,
          condition: WeatherCondition.sunny,
          humidity: 50,
          windSpeed: 5,
          description: '',
          locationName: 'X',
          timestamp: DateTime(2025),
        );
        expect(w.effectiveCondition, WeatherCondition.cold);
      });

      test('mild temps preserve reported condition', () {
        final w = WeatherData(
          temperature: 22,
          feelsLike: 22,
          condition: WeatherCondition.foggy,
          humidity: 50,
          windSpeed: 5,
          description: '',
          locationName: 'X',
          timestamp: DateTime(2025),
        );
        expect(w.effectiveCondition, WeatherCondition.foggy);
      });
    });

    group('fromOpenWeatherMap', () {
      test('parses a sunny payload (id 800)', () {
        final json = {
          'main': {'temp': 22.5, 'feels_like': 24.0, 'humidity': 60},
          'weather': [
            {'id': 800, 'description': 'clear sky'}
          ],
          'wind': {'speed': 3.0}, // 3.0 m/s -> 10.8 km/h
          'name': 'Bangalore',
        };
        final w = WeatherData.fromOpenWeatherMap(json);
        expect(w.temperature, 22.5);
        expect(w.feelsLike, 24.0);
        expect(w.humidity, 60);
        expect(w.condition, WeatherCondition.sunny);
        expect(w.windSpeed, closeTo(10.8, 0.001));
        expect(w.locationName, 'Bangalore');
      });

      test('maps weather id ranges correctly', () {
        Map<String, dynamic> mk(int id) => {
              'main': {'temp': 20.0, 'feels_like': 20.0, 'humidity': 50},
              'weather': [
                {'id': id, 'description': ''}
              ],
              'wind': {'speed': 1.0},
              'name': 'X',
            };
        expect(WeatherData.fromOpenWeatherMap(mk(210)).condition,
            WeatherCondition.stormy); // 200-299
        expect(WeatherData.fromOpenWeatherMap(mk(310)).condition,
            WeatherCondition.rainy); // 300-399
        expect(WeatherData.fromOpenWeatherMap(mk(521)).condition,
            WeatherCondition.rainy); // 500-599
        expect(WeatherData.fromOpenWeatherMap(mk(601)).condition,
            WeatherCondition.snowy); // 600-699
        expect(WeatherData.fromOpenWeatherMap(mk(741)).condition,
            WeatherCondition.foggy); // mist=741
        expect(WeatherData.fromOpenWeatherMap(mk(781)).condition,
            WeatherCondition.stormy); // tornado
        expect(WeatherData.fromOpenWeatherMap(mk(800)).condition,
            WeatherCondition.sunny); // clear
        expect(WeatherData.fromOpenWeatherMap(mk(802)).condition,
            WeatherCondition.sunny); // clouds map to sunny
      });

      test('uses "Unknown" when name missing', () {
        final json = {
          'main': {'temp': 20.0, 'feels_like': 20.0, 'humidity': 50},
          'weather': [
            {'id': 800, 'description': ''}
          ],
          'wind': {'speed': 0.0},
        };
        expect(WeatherData.fromOpenWeatherMap(json).locationName, 'Unknown');
      });
    });
  });

  group('WeatherSuggestionEngine.generateSuggestions', () {
    test('skips places in not-recommended categories', () {
      final places = [
        _place(id: '1', category: PlaceCategory.beach), // excluded for rainy
        _place(id: '2', category: PlaceCategory.heritage), // suggested
      ];
      final w = WeatherData.mock(condition: WeatherCondition.rainy);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
      );
      // Beach must be filtered out
      expect(result.any((s) => s.place.placeId == '1'), isFalse);
      expect(result.any((s) => s.place.placeId == '2'), isTrue);
    });

    test('suggests nothing from empty input', () {
      final w = WeatherData.mock();
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: const [],
        weather: w,
      );
      expect(result, isEmpty);
    });

    test('respects limit parameter', () {
      final places = List.generate(
        20,
        (i) => _place(id: '$i', category: PlaceCategory.heritage),
      );
      final w = WeatherData.mock(condition: WeatherCondition.rainy);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
        limit: 5,
      );
      expect(result.length, 5);
    });

    test('higher rating yields higher relevance score', () {
      final places = [
        _place(id: 'low', category: PlaceCategory.heritage, rating: 3.0),
        _place(id: 'high', category: PlaceCategory.heritage, rating: 4.7),
      ];
      final w = WeatherData.mock(condition: WeatherCondition.rainy);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
      );
      // High should come first (sorted desc by score)
      expect(result.first.place.placeId, 'high');
      expect(result.first.relevanceScore,
          greaterThan(result.last.relevanceScore));
    });

    test('relevance score is clamped between 0 and 1', () {
      final places = [
        _place(
          id: 'p',
          category: PlaceCategory.heritage,
          rating: 4.9,
          openNow: true,
        ),
      ];
      final w = WeatherData.mock(condition: WeatherCondition.rainy);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
      );
      expect(result.first.relevanceScore, inInclusiveRange(0.0, 1.0));
    });

    test('marks indoor categories accordingly', () {
      final places = [_place(category: PlaceCategory.heritage)];
      final w = WeatherData.mock(condition: WeatherCondition.rainy);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
      );
      expect(result.first.isIndoorActivity, isTrue);
    });

    test('non-suggested categories without rating bonus get filtered out', () {
      // urban is NOT in sunny's suggested list and NOT excluded.
      // Without a rating bonus or openNow bonus, score is only 0.2 — below
      // the 0.3 inclusion threshold.
      final places = [_place(category: PlaceCategory.urban)];
      final w = WeatherData.mock(condition: WeatherCondition.sunny);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
      );
      expect(result, isEmpty);
    });

    test('non-suggested categories with rating bonus pass the threshold', () {
      // urban + rating 4.5 → 0.2 (else branch) + 0.2 (rating>=4.5) = 0.4 → included.
      final places = [_place(category: PlaceCategory.urban, rating: 4.5)];
      final w = WeatherData.mock(condition: WeatherCondition.sunny);
      final result = WeatherSuggestionEngine.generateSuggestions(
        allPlaces: places,
        weather: w,
      );
      expect(result, hasLength(1));
      expect(result.first.reason, 'Available nearby');
    });
  });

  group('WeatherSuggestionEngine.getWeatherSummary', () {
    test('returns a non-empty summary for every condition', () {
      for (final c in WeatherCondition.values) {
        final w = WeatherData(
          temperature: 25,
          feelsLike: 25,
          condition: c,
          humidity: 50,
          windSpeed: 5,
          description: '',
          locationName: 'X',
          timestamp: DateTime(2025),
        );
        final summary = WeatherSuggestionEngine.getWeatherSummary(w);
        expect(summary, isNotEmpty);
      }
    });

    test('hot summary mentions cooling off', () {
      final w = WeatherData.mock(temperature: 40); // forces effective hot
      final summary = WeatherSuggestionEngine.getWeatherSummary(w);
      expect(summary.toLowerCase(), anyOf(contains('hot'), contains('beach')));
    });
  });
}
