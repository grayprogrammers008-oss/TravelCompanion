import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/poll_model.dart';

/// Talks to Supabase for everything poll-related.
///
/// Realtime is callback-driven so we hold the [SupabaseClient] directly for
/// channel subscriptions and route the actual reads back through this same
/// class so refetch logic stays in one place.
class PollRemoteDataSource {
  PollRemoteDataSource(this._client);

  final SupabaseClient _client;

  // ---- Reads -------------------------------------------------------------

  Future<List<PollModel>> getTripPolls(String tripId) async {
    if (kDebugMode) debugPrint('🗳️ [polls] getTripPolls($tripId) -> calling rpc');
    try {
      final rows = await _client.rpc(
        'get_trip_polls',
        params: {'p_trip_id': tripId},
      );
      if (kDebugMode) {
        debugPrint('🗳️ [polls] rpc returned: ${rows.runtimeType} '
            '(${rows is List ? rows.length : "not-a-list"} rows)');
      }
      final asMaps = _asListOfMaps(rows);
      if (kDebugMode) debugPrint('🗳️ [polls] after _asListOfMaps: ${asMaps.length} rows');
      final parsed = asMaps.map(PollModel.fromJson).toList();
      if (kDebugMode) debugPrint('🗳️ [polls] parsed ${parsed.length} polls');
      return parsed;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ [polls] getTripPolls failed: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<PollModel?> getPoll(String pollId) async {
    if (kDebugMode) debugPrint('🗳️ [polls] getPoll($pollId) starting');
    final row = await _client
        .from('trip_polls')
        .select()
        .eq('id', pollId)
        .maybeSingle();
    if (kDebugMode) debugPrint('🗳️ [polls] getPoll base row: ${row == null ? "null" : "ok"}');
    if (row == null) return null;

    final voteRow = await _client
        .from('trip_poll_votes')
        .select('option_id')
        .eq('poll_id', pollId)
        .eq('user_id', _client.auth.currentUser?.id ?? '')
        .maybeSingle();

    final voteCountRows = await _client
        .from('trip_poll_votes')
        .select('id')
        .eq('poll_id', pollId);
    if (kDebugMode) debugPrint('🗳️ [polls] getPoll vote count rows fetched');

    final optionRows = await _client
        .from('trip_poll_options')
        .select('id, label')
        .eq('poll_id', pollId);
    if (kDebugMode) debugPrint('🗳️ [polls] getPoll option rows fetched');

    String? defaultLabel;
    if (row['default_option_id'] != null) {
      final defaultId = row['default_option_id'] as String;
      for (final o in (optionRows as List)) {
        if (o['id'] == defaultId) {
          defaultLabel = o['label'] as String?;
          break;
        }
      }
    }

    return PollModel.fromJson({
      ...row,
      'creator_name': null,
      'default_option_label': defaultLabel,
      'option_count': (optionRows as List).length,
      'vote_count': (voteCountRows as List).length,
      'current_user_voted': voteRow != null,
      'current_user_option': voteRow?['option_id'],
    });
  }

  Future<List<PollOptionModel>> getPollOptions(String pollId) async {
    if (kDebugMode) debugPrint('🗳️ [polls] getPollOptions($pollId) starting');
    try {
      final rows = await _client
          .from('trip_poll_options')
          .select()
          .eq('poll_id', pollId)
          .order('position');
      if (kDebugMode) {
        debugPrint('🗳️ [polls] getPollOptions returned ${(rows as List).length} rows');
      }
      return _asListOfMaps(rows).map(PollOptionModel.fromJson).toList();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ [polls] getPollOptions failed: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPollResults(String pollId) async {
    final rows = await _client.rpc(
      'get_poll_results',
      params: {'p_poll_id': pollId},
    );
    return _asListOfMaps(rows);
  }

  // ---- Writes ------------------------------------------------------------

  Future<String> createPoll({
    required String tripId,
    required String question,
    required List<String> optionLabels,
    required int defaultIndex,
    required DateTime deadline,
  }) async {
    final result = await _client.rpc('create_trip_poll', params: {
      'p_trip_id': tripId,
      'p_question': question.trim(),
      'p_options': optionLabels.map((l) => {'label': l.trim()}).toList(),
      'p_default_index': defaultIndex,
      'p_deadline': deadline.toUtc().toIso8601String(),
    });
    if (result is String) return result;
    if (result is Map && result['id'] is String) return result['id'] as String;
    throw Exception('Unexpected create_trip_poll response: $result');
  }

  Future<void> castVote({
    required String pollId,
    required String optionId,
  }) async {
    await _client.rpc('cast_poll_vote', params: {
      'p_poll_id': pollId,
      'p_option_id': optionId,
    });
  }

  Future<void> closePoll(String pollId) async {
    await _client.rpc('close_trip_poll', params: {'p_poll_id': pollId});
  }

  /// Delete a poll. The DELETE policy restricts this to the poll creator,
  /// so a non-organizer call will just affect zero rows.
  Future<void> deletePoll(String pollId) async {
    await _client.from('trip_polls').delete().eq('id', pollId);
  }

  // ---- Realtime ----------------------------------------------------------

  Stream<List<PollModel>> watchTripPolls(String tripId) {
    if (kDebugMode) debugPrint('🗳️ [polls] watchTripPolls($tripId) starting');
    final controller = StreamController<List<PollModel>>.broadcast();

    Future<void> refetch(String reason) async {
      if (kDebugMode) debugPrint('🗳️ [polls] refetch($reason) starting');
      if (controller.isClosed) return;
      try {
        final polls = await getTripPolls(tripId);
        if (!controller.isClosed) {
          controller.add(polls);
          if (kDebugMode) {
            debugPrint('🗳️ [polls] emitted ${polls.length} polls to stream');
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [polls] refetch ($reason) failed: $e');
        if (!controller.isClosed) controller.addError(e);
      }
    }

    final pollsChannel = _client
        .channel('polls:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_polls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) => refetch('poll ${payload.eventType}'),
        );

    // Vote changes can't be filtered by trip_id at the DB level (votes only
    // carry poll_id), so we listen broadly and let refetch decide.
    final votesChannel = _client
        .channel('poll_votes:$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_poll_votes',
          callback: (payload) => refetch('vote ${payload.eventType}'),
        );

    pollsChannel.subscribe((status, error) {
      if (kDebugMode) {
        debugPrint('🗳️ [polls] polls channel status=$status err=$error');
      }
    });
    votesChannel.subscribe((status, error) {
      if (kDebugMode) {
        debugPrint('🗳️ [polls] votes channel status=$status err=$error');
      }
    });

    refetch('initial');

    controller.onCancel = () {
      if (kDebugMode) debugPrint('🗳️ [polls] stream cancelled, unsubscribing');
      pollsChannel.unsubscribe();
      votesChannel.unsubscribe();
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> watchPollResults(String pollId) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> refetch(String reason) async {
      if (controller.isClosed) return;
      try {
        final results = await getPollResults(pollId);
        if (!controller.isClosed) controller.add(results);
      } catch (e) {
        if (kDebugMode) debugPrint('❌ Results refetch ($reason) failed: $e');
        if (!controller.isClosed) controller.addError(e);
      }
    }

    final votesChannel = _client
        .channel('poll_results:$pollId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_poll_votes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'poll_id',
            value: pollId,
          ),
          callback: (payload) => refetch('vote ${payload.eventType}'),
        );

    final pollChannel = _client
        .channel('poll_status:$pollId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trip_polls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: pollId,
          ),
          callback: (payload) => refetch('poll updated'),
        );

    votesChannel.subscribe();
    pollChannel.subscribe();

    refetch('initial');

    controller.onCancel = () {
      votesChannel.unsubscribe();
      pollChannel.unsubscribe();
    };

    return controller.stream;
  }

  // ---- Helpers -----------------------------------------------------------

  List<Map<String, dynamic>> _asListOfMaps(dynamic rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return const [];
  }
}
