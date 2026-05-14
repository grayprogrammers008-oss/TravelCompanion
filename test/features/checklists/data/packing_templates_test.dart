import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/checklists/data/packing_templates.dart';

void main() {
  group('PackingTemplate constructor', () {
    test('stores all required fields', () {
      const t = PackingTemplate(
        id: 'x',
        name: 'X',
        icon: '🎒',
        description: 'desc',
        items: ['a', 'b'],
        category: 'cat',
      );
      expect(t.id, 'x');
      expect(t.name, 'X');
      expect(t.icon, '🎒');
      expect(t.description, 'desc');
      expect(t.items, ['a', 'b']);
      expect(t.category, 'cat');
    });
  });

  group('PackingTemplates.all', () {
    test('contains the 12 built-in templates', () {
      expect(PackingTemplates.all.length, 12);
    });

    test('every template has an id, name, icon, description, items, category',
        () {
      for (final t in PackingTemplates.all) {
        expect(t.id, isNotEmpty);
        expect(t.name, isNotEmpty);
        expect(t.icon, isNotEmpty);
        expect(t.description, isNotEmpty);
        expect(t.items, isNotEmpty);
        expect(t.category, isNotEmpty);
      }
    });

    test('all template ids are unique', () {
      final ids = PackingTemplates.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('expected template ids are present', () {
      final ids = PackingTemplates.all.map((t) => t.id).toSet();
      const expected = {
        'essentials',
        'beach',
        'mountain',
        'business',
        'winter',
        'city',
        'family',
        'camping',
        'toiletries',
        'electronics',
        'international',
        'weekend',
      };
      expect(ids, expected);
    });
  });

  group('PackingTemplates.byCategory', () {
    test('returns templates with matching category', () {
      final essentials = PackingTemplates.byCategory('Essential');
      expect(essentials, isNotEmpty);
      expect(essentials.every((t) => t.category == 'Essential'), isTrue);
    });

    test('returns adventure templates (mountain, camping)', () {
      final adventure = PackingTemplates.byCategory('Adventure');
      final ids = adventure.map((t) => t.id).toSet();
      expect(ids, contains('mountain'));
      expect(ids, contains('camping'));
    });

    test('returns vacation templates (beach, city, weekend)', () {
      final vacation = PackingTemplates.byCategory('Vacation');
      final ids = vacation.map((t) => t.id).toSet();
      expect(ids, contains('beach'));
      expect(ids, contains('city'));
      expect(ids, contains('weekend'));
    });

    test('returns empty list for unknown category', () {
      expect(PackingTemplates.byCategory('Spaceship'), isEmpty);
    });
  });

  group('PackingTemplates.categories', () {
    test('contains all 6 distinct category names', () {
      final categories = PackingTemplates.categories.toSet();
      const expected = {
        'Essential',
        'Vacation',
        'Adventure',
        'Work',
        'Seasonal',
        'Family',
      };
      expect(categories, expected);
    });
  });

  group('PackingTemplates.byId', () {
    test('returns the matching template when id exists', () {
      final t = PackingTemplates.byId('beach');
      expect(t, isNotNull);
      expect(t!.id, 'beach');
      expect(t.name, 'Beach Vacation');
    });

    test('returns the essentials template', () {
      final t = PackingTemplates.byId('essentials');
      expect(t, isNotNull);
      expect(t!.category, 'Essential');
    });

    test('returns null when id is unknown', () {
      expect(PackingTemplates.byId('nonexistent'), isNull);
      expect(PackingTemplates.byId(''), isNull);
    });
  });
}
