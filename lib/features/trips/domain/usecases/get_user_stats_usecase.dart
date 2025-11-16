import '../repositories/trip_repository.dart';

/// Statistics about user's travel activity
class UserTravelStats {
  final int totalTrips;
  final int totalExpenses;
  final double totalSpent;
  final int uniqueCrewMembers;

  const UserTravelStats({
    required this.totalTrips,
    required this.totalExpenses,
    required this.totalSpent,
    required this.uniqueCrewMembers,
  });

  factory UserTravelStats.empty() {
    return const UserTravelStats(
      totalTrips: 0,
      totalExpenses: 0,
      totalSpent: 0.0,
      uniqueCrewMembers: 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserTravelStats &&
        other.totalTrips == totalTrips &&
        other.totalExpenses == totalExpenses &&
        other.totalSpent == totalSpent &&
        other.uniqueCrewMembers == uniqueCrewMembers;
  }

  @override
  int get hashCode =>
      totalTrips.hashCode ^
      totalExpenses.hashCode ^
      totalSpent.hashCode ^
      uniqueCrewMembers.hashCode;
}

/// Use case for getting user's travel statistics
class GetUserStatsUseCase {
  final TripRepository repository;

  GetUserStatsUseCase(this.repository);

  /// Get user's travel statistics
  Future<UserTravelStats> call() async {
    try {
      final stats = await repository.getUserStats();
      return stats;
    } catch (e) {
      return UserTravelStats.empty();
    }
  }

  /// Watch user's travel statistics with real-time updates
  Stream<UserTravelStats> watch() {
    return repository.watchUserStats();
  }
}
