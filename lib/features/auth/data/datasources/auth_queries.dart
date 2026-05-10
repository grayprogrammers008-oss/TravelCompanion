import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase calls used by [AuthRemoteDataSource].
///
/// The Supabase fluent builders (`from(t).select().eq(c, v).maybeSingle()`)
/// and `auth` calls (`signInWithPassword(...)`, `updateUser(...)`,
/// `verifyOTP(...)`) are not mockable through Mockito — their generic
/// types and the awaited `then()` aren't interceptable. Wrapping these
/// chain calls in this interface lets tests substitute a fake while the
/// production [AuthQueriesImpl] carries the (untestable) Supabase code.
abstract class AuthQueries {
  // ------------- Profile (PostgREST) -------------

  /// Select a profile by id; returns null if missing (maybeSingle).
  Future<Map<String, dynamic>?> getProfileById(String userId);

  /// Insert a new profile row.
  Future<void> insertProfile(Map<String, dynamic> data);

  /// Update profile by id, returning the updated row (maybeSingle).
  Future<Map<String, dynamic>?> updateProfileById(
    String userId,
    Map<String, dynamic> data,
  );

  // ------------- Auth (GoTrueClient) -------------

  /// Sign up with email + password (auth.signUp).
  Future<AuthResponse> authSignUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });

  /// Sign in with email + password (auth.signInWithPassword).
  Future<AuthResponse> authSignIn({
    required String email,
    required String password,
  });

  /// Sign out current session.
  Future<void> authSignOut();

  /// Send a password-reset email with redirect URL.
  Future<void> authResetPasswordForEmail(String email, {String? redirectTo});

  /// Update the current user's password.
  Future<UserResponse> authUpdatePassword(String newPassword);

  /// Verify an OTP token (recovery flow).
  Future<AuthResponse> authVerifyOtpRecovery(String token);

  /// Currently logged-in user (or null).
  User? get currentUser;

  /// Stream that fires on every auth state change.
  Stream<User?> get authStateChanges;
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the Supabase SDK and is exercised end-to-end
/// by integration / live tests, not unit tests.
class AuthQueriesImpl implements AuthQueries {
  AuthQueriesImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<void> insertProfile(Map<String, dynamic> data) async {
    await _client.from('profiles').insert(data);
  }

  @override
  Future<Map<String, dynamic>?> updateProfileById(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', userId)
        .select()
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<AuthResponse> authSignUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  @override
  Future<AuthResponse> authSignIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> authSignOut() => _client.auth.signOut();

  @override
  Future<void> authResetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  @override
  Future<UserResponse> authUpdatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<AuthResponse> authVerifyOtpRecovery(String token) {
    return _client.auth.verifyOTP(type: OtpType.recovery, token: token);
  }

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }
}
