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
You are an expert travel planner with deep knowledge of Indian destinations. Based on the user's voice request, generate a COMPLETE trip plan including itinerary AND packing list.

USER'S VOICE REQUEST: "$voicePrompt"

TRIP DETAILS:
- Destination: $destination
- Duration: $durationDays days
- $budgetStr
${interestsStr.isNotEmpty ? '- $interestsStr' : ''}
${styleStr.isNotEmpty ? '- $styleStr' : ''}
${groupStr.isNotEmpty ? '- $groupStr' : ''}

CRITICAL PLANNING REQUIREMENTS (FOLLOW STRICTLY):

**1. TRIP NAME:**
- Create a FUN, PEPPY, CREATIVE trip name - NOT "Trip to [destination]"
- Use alliteration, rhymes, wordplay, or evocative language
- Examples: "Goan Paradise Escape", "Kerala Backwater Bliss", "Majestic Manali Mountains"

**2. REALISTIC TIME MANAGEMENT:**
- Day 1: Start activities from check-in time (usually 2-3 PM) or arrival time, NOT early morning
- Last Day: End by checkout time (usually 11 AM-12 PM), plan only morning activities
- Include realistic TRAVEL TIME between locations (30-60 mins for city travel, 2-4 hours for inter-city)
- Add 15-30 min buffer between activities for unexpected delays
- Limit to 4-5 major activities per day to avoid exhaustion

**3. LOGICAL ACTIVITY SEQUENCING:**
- MORNING (6 AM-12 PM): Nature walks, temples, sunrise points, outdoor activities when cooler
- AFTERNOON (12 PM-4 PM): Indoor activities (museums, restaurants, shopping, rest time during peak heat)
- EVENING (4 PM-9 PM): Sunset points, markets, cultural shows, dinner
- Group nearby locations together to minimize travel
- Don't schedule strenuous activities after heavy meals

**4. SENSIBLE DAILY STRUCTURE:**
- Breakfast: 7:30-9:00 AM
- Lunch: 12:30-2:00 PM
- Dinner: 7:30-9:00 PM
- Include 1-2 hours rest/free time in afternoon (especially in hot climates)
- Don't pack every minute - allow spontaneity

**5. WEATHER & SEASON AWARENESS:**
- Consider current month's typical weather for the destination
- Suggest appropriate clothing and gear
- Adjust outdoor activity timing based on climate
- Include rain contingency plans for monsoon destinations

**6. PRACTICAL COST ESTIMATES (2024-2025 PRICES IN INR):**
- Entry fees: ₹50-500 for local sites, ₹500-1500 for premium attractions
- Meals: ₹200-400 budget, ₹500-1000 mid-range, ₹1500+ fine dining
- Transport: ₹500-1500/day for local travel
- Be realistic - don't underestimate costs

**7. SMART PACKING LIST:**
- ONLY include items ACTUALLY needed for this specific trip
- Consider: destination climate, planned activities, trip duration
- Don't add generic items that aren't relevant
- Specify quantities based on trip length (e.g., "3 t-shirts" for 3-day trip)
- Group by category: documents, clothing, toiletries, electronics, medicines, accessories

**8. ACTIONABLE TIPS:**
- Include destination-specific advice (local customs, scams to avoid, best transport options)
- Mention best times to visit specific attractions (e.g., "Visit Taj Mahal at sunrise to avoid crowds")
- Include emergency info (nearest hospital, police station, emergency numbers)

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
You are an expert travel planner with deep knowledge of Indian destinations. The user has spoken their trip request in natural language.

Your job is to:
1. UNDERSTAND what they said (could be in any language - English, Hindi, Tamil, etc.)
2. EXTRACT the destination, duration, trip type, and preferences
3. GENERATE a sensible, practical, and well-paced trip plan

USER'S VOICE INPUT: "$voiceInput"

CRITICAL PLANNING REQUIREMENTS (FOLLOW STRICTLY):

**1. EXTRACT FROM VOICE:**
- Identify the DESTINATION from what the user said
- Identify the DURATION (number of days) - if not specified, assume 3 days
- Identify trip preferences (family, adventure, romantic, budget, solo, etc.)

**2. TRIP NAME:**
- Generate a creative, peppy trip name (NOT "Trip to X")
- Use alliteration, rhymes, wordplay: "Goan Paradise Escape", "Kerala Backwater Bliss"

**3. REALISTIC TIME MANAGEMENT:**
- Day 1: Start activities from arrival/check-in time (2-3 PM), NOT early morning
- Last Day: End by checkout (11 AM-12 PM), plan only morning activities
- Include realistic TRAVEL TIME between locations (30-60 mins city, 2-4 hours inter-city)
- Add 15-30 min buffer between activities
- Limit to 4-5 major activities per day

**4. LOGICAL ACTIVITY SEQUENCING:**
- MORNING (6-12): Nature walks, temples, sunrise points, outdoor activities
- AFTERNOON (12-4): Indoor activities, museums, restaurants, rest time (hot climates)
- EVENING (4-9): Sunset points, markets, cultural shows, dinner
- Group nearby locations together
- Don't schedule strenuous activities after heavy meals

**5. SENSIBLE DAILY STRUCTURE:**
- Breakfast: 7:30-9:00 AM | Lunch: 12:30-2:00 PM | Dinner: 7:30-9:00 PM
- Include 1-2 hours rest/free time in afternoon
- Don't pack every minute - allow spontaneity

**6. WEATHER & SEASON AWARENESS:**
- Consider current month's typical weather for the destination
- Adjust outdoor activity timing based on climate
- Include rain contingency plans for monsoon destinations

**7. PRACTICAL COST ESTIMATES (2024-2025 INR):**
- Entry fees: ₹50-500 local, ₹500-1500 premium attractions
- Meals: ₹200-400 budget, ₹500-1000 mid-range, ₹1500+ fine dining
- Transport: ₹500-1500/day for local travel

**8. SMART PACKING LIST:**
- ONLY include items ACTUALLY needed for THIS specific trip
- Consider: destination climate, planned activities, trip duration
- Specify quantities based on trip length (e.g., "3 t-shirts" for 3-day trip)
- Don't add generic irrelevant items

**9. ACTIONABLE TIPS:**
- Destination-specific advice (local customs, scams to avoid, best transport)
- Best times to visit specific attractions
- Emergency info (nearest hospital, police, emergency numbers)

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
