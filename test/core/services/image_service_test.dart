import 'package:flutter_test/flutter_test.dart';

import 'package:pathio/core/services/image_service.dart';

/// Tests for the [CachedImage] data class exported from image_service.dart.
///
/// The [ImageService] singleton itself owns Google Places API calls and an
/// in-memory cache that can't be cleared from outside; testing it would
/// require refactoring the singleton + injecting an HTTP client.
/// We cover the publicly-exposed [CachedImage] type here.

void main() {
  group('CachedImage', () {
    test('stores url and cachedAt as provided', () {
      final cachedAt = DateTime.utc(2024, 6, 1);
      final c = CachedImage(url: 'https://x.com/img.png', cachedAt: cachedAt);
      expect(c.url, 'https://x.com/img.png');
      expect(c.cachedAt, cachedAt);
    });

    test('isExpired is false when cached just now', () {
      final c = CachedImage(url: 'x', cachedAt: DateTime.now());
      expect(c.isExpired, isFalse);
    });

    test('isExpired is false when cached 6 days ago', () {
      final c = CachedImage(
        url: 'x',
        cachedAt: DateTime.now().subtract(const Duration(days: 6)),
      );
      expect(c.isExpired, isFalse);
    });

    test('isExpired is true when cached more than 7 days ago', () {
      final c = CachedImage(
        url: 'x',
        cachedAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(c.isExpired, isTrue);
    });

    test('isExpired is true for very old cache', () {
      final c = CachedImage(
        url: 'x',
        cachedAt: DateTime.now().subtract(const Duration(days: 365)),
      );
      expect(c.isExpired, isTrue);
    });
  });
}
