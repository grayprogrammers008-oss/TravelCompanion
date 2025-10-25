import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

/// Test helper utilities to reduce boilerplate in widget tests
class TestHelpers {
  /// Creates a ProviderScope with common provider overrides
  static Widget createTestApp({
    required Widget child,
    UserEntity? mockUser,
    List<TripWithMembers>? mockTrips,
  }) {
    final user = mockUser ??
        UserEntity(
          id: 'test-user-1',
          email: 'test@example.com',
          fullName: 'Test User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final trips = mockTrips ?? <TripWithMembers>[];

    return ProviderScope(
      overrides: [
        // Auth providers
        currentUserProvider.overrideWith((ref) async => user),
        authStateProvider.overrideWith((ref) => Stream.value(user.id)),

        // Trip providers
        userTripsProvider.overrideWith((ref) => Stream.value(trips)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Creates a test user for use in tests
  static UserEntity createTestUser({
    String? id,
    String? email,
    String? fullName,
  }) {
    return UserEntity(
      id: id ?? 'test-user-1',
      email: email ?? 'test@example.com',
      fullName: fullName ?? 'Test User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Pumps widget and waits for all animations/async operations
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(
      const Duration(seconds: 10),
      EnginePhase.sendSemanticsUpdate,
      const Duration(milliseconds: 100),
    );
  }
}
