import '../entities/poll_entity.dart';
import '../entities/poll_option_entity.dart';
import '../entities/poll_result_entity.dart';

/// Repository for trip-poll operations.
abstract class PollRepository {
  /// Create a poll. Only the trip organizer is allowed (enforced by RLS/RPC).
  ///
  /// [optionLabels] is the ordered list of choices; [defaultIndex] is the
  /// 0-based index that becomes the poll's default option.
  Future<String> createPoll({
    required String tripId,
    required String question,
    required List<String> optionLabels,
    required int defaultIndex,
    required DateTime deadline,
  });

  /// Cast or change the current user's vote. Repeated calls overwrite.
  Future<void> castVote({
    required String pollId,
    required String optionId,
  });

  /// Organizer-only: flip the poll to closed early.
  Future<void> closePoll(String pollId);

  /// Organizer-only: permanently delete a poll and all its options/votes.
  Future<void> deletePoll(String pollId);

  /// List polls for a trip, ordered open-first then newest-first.
  Future<List<PollEntity>> getTripPolls(String tripId);

  /// Single poll with summary fields populated (vote-state for current user).
  Future<PollEntity?> getPoll(String pollId);

  /// Options for a poll, ordered by `position`.
  Future<List<PollOptionEntity>> getPollOptions(String pollId);

  /// Live tally — non-voters folded into the default option.
  Future<PollResultEntity> getPollResults(String pollId);

  /// Realtime stream of polls for a trip. Refetches on table changes.
  Stream<List<PollEntity>> watchTripPolls(String tripId);

  /// Realtime stream of a single poll's results.
  Stream<PollResultEntity> watchPollResults(String pollId);
}
