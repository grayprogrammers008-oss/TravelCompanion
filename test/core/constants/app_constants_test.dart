import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('app info constants are non-empty', () {
      expect(AppConstants.appName, isNotEmpty);
      expect(AppConstants.appVersion, isNotEmpty);
      expect(AppConstants.appTagline, isNotEmpty);
    });

    test('numeric constants have sensible values', () {
      expect(AppConstants.apiTimeout, greaterThan(0));
      expect(AppConstants.realtimeTimeout, greaterThan(0));
      expect(AppConstants.defaultPageSize, greaterThan(0));
      expect(AppConstants.maxPageSize, greaterThanOrEqualTo(AppConstants.defaultPageSize));
      expect(AppConstants.maxFileSize, greaterThan(0));
    });

    test('trip name lengths are sensible', () {
      expect(AppConstants.minTripNameLength, greaterThan(0));
      expect(AppConstants.maxTripNameLength, greaterThan(AppConstants.minTripNameLength));
      expect(AppConstants.maxTripDescriptionLength, greaterThan(0));
    });

    test('image formats list is non-empty and contains common types', () {
      expect(AppConstants.allowedImageFormats, contains('jpg'));
      expect(AppConstants.allowedImageFormats, contains('png'));
      expect(AppConstants.allowedImageFormats, isNotEmpty);
    });

    test('document formats list is non-empty', () {
      expect(AppConstants.allowedDocumentFormats, isNotEmpty);
      expect(AppConstants.allowedDocumentFormats, contains('pdf'));
    });

    test('supported currencies includes default', () {
      expect(AppConstants.supportedCurrencies, contains(AppConstants.defaultCurrency));
      expect(AppConstants.currencySymbol, isNotEmpty);
    });

    test('payment methods list is non-empty and unique', () {
      expect(AppConstants.paymentMethods, isNotEmpty);
      expect(
        AppConstants.paymentMethods.toSet().length,
        AppConstants.paymentMethods.length,
        reason: 'Payment methods should be unique',
      );
    });

    test('storage bucket names are non-empty and unique', () {
      final buckets = [
        AppConstants.profileAvatarsBucket,
        AppConstants.tripCoversBucket,
        AppConstants.expenseReceiptsBucket,
        AppConstants.settlementProofsBucket,
      ];
      for (final b in buckets) {
        expect(b, isNotEmpty);
      }
      expect(buckets.toSet().length, buckets.length);
    });
  });

  group('ExpenseCategory', () {
    test('all is non-empty and contains all individual categories', () {
      expect(ExpenseCategory.all, isNotEmpty);
      expect(ExpenseCategory.all, contains(ExpenseCategory.food));
      expect(ExpenseCategory.all, contains(ExpenseCategory.accommodation));
      expect(ExpenseCategory.all, contains(ExpenseCategory.transportation));
      expect(ExpenseCategory.all, contains(ExpenseCategory.activities));
      expect(ExpenseCategory.all, contains(ExpenseCategory.shopping));
      expect(ExpenseCategory.all, contains(ExpenseCategory.other));
    });

    test('categories are unique', () {
      expect(ExpenseCategory.all.toSet().length, ExpenseCategory.all.length);
    });
  });

  group('TripRole enum', () {
    test('display names are non-empty for all values', () {
      for (final r in TripRole.values) {
        expect(r.displayName, isNotEmpty);
      }
    });

    test('admin and member have distinct display names', () {
      expect(TripRole.admin.displayName, isNot(TripRole.member.displayName));
    });
  });

  group('InviteStatus enum', () {
    test('display names are non-empty and unique', () {
      final names = InviteStatus.values.map((e) => e.displayName).toList();
      expect(names.every((n) => n.isNotEmpty), true);
      expect(names.toSet().length, names.length);
    });
  });

  group('SettlementStatus enum', () {
    test('display names are non-empty and unique', () {
      final names = SettlementStatus.values.map((e) => e.displayName).toList();
      expect(names.every((n) => n.isNotEmpty), true);
      expect(names.toSet().length, names.length);
    });
  });

  group('SplitType enum', () {
    test('display names are non-empty', () {
      for (final t in SplitType.values) {
        expect(t.displayName, isNotEmpty);
      }
    });
  });

  group('NotificationType enum', () {
    test('all values have non-empty unique display names', () {
      final names = NotificationType.values.map((e) => e.displayName).toList();
      expect(names.every((n) => n.isNotEmpty), true);
      expect(names.toSet().length, names.length);
    });
  });

  group('AutopilotSuggestionType enum', () {
    test('all values have non-empty display names and icons', () {
      for (final t in AutopilotSuggestionType.values) {
        expect(t.displayName, isNotEmpty);
        expect(t.icon, isNotEmpty);
      }
    });

    test('display names are unique', () {
      final names =
          AutopilotSuggestionType.values.map((e) => e.displayName).toList();
      expect(names.toSet().length, names.length);
    });
  });
}
