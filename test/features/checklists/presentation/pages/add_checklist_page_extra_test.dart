import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/checklists/data/packing_templates.dart';
import 'package:travel_crew/features/checklists/presentation/pages/add_checklist_page.dart';
import 'package:travel_crew/features/checklists/presentation/providers/checklist_providers.dart';

import '../widgets/fake_checklist_repository.dart';

/// Extra tests covering the [AddChecklistPage] template selection flow.
/// The form-validation tests already live in
/// `test/features/checklists/presentation/checklist_e2e_test.dart`; this
/// file extends coverage to the template UI paths.
void main() {
  final theme = AppThemeData.getThemeData(AppThemeType.ocean);

  void Function() _ignoreOverflow() {
    final original = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final ex = d.exception;
      if (ex is FlutterError &&
          (ex.message.contains('A RenderFlex overflowed') ||
              ex.message.contains('overflowed by'))) {
        return;
      }
      original?.call(d);
    };
    return () => FlutterError.onError = original;
  }

  Widget wrap(Widget child, FakeChecklistRepository repo) {
    return ProviderScope(
      overrides: [
        checklistRepositoryProvider.overrideWithValue(repo),
      ],
      child: AppThemeProvider(
        themeData: theme,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      ),
    );
  }

  void setSurfaceSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('AddChecklistPage extra coverage', () {
    testWidgets('renders Smart Packing card and template list', (tester) async {
      addTearDown(_ignoreOverflow());
      setSurfaceSize(tester);

      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
          wrap(const AddChecklistPage(tripId: 'trip-1'), repo));
      await tester.pumpAndSettle();

      // Smart Packing card
      expect(find.text('Smart\nPacking'), findsOneWidget);
      expect(find.text('AI-generated'), findsOneWidget);

      // First built-in template's name should appear
      final firstTemplate = PackingTemplates.all.first;
      expect(find.text(firstTemplate.name), findsAtLeastNWidgets(1));
    });

    testWidgets('selecting a template fills the name field and shows preview',
        (tester) async {
      addTearDown(_ignoreOverflow());
      setSurfaceSize(tester);

      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
          wrap(const AddChecklistPage(tripId: 'trip-1'), repo));
      await tester.pumpAndSettle();

      final firstTemplate = PackingTemplates.all.first;
      // Find the GestureDetector that wraps the template card by tapping
      // its name label.
      await tester.tap(find.text(firstTemplate.name).first);
      await tester.pumpAndSettle();

      // Name field is auto-filled with the template name
      final tff = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(tff.controller!.text, firstTemplate.name);

      // Items count is shown in preview ("X items included")
      expect(
        find.text('${firstTemplate.items.length} items included'),
        findsOneWidget,
      );

      // Create button label updates with the count
      expect(
        find.text('Create with ${firstTemplate.items.length} Items'),
        findsOneWidget,
      );
    });

    testWidgets('"Clear" button resets template selection', (tester) async {
      addTearDown(_ignoreOverflow());
      setSurfaceSize(tester);

      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
          wrap(const AddChecklistPage(tripId: 'trip-1'), repo));
      await tester.pumpAndSettle();

      final firstTemplate = PackingTemplates.all.first;
      await tester.tap(find.text(firstTemplate.name).first);
      await tester.pumpAndSettle();

      expect(find.text('Clear'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Name field cleared
      final tff = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(tff.controller!.text, isEmpty);
      // Create button label reverts
      expect(find.text('Create Checklist'), findsOneWidget);
    });

    testWidgets('renders helper text when no template selected',
        (tester) async {
      addTearDown(_ignoreOverflow());
      setSurfaceSize(tester);

      final repo = FakeChecklistRepository();
      await tester.pumpWidget(
          wrap(const AddChecklistPage(tripId: 'trip-1'), repo));
      await tester.pumpAndSettle();

      expect(find.text('or create your own'), findsOneWidget);
      expect(
        find.text('You can add items to this checklist after creating it'),
        findsOneWidget,
      );
    });
  });
}
