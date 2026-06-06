import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../data/datasources/poll_remote_datasource.dart';
import '../../data/repositories/poll_repository_impl.dart';
import '../../domain/entities/poll_entity.dart';
import '../../domain/entities/poll_option_entity.dart';
import '../../domain/entities/poll_result_entity.dart';
import '../../domain/repositories/poll_repository.dart';

// ============================================================================
// DATA SOURCES & REPOSITORY
// ============================================================================

final pollRemoteDataSourceProvider = Provider<PollRemoteDataSource>((ref) {
  return PollRemoteDataSource(SupabaseClientWrapper.client);
});

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepositoryImpl(ref.watch(pollRemoteDataSourceProvider));
});

// ============================================================================
// STATE PROVIDERS
// ============================================================================

final tripPollsProvider =
    StreamProvider.family<List<PollEntity>, String>((ref, tripId) {
  return ref.watch(pollRepositoryProvider).watchTripPolls(tripId);
});

final pollProvider =
    FutureProvider.family<PollEntity?, String>((ref, pollId) async {
  return ref.watch(pollRepositoryProvider).getPoll(pollId);
});

final pollOptionsProvider =
    FutureProvider.family<List<PollOptionEntity>, String>((ref, pollId) async {
  return ref.watch(pollRepositoryProvider).getPollOptions(pollId);
});

final pollResultsProvider =
    StreamProvider.family<PollResultEntity, String>((ref, pollId) {
  return ref.watch(pollRepositoryProvider).watchPollResults(pollId);
});

/// Counts of polls in this trip relevant for badging.
///
/// * [unvoted] — open polls the current user hasn't voted on yet. Drives
///   the attention-grabbing pink "needs your vote" badge.
/// * [open]   — all open polls (including ones the user has voted on).
///   Drives a softer "voting in progress" hint after the user has voted
///   but before the deadline.
///
/// Returns zero counts while polls are loading or on error so call sites
/// don't have to deal with AsyncValue plumbing.
class PollBadgeCounts {
  final int unvoted;
  final int open;
  const PollBadgeCounts({required this.unvoted, required this.open});
  static const empty = PollBadgeCounts(unvoted: 0, open: 0);
  bool get hasAny => open > 0;
}

final pollBadgeCountsProvider =
    Provider.family<PollBadgeCounts, String>((ref, tripId) {
  final pollsAsync = ref.watch(tripPollsProvider(tripId));
  return pollsAsync.maybeWhen(
    data: (polls) {
      var unvoted = 0;
      var open = 0;
      for (final p in polls) {
        if (kDebugMode) {
          debugPrint(
              '🎯 [badgeCounts] $tripId poll "${p.question}" '
              'status=${p.status} deadline=${p.deadline.toIso8601String()} '
              'isOpenForVoting=${p.isOpenForVoting} '
              'currentUserVoted=${p.currentUserVoted}');
        }
        if (p.isOpenForVoting) {
          open++;
          if (!p.currentUserVoted) unvoted++;
        }
      }
      return PollBadgeCounts(unvoted: unvoted, open: open);
    },
    orElse: () => PollBadgeCounts.empty,
  );
});

/// Convenience: just the unvoted count. Kept for the trip-detail tile
/// badge which only needs the attention-grabbing number.
final unvotedOpenPollCountProvider =
    Provider.family<int, String>((ref, tripId) {
  return ref.watch(pollBadgeCountsProvider(tripId)).unvoted;
});

/// One row per trip that has at least one open poll, with the
/// trip-level unvoted/open counts. Used by the home-page notification
/// bell to list "where do I have polls to vote on".
class PendingPollsTripRow {
  final String tripId;
  final String tripName;
  final int unvoted;
  final int open;
  const PendingPollsTripRow({
    required this.tripId,
    required this.tripName,
    required this.unvoted,
    required this.open,
  });
}

class PendingPollsSummary {
  final int totalUnvoted;
  final int totalOpen;
  final List<PendingPollsTripRow> rows;
  const PendingPollsSummary({
    required this.totalUnvoted,
    required this.totalOpen,
    required this.rows,
  });
  static const empty = PendingPollsSummary(
    totalUnvoted: 0,
    totalOpen: 0,
    rows: [],
  );
}

/// App-wide aggregate for the top-bar notification bell. Returns one row
/// per trip that has at least one open poll, plus totals. Watches the
/// per-trip `pollBadgeCountsProvider` so vote/poll changes reflow.
final pendingPollsSummaryProvider = Provider<PendingPollsSummary>((ref) {
  final tripsAsync = ref.watch(userTripsProvider);
  return tripsAsync.maybeWhen(
    data: (trips) {
      final rows = <PendingPollsTripRow>[];
      var totalUnvoted = 0;
      var totalOpen = 0;
      for (final t in trips) {
        final counts = ref.watch(pollBadgeCountsProvider(t.trip.id));
        if (kDebugMode) {
          debugPrint(
              '🗳️ [summary] trip ${t.trip.name} (${t.trip.id.substring(0, 8)}): '
              'open=${counts.open} unvoted=${counts.unvoted}');
        }
        if (counts.open == 0) continue;
        rows.add(PendingPollsTripRow(
          tripId: t.trip.id,
          tripName: t.trip.name,
          unvoted: counts.unvoted,
          open: counts.open,
        ));
        totalUnvoted += counts.unvoted;
        totalOpen += counts.open;
      }
      // Trips with unvoted polls bubble to the top, otherwise alpha.
      rows.sort((a, b) {
        if (a.unvoted != b.unvoted) return b.unvoted.compareTo(a.unvoted);
        return a.tripName.compareTo(b.tripName);
      });
      if (kDebugMode) {
        debugPrint('🗳️ [summary] totalOpen=$totalOpen '
            'totalUnvoted=$totalUnvoted rows=${rows.length}');
      }
      return PendingPollsSummary(
        totalUnvoted: totalUnvoted,
        totalOpen: totalOpen,
        rows: rows,
      );
    },
    orElse: () => PendingPollsSummary.empty,
  );
});

// ============================================================================
// CONTROLLER
// ============================================================================

class PollState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PollState({this.isLoading = false, this.error, this.successMessage});

  PollState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return PollState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class PollController extends Notifier<PollState> {
  late final PollRepository _repo;

  @override
  PollState build() {
    _repo = ref.read(pollRepositoryProvider);
    return const PollState();
  }

  Future<String?> createPoll({
    required String tripId,
    required String question,
    required List<String> optionLabels,
    required int defaultIndex,
    required DateTime deadline,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final id = await _repo.createPoll(
        tripId: tripId,
        question: question,
        optionLabels: optionLabels,
        defaultIndex: defaultIndex,
        deadline: deadline,
      );
      state = state.copyWith(isLoading: false, successMessage: 'Poll created');
      return id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> castVote({required String pollId, required String optionId}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _repo.castVote(pollId: pollId, optionId: optionId);
      state = state.copyWith(isLoading: false, successMessage: 'Vote recorded');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> closePoll(String pollId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _repo.closePoll(pollId);
      state = state.copyWith(isLoading: false, successMessage: 'Poll closed');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deletePoll(String pollId) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _repo.deletePoll(pollId);
      state = state.copyWith(isLoading: false, successMessage: 'Poll deleted');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessage() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final pollControllerProvider =
    NotifierProvider<PollController, PollState>(PollController.new);
