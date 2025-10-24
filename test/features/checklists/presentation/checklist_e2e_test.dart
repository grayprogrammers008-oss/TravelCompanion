import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/checklists/presentation/pages/add_checklist_page.dart';
import 'package:travel_crew/features/checklists/presentation/pages/checklist_list_page.dart';
import 'package:travel_crew/features/checklists/presentation/providers/checklist_providers.dart';
import 'package:travel_crew/features/checklists/presentation/widgets/add_item_bottom_sheet.dart';

void main() {
  group('Checklist E2E Tests', () {
    const testTripId = 'test-trip-123';
    const testChecklistId = 'test-checklist-456';
    const testUserId = 'test-user-789';

    final testChecklist = ChecklistEntity(
      id: testChecklistId,
      tripId: testTripId,
      name: 'Test Packing List',
      createdAt: DateTime.now(),
      createdBy: testUserId,
    );

    final testItem = ChecklistItemEntity(
      id: 'item-1',
      checklistId: testChecklistId,
      title: 'Passport',
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    group('Checklist List Page - Theme Colors', () {
      testWidgets('AppBar should use theme colors correctly', (tester) async {
        // Create provider override for empty list
        final container = ProviderContainer(
          overrides: [
            tripChecklistsProvider(testTripId).overrideWith(
              (ref) => Future.value(<ChecklistEntity>[]),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ChecklistListPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find AppBar
        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        // Get AppBar widget
        final appBar = tester.widget<AppBar>(appBarFinder);

        // Verify AppBar has proper background color (not transparent or white)
        expect(appBar.backgroundColor, isNot(equals(Colors.transparent)));
        expect(appBar.backgroundColor, isNot(equals(Colors.white)));

        // Verify title text color is white
        final titleText = appBar.title as Text;
        expect(titleText.style?.color, equals(Colors.white));

        // Verify icon theme color is white
        expect(appBar.iconTheme?.color, equals(Colors.white));

        // Verify flexibleSpace has gradient decoration
        expect(appBar.flexibleSpace, isNotNull);
        final flexibleSpace = appBar.flexibleSpace as Container;
        expect(flexibleSpace.decoration, isA<BoxDecoration>());
        final decoration = flexibleSpace.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
      });

      testWidgets('should show empty state when no checklists', (tester) async {
        final container = ProviderContainer(
          overrides: [
            tripChecklistsProvider(testTripId).overrideWith(
              (ref) => Future.value(<ChecklistEntity>[]),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ChecklistListPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify empty state UI
        expect(find.text('No Checklists Yet'), findsOneWidget);
        expect(find.text('Create your first checklist to start organizing\nyour trip tasks and packing items'), findsOneWidget);
        expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
      });

      testWidgets('should show checklists when data available', (tester) async {
        final container = ProviderContainer(
          overrides: [
            tripChecklistsProvider(testTripId).overrideWith(
              (ref) => Future.value([testChecklist]),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ChecklistListPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify checklist is displayed
        expect(find.text('Test Packing List'), findsOneWidget);
      });

      testWidgets('should show error state on failure', (tester) async {
        final container = ProviderContainer(
          overrides: [
            tripChecklistsProvider(testTripId).overrideWith(
              (ref) => Future.error('Test error'),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ChecklistListPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error state UI
        expect(find.text('Error loading checklists'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('Add Checklist Page - Theme Colors', () {
      testWidgets('AppBar should use theme colors correctly', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: AddChecklistPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find AppBar
        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);

        // Get AppBar widget
        final appBar = tester.widget<AppBar>(appBarFinder);

        // Verify AppBar has proper background color (not transparent or white)
        expect(appBar.backgroundColor, isNot(equals(Colors.transparent)));
        expect(appBar.backgroundColor, isNot(equals(Colors.white)));

        // Verify title text color is white
        final titleText = appBar.title as Text;
        expect(titleText.style?.color, equals(Colors.white));

        // Verify icon theme color is white
        expect(appBar.iconTheme?.color, equals(Colors.white));

        // Verify flexibleSpace has gradient decoration
        expect(appBar.flexibleSpace, isNotNull);
        final flexibleSpace = appBar.flexibleSpace as Container;
        expect(flexibleSpace.decoration, isA<BoxDecoration>());
        final decoration = flexibleSpace.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
      });
    });

    group('Add Checklist Page - Form Validation', () {
      testWidgets('should show error when name is empty', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: AddChecklistPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap create button without entering name
        final createButton = find.text('Create Checklist');
        expect(createButton, findsOneWidget);

        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Verify validation error is shown
        expect(find.text('Please enter a checklist name'), findsOneWidget);
      });

      testWidgets('should show error when name exceeds 100 characters', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: AddChecklistPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter very long name
        final nameField = find.byType(TextFormField);
        await tester.enterText(nameField, 'A' * 101);

        // Find and tap create button
        final createButton = find.text('Create Checklist');
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Verify validation error is shown
        expect(find.text('Name must be 100 characters or less'), findsOneWidget);
      });

      testWidgets('should accept valid checklist name', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: AddChecklistPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter valid name
        final nameField = find.byType(TextFormField);
        await tester.enterText(nameField, 'Packing List');
        await tester.pumpAndSettle();

        // Verify no validation error
        expect(find.text('Please enter a checklist name'), findsNothing);
        expect(find.text('Name must be 100 characters or less'), findsNothing);
      });
    });

    group('Add Item Bottom Sheet - Form Validation', () {
      testWidgets('should show error when item title is empty', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AddItemBottomSheet(
                          checklistId: testChecklistId,
                        ),
                      );
                    },
                    child: const Text('Show Bottom Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Show bottom sheet
        await tester.tap(find.text('Show Bottom Sheet'));
        await tester.pumpAndSettle();

        // Find and tap add button without entering title
        final addButton = find.text('Add Item');
        expect(addButton, findsOneWidget);

        await tester.tap(addButton.last);
        await tester.pumpAndSettle();

        // Verify validation error is shown
        expect(find.text('Please enter an item title'), findsOneWidget);
      });

      testWidgets('should show error when item title exceeds 200 characters', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AddItemBottomSheet(
                          checklistId: testChecklistId,
                        ),
                      );
                    },
                    child: const Text('Show Bottom Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Show bottom sheet
        await tester.tap(find.text('Show Bottom Sheet'));
        await tester.pumpAndSettle();

        // Enter very long title
        final titleField = find.byType(TextFormField);
        await tester.enterText(titleField.last, 'A' * 201);

        // Find and tap add button
        final addButton = find.text('Add Item');
        await tester.tap(addButton.last);
        await tester.pumpAndSettle();

        // Verify validation error is shown
        expect(find.text('Title must be 200 characters or less'), findsOneWidget);
      });

      testWidgets('should accept valid item title', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AddItemBottomSheet(
                          checklistId: testChecklistId,
                        ),
                      );
                    },
                    child: const Text('Show Bottom Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Show bottom sheet
        await tester.tap(find.text('Show Bottom Sheet'));
        await tester.pumpAndSettle();

        // Enter valid title
        final titleField = find.byType(TextFormField);
        await tester.enterText(titleField.last, 'Passport');
        await tester.pumpAndSettle();

        // Verify no validation error
        expect(find.text('Please enter an item title'), findsNothing);
        expect(find.text('Title must be 200 characters or less'), findsNothing);
      });
    });

    group('Add Item Bottom Sheet - UI Components', () {
      testWidgets('should display all required UI elements', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AddItemBottomSheet(
                          checklistId: testChecklistId,
                        ),
                      );
                    },
                    child: const Text('Show Bottom Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Show bottom sheet
        await tester.tap(find.text('Show Bottom Sheet'));
        await tester.pumpAndSettle();

        // Verify UI elements
        expect(find.text('Add Item'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.add_task), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        // Verify hint text
        expect(find.text('e.g., Passport, Sunscreen, Book tickets'), findsOneWidget);
      });
    });

    group('Integration - Checklist Flow', () {
      testWidgets('should show loading indicator while fetching checklists', (tester) async {
        final container = ProviderContainer(
          overrides: [
            tripChecklistsProvider(testTripId).overrideWith(
              (ref) => Future.delayed(
                const Duration(milliseconds: 500),
                () => [testChecklist],
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ChecklistListPage(tripId: testTripId),
            ),
          ),
        );

        // Verify loading state is shown
        expect(find.text('Loading checklists...'), findsOneWidget);
        expect(find.byIcon(Icons.checklist), findsOneWidget);

        // Wait for data to load
        await tester.pumpAndSettle();

        // Verify loading state is gone and data is shown
        expect(find.text('Loading checklists...'), findsNothing);
        expect(find.text('Test Packing List'), findsOneWidget);
      });

      testWidgets('should navigate to add checklist page when FAB is tapped', (tester) async {
        final container = ProviderContainer(
          overrides: [
            tripChecklistsProvider(testTripId).overrideWith(
              (ref) => Future.value(<ChecklistEntity>[]),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ChecklistListPage(tripId: testTripId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap FAB
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Verify navigation to add checklist page
        expect(find.text('New Checklist'), findsOneWidget);
        expect(find.byType(AddChecklistPage), findsOneWidget);
      });
    });
  });
}
