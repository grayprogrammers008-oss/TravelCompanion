import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Model representing an onboarding screen
class OnboardingPageModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String>? features;

  const OnboardingPageModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.features,
  });

  /// All onboarding pages
  static List<OnboardingPageModel> get pages => [
        // Screen 1: Welcome - Plan trips together
        const OnboardingPageModel(
          title: 'Welcome to Travel Crew',
          subtitle: 'Plan trips together with your crew and make unforgettable memories',
          icon: Icons.luggage,
          gradientColors: [AppTheme.primaryTeal, AppTheme.primaryDeep],
          features: [
            'Collaborate with friends',
            'Real-time sync',
            'Easy trip planning',
          ],
        ),

        // Screen 2: Expenses - Split costs effortlessly
        const OnboardingPageModel(
          title: 'Split Costs Effortlessly',
          subtitle: 'Track expenses and settle up fairly with automatic splitting',
          icon: Icons.account_balance_wallet,
          gradientColors: [AppTheme.accentCoral, AppTheme.accentOrange],
          features: [
            'Auto-calculate splits',
            'Track who owes what',
            'Multiple payment methods',
          ],
        ),

        // Screen 3: Itinerary - Build the perfect schedule
        const OnboardingPageModel(
          title: 'Build the Perfect Schedule',
          subtitle: 'Create detailed itineraries and keep everyone on the same page',
          icon: Icons.calendar_month,
          gradientColors: [AppTheme.primaryTeal, AppTheme.info],
          features: [
            'Day-by-day planning',
            'Location tracking',
            'Shared checklists',
          ],
        ),

        // Screen 4: AI Autopilot - Let AI guide your adventure
        const OnboardingPageModel(
          title: 'Let AI Guide Your Adventure',
          subtitle: 'Get personalized recommendations and smart suggestions powered by AI',
          icon: Icons.auto_awesome,
          gradientColors: [AppTheme.accentPurple, AppTheme.accentCoral],
          features: [
            'Smart recommendations',
            'Local insights',
            'Adaptive planning',
          ],
        ),
      ];
}
