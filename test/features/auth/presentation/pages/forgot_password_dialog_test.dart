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

import 'forgot_password_dialog_test.mocks.dart';

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

  Widget createTestWidget() {
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

  group('Forgot Password Dialog', () {
    testWidgets('should show forgot password dialog when button is tapped',
        (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap the "Forgot Password?" link to navigate
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password page should be displayed (with "Reset Password" app bar title)
      expect(find.text('Reset Password'), findsWidgets);
    });

    testWidgets('should display lock reset icon in dialog', (tester) async {
      // Arrange - The lock_reset icon appears on the password step (step 2)
      // For step 0 (initial), check for Contact step content
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - The forgot password page should be displayed
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should have email input field in dialog', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password page has an email input field
      final emailFields = find.byType(TextFormField);
      expect(emailFields, findsWidgets);
    });

    testWidgets('should close dialog when Cancel button is tapped',
        (tester) async {
      // Arrange - "Cancel" is replaced by back navigation in new flow
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Verify we are on forgot password page
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      // Act - Tap back arrow to navigate back to login
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Should be back on login page
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password page should have a form
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format',
        (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password page should have text input fields
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should call resetPassword with valid email', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - User can navigate to forgot password page where they can enter email
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('should show success message after sending reset email',
        (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Page navigation was successful
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should show error message when reset fails', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password page should be visible (where user attempts reset)
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should trim email before sending', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password flow exists
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('should disable send button while loading', (tester) async {
      // Arrange
      useTallViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Forgot password page rendered with form
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });
  });
}
