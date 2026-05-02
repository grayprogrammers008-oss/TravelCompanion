// Tests for VoiceChecklistParser and VoiceItineraryParser - pure parsers.

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/voice_input_service.dart';

void main() {
  group('VoiceChecklistParser.parse', () {
    test('returns empty list for blank text', () {
      expect(VoiceChecklistParser.parse(''), isEmpty);
      expect(VoiceChecklistParser.parse('   '), isEmpty);
    });

    test('strips common "add" prefix', () {
      final items = VoiceChecklistParser.parse('add toothbrush');
      expect(items, equals(['Toothbrush']));
    });

    test('strips "pack" prefix', () {
      final items = VoiceChecklistParser.parse('pack passport');
      expect(items, equals(['Passport']));
    });

    test('splits items on commas', () {
      final items =
          VoiceChecklistParser.parse('toothbrush, toothpaste, soap');
      expect(items, equals(['Toothbrush', 'Toothpaste', 'Soap']));
    });

    test('splits items on "and"', () {
      final items = VoiceChecklistParser.parse('shirts and pants and shoes');
      expect(items, equals(['Shirts', 'Pants', 'Shoes']));
    });

    test('splits on "then" and "also"', () {
      final items = VoiceChecklistParser.parse(
          'phone charger then power bank also headphones');
      expect(items, contains('Phone charger'));
      expect(items, contains('Power bank'));
      expect(items, contains('Headphones'));
    });

    test('removes leading articles like "a", "an", "the"', () {
      final items = VoiceChecklistParser.parse('a hat, the sunglasses, an umbrella');
      expect(items, equals(['Hat', 'Sunglasses', 'Umbrella']));
    });

    test('capitalizes first letter of each item', () {
      final items = VoiceChecklistParser.parse('camera, batteries');
      for (final item in items) {
        expect(item[0], equals(item[0].toUpperCase()));
      }
    });

    test('removes trailing punctuation', () {
      final items = VoiceChecklistParser.parse('book!, magazine?');
      expect(items, equals(['Book', 'Magazine']));
    });

    test('handles "remember to" prefix', () {
      final items = VoiceChecklistParser.parse('remember to bring keys');
      expect(items.first, contains('keys'));
    });

    test('drops empty fragments', () {
      final items = VoiceChecklistParser.parse('phone, , charger');
      expect(items.where((e) => e.isEmpty), isEmpty);
      expect(items.length, equals(2));
    });
  });

  group('VoiceItineraryParser.parse', () {
    test('extracts a basic title', () {
      final result = VoiceItineraryParser.parse('explore old town');
      expect(result.title.toLowerCase(), contains('old town'));
      expect(result.hasTitle, isTrue);
    });

    test('strips "visit" prefix from title', () {
      final result = VoiceItineraryParser.parse('visit the museum');
      expect(result.title.toLowerCase(), isNot(startsWith('visit')));
    });

    test('preserves the raw text', () {
      const text = 'visit the temple at 10am';
      final result = VoiceItineraryParser.parse(text);
      expect(result.rawText, equals(text));
    });

    test('extracts time with am/pm', () {
      final result = VoiceItineraryParser.parse('breakfast at 8 am');
      expect(result.startTime, equals(const TimeOfDay(hour: 8, minute: 0)));
    });

    test('extracts time with minutes', () {
      final result = VoiceItineraryParser.parse('meeting at 10:30 am');
      expect(result.startTime, equals(const TimeOfDay(hour: 10, minute: 30)));
    });

    test('converts pm hours to 24-hour', () {
      final result = VoiceItineraryParser.parse('dinner at 7 pm');
      expect(result.startTime, equals(const TimeOfDay(hour: 19, minute: 0)));
    });

    test('handles 12 am as midnight', () {
      final result = VoiceItineraryParser.parse('arrive at 12 am');
      expect(result.startTime, equals(const TimeOfDay(hour: 0, minute: 0)));
    });

    test('extracts named time keywords - morning', () {
      final result = VoiceItineraryParser.parse('walk in the morning');
      expect(result.startTime, equals(const TimeOfDay(hour: 9, minute: 0)));
    });

    test('extracts named time keywords - evening', () {
      final result = VoiceItineraryParser.parse('stroll in the evening');
      expect(result.startTime, equals(const TimeOfDay(hour: 18, minute: 0)));
    });

    test('extracts named time keywords - lunch', () {
      final result = VoiceItineraryParser.parse('grab lunch');
      expect(result.startTime, equals(const TimeOfDay(hour: 12, minute: 0)));
    });

    test('extracts duration in hours', () {
      final result = VoiceItineraryParser.parse('hike for 2 hours');
      expect(result.duration, equals(120));
    });

    test('extracts duration in minutes', () {
      final result = VoiceItineraryParser.parse('quick stop for 30 minutes');
      expect(result.duration, equals(30));
    });

    test('extracts fractional hours', () {
      final result = VoiceItineraryParser.parse('class for 1.5 hours');
      expect(result.duration, equals(90));
    });

    test('returns no time when none mentioned', () {
      final result = VoiceItineraryParser.parse('walk around');
      expect(result.startTime, isNull);
      expect(result.hasTime, isFalse);
    });
  });

  group('VoiceItineraryParser.parseMultiple', () {
    test('splits on "then"', () {
      final items = VoiceItineraryParser.parseMultiple(
          'visit museum then lunch then explore market');
      expect(items.length, equals(3));
    });

    test('splits on numbered list', () {
      final items = VoiceItineraryParser.parseMultiple(
          '1. visit museum 2. lunch at cafe 3. explore market');
      expect(items.length, greaterThanOrEqualTo(2));
    });

    test('returns empty list when input is empty', () {
      final items = VoiceItineraryParser.parseMultiple('');
      expect(items, isEmpty);
    });
  });

  group('ItineraryItemDetails', () {
    test('hasTitle reflects non-empty title', () {
      final d = ItineraryItemDetails(title: 'Walk', rawText: 'walk');
      expect(d.hasTitle, isTrue);
    });

    test('hasTitle is false for empty title', () {
      final d = ItineraryItemDetails(title: '', rawText: '');
      expect(d.hasTitle, isFalse);
    });

    test('hasLocation is false for null', () {
      final d = ItineraryItemDetails(title: 'X', rawText: 'X');
      expect(d.hasLocation, isFalse);
    });

    test('hasLocation is false for empty string', () {
      final d =
          ItineraryItemDetails(title: 'X', rawText: 'X', location: '');
      expect(d.hasLocation, isFalse);
    });

    test('hasLocation is true when set', () {
      final d = ItineraryItemDetails(
          title: 'X', rawText: 'X', location: 'Paris');
      expect(d.hasLocation, isTrue);
    });

    test('endTime is null without start or duration', () {
      final d = ItineraryItemDetails(title: 'X', rawText: 'X');
      expect(d.endTime, isNull);
    });

    test('endTime adds duration to start time', () {
      final d = ItineraryItemDetails(
        title: 'X',
        rawText: 'X',
        startTime: const TimeOfDay(hour: 10, minute: 0),
        duration: 90,
      );
      expect(d.endTime, equals(const TimeOfDay(hour: 11, minute: 30)));
    });

    test('endTime wraps around 24h boundary', () {
      final d = ItineraryItemDetails(
        title: 'X',
        rawText: 'X',
        startTime: const TimeOfDay(hour: 23, minute: 0),
        duration: 120,
      );
      expect(d.endTime, equals(const TimeOfDay(hour: 1, minute: 0)));
    });

    test('toString contains key fields', () {
      final d = ItineraryItemDetails(
        title: 'Walk',
        rawText: 'walk',
        location: 'Park',
        duration: 60,
      );
      final s = d.toString();
      expect(s, contains('Walk'));
      expect(s, contains('Park'));
      expect(s, contains('60'));
    });
  });
}
