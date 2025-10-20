import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/invite_remote_datasource.dart';
import '../../data/repositories/invite_repository_impl.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../domain/usecases/generate_invite_usecase.dart';
import '../../domain/usecases/accept_invite_usecase.dart';
import '../../domain/usecases/revoke_invite_usecase.dart';
import '../../domain/usecases/get_trip_invites_usecase.dart';
import '../../domain/entities/invite_entity.dart';
import '../../../../core/network/supabase_client.dart';

// ============================================================================
// DATA SOURCES
// ============================================================================

/// Provider for invite remote data source
final inviteRemoteDataSourceProvider = Provider<InviteRemoteDataSource>((ref) {
  return InviteRemoteDataSource(SupabaseClientWrapper.client);
});

// ============================================================================
// REPOSITORIES
// ============================================================================

/// Provider for invite repository
final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  final remoteDataSource = ref.watch(inviteRemoteDataSourceProvider);
  return InviteRepositoryImpl(remoteDataSource);
});

// ============================================================================
// USE CASES
// ============================================================================

/// Provider for generate invite use case
final generateInviteUseCaseProvider = Provider<GenerateInviteUseCase>((ref) {
  final repository = ref.watch(inviteRepositoryProvider);
  return GenerateInviteUseCase(repository);
});

/// Provider for accept invite use case
final acceptInviteUseCaseProvider = Provider<AcceptInviteUseCase>((ref) {
  final repository = ref.watch(inviteRepositoryProvider);
  return AcceptInviteUseCase(repository);
});

/// Provider for revoke invite use case
final revokeInviteUseCaseProvider = Provider<RevokeInviteUseCase>((ref) {
  final repository = ref.watch(inviteRepositoryProvider);
  return RevokeInviteUseCase(repository);
});

/// Provider for get trip invites use case
final getTripInvitesUseCaseProvider = Provider<GetTripInvitesUseCase>((ref) {
  final repository = ref.watch(inviteRepositoryProvider);
  return GetTripInvitesUseCase(repository);
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

/// Provider for getting trip invites
final tripInvitesProvider = FutureProvider.family<List<InviteEntity>, String>((ref, tripId) async {
  final useCase = ref.watch(getTripInvitesUseCaseProvider);
  return await useCase(tripId: tripId);
});

/// Provider for getting invite by code
final inviteByCodeProvider = FutureProvider.family<InviteEntity?, String>((ref, inviteCode) async {
  final repository = ref.watch(inviteRepositoryProvider);
  return await repository.getInviteByCode(inviteCode);
});

/// Provider for pending invites for current user
final pendingInvitesProvider = FutureProvider<List<InviteEntity>>((ref) async {
  final repository = ref.watch(inviteRepositoryProvider);
  // TODO: Get current user email from auth
  final email = 'user@example.com'; // Placeholder
  return await repository.getPendingInvitesForEmail(email);
});

// ============================================================================
// CONTROLLER
// ============================================================================

/// State for invite operations
class InviteState {
  final bool isLoading;
  final String? error;
  final InviteEntity? lastCreatedInvite;
  final String? successMessage;

  const InviteState({
    this.isLoading = false,
    this.error,
    this.lastCreatedInvite,
    this.successMessage,
  });

  InviteState copyWith({
    bool? isLoading,
    String? error,
    InviteEntity? lastCreatedInvite,
    String? successMessage,
  }) {
    return InviteState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastCreatedInvite: lastCreatedInvite ?? this.lastCreatedInvite,
      successMessage: successMessage,
    );
  }
}

/// Controller for invite operations
class InviteController extends Notifier<InviteState> {
  late final GenerateInviteUseCase _generateInviteUseCase;
  late final AcceptInviteUseCase _acceptInviteUseCase;
  late final RevokeInviteUseCase _revokeInviteUseCase;

  @override
  InviteState build() {
    // Initialize dependencies from ref
    _generateInviteUseCase = ref.read(generateInviteUseCaseProvider);
    _acceptInviteUseCase = ref.read(acceptInviteUseCaseProvider);
    _revokeInviteUseCase = ref.read(revokeInviteUseCaseProvider);

    return const InviteState();
  }

  /// Generate a new invite
  Future<InviteEntity?> generateInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final invite = await _generateInviteUseCase(
        tripId: tripId,
        email: email,
        phoneNumber: phoneNumber,
        expiresInDays: expiresInDays,
      );

      state = state.copyWith(
        isLoading: false,
        lastCreatedInvite: invite,
        successMessage: 'Invite created successfully!',
      );

      return invite;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  /// Accept an invite
  Future<bool> acceptInvite({
    required String inviteCode,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _acceptInviteUseCase(
        inviteCode: inviteCode,
        userId: userId,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Successfully joined the trip!',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Revoke an invite
  Future<bool> revokeInvite({
    required String inviteId,
    required String userId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _revokeInviteUseCase(
        inviteId: inviteId,
        userId: userId,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invite revoked successfully',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

/// Provider for invite controller
final inviteControllerProvider = NotifierProvider<InviteController, InviteState>(() {
  return InviteController();
});
