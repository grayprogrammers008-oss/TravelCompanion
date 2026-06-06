import '../../domain/entities/poll_entity.dart';
import '../../domain/entities/poll_option_entity.dart';
import '../../domain/entities/poll_result_entity.dart';
import '../../domain/repositories/poll_repository.dart';
import '../datasources/poll_remote_datasource.dart';
import '../models/poll_model.dart';

class PollRepositoryImpl implements PollRepository {
  PollRepositoryImpl(this._remote);

  final PollRemoteDataSource _remote;

  @override
  Future<String> createPoll({
    required String tripId,
    required String question,
    required List<String> optionLabels,
    required int defaultIndex,
    required DateTime deadline,
  }) {
    return _remote.createPoll(
      tripId: tripId,
      question: question,
      optionLabels: optionLabels,
      defaultIndex: defaultIndex,
      deadline: deadline,
    );
  }

  @override
  Future<void> castVote({required String pollId, required String optionId}) {
    return _remote.castVote(pollId: pollId, optionId: optionId);
  }

  @override
  Future<void> closePoll(String pollId) => _remote.closePoll(pollId);

  @override
  Future<void> deletePoll(String pollId) => _remote.deletePoll(pollId);

  @override
  Future<List<PollEntity>> getTripPolls(String tripId) async {
    final models = await _remote.getTripPolls(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PollEntity?> getPoll(String pollId) async {
    final model = await _remote.getPoll(pollId);
    return model?.toEntity();
  }

  @override
  Future<List<PollOptionEntity>> getPollOptions(String pollId) async {
    final models = await _remote.getPollOptions(pollId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PollResultEntity> getPollResults(String pollId) async {
    final rows = await _remote.getPollResults(pollId);
    return buildPollResultEntity(pollId, rows);
  }

  @override
  Stream<List<PollEntity>> watchTripPolls(String tripId) {
    return _remote
        .watchTripPolls(tripId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<PollResultEntity> watchPollResults(String pollId) {
    return _remote
        .watchPollResults(pollId)
        .map((rows) => buildPollResultEntity(pollId, rows));
  }
}
