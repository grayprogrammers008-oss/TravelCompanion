import '../../domain/entities/poll_entity.dart';
import '../../domain/entities/poll_option_entity.dart';
import '../../domain/entities/poll_result_entity.dart';

class PollModel {
  final String id;
  final String tripId;
  final String createdBy;
  final String? creatorName;
  final String question;
  final String? defaultOptionId;
  final String? defaultOptionLabel;
  final DateTime deadline;
  final String status;
  final DateTime? closedAt;
  final DateTime createdAt;
  final int optionCount;
  final int voteCount;
  final bool currentUserVoted;
  final String? currentUserOptionId;

  const PollModel({
    required this.id,
    required this.tripId,
    required this.createdBy,
    this.creatorName,
    required this.question,
    this.defaultOptionId,
    this.defaultOptionLabel,
    required this.deadline,
    required this.status,
    this.closedAt,
    required this.createdAt,
    this.optionCount = 0,
    this.voteCount = 0,
    this.currentUserVoted = false,
    this.currentUserOptionId,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      createdBy: json['created_by'] as String,
      creatorName: json['creator_name'] as String?,
      question: json['question'] as String,
      defaultOptionId: json['default_option_id'] as String?,
      defaultOptionLabel: json['default_option_label'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      status: json['status'] as String,
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      optionCount: (json['option_count'] as num?)?.toInt() ?? 0,
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      currentUserVoted: json['current_user_voted'] as bool? ?? false,
      currentUserOptionId: json['current_user_option'] as String?,
    );
  }

  PollEntity toEntity() {
    return PollEntity(
      id: id,
      tripId: tripId,
      createdBy: createdBy,
      creatorName: creatorName,
      question: question,
      defaultOptionId: defaultOptionId,
      defaultOptionLabel: defaultOptionLabel,
      deadline: deadline,
      status: status == 'closed' ? PollStatus.closed : PollStatus.open,
      closedAt: closedAt,
      createdAt: createdAt,
      optionCount: optionCount,
      voteCount: voteCount,
      currentUserVoted: currentUserVoted,
      currentUserOptionId: currentUserOptionId,
    );
  }
}

class PollOptionModel {
  final String id;
  final String pollId;
  final String label;
  final int position;

  const PollOptionModel({
    required this.id,
    required this.pollId,
    required this.label,
    required this.position,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      label: json['label'] as String,
      position: (json['position'] as num).toInt(),
    );
  }

  PollOptionEntity toEntity() => PollOptionEntity(
        id: id,
        pollId: pollId,
        label: label,
        position: position,
      );
}

class PollResultRowModel {
  final String optionId;
  final String label;
  final int position;
  final bool isDefault;
  final int explicitVotes;
  final int effectiveVotes;
  final bool isFinal;
  final int totalMembers;
  final int totalVoted;

  const PollResultRowModel({
    required this.optionId,
    required this.label,
    required this.position,
    required this.isDefault,
    required this.explicitVotes,
    required this.effectiveVotes,
    required this.isFinal,
    required this.totalMembers,
    required this.totalVoted,
  });

  factory PollResultRowModel.fromJson(Map<String, dynamic> json) {
    // `position` is exposed as `opt_position` by the RPC because Postgres
    // rejects `position` as a column name in a RETURNS TABLE list.
    return PollResultRowModel(
      optionId: json['option_id'] as String,
      label: json['label'] as String,
      position: (json['opt_position'] as num?)?.toInt() ??
          (json['position'] as num?)?.toInt() ??
          0,
      isDefault: json['is_default'] as bool? ?? false,
      explicitVotes: (json['explicit_votes'] as num?)?.toInt() ?? 0,
      effectiveVotes: (json['effective_votes'] as num?)?.toInt() ?? 0,
      isFinal: json['is_final'] as bool? ?? false,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      totalVoted: (json['total_voted'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Builds the full result entity from the raw RPC rows.
PollResultEntity buildPollResultEntity(
  String pollId,
  List<Map<String, dynamic>> rawRows,
) {
  if (rawRows.isEmpty) {
    return PollResultEntity(
      pollId: pollId,
      rows: const [],
      isFinal: false,
      totalMembers: 0,
      totalVoted: 0,
    );
  }
  final parsed = rawRows.map(PollResultRowModel.fromJson).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  final head = parsed.first;
  return PollResultEntity(
    pollId: pollId,
    rows: parsed
        .map((r) => PollResultRowEntity(
              optionId: r.optionId,
              label: r.label,
              position: r.position,
              isDefault: r.isDefault,
              explicitVotes: r.explicitVotes,
              effectiveVotes: r.effectiveVotes,
            ))
        .toList(),
    isFinal: head.isFinal,
    totalMembers: head.totalMembers,
    totalVoted: head.totalVoted,
  );
}
