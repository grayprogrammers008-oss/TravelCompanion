import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_crew/core/providers/supabase_provider.dart';
import 'package:travel_crew/features/templates/data/datasources/template_remote_datasource.dart';
import 'package:travel_crew/features/templates/domain/entities/ai_usage.dart';
import 'package:travel_crew/features/templates/domain/entities/trip_template.dart';
import 'package:travel_crew/features/templates/presentation/providers/template_providers.dart';

/// Bare SupabaseClient stub: never accessed because the fake datasource
/// overrides every method that would touch it.
class _StubSupabaseClient extends Mock implements SupabaseClient {}

/// Lightweight SupabaseClient that only exposes a fake `auth.currentUser`
/// — used to test code paths that previously called
/// `Supabase.instance.client.auth.currentUser?.id` directly.
class _AuthStubClient extends Mock implements SupabaseClient {
  _AuthStubClient(this._currentUserId);
  final String? _currentUserId;
  late final _AuthStub _auth = _AuthStub(_currentUserId);

  @override
  GoTrueClient get auth => _auth as GoTrueClient;
}

class _AuthStub extends Mock implements GoTrueClient {
  _AuthStub(this._userId);
  final String? _userId;

  @override
  User? get currentUser => _userId == null ? null : _FakeUser(_userId);
}

class _FakeUser extends Mock implements User {
  _FakeUser(this._id);
  final String _id;

  @override
  String get id => _id;
}

/// Hand-rolled fake datasource. Each method returns canned data and records
/// invocations. Methods we don't expect to call default to throwing via the
/// inherited Supabase calls (which would fail loudly).
class _FakeTemplateDataSource extends TemplateRemoteDataSource {
  _FakeTemplateDataSource() : super(_StubSupabaseClient());

  // Canned outputs
  List<TripTemplate> templatesToReturn = const [];
  List<TripTemplate> featuredToReturn = const [];
  List<TripTemplate> popularToReturn = const [];
  TripTemplate? templateByIdToReturn;
  TripTemplate? templateWithDetailsToReturn;
  Map<TemplateCategory, List<TripTemplate>> byCategory = const {};

  bool applyResult = true;
  Object? applyError;

  UserAiUsage? aiUsageToReturn;
  bool canGenerateResult = true;
  int remainingResult = 4;
  UserAiUsage? incrementResult;

  // Recorded calls
  final List<Map<String, dynamic>> getTemplatesCalls = [];
  final List<String> getByIdCalls = [];
  final List<String> getDetailsCalls = [];
  final List<TemplateCategory> byCategoryCalls = [];
  final List<Map<String, String>> applyCalls = [];
  final List<String> getOrCreateAiCalls = [];
  final List<String> incrementCalls = [];
  final List<Map<String, dynamic>> logCalls = [];

  @override
  Future<List<TripTemplate>> getTemplates({
    TemplateCategory? category,
    int? minDays,
    int? maxDays,
    double? maxBudget,
    bool? featuredOnly,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    getTemplatesCalls.add({
      'category': category,
      'minDays': minDays,
      'maxDays': maxDays,
      'maxBudget': maxBudget,
      'featuredOnly': featuredOnly,
      'search': search,
      'limit': limit,
      'offset': offset,
    });
    return templatesToReturn;
  }

  @override
  Future<List<TripTemplate>> getFeaturedTemplates({int limit = 5}) async {
    return featuredToReturn;
  }

  @override
  Future<List<TripTemplate>> getPopularTemplates({int limit = 10}) async {
    return popularToReturn;
  }

  @override
  Future<TripTemplate?> getTemplateById(String templateId) async {
    getByIdCalls.add(templateId);
    return templateByIdToReturn;
  }

  @override
  Future<TripTemplate?> getTemplateWithDetails(String templateId) async {
    getDetailsCalls.add(templateId);
    return templateWithDetailsToReturn;
  }

  @override
  Future<List<TripTemplate>> getTemplatesByCategory(
    TemplateCategory category, {
    int limit = 20,
  }) async {
    byCategoryCalls.add(category);
    return byCategory[category] ?? const [];
  }

  @override
  Future<bool> applyTemplateToTrip({
    required String templateId,
    required String tripId,
    required String userId,
  }) async {
    applyCalls.add({
      'templateId': templateId,
      'tripId': tripId,
      'userId': userId,
    });
    if (applyError != null) throw applyError!;
    return applyResult;
  }

  @override
  Future<UserAiUsage> getOrCreateAiUsage(String userId) async {
    getOrCreateAiCalls.add(userId);
    final u = aiUsageToReturn;
    if (u == null) {
      throw StateError('aiUsageToReturn not set on fake');
    }
    return u;
  }

  @override
  Future<bool> canGenerateAiItinerary(String userId) async => canGenerateResult;

  @override
  Future<int> getRemainingAiGenerations(String userId) async => remainingResult;

  @override
  Future<UserAiUsage> incrementAiUsage(String userId) async {
    incrementCalls.add(userId);
    final u = incrementResult;
    if (u == null) {
      throw StateError('incrementResult not set on fake');
    }
    return u;
  }

  @override
  Future<void> logAiGeneration({
    required String userId,
    required String destination,
    required int durationDays,
    double? budget,
    List<String>? interests,
    String? tripId,
    int? generationTimeMs,
    bool wasSuccessful = true,
    String? errorMessage,
  }) async {
    logCalls.add({
      'userId': userId,
      'destination': destination,
      'durationDays': durationDays,
      'budget': budget,
      'interests': interests,
      'tripId': tripId,
      'generationTimeMs': generationTimeMs,
      'wasSuccessful': wasSuccessful,
      'errorMessage': errorMessage,
    });
  }
}

TripTemplate _t(String id, {TemplateCategory cat = TemplateCategory.beach}) {
  final now = DateTime.parse('2026-01-01T00:00:00Z');
  return TripTemplate(
    id: id,
    name: 'Tpl-$id',
    destination: 'Dest-$id',
    durationDays: 3,
    category: cat,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _container({
  _FakeTemplateDataSource? fake,
  String? authUserId,
}) {
  return ProviderContainer(
    overrides: [
      templateDataSourceProvider
          .overrideWithValue(fake ?? _FakeTemplateDataSource()),
      supabaseClientProvider.overrideWithValue(
        _AuthStubClient(authUserId),
      ),
    ],
  );
}

void main() {
  group('TemplateFilters', () {
    test('equality is by value, not identity', () {
      const a = TemplateFilters(category: TemplateCategory.beach, search: 'x');
      const b = TemplateFilters(category: TemplateCategory.beach, search: 'x');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality across distinct fields', () {
      const a = TemplateFilters(category: TemplateCategory.beach);
      const b = TemplateFilters(category: TemplateCategory.heritage);
      expect(a, isNot(equals(b)));
    });

    test('copyWith preserves unspecified fields', () {
      const f = TemplateFilters(
        category: TemplateCategory.adventure,
        minDays: 2,
        maxDays: 7,
        maxBudget: 50000,
        featuredOnly: true,
        search: 'goa',
      );
      final c = f.copyWith(search: 'manali');
      expect(c.search, 'manali');
      expect(c.category, TemplateCategory.adventure);
      expect(c.minDays, 2);
      expect(c.maxDays, 7);
      expect(c.maxBudget, 50000);
      expect(c.featuredOnly, isTrue);
    });

    test('all-null filters compare equal', () {
      const a = TemplateFilters();
      const b = TemplateFilters();
      expect(a, equals(b));
    });
  });

  group('TemplateControllerState', () {
    test('default state is not loading and no error', () {
      const s = TemplateControllerState();
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
    });

    test('copyWith updates isLoading independently', () {
      const s = TemplateControllerState();
      final s2 = s.copyWith(isLoading: true);
      expect(s2.isLoading, isTrue);
      expect(s2.error, isNull);
    });

    test('copyWith allows clearing error by passing explicit null', () {
      const s = TemplateControllerState(isLoading: false, error: 'boom');
      // Calling copyWith with no error arg creates new state with error: null
      // because the copyWith implementation does `error: error` (not ?? this.error).
      final s2 = s.copyWith();
      expect(s2.error, isNull);
    });
  });

  group('templatesProvider', () {
    test('returns datasource templates list', () async {
      final fake = _FakeTemplateDataSource()
        ..templatesToReturn = [_t('a'), _t('b')];
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final list = await c.read(templatesProvider(null).future);
      expect(list.map((e) => e.id), ['a', 'b']);
    });

    test('forwards filter values to datasource', () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      const filters = TemplateFilters(
        category: TemplateCategory.adventure,
        minDays: 2,
        maxDays: 7,
        maxBudget: 30000,
        featuredOnly: true,
        search: 'manali',
      );
      await c.read(templatesProvider(filters).future);

      expect(fake.getTemplatesCalls, hasLength(1));
      final call = fake.getTemplatesCalls.first;
      expect(call['category'], TemplateCategory.adventure);
      expect(call['minDays'], 2);
      expect(call['maxDays'], 7);
      expect(call['maxBudget'], 30000);
      expect(call['featuredOnly'], isTrue);
      expect(call['search'], 'manali');
    });

    test('passes nulls when filters argument is null', () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      await c.read(templatesProvider(null).future);

      expect(fake.getTemplatesCalls, hasLength(1));
      final call = fake.getTemplatesCalls.first;
      expect(call['category'], isNull);
      expect(call['search'], isNull);
    });

    test('caches by family arg (different filters = separate calls)',
        () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      const f1 = TemplateFilters(category: TemplateCategory.beach);
      const f2 = TemplateFilters(category: TemplateCategory.heritage);
      await c.read(templatesProvider(f1).future);
      await c.read(templatesProvider(f2).future);
      // Read same filter again - should reuse.
      await c.read(templatesProvider(f1).future);

      expect(fake.getTemplatesCalls, hasLength(2));
    });
  });

  group('featured/popular providers', () {
    test('featuredTemplatesProvider returns datasource featured list',
        () async {
      final fake = _FakeTemplateDataSource()..featuredToReturn = [_t('f')];
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final list = await c.read(featuredTemplatesProvider.future);
      expect(list.single.id, 'f');
    });

    test('popularTemplatesProvider returns datasource popular list',
        () async {
      final fake = _FakeTemplateDataSource()..popularToReturn = [_t('p')];
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final list = await c.read(popularTemplatesProvider.future);
      expect(list.single.id, 'p');
    });
  });

  group('templateByIdProvider / templateDetailsProvider', () {
    test('templateByIdProvider returns null when datasource returns null',
        () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final result = await c.read(templateByIdProvider('missing').future);
      expect(result, isNull);
      expect(fake.getByIdCalls, ['missing']);
    });

    test('templateByIdProvider returns the matched template', () async {
      final fake = _FakeTemplateDataSource()..templateByIdToReturn = _t('x');
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final result = await c.read(templateByIdProvider('x').future);
      expect(result?.id, 'x');
    });

    test('templateDetailsProvider returns full template', () async {
      final fake = _FakeTemplateDataSource()
        ..templateWithDetailsToReturn = _t('d');
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final result = await c.read(templateDetailsProvider('d').future);
      expect(result?.id, 'd');
      expect(fake.getDetailsCalls, ['d']);
    });
  });

  group('templatesByCategoryProvider', () {
    test('forwards category and returns canned list', () async {
      final fake = _FakeTemplateDataSource()
        ..byCategory = {
          TemplateCategory.beach: [_t('b1'), _t('b2')],
        };
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final list = await c
          .read(templatesByCategoryProvider(TemplateCategory.beach).future);
      expect(list.map((e) => e.id), ['b1', 'b2']);
      expect(fake.byCategoryCalls, [TemplateCategory.beach]);
    });

    test('returns empty list when datasource has no entries for category',
        () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake);
      addTearDown(c.dispose);

      final list = await c
          .read(templatesByCategoryProvider(TemplateCategory.weekend).future);
      expect(list, isEmpty);
    });
  });

  group('aiUsageProvider (now testable via supabaseClientProvider)', () {
    test('returns null when no logged-in user', () async {
      final c = _container(authUserId: null);
      addTearDown(c.dispose);

      final result = await c.read(aiUsageProvider.future);
      expect(result, isNull);
    });

    test('returns datasource AI usage when user is logged in', () async {
      final usage = UserAiUsage.newUser('user-1');
      final fake = _FakeTemplateDataSource()..aiUsageToReturn = usage;
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      final result = await c.read(aiUsageProvider.future);
      expect(result, isNotNull);
      expect(result!.userId, 'user-1');
      expect(fake.getOrCreateAiCalls, ['user-1']);
    });
  });

  group('canGenerateAiProvider', () {
    test('returns false when no logged-in user', () async {
      final c = _container(authUserId: null);
      addTearDown(c.dispose);

      expect(await c.read(canGenerateAiProvider.future), isFalse);
    });

    test('returns datasource result when user is logged in', () async {
      final fake = _FakeTemplateDataSource()..canGenerateResult = true;
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      expect(await c.read(canGenerateAiProvider.future), isTrue);
    });

    test('respects datasource canGenerate=false', () async {
      final fake = _FakeTemplateDataSource()..canGenerateResult = false;
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      expect(await c.read(canGenerateAiProvider.future), isFalse);
    });
  });

  group('remainingGenerationsProvider', () {
    test('returns 0 when no logged-in user', () async {
      final c = _container(authUserId: null);
      addTearDown(c.dispose);

      expect(await c.read(remainingGenerationsProvider.future), 0);
    });

    test('returns datasource count when user is logged in', () async {
      final fake = _FakeTemplateDataSource()..remainingResult = 7;
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      expect(await c.read(remainingGenerationsProvider.future), 7);
    });
  });

  group('TemplateController.applyTemplateToTrip', () {
    test('returns false when no logged-in user', () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake, authUserId: null);
      addTearDown(c.dispose);

      final ctrl = c.read(templateControllerProvider.notifier);
      final result = await ctrl.applyTemplateToTrip(
        templateId: 'tpl',
        tripId: 'trip',
      );
      expect(result, isFalse);
      // No datasource call when no user
      expect(fake.applyCalls, isEmpty);
    });

    test('returns true and forwards to datasource when user is logged in',
        () async {
      final fake = _FakeTemplateDataSource()..applyResult = true;
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      final ctrl = c.read(templateControllerProvider.notifier);
      final result = await ctrl.applyTemplateToTrip(
        templateId: 'tpl-42',
        tripId: 'trip-42',
      );
      expect(result, isTrue);
      expect(fake.applyCalls, [
        {'templateId': 'tpl-42', 'tripId': 'trip-42', 'userId': 'user-1'},
      ]);
      // Final state should not be loading and have no error
      final state = c.read(templateControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('returns false and surfaces error when datasource throws', () async {
      final fake = _FakeTemplateDataSource()
        ..applyError = Exception('apply failed');
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      final ctrl = c.read(templateControllerProvider.notifier);
      final result = await ctrl.applyTemplateToTrip(
        templateId: 'tpl',
        tripId: 'trip',
      );
      expect(result, isFalse);
      final state = c.read(templateControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('apply failed'));
    });
  });

  group('TemplateController.incrementAiUsage', () {
    test('returns null when no logged-in user', () async {
      final c = _container(authUserId: null);
      addTearDown(c.dispose);

      final result =
          await c.read(templateControllerProvider.notifier).incrementAiUsage();
      expect(result, isNull);
    });

    test('returns datasource result when user is logged in', () async {
      final usage = UserAiUsage.newUser('user-1');
      final fake = _FakeTemplateDataSource()..incrementResult = usage;
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      final result =
          await c.read(templateControllerProvider.notifier).incrementAiUsage();
      expect(result, isNotNull);
      expect(fake.incrementCalls, ['user-1']);
    });

    test('returns null silently when datasource throws', () async {
      // incrementResult is null → fake's getOrCreate throws StateError; the
      // controller catches and returns null.
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      final result =
          await c.read(templateControllerProvider.notifier).incrementAiUsage();
      expect(result, isNull);
    });
  });

  group('TemplateController.logAiGeneration', () {
    test('no-ops when no logged-in user', () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake, authUserId: null);
      addTearDown(c.dispose);

      await c.read(templateControllerProvider.notifier).logAiGeneration(
            destination: 'Goa',
            durationDays: 3,
          );
      expect(fake.logCalls, isEmpty);
    });

    test('forwards to datasource when user is logged in', () async {
      final fake = _FakeTemplateDataSource();
      final c = _container(fake: fake, authUserId: 'user-1');
      addTearDown(c.dispose);

      await c.read(templateControllerProvider.notifier).logAiGeneration(
            destination: 'Goa',
            durationDays: 3,
            budget: 50000,
            interests: const ['beach'],
            tripId: 'trip-1',
            generationTimeMs: 1234,
          );

      expect(fake.logCalls, hasLength(1));
      final call = fake.logCalls.first;
      expect(call['userId'], 'user-1');
      expect(call['destination'], 'Goa');
      expect(call['durationDays'], 3);
      expect(call['budget'], 50000);
      expect(call['interests'], ['beach']);
      expect(call['tripId'], 'trip-1');
      expect(call['generationTimeMs'], 1234);
      expect(call['wasSuccessful'], isTrue);
    });
  });
}
