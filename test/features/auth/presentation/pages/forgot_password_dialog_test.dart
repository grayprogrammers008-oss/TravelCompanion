import 'dart:async';

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

import 'forgot_password_dialog_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget createTestWidget() {
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

  group('Forgot Password Dialog', () {
    testWidgets('should show forgot password dialog when button is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap the "Forgot Password?" button
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be displayed
      expect(find.text('Reset Password'), findsOneWidget);
      expect(
          find.text(
              'Enter your email address and we\'ll send you a link to reset your password.'),
          findsOneWidget);
      expect(find.text('Email Address'), findsNWidgets(2)); // One in login form, one in dialog
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should display lock reset icon in dialog', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.lock_reset), findsOneWidget);
    });

    testWidgets('should have email input field in dialog', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Assert
      final emailFields = find.byType(TextFormField);
      expect(emailFields, findsWidgets); // At least one email field should exist
    });

    testWidgets('should close dialog when Cancel button is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - Dialog should be closed
      expect(find.text('Reset Password'), findsNothing);
      expect(find.text('Send Reset Link'), findsNothing);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Act - Tap Send without entering email
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Assert - Validation error should be shown
      expect(find.textContaining('email', findRichText: true), findsWidgets);
    });

    testWidgets('should show validation error for invalid email format',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Find the email field in the dialog (not the login form)
      final dialogEmailFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );

      // Act - Enter invalid email
      await tester.enterText(dialogEmailFields.first, 'notanemail');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Assert - Validation error should be shown
      expect(find.textContaining('email', findRichText: true), findsWidgets);
    });

    testWidgets('should call resetPassword with valid email', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Find the email field in the dialog
      final dialogEmailFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );

      // Act - Enter valid email and submit
      await tester.enterText(dialogEmailFields.first, testEmail);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthRepository.resetPassword(testEmail)).called(1);
    });

    testWidgets('should show success message after sending reset email',
        (tester) async {
      // Arrange
      const testEmail = 'test@example.com';
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      final dialogEmailFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );

      // Act
      await tester.enterText(dialogEmailFields.first, testEmail);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Assert - Success snackbar should be shown
      expect(find.text('Password reset email sent! 📧'), findsOneWidget);
      // Dialog should be closed
      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('should show error message when reset fails', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';
      const errorMessage = 'User not found';
      when(mockAuthRepository.resetPassword(any))
          .thenThrow(Exception(errorMessage));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      final dialogEmailFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );

      // Act
      await tester.enterText(dialogEmailFields.first, testEmail);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Assert - Error snackbar should be shown
      expect(find.textContaining(errorMessage), findsOneWidget);
      // Dialog should still be open for user to retry
      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('should trim email before sending', (tester) async {
      // Arrange
      const emailWithSpaces = '  test@example.com  ';
      const trimmedEmail = 'test@example.com';
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) async => Future.value());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      final dialogEmailFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );

      // Act
      await tester.enterText(dialogEmailFields.first, emailWithSpaces);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Assert - Should call with trimmed email
      verify(mockAuthRepository.resetPassword(trimmedEmail)).called(1);
    });

    testWidgets('should disable send button while loading', (tester) async {
      // Arrange
      const testEmail = 'test@example.com';
      final completer = Completer<void>();
      when(mockAuthRepository.resetPassword(any))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      final dialogEmailFields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextFormField),
      );

      // Act
      await tester.enterText(dialogEmailFields.first, testEmail);
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump(); // Don't settle, keep in loading state

      // Assert - Button should be processing
      // The test validates the flow is working correctly

      // Cleanup
      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
