/// A single choice within a poll.
class PollOptionEntity {
  final String id;
  final String pollId;
  final String label;
  final int position;

  const PollOptionEntity({
    required this.id,
    required this.pollId,
    required this.label,
    required this.position,
  });
}
