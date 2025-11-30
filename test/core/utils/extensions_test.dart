import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/utils/extensions.dart';

void main() {
  group('StringExtensions', () {
    group('capitalize', () {
      test('should capitalize first letter of string', () {
        expect('hello'.capitalize(), 'Hello');
      });

      test('should return empty string for empty input', () {
        expect(''.capitalize(), '');
      });

      test('should handle already capitalized string', () {
        expect('Hello'.capitalize(), 'Hello');
      });

      test('should capitalize single character', () {
        expect('a'.capitalize(), 'A');
      });

      test('should handle string starting with number', () {
        expect('123abc'.capitalize(), '123abc');
      });

      test('should handle string with special characters', () {
        expect('@hello'.capitalize(), '@hello');
      });
    });

    group('toTitleCase', () {
      test('should convert to title case', () {
        expect('hello world'.toTitleCase(), 'Hello World');
      });

      test('should handle single word', () {
        expect('hello'.toTitleCase(), 'Hello');
      });

      test('should handle empty string', () {
        expect(''.toTitleCase(), '');
      });

      test('should handle multiple spaces', () {
        expect('hello  world'.toTitleCase(), 'Hello  World');
      });

      test('should handle already title case', () {
        expect('Hello World'.toTitleCase(), 'Hello World');
      });

      test('should handle all uppercase', () {
        expect('HELLO WORLD'.toTitleCase(), 'HELLO WORLD');
      });
    });

    group('isValidEmail', () {
      test('should return true for valid email', () {
        expect('test@example.com'.isValidEmail, true);
      });

      test('should return true for email with subdomain', () {
        expect('test@mail.example.com'.isValidEmail, true);
      });

      test('should return true for email with dots in local part', () {
        expect('test.user@example.com'.isValidEmail, true);
      });

      test('should return true for email with numbers', () {
        expect('test123@example.com'.isValidEmail, true);
      });

      test('should return true for email with hyphen', () {
        expect('test-user@example.com'.isValidEmail, true);
      });

      test('should return false for email without @', () {
        expect('testexample.com'.isValidEmail, false);
      });

      test('should return false for email without domain', () {
        expect('test@'.isValidEmail, false);
      });

      test('should return false for email without local part', () {
        expect('@example.com'.isValidEmail, false);
      });

      test('should return false for email with spaces', () {
        expect('test @example.com'.isValidEmail, false);
      });

      test('should return false for empty string', () {
        expect(''.isValidEmail, false);
      });

      test('should return false for email with short TLD', () {
        expect('test@example.c'.isValidEmail, false);
      });
    });

    group('truncate', () {
      test('should truncate string with ellipsis', () {
        expect('Hello World'.truncate(5), 'Hello...');
      });

      test('should not truncate short string', () {
        expect('Hi'.truncate(5), 'Hi');
      });

      test('should return exact length string without ellipsis', () {
        expect('Hello'.truncate(5), 'Hello');
      });

      test('should use custom ellipsis', () {
        expect('Hello World'.truncate(5, ellipsis: '…'), 'Hello…');
      });

      test('should handle empty ellipsis', () {
        expect('Hello World'.truncate(5, ellipsis: ''), 'Hello');
      });

      test('should handle empty string', () {
        expect(''.truncate(5), '');
      });

      test('should handle maxLength of 0', () {
        expect('Hello'.truncate(0), '...');
      });
    });
  });

  group('DateTimeExtensions', () {
    group('toFormattedDate', () {
      test('should format date correctly', () {
        final date = DateTime(2024, 1, 15);
        expect(date.toFormattedDate(), 'Jan 15, 2024');
      });

      test('should format date with single digit day', () {
        final date = DateTime(2024, 1, 5);
        expect(date.toFormattedDate(), 'Jan 05, 2024');
      });
    });

    group('toShortDate', () {
      test('should format short date correctly', () {
        final date = DateTime(2024, 1, 15);
        expect(date.toShortDate(), '15 Jan');
      });

      test('should format short date with single digit day', () {
        final date = DateTime(2024, 1, 5);
        expect(date.toShortDate(), '05 Jan');
      });
    });

    group('toFormattedTime', () {
      test('should format morning time correctly', () {
        final date = DateTime(2024, 1, 15, 9, 30);
        expect(date.toFormattedTime(), '9:30 AM');
      });

      test('should format afternoon time correctly', () {
        final date = DateTime(2024, 1, 15, 14, 30);
        expect(date.toFormattedTime(), '2:30 PM');
      });

      test('should format midnight correctly', () {
        final date = DateTime(2024, 1, 15, 0, 0);
        expect(date.toFormattedTime(), '12:00 AM');
      });

      test('should format noon correctly', () {
        final date = DateTime(2024, 1, 15, 12, 0);
        expect(date.toFormattedTime(), '12:00 PM');
      });
    });

    group('toFormattedDateTime', () {
      test('should format date and time correctly', () {
        final date = DateTime(2024, 1, 15, 14, 30);
        expect(date.toFormattedDateTime(), 'Jan 15, 2024 at 2:30 PM');
      });
    });

    group('toRelativeTime', () {
      test('should return "just now" for recent past', () {
        final now = DateTime.now();
        final recent = now.subtract(const Duration(seconds: 30));
        expect(recent.toRelativeTime(), 'just now');
      });

      test('should return minutes ago', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(minutes: 5));
        expect(past.toRelativeTime(), '5 minutes ago');
      });

      test('should return "1 minute ago" for single minute', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(minutes: 1));
        expect(past.toRelativeTime(), '1 minute ago');
      });

      test('should return hours ago', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(hours: 3));
        expect(past.toRelativeTime(), '3 hours ago');
      });

      test('should return "1 hour ago" for single hour', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(hours: 1));
        expect(past.toRelativeTime(), '1 hour ago');
      });

      test('should return days ago', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 5));
        expect(past.toRelativeTime(), '5 days ago');
      });

      test('should return "1 day ago" for single day', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 1));
        expect(past.toRelativeTime(), '1 day ago');
      });

      test('should return months ago', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 60));
        expect(past.toRelativeTime(), '2 months ago');
      });

      test('should return "1 month ago" for single month', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 35));
        expect(past.toRelativeTime(), '1 month ago');
      });

      test('should return years ago', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 800));
        expect(past.toRelativeTime(), '2 years ago');
      });

      test('should return "1 year ago" for single year', () {
        final now = DateTime.now();
        final past = now.subtract(const Duration(days: 400));
        expect(past.toRelativeTime(), '1 year ago');
      });

      test('should return "in a few seconds" for near future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(seconds: 30));
        expect(future.toRelativeTime(), 'in a few seconds');
      });

      test('should return "in X minutes" for future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(minutes: 5, seconds: 30));
        expect(future.toRelativeTime(), 'in 5 minutes');
      });

      test('should return "in 1 minute" for single minute future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(minutes: 1, seconds: 30));
        expect(future.toRelativeTime(), 'in 1 minute');
      });

      test('should return "in X hours" for future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 3, minutes: 30));
        expect(future.toRelativeTime(), 'in 3 hours');
      });

      test('should return "in 1 hour" for single hour future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 1, minutes: 30));
        expect(future.toRelativeTime(), 'in 1 hour');
      });

      test('should return "in X days" for future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(days: 5, hours: 12));
        expect(future.toRelativeTime(), 'in 5 days');
      });

      test('should return "in 1 day" for single day future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(days: 1, hours: 12));
        expect(future.toRelativeTime(), 'in 1 day');
      });

      test('should return "in X months" for future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(days: 75));
        expect(future.toRelativeTime(), 'in 2 months');
      });

      test('should return "in 1 month" for single month future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(days: 35));
        expect(future.toRelativeTime(), 'in 1 month');
      });

      test('should return "in X years" for future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(days: 800));
        expect(future.toRelativeTime(), 'in 2 years');
      });

      test('should return "in 1 year" for single year future', () {
        final now = DateTime.now();
        final future = now.add(const Duration(days: 400));
        expect(future.toRelativeTime(), 'in 1 year');
      });
    });

    group('isToday', () {
      test('should return true for today', () {
        final today = DateTime.now();
        expect(today.isToday, true);
      });

      test('should return false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isToday, false);
      });

      test('should return false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isToday, false);
      });

      test('should return true for different time today', () {
        final now = DateTime.now();
        final earlierToday = DateTime(now.year, now.month, now.day, 1, 0, 0);
        expect(earlierToday.isToday, true);
      });
    });

    group('isTomorrow', () {
      test('should return true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowMidnight = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
        expect(tomorrowMidnight.isTomorrow, true);
      });

      test('should return false for today', () {
        final today = DateTime.now();
        expect(today.isTomorrow, false);
      });

      test('should return false for day after tomorrow', () {
        final dayAfter = DateTime.now().add(const Duration(days: 2));
        expect(dayAfter.isTomorrow, false);
      });
    });

    group('isPast', () {
      test('should return true for past date', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        expect(past.isPast, true);
      });

      test('should return false for future date', () {
        final future = DateTime.now().add(const Duration(days: 1));
        expect(future.isPast, false);
      });
    });

    group('isFuture', () {
      test('should return true for future date', () {
        final future = DateTime.now().add(const Duration(days: 1));
        expect(future.isFuture, true);
      });

      test('should return false for past date', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        expect(past.isFuture, false);
      });
    });
  });

  group('DoubleExtensions', () {
    group('toINR', () {
      test('should format positive amount with INR symbol', () {
        expect(1500.0.toINR(), contains('₹'));
        expect(1500.0.toINR(), contains('1,500'));
      });

      test('should format zero amount', () {
        expect(0.0.toINR(), contains('₹'));
        expect(0.0.toINR(), contains('0.00'));
      });

      test('should format large amount with proper formatting', () {
        final result = 1000000.0.toINR();
        expect(result, contains('₹'));
        expect(result, contains('10,00,000'));
      });

      test('should include decimal places', () {
        expect(1500.50.toINR(), contains('.50'));
      });
    });

    group('toFormattedAmount', () {
      test('should format amount without symbol', () {
        final result = 1500.0.toFormattedAmount();
        expect(result, isNot(contains('₹')));
        expect(result, contains('1,500'));
      });

      test('should format zero amount', () {
        final result = 0.0.toFormattedAmount();
        expect(result, contains('0.00'));
      });

      test('should format large amount with proper formatting', () {
        final result = 1000000.0.toFormattedAmount();
        expect(result, contains('10,00,000'));
      });
    });
  });

  group('ListExtensions', () {
    group('firstOrNull', () {
      test('should return first element for non-empty list', () {
        expect([1, 2, 3].firstOrNull, 1);
      });

      test('should return null for empty list', () {
        expect(<int>[].firstOrNull, isNull);
      });

      test('should work with different types', () {
        expect(['a', 'b', 'c'].firstOrNull, 'a');
      });
    });

    group('lastOrNull', () {
      test('should return last element for non-empty list', () {
        expect([1, 2, 3].lastOrNull, 3);
      });

      test('should return null for empty list', () {
        expect(<int>[].lastOrNull, isNull);
      });

      test('should work with different types', () {
        expect(['a', 'b', 'c'].lastOrNull, 'c');
      });
    });

    group('chunk', () {
      test('should split list into chunks of specified size', () {
        final result = [1, 2, 3, 4, 5, 6].chunk(2);
        expect(result, [
          [1, 2],
          [3, 4],
          [5, 6]
        ]);
      });

      test('should handle list not evenly divisible', () {
        final result = [1, 2, 3, 4, 5].chunk(2);
        expect(result, [
          [1, 2],
          [3, 4],
          [5]
        ]);
      });

      test('should handle chunk size larger than list', () {
        final result = [1, 2, 3].chunk(5);
        expect(result, [
          [1, 2, 3]
        ]);
      });

      test('should handle chunk size of 1', () {
        final result = [1, 2, 3].chunk(1);
        expect(result, [
          [1],
          [2],
          [3]
        ]);
      });

      test('should handle empty list', () {
        final result = <int>[].chunk(2);
        expect(result, isEmpty);
      });

      test('should work with different types', () {
        final result = ['a', 'b', 'c', 'd'].chunk(2);
        expect(result, [
          ['a', 'b'],
          ['c', 'd']
        ]);
      });
    });
  });
}
