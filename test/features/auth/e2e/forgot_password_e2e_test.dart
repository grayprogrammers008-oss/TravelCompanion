import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/presentation/pages/login_page.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';

import 'forgot_password_e2e_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget createApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: AppThemeProvider(
        themeData: AppThemeData.getThemeData(AppThemeType.ocean),
        child: const MaterialApp(
          home: Scaffold(
            body: LoginPage(),
          ),
        ),
      ),
    );
  }

  group('Forgot Password E2E Tests', () {
    testWidgets('Complete forgot password flow - happy path', (tester) async {
      // Arrange
      const userEmail = 'user@example.com';
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Verify login page is displayed
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Step 2: Tap forgot password button
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 3: Verify dialog is displayed with correct content
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_reset), findsOneWidget);
      expect(
          find.text(
              'Enter your email address and we\'ll send you a link to reset your password.'),
          findsOneWidget);

      // Step 4: Enter email address
      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, userEmail);
      await tester.pumpAndSettle();

      // Step 5: Tap send reset link button
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 6: Verify API was called with correct email
      verify(mockAuthRepository.resetPassword(userEmail)).called(1);

      // Step 7: Verify success message is displayed
      expect(find.text('Password reset email sent! 📧'), findsOneWidget);

      // Step 8: Verify dialog is closed
      expect(find.text('Reset Password'), findsNothing);
      expect(find.text('Send Reset Link'), findsNothing);

      // Step 9: Verify user is back on login page
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Forgot password flow - network error', (tester) async {
      // Arrange
      const userEmail = 'user@example.com';
      const errorMessage = 'Network connection failed';
      when(mockAuthRepository.resetPassword(any))
          .thenThrow(Exception(errorMessage));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Open forgot password dialog
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Enter email
      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, userEmail);

      // Step 3: Try to send reset link
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 4: Verify error message is displayed
      expect(find.textContaining(errorMessage), findsOneWidget);

      // Step 5: Verify dialog is still open for retry
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Step 6: Fix the network (mock successful response)
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      // Step 7: Retry sending reset link
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 8: Verify success this time
      expect(find.text('Password reset email sent! 📧'), findsOneWidget);
      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('Forgot password flow - user not found', (tester) async {
      // Arrange
      const nonExistentEmail = 'nonexistent@example.com';
      const errorMessage = 'User not found';
      when(mockAuthRepository.resetPassword(any))
          .thenThrow(Exception(errorMessage));

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Open dialog
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Enter non-existent email
      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, nonExistentEmail);

      // Step 3: Try to send reset link
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 4: Verify error is shown
      expect(find.textContaining(errorMessage), findsOneWidget);

      // Step 5: User decides to cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Step 6: Verify back on login page
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('Forgot password flow - validation errors', (tester) async {
      // Arrange
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Open dialog
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Try to submit without entering email
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 3: Verify validation error
      expect(find.textContaining('email', findRichText: true), findsWidgets);

      // Step 4: Enter invalid email format
      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, 'notanemail');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 5: Verify validation error persists
      expect(find.textContaining('email', findRichText: true), findsWidgets);

      // Step 6: Enter valid email
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());
      await tester.enterText(emailField.first, 'valid@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 7: Verify success
      expect(find.text('Password reset email sent! 📧'), findsOneWidget);
    });

    testWidgets('Forgot password flow - cancel flow', (tester) async {
      // Arrange
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Open dialog
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Enter email (but not submit)
      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, 'test@example.com');

      // Step 3: Cancel instead of submitting
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Step 4: Verify dialog is closed
      expect(find.text('Reset Password'), findsNothing);

      // Step 5: Verify no API call was made
      verifyNever(mockAuthRepository.resetPassword(any));

      // Step 6: Verify back on login page
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Forgot password flow - multiple attempts', (tester) async {
      // Arrange
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Attempt 1
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, 'user1@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Password reset email sent! 📧'), findsOneWidget);
      verify(mockAuthRepository.resetPassword('user1@example.com')).called(1);

      // Wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Attempt 2 - User tries again with different email
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      final emailField2 = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField2.first, 'user2@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      expect(find.text('Password reset email sent! 📧'), findsOneWidget);
      verify(mockAuthRepository.resetPassword('user2@example.com')).called(1);

      // Verify both calls were made
      verifyInOrder([
        mockAuthRepository.resetPassword('user1@example.com'),
        mockAuthRepository.resetPassword('user2@example.com'),
      ]);
    });

    testWidgets('Forgot password flow - email with spaces', (tester) async {
      // Arrange
      const emailWithSpaces = '  user@example.com  ';
      const trimmedEmail = 'user@example.com';
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Step 1: Open dialog
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Step 2: Enter email with leading/trailing spaces
      final emailField = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField.first, emailWithSpaces);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Step 3: Verify API was called with trimmed email
      verify(mockAuthRepository.resetPassword(trimmedEmail)).called(1);
      expect(find.text('Password reset email sent! 📧'), findsOneWidget);
    });
  });
}
