// Template Providers
//
// Riverpod providers for trip templates and AI usage.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/template_remote_datasource.dart';
import '../../domain/entities/trip_template.dart';
import '../../domain/entities/ai_usage.dart';

// =====================================================
// DATA SOURCE PROVIDER
// =====================================================

final templateDataSourceProvider = Provider<TemplateRemoteDataSource>((ref) {
  return TemplateRemoteDataSource(Supabase.instance.client);
});

// =====================================================
// TEMPLATE PROVIDERS
// =====================================================

/// All templates with optional filters
final templatesProvider = FutureProvider.family<List<TripTemplate>, TemplateFilters?>(
  (ref, filters) async {
    final dataSource = ref.watch(templateDataSourceProvider);
    return dataSource.getTemplates(
      category: filters?.category,
      minDays: filters?.minDays,
      maxDays: filters?.maxDays,
      maxBudget: filters?.maxBudget,
      featuredOnly: filters?.featuredOnly,
      search: filters?.search,
    );
  },
);

/// Featured templates for home page
final featuredTemplatesProvider = FutureProvider<List<TripTemplate>>((ref) async {
  final dataSource = ref.watch(templateDataSourceProvider);
  return dataSource.getFeaturedTemplates();
});

/// Popular templates
final popularTemplatesProvider = FutureProvider<List<TripTemplate>>((ref) async {
  final dataSource = ref.watch(templateDataSourceProvider);
  return dataSource.getPopularTemplates();
});

/// Single template by ID
final templateByIdProvider = FutureProvider.family<TripTemplate?, String>(
  (ref, templateId) async {
    final dataSource = ref.watch(templateDataSourceProvider);
    return dataSource.getTemplateById(templateId);
  },
);

/// Template with full details (itinerary, checklists)
final templateDetailsProvider = FutureProvider.family<TripTemplate?, String>(
  (ref, templateId) async {
    final dataSource = ref.watch(templateDataSourceProvider);
    return dataSource.getTemplateWithDetails(templateId);
  },
);

/// Templates by category
final templatesByCategoryProvider = FutureProvider.family<List<TripTemplate>, TemplateCategory>(
  (ref, category) async {
    final dataSource = ref.watch(templateDataSourceProvider);
    return dataSource.getTemplatesByCategory(category);
  },
);

// =====================================================
// AI USAGE PROVIDERS
// =====================================================

/// Current user's AI usage
final aiUsageProvider = FutureProvider<UserAiUsage?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final dataSource = ref.watch(templateDataSourceProvider);
  return dataSource.getOrCreateAiUsage(userId);
});

/// Check if current user can generate AI itinerary
final canGenerateAiProvider = FutureProvider<bool>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;

  final dataSource = ref.watch(templateDataSourceProvider);
  return dataSource.canGenerateAiItinerary(userId);
});

/// Remaining AI generations for current user
final remainingGenerationsProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 0;

  final dataSource = ref.watch(templateDataSourceProvider);
  return dataSource.getRemainingAiGenerations(userId);
});

// =====================================================
// TEMPLATE CONTROLLER STATE
// =====================================================

class TemplateControllerState {
  final bool isLoading;
  final String? error;

  const TemplateControllerState({
    this.isLoading = false,
    this.error,
  });

  TemplateControllerState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return TemplateControllerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// =====================================================
// TEMPLATE CONTROLLER (Riverpod 3.0 Pattern)
// =====================================================

class TemplateController extends Notifier<TemplateControllerState> {
  @override
  TemplateControllerState build() {
    return const TemplateControllerState();
  }

  /// Apply a template to a trip
  Future<bool> applyTemplateToTrip({
    required String templateId,
    required String tripId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final dataSource = ref.read(templateDataSourceProvider);
      final success = await dataSource.applyTemplateToTrip(
        templateId: templateId,
        tripId: tripId,
        userId: userId,
      );

      if (success) {
        // Invalidate template to update use count
        ref.invalidate(templateByIdProvider(templateId));
      }

      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Increment AI usage after generation
  Future<UserAiUsage?> incrementAiUsage() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final dataSource = ref.read(templateDataSourceProvider);
      final usage = await dataSource.incrementAiUsage(userId);

      // Refresh AI usage providers
      ref.invalidate(aiUsageProvider);
      ref.invalidate(canGenerateAiProvider);
      ref.invalidate(remainingGenerationsProvider);

      return usage;
    } catch (e) {
      return null;
    }
  }

  /// Log AI generation
  Future<void> logAiGeneration({
    required String destination,
    required int durationDays,
    double? budget,
    List<String>? interests,
    String? tripId,
    int? generationTimeMs,
    bool wasSuccessful = true,
    String? errorMessage,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final dataSource = ref.read(templateDataSourceProvider);
      await dataSource.logAiGeneration(
        userId: userId,
        destination: destination,
        durationDays: durationDays,
        budget: budget,
        interests: interests,
        tripId: tripId,
        generationTimeMs: generationTimeMs,
        wasSuccessful: wasSuccessful,
        errorMessage: errorMessage,
      );
    } catch (e) {
      // Silent fail for logging
    }
  }
}

final templateControllerProvider = NotifierProvider<TemplateController, TemplateControllerState>(() {
  return TemplateController();
});

// =====================================================
// FILTER MODEL
// =====================================================

class TemplateFilters {
  final TemplateCategory? category;
  final int? minDays;
  final int? maxDays;
  final double? maxBudget;
  final bool? featuredOnly;
  final String? search;

  const TemplateFilters({
    this.category,
    this.minDays,
    this.maxDays,
    this.maxBudget,
    this.featuredOnly,
    this.search,
  });

  TemplateFilters copyWith({
    TemplateCategory? category,
    int? minDays,
    int? maxDays,
    double? maxBudget,
    bool? featuredOnly,
    String? search,
  }) {
    return TemplateFilters(
      category: category ?? this.category,
      minDays: minDays ?? this.minDays,
      maxDays: maxDays ?? this.maxDays,
      maxBudget: maxBudget ?? this.maxBudget,
      featuredOnly: featuredOnly ?? this.featuredOnly,
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateFilters &&
        other.category == category &&
        other.minDays == minDays &&
        other.maxDays == maxDays &&
        other.maxBudget == maxBudget &&
        other.featuredOnly == featuredOnly &&
        other.search == search;
  }

  @override
  int get hashCode {
    return Object.hash(
      category,
      minDays,
      maxDays,
      maxBudget,
      featuredOnly,
      search,
    );
  }
}
