// Widget tests for AiItineraryResultPage.
//
// Scope: rendering for various input states (with/without summary,
// with/without packing, with/without tips, with/without tripId, etc.)
// and tab content.
//
// Out of scope: refinement (calls multiProviderAiServiceProvider which
// requires real AI API keys), share to WhatsApp/clipboard (calls native
// channels), and "Apply to Trip" (writes to Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/ai_itinerary/domain/entities/ai_itinerary.dart';
import 'package:travel_crew/features/ai_itinerary/presentation/widgets/ai_itinerary_result.dart';

void main() {
  final defaultTheme = AppThemeData.getThemeData(AppThemeType.ocean);

  AiGeneratedItinerary buildItinerary({
    String destination = 'Goa',
    int durationDays = 3,
    double? budget,
    String currency = 'INR',
    String? summary,
    List<AiItineraryDay>? days,
    List<AiPackingItem>? packingList,
    List<String>? tips,
  }) {
    return AiGeneratedItinerary(
      destination: destination,
      durationDays: durationDays,
      budget: budget,
      currency: currency,
      summary: summary,
      days: days ??
          const [
            AiItineraryDay(
              dayNumber: 1,
              title: 'Arrival',
              description: 'Land and check in',
              activities: [
                AiItineraryActivity(
                  title: 'Check in to hotel',
                  startTime: '14:00',
                  category: AiActivityCategory.accommodation,
                  estimatedCost: 2500,
                ),
                AiItineraryActivity(
                  title: 'Beach walk',
                  description: 'Sunset stroll',
                  location: 'Baga Beach',
                  category: AiActivityCategory.sightseeing,
                  tip: 'Wear flip-flops',
                ),
              ],
            ),
            AiItineraryDay(
              dayNumber: 2,
              activities: [
                AiItineraryActivity(
                  title: 'Local lunch',
                  category: AiActivityCategory.food,
                ),
              ],
            ),
          ],
      packingList: packingList ?? const [],
      tips: tips ?? const [],
      generatedAt: DateTime(2024, 1, 1),
    );
  }

  Widget buildHarness(AiGeneratedItinerary itinerary,
      {String? tripId, VoidCallback? onBack}) {
    return ProviderScope(
      overrides: [
        theme_provider.currentThemeDataProvider.overrideWith((_) => defaultTheme),
      ],
      child: MaterialApp(
        home: AiItineraryResultPage(
          itinerary: itinerary,
          tripId: tripId,
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  group('AiItineraryResultPage rendering', () {
    testWidgets('renders destination and duration in header', (tester) async {
      await tester.pumpWidget(
        buildHarness(buildItinerary(destination: 'Bali', durationDays: 5)),
      );
      // Header (destination text)
      expect(find.text('Bali'), findsOneWidget);
      // Duration text without budget shows just "<n> days"
      expect(find.text('5 days'), findsOneWidget);
    });

    testWidgets('renders budget alongside duration with INR symbol',
        (tester) async {
      await tester.pumpWidget(
        buildHarness(buildItinerary(
          destination: 'Goa',
          durationDays: 3,
          budget: 25000,
          currency: 'INR',
        )),
      );
      expect(find.text('3 days • ₹25000'), findsOneWidget);
    });

    testWidgets('renders budget with USD symbol', (tester) async {
      await tester.pumpWidget(
        buildHarness(buildItinerary(
          destination: 'NYC',
          durationDays: 4,
          budget: 1500,
          currency: 'USD',
        )),
      );
      expect(find.text('4 days • \$1500'), findsOneWidget);
    });

    testWidgets('renders summary text when summary is provided',
        (tester) async {
      await tester.pumpWidget(
        buildHarness(buildItinerary(summary: 'A relaxing beach getaway')),
      );
      expect(find.text('A relaxing beach getaway'), findsOneWidget);
    });

    testWidgets('does not render summary text when summary is null',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      expect(find.text('A relaxing beach getaway'), findsNothing);
    });

    testWidgets('renders tab labels with counts', (tester) async {
      final itinerary = buildItinerary(
        packingList: const [
          AiPackingItem(item: 'Sunscreen'),
          AiPackingItem(item: 'Hat'),
        ],
        tips: const ['Carry cash', 'Hydrate well', 'Bring sunglasses'],
      );
      await tester.pumpWidget(buildHarness(itinerary));

      // 2 days, 2 packing items, 3 tips
      expect(find.text('Itinerary (2)'), findsOneWidget);
      expect(find.text('Packing (2)'), findsOneWidget);
      expect(find.text('Tips (3)'), findsOneWidget);
    });

    testWidgets('shows AppBar title and share menu icon', (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      expect(find.text('Your AI Itinerary'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('Itinerary tab (default)', () {
    testWidgets('renders the first day card with provided title',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      // First day uses provided title
      expect(find.text('Arrival'), findsOneWidget);
      // Day-number bubbles include "1"
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows activity count for the first day', (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      // Day 1 has 2 activities
      expect(find.text('2 activities'), findsOneWidget);
    });

    testWidgets('falls back to "Day N" when day title is null', (tester) async {
      // Single day with no title -> renders "Day 1"
      final itinerary = buildItinerary(
        days: const [
          AiItineraryDay(
            dayNumber: 1,
            activities: [AiItineraryActivity(title: 'Test activity')],
          ),
        ],
      );
      await tester.pumpWidget(buildHarness(itinerary));
      expect(find.text('Day 1'), findsOneWidget);
    });

    testWidgets('renders activity titles for initially expanded day 1',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      // initiallyExpanded: day.dayNumber <= 2 => Day 1 always laid out and
      // expanded. Day 2 may be off-screen depending on layout, so we only
      // assert Day 1 activities here.
      expect(find.text('Check in to hotel'), findsOneWidget);
      expect(find.text('Beach walk'), findsOneWidget);
    });

    testWidgets('renders activity description, location, time, and tip',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      expect(find.text('Sunset stroll'), findsOneWidget); // description
      expect(find.text('Baga Beach'), findsOneWidget); // location
      expect(find.text('14:00'), findsOneWidget); // start time
      expect(find.text('Wear flip-flops'), findsOneWidget); // tip
    });

    testWidgets('renders estimated cost chip for activities with cost',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      // 2500 INR -> ₹2500
      expect(find.text('₹2500'), findsOneWidget);
    });
  });

  group('Packing tab', () {
    testWidgets('shows empty state when packing list is empty',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      await tester.tap(find.text('Packing (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No packing suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
    });

    testWidgets('renders packing items grouped by category', (tester) async {
      final itinerary = buildItinerary(packingList: const [
        AiPackingItem(item: 'Passport', category: 'Documents', isEssential: true),
        AiPackingItem(item: 'ID Card', category: 'Documents'),
        AiPackingItem(item: 'Sunscreen', category: 'Toiletries'),
      ]);
      await tester.pumpWidget(buildHarness(itinerary));
      await tester.tap(find.text('Packing (3)'));
      await tester.pumpAndSettle();

      // Headers (uppercased)
      expect(find.text('DOCUMENTS'), findsOneWidget);
      expect(find.text('TOILETRIES'), findsOneWidget);

      // Items
      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('ID Card'), findsOneWidget);
      expect(find.text('Sunscreen'), findsOneWidget);

      // Item counts
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('1 items'), findsOneWidget);

      // Essential badge
      expect(find.text('Essential'), findsOneWidget);
    });

    testWidgets('groups items without category under "Other"',
        (tester) async {
      final itinerary = buildItinerary(packingList: const [
        AiPackingItem(item: 'Snacks'),
      ]);
      await tester.pumpWidget(buildHarness(itinerary));
      await tester.tap(find.text('Packing (1)'));
      await tester.pumpAndSettle();
      expect(find.text('OTHER'), findsOneWidget);
    });
  });

  group('Tips tab', () {
    testWidgets('shows empty state when tips is empty', (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      await tester.tap(find.text('Tips (0)'));
      await tester.pumpAndSettle();

      expect(find.text('No tips available'), findsOneWidget);
      // The lightbulb_outline icon also appears in the tab bar, so we expect
      // at least 2 occurrences (tab icon + empty-state icon).
      expect(find.byIcon(Icons.lightbulb_outline), findsAtLeastNWidgets(2));
    });

    testWidgets('renders numbered tips list', (tester) async {
      final itinerary =
          buildItinerary(tips: const ['Tip One', 'Tip Two', 'Tip Three']);
      await tester.pumpWidget(buildHarness(itinerary));
      await tester.tap(find.text('Tips (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Tip One'), findsOneWidget);
      expect(find.text('Tip Two'), findsOneWidget);
      expect(find.text('Tip Three'), findsOneWidget);

      // Numbered indices
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });
  });

  group('Bottom action bar', () {
    testWidgets('shows "Create Trip" when no tripId is provided',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      expect(find.text('Create Trip'), findsOneWidget);
      expect(find.text('Apply to Trip'), findsNothing);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('shows "Apply to Trip" when tripId is provided',
        (tester) async {
      await tester.pumpWidget(
        buildHarness(buildItinerary(), tripId: 'trip-123'),
      );
      expect(find.text('Apply to Trip'), findsOneWidget);
      expect(find.text('Create Trip'), findsNothing);
    });
  });

  group('Refinement section', () {
    testWidgets('renders collapsed refinement bar with remaining count',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      expect(find.text('Tap to refine itinerary'), findsOneWidget);
      // Initial _maxRefinements is 3 -> "3" badge present
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('expands refinement panel on tap and shows input + send button',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));

      await tester.tap(find.text('Tap to refine itinerary'));
      await tester.pumpAndSettle();

      // Expanded title
      expect(find.text('Refine Itinerary'), findsOneWidget);
      // Remaining-left chip
      expect(find.text('3 left'), findsOneWidget);
      // Text input is present
      expect(find.byType(TextField), findsOneWidget);
      // Send icon button
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });

  group('Discard dialog', () {
    testWidgets('back button opens discard confirmation dialog',
        (tester) async {
      await tester.pumpWidget(buildHarness(buildItinerary()));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Discard Itinerary?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // Dialog has a "Discard" action button (matching the bottom-bar
      // "Discard" outlined button -> findsAtLeastNWidgets(1))
      expect(find.text('Discard'), findsAtLeastNWidgets(1));
    });

    testWidgets('Cancel dismisses dialog without invoking onBack',
        (tester) async {
      var backCalled = false;
      await tester.pumpWidget(buildHarness(
        buildItinerary(),
        onBack: () => backCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard Itinerary?'), findsNothing);
      expect(backCalled, false);
    });
  });
}
