import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/templates/domain/entities/trip_template.dart';
import 'package:travel_crew/features/templates/presentation/widgets/template_card.dart';

TripTemplate _template({
  String id = 't-1',
  String name = 'Goa Sunset Tour',
  String? description,
  String destination = 'Goa',
  String? destinationState,
  int durationDays = 3,
  double? budgetMin,
  double? budgetMax,
  String currency = 'INR',
  TemplateCategory category = TemplateCategory.beach,
  List<String> bestSeason = const [],
  DifficultyLevel difficultyLevel = DifficultyLevel.easy,
  bool isFeatured = false,
  int useCount = 0,
  double rating = 0,
}) {
  final now = DateTime.parse('2026-01-01T00:00:00Z');
  return TripTemplate(
    id: id,
    name: name,
    description: description,
    destination: destination,
    destinationState: destinationState,
    durationDays: durationDays,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    currency: currency,
    category: category,
    bestSeason: bestSeason,
    difficultyLevel: difficultyLevel,
    isFeatured: isFeatured,
    useCount: useCount,
    rating: rating,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      // Use a basic theme that ensures titleMedium / bodyMedium are not null.
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(width: 360, height: 600, child: child),
      ),
    );
  }

  group('TemplateCard', () {
    testWidgets('renders template name and destination', (tester) async {
      final t = _template(
          name: 'Beach Bonanza', destination: 'Calangute');

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('Beach Bonanza'), findsOneWidget);
      expect(find.text('Calangute'), findsOneWidget);
    });

    testWidgets('joins destination + state when state present',
        (tester) async {
      final t = _template(destination: 'Manali', destinationState: 'HP');

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('Manali, HP'), findsOneWidget);
    });

    testWidgets('renders duration label with singular Day for 1', (tester) async {
      final t = _template(durationDays: 1);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('1 Day'), findsOneWidget);
    });

    testWidgets('renders duration label with plural Days for >1', (tester) async {
      final t = _template(durationDays: 5);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('5 Days'), findsOneWidget);
    });

    testWidgets('renders category display name', (tester) async {
      final t = _template(category: TemplateCategory.heritage);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('Heritage'), findsOneWidget);
    });

    testWidgets('shows Featured badge when isFeatured=true', (tester) async {
      final t = _template(isFeatured: true);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('Featured'), findsOneWidget);
    });

    testWidgets('hides Featured badge when isFeatured=false', (tester) async {
      final t = _template(isFeatured: false);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('Featured'), findsNothing);
    });

    testWidgets('shows description when provided', (tester) async {
      final t = _template(description: 'A relaxing seaside escape');

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('A relaxing seaside escape'), findsOneWidget);
    });

    testWidgets('hides description block when null/empty', (tester) async {
      final t = _template(description: '');

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      // Find should locate no widget with empty text we set
      expect(find.text(''), findsNothing);
    });

    testWidgets('renders budget chip when budgetMax is set', (tester) async {
      final t = _template(budgetMax: 50000);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      // budgetDisplay returns "50K"
      expect(find.text('₹50K'), findsOneWidget);
    });

    testWidgets('uses currency_rupee icon for INR currency', (tester) async {
      final t = _template(currency: 'INR', budgetMax: 1000);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.currency_rupee), findsOneWidget);
    });

    testWidgets('uses attach_money icon for USD currency', (tester) async {
      final t = _template(currency: 'USD', budgetMax: 1000);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('hides budget chip when no budget set', (tester) async {
      final t = _template();

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      // Currency icons should not appear (no budget chip rendered).
      expect(find.byIcon(Icons.currency_rupee), findsNothing);
      expect(find.byIcon(Icons.attach_money), findsNothing);
    });

    testWidgets('renders difficulty chip', (tester) async {
      final t = _template(difficultyLevel: DifficultyLevel.moderate);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('Moderate'), findsOneWidget);
    });

    testWidgets('shows use count when > 0', (tester) async {
      final t = _template(useCount: 42);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('hides use count row when useCount=0', (tester) async {
      final t = _template(useCount: 0);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsNothing);
    });

    testWidgets('shows rating with star when rating > 0', (tester) async {
      final t = _template(rating: 4.7);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
    });

    testWidgets('hides rating when rating == 0', (tester) async {
      final t = _template(rating: 0);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('renders best season tag block when seasons provided',
        (tester) async {
      final t = _template(bestSeason: ['Nov', 'Dec', 'Jan']);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
      expect(find.textContaining('Nov'), findsOneWidget);
    });

    testWidgets('appends ellipsis when more than 3 seasons', (tester) async {
      final t = _template(bestSeason: ['Jan', 'Feb', 'Mar', 'Apr', 'May']);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      // Only first 3 shown plus '...'
      expect(find.textContaining('...'), findsOneWidget);
    });

    testWidgets('hides season block when bestSeason is empty', (tester) async {
      final t = _template(bestSeason: const []);

      await tester.pumpWidget(wrap(TemplateCard(template: t, onTap: () {})));
      await tester.pump();

      expect(find.byIcon(Icons.wb_sunny_outlined), findsNothing);
    });

    testWidgets('invokes onTap when card tapped', (tester) async {
      final t = _template(name: 'TapMe');
      var taps = 0;

      await tester.pumpWidget(wrap(
        TemplateCard(template: t, onTap: () => taps++),
      ));
      await tester.pump();

      // Tap the visible name - the InkWell wraps the whole card.
      await tester.tap(find.text('TapMe'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
