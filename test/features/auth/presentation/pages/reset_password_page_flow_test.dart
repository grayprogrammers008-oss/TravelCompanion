import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_crew/features/auth/presentation/pages/reset_password_page.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';

/// Tests that exercise the actual Supabase auth call sequences in
/// [ResetPasswordPage]. Overrides both [supabaseClientProvider] and
/// [authRepositoryProvider] so we can observe the page's interaction with
/// the auth client (currentSession / currentUser / signOut) and with the
/// repository (updatePassword / verifyOtpAndUpdatePassword).

class _FakeUser extends Mock implements User {
  _FakeUser({String id = 'user-1', String? email = 'reset@example.com'})
      : _id = id,
        _email = email;
  final String _id;
  final String? _email;

  @override
  String get id => _id;

  @override
  String? get email => _email;
}

class _FakeSession extends Mock implements Session {
  _FakeSession({User? user}) : _user = user ?? _FakeUser();
  final User _user;

  @override
  String get accessToken => 'access-token-12345678901234567890';

  @override
  String? get refreshToken => 'refresh-token-12345678901234567890';

  @override
  User get user => _user;
}

class _FakeAuth extends Mock implements GoTrueClient {
  Session? sessionToReturn;
  User? userToReturn;
  int signOutCalls = 0;
  Object? throwOnSignOut;

  @override
  Session? get currentSession => sessionToReturn;

  @override
  User? get currentUser => userToReturn;

  @override
  Future<void> signOut({SignOutScope? scope = SignOutScope.local}) async {
    signOutCalls += 1;
    if (throwOnSignOut != null) throw throwOnSignOut!;
  }
}

class _FakeSupabaseClient extends Mock implements SupabaseClient {
  _FakeSupabaseClient(this._auth);
  final _FakeAuth _auth;

  @override
  GoTrueClient get auth => _auth;
}

class _FakeAuthRepository implements AuthRepository {
  final List<String> updatePasswordCalls = [];
  final List<Map<String, String>> verifyOtpCalls = [];

  Object? throwOnUpdatePassword;
  Object? throwOnVerifyOtp;

  @override
  Future<void> updatePassword({required String newPassword}) async {
    if (throwOnUpdatePassword != null) throw throwOnUpdatePassword!;
    updatePasswordCalls.add(newPassword);
  }

  @override
  Future<void> verifyOtpAndUpdatePassword({
    required String token,
    required String newPassword,
  }) async {
    if (throwOnVerifyOtp != null) throw throwOnVerifyOtp!;
    verifyOtpCalls.add({'token': token, 'password': newPassword});
  }

  // --- Unused methods ----------------------------------------------------

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) =>
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
  bool get isAuthenticated => false;
}

void main() {
  late _FakeAuth fakeAuth;
  late _FakeSupabaseClient fakeClient;
  late _FakeAuthRepository fakeRepo;

  setUp(() {
    fakeAuth = _FakeAuth();
    fakeClient = _FakeSupabaseClient(fakeAuth);
    fakeRepo = _FakeAuthRepository();
  });

  GoRouter buildRouter({String? token}) {
    return GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LOGIN_HOME'))),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(accessToken: token),
        ),
      ],
    );
  }

  Widget createApp({String? token}) {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(fakeClient),
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: AppThemeProvider(
        themeData: AppThemeData.getThemeData(AppThemeType.ocean),
        child: MaterialApp.router(
          routerConfig: buildRouter(token: token),
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

  /// The page does an artificial 500ms wait in initState before checking
  /// the session, so we need to advance the clock past it.
  Future<void> waitForSessionCheck(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    required String password,
    String? confirm,
  }) async {
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), password);
    await tester.enterText(fields.at(1), confirm ?? password);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
    // Allow the future-delay-based navigation to start; we don't fully settle
    // because pumpAndSettle would block on the 2-second redirect timer.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ResetPasswordPage - session check', () {
    testWidgets('shows loading spinner while checking session', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());

      // Immediately after pump — still in checking-session state.
      expect(find.text('Verifying reset link...'), findsOneWidget);
      // Let it finish to avoid pending timers.
      await waitForSessionCheck(tester);
    });

    testWidgets(
        'with no current session and no token shows invalid-link error',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = null
        ..userToReturn = null;

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      expect(
        find.text(
            'Invalid or expired reset link. Please request a new password reset email.'),
        findsOneWidget,
      );
    });

    testWidgets('with valid session shows the form (no error banner)',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = _FakeSession()
        ..userToReturn = _FakeUser();

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      expect(find.text('Create New Password'), findsOneWidget);
      expect(
        find.text(
            'Invalid or expired reset link. Please request a new password reset email.'),
        findsNothing,
      );
    });
  });

  group('ResetPasswordPage - PKCE / direct update flow', () {
    testWidgets('calls repository.updatePassword when session is valid',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = _FakeSession()
        ..userToReturn = _FakeUser();

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      await fillAndSubmit(tester, password: 'NewPass123!');

      expect(fakeRepo.updatePasswordCalls, ['NewPass123!']);
      expect(fakeRepo.verifyOtpCalls, isEmpty);
      // Cancel any pending navigation timers scheduled after success.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('signs out from supabase client after success', (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = _FakeSession()
        ..userToReturn = _FakeUser();

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      await fillAndSubmit(tester, password: 'NewPass123!');

      expect(fakeAuth.signOutCalls, 1);
      // Cancel any pending navigation timers.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows success view after successful update', (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = _FakeSession()
        ..userToReturn = _FakeUser();

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      await fillAndSubmit(tester, password: 'NewPass123!');

      expect(find.text('Password Reset Successful!'), findsOneWidget);
      // Cancel any pending navigation timers.
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('ResetPasswordPage - OTP fallback flow', () {
    testWidgets(
        'calls verifyOtpAndUpdatePassword when no session but token in URL',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = null
        ..userToReturn = null;

      await tester.pumpWidget(createApp(token: 'recovery-token-abc'));
      await waitForSessionCheck(tester);

      // The error message about invalid link is shown but the form is also
      // present because widget.accessToken != null suppresses the banner.
      // Either way, the form fields should be available.
      await fillAndSubmit(tester, password: 'NewPass123!');

      expect(fakeRepo.verifyOtpCalls, hasLength(1));
      expect(fakeRepo.verifyOtpCalls.single['token'], 'recovery-token-abc');
      expect(fakeRepo.verifyOtpCalls.single['password'], 'NewPass123!');
      expect(fakeRepo.updatePasswordCalls, isEmpty);

      // Cancel any pending navigation timers.
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('ResetPasswordPage - error path', () {
    testWidgets('repository.updatePassword throwing surfaces in UI',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = _FakeSession()
        ..userToReturn = _FakeUser();
      fakeRepo.throwOnUpdatePassword = Exception('Password too weak');

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      await fillAndSubmit(tester, password: 'NewPass123!');

      // The page strips the "Exception: " prefix.
      expect(find.text('Password too weak'), findsWidgets);
      // signOut should NOT be called when updatePassword fails.
      expect(fakeAuth.signOutCalls, 0);
    });

    testWidgets('verifyOtpAndUpdatePassword throwing surfaces in UI',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = null
        ..userToReturn = null;
      fakeRepo.throwOnVerifyOtp = Exception('Token expired');

      await tester.pumpWidget(createApp(token: 'expired-token'));
      await waitForSessionCheck(tester);

      await fillAndSubmit(tester, password: 'NewPass123!');

      expect(find.text('Token expired'), findsWidgets);
    });

    testWidgets('mismatched passwords skip the auth call',
        (tester) async {
      useTallViewport(tester);
      fakeAuth
        ..sessionToReturn = _FakeSession()
        ..userToReturn = _FakeUser();

      await tester.pumpWidget(createApp());
      await waitForSessionCheck(tester);

      await fillAndSubmit(
        tester,
        password: 'NewPass123!',
        confirm: 'OtherPass456!',
      );

      expect(fakeRepo.updatePasswordCalls, isEmpty);
      expect(fakeRepo.verifyOtpCalls, isEmpty);
    });
  });
}
