// Template Remote Data Source
//
// Handles Supabase operations for trip templates and AI usage.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip_template.dart';
import '../../domain/entities/ai_usage.dart';

class TemplateRemoteDataSource {
  final SupabaseClient _client;

  TemplateRemoteDataSource(this._client);

  // =====================================================
  // TRIP TEMPLATES
  // =====================================================

  /// Get all active templates with optional filters
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
    var query = _client
        .from('trip_templates')
        .select()
        .eq('is_active', true);

    if (category != null) {
      query = query.eq('category', category.name);
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
        .map((e) => TripTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get featured templates for home page
  Future<List<TripTemplate>> getFeaturedTemplates({int limit = 5}) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('is_active', true)
        .eq('is_featured', true)
        .order('use_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => TripTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get popular templates
  Future<List<TripTemplate>> getPopularTemplates({int limit = 10}) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('is_active', true)
        .order('use_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => TripTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single template by ID
  Future<TripTemplate?> getTemplateById(String templateId) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('id', templateId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return TripTemplate.fromJson(response);
  }

  /// Get template with all related data (itinerary, checklists)
  Future<TripTemplate?> getTemplateWithDetails(String templateId) async {
    final template = await getTemplateById(templateId);
    if (template == null) return null;

    // Get itinerary items
    final itineraryResponse = await _client
        .from('template_itinerary_items')
        .select()
        .eq('template_id', templateId)
        .order('day_number')
        .order('order_index');

    final itineraryItems = (itineraryResponse as List)
        .map((e) => TemplateItineraryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Get checklists with items
    final checklistsResponse = await _client
        .from('template_checklists')
        .select('*, template_checklist_items(*)')
        .eq('template_id', templateId)
        .order('order_index');

    final checklists = (checklistsResponse as List).map((e) {
      final json = e as Map<String, dynamic>;
      final items = (json['template_checklist_items'] as List?)
          ?.map((i) => TemplateChecklistItem.fromJson(i as Map<String, dynamic>))
          .toList();
      json.remove('template_checklist_items');
      return TemplateChecklist.fromJson(json).copyWith(items: items);
    }).toList();

    return template.copyWith(
      itineraryItems: itineraryItems,
      checklists: checklists,
    );
  }

  /// Get templates by category
  Future<List<TripTemplate>> getTemplatesByCategory(
    TemplateCategory category, {
    int limit = 20,
  }) async {
    final response = await _client
        .from('trip_templates')
        .select()
        .eq('is_active', true)
        .eq('category', category.name)
        .order('use_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => TripTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Apply template to a trip
  Future<bool> applyTemplateToTrip({
    required String templateId,
    required String tripId,
    required String userId,
  }) async {
    final response = await _client.rpc(
      'apply_template_to_trip',
      params: {
        'p_template_id': templateId,
        'p_trip_id': tripId,
        'p_user_id': userId,
      },
    );

    return response == true;
  }

  /// Increment template use count
  Future<void> incrementTemplateUseCount(String templateId) async {
    await _client.rpc(
      'increment_template_use_count',
      params: {'p_template_id': templateId},
    );
  }

  // =====================================================
  // AI USAGE
  // =====================================================

  /// Get or create user AI usage record
  Future<UserAiUsage> getOrCreateAiUsage(String userId) async {
    final response = await _client.rpc(
      'get_or_create_ai_usage',
      params: {'p_user_id': userId},
    );

    return UserAiUsage.fromJson(response as Map<String, dynamic>);
  }

  /// Check if user can generate AI itinerary
  Future<bool> canGenerateAiItinerary(String userId) async {
    try {
      final response = await _client.rpc(
        'can_generate_ai_itinerary',
        params: {'p_user_id': userId},
      );
      return response == true;
    } catch (e) {
      // If function doesn't exist or any error, allow generation
      // This allows the app to work before database migration is applied
      return true;
    }
  }

  /// Get remaining AI generations
  Future<int> getRemainingAiGenerations(String userId) async {
    try {
      final response = await _client.rpc(
        'get_remaining_ai_generations',
        params: {'p_user_id': userId},
      );
      return response as int;
    } catch (e) {
      // If function doesn't exist, return 5 (default free tier)
      // This allows the app to work before database migration is applied
      return 5;
    }
  }

  /// Increment AI usage after generation
  Future<UserAiUsage> incrementAiUsage(String userId) async {
    final response = await _client.rpc(
      'increment_ai_usage',
      params: {'p_user_id': userId},
    );

    return UserAiUsage.fromJson(response as Map<String, dynamic>);
  }

  /// Log AI generation for analytics
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
    await _client.from('ai_generation_logs').insert({
      'user_id': userId,
      'destination': destination,
      'duration_days': durationDays,
      'budget': budget,
      'interests': interests ?? [],
      'trip_id': tripId,
      'generation_time_ms': generationTimeMs,
      'was_successful': wasSuccessful,
      'error_message': errorMessage,
    });
  }

  /// Get user's generation history
  Future<List<AiGenerationLog>> getGenerationHistory(
    String userId, {
    int limit = 20,
  }) async {
    final response = await _client
        .from('ai_generation_logs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => AiGenerationLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// Extension for TemplateChecklist to add copyWith
extension TemplateChecklistCopyWith on TemplateChecklist {
  TemplateChecklist copyWith({
    String? id,
    String? templateId,
    String? name,
    String? icon,
    int? orderIndex,
    DateTime? createdAt,
    List<TemplateChecklistItem>? items,
  }) {
    return TemplateChecklist(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
