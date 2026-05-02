import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed AuthLocalDataSource import - no longer needed
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/settings/presentation/pages/settings_page_enhanced.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';

void main() {
  group('SettingsPageEnhanced Widget Tests', () {
    late UserEntity testUser;

    setUp(() async {
      // Initialize SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      testUser = UserEntity(
        id: 'test-user-1',
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display user profile section', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // Assert - should show user profile info
      expect(find.text('john.doe'), findsOneWidget); // Username from email
      expect(find.text('john.doe@example.com'), findsOneWidget); // Email
    });

    testWidgets('should display all notification toggle switches', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - all notification toggles present
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Trip Invites'), findsOneWidget);
      expect(find.text('Expense Updates'), findsOneWidget);
      expect(find.text('Itinerary Changes'), findsOneWidget);

      // Assert - should have 5 switches (one for each notification type)
      expect(find.byType(SwitchListTile), findsNWidgets(5));
    });

    testWidgets('should toggle push notifications switch', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Find the Push Notifications switch
      final pushNotificationsSwitch = find.ancestor(
        of: find.text('Push Notifications'),
        matching: find.byType(SwitchListTile),
      );

      expect(pushNotificationsSwitch, findsOneWidget);

      // Get initial switch value (should be true by default)
      final switchWidget = tester.widget<SwitchListTile>(pushNotificationsSwitch);
      expect(switchWidget.value, isTrue);

      // Act - toggle the switch
      await tester.tap(pushNotificationsSwitch, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert - switch should be off now
      final toggledSwitchWidget = tester.widget<SwitchListTile>(pushNotificationsSwitch);
      expect(toggledSwitchWidget.value, isFalse);

      // Verify SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('push_notifications'), isFalse);
    });

    testWidgets('should display language preference', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show language setting
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget); // Default language
    });

    testWidgets('should display currency preference', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show currency setting
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget); // Default currency
    });

    testWidgets('should display About section with app version', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - About section elements
      expect(find.text('About'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('should display logout button', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - logout button present
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('should display delete account option', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - delete account button present
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('should open language dialog when language tile tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Scroll the Language tile into view (it's below the default viewport)
      await tester.dragUntilVisible(
        find.text('Language'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -100),
      );

      // Find and tap Language tile
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Assert - dialog should be shown
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);
    });

    testWidgets('should open currency dialog when currency tile tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Scroll the Currency tile into view (it's below the default viewport)
      await tester.dragUntilVisible(
        find.text('Currency'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -100),
      );

      // Find and tap Currency tile
      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      // Assert - dialog should be shown
      // Currency entries are formatted as 'CODE - Name' (e.g. 'EUR - Euro')
      expect(find.text('Select Currency'), findsOneWidget);
      expect(find.text('EUR - Euro'), findsOneWidget);
      expect(find.text('GBP - British Pound'), findsOneWidget);
    });

    testWidgets('should show logout confirmation dialog when logout tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Scroll the Logout button into view (it's at the bottom of the page)
      await tester.dragUntilVisible(
        find.text('Logout'),
        find.byType(SingleChildScrollView).first,
        const Offset(0, -100),
      );

      // Find and tap Logout button
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Assert - confirmation dialog should be shown
      // The dialog title is 'Logout' (matching the source code)
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Two 'Logout' instances exist now: tile and dialog button
      expect(find.text('Logout'), findsAtLeastNWidgets(2));
    });

    testWidgets('should persist notification preference changes', (WidgetTester tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        'push_notifications': true,
        'email_notifications': true,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Toggle email notifications
      final emailNotificationsSwitch = find.ancestor(
        of: find.text('Email Notifications'),
        matching: find.byType(SwitchListTile),
      );

      await tester.tap(emailNotificationsSwitch, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify preference was saved
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('email_notifications'), isFalse);
    });

    testWidgets('should load saved preferences on init', (WidgetTester tester) async {
      // Arrange - set saved preferences
      SharedPreferences.setMockInitialValues({
        'push_notifications': false,
        'email_notifications': false,
        'trip_invites': true,
        'language': 'Spanish',
        'currency': 'EUR',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Assert - loaded preferences should be displayed
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);

      // Check switch states
      final pushNotificationsSwitch = find.ancestor(
        of: find.text('Push Notifications'),
        matching: find.byType(SwitchListTile),
      );
      final pushSwitchWidget = tester.widget<SwitchListTile>(pushNotificationsSwitch);
      expect(pushSwitchWidget.value, isFalse);
    });
  });

  group('SettingsPageEnhanced Integration Tests', () {
    late UserEntity testUser;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should navigate to profile page when profile section tapped', (WidgetTester tester) async {
      // Note: This test would require router setup, skipping actual navigation test
      // but verifying the InkWell is tappable

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Find the profile section
      expect(find.text('test@example.com'), findsOneWidget);

      // Profile section should be tappable (has InkWell)
      final profileSection = find.ancestor(
        of: find.text('test@example.com'),
        matching: find.byType(InkWell),
      );
      expect(profileSection, findsOneWidget);
    });

    testWidgets('should handle multiple notification toggle changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
            home: SettingsPageEnhanced(),
          ),
          )
        ),
      );

      await tester.pumpAndSettle();

      // Toggle multiple switches
      await tester.tap(find.ancestor(
        of: find.text('Push Notifications'),
        matching: find.byType(SwitchListTile),
      ), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('Trip Invites'),
        matching: find.byType(SwitchListTile),
      ), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.text('Expense Updates'),
        matching: find.byType(SwitchListTile),
      ), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify all changes were persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('push_notifications'), isFalse);
      expect(prefs.getBool('trip_invites'), isFalse);
      expect(prefs.getBool('expense_updates'), isFalse);
    });
  });
}
