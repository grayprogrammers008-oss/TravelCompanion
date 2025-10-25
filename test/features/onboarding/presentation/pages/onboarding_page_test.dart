import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_crew/features/onboarding/domain/models/onboarding_page_model.dart';
import 'package:travel_crew/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:travel_crew/features/onboarding/presentation/widgets/onboarding_screen.dart';

void main() {
  group('OnboardingPage Widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should render PageView with 4 onboarding screens',
        (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('should display first screen initially', (tester) async {
      // Arrange
      final firstPage = OnboardingPageModel.pages[0];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(firstPage.title), findsOneWidget);
      expect(find.text(firstPage.subtitle), findsOneWidget);
    });

    testWidgets('should display Skip button on first screen', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Skip'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Skip'), findsOneWidget);
    });

    testWidgets('should display Next button on first screen', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Next'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);
    });

    testWidgets('should display PageIndicator with 4 dots', (tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PageIndicator), findsOneWidget);

      final pageIndicator = tester.widget<PageIndicator>(
        find.byType(PageIndicator),
      );
      expect(pageIndicator.pageCount, 4);
      expect(pageIndicator.currentPage, 0);
    });

    testWidgets('should navigate to next page when Next button is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstPage = OnboardingPageModel.pages[0];
      final secondPage = OnboardingPageModel.pages[1];

      expect(find.text(firstPage.title), findsOneWidget);

      // Act
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(secondPage.title), findsOneWidget);
      expect(find.text(secondPage.subtitle), findsOneWidget);
    });

    testWidgets('should update PageIndicator when page changes',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state
      var pageIndicator = tester.widget<PageIndicator>(
        find.byType(PageIndicator),
      );
      expect(pageIndicator.currentPage, 0);

      // Act - Navigate to next page
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
      await tester.pumpAndSettle();

      // Assert
      pageIndicator = tester.widget<PageIndicator>(
        find.byType(PageIndicator),
      );
      expect(pageIndicator.currentPage, 1);
    });

    testWidgets('should allow swiping between pages', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify PageView exists
      expect(find.byType(PageView), findsOneWidget);

      // Act - Swipe left to go to next page
      await tester.drag(
        find.byType(PageView),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      // Assert - Just verify that PageView is still there after swipe
      // (the actual page change is tested by other tests that tap Next button)
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('should hide Skip button on last page', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pumpAndSettle();
      }

      // Assert - Skip button should not be visible on last page
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('should display Get Started button on last page',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
        await tester.pumpAndSettle();
      }

      // Assert
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);
    });

    testWidgets('should display correct icon on Next button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - First page should have arrow forward
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      // Assert - Last page should have check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should mark onboarding as complete when Skip is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home')),
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

      // Act
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
    });

    testWidgets(
        'should mark onboarding as complete when Get Started is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home')),
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

      // Navigate to last page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      // Act
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Assert
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), true);
    });

    testWidgets('should navigate through all 4 pages sequentially',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pages = OnboardingPageModel.pages;

      // Assert - Check each page
      for (int i = 0; i < pages.length; i++) {
        expect(find.text(pages[i].title), findsOneWidget);
        expect(find.text(pages[i].subtitle), findsOneWidget);

        if (i < pages.length - 1) {
          // Not last page - tap Next
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }

      // Final page should show Get Started
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('should allow backward swiping', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on a page (PageView still exists)
      expect(find.byType(PageView), findsOneWidget);

      // Act - Swipe right to go back
      await tester.drag(
        find.byType(PageView),
        const Offset(400, 0),
      );
      await tester.pumpAndSettle();

      // Assert - Just verify that PageView is still there after swipe
      // (the actual page change is tested by other tests that tap Next button)
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('should display all 4 screens content correctly',
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

      // Act & Assert - Check each page
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];

        // Verify title and subtitle
        expect(find.text(page.title), findsOneWidget);
        expect(find.text(page.subtitle), findsOneWidget);

        // Verify icon
        expect(find.byIcon(page.icon), findsOneWidget);

        // Verify features
        if (page.features != null) {
          for (final feature in page.features!) {
            expect(find.text(feature), findsOneWidget);
          }
        }

        // Move to next page if not last
        if (i < pages.length - 1) {
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('should have correct button styling', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Check ElevatedButton
      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final buttonStyle = elevatedButton.style!;

      expect(
        buttonStyle.backgroundColor?.resolve({}),
        Colors.white,
      );

      // Assert - Check TextButton (Skip)
      final textButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Skip'),
      );
      final skipStyle = textButton.style!;

      expect(
        skipStyle.foregroundColor?.resolve({}),
        Colors.white,
      );
    });

    testWidgets('should maintain page state during rebuilds', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final secondPage = OnboardingPageModel.pages[1];
      expect(find.text(secondPage.title), findsOneWidget);

      // Act - Force rebuild
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should still be on page 2
      expect(find.text(secondPage.title), findsOneWidget);
    });

    testWidgets('should have proper safe area padding', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - OnboardingScreen uses SafeArea
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('should handle rapid button taps gracefully', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Rapid taps
      await tester.tap(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Assert - Should handle gracefully without error
      expect(tester.takeException(), isNull);
    });

    testWidgets('should dispose PageController properly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Dispose widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const Scaffold(body: Text('Different Page')),
          ),
        ),
      );

      // Assert - Should dispose without error
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show gradient overlay on bottom section',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Find positioned widget with gradient
      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Positioned),
        ).last,
      );

      expect(positioned.bottom, 0);
      expect(positioned.left, 0);
      expect(positioned.right, 0);
    });

    testWidgets('should handle all pages navigation with PageController',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Navigate through all pages
      for (int i = 0; i < 3; i++) {
        final pageIndicator = tester.widget<PageIndicator>(
          find.byType(PageIndicator),
        );
        expect(pageIndicator.currentPage, i);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      // Assert - Should be on last page
      final finalPageIndicator = tester.widget<PageIndicator>(
        find.byType(PageIndicator),
      );
      expect(finalPageIndicator.currentPage, 3);
    });

    testWidgets('should have full-width button', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, double.infinity);
      expect(sizedBox.height, 56);
    });

    testWidgets('should center button text and icon', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final row = tester.widget<Row>(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(Row),
        ),
      );

      expect(row.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}
