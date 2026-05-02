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
    // Guard against state updates after the provider has been disposed
    // (e.g. user navigates away while the async write is still in flight).
    if (!ref.mounted) return;
    state = const AsyncValue.data(true);
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    // Guard against state updates after the provider has been disposed.
    if (!ref.mounted) return;
    state = const AsyncValue.data(false);
  }
}
