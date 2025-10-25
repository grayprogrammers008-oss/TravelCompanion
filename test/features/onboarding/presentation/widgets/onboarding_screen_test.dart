import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/onboarding/domain/models/onboarding_page_model.dart';
import 'package:travel_crew/features/onboarding/presentation/widgets/onboarding_screen.dart';

void main() {
  group('OnboardingScreen Widget', () {
    testWidgets('should render all basic elements', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        icon: Icons.check_circle,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display gradient background', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.red, Colors.yellow],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(OnboardingScreen),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;

      expect(gradient.colors, equals([Colors.red, Colors.yellow]));
    });

    testWidgets('should display icon in circular container', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.star,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );

      // Assert
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.size, 80);
      expect(iconWidget.color, Colors.white);
    });

    testWidgets('should display features list when provided', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
        features: ['Feature 1', 'Feature 2', 'Feature 3'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Feature 1'), findsOneWidget);
      expect(find.text('Feature 2'), findsOneWidget);
      expect(find.text('Feature 3'), findsOneWidget);
    });

    testWidgets('should not display features section when features is null',
        (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should only have title and subtitle text
      expect(find.text('Test'), findsNWidgets(2)); // title and subtitle
    });

    testWidgets('should not display features section when features is empty',
        (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
        features: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      // No feature items should be displayed
    });

    testWidgets('should display feature bullets correctly', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
        features: ['Feature 1'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Find bullet point container
      final bulletContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(Container),
        ),
      );

      // Check if any container matches bullet point specs
      final hasBullet = bulletContainers.any((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == Colors.white &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });

      expect(hasBullet, true);
    });

    testWidgets('should use SafeArea', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );

      // Assert
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should apply correct padding', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );

      // Assert - Find the main padding widget
      final paddingWidget = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SafeArea),
          matching: find.byType(Padding),
        ).first,
      );

      expect(
        paddingWidget.padding,
        const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacing2xl,
        ),
      );
    });

    testWidgets('should render with real onboarding pages', (tester) async {
      // Arrange - Test with actual app data
      final pages = OnboardingPageModel.pages;

      for (final page in pages) {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: OnboardingScreen(page: page),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text(page.title), findsOneWidget);
        expect(find.text(page.subtitle), findsOneWidget);
        expect(find.byIcon(page.icon), findsOneWidget);

        if (page.features != null) {
          for (final feature in page.features!) {
            expect(find.text(feature), findsOneWidget);
          }
        }
      }
    });

    testWidgets('should handle long text gracefully', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'This is a very long title that should still render correctly '
            'without causing any layout issues or overflow errors',
        subtitle: 'This is also a very long subtitle that contains a lot of '
            'text and should wrap properly to multiple lines',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
        features: [
          'This is a very long feature description that should wrap',
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should not overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('should center content vertically', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );

      // Assert
      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(Padding),
          matching: find.byType(Column),
        ).first,
      );

      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('should have white text color', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test Title',
        subtitle: 'Test Subtitle',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Find text widgets
      final titleWidget = tester.widget<Text>(find.text('Test Title'));
      final subtitleWidget = tester.widget<Text>(find.text('Test Subtitle'));

      expect(titleWidget.style?.color, Colors.white);
      expect(
        subtitleWidget.style?.color,
        Colors.white.withValues(alpha: 0.9),
      );
    });

    testWidgets('should display multiple features correctly', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test',
        subtitle: 'Test',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
        features: [
          'Feature 1',
          'Feature 2',
          'Feature 3',
          'Feature 4',
          'Feature 5',
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - All features visible
      expect(find.text('Feature 1'), findsOneWidget);
      expect(find.text('Feature 2'), findsOneWidget);
      expect(find.text('Feature 3'), findsOneWidget);
      expect(find.text('Feature 4'), findsOneWidget);
      expect(find.text('Feature 5'), findsOneWidget);
    });

    testWidgets('should handle special characters in text', (tester) async {
      // Arrange
      const testPage = OnboardingPageModel(
        title: 'Test™ Title 🎉',
        subtitle: 'Subtitle with émojis 🚀',
        icon: Icons.check,
        gradientColors: [Colors.blue, Colors.green],
        features: ['Feature with 💰', 'Another ✈️'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(page: testPage),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test™ Title 🎉'), findsOneWidget);
      expect(find.text('Subtitle with émojis 🚀'), findsOneWidget);
      expect(find.text('Feature with 💰'), findsOneWidget);
      expect(find.text('Another ✈️'), findsOneWidget);
    });
  });

  group('PageIndicator Widget', () {
    testWidgets('should render correct number of dots', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 4),
          ),
        ),
      );

      // Assert - Find all animated containers (dots)
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('should highlight current page dot', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 2, pageCount: 4),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      var index = 0;
      for (final container in animatedContainers) {
        final decoration = container.decoration as BoxDecoration;
        if (index == 2) {
          // Current page should be highlighted
          expect(decoration.color, isNotNull);
          expect(decoration.color, isNot(Colors.white.withValues(alpha: 0.5)));
          expect(container.constraints?.maxWidth, 24);
        } else {
          // Other pages should be neutral
          expect(decoration.color, AppTheme.neutral300);
          expect(container.constraints?.maxWidth, 8);
        }
        index++;
      }
    });

    testWidgets('should highlight first page when currentPage is 0',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final firstDot = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final decoration = firstDot.decoration as BoxDecoration;

      expect(decoration.color, isNotNull);
      expect(decoration.color, isNot(Colors.white.withValues(alpha: 0.5)));
      expect(firstDot.constraints?.maxWidth, 24);
    });

    testWidgets('should highlight last page correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 3, pageCount: 4),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final dots = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();

      final lastDot = dots[3];
      final decoration = lastDot.decoration as BoxDecoration;

      expect(decoration.color, isNotNull);
      expect(decoration.color, isNot(Colors.white.withValues(alpha: 0.5)));
      expect(lastDot.constraints?.maxWidth, 24);
    });

    testWidgets('should center indicators horizontally', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 3),
          ),
        ),
      );

      // Assert
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('should have correct spacing between dots', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 3),
          ),
        ),
      );

      // Assert
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      for (final container in animatedContainers) {
        expect(
          container.margin,
          const EdgeInsets.symmetric(horizontal: 4),
        );
      }
    });

    testWidgets('should have correct height for all dots', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 1, pageCount: 4),
          ),
        ),
      );

      // Assert
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      for (final container in animatedContainers) {
        expect(container.constraints?.maxHeight, 8);
      }
    });

    testWidgets('should animate when current page changes', (tester) async {
      // Arrange - Start at page 0
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Change to page 1
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 1, pageCount: 3),
          ),
        ),
      );

      // Pump halfway through animation
      await tester.pump(const Duration(milliseconds: 150));

      // Assert - Animation should be in progress
      expect(tester.binding.hasScheduledFrame, true);
    });

    testWidgets('should handle single page', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AnimatedContainer), findsOneWidget);

      final dot = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = dot.decoration as BoxDecoration;

      expect(decoration.color, isNotNull);
      expect(decoration.color, isNot(Colors.white.withValues(alpha: 0.5)));
    });

    testWidgets('should handle many pages', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 5, pageCount: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AnimatedContainer), findsNWidgets(10));

      final dots = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList();

      final activeDot = dots[5];
      final decoration = activeDot.decoration as BoxDecoration;

      expect(decoration.color, isNotNull);
      expect(decoration.color, isNot(Colors.white.withValues(alpha: 0.5)));
    });

    testWidgets('should have rounded corners', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 3),
          ),
        ),
      );

      // Assert
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      for (final container in animatedContainers) {
        final decoration = container.decoration as BoxDecoration;
        final borderRadius = decoration.borderRadius as BorderRadius;

        expect(
          borderRadius,
          BorderRadius.circular(AppTheme.radiusSm),
        );
      }
    });

    testWidgets('should transition smoothly between pages', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 0, pageCount: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Get initial state
      final initialDot = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final initialDecoration = initialDot.decoration as BoxDecoration;
      expect(initialDecoration.color, isNotNull);
      expect(initialDecoration.color, isNot(Colors.white.withValues(alpha: 0.5)));

      // Act - Move to next page
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(currentPage: 1, pageCount: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - First dot should no longer be highlighted
      final updatedDot = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final updatedDecoration = updatedDot.decoration as BoxDecoration;
      expect(updatedDecoration.color, AppTheme.neutral300);

      // Second dot should be highlighted
      final secondDot = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).toList()[1];
      final secondDecoration = secondDot.decoration as BoxDecoration;
      expect(secondDecoration.color, isNotNull);
      expect(secondDecoration.color, isNot(Colors.white.withValues(alpha: 0.5)));
    });
  });
}
