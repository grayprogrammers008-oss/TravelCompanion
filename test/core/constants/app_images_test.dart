import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/constants/app_images.dart';

void main() {
  group('AppImages', () {
    test('destination paths constant is set', () {
      expect(AppImages.destinationsPath, isNotEmpty);
      expect(AppImages.destinationsPath, startsWith('assets/'));
    });

    test('defaultDestinations is non-empty and contains valid asset paths', () {
      expect(AppImages.defaultDestinations, isNotEmpty);
      for (final p in AppImages.defaultDestinations) {
        expect(p, startsWith('assets/'));
        expect(p, endsWith('.jpg'));
      }
    });

    test('destinationImageMap entries map to known asset paths', () {
      expect(AppImages.destinationImageMap, isNotEmpty);
      for (final entry in AppImages.destinationImageMap.entries) {
        expect(entry.key, isNotEmpty);
        expect(entry.value, startsWith('assets/'));
      }
    });

    test('illustration constants are non-empty assets', () {
      expect(AppImages.emptyTrips, startsWith('assets/'));
      expect(AppImages.emptyExpenses, startsWith('assets/'));
      expect(AppImages.emptyItinerary, startsWith('assets/'));
      expect(AppImages.emptyChecklists, startsWith('assets/'));
      expect(AppImages.errorState, startsWith('assets/'));
      expect(AppImages.noConnection, startsWith('assets/'));
    });

    test('placeholder constants are non-empty assets', () {
      expect(AppImages.tripPlaceholder, startsWith('assets/'));
      expect(AppImages.userAvatar, startsWith('assets/'));
    });

    group('getDestinationImage', () {
      test('returns a default destination when name is null', () {
        final result = AppImages.getDestinationImage(null, seed: 0);
        expect(AppImages.defaultDestinations, contains(result));
      });

      test('returns a default destination when name is empty', () {
        final result = AppImages.getDestinationImage('', seed: 1);
        expect(AppImages.defaultDestinations, contains(result));
      });

      test('matches a known destination keyword (case-insensitive)', () {
        final result = AppImages.getDestinationImage('Trip to BALI 2024');
        expect(result, AppImages.destinationImageMap['bali']);
      });

      test('falls back to a deterministic image for unknown names', () {
        final r1 = AppImages.getDestinationImage('Some Random Town');
        final r2 = AppImages.getDestinationImage('Some Random Town');
        expect(r1, r2);
        expect(AppImages.defaultDestinations, contains(r1));
      });
    });

    group('getRandomDestinationImage', () {
      test('uses seed to make a deterministic choice', () {
        final r1 = AppImages.getRandomDestinationImage(seed: 5);
        final r2 = AppImages.getRandomDestinationImage(seed: 5);
        expect(r1, r2);
      });

      test('returns a known destination', () {
        final r = AppImages.getRandomDestinationImage(seed: 12);
        expect(AppImages.defaultDestinations, contains(r));
      });

      test('handles negative seed via abs()', () {
        final r = AppImages.getRandomDestinationImage(seed: -7);
        expect(AppImages.defaultDestinations, contains(r));
      });
    });

    group('getDestinationImageByIndex', () {
      test('returns expected element', () {
        expect(
          AppImages.getDestinationImageByIndex(0),
          AppImages.defaultDestinations[0],
        );
      });

      test('wraps around using modulo', () {
        final n = AppImages.defaultDestinations.length;
        expect(
          AppImages.getDestinationImageByIndex(n),
          AppImages.defaultDestinations[0],
        );
        expect(
          AppImages.getDestinationImageByIndex(n + 3),
          AppImages.defaultDestinations[3],
        );
      });
    });

    group('getUserAvatar', () {
      test('returns provided url when non-null', () {
        expect(
          AppImages.getUserAvatar('https://example.com/me.jpg'),
          'https://example.com/me.jpg',
        );
      });

      test('returns default placeholder when null', () {
        expect(AppImages.getUserAvatar(null), AppImages.userAvatar);
      });
    });

    group('isAssetImage / isNetworkImage', () {
      test('detects asset paths', () {
        expect(AppImages.isAssetImage('assets/foo.png'), true);
        expect(AppImages.isAssetImage('https://example.com/x.png'), false);
        expect(AppImages.isAssetImage(null), false);
      });

      test('detects network paths', () {
        expect(AppImages.isNetworkImage('https://example.com/x.png'), true);
        expect(AppImages.isNetworkImage('http://example.com/x.png'), true);
        expect(AppImages.isNetworkImage('assets/x.png'), false);
        expect(AppImages.isNetworkImage(null), false);
      });
    });

    group('DestinationColors extension', () {
      test('returns a 2-element color pair for any string', () {
        final pair = 'Bali'.destinationColorPair;
        expect(pair.length, 2);
        for (final v in pair) {
          // 32-bit ARGB color
          expect(v, greaterThanOrEqualTo(0));
        }
      });

      test('same input produces same output', () {
        expect('Paris'.destinationColorPair, 'Paris'.destinationColorPair);
      });
    });
  });
}
