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

      test('should use custom field name', () {
        expect(
          Validators.positiveNumber('-1', fieldName: 'Budget'),
          contains('Budget must be greater than 0'),
        );
      });
    });

    group('password', () {
      test('should return null for valid passwords', () {
        expect(Validators.password('12345678'), null);
        expect(Validators.password('password123'), null);
        expect(Validators.password('MySecureP@ss'), null);
      });

      test('should return error for empty password', () {
        expect(Validators.password(''), 'Password is required');
        expect(Validators.password(null), 'Password is required');
      });

      test('should return error for short password', () {
        expect(Validators.password('1234567'), 'Password must be at least 8 characters');
        expect(Validators.password('abc'), 'Password must be at least 8 characters');
      });
    });

    group('confirmPassword', () {
      test('should return null when passwords match', () {
        expect(Validators.confirmPassword('password123', 'password123'), null);
      });

      test('should return error when password is empty', () {
        expect(Validators.confirmPassword('', 'password123'), 'Please confirm your password');
        expect(Validators.confirmPassword(null, 'password123'), 'Please confirm your password');
      });

      test('should return error when passwords do not match', () {
        expect(Validators.confirmPassword('password1', 'password2'), 'Passwords do not match');
      });
    });

    group('name', () {
      test('should return null for valid names', () {
        expect(Validators.name('John'), null);
        expect(Validators.name('John Doe'), null);
        expect(Validators.name('JD'), null);
      });

      test('should return error for empty name', () {
        expect(Validators.name(''), 'Name is required');
        expect(Validators.name(null), 'Name is required');
      });

      test('should return error for short name', () {
        expect(Validators.name('J'), 'Name must be at least 2 characters');
      });
    });

    group('phoneNumber', () {
      test('should return null for valid Indian phone numbers', () {
        expect(Validators.phoneNumber('9876543210'), null);
        expect(Validators.phoneNumber('6123456789'), null);
        expect(Validators.phoneNumber('7999999999'), null);
        expect(Validators.phoneNumber('8888888888'), null);
      });

      test('should return null for empty (optional field)', () {
        expect(Validators.phoneNumber(''), null);
        expect(Validators.phoneNumber(null), null);
      });

      test('should return error for invalid phone numbers', () {
        expect(Validators.phoneNumber('1234567890'), contains('valid 10-digit'));
        expect(Validators.phoneNumber('5123456789'), contains('valid 10-digit'));
        expect(Validators.phoneNumber('98765'), contains('valid 10-digit'));
        expect(Validators.phoneNumber('98765432101'), contains('valid 10-digit'));
        expect(Validators.phoneNumber('abcdefghij'), contains('valid 10-digit'));
      });
    });

    group('maxLength', () {
      test('should return null for values within max length', () {
        expect(Validators.maxLength('12345', 10), null);
        expect(Validators.maxLength('12345', 5), null);
        expect(Validators.maxLength(null, 5), null);
        expect(Validators.maxLength('', 5), null);
      });

      test('should return error for values exceeding max length', () {
        expect(Validators.maxLength('123456', 5), contains('cannot exceed 5 characters'));
      });

      test('should use custom field name', () {
        expect(
          Validators.maxLength('123456', 5, fieldName: 'Title'),
          contains('Title cannot exceed 5 characters'),
        );
      });
    });

    group('number', () {
      test('should return null for valid numbers', () {
        expect(Validators.number('123'), null);
        expect(Validators.number('123.45'), null);
        expect(Validators.number('-123'), null);
        expect(Validators.number('0'), null);
      });

      test('should return error for empty value', () {
        expect(Validators.number(''), contains('is required'));
        expect(Validators.number(null), contains('is required'));
      });

      test('should return error for non-numeric value', () {
        expect(Validators.number('abc'), 'Please enter a valid number');
        expect(Validators.number('12.34.56'), 'Please enter a valid number');
      });

      test('should use custom field name', () {
        expect(
          Validators.number('', fieldName: 'Quantity'),
          contains('Quantity is required'),
        );
      });
    });

    group('amount', () {
      test('should return null for valid amounts', () {
        expect(Validators.amount('100'), null);
        expect(Validators.amount('0.01'), null);
        expect(Validators.amount('99999.99'), null);
      });

      test('should return error for invalid amounts', () {
        expect(Validators.amount(''), contains('Amount is required'));
        expect(Validators.amount('0'), contains('Amount must be greater than 0'));
        expect(Validators.amount('-100'), contains('Amount must be greater than 0'));
        expect(Validators.amount('abc'), contains('valid number'));
      });
    });

    group('upiId', () {
      test('should return null for valid UPI IDs', () {
        expect(Validators.upiId('user@upi'), null);
        expect(Validators.upiId('username@paytm'), null);
        expect(Validators.upiId('john.doe@oksbi'), null);
        expect(Validators.upiId('user_name@ybl'), null);
        expect(Validators.upiId('user-name@axis'), null);
      });

      test('should return null for empty (optional field)', () {
        expect(Validators.upiId(''), null);
        expect(Validators.upiId(null), null);
      });

      test('should return error for invalid UPI IDs', () {
        expect(Validators.upiId('user'), contains('valid UPI ID'));
        expect(Validators.upiId('user@'), contains('valid UPI ID'));
        expect(Validators.upiId('@upi'), contains('valid UPI ID'));
        expect(Validators.upiId('ab@up'), contains('valid UPI ID'));
      });
    });
  });
}
