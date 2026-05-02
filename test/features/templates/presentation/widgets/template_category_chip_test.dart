import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/templates/presentation/widgets/template_category_chip.dart';

void main() {
  Widget wrap(Widget child, {Color primaryColor = const Color(0xFF1976D2)}) {
    return MaterialApp(
      theme: ThemeData(primaryColor: primaryColor),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('TemplateCategoryChip', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'Beach',
          icon: Icons.beach_access,
          isSelected: false,
          onTap: () {},
        ),
      ));

      expect(find.text('Beach'), findsOneWidget);
      expect(find.byIcon(Icons.beach_access), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'Adventure',
          icon: Icons.terrain,
          isSelected: false,
          onTap: () => taps++,
        ),
      ));

      await tester.tap(find.byType(TemplateCategoryChip));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('icon uses primary color when selected', (tester) async {
      const primary = Color(0xFFFF0000);
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'Heritage',
          icon: Icons.account_balance,
          isSelected: true,
          onTap: () {},
        ),
        primaryColor: primary,
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.account_balance));
      expect(icon.color, primary);
    });

    testWidgets('icon uses white when not selected', (tester) async {
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'Heritage',
          icon: Icons.account_balance,
          isSelected: false,
          onTap: () {},
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.account_balance));
      expect(icon.color, Colors.white);
    });

    testWidgets('text uses primary color & bold when selected',
        (tester) async {
      const primary = Color(0xFF00FF00);
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'Family',
          icon: Icons.family_restroom,
          isSelected: true,
          onTap: () {},
        ),
        primaryColor: primary,
      ));

      final text = tester.widget<Text>(find.text('Family'));
      expect(text.style?.color, primary);
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('text uses white & medium weight when not selected',
        (tester) async {
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'Family',
          icon: Icons.family_restroom,
          isSelected: false,
          onTap: () {},
        ),
      ));

      final text = tester.widget<Text>(find.text('Family'));
      expect(text.style?.color, Colors.white);
      expect(text.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('selected chip has solid white background', (tester) async {
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'X',
          icon: Icons.star,
          isSelected: true,
          onTap: () {},
        ),
      ));

      final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);
    });

    testWidgets('unselected chip has translucent background', (tester) async {
      await tester.pumpWidget(wrap(
        TemplateCategoryChip(
          label: 'X',
          icon: Icons.star,
          isSelected: false,
          onTap: () {},
        ),
      ));

      final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer));
      final decoration = container.decoration as BoxDecoration;
      // 0.2 alpha of white - not pure white
      expect(decoration.color, isNot(Colors.white));
      expect(decoration.color, isNotNull);
    });

    testWidgets('updates appearance when isSelected changes', (tester) async {
      bool selected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: TemplateCategoryChip(
                  label: 'Toggle',
                  icon: Icons.swap_horiz,
                  isSelected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
              ),
            ),
          ),
        ),
      );

      // Initially unselected - white text
      var text = tester.widget<Text>(find.text('Toggle'));
      expect(text.style?.color, Colors.white);

      await tester.tap(find.byType(TemplateCategoryChip));
      await tester.pumpAndSettle();

      // Now selected - color is primary (default ThemeData primaryColor is non-white)
      text = tester.widget<Text>(find.text('Toggle'));
      expect(text.style?.color, isNot(Colors.white));
      expect(text.style?.fontWeight, FontWeight.w600);
    });
  });
}
