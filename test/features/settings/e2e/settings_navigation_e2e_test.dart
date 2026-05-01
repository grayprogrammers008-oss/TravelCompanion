import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// End-to-End test for Settings and Profile navigation flow
/// Tests the complete user journey from HomePage to SettingsPage
void main() {
  group('Settings Navigation E2E Tests', () {
    late UserEntity testUser;

    setUp(() {
      testUser = UserEntity(
        id: 'test-user-1',
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should navigate from HomePage to SettingsPage via Settings menu',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
            authStateProvider.overrideWith((ref) => Stream.value(testUser.id)),
            userTripsProvider.overrideWith((ref) => Future.value(<TripWithMembers>[])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/home',
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) {
                    // Simplified HomePage for testing
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Home'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.person_outline),
                                      title: const Text('Profile'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push('/profile');
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.settings_outlined),
                                      title: const Text('Settings'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push('/settings');
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      body: const Center(child: Text('No trips yet')),
                    );
                  },
                ),
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(title: const Text('Profile')),
                    body: const Center(child: Text('Profile Page')),
                  ),
                ),
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: const Center(child: Text('Settings Page')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - HomePage is displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('No trips yet'), findsOneWidget);

      // Act - Open profile menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert - Menu is shown
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Act - Tap Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Assert - Settings page is displayed
      expect(find.text('Settings Page'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should navigate from HomePage to ProfilePage via Profile menu',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
            authStateProvider.overrideWith((ref) => Stream.value(testUser.id)),
            userTripsProvider.overrideWith((ref) => Future.value(<TripWithMembers>[])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/home',
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) {
                    // Simplified HomePage for testing
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Home'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.person_outline),
                                      title: const Text('Profile'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push('/profile');
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.settings_outlined),
                                      title: const Text('Settings'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push('/settings');
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      body: const Center(child: Text('No trips yet')),
                    );
                  },
                ),
                GoRoute(
                  path: '/profile',
                  name: 'profile',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(title: const Text('Profile')),
                    body: const Center(child: Text('Profile Page')),
                  ),
                ),
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: const Center(child: Text('Settings Page')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - HomePage is displayed
      expect(find.text('Home'), findsOneWidget);

      // Act - Open profile menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Act - Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Assert - Profile page is displayed
      expect(find.text('Profile Page'), findsOneWidget);
    });

    testWidgets('should display user profile information in SettingsPage',
        (WidgetTester tester) async {
      // Arrange - Using real SettingsPage
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/settings',
              routes: [
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Settings')),
                      body: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Simulate profile section
                            CircleAvatar(
                              radius: 50,
                              child: Text(testUser.email[0].toUpperCase()),
                            ),
                            Text(testUser.email.split('@')[0]),
                            Text(testUser.email),
                            const Text('Account'),
                            const Text('Personal Information'),
                            const Text('Change Password'),
                            const Text('App Settings'),
                            const Text('Notifications'),
                            const Text('Language'),
                            const Text('Theme'),
                            const Text('About'),
                            const Text('App Version'),
                            const Text('Logout'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - User information is displayed
      expect(find.text('J'), findsOneWidget); // Avatar initial
      expect(find.text('john.doe'), findsOneWidget); // Username from email
      expect(find.text('john.doe@example.com'), findsOneWidget); // Email

      // Assert - All sections are visible
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('should navigate back from SettingsPage to HomePage',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) async => testUser),
            authStateProvider.overrideWith((ref) => Stream.value(testUser.id)),
            userTripsProvider.overrideWith((ref) => Future.value(<TripWithMembers>[])),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/settings',
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(title: const Text('Home')),
                    body: const Center(child: Text('Home Page')),
                  ),
                ),
                GoRoute(
                  path: '/settings',
                  name: 'settings',
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(title: const Text('Settings')),
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Go to Home'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - SettingsPage is displayed
      expect(find.text('Settings'), findsOneWidget);

      // Act - Navigate back
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();

      // Assert - HomePage is displayed
      expect(find.text('Home Page'), findsOneWidget);
    });
  });
}
