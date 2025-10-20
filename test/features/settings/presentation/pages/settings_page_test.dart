import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/settings/presentation/pages/settings_page.dart';

void main() {
  group('SettingsPage Widget Tests', () {
    late AuthLocalDataSource mockAuthDataSource;

    setUp(() {
      mockAuthDataSource = AuthLocalDataSource();
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith(
              (ref) => Future.delayed(
                const Duration(seconds: 10),
                () => null,
              ),
            ),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Assert - should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display user profile information when loaded', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // Assert - should show user info
      expect(find.text('john.doe'), findsOneWidget); // Username from email
      expect(find.text('john.doe@example.com'), findsOneWidget); // Email
      expect(find.text('J'), findsOneWidget); // Avatar initial
    });

    testWidgets('should display all settings sections', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Account section
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);

      // Assert - App Settings section
      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Assert - About section
      expect(find.text('About'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);

      // Assert - Logout
      expect(find.text('Logout'), findsAtLeastNWidgets(1)); // Title text
    });

    testWidgets('should show Edit Profile button', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.edit), findsOneWidget);
    });

    testWidgets('should show snackbar when Edit Profile is tapped', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Edit Profile - Coming Soon'), findsOneWidget);
    });

    testWidgets('should show snackbar when Personal Information is tapped', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Personal Information'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Personal Information - Coming Soon'), findsOneWidget);
    });

    testWidgets('should show logout confirmation dialog when Logout is tapped', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to the bottom to find the Logout button
      await tester.dragUntilVisible(
        find.byIcon(Icons.logout),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Find the Logout ListTile
      final logoutTile = find.ancestor(
        of: find.byIcon(Icons.logout),
        matching: find.byType(ListTile),
      );

      // Act
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // Assert - Dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Logout'), findsOneWidget);
    });

    testWidgets('should cancel logout when Cancel is tapped in dialog', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to the bottom to find the Logout button
      await tester.dragUntilVisible(
        find.byIcon(Icons.logout),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Open logout dialog
      final logoutTile = find.ancestor(
        of: find.byIcon(Icons.logout),
        matching: find.byType(ListTile),
      );
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // Act - Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog is dismissed
      expect(find.byType(AlertDialog), findsNothing);
      // User should still be on settings page
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should display error state when user loading fails', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => throw Exception('Failed to load user')),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // Assert - should show error message
      expect(find.text('Error loading profile'), findsOneWidget);
    });

    testWidgets('should show correct avatar initial for uppercase email', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'UPPERCASE@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show uppercase 'U' from email
      expect(find.text('U'), findsOneWidget); // First character should be uppercase
    });

    testWidgets('should handle null user gracefully', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show default values
      expect(find.text('?'), findsOneWidget); // Default avatar
      expect(find.text('User'), findsOneWidget); // Default username
    });

    testWidgets('should display all setting tile icons', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(mockAuthDataSource),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check for icons
      expect(find.byIcon(Icons.person), findsOneWidget); // Personal Information
      expect(find.byIcon(Icons.lock), findsOneWidget); // Change Password
      expect(find.byIcon(Icons.notifications), findsOneWidget); // Notifications
      expect(find.byIcon(Icons.language), findsOneWidget); // Language
      expect(find.byIcon(Icons.palette), findsOneWidget); // Theme
      expect(find.byIcon(Icons.info), findsOneWidget); // App Version
      expect(find.byIcon(Icons.privacy_tip), findsOneWidget); // Privacy Policy
      expect(find.byIcon(Icons.description), findsOneWidget); // Terms of Service
      expect(find.byIcon(Icons.logout), findsOneWidget); // Logout
    });
  });

  group('SettingsPage Integration Tests', () {
    testWidgets('should show snackbar for Change Password feature', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(AuthLocalDataSource()),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Change Password - Coming Soon'), findsOneWidget);
    });

    testWidgets('should show snackbar for Theme Settings feature', (WidgetTester tester) async {
      // Arrange
      final testUser = UserEntity(
        id: 'test-user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authLocalDataSourceProvider.overrideWithValue(AuthLocalDataSource()),
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Theme Settings - Coming Soon'), findsOneWidget);
    });
  });
}
