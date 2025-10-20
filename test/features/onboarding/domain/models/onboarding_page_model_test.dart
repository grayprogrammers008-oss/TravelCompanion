import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/features/onboarding/domain/models/onboarding_page_model.dart';

void main() {
  group('OnboardingPageModel', () {
    group('Constructor', () {
      test('should create instance with required parameters', () {
        // Arrange & Act
        const model = OnboardingPageModel(
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
        );

        // Assert
        expect(model.title, 'Test Title');
        expect(model.subtitle, 'Test Subtitle');
        expect(model.icon, Icons.check);
        expect(model.gradientColors, [Colors.blue, Colors.green]);
        expect(model.features, isNull);
      });

      test('should create instance with optional features list', () {
        // Arrange & Act
        const model = OnboardingPageModel(
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
          features: ['Feature 1', 'Feature 2', 'Feature 3'],
        );

        // Assert
        expect(model.features, isNotNull);
        expect(model.features!.length, 3);
        expect(model.features, ['Feature 1', 'Feature 2', 'Feature 3']);
      });

      test('should create instance with empty features list', () {
        // Arrange & Act
        const model = OnboardingPageModel(
          title: 'Test Title',
          subtitle: 'Test Subtitle',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
          features: [],
        );

        // Assert
        expect(model.features, isNotNull);
        expect(model.features!.isEmpty, true);
      });
    });

    group('Static pages getter', () {
      test('should return exactly 4 onboarding pages', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        expect(pages.length, 4);
      });

      test('should return pages in correct order', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        expect(pages[0].title, 'Welcome to Travel Crew');
        expect(pages[1].title, 'Split Costs Effortlessly');
        expect(pages[2].title, 'Build the Perfect Schedule');
        expect(pages[3].title, 'Let AI Guide Your Adventure');
      });

      test('Page 1 - Welcome should have correct properties', () {
        // Act
        final page = OnboardingPageModel.pages[0];

        // Assert
        expect(page.title, 'Welcome to Travel Crew');
        expect(
          page.subtitle,
          'Plan trips together with your crew and make unforgettable memories',
        );
        expect(page.icon, Icons.luggage);
        expect(
          page.gradientColors,
          [AppTheme.primaryTeal, AppTheme.primaryDeep],
        );
        expect(page.features, isNotNull);
        expect(page.features!.length, 3);
        expect(page.features![0], 'Collaborate with friends');
        expect(page.features![1], 'Real-time sync');
        expect(page.features![2], 'Easy trip planning');
      });

      test('Page 2 - Expenses should have correct properties', () {
        // Act
        final page = OnboardingPageModel.pages[1];

        // Assert
        expect(page.title, 'Split Costs Effortlessly');
        expect(
          page.subtitle,
          'Track expenses and settle up fairly with automatic splitting',
        );
        expect(page.icon, Icons.account_balance_wallet);
        expect(
          page.gradientColors,
          [AppTheme.accentCoral, AppTheme.accentOrange],
        );
        expect(page.features, isNotNull);
        expect(page.features!.length, 3);
        expect(page.features![0], 'Auto-calculate splits');
        expect(page.features![1], 'Track who owes what');
        expect(page.features![2], 'Multiple payment methods');
      });

      test('Page 3 - Itinerary should have correct properties', () {
        // Act
        final page = OnboardingPageModel.pages[2];

        // Assert
        expect(page.title, 'Build the Perfect Schedule');
        expect(
          page.subtitle,
          'Create detailed itineraries and keep everyone on the same page',
        );
        expect(page.icon, Icons.calendar_month);
        expect(
          page.gradientColors,
          [AppTheme.primaryTeal, AppTheme.info],
        );
        expect(page.features, isNotNull);
        expect(page.features!.length, 3);
        expect(page.features![0], 'Day-by-day planning');
        expect(page.features![1], 'Location tracking');
        expect(page.features![2], 'Shared checklists');
      });

      test('Page 4 - AI Autopilot should have correct properties', () {
        // Act
        final page = OnboardingPageModel.pages[3];

        // Assert
        expect(page.title, 'Let AI Guide Your Adventure');
        expect(
          page.subtitle,
          'Get personalized recommendations and smart suggestions powered by AI',
        );
        expect(page.icon, Icons.auto_awesome);
        expect(
          page.gradientColors,
          [AppTheme.accentPurple, AppTheme.accentCoral],
        );
        expect(page.features, isNotNull);
        expect(page.features!.length, 3);
        expect(page.features![0], 'Smart recommendations');
        expect(page.features![1], 'Local insights');
        expect(page.features![2], 'Adaptive planning');
      });

      test('all pages should have non-empty titles', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          expect(page.title.isNotEmpty, true);
        }
      });

      test('all pages should have non-empty subtitles', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          expect(page.subtitle.isNotEmpty, true);
        }
      });

      test('all pages should have valid icons', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          expect(page.icon, isNotNull);
          expect(page.icon, isA<IconData>());
        }
      });

      test('all pages should have exactly 2 gradient colors', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          expect(page.gradientColors.length, 2);
        }
      });

      test('all pages should have features list', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          expect(page.features, isNotNull);
          expect(page.features!.isNotEmpty, true);
        }
      });

      test('all pages should have exactly 3 features', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          expect(page.features!.length, 3);
        }
      });

      test('all feature items should be non-empty strings', () {
        // Act
        final pages = OnboardingPageModel.pages;

        // Assert
        for (var page in pages) {
          for (var feature in page.features!) {
            expect(feature.isNotEmpty, true);
            expect(feature, isA<String>());
          }
        }
      });
    });

    group('Gradient Colors', () {
      test('should support any number of gradient colors', () {
        // Arrange & Act
        const model1 = OnboardingPageModel(
          title: 'Test',
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: [Colors.blue],
        );

        const model2 = OnboardingPageModel(
          title: 'Test',
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
        );

        const model3 = OnboardingPageModel(
          title: 'Test',
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green, Colors.red],
        );

        // Assert
        expect(model1.gradientColors.length, 1);
        expect(model2.gradientColors.length, 2);
        expect(model3.gradientColors.length, 3);
      });
    });

    group('Immutability', () {
      test('should create instances with const constructor', () {
        // Arrange & Act
        const model1 = OnboardingPageModel(
          title: 'Test',
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
        );

        const model2 = OnboardingPageModel(
          title: 'Test Different',
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
        );

        // Assert - Same values should be equal
        expect(model1.title, 'Test');
        expect(model2.title, 'Test Different');
        // Properties are immutable
        expect(model1.subtitle, model2.subtitle);
        expect(model1.icon, model2.icon);
      });
    });

    group('Edge Cases', () {
      test('should handle very long title', () {
        // Arrange
        const longTitle = 'This is a very long title that contains many words '
            'and should still work correctly without any issues whatsoever '
            'even though it is extremely long';

        // Act
        const model = OnboardingPageModel(
          title: longTitle,
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
        );

        // Assert
        expect(model.title, longTitle);
        expect(model.title.length, greaterThan(100));
      });

      test('should handle very long subtitle', () {
        // Arrange
        const longSubtitle = 'This is a very long subtitle that contains many '
            'words and should still work correctly without any issues whatsoever '
            'even though it is extremely long and detailed';

        // Act
        const model = OnboardingPageModel(
          title: 'Test',
          subtitle: longSubtitle,
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
        );

        // Assert
        expect(model.subtitle, longSubtitle);
        expect(model.subtitle.length, greaterThan(100));
      });

      test('should handle many features', () {
        // Arrange
        final manyFeatures = List.generate(10, (i) => 'Feature ${i + 1}');

        // Act
        final model = OnboardingPageModel(
          title: 'Test',
          subtitle: 'Test',
          icon: Icons.check,
          gradientColors: const [Colors.blue, Colors.green],
          features: manyFeatures,
        );

        // Assert
        expect(model.features!.length, 10);
        expect(model.features![0], 'Feature 1');
        expect(model.features![9], 'Feature 10');
      });

      test('should handle special characters in text', () {
        // Arrange & Act
        const model = OnboardingPageModel(
          title: 'Test™ with special ©️ characters 🎉',
          subtitle: 'Subtitle with émojis 🚀 and áccents',
          icon: Icons.check,
          gradientColors: [Colors.blue, Colors.green],
          features: ['Feature with 💰', 'Another with ✈️'],
        );

        // Assert
        expect(model.title, contains('™'));
        expect(model.title, contains('©️'));
        expect(model.title, contains('🎉'));
        expect(model.subtitle, contains('🚀'));
        expect(model.subtitle, contains('á'));
        expect(model.features![0], contains('💰'));
        expect(model.features![1], contains('✈️'));
      });
    });
  });
}
