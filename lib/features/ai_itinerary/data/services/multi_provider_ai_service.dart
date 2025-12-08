// Multi-Provider AI Service
//
// Handles automatic failover between AI providers:
// 1. Primary: Groq (1,000 requests/day free)
// 2. Fallback: Gemini (25 requests/day free)
//
// Total: ~1,025 free AI generations per day

import 'package:flutter/foundation.dart';
import 'groq_service.dart';
import 'gemini_service.dart';
import '../../domain/entities/ai_itinerary.dart';

enum AiProvider { groq, gemini }

class MultiProviderAiService {
  final GroqService _groqService;
  final GeminiService _geminiService;

  MultiProviderAiService({
    required GroqService groqService,
    required GeminiService geminiService,
  })  : _groqService = groqService,
        _geminiService = geminiService;

  /// Generate complete trip plan with automatic failover
  /// Tries Groq first (1,000 RPD), falls back to Gemini (25 RPD) if rate limited
  Future<AiCompleteTripPlan> generateCompleteTripPlan({
    required String voicePrompt,
    required String destination,
    required int durationDays,
    String? tripType,
    double? budget,
    String currency = 'INR',
    List<String> interests = const [],
    int? groupSize,
  }) async {
    debugPrint('🔄 MultiProviderAiService: Starting trip plan generation');
    debugPrint('   Primary: Groq (1,000 RPD)');
    debugPrint('   Fallback: Gemini (25 RPD)');

    // Try Groq first (primary - 1,000 requests/day)
    try {
      debugPrint('🚀 Trying Groq (primary provider)...');
      debugPrint('   Parameters:');
      debugPrint('     - voicePrompt: $voicePrompt');
      debugPrint('     - destination: $destination');
      debugPrint('     - durationDays: $durationDays');
      final plan = await _groqService.generateCompleteTripPlan(
        voicePrompt: voicePrompt,
        destination: destination,
        durationDays: durationDays,
        tripType: tripType,
        budget: budget,
        currency: currency,
        interests: interests,
        groupSize: groupSize,
      );
      debugPrint('✅ Groq succeeded!');
      debugPrint('   Trip name: ${plan.tripName}');
      debugPrint('   Days: ${plan.days.length}');
      return plan;
    } catch (groqError, groqStack) {
      debugPrint('⚠️ Groq failed: $groqError');
      debugPrint('   Groq stack: $groqStack');
      debugPrint('🔄 Falling back to Gemini...');

      // Fallback to Gemini (25 requests/day)
      try {
        final plan = await _geminiService.generateCompleteTripPlan(
          voicePrompt: voicePrompt,
          destination: destination,
          durationDays: durationDays,
          tripType: tripType,
          budget: budget,
          currency: currency,
          interests: interests,
          groupSize: groupSize,
        );
        debugPrint('✅ Gemini fallback succeeded!');
        debugPrint('   Trip name: ${plan.tripName}');
        debugPrint('   Days: ${plan.days.length}');
        return plan;
      } catch (geminiError, geminiStack) {
        debugPrint('❌ Both providers failed!');
        debugPrint('   Groq error: $groqError');
        debugPrint('   Gemini error: $geminiError');
        debugPrint('   Gemini stack: $geminiStack');

        // Throw a user-friendly error with details for debugging
        throw Exception('AI service is currently unavailable. Groq: $groqError | Gemini: $geminiError');
      }
    }
  }

  /// Generate complete trip plan from raw voice input with automatic failover
  /// AI extracts destination, duration, and all trip details from natural language
  /// Primary: Groq (1,000 RPD) -> Fallback: Gemini (25 RPD)
  Future<AiCompleteTripPlan> generateCompleteTripPlanFromVoice({
    required String voiceInput,
  }) async {
    debugPrint('🔄 MultiProviderAiService: Starting voice-based trip generation');
    debugPrint('   Voice input: $voiceInput');
    debugPrint('   Primary: Groq (1,000 RPD)');
    debugPrint('   Fallback: Gemini (25 RPD)');

    // Try Groq first (primary - 1,000 requests/day)
    try {
      debugPrint('🚀 Trying Groq (primary provider)...');
      final plan = await _groqService.generateCompleteTripPlanFromVoice(
        voiceInput: voiceInput,
      );
      debugPrint('✅ Groq succeeded!');
      debugPrint('   Destination: ${plan.destination}');
      debugPrint('   Trip name: ${plan.tripName}');
      return plan;
    } catch (groqError, groqStack) {
      debugPrint('⚠️ Groq failed: $groqError');
      debugPrint('   Groq stack: $groqStack');
      debugPrint('🔄 Falling back to Gemini...');

      // Fallback to Gemini (25 requests/day)
      try {
        final plan = await _geminiService.generateCompleteTripPlanFromVoice(
          voiceInput: voiceInput,
        );
        debugPrint('✅ Gemini fallback succeeded!');
        debugPrint('   Destination: ${plan.destination}');
        debugPrint('   Trip name: ${plan.tripName}');
        return plan;
      } catch (geminiError, geminiStack) {
        debugPrint('❌ Both providers failed!');
        debugPrint('   Groq error: $groqError');
        debugPrint('   Gemini error: $geminiError');
        debugPrint('   Gemini stack: $geminiStack');

        throw Exception('AI service is currently unavailable. Groq: $groqError | Gemini: $geminiError');
      }
    }
  }

  /// Generate itinerary only (uses Gemini directly as it has this method)
  Future<AiGeneratedItinerary> generateItinerary(AiItineraryRequest request) async {
    debugPrint('🔄 MultiProviderAiService: Generating itinerary (Gemini)');
    return _geminiService.generateItinerary(request);
  }

  /// Generate checklist items (uses Gemini directly as it has this method)
  Future<List<AiChecklistItem>> generateChecklistItems({
    required String voicePrompt,
    required String destination,
    required String tripType,
    int? durationDays,
  }) async {
    debugPrint('🔄 MultiProviderAiService: Generating checklist (Gemini)');
    return _geminiService.generateChecklistItems(
      voicePrompt: voicePrompt,
      destination: destination,
      tripType: tripType,
      durationDays: durationDays,
    );
  }
}
