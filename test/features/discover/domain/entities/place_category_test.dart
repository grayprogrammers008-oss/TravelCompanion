import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/place_category.dart';

void main() {
  group('PlaceCategory enum', () {
    test('has 11 categories', () {
      expect(PlaceCategory.values, hasLength(11));
    });

    test('contains all expected values', () {
      const expected = {
        PlaceCategory.beach,
        PlaceCategory.hillStation,
        PlaceCategory.heritage,
        PlaceCategory.adventure,
        PlaceCategory.wildlife,
        PlaceCategory.religious,
        PlaceCategory.nature,
        PlaceCategory.urban,
        PlaceCategory.familyKids,
        PlaceCategory.pilgrimage,
        PlaceCategory.seniorFriendly,
      };
      expect(PlaceCategory.values.toSet(), expected);
    });
  });

  group('PlaceCategoryExtension.displayName', () {
    test('returns user-facing label for every category', () {
      const expected = {
        PlaceCategory.beach: 'Beaches',
        PlaceCategory.hillStation: 'Hill Stations',
        PlaceCategory.heritage: 'Heritage',
        PlaceCategory.adventure: 'Adventure',
        PlaceCategory.wildlife: 'Wildlife',
        PlaceCategory.religious: 'Religious',
        PlaceCategory.nature: 'Nature',
        PlaceCategory.urban: 'Urban',
        PlaceCategory.familyKids: 'Family & Kids',
        PlaceCategory.pilgrimage: 'Pilgrimage',
        PlaceCategory.seniorFriendly: 'Senior Friendly',
      };
      for (final entry in expected.entries) {
        expect(entry.key.displayName, entry.value);
      }
    });

    test('display names are unique', () {
      final names = PlaceCategory.values.map((c) => c.displayName).toSet();
      expect(names.length, PlaceCategory.values.length);
    });
  });

  group('PlaceCategoryExtension.icon', () {
    test('returns a non-null IconData for every category', () {
      for (final c in PlaceCategory.values) {
        expect(c.icon, isA<IconData>());
      }
    });

    test('beach uses beach_access icon', () {
      expect(PlaceCategory.beach.icon, Icons.beach_access);
    });

    test('hillStation uses terrain icon', () {
      expect(PlaceCategory.hillStation.icon, Icons.terrain);
    });

    test('familyKids uses family_restroom icon', () {
      expect(PlaceCategory.familyKids.icon, Icons.family_restroom);
    });

    test('seniorFriendly uses elderly icon', () {
      expect(PlaceCategory.seniorFriendly.icon, Icons.elderly);
    });
  });

  group('PlaceCategoryExtension.color', () {
    test('returns a non-null Color for every category', () {
      for (final c in PlaceCategory.values) {
        expect(c.color, isA<Color>());
      }
    });

    test('beach is cyan-ish', () {
      expect(PlaceCategory.beach.color, const Color(0xFF00BCD4));
    });

    test('hillStation is green', () {
      expect(PlaceCategory.hillStation.color, const Color(0xFF4CAF50));
    });
  });

  group('PlaceCategoryExtension.googlePlaceType', () {
    test('keyword-only categories return null', () {
      expect(PlaceCategory.beach.googlePlaceType, isNull);
      expect(PlaceCategory.hillStation.googlePlaceType, isNull);
      expect(PlaceCategory.heritage.googlePlaceType, isNull);
      expect(PlaceCategory.adventure.googlePlaceType, isNull);
      expect(PlaceCategory.wildlife.googlePlaceType, isNull);
      expect(PlaceCategory.religious.googlePlaceType, isNull);
      expect(PlaceCategory.pilgrimage.googlePlaceType, isNull);
    });

    test('typed categories return the expected type', () {
      expect(PlaceCategory.nature.googlePlaceType, 'park');
      expect(PlaceCategory.urban.googlePlaceType, 'point_of_interest');
      expect(PlaceCategory.familyKids.googlePlaceType, 'amusement_park');
      expect(PlaceCategory.seniorFriendly.googlePlaceType, 'park');
    });
  });

  group('PlaceCategoryExtension.googlePlaceKeyword', () {
    test('returns a non-empty keyword for every category', () {
      for (final c in PlaceCategory.values) {
        expect(c.googlePlaceKeyword, isNotEmpty);
      }
    });

    test('keywords are short (<=5 words)', () {
      for (final c in PlaceCategory.values) {
        final wordCount = c.googlePlaceKeyword.split(' ').length;
        expect(wordCount, lessThanOrEqualTo(5),
            reason: '${c.name} keyword "${c.googlePlaceKeyword}" too long');
      }
    });

    test('beach keyword is "beach"', () {
      expect(PlaceCategory.beach.googlePlaceKeyword, 'beach');
    });
  });

  group('PlaceCategoryExtension.description', () {
    test('returns a non-empty description for every category', () {
      for (final c in PlaceCategory.values) {
        expect(c.description, isNotEmpty);
      }
    });

    test('descriptions are unique', () {
      final descs = PlaceCategory.values.map((c) => c.description).toSet();
      expect(descs.length, PlaceCategory.values.length);
    });
  });

  group('PlaceCategoryExtension.sampleImageUrl', () {
    test('returns a https URL for every category', () {
      for (final c in PlaceCategory.values) {
        expect(c.sampleImageUrl, startsWith('https://'));
      }
    });

    test('image URLs are unique', () {
      final urls = PlaceCategory.values.map((c) => c.sampleImageUrl).toSet();
      expect(urls.length, PlaceCategory.values.length);
    });
  });
}
