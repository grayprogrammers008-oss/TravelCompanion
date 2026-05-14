// Tests for `quick_expense_sheet.dart`.
//
// SCOPE: `QuickExpenseSheet` is a stateful widget that reads
// `SupabaseClientWrapper.currentUserId` in `initState`, which throws
// "Supabase not initialized" in widget tests. We therefore can NOT render
// the widget itself. The image-attach feature additionally uses the
// `file_picker` plugin (also documented as out-of-scope).
//
// What we CAN test directly: the public `expenseCategories` list (a
// const collection used by callers) and the `ExpenseCategory` data
// class shape.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/expenses/presentation/widgets/quick_expense_sheet.dart';

void main() {
  group('expenseCategories — public constants', () {
    test('exposes 6 categories', () {
      expect(expenseCategories.length, 6);
    });

    test('includes Food category with restaurant icon', () {
      final food = expenseCategories.firstWhere((c) => c.name == 'Food');
      expect(food.icon, Icons.restaurant);
      expect(food.color.value, const Color(0xFFFF9800).value);
    });

    test('includes Transport category with directions_car icon', () {
      final t = expenseCategories.firstWhere((c) => c.name == 'Transport');
      expect(t.icon, Icons.directions_car);
      expect(t.color.value, const Color(0xFF2196F3).value);
    });

    test('includes Accommodation category with hotel icon', () {
      final c = expenseCategories.firstWhere((c) => c.name == 'Accommodation');
      expect(c.icon, Icons.hotel);
    });

    test('includes Activities category', () {
      final c = expenseCategories.firstWhere((c) => c.name == 'Activities');
      expect(c.icon, Icons.confirmation_number);
    });

    test('includes Shopping category with shopping_bag icon', () {
      final c = expenseCategories.firstWhere((c) => c.name == 'Shopping');
      expect(c.icon, Icons.shopping_bag);
    });

    test('includes Other category as fallback', () {
      final c = expenseCategories.firstWhere((c) => c.name == 'Other');
      expect(c.icon, Icons.more_horiz);
    });

    test('all categories have unique names', () {
      final names = expenseCategories.map((c) => c.name).toSet();
      expect(names.length, expenseCategories.length);
    });

    test('all categories have non-null icon and color', () {
      for (final c in expenseCategories) {
        expect(c.icon, isNotNull);
        expect(c.color, isNotNull);
        expect(c.name, isNotEmpty);
      }
    });
  });

  group('ExpenseCategory — data class', () {
    test('constructor stores all fields', () {
      const c = ExpenseCategory(
        name: 'Test',
        icon: Icons.star,
        color: Colors.red,
      );
      expect(c.name, 'Test');
      expect(c.icon, Icons.star);
      expect(c.color, Colors.red);
    });
  });

  // SKIPPED: QuickExpenseSheet widget render and submit-flow tests.
  // The widget reads `SupabaseClientWrapper.currentUserId` in
  // `initState()`, which throws when Supabase isn't bootstrapped. The
  // image-attach feature uses `file_picker` which requires platform
  // channels. Both are out of widget-test scope.
}
