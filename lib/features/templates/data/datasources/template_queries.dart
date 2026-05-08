import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase PostgREST chain used by
/// [TemplateRemoteDataSource].
///
/// The Supabase fluent builders are not mockable through Mockito — their
/// generic types are fixed per method and `Mock` cannot intercept the awaited
/// `then()`. Wrapping the chain calls in this interface lets tests substitute
/// a fake while the production [TemplateQueriesImpl] carries the (untestable)
/// Supabase code.
abstract class TemplateQueries {
  /// Get all templates with optional filters, paginated.
  Future<List<Map<String, dynamic>>> getTemplates({
    String? category,
    int? minDays,
    int? maxDays,
    double? maxBudget,
    bool? featuredOnly,
    String? search,
    required int limit,
    required int offset,
  });

  /// Get featured templates ordered by use_count desc.
  Future<List<Map<String, dynamic>>> getFeaturedTemplates({required int limit});

  /// Get popular templates (active, ordered by use_count desc).
  Future<List<Map<String, dynamic>>> getPopularTemplates({required int limit});

  /// Get a single active template by ID (or null).
  Future<Map<String, dynamic>?> getTemplateById(String templateId);

  /// Get itinerary items for a template ordered by day_number, order_index.
  Future<List<Map<String, dynamic>>> getTemplateItineraryItems(
      String templateId);

  /// Get checklists for a template (nested items inlined) ordered by order.
  Future<List<Map<String, dynamic>>> getTemplateChecklistsWithItems(
      String templateId);

  /// Get templates filtered by category, ordered by use_count desc.
  Future<List<Map<String, dynamic>>> getTemplatesByCategory(
    String categoryName, {
    required int limit,
  });

  /// Apply template to trip via RPC. Returns raw RPC response.
  Future<dynamic> applyTemplateToTripRpc({
    required String templateId,
    required String tripId,
    required String userId,
  });

  /// Increment template use_count via RPC.
  Future<void> incrementTemplateUseCountRpc(String templateId);

  /// Get or create AI usage row for a user via RPC.
  Future<Map<String, dynamic>> getOrCreateAiUsageRpc(String userId);

  /// Check if user can generate AI itinerary via RPC. Returns raw response.
  Future<dynamic> canGenerateAiItineraryRpc(String userId);

  /// Get remaining AI generations for a user via RPC. Returns raw response.
  Future<dynamic> getRemainingAiGenerationsRpc(String userId);

  /// Increment AI usage for a user via RPC.
  Future<Map<String, dynamic>> incrementAiUsageRpc(String userId);

  /// Insert a row into ai_generation_logs.
  Future<void> insertAiGenerationLog(Map<String, dynamic> data);

  /// Fetch a user's AI generation log history newest first.
  Future<List<Map<String, dynamic>>> getAiGenerationHistory(
    String userId, {
    required int limit,
  });
}

/// Production implementation that talks to Supabase. Each method is a
/// minimal pass-through to the PostgREST chain and is exercised end-to-end
/// by integration / live tests, not unit tests.
class TemplateQueriesImpl implements TemplateQueries {
  TemplateQueriesImpl(this._client);
  final SupabaseClient _client;

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
    var query = _client.from('trip_templates').select().eq('is_active', true);

    if (category != null) {
      query = query.eq('category', category);
    }
    if (minDays != null) {
      query = query.gte('duration_days', minDays);
    }
    if (maxDays != null) {
      query = query.lte('duration_days', maxDays);
    }
    if (maxBudget != null) {
      query = query.or('budget_min.is.null,budget_min.lte.$maxBudget');
    }
    if (featuredOnly == true) {
      query = query.eq('is_featured', true);
    }
    if (search != null && search.isNotEmpty) {
      query = query.or(
        'name.ilike.%$search%,destination.ilike.%$search%,description.ilike.%$search%',
      );
    }

    final response = await query
        .order('is_featured', ascending: false)
        .order('use_count', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getFeaturedTemplates({
    required int limit,
  }) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('use_count', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPopularTemplates({
    required int limit,
  }) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('is_active', true)
        .order('use_count', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('id', templateId)
        .eq('is_active', true)
        .maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplateItineraryItems(
      String templateId) async {
    final response = await _client
        .from('template_itinerary_items')
        .select()
        .eq('template_id', templateId)
        .order('day_number')
        .order('order_index');
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplateChecklistsWithItems(
      String templateId) async {
    final response = await _client
        .from('template_checklists')
        .select('*, template_checklist_items(*)')
        .eq('template_id', templateId)
        .order('order_index');
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplatesByCategory(
    String categoryName, {
    required int limit,
  }) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('is_active', true)
        .eq('category', categoryName)
        .order('use_count', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Future<dynamic> applyTemplateToTripRpc({
    required String templateId,
    required String tripId,
    required String userId,
  }) async {
    return _client.rpc(
      'apply_template_to_trip',
      params: {
        'p_template_id': templateId,
        'p_trip_id': tripId,
        'p_user_id': userId,
      },
    );
  }

  @override
  Future<void> incrementTemplateUseCountRpc(String templateId) async {
    await _client.rpc(
      'increment_template_use_count',
      params: {'p_template_id': templateId},
    );
  }

  @override
  Future<Map<String, dynamic>> getOrCreateAiUsageRpc(String userId) async {
    final response = await _client.rpc(
      'get_or_create_ai_usage',
      params: {'p_user_id': userId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<dynamic> canGenerateAiItineraryRpc(String userId) async {
    return _client.rpc(
      'can_generate_ai_itinerary',
      params: {'p_user_id': userId},
    );
  }

  @override
  Future<dynamic> getRemainingAiGenerationsRpc(String userId) async {
    return _client.rpc(
      'get_remaining_ai_generations',
      params: {'p_user_id': userId},
    );
  }

  @override
  Future<Map<String, dynamic>> incrementAiUsageRpc(String userId) async {
    final response = await _client.rpc(
      'increment_ai_usage',
      params: {'p_user_id': userId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> insertAiGenerationLog(Map<String, dynamic> data) async {
    await _client.from('ai_generation_logs').insert(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getAiGenerationHistory(
    String userId, {
    required int limit,
  }) async {
    final response = await _client
        .from('ai_generation_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
