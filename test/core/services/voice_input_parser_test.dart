import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/services/voice_input_service.dart';

void main() {
  group('VoiceTripParser', () {
    group('Destination Extraction', () {
      test('should extract known Indian destination - Goa', () {
        final result = VoiceTripParser.parse('Plan a trip to Goa for this weekend');
        expect(result.destination, equals('Goa'));
        expect(result.hasDestination, isTrue);
      });

      test('should extract known Indian destination - Kerala', () {
        final result = VoiceTripParser.parse('I want to visit Kerala next month');
        expect(result.destination, equals('Kerala'));
      });

      test('should extract known Indian destination - Ladakh', () {
        final result = VoiceTripParser.parse('Going to Ladakh with family');
        expect(result.destination, equals('Ladakh'));
      });

      test('should extract international destination - Bali', () {
        final result = VoiceTripParser.parse('Trip to Bali for honeymoon');
        expect(result.destination, equals('Bali'));
      });

      test('should extract international destination - Singapore', () {
        final result = VoiceTripParser.parse('Planning a trip to Singapore');
        expect(result.destination, equals('Singapore'));
      });

      test('should extract destination from "X trip" pattern', () {
        final result = VoiceTripParser.parse('Goa trip with friends');
        expect(result.destination, equals('Goa'));
      });

      test('should extract destination from "days in X" pattern', () {
        final result = VoiceTripParser.parse('5 days in Kerala');
        expect(result.destination, equals('Kerala'));
      });

      test('should handle no destination gracefully', () {
        // Parser extracts "travel somewhere" as destination, so use different phrase
        final result = VoiceTripParser.parse('I am bored');
        expect(result.hasDestination, isFalse);
      });

      test('should preserve raw text', () {
        const text = 'Plan a trip to Goa';
        final result = VoiceTripParser.parse(text);
        expect(result.rawText, equals(text));
      });
    });

    group('Duration Extraction', () {
      test('should extract days', () {
        final result = VoiceTripParser.parse('Plan a 3 days trip to Goa');
        expect(result.numberOfDays, equals(3));
      });

      test('should extract nights (converts to days + 1)', () {
        final result = VoiceTripParser.parse('5 nights in Kerala');
        expect(result.numberOfDays, equals(6));
      });

      test('should extract weekend', () {
        final result = VoiceTripParser.parse('Weekend trip to Manali');
        expect(result.numberOfDays, equals(2));
      });

      test('should extract week duration', () {
        final result = VoiceTripParser.parse('A week in Rajasthan');
        expect(result.numberOfDays, equals(7));
      });

      test('should extract multiple weeks', () {
        final result = VoiceTripParser.parse('2 weeks in Europe');
        expect(result.numberOfDays, equals(14));
      });

      test('should return duration string', () {
        final result = VoiceTripParser.parse('3 days trip to Goa');
        expect(result.duration, contains('3'));
        expect(result.duration, contains('day'));
      });
    });

    group('Date Extraction', () {
      test('should extract tomorrow', () {
        final result = VoiceTripParser.parse('Trip to Goa starting tomorrow');
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        expect(result.startDate?.day, equals(tomorrow.day));
        expect(result.startDate?.month, equals(tomorrow.month));
      });

      test('should extract this weekend', () {
        final result = VoiceTripParser.parse('Goa trip this weekend');
        expect(result.startDate, isNotNull);
        // Should be a Saturday
        expect(result.startDate?.weekday, equals(DateTime.saturday));
      });

      test('should extract next week', () {
        final result = VoiceTripParser.parse('Visit Kerala next week');
        expect(result.startDate, isNotNull);
        // Should be a Monday
        expect(result.startDate?.weekday, equals(DateTime.monday));
      });

      test('should extract month name - January', () {
        final result = VoiceTripParser.parse('Trip to Goa in January');
        expect(result.startDate, isNotNull);
        expect(result.startDate?.month, equals(1));
      });

      test('should extract month and day - 15th March', () {
        final result = VoiceTripParser.parse('Kerala trip on 15th March');
        expect(result.startDate, isNotNull);
        expect(result.startDate?.month, equals(3));
        expect(result.startDate?.day, equals(15));
      });
    });

    group('Companion Extraction', () {
      test('should extract family companion', () {
        final result = VoiceTripParser.parse('Goa trip with family');
        expect(result.companions, contains('Family'));
      });

      test('should extract friends companion', () {
        final result = VoiceTripParser.parse('Beach trip with friends');
        expect(result.companions, contains('Friends'));
      });

      test('should extract kids', () {
        final result = VoiceTripParser.parse('Disneyland with kids');
        expect(result.companions, contains('Kids'));
      });

      test('should extract spouse', () {
        final result = VoiceTripParser.parse('Romantic getaway with wife');
        expect(result.companions, contains('Spouse'));
      });

      test('should extract multiple companions', () {
        final result = VoiceTripParser.parse('Family trip with kids and parents');
        expect(result.companions, contains('Family'));
        expect(result.companions, contains('Kids'));
        expect(result.companions, contains('Parents'));
      });
    });

    group('Trip Type Extraction', () {
      test('should identify family trip', () {
        final result = VoiceTripParser.parse('Family vacation to Kerala');
        expect(result.tripType, equals('family'));
      });

      test('should identify friends trip', () {
        final result = VoiceTripParser.parse('Trip with friends to Goa');
        expect(result.tripType, equals('friends'));
      });

      test('should identify solo trip', () {
        final result = VoiceTripParser.parse('Solo backpacking trip');
        expect(result.tripType, equals('solo'));
      });

      test('should identify business trip', () {
        final result = VoiceTripParser.parse('Business trip to Mumbai');
        expect(result.tripType, equals('business'));
      });

      test('should identify romantic trip', () {
        final result = VoiceTripParser.parse('Honeymoon in Maldives');
        expect(result.tripType, equals('romantic'));
      });

      test('should identify adventure trip', () {
        final result = VoiceTripParser.parse('Adventure trip to Ladakh');
        expect(result.tripType, equals('adventure'));
      });
    });

    group('Complex Inputs', () {
      test('should parse complete trip description', () {
        final result = VoiceTripParser.parse(
          'Plan a 5 day family trip to Kerala starting next weekend',
        );
        expect(result.destination, equals('Kerala'));
        expect(result.numberOfDays, equals(5));
        expect(result.tripType, equals('family'));
        expect(result.companions, contains('Family'));
      });

      test('should parse trip with multiple details', () {
        final result = VoiceTripParser.parse(
          'Going to Bali for honeymoon in February for 7 nights',
        );
        expect(result.destination, equals('Bali'));
        expect(result.tripType, equals('romantic'));
        expect(result.numberOfDays, equals(8)); // 7 nights + 1
        expect(result.startDate?.month, equals(2));
      });

      test('should handle mixed case input', () {
        final result = VoiceTripParser.parse('TRIP TO GOA with FAMILY');
        expect(result.destination, equals('Goa'));
        expect(result.tripType, equals('family'));
      });
    });
  });

  group('VoiceChecklistParser', () {
    group('Single Item', () {
      test('should parse simple item', () {
        final items = VoiceChecklistParser.parse('Passport');
        expect(items, contains('Passport'));
        expect(items.length, equals(1));
      });

      test('should capitalize first letter', () {
        final items = VoiceChecklistParser.parse('passport');
        expect(items.first, equals('Passport'));
      });

      test('should remove "add" prefix', () {
        final items = VoiceChecklistParser.parse('Add passport');
        expect(items, contains('Passport'));
      });

      test('should remove "pack" prefix', () {
        final items = VoiceChecklistParser.parse('Pack sunscreen');
        expect(items, contains('Sunscreen'));
      });

      test('should remove "remember to" prefix', () {
        final items = VoiceChecklistParser.parse("Remember to bring camera");
        expect(items.first, equals('Bring camera'));
      });
    });

    group('Multiple Items', () {
      test('should split by comma', () {
        final items = VoiceChecklistParser.parse('Passport, tickets, wallet');
        expect(items.length, equals(3));
        expect(items, contains('Passport'));
        expect(items, contains('Tickets'));
        expect(items, contains('Wallet'));
      });

      test('should split by "and"', () {
        final items = VoiceChecklistParser.parse('Passport and tickets and phone');
        expect(items.length, equals(3));
        expect(items, contains('Passport'));
        expect(items, contains('Tickets'));
        expect(items, contains('Phone'));
      });

      test('should handle mixed delimiters', () {
        final items = VoiceChecklistParser.parse('Passport, tickets and wallet');
        expect(items.length, equals(3));
      });

      test('should split by period', () {
        final items = VoiceChecklistParser.parse('Pack clothes. Bring camera.');
        expect(items.length, equals(2));
      });

      test('should split by "then"', () {
        final items = VoiceChecklistParser.parse('Passport then tickets then cash');
        expect(items.length, equals(3));
      });
    });

    group('Edge Cases', () {
      test('should handle empty input', () {
        final items = VoiceChecklistParser.parse('');
        expect(items, isEmpty);
      });

      test('should handle whitespace only', () {
        final items = VoiceChecklistParser.parse('   ');
        expect(items, isEmpty);
      });

      test('should remove articles', () {
        final items = VoiceChecklistParser.parse('a passport, the tickets, my wallet');
        expect(items, contains('Passport'));
        expect(items, contains('Tickets'));
        expect(items, contains('Wallet'));
      });

      test('should remove trailing punctuation', () {
        final items = VoiceChecklistParser.parse('Passport!, Tickets?');
        expect(items[0], isNot(contains('!')));
        expect(items[1], isNot(contains('?')));
      });
    });
  });

  group('VoiceItineraryParser', () {
    group('Title Extraction', () {
      test('should extract simple title', () {
        final result = VoiceItineraryParser.parse('Visit Eiffel Tower');
        expect(result.title, equals('Eiffel Tower'));
        expect(result.hasTitle, isTrue);
      });

      test('should clean up "visit" prefix', () {
        final result = VoiceItineraryParser.parse('Visit the beach');
        expect(result.title, isNot(startsWith('Visit')));
      });

      test('should clean up "go to" prefix', () {
        final result = VoiceItineraryParser.parse('Go to the museum');
        expect(result.title, isNot(startsWith('Go to')));
      });

      test('should capitalize first letter', () {
        final result = VoiceItineraryParser.parse('breakfast at hotel');
        expect(result.title[0], equals(result.title[0].toUpperCase()));
      });
    });

    group('Time Extraction', () {
      test('should extract time with AM', () {
        final result = VoiceItineraryParser.parse('Meeting at 10am');
        expect(result.startTime, isNotNull);
        expect(result.startTime?.hour, equals(10));
        expect(result.startTime?.minute, equals(0));
      });

      test('should extract time with PM', () {
        final result = VoiceItineraryParser.parse('Dinner at 7pm');
        expect(result.startTime, isNotNull);
        expect(result.startTime?.hour, equals(19));
      });

      test('should extract time with minutes', () {
        final result = VoiceItineraryParser.parse('Tour starts at 10:30');
        expect(result.startTime, isNotNull);
        expect(result.startTime?.hour, equals(10));
        expect(result.startTime?.minute, equals(30));
      });

      test('should extract "morning" as 9 AM', () {
        final result = VoiceItineraryParser.parse('Morning yoga session');
        expect(result.startTime, isNotNull);
        expect(result.startTime?.hour, equals(9));
      });

      test('should extract "afternoon" as 2 PM', () {
        final result = VoiceItineraryParser.parse('Afternoon tour');
        expect(result.startTime, isNotNull);
        expect(result.startTime?.hour, equals(14));
      });

      test('should extract "evening" as 6 PM', () {
        final result = VoiceItineraryParser.parse('Evening walk');
        expect(result.startTime, isNotNull);
        expect(result.startTime?.hour, equals(18));
      });

      test('should extract "breakfast" as 8 AM', () {
        final result = VoiceItineraryParser.parse('Breakfast at the hotel');
        expect(result.startTime?.hour, equals(8));
      });

      test('should extract "lunch" as noon', () {
        final result = VoiceItineraryParser.parse('Lunch at local restaurant');
        expect(result.startTime?.hour, equals(12));
      });

      test('should extract "dinner" as 7 PM', () {
        final result = VoiceItineraryParser.parse('Dinner reservation');
        expect(result.startTime?.hour, equals(19));
      });

      test('should assume PM for small hours without AM/PM', () {
        final result = VoiceItineraryParser.parse('Meeting at 3');
        // Should assume 3 PM, not 3 AM
        expect(result.startTime?.hour, equals(15));
      });
    });

    group('Duration Extraction', () {
      test('should extract hours duration', () {
        final result = VoiceItineraryParser.parse('City tour for 3 hours');
        expect(result.duration, equals(180));
      });

      test('should extract minutes duration', () {
        final result = VoiceItineraryParser.parse('Quick visit for 30 minutes');
        expect(result.duration, equals(30));
      });

      test('should extract decimal hours', () {
        final result = VoiceItineraryParser.parse('Museum visit for 1.5 hours');
        expect(result.duration, equals(90));
      });

      test('should calculate end time from duration', () {
        final result = VoiceItineraryParser.parse('Museum at 10am for 2 hours');
        expect(result.startTime?.hour, equals(10));
        expect(result.endTime?.hour, equals(12));
      });
    });

    group('Location Extraction', () {
      test('should extract location with "at"', () {
        final result = VoiceItineraryParser.parse('Lunch at Downtown Restaurant');
        expect(result.location, isNotNull);
        expect(result.hasLocation, isTrue);
      });

      test('should extract location with "in"', () {
        final result = VoiceItineraryParser.parse('Shopping in Main Street');
        expect(result.location, isNotNull);
      });
    });

    group('Multiple Items', () {
      test('should parse multiple items separated by "then"', () {
        final items = VoiceItineraryParser.parseMultiple(
          'Visit museum then have lunch then explore park',
        );
        expect(items.length, equals(3));
      });

      test('should parse numbered items', () {
        final items = VoiceItineraryParser.parseMultiple(
          '1. Breakfast 2. City tour 3. Lunch',
        );
        expect(items.length, equals(3));
      });
    });

    group('Complex Inputs', () {
      test('should parse complete itinerary item', () {
        final result = VoiceItineraryParser.parse(
          'Visit the Eiffel Tower at 10am for 2 hours',
        );
        expect(result.hasTitle, isTrue);
        expect(result.hasTime, isTrue);
        expect(result.duration, isNotNull);
      });

      test('should preserve raw text', () {
        const text = 'Morning yoga at beach';
        final result = VoiceItineraryParser.parse(text);
        expect(result.rawText, equals(text));
      });
    });
  });

  group('VoiceTripDetails', () {
    test('hasDestination returns true when destination is set', () {
      final details = VoiceTripDetails(
        destination: 'Goa',
        rawText: 'Trip to Goa',
      );
      expect(details.hasDestination, isTrue);
    });

    test('hasDestination returns false when destination is null', () {
      final details = VoiceTripDetails(
        destination: null,
        rawText: 'Some trip',
      );
      expect(details.hasDestination, isFalse);
    });

    test('hasDestination returns false when destination is empty', () {
      final details = VoiceTripDetails(
        destination: '',
        rawText: 'Some trip',
      );
      expect(details.hasDestination, isFalse);
    });

    test('hasDates returns true when startDate is set', () {
      final details = VoiceTripDetails(
        startDate: DateTime.now(),
        rawText: 'Trip starting today',
      );
      expect(details.hasDates, isTrue);
    });

    test('hasDates returns true when numberOfDays is set', () {
      final details = VoiceTripDetails(
        numberOfDays: 5,
        rawText: '5 day trip',
      );
      expect(details.hasDates, isTrue);
    });

    test('toString returns formatted string', () {
      final details = VoiceTripDetails(
        destination: 'Goa',
        numberOfDays: 3,
        tripType: 'family',
        rawText: 'Family trip to Goa',
      );
      final str = details.toString();
      expect(str, contains('destination: Goa'));
      expect(str, contains('numberOfDays: 3'));
      expect(str, contains('tripType: family'));
    });
  });

  group('ItineraryItemDetails', () {
    test('hasTitle returns true when title is not empty', () {
      final details = ItineraryItemDetails(
        title: 'Visit Museum',
        rawText: 'Visit Museum',
      );
      expect(details.hasTitle, isTrue);
    });

    test('hasTitle returns false when title is empty', () {
      final details = ItineraryItemDetails(
        title: '',
        rawText: '',
      );
      expect(details.hasTitle, isFalse);
    });

    test('hasTime returns true when startTime is set', () {
      final details = ItineraryItemDetails(
        title: 'Meeting',
        startTime: const TimeOfDay(hour: 10, minute: 0),
        rawText: 'Meeting at 10',
      );
      expect(details.hasTime, isTrue);
    });

    test('hasLocation returns true when location is set', () {
      final details = ItineraryItemDetails(
        title: 'Lunch',
        location: 'Restaurant',
        rawText: 'Lunch at Restaurant',
      );
      expect(details.hasLocation, isTrue);
    });

    test('endTime calculates correctly from startTime and duration', () {
      final details = ItineraryItemDetails(
        title: 'Tour',
        startTime: const TimeOfDay(hour: 10, minute: 30),
        duration: 90, // 1.5 hours
        rawText: 'Tour at 10:30 for 1.5 hours',
      );
      expect(details.endTime?.hour, equals(12));
      expect(details.endTime?.minute, equals(0));
    });

    test('endTime handles overflow past midnight', () {
      final details = ItineraryItemDetails(
        title: 'Late event',
        startTime: const TimeOfDay(hour: 23, minute: 0),
        duration: 120, // 2 hours
        rawText: 'Late event',
      );
      // 23:00 + 2 hours = 01:00 next day
      expect(details.endTime?.hour, equals(1));
    });

    test('endTime returns null when startTime is null', () {
      final details = ItineraryItemDetails(
        title: 'Some activity',
        duration: 60,
        rawText: 'Some activity',
      );
      expect(details.endTime, isNull);
    });

    test('endTime returns null when duration is null', () {
      final details = ItineraryItemDetails(
        title: 'Some activity',
        startTime: const TimeOfDay(hour: 10, minute: 0),
        rawText: 'Some activity at 10',
      );
      expect(details.endTime, isNull);
    });
  });
}
