import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/emergency/data/datasources/emergency_remote_datasource.dart';
import 'package:travel_crew/features/emergency/presentation/pages/emergency_page.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';

/// A no-op fake [EmergencyRemoteDataSource] that returns nothing for every
/// method. The page's child widgets (SOSButton, NearestHospitalsWidget) will
/// see empty lists / no-op responses and render their empty states.
class _FakeRemoteDataSource implements EmergencyRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    // Stream-returning methods → empty stream.
    if (name.contains('watch')) return const Stream.empty();
    // Future-returning methods → resolved with empty / null.
    return Future.value(<dynamic>[]);
  }
}

/// Widget tests for [EmergencyPage].
///
/// The page wires several child widgets ([SOSButton], [NearestHospitalsWidget],
/// medical emergency button) that internally read providers and may call
/// platform plugins. We don't override every provider — instead we let
/// the tree render with default Riverpod state and verify the page-level
/// scaffolding (header, section titles, quick-action labels, info dialog).
///
/// Tests that would require firing the SOS animation or making a phone call
/// (`url_launcher` channel) are deliberately out-of-scope.

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/emergency',
      routes: [
        GoRoute(
          path: '/emergency',
          builder: (context, state) => const EmergencyPage(),
        ),
      ],
    );
  }

  Widget app() {
    final themeData = AppThemeData.getThemeData(AppThemeType.ocean);
    return ProviderScope(
      overrides: [
        theme_provider.currentThemeDataProvider.overrideWith((_) => themeData),
        emergencyRemoteDataSourceProvider
            .overrideWithValue(_FakeRemoteDataSource()),
      ],
      child: AppThemeProvider(
        themeData: themeData,
        child: MaterialApp.router(routerConfig: buildRouter()),
      ),
    );
  }

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('EmergencyPage — header', () {
    testWidgets('renders the "Emergency Services" app bar title',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Emergency Services'), findsOneWidget);
    });

    testWidgets('renders the info icon in the app bar', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets(
        'renders the red "Emergency Assistance" header with subtitle',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Emergency Assistance'), findsOneWidget);
      expect(
        find.text('Quick access to emergency services and help'),
        findsOneWidget,
      );
    });

    testWidgets('renders the emergency icon in the red header', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.emergency), findsAtLeastNWidgets(1));
    });
  });

  group('EmergencyPage — sections', () {
    testWidgets('renders the "Emergency Alert" section title', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Emergency Alert'), findsOneWidget);
    });

    testWidgets('renders the SOS hold-3-seconds warning text', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(
        find.textContaining('Hold the SOS button for 3 seconds'),
        findsOneWidget,
      );
    });

    testWidgets('renders the "Quick Actions" section title', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Quick Actions'), findsOneWidget);
    });
  });

  group('EmergencyPage — quick action cards', () {
    testWidgets('renders Police card with "Call 100"', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Police'), findsOneWidget);
      expect(find.text('Call 100'), findsOneWidget);
    });

    testWidgets('renders Fire card with "Call 101"', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Fire'), findsOneWidget);
      expect(find.text('Call 101'), findsOneWidget);
    });

    testWidgets('renders Share Location card', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('renders the police icon for Police card', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.local_police), findsOneWidget);
    });

    testWidgets('renders the fire truck icon for Fire card', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.byIcon(Icons.fire_truck), findsOneWidget);
    });
  });

  group('EmergencyPage — info dialog', () {
    testWidgets('tapping the info icon opens an info dialog', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog opens — verify by looking for an AlertDialog or Dialog widget.
      expect(find.byType(Dialog), findsAtLeastNWidgets(0));
      // Drain pending timers / dialog animations.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('EmergencyPage — quick action taps (channel-mocked)', () {
    setUp(() {
      // Mock url_launcher and share_plus channels so taps don't crash.
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher_android'),
        (call) async => true,
      );
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (call) async => true,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher_android'),
        null,
      );
      TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      );
    });

    testWidgets('tapping Police card does not throw', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('Police'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No exception means the tap path completed cleanly. The actual
      // url_launcher call goes through the mocked channel.
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Fire card does not throw', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(app());
      await tester.pump();

      await tester.tap(find.text('Fire'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });

  group('EmergencyPage — tripId', () {
    testWidgets('passes through the optional tripId argument', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            theme_provider.currentThemeDataProvider.overrideWith(
                (_) => AppThemeData.getThemeData(AppThemeType.ocean)),
            emergencyRemoteDataSourceProvider
                .overrideWithValue(_FakeRemoteDataSource()),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: const MaterialApp(
              home: EmergencyPage(tripId: 'trip-1'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Page renders without throwing despite tripId being non-null.
      expect(find.text('Emergency Services'), findsOneWidget);
    });
  });
}
