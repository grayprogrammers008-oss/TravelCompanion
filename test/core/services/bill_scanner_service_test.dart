// Tests for the ParsedBillData value object exposed by BillScannerService.
//
// The BillScannerService class itself wraps Google ML Kit text recognition
// AND the Groq HTTP API. Both require platform channels and network access
// and are intentionally NOT tested here. The pure data model is fully
// testable.

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/bill_scanner_service.dart';

void main() {
  group('ParsedBillData.fromJson', () {
    test('parses fully populated payload', () {
      final p = ParsedBillData.fromJson({
        'total_amount': 250.5,
        'vendor_name': "Joe's Cafe",
        'category': 'Food',
        'date': '2024-06-15T12:00:00.000Z',
        'currency': 'USD',
        'description': 'Lunch',
        'confidence': 0.95,
        'raw_text': 'JOE\'S CAFE\nTOTAL: 250.50',
      });

      expect(p.totalAmount, equals(250.5));
      expect(p.vendorName, equals("Joe's Cafe"));
      expect(p.category, equals('Food'));
      expect(p.currency, equals('USD'));
      expect(p.description, equals('Lunch'));
      expect(p.confidence, equals(0.95));
      expect(p.rawText, contains('TOTAL'));
      expect(p.date, isNotNull);
      expect(p.date!.year, equals(2024));
      expect(p.date!.month, equals(6));
      expect(p.date!.day, equals(15));
    });

    test('handles missing optional fields', () {
      final p = ParsedBillData.fromJson({});
      expect(p.totalAmount, isNull);
      expect(p.vendorName, isNull);
      expect(p.category, isNull);
      expect(p.date, isNull);
      expect(p.description, isNull);
      // Defaults
      expect(p.currency, equals('INR'));
      expect(p.confidence, equals(0.0));
      expect(p.rawText, equals(''));
    });

    test('coerces numeric total from int', () {
      final p = ParsedBillData.fromJson({'total_amount': 100});
      expect(p.totalAmount, equals(100.0));
    });

    test('returns null date for invalid date string', () {
      final p = ParsedBillData.fromJson({'date': 'not-a-date'});
      expect(p.date, isNull);
    });

    test('coerces confidence from int', () {
      final p = ParsedBillData.fromJson({'confidence': 1});
      expect(p.confidence, equals(1.0));
    });
  });

  group('ParsedBillData.toJson', () {
    test('round-trips a populated instance', () {
      final original = ParsedBillData(
        totalAmount: 99.99,
        vendorName: 'Vendor',
        category: 'Travel',
        date: DateTime.utc(2024, 1, 2, 3, 4, 5),
        currency: 'EUR',
        description: 'Train ticket',
        confidence: 0.8,
        rawText: 'raw',
      );
      final json = original.toJson();
      expect(json['total_amount'], equals(99.99));
      expect(json['vendor_name'], equals('Vendor'));
      expect(json['category'], equals('Travel'));
      expect(json['currency'], equals('EUR'));
      expect(json['description'], equals('Train ticket'));
      expect(json['confidence'], equals(0.8));
      expect(json['raw_text'], equals('raw'));
      expect(json['date'], isNotNull);

      final reparsed = ParsedBillData.fromJson(json);
      expect(reparsed.totalAmount, equals(original.totalAmount));
      expect(reparsed.vendorName, equals(original.vendorName));
      expect(reparsed.category, equals(original.category));
      expect(reparsed.currency, equals(original.currency));
      expect(reparsed.description, equals(original.description));
      expect(reparsed.confidence, equals(original.confidence));
      expect(reparsed.rawText, equals(original.rawText));
      expect(reparsed.date, equals(original.date));
    });

    test('encodes null fields as null', () {
      const p = ParsedBillData();
      final json = p.toJson();
      expect(json['total_amount'], isNull);
      expect(json['vendor_name'], isNull);
      expect(json['category'], isNull);
      expect(json['date'], isNull);
      expect(json['description'], isNull);
    });
  });

  group('ParsedBillData.toString', () {
    test('contains key field values', () {
      final p = ParsedBillData(
        totalAmount: 42.0,
        vendorName: 'X',
        category: 'Y',
        currency: 'INR',
        confidence: 0.5,
      );
      final s = p.toString();
      expect(s, contains('42'));
      expect(s, contains('X'));
      expect(s, contains('Y'));
      expect(s, contains('INR'));
      expect(s, contains('0.5'));
    });
  });
}
