import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';

/// Tests that exercise the actual Supabase auth call sequences in
/// [ForgotPasswordPage]. Uses a hand-rolled fake [SupabaseClient]/[GoTrueClient]
/// that records every interaction so we can assert the page invokes the right
/// auth methods with the right arguments.

class _FakeUser extends Mock implements User {
  _FakeUser({String id = 'user-1', String? email = 'test@example.com'})
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
  _FakeSession({
    this.accessToken = 'access-token-12345678901234567890',
    this.refreshToken = 'refresh-token-12345678901234567890',
    User? user,
  }) : _user = user ?? _FakeUser();

  @override
  final String accessToken;
  @override
  final String? refreshToken;
  final User _user;

  @override
  User get user => _user;
}

class _FakeAuthResponse extends Mock implements AuthResponse {
  _FakeAuthResponse({Session? session, User? user})
      : _session = session,
        _user = user;
  final Session? _session;
  final User? _user;

  @override
  Session? get session => _session;

  @override
  User? get user => _user;
}

class _FakeAuth extends Mock implements GoTrueClient {
  Session? sessionToReturn;
  User? userToReturn;

  // Configurable response for verifyOTP
  AuthResponse? verifyResponse;
  Object? throwOnVerify;

  // Configurable error injection
  Object? throwOnReset;
  Object? throwOnSignInOtp;
  Object? throwOnUpdateUser;

  // Recorded calls
  final List<String> resetEmailsCalled = [];
  final List<Map<String, dynamic>> signInOtpCalls = [];
  final List<Map<String, dynamic>> verifyOtpCalls = [];
  final List<String> setSessionCalls = [];
  final List<String> recoverSessionCalls = [];
  final List<String?> updatedPasswords = [];
  int signOutCalls = 0;

  @override
  Session? get currentSession => sessionToReturn;

  @override
  User? get currentUser => userToReturn;

  @override
  Future<void> resetPasswordForEmail(
    String? email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    if (throwOnReset != null) throw throwOnReset!;
    resetEmailsCalled.add(email ?? '');
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel? channel = OtpChannel.sms,
  }) async {
    if (throwOnSignInOtp != null) throw throwOnSignInOtp!;
    signInOtpCalls.add({'email': email, 'phone': phone});
  }

  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    String? token,
    required OtpType? type,
    String? redirectTo,
    String? captchaToken,
    String? tokenHash,
  }) async {
    verifyOtpCalls.add({
      'email': email,
      'phone': phone,
      'token': token,
      'type': type,
    });
    if (throwOnVerify != null) throw throwOnVerify!;
    return verifyResponse ?? _FakeAuthResponse();
  }

  // Optional: populate currentSession/currentUser as a side-effect when the
  // production code restores a session. Mirrors real Supabase behavior.
  Session? sessionAfterSetSession;
  User? userAfterSetSession;

  Session? sessionAfterRecover;
  User? userAfterRecover;

  @override
  Future<AuthResponse> setSession(String? refreshToken) async {
    setSessionCalls.add(refreshToken ?? '');
    if (sessionAfterSetSession != null) {
      sessionToReturn = sessionAfterSetSession;
      userToReturn = userAfterSetSession ?? userToReturn;
    }
    return _FakeAuthResponse(
      session: sessionAfterSetSession ?? sessionToReturn,
      user: userAfterSetSession ?? userToReturn,
    );
  }

  @override
  Future<AuthResponse> recoverSession(String? jsonStr) async {
    recoverSessionCalls.add(jsonStr ?? '');
    if (sessionAfterRecover != null) {
      sessionToReturn = sessionAfterRecover;
      userToReturn = userAfterRecover ?? userToReturn;
    }
    return _FakeAuthResponse(
      session: sessionAfterRecover ?? sessionToReturn,
      user: userAfterRecover ?? userToReturn,
    );
  }

  @override
  Future<UserResponse> updateUser(
    UserAttributes? attributes, {
    String? emailRedirectTo,
  }) async {
    if (throwOnUpdateUser != null) throw throwOnUpdateUser!;
    updatedPasswords.add(attributes?.password);
    // Return a fake UserResponse via a cast — we rely on Mockito's
    // throwOnMissingStub being off because we never read it back.
    return _FakeUserResponse(user: userToReturn);
  }

  @override
  Future<void> signOut({SignOutScope? scope = SignOutScope.local}) async {
    signOutCalls += 1;
  }
}

class _FakeUserResponse extends Mock implements UserResponse {
  _FakeUserResponse({User? user}) : _user = user;
  final User? _user;
  @override
  User? get user => _user;
}

class _FakeSupabaseClient extends Mock implements SupabaseClient {
  _FakeSupabaseClient(this._auth);
  final _FakeAuth _auth;

  @override
  GoTrueClient get auth => _auth;
}

void main() {
  late _FakeAuth fakeAuth;
  late _FakeSupabaseClient fakeClient;

  setUp(() {
    fakeAuth = _FakeAuth();
    fakeClient = _FakeSupabaseClient(fakeAuth);
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LOGIN'))),
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
        supabaseClientProvider.overrideWithValue(fakeClient),
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

  /// Drives the flow from step 0 to step 1 (OTP input visible).
  Future<void> sendEmailOtp(WidgetTester tester, String email) async {
    final emailField = find.widgetWithText(TextFormField, 'Email Address');
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, email);

    final sendBtn = find.widgetWithText(ElevatedButton, 'Send OTP to Email');
    expect(sendBtn, findsOneWidget);
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();
  }

  /// Drives flow from step 1 to step 2 (Password step).
  Future<void> verifyOtp(WidgetTester tester, String code) async {
    final otpField = find.byType(TextFormField);
    expect(otpField, findsOneWidget);
    await tester.enterText(otpField, code);

    final verifyBtn = find.widgetWithText(ElevatedButton, 'Verify OTP');
    expect(verifyBtn, findsOneWidget);
    await tester.tap(verifyBtn);
    await tester.pumpAndSettle();
  }

  group('ForgotPasswordPage - Send OTP step', () {
    testWidgets('email path calls resetPasswordForEmail with entered email',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'user@example.com');

      expect(fakeAuth.resetEmailsCalled, ['user@example.com']);
      expect(fakeAuth.signInOtpCalls, isEmpty);
    });

    testWidgets('email path rejects whitespace-padded email at validation',
        (tester) async {
      // Validators.email runs the regex BEFORE the page trims, so a padded
      // email fails form validation and resetPasswordForEmail is never called.
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, '   spaced@example.com  ');

      expect(fakeAuth.resetEmailsCalled, isEmpty);
    });

    testWidgets('email path advances to OTP step on success', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'user@example.com');

      // OTP step header
      expect(find.text('Enter OTP Code'), findsOneWidget);
      expect(find.text('Sent via Email'), findsOneWidget);
    });

    testWidgets('email path shows error UI when AuthException is thrown',
        (tester) async {
      useTallViewport(tester);
      fakeAuth.throwOnReset = AuthException('User not found');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'missing@example.com');

      // Page should remain on contact step + show error message.
      expect(find.text('Reset Your Password'), findsOneWidget);
      expect(find.text('Account not found. Please check your email/phone.'),
          findsOneWidget);
    });

    testWidgets('rate limit AuthException maps to friendly message',
        (tester) async {
      useTallViewport(tester);
      fakeAuth.throwOnReset = AuthException('You are over the rate limit');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'user@example.com');

      expect(find.text('Too many attempts. Please wait a few minutes.'),
          findsOneWidget);
    });

    testWidgets('non-AuthException errors map to generic failure copy',
        (tester) async {
      useTallViewport(tester);
      fakeAuth.throwOnReset = StateError('socket exploded');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'user@example.com');

      expect(find.text('Failed to send OTP. Please try again.'), findsOneWidget);
    });

    testWidgets('does not call auth when email field is empty',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final sendBtn = find.widgetWithText(ElevatedButton, 'Send OTP to Email');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(fakeAuth.resetEmailsCalled, isEmpty);
      // Still on contact step (validation failure).
      expect(find.text('Reset Your Password'), findsOneWidget);
    });

    testWidgets('does not call auth for malformed email', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'not-an-email',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP to Email'));
      await tester.pumpAndSettle();

      expect(fakeAuth.resetEmailsCalled, isEmpty);
    });
  });

  group('ForgotPasswordPage - Resend OTP', () {
    testWidgets('Resend triggers another resetPasswordForEmail call',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'resend@example.com');

      // Trigger resend
      final resendBtn = find.text("Didn't receive code? Resend OTP");
      expect(resendBtn, findsOneWidget);
      await tester.tap(resendBtn);
      await tester.pumpAndSettle();

      expect(fakeAuth.resetEmailsCalled,
          ['resend@example.com', 'resend@example.com']);
    });
  });

  group('ForgotPasswordPage - Verify OTP step', () {
    testWidgets('Verify OTP calls verifyOTP with email + code + recovery type',
        (tester) async {
      useTallViewport(tester);
      // Make verify return a session so we can advance.
      fakeAuth.verifyResponse = _FakeAuthResponse(
        session: _FakeSession(),
        user: _FakeUser(),
      );

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'verify@example.com');
      await verifyOtp(tester, '123456');

      expect(fakeAuth.verifyOtpCalls, hasLength(1));
      final call = fakeAuth.verifyOtpCalls.single;
      expect(call['email'], 'verify@example.com');
      expect(call['token'], '123456');
      expect(call['type'], OtpType.recovery);
    });

    testWidgets('Verify OTP advances to password step on session success',
        (tester) async {
      useTallViewport(tester);
      fakeAuth.verifyResponse = _FakeAuthResponse(
        session: _FakeSession(),
        user: _FakeUser(),
      );

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'verify@example.com');
      await verifyOtp(tester, '123456');

      // Password step header is "Create New Password"
      expect(find.text('Create New Password'), findsOneWidget);
    });

    testWidgets('Verify OTP shows error when AuthException is thrown',
        (tester) async {
      useTallViewport(tester);
      fakeAuth.throwOnVerify = AuthException('Token has expired');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'verify@example.com');
      await verifyOtp(tester, '999999');

      expect(find.text('OTP has expired. Please request a new one.'),
          findsOneWidget);
      // Did not advance to password step.
      expect(find.text('Create New Password'), findsNothing);
    });

    testWidgets('Verify OTP without session keeps user on OTP step',
        (tester) async {
      useTallViewport(tester);
      // Empty AuthResponse (no session) — page treats this as Invalid OTP.
      fakeAuth.verifyResponse = _FakeAuthResponse();

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'verify@example.com');
      await verifyOtp(tester, '654321');

      expect(find.text('Create New Password'), findsNothing);
      expect(find.text('Invalid or expired OTP. Please try again.'),
          findsOneWidget);
    });

    testWidgets('Empty OTP field shows inline error and does not call auth',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'verify@example.com');

      // Tap Verify with empty OTP
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(fakeAuth.verifyOtpCalls, isEmpty);
      expect(find.text('Please enter the OTP code'), findsOneWidget);
    });
  });

  group('ForgotPasswordPage - Update password step', () {
    testWidgets('Reset Password calls updateUser with new password',
        (tester) async {
      useTallViewport(tester);

      // Configure session present (to skip restore branch) and successful verify.
      final sess = _FakeSession();
      final usr = _FakeUser();
      fakeAuth
        ..verifyResponse = _FakeAuthResponse(session: sess, user: usr)
        ..sessionToReturn = sess
        ..userToReturn = usr;

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'finish@example.com');
      await verifyOtp(tester, '111222');

      // Now on password step. Enter strong matching passwords.
      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsNWidgets(2));

      await tester.enterText(passwordFields.at(0), 'StrongPass1!');
      await tester.enterText(passwordFields.at(1), 'StrongPass1!');

      // Tap reset
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(fakeAuth.updatedPasswords, ['StrongPass1!']);
      // signOut is called fire-and-forget after success.
      expect(fakeAuth.signOutCalls, 1);
    });

    testWidgets(
        'Reset Password restores session via setSession when no current session',
        (tester) async {
      useTallViewport(tester);

      final sess = _FakeSession(
        accessToken: 'verify-access-token-12345678901234567890',
        refreshToken: 'verify-refresh-token-12345678901234567890',
      );
      final usr = _FakeUser();

      fakeAuth.verifyResponse = _FakeAuthResponse(session: sess, user: usr);
      // Initially no current session — page must restore.
      fakeAuth.sessionToReturn = null;
      fakeAuth.userToReturn = null;
      // Configure the fake so that calling setSession populates the session
      // as a side-effect, the way real Supabase does.
      fakeAuth
        ..sessionAfterSetSession = sess
        ..userAfterSetSession = usr;

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'restore@example.com');
      await verifyOtp(tester, '321321');

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'StrongPass1!');
      await tester.enterText(passwordFields.at(1), 'StrongPass1!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      // setSession should have been called with the verified refresh token.
      expect(fakeAuth.setSessionCalls,
          ['verify-refresh-token-12345678901234567890']);
      expect(fakeAuth.updatedPasswords, ['StrongPass1!']);
    });

    testWidgets('Reset Password surfaces AuthException via error UI',
        (tester) async {
      useTallViewport(tester);

      final sess = _FakeSession();
      final usr = _FakeUser();
      fakeAuth
        ..verifyResponse = _FakeAuthResponse(session: sess, user: usr)
        ..sessionToReturn = sess
        ..userToReturn = usr
        ..throwOnUpdateUser =
            AuthException('New password should be different from old.');

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'fail@example.com');
      await verifyOtp(tester, '999000');

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'StrongPass1!');
      await tester.enterText(passwordFields.at(1), 'StrongPass1!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('New password should be different from old.'),
          findsOneWidget);
      expect(fakeAuth.signOutCalls, 0);
    });

    testWidgets('Aborts when password fields do not match', (tester) async {
      useTallViewport(tester);
      final sess = _FakeSession();
      final usr = _FakeUser();
      fakeAuth
        ..verifyResponse = _FakeAuthResponse(session: sess, user: usr)
        ..sessionToReturn = sess
        ..userToReturn = usr;

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'mismatch@example.com');
      await verifyOtp(tester, '424242');

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'StrongPass1!');
      await tester.enterText(passwordFields.at(1), 'OtherPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(fakeAuth.updatedPasswords, isEmpty);
    });

    testWidgets('Aborts when no session exists and tokens cannot restore',
        (tester) async {
      useTallViewport(tester);

      // verifyOTP returns session, but page reports no current session even
      // after restore attempts.
      final verifiedSession = _FakeSession();
      fakeAuth
        ..verifyResponse =
            _FakeAuthResponse(session: verifiedSession, user: _FakeUser())
        ..sessionToReturn = null
        ..userToReturn = null;

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await sendEmailOtp(tester, 'nosession@example.com');
      await verifyOtp(tester, '202020');

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'StrongPass1!');
      await tester.enterText(passwordFields.at(1), 'StrongPass1!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pumpAndSettle();

      // updateUser must not be called because the session check fails.
      expect(fakeAuth.updatedPasswords, isEmpty);
      // Friendly error message
      expect(
        find.text('Session expired. Please start the password reset process again.'),
        findsOneWidget,
      );
    });
  });

  group('ForgotPasswordPage - back button resets flow', () {
    testWidgets('back from contact step pops out of forgot-password',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Sanity: we are on the page.
      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      // Read provider to assert state is reset
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ForgotPasswordPage)),
      );
      // Move into the flow.
      container.read(passwordResetProvider.notifier).startFlowWithEmail(
            'state@example.com',
          );
      expect(container.read(passwordResetProvider).isInFlow, isTrue);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(container.read(passwordResetProvider).isInFlow, isFalse);
    });
  });
}
