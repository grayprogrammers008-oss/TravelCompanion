import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidEmail', () {
      test('should return true for valid email addresses', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('user.name@example.co.uk'), true);
        expect(Validators.isValidEmail('user+tag@example.com'), true);
        expect(Validators.isValidEmail('user_name@example.org'), true);
      });

      test('should return false for invalid email addresses', () {
        expect(Validators.isValidEmail(''), false);
        expect(Validators.isValidEmail('invalid'), false);
        expect(Validators.isValidEmail('invalid@'), false);
        expect(Validators.isValidEmail('@example.com'), false);
        expect(Validators.isValidEmail('user@'), false);
        expect(Validators.isValidEmail('user@.com'), false);
      });
    });

    group('email', () {
      test('should return null for valid email addresses', () {
        expect(Validators.email('test@example.com'), null);
        expect(Validators.email('user.name@example.co.uk'), null);
      });

      test('should return error message for invalid email addresses', () {
        expect(Validators.email(''), 'Email is required');
        expect(Validators.email(null), 'Email is required');
        expect(Validators.email('invalid'), 'Please enter a valid email');
        expect(Validators.email('invalid@'), 'Please enter a valid email');
      });
    });

    group('required', () {
      test('should return null for non-empty values', () {
        expect(Validators.required('test'), null);
        expect(Validators.required('   test   '), null);
      });

      test('should return error message for empty values', () {
        expect(Validators.required(''), 'This field is required');
        expect(Validators.required(null), 'This field is required');
        expect(Validators.required('', fieldName: 'Email'), 'Email is required');
      });
    });

    group('minLength', () {
      test('should return null for values meeting minimum length', () {
        expect(Validators.minLength('12345', 5), null);
        expect(Validators.minLength('123456', 5), null);
      });

      test('should return error message for values below minimum length', () {
        expect(Validators.minLength('1234', 5), contains('must be at least 5 characters'));
        expect(Validators.minLength('', 5), contains('is required'));
        expect(Validators.minLength(null, 5), contains('is required'));
      });
    });

    group('positiveNumber', () {
      test('should return null for positive numbers', () {
        expect(Validators.positiveNumber('1'), null);
        expect(Validators.positiveNumber('0.01'), null);
        expect(Validators.positiveNumber('999.99'), null);
      });

      test('should return error message for non-positive numbers', () {
        expect(Validators.positiveNumber('0'), contains('must be greater than 0'));
        expect(Validators.positiveNumber('-1'), contains('must be greater than 0'));
        expect(Validators.positiveNumber(''), contains('is required'));
        expect(Validators.positiveNumber('abc'), contains('valid number'));
      });
    });
  });
}
