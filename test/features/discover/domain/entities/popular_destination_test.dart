import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/discover/domain/entities/popular_destination.dart';

void main() {
  group('PopularDestination constructor', () {
    test('stores required fields', () {
      const d = PopularDestination(
        id: 'goa',
        name: 'Goa',
        country: 'India',
        region: 'West India',
        description: 'Beach paradise',
        imageUrl: 'https://img/goa.jpg',
        latitude: 15.2993,
        longitude: 74.1240,
        highlights: ['Baga Beach'],
        bestTimeToVisit: 'November - February',
      );
      expect(d.id, 'goa');
      expect(d.name, 'Goa');
      expect(d.country, 'India');
      expect(d.highlights, ['Baga Beach']);
    });
  });

  group('PopularDestinations.all', () {
    test('returns a non-empty list', () {
      expect(PopularDestinations.all, isNotEmpty);
    });

    test('every destination has unique id', () {
      final ids = PopularDestinations.all.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate ids found: $ids');
    });

    test('every destination has non-empty required fields', () {
      for (final d in PopularDestinations.all) {
        expect(d.id, isNotEmpty);
        expect(d.name, isNotEmpty);
        expect(d.country, isNotEmpty);
        expect(d.region, isNotEmpty);
        expect(d.description, isNotEmpty);
        expect(d.imageUrl, startsWith('https://'));
        expect(d.highlights, isNotEmpty);
        expect(d.bestTimeToVisit, isNotEmpty);
      }
    });

    test('coordinates are within valid Earth ranges', () {
      for (final d in PopularDestinations.all) {
        expect(d.latitude, inInclusiveRange(-90.0, 90.0));
        expect(d.longitude, inInclusiveRange(-180.0, 180.0));
      }
    });
  });

  group('PopularDestinations.getCountries', () {
    test('returns sorted unique countries', () {
      final countries = PopularDestinations.getCountries();
      expect(countries, isNotEmpty);
      expect(countries.toSet().length, countries.length, reason: 'duplicates');
      final sorted = [...countries]..sort();
      expect(countries, sorted);
    });

    test('includes India', () {
      expect(PopularDestinations.getCountries(), contains('India'));
    });
  });

  group('PopularDestinations.getByCountry', () {
    test('returns only destinations for the given country', () {
      final indiaDests = PopularDestinations.getByCountry('India');
      expect(indiaDests, isNotEmpty);
      for (final d in indiaDests) {
        expect(d.country, 'India');
      }
    });

    test('returns empty for unknown country', () {
      expect(PopularDestinations.getByCountry('Atlantis'), isEmpty);
    });
  });

  group('PopularDestinations.groupByCountry', () {
    test('every destination appears under its country', () {
      final grouped = PopularDestinations.groupByCountry();
      for (final dest in PopularDestinations.all) {
        expect(grouped[dest.country], contains(dest));
      }
    });

    test('group counts equal getByCountry counts', () {
      final grouped = PopularDestinations.groupByCountry();
      for (final country in grouped.keys) {
        expect(
          grouped[country]!.length,
          PopularDestinations.getByCountry(country).length,
        );
      }
    });
  });

  group('PopularDestinations.getRegions', () {
    test('returns India regions only', () {
      final regions = PopularDestinations.getRegions();
      expect(regions, isNotEmpty);
      // All regions returned correspond to entries in the india list
      final indiaRegions = PopularDestinations.india.map((d) => d.region).toSet();
      expect(regions.toSet(), indiaRegions);
    });
  });

  group('PopularDestinations.getByRegion', () {
    test('groups India destinations by region', () {
      final byRegion = PopularDestinations.getByRegion();
      // Every India destination is present
      for (final d in PopularDestinations.india) {
        expect(byRegion[d.region], contains(d));
      }
    });
  });

  group('CountryInfo.getInfo', () {
    test('returns metadata for known countries', () {
      const knownCountries = [
        'India', 'Thailand', 'Japan', 'Indonesia', 'Singapore',
        'UAE', 'France', 'Italy', 'United Kingdom', 'USA',
        'Australia', 'Maldives', 'Switzerland',
      ];
      for (final c in knownCountries) {
        final info = CountryInfo.getInfo(c);
        expect(info.name, c);
        expect(info.flag, isNotEmpty);
        expect(info.icon, isA<IconData>());
        expect(info.color, isA<Color>());
      }
    });

    test('returns generic info for unknown country', () {
      final info = CountryInfo.getInfo('Atlantis');
      expect(info.name, 'Atlantis');
      expect(info.flag, '🌍');
      expect(info.icon, Icons.place);
    });

    test('India uses saffron color and Hindu temple icon', () {
      final info = CountryInfo.getInfo('India');
      expect(info.color, const Color(0xFFFF9933));
      expect(info.icon, Icons.temple_hindu);
      expect(info.flag, '🇮🇳');
    });
  });

  group('RegionInfo.getInfo', () {
    test('returns metadata for North/South/West/East India', () {
      const known = ['North India', 'South India', 'West India', 'East India'];
      for (final r in known) {
        final info = RegionInfo.getInfo(r);
        expect(info.name, r);
        expect(info.icon, isA<IconData>());
        expect(info.color, isA<Color>());
      }
    });

    test('returns "Other" fallback for unknown region', () {
      final info = RegionInfo.getInfo('Mars Valley');
      expect(info.name, 'Other');
      expect(info.icon, Icons.place);
    });
  });
}
