import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/templates/domain/entities/ai_usage.dart';

UserAiUsage _usage({
  String id = 'u-1',
  String userId = 'user-1',
  int aiGenerationsUsed = 0,
  int aiGenerationsLimit = 5,
  bool isPremium = false,
  DateTime? premiumExpiresAt,
  DateTime? premiumStartedAt,
  String? premiumPlan,
  int lifetimeGenerations = 0,
}) {
  final now = DateTime.parse('2026-01-01T00:00:00Z');
  return UserAiUsage(
    id: id,
    userId: userId,
    aiGenerationsUsed: aiGenerationsUsed,
    aiGenerationsLimit: aiGenerationsLimit,
    isPremium: isPremium,
    premiumPlan: premiumPlan,
    premiumStartedAt: premiumStartedAt,
    premiumExpiresAt: premiumExpiresAt,
    lifetimeGenerations: lifetimeGenerations,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('UserAiUsage.canGenerate', () {
    test('returns true when usage below limit (free user)', () {
      expect(_usage(aiGenerationsUsed: 2, aiGenerationsLimit: 5).canGenerate,
          isTrue);
    });

    test('returns false when usage equals limit', () {
      expect(_usage(aiGenerationsUsed: 5, aiGenerationsLimit: 5).canGenerate,
          isFalse);
    });

    test('returns false when usage exceeds limit', () {
      expect(_usage(aiGenerationsUsed: 6, aiGenerationsLimit: 5).canGenerate,
          isFalse);
    });

    test('returns true when premium and expiry is in future, even at limit', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(
          _usage(
            isPremium: true,
            premiumExpiresAt: future,
            aiGenerationsUsed: 999,
            aiGenerationsLimit: 5,
          ).canGenerate,
          isTrue);
    });

    test('returns false when premium but expiry is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(
          _usage(
            isPremium: true,
            premiumExpiresAt: past,
            aiGenerationsUsed: 5,
            aiGenerationsLimit: 5,
          ).canGenerate,
          isFalse);
    });

    test('returns false when premium=true but premiumExpiresAt is null and at limit',
        () {
      expect(
          _usage(
            isPremium: true,
            premiumExpiresAt: null,
            aiGenerationsUsed: 5,
            aiGenerationsLimit: 5,
          ).canGenerate,
          isFalse);
    });
  });

  group('UserAiUsage.remainingGenerations', () {
    test('returns -1 (unlimited) for active premium', () {
      final future = DateTime.now().add(const Duration(days: 5));
      expect(
          _usage(isPremium: true, premiumExpiresAt: future)
              .remainingGenerations,
          -1);
    });

    test('returns difference for free users', () {
      expect(_usage(aiGenerationsUsed: 2, aiGenerationsLimit: 5)
          .remainingGenerations, 3);
    });

    test('clamps to zero when used exceeds limit', () {
      expect(_usage(aiGenerationsUsed: 10, aiGenerationsLimit: 5)
          .remainingGenerations, 0);
    });

    test('returns 5 for fresh free user', () {
      expect(_usage().remainingGenerations, 5);
    });
  });

  group('UserAiUsage.isPremiumActive', () {
    test('false when isPremium is false', () {
      expect(_usage(isPremium: false).isPremiumActive, isFalse);
    });

    test('false when isPremium=true but expiry null', () {
      expect(
          _usage(isPremium: true, premiumExpiresAt: null).isPremiumActive,
          isFalse);
    });

    test('false when expiry in past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(
          _usage(isPremium: true, premiumExpiresAt: past).isPremiumActive,
          isFalse);
    });

    test('true when expiry in future', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(
          _usage(isPremium: true, premiumExpiresAt: future).isPremiumActive,
          isTrue);
    });
  });

  group('UserAiUsage.daysUntilExpiry', () {
    test('null when not premium', () {
      expect(_usage().daysUntilExpiry, isNull);
    });

    test('returns positive int when premium expiry in future', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final d = _usage(isPremium: true, premiumExpiresAt: future)
          .daysUntilExpiry;
      // Could be 9 or 10 depending on rounding; allow a small range.
      expect(d, isNotNull);
      expect(d! >= 9 && d <= 10, isTrue);
    });

    test('null when premium expiry in past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(_usage(isPremium: true, premiumExpiresAt: past).daysUntilExpiry,
          isNull);
    });
  });

  group('UserAiUsage.fromJson / toJson', () {
    test('fromJson parses required and optional fields', () {
      final json = {
        'id': 'u',
        'user_id': 'me',
        'ai_generations_used': 3,
        'ai_generations_limit': 10,
        'is_premium': true,
        'premium_plan': 'monthly',
        'premium_started_at': '2026-01-01T00:00:00Z',
        'premium_expires_at': '2026-02-01T00:00:00Z',
        'lifetime_generations': 25,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
      };
      final u = UserAiUsage.fromJson(json);
      expect(u.id, 'u');
      expect(u.userId, 'me');
      expect(u.aiGenerationsUsed, 3);
      expect(u.aiGenerationsLimit, 10);
      expect(u.isPremium, isTrue);
      expect(u.premiumPlan, 'monthly');
      expect(u.premiumStartedAt, isNotNull);
      expect(u.premiumExpiresAt, isNotNull);
      expect(u.lifetimeGenerations, 25);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {
        'id': 'u',
        'user_id': 'me',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final u = UserAiUsage.fromJson(json);
      expect(u.aiGenerationsUsed, 0);
      expect(u.aiGenerationsLimit, 5);
      expect(u.isPremium, isFalse);
      expect(u.lifetimeGenerations, 0);
      expect(u.premiumPlan, isNull);
      expect(u.premiumStartedAt, isNull);
      expect(u.premiumExpiresAt, isNull);
    });

    test('toJson includes all expected keys', () {
      final u = _usage(
        isPremium: true,
        premiumPlan: 'annual',
        premiumStartedAt: DateTime.parse('2026-01-01T00:00:00Z'),
        premiumExpiresAt: DateTime.parse('2027-01-01T00:00:00Z'),
        aiGenerationsUsed: 4,
        aiGenerationsLimit: 5,
        lifetimeGenerations: 17,
      );
      final j = u.toJson();
      expect(j['id'], 'u-1');
      expect(j['user_id'], 'user-1');
      expect(j['ai_generations_used'], 4);
      expect(j['ai_generations_limit'], 5);
      expect(j['is_premium'], isTrue);
      expect(j['premium_plan'], 'annual');
      expect(j['premium_started_at'], isA<String>());
      expect(j['premium_expires_at'], isA<String>());
      expect(j['lifetime_generations'], 17);
      expect(j['created_at'], isA<String>());
      expect(j['updated_at'], isA<String>());
    });

    test('toJson emits null for absent date/plan fields', () {
      final j = _usage().toJson();
      expect(j['premium_plan'], isNull);
      expect(j['premium_started_at'], isNull);
      expect(j['premium_expires_at'], isNull);
    });
  });

  group('UserAiUsage.newUser', () {
    test('creates default record with empty id and 0 used', () {
      final u = UserAiUsage.newUser('me');
      expect(u.id, '');
      expect(u.userId, 'me');
      expect(u.aiGenerationsUsed, 0);
      expect(u.aiGenerationsLimit, 5);
      expect(u.isPremium, isFalse);
      expect(u.lifetimeGenerations, 0);
    });
  });

  group('UserAiUsage.copyWith', () {
    test('returns same values when no overrides', () {
      final u = _usage(aiGenerationsUsed: 1);
      final c = u.copyWith();
      expect(c.aiGenerationsUsed, 1);
      expect(c.id, u.id);
    });

    test('overrides only specified fields', () {
      final u = _usage(aiGenerationsUsed: 1, isPremium: false);
      final c = u.copyWith(aiGenerationsUsed: 4, isPremium: true);
      expect(c.aiGenerationsUsed, 4);
      expect(c.isPremium, isTrue);
      expect(c.userId, u.userId); // unchanged
    });
  });

  group('AiGenerationLog', () {
    test('fromJson parses required + optional fields', () {
      final json = {
        'id': 'log-1',
        'user_id': 'me',
        'destination': 'Goa',
        'duration_days': 3,
        'budget': 12000.5,
        'interests': ['food', 'beach'],
        'trip_id': 'trip-1',
        'generation_time_ms': 1234,
        'was_successful': true,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final log = AiGenerationLog.fromJson(json);
      expect(log.id, 'log-1');
      expect(log.destination, 'Goa');
      expect(log.durationDays, 3);
      expect(log.budget, closeTo(12000.5, 0.0001));
      expect(log.interests, ['food', 'beach']);
      expect(log.tripId, 'trip-1');
      expect(log.generationTimeMs, 1234);
      expect(log.wasSuccessful, isTrue);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': 'log-1',
        'user_id': 'me',
        'destination': 'Goa',
        'duration_days': 3,
        'created_at': '2026-01-01T00:00:00Z',
      };
      final log = AiGenerationLog.fromJson(json);
      expect(log.budget, isNull);
      expect(log.interests, isEmpty);
      expect(log.tripId, isNull);
      expect(log.generationTimeMs, isNull);
      expect(log.wasSuccessful, isTrue); // default
      expect(log.errorMessage, isNull);
    });

    test('toJson emits all expected keys', () {
      final log = AiGenerationLog(
        id: 'l',
        userId: 'u',
        destination: 'X',
        durationDays: 2,
        budget: 100,
        interests: ['a'],
        tripId: 't',
        generationTimeMs: 500,
        wasSuccessful: false,
        errorMessage: 'err',
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      final j = log.toJson();
      expect(j['id'], 'l');
      expect(j['user_id'], 'u');
      expect(j['destination'], 'X');
      expect(j['duration_days'], 2);
      expect(j['budget'], 100);
      expect(j['interests'], ['a']);
      expect(j['trip_id'], 't');
      expect(j['generation_time_ms'], 500);
      expect(j['was_successful'], isFalse);
      expect(j['error_message'], 'err');
    });
  });
}
