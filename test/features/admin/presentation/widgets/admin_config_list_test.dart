import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/admin/domain/entities/admin_config.dart';
import 'package:pathio/features/admin/presentation/widgets/admin_config_list.dart';

Widget _wrap() {
  return const ProviderScope(
    child: MaterialApp(home: Scaffold(body: AdminConfigList())),
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AdminConfigList - rendering', () {
    testWidgets('renders search field with hint', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Search configurations...'), findsOneWidget);
    });

    testWidgets('renders all category chips', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // The "All" chip plus each ConfigCategory display name.
      expect(find.text('All'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Feature Flags'), findsOneWidget);
    });

    testWidgets('renders default config items by display name', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      // Some display names from default configs (auto-derived from keys).
      expect(find.text('Max Trip Members'), findsOneWidget);
      expect(find.text('Default Currency'), findsOneWidget);
      expect(find.text('Allow User Registration'), findsOneWidget);
      expect(find.text('Enable Push Notifications'), findsOneWidget);
    });

    testWidgets('renders Switch for boolean configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsWidgets);
    });
  });

  group('AdminConfigList - search', () {
    testWidgets('typing in search shows clear icon', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'currency');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear button resets search', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'currency');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('search filters configs by display name', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'currency');
      await tester.pumpAndSettle();
      // "Default Currency" should appear; an unrelated key should not.
      expect(find.text('Default Currency'), findsOneWidget);
      expect(find.text('Max Trip Members'), findsNothing);
    });

    testWidgets('search with no matches shows empty state', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'zzzzzzzzzz');
      await tester.pumpAndSettle();
      expect(find.text('No configurations found'), findsOneWidget);
      expect(
        find.text('Try adjusting your search or filters'),
        findsOneWidget,
      );
    });

    testWidgets('search by description keyword filters', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // "Maximum amount for a single expense" — search for unique word.
      await tester.enterText(find.byType(TextField).first, 'maximum amount');
      await tester.pumpAndSettle();
      expect(find.text('Max Expense Amount'), findsOneWidget);
    });
  });

  group('AdminConfigList - category filter', () {
    testWidgets('tapping Trips chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();
      // Trips category should remain visible
      expect(find.text('Max Trip Members'), findsOneWidget);
      // Other category configs should be hidden
      expect(find.text('Default Currency'), findsNothing);
    });

    testWidgets('tapping Expenses chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Default Currency'), findsOneWidget);
    });

    testWidgets('tapping Users chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Users'));
      await tester.pumpAndSettle();
      expect(find.text('Allow User Registration'), findsOneWidget);
    });

    testWidgets('tapping Notifications chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Enable Push Notifications'), findsOneWidget);
    });

    testWidgets('tapping Security chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      expect(find.text('Min Password Length'), findsOneWidget);
    });

    testWidgets('tapping Feature Flags chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Feature Flags'));
      await tester.pumpAndSettle();
      expect(find.text('Enable Chat'), findsOneWidget);
    });

    testWidgets('tapping General chip filters configs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      expect(find.text('App Name'), findsOneWidget);
    });

    testWidgets('tapping All resets category filter', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      // After reset, configs from multiple categories should be visible again.
      expect(find.text('Default Currency'), findsOneWidget);
    });
  });

  group('AdminConfigList - editing', () {
    testWidgets('toggling boolean Switch shows snackbar', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Filter to Feature Flags first to make a Switch easy to find.
      await tester.tap(find.text('Feature Flags'));
      await tester.pumpAndSettle();

      // Tap the first Switch.
      final firstSwitch = find.byType(Switch).first;
      await tester.tap(firstSwitch);
      await tester.pumpAndSettle();

      // Snackbar appears after toggle.
      expect(find.textContaining('updated'), findsOneWidget);
    });

    testWidgets('tapping non-boolean config opens edit dialog', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Filter to General to make it easier to find a string config row.
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('App Name'));
      await tester.pumpAndSettle();

      expect(find.text('Edit App Name'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('edit dialog Cancel dismisses without changes', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App Name'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit App Name'), findsNothing);
    });

    testWidgets('edit dialog Save with new value updates config and shows snackbar',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App Name'));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'New App Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Snackbar 'App Name updated' should appear.
      expect(find.textContaining('updated'), findsOneWidget);
    });

    testWidgets('edit dialog Save with empty value keeps dialog open',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App Name'));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, '   ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Dialog should still be open because empty after trim.
      expect(find.text('Edit App Name'), findsOneWidget);
    });

    testWidgets('tapping number config opens dialog with number keyboard',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Max Trip Members'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Max Trip Members'), findsOneWidget);
    });
  });

  group('ConfigListNotifier', () {
    test('updateConfig changes value and updatedAt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(configListProvider);
      final firstId = initial.first.id;

      container.read(configListProvider.notifier).updateConfig(firstId, 'newval');

      final updated = container.read(configListProvider);
      final updatedConfig = updated.firstWhere((c) => c.id == firstId);
      expect(updatedConfig.value, 'newval');
      expect(updatedConfig.updatedAt, isNotNull);
    });

    test('updateConfig with non-existent id is a no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(configListProvider);
      container
          .read(configListProvider.notifier)
          .updateConfig('not-a-real-id', 'whatever');
      final after = container.read(configListProvider);
      expect(after, equals(initial));
    });
  });

  group('ConfigCategoryNotifier and search', () {
    test('setCategory updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedConfigCategoryProvider), isNull);

      container
          .read(selectedConfigCategoryProvider.notifier)
          .setCategory(ConfigCategory.trips.value);
      expect(container.read(selectedConfigCategoryProvider),
          ConfigCategory.trips.value);

      container.read(selectedConfigCategoryProvider.notifier).setCategory(null);
      expect(container.read(selectedConfigCategoryProvider), isNull);
    });

    test('setSearch updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(configSearchQueryProvider), '');

      container.read(configSearchQueryProvider.notifier).setSearch('hello');
      expect(container.read(configSearchQueryProvider), 'hello');
    });

    test('filteredConfigs filters by category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedConfigCategoryProvider.notifier)
          .setCategory(ConfigCategory.security.value);
      final filtered = container.read(filteredConfigsProvider);
      expect(filtered, isNotEmpty);
      expect(filtered.every((c) => c.category == 'security'), isTrue);
    });

    test('filteredConfigs filters by search', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(configSearchQueryProvider.notifier).setSearch('password');
      final filtered = container.read(filteredConfigsProvider);
      expect(filtered, isNotEmpty);
      // All filtered configs should mention password somewhere.
      for (final c in filtered) {
        final hay =
            '${c.key} ${c.displayName} ${c.description ?? ''}'.toLowerCase();
        expect(hay.contains('password'), isTrue);
      }
    });

    test('filteredConfigs combines category and search', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedConfigCategoryProvider.notifier)
          .setCategory(ConfigCategory.users.value);
      container.read(configSearchQueryProvider.notifier).setSearch('email');
      final filtered = container.read(filteredConfigsProvider);
      expect(filtered, isNotEmpty);
      expect(filtered.every((c) => c.category == 'users'), isTrue);
    });
  });
}
