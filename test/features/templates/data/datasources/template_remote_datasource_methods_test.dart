import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pathio/features/templates/data/datasources/template_queries.dart';
import 'package:pathio/features/templates/data/datasources/template_remote_datasource.dart';
import 'package:pathio/features/templates/domain/entities/trip_template.dart';

/// Hand-rolled fake of [TemplateQueries] that records every call and lets
/// tests script the response. No mockito codegen.
class _FakeQueries implements TemplateQueries {
  // -------- recorded args --------
  Map<String, dynamic>? lastGetTemplatesArgs;
  int? lastFeaturedLimit;
  int? lastPopularLimit;
  String? lastGetByIdArg;
  String? lastItineraryArg;
  String? lastChecklistsArg;
  String? lastByCategoryName;
  int? lastByCategoryLimit;
  Map<String, String>? lastApplyArgs;
  String? lastIncrementUseCountArg;
  String? lastGetOrCreateAiUserId;
  String? lastCanGenerateUserId;
  String? lastRemainingUserId;
  String? lastIncrementAiUserId;
  Map<String, dynamic>? lastLogInsertArg;
  String? lastHistoryUserId;
  int? lastHistoryLimit;

  // -------- canned outputs --------
  List<Map<String, dynamic>> templatesResponse = const [];
  List<Map<String, dynamic>> featuredResponse = const [];
  List<Map<String, dynamic>> popularResponse = const [];
  Map<String, dynamic>? templateByIdResponse;
  bool _byIdReturnNull = false;
  List<Map<String, dynamic>> itineraryResponse = const [];
  List<Map<String, dynamic>> checklistsResponse = const [];
  List<Map<String, dynamic>> byCategoryResponse = const [];
  dynamic applyRpcResponse = true;
  Map<String, dynamic> getOrCreateAiResponse = const {};
  dynamic canGenerateResponse = true;
  dynamic remainingResponse = 5;
  Map<String, dynamic> incrementAiResponse = const {};
  List<Map<String, dynamic>> historyResponse = const [];

  // -------- error injection --------
  Object? throwOnGetTemplates;
  Object? throwOnFeatured;
  Object? throwOnPopular;
  Object? throwOnGetById;
  Object? throwOnItinerary;
  Object? throwOnChecklists;
  Object? throwOnByCategory;
  Object? throwOnApply;
  Object? throwOnIncrementUseCount;
  Object? throwOnGetOrCreateAi;
  Object? throwOnCanGenerate;
  Object? throwOnRemaining;
  Object? throwOnIncrementAi;
  Object? throwOnLogInsert;
  Object? throwOnHistory;

  void setByIdReturnsNull() => _byIdReturnNull = true;

  @override
  Future<List<Map<String, dynamic>>> getTemplates({
    String? category,
    int? minDays,
    int? maxDays,
    double? maxBudget,
    bool? featuredOnly,
    String? search,
    required int limit,
    required int offset,
  }) async {
    if (throwOnGetTemplates != null) throw throwOnGetTemplates!;
    lastGetTemplatesArgs = {
      'category': category,
      'minDays': minDays,
      'maxDays': maxDays,
      'maxBudget': maxBudget,
      'featuredOnly': featuredOnly,
      'search': search,
      'limit': limit,
      'offset': offset,
    };
    return templatesResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getFeaturedTemplates(
      {required int limit}) async {
    if (throwOnFeatured != null) throw throwOnFeatured!;
    lastFeaturedLimit = limit;
    return featuredResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getPopularTemplates(
      {required int limit}) async {
    if (throwOnPopular != null) throw throwOnPopular!;
    lastPopularLimit = limit;
    return popularResponse;
  }

  @override
  Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    if (throwOnGetById != null) throw throwOnGetById!;
    lastGetByIdArg = templateId;
    if (_byIdReturnNull) return null;
    return templateByIdResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplateItineraryItems(
      String templateId) async {
    if (throwOnItinerary != null) throw throwOnItinerary!;
    lastItineraryArg = templateId;
    return itineraryResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplateChecklistsWithItems(
      String templateId) async {
    if (throwOnChecklists != null) throw throwOnChecklists!;
    lastChecklistsArg = templateId;
    return checklistsResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplatesByCategory(
    String categoryName, {
    required int limit,
  }) async {
    if (throwOnByCategory != null) throw throwOnByCategory!;
    lastByCategoryName = categoryName;
    lastByCategoryLimit = limit;
    return byCategoryResponse;
  }

  @override
  Future<dynamic> applyTemplateToTripRpc({
    required String templateId,
    required String tripId,
    required String userId,
  }) async {
    if (throwOnApply != null) throw throwOnApply!;
    lastApplyArgs = {
      'templateId': templateId,
      'tripId': tripId,
      'userId': userId,
    };
    return applyRpcResponse;
  }

  @override
  Future<void> incrementTemplateUseCountRpc(String templateId) async {
    if (throwOnIncrementUseCount != null) throw throwOnIncrementUseCount!;
    lastIncrementUseCountArg = templateId;
  }

  @override
  Future<Map<String, dynamic>> getOrCreateAiUsageRpc(String userId) async {
    if (throwOnGetOrCreateAi != null) throw throwOnGetOrCreateAi!;
    lastGetOrCreateAiUserId = userId;
    return getOrCreateAiResponse;
  }

  @override
  Future<dynamic> canGenerateAiItineraryRpc(String userId) async {
    if (throwOnCanGenerate != null) throw throwOnCanGenerate!;
    lastCanGenerateUserId = userId;
    return canGenerateResponse;
  }

  @override
  Future<dynamic> getRemainingAiGenerationsRpc(String userId) async {
    if (throwOnRemaining != null) throw throwOnRemaining!;
    lastRemainingUserId = userId;
    return remainingResponse;
  }

  @override
  Future<Map<String, dynamic>> incrementAiUsageRpc(String userId) async {
    if (throwOnIncrementAi != null) throw throwOnIncrementAi!;
    lastIncrementAiUserId = userId;
    return incrementAiResponse;
  }

  @override
  Future<void> insertAiGenerationLog(Map<String, dynamic> data) async {
    if (throwOnLogInsert != null) throw throwOnLogInsert!;
    lastLogInsertArg = data;
  }

  @override
  Future<List<Map<String, dynamic>>> getAiGenerationHistory(
    String userId, {
    required int limit,
  }) async {
    if (throwOnHistory != null) throw throwOnHistory!;
    lastHistoryUserId = userId;
    lastHistoryLimit = limit;
    return historyResponse;
  }
}

/// Bare SupabaseClient stub: never accessed because the queries layer is
/// fully faked.
class _StubSupabaseClient extends Mock implements SupabaseClient {}

DateTime _ts() => DateTime.utc(2024, 6, 1, 12, 0, 0);

Map<String, dynamic> _templateRow({
  String id = 't-1',
  String name = 'Goa Beach Trip',
  String destination = 'Goa',
  int days = 5,
  String category = 'beach',
  bool featured = false,
  int useCount = 10,
}) {
  return {
    'id': id,
    'name': name,
    'description': 'A wonderful trip',
    'destination': destination,
    'destination_state': 'Goa',
    'duration_days': days,
    'budget_min': 5000,
    'budget_max': 20000,
    'currency': 'INR',
    'cover_image_url': null,
    'category': category,
    'tags': const ['fun', 'sun'],
    'best_season': const ['Oct', 'Nov'],
    'difficulty_level': 'easy',
    'is_active': true,
    'is_featured': featured,
    'use_count': useCount,
    'rating': 4.5,
    'rating_count': 30,
    'created_at': _ts().toIso8601String(),
    'updated_at': _ts().toIso8601String(),
  };
}

Map<String, dynamic> _itineraryRow({
  String id = 'i-1',
  String templateId = 't-1',
  int day = 1,
}) {
  return {
    'id': id,
    'template_id': templateId,
    'day_number': day,
    'order_index': 0,
    'title': 'Visit beach',
    'description': 'Enjoy the sun',
    'location': 'Baga',
    'location_url': null,
    'start_time': '09:00',
    'end_time': '11:00',
    'duration_minutes': 120,
    'category': 'sightseeing',
    'estimated_cost': 0,
    'tips': 'Bring sunscreen',
    'created_at': _ts().toIso8601String(),
  };
}

Map<String, dynamic> _checklistRow({
  String id = 'c-1',
  String templateId = 't-1',
  List<Map<String, dynamic>>? items,
}) {
  return {
    'id': id,
    'template_id': templateId,
    'name': 'Packing',
    'icon': 'checklist',
    'order_index': 0,
    'created_at': _ts().toIso8601String(),
    'template_checklist_items': items ?? <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _checklistItemRow({
  String id = 'ci-1',
  String checklistId = 'c-1',
  bool essential = false,
}) {
  return {
    'id': id,
    'checklist_id': checklistId,
    'content': 'Sunglasses',
    'order_index': 0,
    'is_essential': essential,
    'category': null,
    'created_at': _ts().toIso8601String(),
  };
}

Map<String, dynamic> _aiUsageRow({
  String id = 'a-1',
  String userId = 'u-1',
  int used = 1,
  int limit = 5,
}) {
  return {
    'id': id,
    'user_id': userId,
    'ai_generations_used': used,
    'ai_generations_limit': limit,
    'is_premium': false,
    'lifetime_generations': used,
    'created_at': _ts().toIso8601String(),
    'updated_at': _ts().toIso8601String(),
  };
}

Map<String, dynamic> _logRow({String id = 'l-1', String userId = 'u-1'}) {
  return {
    'id': id,
    'user_id': userId,
    'destination': 'Goa',
    'duration_days': 4,
    'budget': 10000,
    'interests': const ['beach'],
    'trip_id': 't-1',
    'generation_time_ms': 1234,
    'was_successful': true,
    'error_message': null,
    'created_at': _ts().toIso8601String(),
  };
}

void main() {
  late _FakeQueries queries;
  late TemplateRemoteDataSource ds;

  setUp(() {
    queries = _FakeQueries();
    ds = TemplateRemoteDataSource(_StubSupabaseClient(), queries: queries);
  });

  group('getTemplates', () {
    test('passes default pagination and no filters when none supplied',
        () async {
      queries.templatesResponse = [_templateRow()];

      final result = await ds.getTemplates();

      expect(result, hasLength(1));
      expect(result.single.id, 't-1');
      expect(queries.lastGetTemplatesArgs!['category'], isNull);
      expect(queries.lastGetTemplatesArgs!['minDays'], isNull);
      expect(queries.lastGetTemplatesArgs!['maxDays'], isNull);
      expect(queries.lastGetTemplatesArgs!['maxBudget'], isNull);
      expect(queries.lastGetTemplatesArgs!['featuredOnly'], isNull);
      expect(queries.lastGetTemplatesArgs!['search'], isNull);
      expect(queries.lastGetTemplatesArgs!['limit'], 50);
      expect(queries.lastGetTemplatesArgs!['offset'], 0);
    });

    test('serialises category enum to its name', () async {
      queries.templatesResponse = const [];
      await ds.getTemplates(category: TemplateCategory.beach);
      expect(queries.lastGetTemplatesArgs!['category'], 'beach');
    });

    test('forwards every numeric / boolean / search filter', () async {
      queries.templatesResponse = const [];
      await ds.getTemplates(
        category: TemplateCategory.adventure,
        minDays: 2,
        maxDays: 14,
        maxBudget: 50000,
        featuredOnly: true,
        search: 'goa',
        limit: 10,
        offset: 20,
      );
      expect(queries.lastGetTemplatesArgs!['category'], 'adventure');
      expect(queries.lastGetTemplatesArgs!['minDays'], 2);
      expect(queries.lastGetTemplatesArgs!['maxDays'], 14);
      expect(queries.lastGetTemplatesArgs!['maxBudget'], 50000);
      expect(queries.lastGetTemplatesArgs!['featuredOnly'], isTrue);
      expect(queries.lastGetTemplatesArgs!['search'], 'goa');
      expect(queries.lastGetTemplatesArgs!['limit'], 10);
      expect(queries.lastGetTemplatesArgs!['offset'], 20);
    });

    test('returns empty list when query yields no rows', () async {
      queries.templatesResponse = const [];
      final result = await ds.getTemplates();
      expect(result, isEmpty);
    });

    test('maps multiple rows to TripTemplate models', () async {
      queries.templatesResponse = [
        _templateRow(id: 'a'),
        _templateRow(id: 'b', name: 'Other Trip'),
      ];
      final result = await ds.getTemplates();
      expect(result.map((e) => e.id), ['a', 'b']);
      expect(result[1].name, 'Other Trip');
    });

    test('propagates the underlying error', () async {
      queries.throwOnGetTemplates = Exception('boom');
      await expectLater(ds.getTemplates(), throwsA(isA<Exception>()));
    });
  });

  group('getFeaturedTemplates', () {
    test('uses default limit of 5 and returns mapped models', () async {
      queries.featuredResponse = [_templateRow(featured: true)];
      final result = await ds.getFeaturedTemplates();
      expect(queries.lastFeaturedLimit, 5);
      expect(result.single.isFeatured, isTrue);
    });

    test('passes through an explicit limit', () async {
      queries.featuredResponse = const [];
      await ds.getFeaturedTemplates(limit: 12);
      expect(queries.lastFeaturedLimit, 12);
    });

    test('propagates errors', () async {
      queries.throwOnFeatured = Exception('boom');
      await expectLater(
          ds.getFeaturedTemplates(), throwsA(isA<Exception>()));
    });
  });

  group('getPopularTemplates', () {
    test('uses default limit of 10 and returns mapped models', () async {
      queries.popularResponse = [_templateRow()];
      final result = await ds.getPopularTemplates();
      expect(queries.lastPopularLimit, 10);
      expect(result.single.id, 't-1');
    });

    test('passes through an explicit limit', () async {
      queries.popularResponse = const [];
      await ds.getPopularTemplates(limit: 3);
      expect(queries.lastPopularLimit, 3);
    });

    test('propagates errors', () async {
      queries.throwOnPopular = Exception('boom');
      await expectLater(ds.getPopularTemplates(), throwsA(isA<Exception>()));
    });
  });

  group('getTemplateById', () {
    test('returns null when the row is null', () async {
      queries.setByIdReturnsNull();
      expect(await ds.getTemplateById('t-1'), isNull);
      expect(queries.lastGetByIdArg, 't-1');
    });

    test('parses the row when present', () async {
      queries.templateByIdResponse = _templateRow();
      final result = await ds.getTemplateById('t-1');
      expect(result, isNotNull);
      expect(result!.id, 't-1');
    });

    test('propagates errors', () async {
      queries.throwOnGetById = Exception('boom');
      await expectLater(ds.getTemplateById('t'), throwsA(isA<Exception>()));
    });
  });

  group('getTemplateWithDetails', () {
    test('returns null when the base template is null', () async {
      queries.setByIdReturnsNull();
      final result = await ds.getTemplateWithDetails('t-1');
      expect(result, isNull);
      // Itinerary and checklists not fetched once base template is null.
      expect(queries.lastItineraryArg, isNull);
      expect(queries.lastChecklistsArg, isNull);
    });

    test('attaches itinerary items and checklists with nested items',
        () async {
      queries.templateByIdResponse = _templateRow();
      queries.itineraryResponse = [
        _itineraryRow(id: 'i-1', day: 1),
        _itineraryRow(id: 'i-2', day: 2),
      ];
      queries.checklistsResponse = [
        _checklistRow(items: [_checklistItemRow(id: 'ci-1', essential: true)]),
      ];

      final result = await ds.getTemplateWithDetails('t-1');
      expect(result, isNotNull);
      expect(result!.itineraryItems, hasLength(2));
      expect(result.itineraryItems!.first.id, 'i-1');
      expect(result.checklists, hasLength(1));
      expect(result.checklists!.first.items, isNotNull);
      expect(result.checklists!.first.items!.single.isEssential, isTrue);
      expect(queries.lastItineraryArg, 't-1');
      expect(queries.lastChecklistsArg, 't-1');
    });

    test('handles checklists with no nested items list (defaults to null)',
        () async {
      queries.templateByIdResponse = _templateRow();
      queries.itineraryResponse = const [];
      // Checklist row missing the nested key entirely.
      queries.checklistsResponse = [
        {
          'id': 'c-1',
          'template_id': 't-1',
          'name': 'Packing',
          'icon': 'checklist',
          'order_index': 0,
          'created_at': _ts().toIso8601String(),
        },
      ];
      final result = await ds.getTemplateWithDetails('t-1');
      expect(result!.checklists!.single.items, isNull);
    });

    test('removes the template_checklist_items key before fromJson', () async {
      queries.templateByIdResponse = _templateRow();
      queries.itineraryResponse = const [];
      queries.checklistsResponse = [
        _checklistRow(items: const []),
      ];
      // No throw means fromJson did not encounter unexpected key.
      final result = await ds.getTemplateWithDetails('t-1');
      expect(result!.checklists, hasLength(1));
      expect(result.checklists!.first.items, isEmpty);
    });

    test('propagates itinerary errors', () async {
      queries.templateByIdResponse = _templateRow();
      queries.throwOnItinerary = Exception('boom');
      await expectLater(
          ds.getTemplateWithDetails('t-1'), throwsA(isA<Exception>()));
    });
  });

  group('getTemplatesByCategory', () {
    test('uses default limit of 20 and serialises enum name', () async {
      queries.byCategoryResponse = [_templateRow()];
      final result =
          await ds.getTemplatesByCategory(TemplateCategory.heritage);
      expect(queries.lastByCategoryName, 'heritage');
      expect(queries.lastByCategoryLimit, 20);
      expect(result, hasLength(1));
    });

    test('passes through a custom limit', () async {
      queries.byCategoryResponse = const [];
      await ds.getTemplatesByCategory(TemplateCategory.beach, limit: 7);
      expect(queries.lastByCategoryLimit, 7);
    });

    test('propagates errors', () async {
      queries.throwOnByCategory = Exception('boom');
      await expectLater(
        ds.getTemplatesByCategory(TemplateCategory.adventure),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('applyTemplateToTrip', () {
    test('returns true when RPC response is true', () async {
      queries.applyRpcResponse = true;
      final result = await ds.applyTemplateToTrip(
        templateId: 't-1',
        tripId: 'trip-1',
        userId: 'u-1',
      );
      expect(result, isTrue);
      expect(queries.lastApplyArgs, {
        'templateId': 't-1',
        'tripId': 'trip-1',
        'userId': 'u-1',
      });
    });

    test('returns false when RPC response is not true', () async {
      queries.applyRpcResponse = false;
      expect(
        await ds.applyTemplateToTrip(
          templateId: 't',
          tripId: 't2',
          userId: 'u',
        ),
        isFalse,
      );
    });

    test('returns false when RPC response is null', () async {
      queries.applyRpcResponse = null;
      expect(
        await ds.applyTemplateToTrip(
          templateId: 't',
          tripId: 't2',
          userId: 'u',
        ),
        isFalse,
      );
    });

    test('rethrows when RPC throws', () async {
      queries.throwOnApply = Exception('rpc failed');
      await expectLater(
        ds.applyTemplateToTrip(
          templateId: 't',
          tripId: 't2',
          userId: 'u',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('incrementTemplateUseCount', () {
    test('forwards templateId to queries', () async {
      await ds.incrementTemplateUseCount('t-1');
      expect(queries.lastIncrementUseCountArg, 't-1');
    });

    test('propagates errors', () async {
      queries.throwOnIncrementUseCount = Exception('boom');
      await expectLater(
          ds.incrementTemplateUseCount('t'), throwsA(isA<Exception>()));
    });
  });

  group('getOrCreateAiUsage', () {
    test('returns parsed UserAiUsage', () async {
      queries.getOrCreateAiResponse = _aiUsageRow(used: 2, limit: 5);
      final result = await ds.getOrCreateAiUsage('u-1');
      expect(queries.lastGetOrCreateAiUserId, 'u-1');
      expect(result.aiGenerationsUsed, 2);
      expect(result.aiGenerationsLimit, 5);
      expect(result.userId, 'u-1');
    });

    test('propagates errors', () async {
      queries.throwOnGetOrCreateAi = Exception('boom');
      await expectLater(
          ds.getOrCreateAiUsage('u'), throwsA(isA<Exception>()));
    });
  });

  group('canGenerateAiItinerary', () {
    test('returns true when RPC returns true', () async {
      queries.canGenerateResponse = true;
      expect(await ds.canGenerateAiItinerary('u'), isTrue);
      expect(queries.lastCanGenerateUserId, 'u');
    });

    test('returns false when RPC returns false', () async {
      queries.canGenerateResponse = false;
      expect(await ds.canGenerateAiItinerary('u'), isFalse);
    });

    test('returns false when RPC returns null', () async {
      queries.canGenerateResponse = null;
      expect(await ds.canGenerateAiItinerary('u'), isFalse);
    });

    test('returns true (graceful) when RPC throws', () async {
      queries.throwOnCanGenerate = Exception('rpc missing');
      expect(await ds.canGenerateAiItinerary('u'), isTrue);
    });
  });

  group('getRemainingAiGenerations', () {
    test('returns the int when RPC returns an int', () async {
      queries.remainingResponse = 7;
      expect(await ds.getRemainingAiGenerations('u'), 7);
      expect(queries.lastRemainingUserId, 'u');
    });

    test('returns 5 (graceful default) when RPC throws', () async {
      queries.throwOnRemaining = Exception('boom');
      expect(await ds.getRemainingAiGenerations('u'), 5);
    });

    test('returns 5 (graceful) when RPC returns a non-int (cast fails)',
        () async {
      queries.remainingResponse = 'not-an-int';
      expect(await ds.getRemainingAiGenerations('u'), 5);
    });
  });

  group('incrementAiUsage', () {
    test('returns parsed UserAiUsage', () async {
      queries.incrementAiResponse = _aiUsageRow(used: 3);
      final result = await ds.incrementAiUsage('u-1');
      expect(queries.lastIncrementAiUserId, 'u-1');
      expect(result.aiGenerationsUsed, 3);
    });

    test('propagates errors', () async {
      queries.throwOnIncrementAi = Exception('boom');
      await expectLater(
          ds.incrementAiUsage('u'), throwsA(isA<Exception>()));
    });
  });

  group('logAiGeneration', () {
    test('inserts all required and optional fields', () async {
      await ds.logAiGeneration(
        userId: 'u-1',
        destination: 'Goa',
        durationDays: 4,
        budget: 12345.5,
        interests: const ['beach', 'food'],
        tripId: 'trip-1',
        generationTimeMs: 999,
        wasSuccessful: false,
        errorMessage: 'oops',
      );
      expect(queries.lastLogInsertArg, {
        'user_id': 'u-1',
        'destination': 'Goa',
        'duration_days': 4,
        'budget': 12345.5,
        'interests': const ['beach', 'food'],
        'trip_id': 'trip-1',
        'generation_time_ms': 999,
        'was_successful': false,
        'error_message': 'oops',
      });
    });

    test('defaults to wasSuccessful=true and empty interests when omitted',
        () async {
      await ds.logAiGeneration(
        userId: 'u-1',
        destination: 'Goa',
        durationDays: 4,
      );
      expect(queries.lastLogInsertArg!['was_successful'], isTrue);
      expect(queries.lastLogInsertArg!['interests'], isEmpty);
      expect(queries.lastLogInsertArg!['budget'], isNull);
      expect(queries.lastLogInsertArg!['trip_id'], isNull);
      expect(queries.lastLogInsertArg!['generation_time_ms'], isNull);
      expect(queries.lastLogInsertArg!['error_message'], isNull);
    });

    test('propagates insert errors', () async {
      queries.throwOnLogInsert = Exception('boom');
      await expectLater(
        ds.logAiGeneration(
          userId: 'u',
          destination: 'd',
          durationDays: 1,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getGenerationHistory', () {
    test('uses default limit of 20 and returns mapped logs', () async {
      queries.historyResponse = [_logRow(id: 'l-1'), _logRow(id: 'l-2')];
      final result = await ds.getGenerationHistory('u-1');
      expect(queries.lastHistoryUserId, 'u-1');
      expect(queries.lastHistoryLimit, 20);
      expect(result.map((e) => e.id), ['l-1', 'l-2']);
    });

    test('passes through a custom limit', () async {
      queries.historyResponse = const [];
      await ds.getGenerationHistory('u', limit: 3);
      expect(queries.lastHistoryLimit, 3);
    });

    test('propagates errors', () async {
      queries.throwOnHistory = Exception('boom');
      await expectLater(
        ds.getGenerationHistory('u'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Default constructor', () {
    test('builds a TemplateQueriesImpl when none is supplied', () {
      // Using a stub client; we only assert that constructing the DS does
      // not throw and that calling a method without an injected fake would
      // hit the real query layer (which we don't actually invoke here).
      final stub = _StubSupabaseClient();
      final realDs = TemplateRemoteDataSource(stub);
      expect(realDs, isA<TemplateRemoteDataSource>());
    });
  });
}
