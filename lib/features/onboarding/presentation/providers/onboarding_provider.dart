import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

/// Provider for managing onboarding state
@riverpod
class OnboardingState extends _$OnboardingState {
  static const String _key = 'onboarding_completed';

  @override
  Future<bool> build() async {
    return await _isOnboardingCompleted();
  }

  /// Check if onboarding has been completed
  Future<bool> _isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(true);
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncValue.data(false);
  }
}
