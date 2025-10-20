import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_crew/features/onboarding/presentation/providers/onboarding_provider.dart';

void main() {
  group('OnboardingStateProvider', () {
    late ProviderContainer container;

    setUp(() {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should return false when onboarding not completed', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act
        final state = await container.read(onboardingStateProvider.future);

        // Assert
        expect(state, false);
      });

      test('should return true when onboarding is completed', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });

        // Rebuild container to pick up new initial values
        container.dispose();
        container = ProviderContainer();

        // Act
        final state = await container.read(onboardingStateProvider.future);

        // Assert
        expect(state, true);
      });

      test('should return false when onboarding explicitly set to false',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': false,
        });

        container.dispose();
        container = ProviderContainer();

        // Act
        final state = await container.read(onboardingStateProvider.future);

        // Assert
        expect(state, false);
      });
    });

    group('completeOnboarding', () {
      test('should set onboarding as completed in SharedPreferences',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Wait for initial build
        await container.read(onboardingStateProvider.future);

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      test('should update state to true after completing', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Wait for initial build
        final initialState = await container.read(onboardingStateProvider.future);
        expect(initialState, false);

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert
        final newState = await container.read(onboardingStateProvider.future);
        expect(newState, true);
      });

      test('should remain true if called multiple times', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert
        final state = await container.read(onboardingStateProvider.future);
        expect(state, true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      test('should notify listeners when state changes', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        final states = <bool>[];
        container.listen(
          onboardingStateProvider,
          (previous, next) {
            next.whenData((value) => states.add(value));
          },
        );

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Wait for state propagation
        await Future.delayed(Duration.zero);

        // Assert
        expect(states, contains(true));
      });
    });

    group('resetOnboarding', () {
      test('should remove onboarding key from SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .resetOnboarding();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('onboarding_completed'), false);
      });

      test('should update state to false after reset', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        final initialState = await container.read(onboardingStateProvider.future);
        expect(initialState, true);

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .resetOnboarding();

        // Assert
        final newState = await container.read(onboardingStateProvider.future);
        expect(newState, false);
      });

      test('should handle reset when already false', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act & Assert - Should not throw
        await container
            .read(onboardingStateProvider.notifier)
            .resetOnboarding();

        final state = await container.read(onboardingStateProvider.future);
        expect(state, false);
      });

      test('should allow completing after reset', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .resetOnboarding();

        final stateAfterReset =
            await container.read(onboardingStateProvider.future);
        expect(stateAfterReset, false);

        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert
        final finalState = await container.read(onboardingStateProvider.future);
        expect(finalState, true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('onboarding_completed'), true);
      });

      test('should notify listeners when reset', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        final states = <bool>[];
        container.listen(
          onboardingStateProvider,
          (previous, next) {
            next.whenData((value) => states.add(value));
          },
        );

        // Act
        await container
            .read(onboardingStateProvider.notifier)
            .resetOnboarding();

        // Wait for state propagation
        await Future.delayed(Duration.zero);

        // Assert
        expect(states, contains(false));
      });
    });

    group('AsyncValue States', () {
      test('should start with loading state', () {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Act
        final asyncValue = container.read(onboardingStateProvider);

        // Assert
        expect(asyncValue.isLoading, true);
      });

      test('should transition to data state after build completes', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Act
        await container.read(onboardingStateProvider.future);
        final asyncValue = container.read(onboardingStateProvider);

        // Assert
        expect(asyncValue.hasValue, true);
        expect(asyncValue.isLoading, false);
      });

      test('should not have error in normal operation', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Act
        await container.read(onboardingStateProvider.future);
        final asyncValue = container.read(onboardingStateProvider);

        // Assert
        expect(asyncValue.hasError, false);
      });
    });

    group('State Persistence', () {
      test('should persist across provider rebuilds', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act - Complete onboarding
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Dispose and create new container (simulating app restart)
        container.dispose();
        container = ProviderContainer();

        // Assert - State should persist
        final state = await container.read(onboardingStateProvider.future);
        expect(state, true);
      });

      test('should handle multiple containers with same SharedPreferences',
          () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        await container1.read(onboardingStateProvider.future);
        await container2.read(onboardingStateProvider.future);

        // Act - Complete in first container
        await container1
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert - Should be reflected in new container
        container1.dispose();
        container2.dispose();

        final container3 = ProviderContainer();
        final state = await container3.read(onboardingStateProvider.future);
        expect(state, true);

        container3.dispose();
      });
    });

    group('Concurrent Operations', () {
      test('should handle rapid complete/reset cycles', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act - Rapid operations
        for (int i = 0; i < 5; i++) {
          await container
              .read(onboardingStateProvider.notifier)
              .completeOnboarding();
          await container
              .read(onboardingStateProvider.notifier)
              .resetOnboarding();
        }

        // Final complete
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert
        final state = await container.read(onboardingStateProvider.future);
        expect(state, true);
      });

      test('should handle multiple simultaneous reads', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        // Act - Multiple simultaneous reads
        final futures = List.generate(
          10,
          (_) => container.read(onboardingStateProvider.future),
        );

        final results = await Future.wait(futures);

        // Assert - All should return same value
        expect(results.every((result) => result == true), true);
      });
    });

    group('Edge Cases', () {
      test('should handle missing key in SharedPreferences', () async {
        // Arrange - Empty SharedPreferences (simulates missing key)
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Act
        final state = await container.read(onboardingStateProvider.future);

        // Assert - Should default to false
        expect(state, false);
      });

      test('should handle provider disposal during async operation', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act - Start async operation and dispose immediately
        final future = container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        container.dispose();

        // Assert - Should complete without error
        await expectLater(future, completes);
      });
    });

    group('Real-world Scenarios', () {
      test('First-time user flow', () async {
        // Arrange - Fresh install
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        // Act & Assert
        // 1. User opens app
        final initialState =
            await container.read(onboardingStateProvider.future);
        expect(initialState, false); // Should show onboarding

        // 2. User completes onboarding
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        final completedState =
            await container.read(onboardingStateProvider.future);
        expect(completedState, true); // Onboarding marked complete

        // 3. User closes and reopens app
        container.dispose();
        container = ProviderContainer();

        final reopenState = await container.read(onboardingStateProvider.future);
        expect(reopenState, true); // Should not show onboarding again
      });

      test('Returning user flow', () async {
        // Arrange - User who already completed onboarding
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        // Act & Assert
        // User opens app
        final state = await container.read(onboardingStateProvider.future);
        expect(state, true); // Should skip onboarding
      });

      test('Testing/development flow with reset', () async {
        // Arrange - Developer testing onboarding
        SharedPreferences.setMockInitialValues({
          'onboarding_completed': true,
        });
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act & Assert
        // 1. Developer resets onboarding
        await container
            .read(onboardingStateProvider.notifier)
            .resetOnboarding();

        final afterReset = await container.read(onboardingStateProvider.future);
        expect(afterReset, false); // Can test onboarding again

        // 2. Complete onboarding
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        final afterComplete =
            await container.read(onboardingStateProvider.future);
        expect(afterComplete, true);
      });

      test('Skip onboarding scenario', () async {
        // Arrange - User taps Skip button
        SharedPreferences.setMockInitialValues({});
        container.dispose();
        container = ProviderContainer();

        await container.read(onboardingStateProvider.future);

        // Act - Skip calls completeOnboarding immediately
        await container
            .read(onboardingStateProvider.notifier)
            .completeOnboarding();

        // Assert - User goes straight to app
        final state = await container.read(onboardingStateProvider.future);
        expect(state, true);
      });
    });
  });
}
