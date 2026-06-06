/// Tally row for one option.
///
/// `explicitVotes` is the count of votes actually cast for this option.
/// `effectiveVotes` is what counts for the final result — for the default
/// option, it includes every trip member who hasn't voted yet.
class PollResultRowEntity {
  final String optionId;
  final String label;
  final int position;
  final bool isDefault;
  final int explicitVotes;
  final int effectiveVotes;

  const PollResultRowEntity({
    required this.optionId,
    required this.label,
    required this.position,
    required this.isDefault,
    required this.explicitVotes,
    required this.effectiveVotes,
  });
}

/// Full tally for a poll.
///
/// `isFinal` is true once the poll is closed or its deadline has passed.
/// Until then, the default-fill numbers are projections.
class PollResultEntity {
  final String pollId;
  final List<PollResultRowEntity> rows;
  final bool isFinal;
  final int totalMembers;
  final int totalVoted;

  const PollResultEntity({
    required this.pollId,
    required this.rows,
    required this.isFinal,
    required this.totalMembers,
    required this.totalVoted,
  });

  int get totalNonVoters => (totalMembers - totalVoted).clamp(0, totalMembers);

  /// The winning row by `effectiveVotes`. Ties go to lower `position`.
  PollResultRowEntity? get winner {
    if (rows.isEmpty) return null;
    final sorted = [...rows]
      ..sort((a, b) {
        final byVotes = b.effectiveVotes.compareTo(a.effectiveVotes);
        if (byVotes != 0) return byVotes;
        return a.position.compareTo(b.position);
      });
    return sorted.first;
  }
}
