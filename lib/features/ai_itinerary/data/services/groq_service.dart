// Groq AI Service
//
// Primary AI provider with 1,000 requests/day free tier.
// Uses Llama 3.3 70B Versatile for high-quality trip planning.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Using Llama 3.3 70B Versatile (latest version, replaces 3.1)
  static const String _model = 'llama-3.3-70b-versatile';

  final String _apiKey;

  GroqService(this._apiKey);

  /// Generate complete trip plan using Groq API
  /// Includes retry logic with exponential backoff for rate limiting (429 errors)
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
    debugPrint('🚀 GroqService.generateCompleteTripPlan() called');
    debugPrint('🎤 Voice prompt: $voicePrompt');
    debugPrint('📍 Destination: $destination');
    debugPrint('📅 Duration: $durationDays days');

    final prompt = _buildCompleteTripPrompt(
      voicePrompt: voicePrompt,
      destination: destination,
      durationDays: durationDays,
      tripType: tripType,
      budget: budget,
      currency: currency,
      interests: interests,
      groupSize: groupSize,
    );

    debugPrint('📝 Prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Groq API (attempt ${retryCount + 1}/${maxRetries + 1})...');
      debugPrint('🔑 Using model: $_model');

      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert travel planner. You MUST respond with valid JSON only. Do not include any markdown, code blocks, or explanations. Only output the raw JSON object.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 8192,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Response status code: ${response.statusCode}');

      // Handle rate limiting (429) with exponential backoff
      if (response.statusCode == 429) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Groq: Max retries exceeded for rate limiting');
          throw Exception('Groq rate limited: 429');
        }
        debugPrint('⏳ Groq rate limited (429). Waiting ${delaySeconds}s before retry $retryCount/$maxRetries...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      // Handle server errors with retry
      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Groq: Max retries exceeded for server error');
          throw Exception('Groq server error: ${response.statusCode}');
        }
        debugPrint('⏳ Groq server error (${response.statusCode}). Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Groq API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        // Try to extract error message from response
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
          debugPrint('Error detail: $errorDetail');
        } catch (_) {}
        throw Exception('Groq API error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('✅ Groq API returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonResponse['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw Exception('No response from Groq AI');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('Empty response from Groq AI');
      }

      debugPrint('📄 Generated text length: ${content.length} chars');

      try {
        final planJson = jsonDecode(content) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('✅ Successfully parsed complete trip plan from Groq');
        debugPrint('   - Trip name: ${plan.tripName}');
        debugPrint('   - Days: ${plan.days.length}');
        debugPrint('   - Packing items: ${plan.packingList.length}');
        debugPrint('   - Tips: ${plan.tips.length}');
        return plan;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to parse Groq response: $content');
          debugPrint('Error: $e');
        }
        throw Exception('Failed to parse Groq AI response');
      }
    }

    throw Exception('Failed to generate trip plan after multiple attempts');
  }

  /// Build prompt for complete trip plan generation
  String _buildCompleteTripPrompt({
    required String voicePrompt,
    required String destination,
    required int durationDays,
    String? tripType,
    double? budget,
    String currency = 'INR',
    List<String> interests = const [],
    int? groupSize,
  }) {
    final budgetStr = budget != null
        ? 'Budget: ₹${budget.toStringAsFixed(0)} $currency'
        : 'Budget: Flexible';

    final interestsStr = interests.isNotEmpty
        ? 'Interests: ${interests.join(", ")}'
        : '';

    final styleStr = tripType != null ? 'Trip Type: $tripType' : '';
    final groupStr = groupSize != null ? 'Group Size: $groupSize people' : '';

    return '''
You are an expert travel planner. Based on the user's voice request, generate a COMPLETE trip plan including itinerary AND packing list.

USER'S VOICE REQUEST: "$voicePrompt"

TRIP DETAILS:
- Destination: $destination
- Duration: $durationDays days
- $budgetStr
${interestsStr.isNotEmpty ? '- $interestsStr' : ''}
${styleStr.isNotEmpty ? '- $styleStr' : ''}
${groupStr.isNotEmpty ? '- $groupStr' : ''}

REQUIREMENTS:
1. **IMPORTANT: Create a FUN, PEPPY, CREATIVE trip name** - NOT just "Trip to [destination]". Use alliteration, rhymes, wordplay, or evocative language. Examples:
   - "Goan Paradise Escape" instead of "Trip to Goa"
   - "Kerala Backwater Bliss" instead of "Trip to Kerala"
   - "Majestic Manali Mountains" instead of "Trip to Manali"
   - "Rajasthan Royal Rendezvous" instead of "Trip to Jaipur"
   - "Himalayan Heights Adventure" instead of "Trip to Ladakh"
2. Generate a realistic, well-paced day-by-day itinerary
3. Include specific places, restaurants, and activities with times
4. Add estimated costs in INR for each activity
5. Create a comprehensive packing list tailored to the destination
6. Include practical travel tips

RESPOND WITH VALID JSON in this exact format:
{
  "trip_name": "Creative peppy name (NEVER use 'Trip to X' format!)",
  "summary": "A brief 2-3 sentence summary of the trip",
  "days": [
    {
      "day_number": 1,
      "title": "Day title (e.g., 'Arrival & Beach Vibes')",
      "description": "Brief overview of the day",
      "activities": [
        {
          "title": "Activity name",
          "description": "What to do here",
          "location": "Specific location name",
          "start_time": "09:00",
          "end_time": "11:00",
          "duration_minutes": 120,
          "category": "sightseeing|food|transport|activity|accommodation",
          "estimated_cost": 500,
          "tip": "Helpful tip for this activity"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "title": "Item name (e.g., Passport, Sunscreen SPF 50)",
      "category": "documents|clothing|toiletries|electronics|medicines|accessories|misc",
      "is_essential": true,
      "quantity": 1,
      "notes": "Optional helpful note"
    }
  ],
  "tips": [
    "General travel tip 1",
    "General travel tip 2"
  ]
}

Generate the complete trip plan now:
''';
  }

  /// Generate complete trip plan from raw voice input
  /// AI extracts destination, duration, and all trip details from natural language
  /// Supports any language the user speaks
  Future<AiCompleteTripPlan> generateCompleteTripPlanFromVoice({
    required String voiceInput,
  }) async {
    debugPrint('🚀 GroqService.generateCompleteTripPlanFromVoice() called');
    debugPrint('🎤 Voice input: $voiceInput');

    final prompt = _buildVoiceParsingPrompt(voiceInput: voiceInput);
    debugPrint('📝 Voice parsing prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Groq API (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert travel planner. You MUST respond with valid JSON only. Do not include any markdown, code blocks, or explanations. Only output the raw JSON object.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 8192,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Response status code: ${response.statusCode}');

      if (response.statusCode == 429) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq rate limited: 429');
        }
        debugPrint('⏳ Rate limited. Waiting ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error: ${response.statusCode}');
        }
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Groq API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('✅ Groq API returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonResponse['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw Exception('No response from Groq AI');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('Empty response from Groq AI');
      }

      debugPrint('📄 Generated text length: ${content.length} chars');

      try {
        final planJson = jsonDecode(content) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('✅ Successfully parsed complete trip plan from voice');
        debugPrint('   - Destination: ${plan.destination}');
        debugPrint('   - Duration: ${plan.durationDays} days');
        debugPrint('   - Trip name: ${plan.tripName}');
        return plan;
      } catch (e) {
        debugPrint('❌ Failed to parse Groq response: $content');
        debugPrint('Error: $e');
        throw Exception('Failed to parse Groq AI response');
      }
    }

    throw Exception('Failed to generate trip plan after multiple attempts');
  }

  /// Build prompt that lets AI extract everything from voice input
  String _buildVoiceParsingPrompt({required String voiceInput}) {
    return '''
You are an expert travel planner. The user has spoken their trip request in natural language.
Your job is to:
1. UNDERSTAND what they said (could be in any language - English, Hindi, Tamil, etc.)
2. EXTRACT the destination, duration, trip type, and preferences
3. GENERATE a complete trip plan

USER'S VOICE INPUT: "$voiceInput"

INSTRUCTIONS:
1. First, identify the DESTINATION from what the user said
2. Identify the DURATION (number of days) - if not specified, assume 3 days
3. Identify any trip preferences (family, adventure, romantic, budget, etc.)
4. Generate a creative, peppy trip name (NOT "Trip to X")
5. Create a realistic day-by-day itinerary with specific places in India
6. Include a comprehensive packing list
7. Add practical travel tips
8. All costs should be in INR (Indian Rupees)

RESPOND WITH VALID JSON in this exact format:
{
  "destination": "The destination extracted from user input",
  "duration_days": 3,
  "trip_name": "Creative peppy name (e.g., 'Goan Paradise Escape', 'Kerala Backwater Bliss')",
  "summary": "A brief 2-3 sentence summary of the trip",
  "days": [
    {
      "day_number": 1,
      "title": "Day title (e.g., 'Arrival & Beach Vibes')",
      "description": "Brief overview of the day",
      "activities": [
        {
          "title": "Activity name",
          "description": "What to do here",
          "location": "Specific location name",
          "start_time": "09:00",
          "end_time": "11:00",
          "duration_minutes": 120,
          "category": "sightseeing|food|transport|activity|accommodation",
          "estimated_cost": 500,
          "tip": "Helpful tip"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "title": "Item name",
      "category": "documents|clothing|toiletries|electronics|medicines|accessories|misc",
      "is_essential": true,
      "quantity": 1,
      "notes": "Optional note"
    }
  ],
  "tips": [
    "Travel tip 1",
    "Travel tip 2"
  ]
}

Generate the complete trip plan now:
''';
  }
}
