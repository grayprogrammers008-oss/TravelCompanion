import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/profile_photo_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';

/// Model for login user selection
class LoginUserModel {
  final String id;
  final String email;
  final String? fullName;

  const LoginUserModel({
    required this.id,
    required this.email,
    this.fullName,
  });

  String get displayName => fullName ?? email.split('@').first;

  factory LoginUserModel.fromJson(Map<String, dynamic> json) {
    return LoginUserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
    );
  }
}

/// Provider to fetch all users for login dropdown (development/testing only)
final allUsersForLoginProvider = FutureProvider<List<LoginUserModel>>((ref) async {
  try {
    final client = Supabase.instance.client;

    // Fetch all users from profiles table
    // This query uses the public RLS policy (anyone can view profiles with is_active = true)
    final response = await client
        .from('profiles')
        .select('id, email, full_name')
        .order('full_name', ascending: true);

    final users = (response as List)
        .map((json) => LoginUserModel.fromJson(json))
        .toList();

    if (kDebugMode) {
      debugPrint('📋 Loaded ${users.length} users for login dropdown');
    }

    return users;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Error fetching users for login: $e');
    }
    return [];
  }
});

// Remote Data Source Provider - Supabase Only
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

// Repository Provider - Supabase Only
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

// Use Cases Providers
final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateProfileUseCase(repository);
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ChangePasswordUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

// Profile Photo Service Provider
final profilePhotoServiceProvider = Provider<ProfilePhotoService>((ref) {
  return ProfilePhotoService();
});

// Auth State Provider - listens to auth changes from repository
final authStateProvider = StreamProvider<String?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Current User Provider
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return await repository.getCurrentUser();
});

// Auth Controller State
class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Controller - Updated for Riverpod 3.0
class AuthController extends Notifier<AuthState> {
  late final SignUpUseCase _signUpUseCase;
  late final SignInUseCase _signInUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final UpdateProfileUseCase _updateProfileUseCase;
  late final ChangePasswordUseCase _changePasswordUseCase;
  late final ResetPasswordUseCase _resetPasswordUseCase;
  late final AuthRepository _repository;

  @override
  AuthState build() {
    // Initialize dependencies from ref
    _signUpUseCase = ref.read(signUpUseCaseProvider);
    _signInUseCase = ref.read(signInUseCaseProvider);
    _signOutUseCase = ref.read(signOutUseCaseProvider);
    _updateProfileUseCase = ref.read(updateProfileUseCaseProvider);
    _changePasswordUseCase = ref.read(changePasswordUseCaseProvider);
    _resetPasswordUseCase = ref.read(resetPasswordUseCaseProvider);
    _repository = ref.read(authRepositoryProvider);

    return AuthState();
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _signUpUseCase(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      // Invalidate current user provider to refresh with new user data
      ref.invalidate(currentUserProvider);

      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _signInUseCase(email: email, password: password);

      // Invalidate current user provider to refresh with new user data
      ref.invalidate(currentUserProvider);

      // Invalidate trips provider to refresh with new user's trips
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripHistoryProvider);

      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _signOutUseCase();

      // Invalidate current user provider to clear user data
      ref.invalidate(currentUserProvider);

      // Invalidate trips provider to clear trips data
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripHistoryProvider);

      // Invalidate expense providers to clear expense data
      ref.invalidate(userExpensesProvider);
      ref.invalidate(standaloneExpensesProvider);
      ref.invalidate(expenseSummaryProvider);
      ref.invalidate(userBalancesProvider);

      state = AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Reset password - sends password reset email via use case
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _resetPasswordUseCase(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update password - used after clicking reset password link
  Future<void> updatePassword({required String newPassword}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updatePassword(newPassword: newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Verify OTP token and update password (password reset flow)
  Future<void> verifyOtpAndUpdatePassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.verifyOtpAndUpdatePassword(
        token: token,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _updateProfileUseCase(
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
      );

      // Invalidate current user provider to refresh with new user data
      ref.invalidate(currentUserProvider);

      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _changePasswordUseCase(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    final user = await _repository.getCurrentUser();
    state = state.copyWith(user: user, isAuthenticated: user != null);
  }
}

// Auth Controller Provider - Updated for Riverpod 3.0
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

/// Reset method type - email or phone
enum ResetMethod { email, phone }

/// Password Reset Flow State
/// Tracks the current step in the password reset flow so it persists across router rebuilds
class PasswordResetState {
  final int currentStep; // 0: Email/Phone, 1: OTP, 2: Password, 3: Success
  final String? email;
  final String? phone;
  final ResetMethod method;
  final bool isInFlow;
  final bool isSuccess; // Track success state in provider to survive widget rebuilds
  // Store session tokens to survive widget rebuilds after OTP verification
  final String? accessToken;
  final String? refreshToken;

  const PasswordResetState({
    this.currentStep = 0,
    this.email,
    this.phone,
    this.method = ResetMethod.email,
    this.isInFlow = false,
    this.isSuccess = false,
    this.accessToken,
    this.refreshToken,
  });

  /// Get the contact info (email or phone) based on method
  String? get contactInfo => method == ResetMethod.email ? email : phone;

  /// Check if we have valid session tokens stored
  bool get hasSessionTokens => accessToken != null && refreshToken != null;

  PasswordResetState copyWith({
    int? currentStep,
    String? email,
    String? phone,
    ResetMethod? method,
    bool? isInFlow,
    bool? isSuccess,
    String? accessToken,
    String? refreshToken,
  }) {
    return PasswordResetState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      method: method ?? this.method,
      isInFlow: isInFlow ?? this.isInFlow,
      isSuccess: isSuccess ?? this.isSuccess,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

/// Password Reset State Notifier
class PasswordResetNotifier extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() {
    return const PasswordResetState();
  }

  /// Start the password reset flow with email
  void startFlowWithEmail(String email) {
    state = PasswordResetState(
      currentStep: 1, // Move to OTP step after sending
      email: email,
      method: ResetMethod.email,
      isInFlow: true,
    );
  }

  /// Start the password reset flow with phone
  void startFlowWithPhone(String phone) {
    state = PasswordResetState(
      currentStep: 1, // Move to OTP step after sending
      phone: phone,
      method: ResetMethod.phone,
      isInFlow: true,
    );
  }

  /// Legacy method for backward compatibility
  void startFlow(String email) => startFlowWithEmail(email);

  /// Move to password step after OTP verification
  void moveToPasswordStep() {
    state = state.copyWith(currentStep: 2);
  }

  /// Move to password step with session tokens (survives widget rebuilds)
  void moveToPasswordStepWithSession(String accessToken, String refreshToken) {
    state = state.copyWith(
      currentStep: 2,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Mark password reset as successful
  /// This must be called BEFORE signOut to ensure the success state persists
  void markSuccess() {
    state = state.copyWith(isSuccess: true, currentStep: 3);
  }

  /// Reset the flow (after completion or cancel)
  void resetFlow() {
    state = const PasswordResetState();
  }

  /// Go back one step
  void goBack() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }
}

/// Password Reset Provider
final passwordResetProvider = NotifierProvider<PasswordResetNotifier, PasswordResetState>(() {
  return PasswordResetNotifier();
});
