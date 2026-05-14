import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pathio/core/router/app_router.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/auth/domain/entities/user_entity.dart';
import 'package:pathio/features/auth/domain/repositories/auth_repository.dart';
import 'package:pathio/features/auth/presentation/pages/login_page.dart';
import 'package:pathio/features/auth/presentation/providers/auth_providers.dart';

/// Tests for [LoginPage] using a hand-rolled fake [AuthRepository] to drive
/// the auth flows without requiring a real Supabase singleton.
///
/// We override [authRepositoryProvider] (instead of [supabaseClientProvider])
/// because [AuthRemoteDataSource] reads from a static client wrapper that
/// cannot be substituted from tests.

class _FakeAuthRepository implements AuthRepository {
  final List<Map<String, String>> signInCalls = [];
  final List<Map<String, String?>> signUpCalls = [];

  Object? throwOnSignIn;
  UserEntity? signInUserToReturn;

  @override
  Future<UserEntity> signIn({required String email, required String password}) async {
    signInCalls.add({'email': email, 'password': password});
    if (throwOnSignIn != null) throw throwOnSignIn!;
    return signInUserToReturn ??
        const UserEntity(id: 'u-1', email: 'test@example.com', fullName: 'Test User');
  }

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
    return UserEntity(id: 'u-new', email: email, fullName: fullName);
  }

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

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('FORGOT_PASSWORD_PAGE'))),
        ),
        GoRoute(
          path: AppRoutes.welcomeChoice,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('WELCOME_CHOICE_PAGE'))),
        ),
      ],
    );
  }

  Widget createApp({
    Future<List<LoginUserModel>> Function()? usersForLogin,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        // Disable the test-user dropdown's network-backed query so tests stay
        // deterministic regardless of how the page reads the dropdown config.
        allUsersForLoginProvider.overrideWith((ref) async {
          if (usersForLogin != null) return usersForLogin();
          return <LoginUserModel>[];
        }),
      ],
      child: AppThemeProvider(
        themeData: AppThemeData.getThemeData(AppThemeType.ocean),
        child: MaterialApp.router(
          routerConfig: buildRouter(),
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

  Future<void> fillCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email Address'),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
  }

  Future<void> tapSignIn(WidgetTester tester) async {
    // The Sign In button is a GlossyButton (uses InkWell). We tap the
    // InkWell that wraps the "Sign In" Text so the gesture fires.
    final inkwell = find.ancestor(
      of: find.text('Sign In'),
      matching: find.byType(InkWell),
    );
    expect(inkwell, findsAtLeastNWidgets(1));
    await tester.ensureVisible(inkwell.first);
    await tester.tap(inkwell.first);
    await tester.pump();
  }

  group('LoginPage - rendering', () {
    testWidgets('renders all primary UI elements', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.text('Pathio'), findsOneWidget);
      expect(find.text('Your Journey, Together'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Sign in to continue your adventure'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      // GlossyButton renders text via Text widget, not ElevatedButton.
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows airplane icon in branding section', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.airplanemode_active), findsOneWidget);
    });

    testWidgets('shows email and lock prefix icons on form fields',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('password field is initially obscured (visibility icon shown)',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });
  });

  group('LoginPage - password visibility toggle', () {
    testWidgets('tapping visibility icon toggles obscure state', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // First tap: switches to visible (visibility_off icon)
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Second tap: switches back to obscured (visibility icon)
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });
  });

  group('LoginPage - form validation', () {
    testWidgets('empty email shows "Email is required" and skips auth',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tapSignIn(tester);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(fakeRepo.signInCalls, isEmpty);
    });

    testWidgets('malformed email shows "Please enter a valid email"',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(tester, email: 'not-an-email', password: 'pw1234567');
      await tapSignIn(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(fakeRepo.signInCalls, isEmpty);
    });

    testWidgets('empty password shows "Password is required" and skips auth',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'user@example.com',
      );
      await tapSignIn(tester);
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
      expect(fakeRepo.signInCalls, isEmpty);
    });

    testWidgets('short password shows length error', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(tester, email: 'user@example.com', password: 'short');
      await tapSignIn(tester);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(fakeRepo.signInCalls, isEmpty);
    });
  });

  group('LoginPage - successful sign in', () {
    testWidgets('valid credentials call repository.signIn', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(
        tester,
        email: 'user@example.com',
        password: 'MyP@ssword1',
      );
      await tapSignIn(tester);
      // Allow notifier to advance through loading + success states.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.signInCalls, hasLength(1));
      expect(fakeRepo.signInCalls.single['email'], 'user@example.com');
      expect(fakeRepo.signInCalls.single['password'], 'MyP@ssword1');

      // Drain the post-success delayed navigation timer to avoid pending timers.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('shows welcome snackbar on successful sign in', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(
        tester,
        email: 'user@example.com',
        password: 'MyP@ssword1',
      );
      await tapSignIn(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Welcome back! 🎉'), findsOneWidget);

      // Let the post-snackbar 500ms delay + go-router navigation finish.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to welcome choice after successful sign in',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(
        tester,
        email: 'user@example.com',
        password: 'MyP@ssword1',
      );
      await tapSignIn(tester);
      await tester.pumpAndSettle();

      expect(find.text('WELCOME_CHOICE_PAGE'), findsOneWidget);
    });
  });

  group('LoginPage - sign in error handling', () {
    testWidgets('repository exception is surfaced via snackbar', (tester) async {
      useTallViewport(tester);
      fakeRepo.throwOnSignIn = Exception('Invalid credentials');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(
        tester,
        email: 'user@example.com',
        password: 'WrongPass1',
      );
      await tapSignIn(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Invalid credentials'), findsOneWidget);
    });

    testWidgets('error keeps user on login page', (tester) async {
      useTallViewport(tester);
      fakeRepo.throwOnSignIn = Exception('Network error');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(
        tester,
        email: 'user@example.com',
        password: 'AnyPassword1',
      );
      await tapSignIn(tester);
      await tester.pumpAndSettle();

      // Still on login form
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('WELCOME_CHOICE_PAGE'), findsNothing);
    });

    testWidgets('non-AuthException StateError is also surfaced', (tester) async {
      useTallViewport(tester);
      fakeRepo.throwOnSignIn = StateError('socket reset');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await fillCredentials(
        tester,
        email: 'user@example.com',
        password: 'AnyPassword1',
      );
      await tapSignIn(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('socket reset'), findsOneWidget);
    });
  });

  group('LoginPage - navigation links', () {
    testWidgets('Forgot Password link navigates to /forgot-password',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final link = find.text('Forgot Password?');
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.text('FORGOT_PASSWORD_PAGE'), findsOneWidget);
    });

    testWidgets('Sign Up link pushes the SignUpPage on the navigator',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final link = find.widgetWithText(TextButton, 'Sign Up');
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();

      // The SignUp page renders this title.
      expect(find.text('Join Pathio'), findsOneWidget);
    });
  });

  group('LoginPage - quick login dropdown', () {
    testWidgets('shows dropdown with users when provider returns data',
        (tester) async {
      useTallViewport(tester);

      await tester.pumpWidget(createApp(usersForLogin: () async => [
            const LoginUserModel(
              id: 'u-1',
              email: 'a@example.com',
              fullName: 'Alice',
            ),
            const LoginUserModel(
              id: 'u-2',
              email: 'b@example.com',
              fullName: 'Bob',
            ),
          ]));
      await tester.pumpAndSettle();

      // The dropdown header reflects the user count.
      expect(find.text('Quick Login (2 users)'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      // Initially, no user is selected — the hint is shown.
      expect(find.text('Select a user...'), findsOneWidget);
    });

    testWidgets('selecting a user populates email and password fields',
        (tester) async {
      useTallViewport(tester);

      await tester.pumpWidget(createApp(usersForLogin: () async => [
            const LoginUserModel(
              id: 'u-1',
              email: 'vinothvsbe@gmail.com',
              fullName: 'Vinoth',
            ),
          ]));
      await tester.pumpAndSettle();

      // Open the dropdown.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Pick "Vinoth".
      await tester.tap(find.text('Vinoth').last);
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Email Address'),
      );
      expect(emailField.controller?.text, 'vinothvsbe@gmail.com');
      // Password from test_users.json should be populated as well.
      final passwordField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Password'),
      );
      expect(passwordField.controller?.text.isNotEmpty, isTrue);
    });

    testWidgets('selecting the empty placeholder clears both fields',
        (tester) async {
      useTallViewport(tester);

      await tester.pumpWidget(createApp(usersForLogin: () async => [
            const LoginUserModel(
              id: 'u-1',
              email: 'vinothvsbe@gmail.com',
              fullName: 'Vinoth',
            ),
          ]));
      await tester.pumpAndSettle();

      // First populate via "Vinoth".
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vinoth').last);
      await tester.pumpAndSettle();

      // Now reset by selecting "Select User" (empty value).
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select User').last);
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Email Address'),
      );
      final passwordField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Password'),
      );
      expect(emailField.controller?.text, isEmpty);
      expect(passwordField.controller?.text, isEmpty);
    });

    testWidgets('renders empty dropdown when provider returns empty list',
        (tester) async {
      useTallViewport(tester);
      // Default override is already empty list — assert the header is hidden.
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Quick Login'), findsNothing);
    });

    testWidgets(
        'when provider errors, the page swallows it and still renders form',
        (tester) async {
      useTallViewport(tester);

      await tester.pumpWidget(createApp(
          usersForLogin: () async => throw Exception('boom')));
      await tester.pumpAndSettle();

      // Form should still render normally.
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.textContaining('Quick Login'), findsNothing);
    });
  });

  group('LoginPage - test notification button', () {
    testWidgets('renders the test notification outlined button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // The button label and icon are both present.
      expect(find.text('Test Notification'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });
  });
}
