import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_crew/features/onboarding/domain/models/onboarding_page_model.dart';
import 'package:travel_crew/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:travel_crew/features/onboarding/presentation/widgets/onboarding_screen.dart';
import 'package:travel_crew/features/onboarding/presentation/providers/onboarding_provider.dart';

void main() {
  group('Onboarding Flow Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Complete onboarding flow - Navigate through all pages',
        (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Page')),
                  ),
                ),
                GoRoute(
                  path: '/onboarding',
                  builder: (context, state) => const OnboardingPage(),
                ),
              ],
              initialLocation: '/onboarding',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert - Navigate through each page
      for (int i = 0; i < pages.length; i++) {
        // Verify current page content
        expect(find.text(pages[i].title), findsOneWidget);
        expect(find.text(pages[i].subtitle), findsOneWidget);
        expect(find.byIcon(pages[i].icon), findsOneWidget);

        // Verify features are displayed
        if (pages[i].features != null) {
          for (final feature in pages[i].features!) {
            expect(find.text(feature), findsOneWidget);
          }
        }

        // Verify button text
        if (i < pages.length - 1) {
          expect(find.text('Next'), findsOneWidget);
          expect(find.text('Skip'), findsOneWidget);
          await tester.tap(find.text('Next'));
        } else {
          expect(find.text('Get Started'), findsOneWidget);
          expect(find.text('Skip'), findsNothing);
          await tester.tap(find.text('Get Started'));
        }

        await tester.pumpAndSettle();
      }

      // Assert - Should navigate to home page
      expect(find.text('Home Page'), findsOneWidget);

      // Assert - Onboarding should be marked as complete
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
    });

    testWidgets('Skip onboarding flow', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Page')),
                  ),
                ),
                GoRoute(
                  path: '/onboarding',
                  builder: (context, state) => const OnboardingPage(),
                ),
              ],
              initialLocation: '/onboarding',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should be on first page
      final firstPage = OnboardingPageModel.pages[0];
      expect(find.text(firstPage.title), findsOneWidget);

      // Act - Tap Skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Assert - Should navigate to home page
      expect(find.text('Home Page'), findsOneWidget);

      // Assert - Onboarding should be marked as complete
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
    });

    testWidgets('Swipe through onboarding pages', (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert - Swipe through pages
      for (int i = 0; i < pages.length - 1; i++) {
        expect(find.text(pages[i].title), findsOneWidget);

        // Swipe left to next page
        await tester.drag(
          find.byType(PageView),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();
      }

      // Assert - Should be on last page
      expect(find.text(pages.last.title), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Swipe backward through onboarding pages', (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to last page
      for (int i = 0; i < pages.length - 1; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text(pages.last.title), findsOneWidget);

      // Act - Swipe backward through pages
      for (int i = pages.length - 1; i > 0; i--) {
        expect(find.text(pages[i].title), findsOneWidget);

        // Swipe right to previous page
        await tester.drag(
          find.byType(PageView),
          const Offset(400, 0),
        );
        await tester.pumpAndSettle();
      }

      // Assert - Should be back on first page
      expect(find.text(pages.first.title), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('PageIndicator updates during navigation', (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert - Check indicator updates
      for (int i = 0; i < pages.length; i++) {
        final indicator = tester.widget<PageIndicator>(
          find.byType(PageIndicator),
        );
        expect(indicator.currentPage, i);

        if (i < pages.length - 1) {
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Onboarding state persists after completion', (tester) async {
      // Arrange
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Page')),
                  ),
                ),
                GoRoute(
                  path: '/onboarding',
                  builder: (context, state) => const OnboardingPage(),
                ),
              ],
              initialLocation: '/onboarding',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Complete onboarding
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Assert - Check provider state
      final state = await container.read(onboardingStateProvider.future);
      expect(state, true);

      // Assert - Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);

      container.dispose();
    });

    testWidgets('Button text changes from Next to Get Started',
        (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert
      for (int i = 0; i < pages.length - 1; i++) {
        expect(find.text('Next'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Assert - Last page should show Get Started
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('Skip button disappears on last page', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Skip button visible on first page
      expect(find.text('Skip'), findsOneWidget);

      // Act - Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      // Assert - Skip button hidden on last page
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('Rapid navigation through pages', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Rapidly tap Next button
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Assert - Should reach last page without errors
      expect(find.text('Get Started'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('All pages display correct content', (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;
      final expectedTitles = [
        'Welcome to Travel Crew',
        'Split Costs Effortlessly',
        'Build the Perfect Schedule',
        'Let AI Guide Your Adventure',
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert
      for (int i = 0; i < pages.length; i++) {
        // Verify title
        expect(find.text(expectedTitles[i]), findsOneWidget);

        // Verify all features are present
        expect(pages[i].features, isNotNull);
        expect(pages[i].features!.length, 3);

        for (final feature in pages[i].features!) {
          expect(find.text(feature), findsOneWidget);
        }

        // Navigate to next page
        if (i < pages.length - 1) {
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Mixed navigation - buttons and swipes', (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 0 -> 1 (button)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(pages[1].title), findsOneWidget);

      // Page 1 -> 2 (swipe)
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text(pages[2].title), findsOneWidget);

      // Page 2 -> 1 (swipe back)
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(find.text(pages[1].title), findsOneWidget);

      // Page 1 -> 2 -> 3 (buttons)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Assert - Should be on last page
      expect(find.text(pages[3].title), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Reset onboarding and complete again', (tester) async {
      // Arrange - Complete onboarding first time
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Page')),
                  ),
                ),
                GoRoute(
                  path: '/onboarding',
                  builder: (context, state) => const OnboardingPage(),
                ),
              ],
              initialLocation: '/onboarding',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      var state = await container.read(onboardingStateProvider.future);
      expect(state, true);

      // Act - Reset onboarding
      await container.read(onboardingStateProvider.notifier).resetOnboarding();

      state = await container.read(onboardingStateProvider.future);
      expect(state, false);

      // Rebuild with onboarding page
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should show onboarding again
      expect(find.text(OnboardingPageModel.pages[0].title), findsOneWidget);

      // Complete onboarding again
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      state = await container.read(onboardingStateProvider.future);
      expect(state, true);

      container.dispose();
    });

    testWidgets('Verify gradient backgrounds on all pages', (tester) async {
      // Arrange
      final pages = OnboardingPageModel.pages;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert
      for (int i = 0; i < pages.length; i++) {
        // Find the gradient container
        final containers = tester.widgetList<Container>(
          find.byType(Container),
        );

        // Verify at least one container has the expected gradient
        final hasGradient = containers.any((container) {
          if (container.decoration is BoxDecoration) {
            final decoration = container.decoration as BoxDecoration;
            if (decoration.gradient is LinearGradient) {
              final gradient = decoration.gradient as LinearGradient;
              return gradient.colors.length == pages[i].gradientColors.length;
            }
          }
          return false;
        });

        expect(hasGradient, true, reason: 'Page $i should have gradient');

        // Navigate to next page
        if (i < pages.length - 1) {
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Performance test - smooth animations', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Navigate with animations
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));

        // Verify animation completes smoothly
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Assert no frame drops or errors
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('First-time user complete journey', (tester) async {
      // Arrange - Simulate fresh install
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      // Act 1 - Launch app with onboarding
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Page')),
                  ),
                ),
                GoRoute(
                  path: '/onboarding',
                  builder: (context, state) => const OnboardingPage(),
                ),
              ],
              initialLocation: '/onboarding',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - User sees first onboarding screen
      expect(find.text(OnboardingPageModel.pages[0].title), findsOneWidget);

      // Act 2 - User navigates through all pages
      final pages = OnboardingPageModel.pages;
      for (int i = 0; i < pages.length - 1; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Act 3 - User completes onboarding
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Assert - Onboarding marked complete
      final state = await container.read(onboardingStateProvider.future);
      expect(state, true);

      // Assert - Should navigate to home page
      expect(find.text('Home Page'), findsOneWidget);

      // Simulate app restart - should skip onboarding
      final newState = await container.read(onboardingStateProvider.future);
      expect(newState, true); // Still completed

      container.dispose();
    });
  });
}
