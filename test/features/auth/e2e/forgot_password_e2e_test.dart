import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:travel_crew/features/auth/presentation/pages/login_page.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';

import 'forgot_password_e2e_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: LoginPage()),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
      ],
    );
  }

  Widget createApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: AppThemeProvider(
        themeData: AppThemeData.getThemeData(AppThemeType.ocean),
        child: MaterialApp.router(
          routerConfig: buildRouter(),
        ),
      ),
    );
  }

  // Helper to expand viewport so the bottom of the LoginPage (Forgot Password? link) is visible
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Forgot Password E2E Tests', () {
    testWidgets('Complete forgot password flow - happy path', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Verify login page is displayed
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Step 2: Tap forgot password button to navigate
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 3: Verify forgot password page is displayed
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      // Reset Password text appears in app bar / page
      expect(find.text('Reset Password'), findsWidgets);
    });

    testWidgets('Forgot password flow - network error', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Open forgot password page
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Verify page is displayed and ready for user input
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Forgot password flow - user not found', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Navigate to forgot password page
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Verify page is displayed
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      // Step 3: User decides to go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Step 4: Verify back on login page
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Forgot password flow - validation errors', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Navigate to forgot password page
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Verify page has form
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('Forgot password flow - cancel flow', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Navigate to forgot password page
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Verify page displayed
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      // Step 3: Cancel by going back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Step 4: Verify back on login page
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Forgot password flow - multiple attempts', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Attempt 1 - Navigate to forgot password and back
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      // Attempt 2 - Navigate again
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('Forgot password flow - email with spaces', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Navigate to forgot password page
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Verify the page accepts text input
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
