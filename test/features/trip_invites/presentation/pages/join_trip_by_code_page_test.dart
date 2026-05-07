import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trip_invites/presentation/pages/join_trip_by_code_page.dart';

void main() {
  group('UpperCaseTextFormatter', () {
    final formatter = UpperCaseTextFormatter();

    test('uppercases ASCII text input', () {
      const oldVal = TextEditingValue.empty;
      const newVal = TextEditingValue(
        text: 'abc123',
        selection: TextSelection.collapsed(offset: 6),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);

      expect(result.text, 'ABC123');
      // Selection is preserved.
      expect(result.selection.baseOffset, 6);
    });

    test('passes through already-uppercase text unchanged', () {
      const oldVal = TextEditingValue.empty;
      const newVal = TextEditingValue(
        text: 'ALREADY',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);

      expect(result.text, 'ALREADY');
    });

    test('handles empty text', () {
      const oldVal = TextEditingValue(
        text: 'X',
        selection: TextSelection.collapsed(offset: 1),
      );
      const newVal = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);

      expect(result.text, '');
    });

    test('uppercases mixed-case input', () {
      const oldVal = TextEditingValue.empty;
      const newVal = TextEditingValue(
        text: 'aBc123Xy',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);

      expect(result.text, 'ABC123XY');
    });

    test('preserves digits and other non-letter characters', () {
      const oldVal = TextEditingValue.empty;
      const newVal = TextEditingValue(
        text: '12345-az',
        selection: TextSelection.collapsed(offset: 8),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);

      expect(result.text, '12345-AZ');
    });
  });
}
