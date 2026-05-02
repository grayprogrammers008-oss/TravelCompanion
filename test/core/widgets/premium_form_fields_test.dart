import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/premium_form_fields.dart';

import 'test_helpers.dart';

void main() {
  group('PremiumTextField', () {
    testWidgets('renders label / hint / prefix icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumTextField(
          labelText: 'Trip name',
          hintText: 'My epic adventure',
          prefixIcon: Icons.edit,
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('Trip name'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('invokes onChanged with typed text', (tester) async {
      final controller = TextEditingController();
      String? received;
      await tester.pumpWidget(wrapWithTheme(
        PremiumTextField(
          controller: controller,
          onChanged: (s) => received = s,
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'hello');
      expect(received, 'hello');
      expect(controller.text, 'hello');
      controller.dispose();
    });

    testWidgets('supports obscureText for passwords', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumTextField(obscureText: true),
        size: const Size(400, 200),
      ));
      await tester.pump();

      // The internal EditableText carries the obscureText flag.
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
    });
  });

  group('PremiumDropdown', () {
    testWidgets('renders the selected value label', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        PremiumDropdown<String>(
          value: 'one',
          labelText: 'Pick one',
          items: const [
            DropdownMenuItem(value: 'one', child: Text('One')),
            DropdownMenuItem(value: 'two', child: Text('Two')),
          ],
          onChanged: (_) {},
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('One'), findsWidgets);
    });
  });

  group('PremiumDateTimePicker', () {
    testWidgets('renders label when no date / time selected', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PremiumDateTimePicker(labelText: 'Start date'),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('Start date'), findsWidgets);
    });

    testWidgets('renders the formatted date when one is selected',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        PremiumDateTimePicker(
          labelText: 'Start',
          selectedDate: DateTime(2026, 1, 15),
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('15/1/2026'), findsOneWidget);
    });
  });

  group('PremiumCheckbox', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        PremiumCheckbox(
          value: true,
          label: 'I agree',
          onChanged: (_) {},
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();
      expect(find.text('I agree'), findsOneWidget);
      final cb = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cb.value, isTrue);
    });

    testWidgets('invokes onChanged when tapped', (tester) async {
      bool? newValue;
      await tester.pumpWidget(wrapWithTheme(
        PremiumCheckbox(
          value: false,
          label: 'Accept',
          onChanged: (v) => newValue = v,
        ),
        size: const Size(400, 200),
      ));
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(newValue, isTrue);
    });
  });
}
