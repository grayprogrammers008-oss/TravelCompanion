/// Status of a trip poll.
enum PollStatus { open, closed }

/// A single trip poll.
///
/// A poll's *effective* status is `closed` once its deadline has passed,
/// even if `status` is still `open` server-side — see [isEffectivelyClosed].
class PollEntity {
  final String id;
  final String tripId;
  final String createdBy;
  final String? creatorName;
  final String question;
  final String? defaultOptionId;
  final String? defaultOptionLabel;
  final DateTime deadline;
  final PollStatus status;
  final DateTime? closedAt;
  final DateTime createdAt;

  // Summary fields populated by `get_trip_polls`.
  final int optionCount;
  final int voteCount;
  final bool currentUserVoted;
  final String? currentUserOptionId;

  const PollEntity({
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

  bool get isClosed => status == PollStatus.closed;
  bool get isDeadlinePassed => DateTime.now().isAfter(deadline);
  bool get isEffectivelyClosed => isClosed || isDeadlinePassed;
  bool get isOpenForVoting => !isEffectivelyClosed;

  Duration get timeUntilDeadline => deadline.difference(DateTime.now());

  String get timeRemainingLabel {
    if (isClosed) return 'Closed';
    final d = timeUntilDeadline;
    if (d.isNegative) return 'Deadline passed';
    if (d.inDays >= 1) return '${d.inDays}d left';
    if (d.inHours >= 1) return '${d.inHours}h left';
    if (d.inMinutes >= 1) return '${d.inMinutes}m left';
    return 'Closing soon';
  }
}
