import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/presentation/pages/signup_page.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';

/// Tests for [SignUpPage] using a hand-rolled fake [AuthRepository].

class _FakeAuthRepository implements AuthRepository {
  final List<Map<String, String?>> signUpCalls = [];

  Object? throwOnSignUp;
  UserEntity? signUpUserToReturn;

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    signUpCalls.add({
      'email': email,
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    });
    if (throwOnSignUp != null) throw throwOnSignUp!;
    return signUpUserToReturn ??
        UserEntity(id: 'u-new', email: email, fullName: fullName);
  }

  @override
  Future<UserEntity> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Stream<String?> get authStateChanges => const Stream.empty();

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> verifyOtpAndUpdatePassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  bool get isAuthenticated => false;
}

void main() {
  late _FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
  });

  Widget createApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: AppThemeProvider(
        themeData: AppThemeData.getThemeData(AppThemeType.ocean),
        child: MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => const SignUpPage(),
            ),
          ),
        ),
      ),
    );
  }

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> fillFields(
    WidgetTester tester, {
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
  }) async {
    if (fullName != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        fullName,
      );
    }
    if (email != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        email,
      );
    }
    if (phone != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number (Optional)'),
        phone,
      );
    }
    if (password != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        password,
      );
    }
    if (confirmPassword != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        confirmPassword,
      );
    }
  }

  Future<void> tapCreateAccount(WidgetTester tester) async {
    final inkwell = find.ancestor(
      of: find.text('Create Account'),
      matching: find.byType(InkWell),
    );
    expect(inkwell, findsAtLeastNWidgets(1));
    await tester.ensureVisible(inkwell.first);
    await tester.tap(inkwell.first);
    await tester.pump();
  }

  group('SignUpPage - rendering', () {
    testWidgets('renders all primary UI elements', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.text('Join Travel Crew'), findsOneWidget);
      expect(find.text('Start planning amazing trips together'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Phone Number (Optional)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        findsOneWidget,
      );
      expect(find.text('Create Account'), findsOneWidget);
      expect(
        find.text('By creating an account, you agree to our\nTerms of Service and Privacy Policy'),
        findsOneWidget,
      );
    });

    testWidgets('renders person_add and back button icons', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows prefix icons for fields', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      // Two lock icons (password + confirm password).
      expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2));
    });

    testWidgets('both password fields are initially obscured', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Two visibility (eye) icons because both password fields obscure.
      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });
  });

  group('SignUpPage - password visibility toggles', () {
    testWidgets('tapping first eye icon toggles password obscure',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Tap the first visibility icon (Password field).
      final eyes = find.byIcon(Icons.visibility_outlined);
      await tester.ensureVisible(eyes.first);
      await tester.tap(eyes.first);
      await tester.pump();

      // Now there's one visible eye + one off eye.
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('tapping second eye icon toggles confirm-password obscure',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final eyes = find.byIcon(Icons.visibility_outlined);
      await tester.ensureVisible(eyes.last);
      await tester.tap(eyes.last);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('toggling both icons reveals both passwords', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Tap both visibility icons one after another. The first tap leaves one
      // remaining `visibility_outlined` icon (the other password). Tap that
      // too.
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });
  });

  group('SignUpPage - form validation', () {
    testWidgets('all empty fields show required errors', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(fakeRepo.signUpCalls, isEmpty);
    });

    testWidgets('short name fails name validator', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'A',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      expect(fakeRepo.signUpCalls, isEmpty);
    });

    testWidgets('malformed email fails email validator', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'not-an-email',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(fakeRepo.signUpCalls, isEmpty);
    });

    testWidgets('short password fails length validator', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'short',
        confirmPassword: 'short',
      );
      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(fakeRepo.signUpCalls, isEmpty);
    });

    testWidgets('mismatched confirm-password fails', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'OtherPass1',
      );
      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(fakeRepo.signUpCalls, isEmpty);
    });

    testWidgets('invalid phone number fails', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '12345', // Not 10 digits, not starting with 6-9
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a valid 10-digit phone number'),
        findsOneWidget,
      );
      expect(fakeRepo.signUpCalls, isEmpty);
    });
  });

  group('SignUpPage - successful sign up', () {
    testWidgets('valid fields without phone call repository.signUp',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.signUpCalls, hasLength(1));
      final call = fakeRepo.signUpCalls.single;
      expect(call['email'], 'jane@example.com');
      expect(call['password'], 'StrongPass1');
      expect(call['fullName'], 'Jane Doe');
      // Phone is null when not provided.
      expect(call['phoneNumber'], isNull);
    });

    testWidgets('valid fields with phone send phone to signUp',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        phone: '9876543210',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.signUpCalls, hasLength(1));
      expect(fakeRepo.signUpCalls.single['phoneNumber'], '9876543210');
    });

    testWidgets('full name is trimmed', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: '   Jane Doe   ',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.signUpCalls, hasLength(1));
      expect(fakeRepo.signUpCalls.single['fullName'], 'Jane Doe');
    });

    testWidgets('shows success snackbar after sign up succeeds',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Account created successfully! 🎉'), findsOneWidget);
    });
  });

  group('SignUpPage - sign up error handling', () {
    testWidgets('repository exception is surfaced via snackbar',
        (tester) async {
      useTallViewport(tester);
      fakeRepo.throwOnSignUp = Exception('Email already registered');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Email already registered'), findsOneWidget);
    });

    testWidgets('error keeps user on signup page', (tester) async {
      useTallViewport(tester);
      fakeRepo.throwOnSignUp = Exception('Server unreachable');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillFields(
        tester,
        fullName: 'Jane Doe',
        email: 'jane@example.com',
        password: 'StrongPass1',
        confirmPassword: 'StrongPass1',
      );
      await tapCreateAccount(tester);
      await tester.pumpAndSettle();

      // Still on signup page (success snackbar not shown).
      expect(find.text('Join Travel Crew'), findsOneWidget);
      expect(find.text('Account created successfully! 🎉'), findsNothing);
    });
  });

  group('SignUpPage - back button', () {
    testWidgets('back arrow is present and tappable', (tester) async {
      useTallViewport(tester);
      // Mount inside a Navigator that has a parent route to pop back to.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SignUpPage(),
                        ),
                      ),
                      child: const Text('GO_TO_SIGNUP'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Push the SignUpPage onto the navigator.
      await tester.tap(find.text('GO_TO_SIGNUP'));
      await tester.pumpAndSettle();
      expect(find.text('Join Travel Crew'), findsOneWidget);

      // Tap the back arrow icon and verify we pop back.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('GO_TO_SIGNUP'), findsOneWidget);
      expect(find.text('Join Travel Crew'), findsNothing);
    });
  });
}
