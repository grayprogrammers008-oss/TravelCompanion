// Template Remote Data Source
//
// Handles Supabase operations for trip templates and AI usage.
//
// All Supabase chain calls are routed through [TemplateQueries] so the
// datasource itself can be unit-tested with a fake. The default constructor
// wires up the production [TemplateQueriesImpl]; tests inject a fake.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip_template.dart';
import '../../domain/entities/ai_usage.dart';
import '../hardcoded_template_details.dart';
import 'template_queries.dart';

class TemplateRemoteDataSource {
  TemplateRemoteDataSource(
    SupabaseClient client, {
    TemplateQueries? queries,
  })  : _client = client,
        _queries = queries ?? TemplateQueriesImpl(client);

  // Kept for backward compatibility with code that constructs this DS by
  // passing a SupabaseClient. Production code does not read it directly.
  // ignore: unused_field
  final SupabaseClient _client;
  final TemplateQueries _queries;

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
    final rows = await _queries.getTemplates(
      category: category?.name,
      minDays: minDays,
      maxDays: maxDays,
      maxBudget: maxBudget,
      featuredOnly: featuredOnly,
      search: search,
      limit: limit,
      offset: offset,
    );
    return rows.map(TripTemplate.fromJson).toList();
  }

  /// Get featured templates for home page
  Future<List<TripTemplate>> getFeaturedTemplates({int limit = 5}) async {
    final rows = await _queries.getFeaturedTemplates(limit: limit);
    return rows.map(TripTemplate.fromJson).toList();
  }

  /// Get popular templates
  Future<List<TripTemplate>> getPopularTemplates({int limit = 10}) async {
    final rows = await _queries.getPopularTemplates(limit: limit);
    return rows.map(TripTemplate.fromJson).toList();
  }

  /// Get a single template by ID
  Future<TripTemplate?> getTemplateById(String templateId) async {
    final response = await _queries.getTemplateById(templateId);
    if (response == null) return null;
    return TripTemplate.fromJson(response);
  }

  /// Get template with all related data (itinerary, checklists)
  Future<TripTemplate?> getTemplateWithDetails(String templateId) async {
    final template = await getTemplateById(templateId);
    if (template == null) return null;

    final itineraryRows =
        await _queries.getTemplateItineraryItems(templateId);
    final itineraryItems =
        itineraryRows.map(TemplateItineraryItem.fromJson).toList();

    final checklistRows =
        await _queries.getTemplateChecklistsWithItems(templateId);
    final checklists = checklistRows.map((row) {
      final json = Map<String, dynamic>.from(row);
      final items = (json['template_checklist_items'] as List?)
          ?.map((i) =>
              TemplateChecklistItem.fromJson(Map<String, dynamic>.from(i as Map)))
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
    final rows = await _queries.getTemplatesByCategory(
      category.name,
      limit: limit,
    );
    return rows.map(TripTemplate.fromJson).toList();
  }

  /// Apply template to a trip
  Future<bool> applyTemplateToTrip({
    required String templateId,
    required String tripId,
    required String userId,
  }) async {
    debugPrint('📋 DataSource: Calling apply_template_to_trip RPC');
    debugPrint('   templateId: $templateId');
    debugPrint('   tripId: $tripId');
    debugPrint('   userId: $userId');

    try {
      final response = await _queries.applyTemplateToTripRpc(
        templateId: templateId,
        tripId: tripId,
        userId: userId,
      );

      debugPrint(
          '📋 DataSource: RPC response = $response (type: ${response.runtimeType})');
      return response == true;
    } catch (e, stack) {
      debugPrint('❌ DataSource: RPC error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Fallback: apply hardcoded template data directly to a trip when DB tables are empty
  Future<bool> applyHardcodedTemplateToTrip({
    required String templateId,
    required String tripId,
    required String userId,
  }) async {
    final details = HardcodedTemplateDetails.getById(templateId);
    if (details == null) return false;

    try {
      // Get trip start date
      final tripRow = await _client
          .from('trips')
          .select('start_date')
          .eq('id', tripId)
          .single();
      final startDate = tripRow['start_date'] != null
          ? DateTime.parse(tripRow['start_date'] as String)
          : DateTime.now();

      // Insert itinerary items
      for (final item in details.itineraryItems) {
        DateTime? startTime;
        DateTime? endTime;
        if (item.startTime != null) {
          final p = item.startTime!.split(':');
          final d = startDate.add(Duration(days: item.dayNumber - 1));
          startTime = DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
        }
        if (item.endTime != null) {
          final p = item.endTime!.split(':');
          final d = startDate.add(Duration(days: item.dayNumber - 1));
          endTime = DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
        }

        await _client.from('itinerary_items').insert({
          'trip_id': tripId,
          'day_number': item.dayNumber,
          'order_index': item.orderIndex,
          'title': item.title,
          'description': item.description,
          'location': item.location,
          'start_time': startTime?.toIso8601String(),
          'end_time': endTime?.toIso8601String(),
          'created_by': userId,
        });
      }

      // Insert checklists and their items
      for (final checklist in details.checklists) {
        final clRow = await _client
            .from('checklists')
            .insert({
              'trip_id': tripId,
              'name': checklist.name,
              'created_by': userId,
            })
            .select('id')
            .single();
        final newChecklistId = clRow['id'] as String;

        if (checklist.items != null) {
          for (final item in checklist.items!) {
            await _client.from('checklist_items').insert({
              'checklist_id': newChecklistId,
              'content': item.content,
              'is_completed': false,
              'order_index': item.orderIndex,
            });
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Hardcoded template applied to trip $tripId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to apply hardcoded template: $e');
      }
      return false;
    }
  }

  /// Increment template use count
  Future<void> incrementTemplateUseCount(String templateId) async {
    await _queries.incrementTemplateUseCountRpc(templateId);
  }

  // =====================================================
  // AI USAGE
  // =====================================================

  /// Get or create user AI usage record
  Future<UserAiUsage> getOrCreateAiUsage(String userId) async {
    final response = await _queries.getOrCreateAiUsageRpc(userId);
    return UserAiUsage.fromJson(response);
  }

  /// Check if user can generate AI itinerary
  Future<bool> canGenerateAiItinerary(String userId) async {
    try {
      final response = await _queries.canGenerateAiItineraryRpc(userId);
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
      final response = await _queries.getRemainingAiGenerationsRpc(userId);
      return response as int;
    } catch (e) {
      // If function doesn't exist, return 5 (default free tier)
      // This allows the app to work before database migration is applied
      return 5;
    }
  }

  /// Increment AI usage after generation
  Future<UserAiUsage> incrementAiUsage(String userId) async {
    final response = await _queries.incrementAiUsageRpc(userId);
    return UserAiUsage.fromJson(response);
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
    await _queries.insertAiGenerationLog({
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
    final rows = await _queries.getAiGenerationHistory(userId, limit: limit);
    return rows.map(AiGenerationLog.fromJson).toList();
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
