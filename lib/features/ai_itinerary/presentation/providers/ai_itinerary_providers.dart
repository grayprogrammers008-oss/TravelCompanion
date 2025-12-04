// AI Itinerary Providers
//
// Riverpod providers for AI itinerary generation.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/gemini_service.dart';
import '../../domain/entities/ai_itinerary.dart';
import '../../../templates/presentation/providers/template_providers.dart';

// =====================================================
// CONFIGURATION
// =====================================================

/// Gemini API Key - Should be stored securely in production
/// For development, you can set this directly
/// In production, use environment variables or secure storage
const String _geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'AIzaSyBTQDAUYsexJQbtq-sZmMaJ1ypF6dEwn8M',
);

// =====================================================
// SERVICE PROVIDER
// =====================================================

final geminiServiceProvider = Provider<GeminiService>((ref) {
  if (_geminiApiKey.isEmpty) {
    throw Exception('Gemini API key not configured');
  }
  return GeminiService(_geminiApiKey);
});

// =====================================================
// STATE
// =====================================================

class AiItineraryState {
  final bool isLoading;
  final AiGeneratedItinerary? itinerary;
  final String? error;
  final int? remainingGenerations;

  const AiItineraryState({
    this.isLoading = false,
    this.itinerary,
    this.error,
    this.remainingGenerations,
  });

  AiItineraryState copyWith({
    bool? isLoading,
    AiGeneratedItinerary? itinerary,
    bool clearItinerary = false,
    String? error,
    int? remainingGenerations,
  }) {
    return AiItineraryState(
      isLoading: isLoading ?? this.isLoading,
      itinerary: clearItinerary ? null : (itinerary ?? this.itinerary),
      error: error,
      remainingGenerations: remainingGenerations ?? this.remainingGenerations,
    );
  }
}

// =====================================================
// CONTROLLER
// =====================================================

class AiItineraryController extends Notifier<AiItineraryState> {
  @override
  AiItineraryState build() {
    return const AiItineraryState();
  }

  /// Generate an AI itinerary
  Future<AiGeneratedItinerary?> generateItinerary(AiItineraryRequest request) async {
    debugPrint('🔷 AiItineraryController.generateItinerary() called');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    debugPrint('👤 User ID: $userId');

    if (userId == null) {
      debugPrint('❌ User not logged in');
      state = state.copyWith(error: 'Please login to generate itinerary');
      return null;
    }

    // Check if user can generate
    debugPrint('🔍 Checking if user can generate...');
    final templateController = ref.read(templateControllerProvider.notifier);
    final canGenerate = await ref.read(canGenerateAiProvider.future);
    debugPrint('✅ Can generate: $canGenerate');

    if (!canGenerate) {
      debugPrint('❌ User has reached limit');
      state = state.copyWith(
        error: 'You have reached your free limit. Upgrade to Premium for unlimited AI generations.',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('⏳ Set loading state to true');

    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🤖 Calling Gemini API...');
      final geminiService = ref.read(geminiServiceProvider);
      final itinerary = await geminiService.generateItinerary(request);
      debugPrint('✅ Gemini API returned successfully');

      stopwatch.stop();

      // Increment usage
      await templateController.incrementAiUsage();

      // Log generation
      await templateController.logAiGeneration(
        destination: request.destination,
        durationDays: request.durationDays,
        budget: request.budget,
        interests: request.interests,
        generationTimeMs: stopwatch.elapsedMilliseconds,
        wasSuccessful: true,
      );

      // Get updated remaining generations
      final remaining = await ref.read(remainingGenerationsProvider.future);

      state = state.copyWith(
        isLoading: false,
        itinerary: itinerary,
        remainingGenerations: remaining,
      );

      return itinerary;
    } catch (e, stackTrace) {
      stopwatch.stop();

      // Debug logging
      debugPrint('❌ AI Itinerary Generation Error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Log failed generation (ignore errors from logging)
      try {
        await templateController.logAiGeneration(
          destination: request.destination,
          durationDays: request.durationDays,
          budget: request.budget,
          interests: request.interests,
          generationTimeMs: stopwatch.elapsedMilliseconds,
          wasSuccessful: false,
          errorMessage: e.toString(),
        );
      } catch (_) {
        // Ignore logging errors
      }

      // Show user-friendly error message
      String errorMessage = 'Failed to generate itinerary. Please try again.';
      if (e.toString().contains('API')) {
        errorMessage = 'AI service is temporarily unavailable. Please try again later.';
      } else if (e.toString().contains('parse')) {
        errorMessage = 'Error processing AI response. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return null;
    }
  }

  /// Clear the current itinerary
  void clearItinerary() {
    state = state.copyWith(clearItinerary: true, error: null);
  }

  /// Update remaining generations count
  Future<void> refreshRemainingGenerations() async {
    final remaining = await ref.read(remainingGenerationsProvider.future);
    state = state.copyWith(remainingGenerations: remaining);
  }
}

final aiItineraryControllerProvider =
    NotifierProvider<AiItineraryController, AiItineraryState>(() {
  return AiItineraryController();
});

// =====================================================
// INTEREST OPTIONS
// =====================================================

/// Available interest options for itinerary generation
const List<String> availableInterests = [
  'Adventure',
  'Culture & History',
  'Food & Cuisine',
  'Photography',
  'Nature',
  'Wildlife',
  'Beaches',
  'Mountains',
  'Temples',
  'Shopping',
  'Nightlife',
  'Relaxation',
  'Water Sports',
  'Trekking',
  'Art & Museums',
];

/// Travel style options
const List<String> travelStyles = [
  'Budget',
  'Moderate',
  'Luxury',
];
