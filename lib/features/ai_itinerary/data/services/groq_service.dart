// Groq AI Service
//
// Primary AI provider with 14,400 requests/day free tier.
// Uses Llama 3.1 8B Instant for fast, high-quota trip planning.
// Falls back to llama-3.3-70b-versatile if needed (1,000 RPD).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';
import '../../domain/entities/ai_itinerary.dart';

/// Minimal HTTP poster interface so [GroqService] can be unit-tested
/// without making real network calls. The real implementation just delegates
/// to `package:http`'s top-level [http.post].
abstract class GroqHttpClient {
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  });
}

class _DefaultGroqHttpClient implements GroqHttpClient {
  const _DefaultGroqHttpClient();
  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return http.post(url, headers: headers, body: body);
  }
}

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // llama-3.3-70b-versatile: 1,000 RPD, higher TPM limit - handles large trip prompts (~8,891 tokens)
  // llama-3.1-8b-instant: 14,400 RPD but only 6,000 TPM - too small for trip generation prompts
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _fastModel = 'llama-3.1-8b-instant';

  final String _apiKey;
  final GroqHttpClient _httpClient;
  final Future<void> Function(Duration)? _delay;

  GroqService(
    this._apiKey, {
    GroqHttpClient? httpClient,
    Future<void> Function(Duration)? delay,
  })  : _httpClient = httpClient ?? const _DefaultGroqHttpClient(),
        _delay = delay;

  Future<void> _sleep(Duration d) {
    final delay = _delay;
    return delay != null ? delay(d) : Future<void>.delayed(d);
  }

  /// Clean JSON response by removing markdown code blocks and extra text
  /// LLMs sometimes wrap JSON in ```json ... ``` blocks despite instructions
  String _cleanJsonResponse(String content) {
    String cleaned = content.trim();

    // Remove markdown code blocks
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    cleaned = cleaned.trim();

    // If response has text before JSON, find the first { or [
    final jsonStart = cleaned.indexOf('{');
    if (jsonStart > 0) {
      cleaned = cleaned.substring(jsonStart);
    }

    // If response has text after JSON, find the last } or ]
    final jsonEnd = cleaned.lastIndexOf('}');
    if (jsonEnd != -1 && jsonEnd < cleaned.length - 1) {
      cleaned = cleaned.substring(0, jsonEnd + 1);
    }

    return cleaned;
  }

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
    debugPrint('ðŸš€ GroqService.generateCompleteTripPlan() called');
    debugPrint('ðŸŽ¤ Voice prompt: $voicePrompt');
    debugPrint('ðŸ" Destination: $destination');
    debugPrint('ðŸ"… Duration: $durationDays days');

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

    debugPrint('ðŸ" Prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('ðŸŒ Making POST request to Groq API (attempt ${retryCount + 1}/${maxRetries + 1})...');
      debugPrint('Using model: $_model');

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

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('ðŸ"¥ Response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      // Groq free tier: 30 RPM, 1000 RPD - retrying wastes requests
      if (response.statusCode == 429) {
        debugPrint('âŒ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('âŒ Groq: Max retries exceeded for server error');
          throw Exception('Groq server error: ${response.statusCode}');
        }
        debugPrint('â³ Groq server error (${response.statusCode}). Waiting ${delaySeconds}s before retry...');
        await _sleep(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('âŒ Groq API Error: ${response.statusCode}');
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

      debugPrint('âœ… Groq API returned 200 OK');

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

      debugPrint('ðŸ"„ Generated text length: ${content.length} chars');

      try {
        // Clean up response - remove markdown code blocks if present
        final cleanContent = _cleanJsonResponse(content);
        final planJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('âœ… Successfully parsed complete trip plan from Groq');
        debugPrint('   - Trip name: ${plan.tripName}');
        debugPrint('   - Days: ${plan.days.length}');
        debugPrint('   - Packing items: ${plan.packingList.length}');
        debugPrint('   - Tips: ${plan.tips.length}');
        return plan;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('âŒ Failed to parse Groq response: $content');
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
    final currencySymbol = _getCurrencySymbol(currency);
    final budgetStr = budget != null
        ? 'Budget: $currencySymbol${budget.toStringAsFixed(0)} $currency'
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

**6. PRACTICAL COST ESTIMATES (2024-2025 prices in $currency):**
- Provide all cost estimates in $currency ($currencySymbol)
- Give realistic price ranges for the destination
- Be realistic - don't underestimate costs

**7. COMPLETE PACKING LIST (INCLUDE ALL NECESSARY ITEMS):**
Generate a COMPLETE packing list with ALL items the traveler will need. Do NOT skip any category:

**DOCUMENTS (all required):**
- ID proof (Aadhaar/Passport/Driving License)
- Travel tickets & booking confirmations
- Hotel reservation printouts
- Travel insurance documents
- Photocopies of all important documents

**CLOTHING (quantities based on ${durationDays}-day trip):**
- T-shirts/shirts (${durationDays - 1} sets minimum)
- Pants/shorts/bottoms (2-3 pairs)
- Underwear (${durationDays + 2} pieces)
- Socks (${durationDays + 1} pairs)
- Sleepwear/night clothes
- Comfortable walking shoes
- Sandals/flip-flops
- Light jacket/sweater (for AC/evenings)

**TOILETRIES (complete set):**
- Toothbrush & toothpaste
- Soap/body wash
- Shampoo & conditioner
- Deodorant
- Sunscreen (SPF 50+)
- Moisturizer/lotion
- Lip balm
- Comb/hairbrush
- Razor & shaving cream (if needed)
- Feminine hygiene products (if needed)

**ELECTRONICS:**
- Phone charger
- Power bank (10000+ mAh)
- Earphones/headphones
- Camera (if needed)
- Charging cables

**MEDICINES & HEALTH:**
- Pain relievers (Paracetamol/Ibuprofen)
- Antacids/digestive medicine
- Anti-diarrhea medicine
- Band-aids & antiseptic
- Mosquito repellent
- Motion sickness pills (if prone)
- Personal prescription medicines
- Hand sanitizer
- Wet wipes/tissues

**ACCESSORIES:**
- Sunglasses
- Hat/cap
- Umbrella or raincoat
- Water bottle (reusable)
- Day bag/backpack
- Travel pillow (for long journeys)
- Eye mask & earplugs

**ACTIVITY-SPECIFIC (based on itinerary):**
- Add items specific to planned activities (temple wear, beach gear, hiking boots, etc.)

**8. ACTIONABLE TIPS:**
- Include destination-specific advice (local customs, scams to avoid, best transport options)
- Mention best times to visit specific attractions (e.g., "Visit Taj Mahal at sunrise to avoid crowds")
- Include emergency info (nearest hospital, police station, emergency numbers)

RESPOND WITH VALID JSON ONLY. No markdown, no code blocks, no explanations - just the raw JSON object.
CRITICAL: Follow this EXACT schema - field names must match EXACTLY as shown. The parser will FAIL if you use different field names:
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
      "title": "Item name (REQUIRED - must use 'title' NOT 'item')",
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

IMPORTANT: For packing_list items, you MUST use "title" as the field name for the item name, NOT "item". This is critical for parsing.

Generate the complete trip plan now:
''';
  }

  /// Generate complete trip plan from raw voice input
  /// AI extracts destination, duration, and all trip details from natural language
  /// Supports any language the user speaks
  Future<AiCompleteTripPlan> generateCompleteTripPlanFromVoice({
    required String voiceInput,
  }) async {
    debugPrint('ðŸš€ GroqService.generateCompleteTripPlanFromVoice() called');
    debugPrint('ðŸŽ¤ Voice input: $voiceInput');

    final prompt = _buildVoiceParsingPrompt(voiceInput: voiceInput);
    debugPrint('ðŸ" Voice parsing prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('ðŸŒ Making POST request to Groq API (attempt ${retryCount + 1}/${maxRetries + 1})...');

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

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('ðŸ"¥ Response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('âŒ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error: ${response.statusCode}');
        }
        await _sleep(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('âŒ Groq API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('âœ… Groq API returned 200 OK');

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

      debugPrint('ðŸ"„ Generated text length: ${content.length} chars');

      try {
        // Clean up response - remove markdown code blocks if present
        final cleanContent = _cleanJsonResponse(content);
        final planJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('âœ… Successfully parsed complete trip plan from voice');
        debugPrint('   - Destination: ${plan.destination}');
        debugPrint('   - Duration: ${plan.durationDays} days');
        debugPrint('   - Start Date: ${plan.startDate?.toString() ?? 'Not specified'}');
        debugPrint('   - End Date: ${plan.endDate?.toString() ?? 'Not specified'}');
        debugPrint('   - Trip Theme: ${plan.tripTheme ?? 'mixed'}');
        debugPrint('   - Trip name: ${plan.tripName}');
        return plan;
      } catch (e) {
        debugPrint('âŒ Failed to parse Groq response: $content');
        debugPrint('Error: $e');
        throw Exception('Failed to parse Groq AI response');
      }
    }

    throw Exception('Failed to generate trip plan after multiple attempts');
  }

  /// Refine an existing trip plan based on user's refinement request
  /// This method understands that we're MODIFYING an existing plan, not creating a new one
  Future<AiCompleteTripPlan> refineTripPlan({
    required AiCompleteTripPlan currentPlan,
    required String refinementRequest,
  }) async {
    debugPrint('ðŸ"„ GroqService.refineTripPlan() called');
    debugPrint('ðŸ" Refinement request: $refinementRequest');
    debugPrint('ðŸ" Current destination: ${currentPlan.destination}');

    final prompt = _buildRefinementPrompt(
      currentPlan: currentPlan,
      refinementRequest: refinementRequest,
    );
    debugPrint('ðŸ" Refinement prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('ðŸŒ Making POST request to Groq API for refinement (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': '''You are an expert travel planner helping to MODIFY an existing trip plan.
Your job is to REFINE the plan based on the user's request while keeping everything else the same.

IMPORTANT RULES:
1. You are UPDATING an existing plan, NOT creating a new one
2. Only change what the user specifically asks for
3. Keep the same destination, dates, and duration unless explicitly asked to change
4. Keep activities that weren't mentioned - only modify/add/remove what was requested
5. Maintain the same JSON structure exactly
6. You MUST respond with valid JSON only - no markdown, no code blocks, no explanations''',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.5, // Lower temperature for more consistent refinements
        'max_tokens': 8192,
      };

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('ðŸ"¥ Refinement response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('âŒ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error during refinement: ${response.statusCode}');
        }
        await _sleep(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('âŒ Groq API Error during refinement: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API refinement error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('âœ… Groq API refinement returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonResponse['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw Exception('No refinement response from Groq AI');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('Empty refinement response from Groq AI');
      }

      debugPrint('ðŸ"„ Refined plan text length: ${content.length} chars');

      try {
        final cleanContent = _cleanJsonResponse(content);
        final planJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('âœ… Successfully parsed refined trip plan');
        debugPrint('   - Destination: ${plan.destination}');
        debugPrint('   - Duration: ${plan.durationDays} days');
        return plan;
      } catch (e) {
        debugPrint('âŒ Failed to parse refined plan response: $content');
        debugPrint('Error: $e');
        throw Exception('Failed to parse refined plan response');
      }
    }

    throw Exception('Failed to refine trip plan after multiple attempts');
  }

  /// Build prompt for refining an existing plan
  String _buildRefinementPrompt({
    required AiCompleteTripPlan currentPlan,
    required String refinementRequest,
  }) {
    // Build the current itinerary as text
    final itineraryText = currentPlan.days.map((d) => '''
Day ${d.dayNumber}: ${d.title}
${d.activities.map((a) => '  â€¢ ${a.startTime ?? ''} - ${a.title}${a.description != null ? ' (${a.description})' : ''}').join('\n')}
''').join('\n');

    // Build packing list
    final packingText = currentPlan.packingList.map((p) => 'â€¢ ${p.title}').join('\n');

    return '''
CURRENT TRIP PLAN (This is what you need to MODIFY):

**TRIP DETAILS:**
- Trip Name: ${currentPlan.tripName}
- Destination: ${currentPlan.destination}
- Duration: ${currentPlan.durationDays} days
- Start Date: ${currentPlan.startDate?.toString().split(' ')[0] ?? 'Not specified'}
- End Date: ${currentPlan.endDate?.toString().split(' ')[0] ?? 'Not specified'}
- Theme: ${currentPlan.tripTheme ?? 'mixed'}
- Summary: ${currentPlan.summary}

**CURRENT ITINERARY:**
$itineraryText

**CURRENT PACKING LIST:**
$packingText

---

**USER'S REFINEMENT REQUEST:** "$refinementRequest"

---

**YOUR TASK:**
1. UNDERSTAND what the user wants to change (could be in any language - English, Hindi, Tamil, etc.)
2. MODIFY the plan accordingly:

   *For ITINERARY changes:*
   - If they want to ADD an activity: Add it to the appropriate day(s) in the "days" array
   - If they want to REMOVE an activity: Remove it from the itinerary
   - If they want to CHANGE an activity: Replace/modify that activity
   - If they want MORE of something: Add more similar activities
   - If they want LESS of something: Remove some of those activities

   *For PACKING LIST changes:*
   - If they mention packing items, clothes, gear, equipment: Modify the "packing_list" array
   - "Add hiking shoes" â†' Add to packing_list with appropriate category
   - "Remove formal clothes" â†' Remove matching items from packing_list
   - "Add warm clothes" â†' Add jacket, sweater, etc. to packing_list

3. KEEP everything else the same (dates, destination, unmentioned activities/items)
4. Ensure the modified plan is still logical and well-structured

**EXAMPLES OF REFINEMENT REQUESTS:**

*Itinerary Changes:*
- "Add camel ride" â†' Add a camel ride activity to an appropriate day
- "Remove the museum visit" â†' Find and remove museum activities
- "I want more temples" â†' Add more temple visits across days
- "Add beach activities on day 2" â†' Add beach activities specifically to day 2
- "Change dinner to a vegetarian restaurant" â†' Update restaurant recommendations
- "à®'à®Ÿà¯à®Ÿà®•à®šà¯ à®šà®µà®¾à®°à®¿ à®šà¯‡à®°à¯à®•à¯à®•à®µà¯à®®à¯" (Tamil: Add camel ride) â†' Add camel ride activity

*Packing List Changes:*
- "Add hiking shoes" â†' Add hiking shoes to packing_list
- "Add sunscreen and hat" â†' Add sunscreen and hat items to packing_list
- "Remove formal clothes" â†' Remove formal clothing items from packing_list
- "Add camera and tripod" â†' Add photography equipment to packing_list
- "I need warm clothes" â†' Add warm clothing items (jacket, sweater, etc.) to packing_list
- "Add medicines" â†' Add first aid/medicine items to packing_list
- "à®ªà¯†à®Ÿà¯à®Ÿà®¿ à®ªà¯Šà®°à¯à®³à¯à®•à®³à¯ à®šà¯‡à®°à¯à®•à¯à®•à®µà¯à®®à¯" (Tamil: Add packing items) â†' Add relevant items

**OUTPUT FORMAT:**
Return the COMPLETE updated plan in the exact same JSON format:
{
  "trip_name": "string",
  "destination": "string",
  "duration_days": number,
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "summary": "string (1-2 sentences describing the updated trip)",
  "trip_theme": "string",
  "days": [
    {
      "day_number": number,
      "title": "string",
      "activities": [
        {
          "title": "string",
          "description": "string",
          "start_time": "HH:MM",
          "end_time": "HH:MM",
          "location": "string",
          "category": "string",
          "tips": "string"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "title": "string",
      "category": "string"
    }
  ],
  "budget_estimate": {
    "total": number,
    "currency": "INR",
    "breakdown": {
      "accommodation": number,
      "food": number,
      "transport": number,
      "activities": number
    }
  }
}

IMPORTANT: Return ONLY the JSON object, no explanation, no markdown.
''';
  }

  /// Generate an itinerary using Groq API (same format as GeminiService)
  /// Includes retry logic with exponential backoff for rate limiting (429 errors)
  Future<AiGeneratedItinerary> generateItinerary(AiItineraryRequest request) async {
    debugPrint('ðŸš€ GroqService.generateItinerary() called');
    debugPrint('ðŸ" Destination: ${request.destination}');
    debugPrint('ðŸ"… Duration: ${request.durationDays} days');

    final prompt = _buildItineraryPrompt(request);
    debugPrint('ðŸ" Prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('ðŸŒ Making POST request to Groq API (attempt ${retryCount + 1}/${maxRetries + 1})...');

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

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('ðŸ"¥ Response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('âŒ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('âŒ Groq: Max retries exceeded for server error');
          throw Exception('Groq server error: ${response.statusCode}');
        }
        debugPrint('â³ Groq server error (${response.statusCode}). Waiting ${delaySeconds}s before retry...');
        await _sleep(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('âŒ Groq API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('âœ… Groq API returned 200 OK');

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

      debugPrint('ðŸ"„ Generated text length: ${content.length} chars');

      try {
        // Clean up response - remove markdown code blocks if present
        final cleanContent = _cleanJsonResponse(content);
        final itineraryJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final itinerary = AiGeneratedItinerary.fromJson({
          ...itineraryJson,
          'destination': request.destination,
          'duration_days': request.durationDays,
          'budget': request.budget,
          'currency': request.currency,
          'interests': request.interests,
          'generated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('âœ… Successfully parsed itinerary from Groq');
        debugPrint('   - Days: ${itinerary.days.length}');
        debugPrint('   - Packing items: ${itinerary.packingList.length}');
        return itinerary;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('âŒ Failed to parse Groq response: $content');
          debugPrint('Error: $e');
        }
        throw Exception('Failed to parse Groq AI response');
      }
    }

    throw Exception('Failed to generate itinerary after multiple attempts');
  }

  /// Get currency symbol for a currency code
  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return 'â‚¬';
      case 'GBP': return 'Â£';
      case 'JPY': return 'Â¥';
      case 'INR': return 'â‚¹';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'SGD': return 'S\$';
      case 'AED': return 'AED ';
      case 'THB': return 'à¸¿';
      default: return '$currency ';
    }
  }

  /// Build prompt for itinerary generation (matches Gemini format)
  String _buildItineraryPrompt(AiItineraryRequest request) {
    final currencySymbol = _getCurrencySymbol(request.currency);
    final budgetStr = request.budget != null
        ? 'Budget: $currencySymbol${request.budget!.toStringAsFixed(0)} ${request.currency}'
        : 'Budget: Flexible';

    final interestsStr = request.interests.isNotEmpty
        ? 'Interests: ${request.interests.join(", ")}'
        : '';

    final styleStr = request.travelStyle != null
        ? 'Travel Style: ${request.travelStyle}'
        : '';

    final groupStr = request.groupSize != null
        ? 'Group Size: ${request.groupSize} people'
        : '';

    // Build comprehensive context from enhanced request data
    final companionsStr = request.companions != null && request.companions!.isNotEmpty
        ? 'Travelers: ${request.companions!.map((c) {
            final parts = [c.name];
            if (c.relation != null) parts.add(c.relation!);
            if (c.age != null) parts.add('${c.age} years');
            return parts.join(' - ');
          }).join(', ')}'
        : '';

    final transportStr = request.primaryTransport != null
        ? 'Transport to Destination: ${_transportModeToString(request.primaryTransport!)}'
        : '';

    final localTransportStr = request.localTransport != null
        ? 'Local Transport: ${_transportModeToString(request.localTransport!)}'
        : '';

    final weatherStr = request.weatherContext != null && request.weatherContext!.isNotEmpty
        ? 'Weather Context: ${request.weatherContext}'
        : '';

    final eventsStr = request.localEvents != null && request.localEvents!.isNotEmpty
        ? 'Local Events/Festivals: ${request.localEvents}'
        : '';

    final timingStr = request.preferredTiming != null
        ? _buildTimingContext(request.preferredTiming!)
        : '';

    final datesStr = request.startDate != null && request.endDate != null
        ? 'Trip Dates: ${_formatDate(request.startDate!)} to ${_formatDate(request.endDate!)}'
        : '';

    return '''
You are an expert travel planner specializing in Indian destinations. Generate a detailed, PRACTICAL day-by-day itinerary with SPECIFIC restaurant recommendations.

TRIP DETAILS:
- Destination: ${request.destination}, India
- Duration: ${request.durationDays} days
${datesStr.isNotEmpty ? '- $datesStr' : ''}
- $budgetStr
${interestsStr.isNotEmpty ? '- $interestsStr' : ''}
${styleStr.isNotEmpty ? '- $styleStr' : ''}
${groupStr.isNotEmpty ? '- $groupStr' : ''}
${companionsStr.isNotEmpty ? '- $companionsStr' : ''}

TRAVEL CONTEXT:
${transportStr.isNotEmpty ? '- $transportStr' : ''}
${localTransportStr.isNotEmpty ? '- $localTransportStr' : ''}
${weatherStr.isNotEmpty ? '- $weatherStr' : ''}
${eventsStr.isNotEmpty ? '- $eventsStr' : ''}
${timingStr.isNotEmpty ? '$timingStr' : ''}

CRITICAL PLANNING REQUIREMENTS (FOLLOW STRICTLY):

**1. REALISTIC TIME MANAGEMENT:**
- Day 1: Start from check-in/arrival time (2-3 PM), NOT early morning
- Last Day: End by checkout (11 AM-12 PM), plan only morning activities
- Include realistic TRAVEL TIME between locations (30-60 mins city, 2-4 hours inter-city)
- Add 15-30 min buffer between activities
- Limit to 4-5 major activities per day

**2. LOGICAL ACTIVITY SEQUENCING:**
- MORNING (6-12): Nature walks, temples, sunrise points, outdoor activities
- AFTERNOON (12-4): Indoor activities, museums, restaurants, rest time
- EVENING (4-9): Sunset points, markets, cultural shows, dinner
- Group nearby locations together
- Don't schedule strenuous activities after heavy meals

**3. SENSIBLE DAILY STRUCTURE:**
- Breakfast: 7:30-9:00 AM | Lunch: 12:30-2:00 PM | Dinner: 7:30-9:00 PM
- Include 1-2 hours rest/free time in afternoon (especially in hot climates)
- Don't pack every minute - allow spontaneity

**4. SPECIFIC RESTAURANT RECOMMENDATIONS (VERY IMPORTANT):**
- Include REAL, NAMED restaurants for each meal (breakfast, lunch, dinner)
- Recommend popular/well-reviewed local restaurants, cafes, and eateries
- Mix of: Local cuisine spots, popular cafes, street food recommendations
- For each restaurant include:
  - Actual restaurant name (e.g., "Fisherman's Wharf", "Cafe Coffee Day", "Saravana Bhavan")
  - Specific location/area (e.g., "Calangute Beach Road", "MG Road")
  - What they're famous for (signature dishes)
  - Price range matching the budget
- Include at least one local specialty/street food experience per trip
- For breakfast: suggest good cafes or hotel breakfast options
- For lunch: suggest restaurants near the day's activities
- For dinner: suggest atmospheric dining spots

**5. WEATHER & SEASON AWARENESS:**
- Consider current month's typical weather
- Adjust outdoor activity timing based on climate
- Include rain contingency plans if monsoon season

**6. PRACTICAL COST ESTIMATES (2024-2025 prices in ${request.currency}):**
- Provide all cost estimates in ${request.currency} ($currencySymbol)
- Give realistic price ranges for the destination
- Entry fees, meals, transport costs should all use $currencySymbol symbol

**6b. BUDGET-BASED TRANSPORT DECISIONS:**
Based on the budget and local transport preference:
- Recommend appropriate transport based on budget level
- **Realistic Transport Times:** Include actual travel time (e.g., "20-min Uber ride", "45-min metro + walk")
- **Cost-Conscious Tips:** Include cost comparisons in $currencySymbol

**7. SMART PACKING LIST:**
- ONLY items needed for THIS trip (destination climate + activities)
- Specify quantities based on ${request.durationDays}-day duration
- Don't add generic irrelevant items

**8. ACTIONABLE TIPS:**
- Destination-specific advice (local customs, scams to avoid)
- Best times to visit specific attractions
- Must-try local dishes and where to find them
- Emergency info (hospital, police numbers)

RESPOND WITH VALID JSON ONLY. No markdown, no code blocks, no explanations - just the raw JSON object.
CRITICAL: Follow this EXACT schema - field names must match EXACTLY as shown. The parser will FAIL if you use different field names:
{
  "summary": "A brief 2-3 sentence summary of the trip",
  "days": [
    {
      "day_number": 1,
      "title": "Day title (e.g., 'Arrival & City Exploration')",
      "description": "Brief overview of the day",
      "activities": [
        {
          "title": "Activity name (for food: include restaurant name e.g., 'Lunch at Fisherman's Wharf')",
          "description": "What to do/eat here. For restaurants: mention signature dishes",
          "location": "Specific location name (e.g., 'Fisherman's Wharf, Calangute Beach Road')",
          "start_time": "09:00",
          "end_time": "11:00",
          "duration_minutes": 120,
          "category": "sightseeing|food|transport|activity|accommodation",
          "estimated_cost": 500,
          "tip": "Helpful tip (for restaurants: must-try dishes)"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "item": "Item name (REQUIRED - must use 'item' NOT 'title')",
      "category": "clothing|toiletries|electronics|documents|medicines|misc",
      "is_essential": true
    }
  ],
  "tips": [
    "General tip 1",
    "General tip 2"
  ]
}

IMPORTANT: For packing_list items in this itinerary format, you MUST use "item" as the field name for the item name, NOT "title". This is critical for parsing.

Generate a complete itinerary with specific restaurant recommendations now:
''';
  }

  /// Build prompt that lets AI extract everything from voice input
  String _buildVoiceParsingPrompt({required String voiceInput}) {
    final now = DateTime.now();
    final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentDayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];

    return '''
You are an expert travel planner. Today is $currentDate ($currentDayOfWeek).

USER VOICE INPUT: "$voiceInput"

INSTRUCTIONS:
- Understand input in any language (English, Hindi, Tamil, Telugu, Kannada, Malayalam, etc.)
- Extract destination(s), duration, dates, preferences
- Multi-destination: if user says "X 5 days, Y 2 days" respect exact split; otherwise split intelligently
- Use REAL attractions, restaurants, hotels that actually exist
- Date parsing: "this weekend"=next Saturday, "next week"=next Monday, "tomorrow"=tomorrow, no date=7 days from today
- Start date default: $currentDate + 7 days; end date = start + duration - 1
- Trip themes: pilgrimage, adventure, beach, cultural, nature, food, shopping, family, romantic, mixed
- Day 1: start from afternoon (arrival); last day: morning only (checkout)
- Include 4-5 activities per day with realistic times and travel buffers
- Packing list: use "title" field (NOT "item") for item name

RESPOND WITH VALID JSON ONLY (no markdown, no code blocks):
{
  "destination": "extracted destination(s)",
  "duration_days": 3,
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "trip_theme": "pilgrimage|adventure|beach|cultural|nature|food|shopping|family|romantic|mixed",
  "trip_name": "Creative trip name",
  "summary": "2-3 sentence summary",
  "days": [
    {
      "day_number": 1,
      "title": "Day title",
      "description": "Day overview",
      "activities": [
        {
          "title": "Activity name",
          "description": "What to do and why this timing",
          "location": "Specific location with area",
          "start_time": "09:00",
          "end_time": "11:00",
          "duration_minutes": 120,
          "category": "temple|sightseeing|food|transport|activity|accommodation|shopping|rest",
          "estimated_cost": 500,
          "tip": "Insider tip",
          "crowd_level": "low|medium|high",
          "best_time_reason": "Why this time is optimal"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "title": "Item name",
      "category": "documents|clothing|toiletries|electronics|medicines|accessories|pilgrimage|misc",
      "is_essential": true,
      "quantity": 1,
      "notes": "Why needed"
    }
  ],
  "tips": ["Tip 1", "Tip 2", "Tip 3"]
}

Generate the complete trip plan now:
''';
  }

  /// Helper: Convert TransportMode enum to human-readable string
  String _transportModeToString(TransportMode mode) {
    switch (mode) {
      case TransportMode.flight:
        return 'Flight';
      case TransportMode.train:
        return 'Train';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.car:
        return 'Private Car';
      case TransportMode.bike:
        return 'Bike/Scooter';
      case TransportMode.auto:
        return 'Auto-rickshaw';
      case TransportMode.uber:
        return 'Uber/Ola (Ride-sharing)';
      case TransportMode.metro:
        return 'Metro/Subway';
      case TransportMode.walk:
        return 'Walking';
      case TransportMode.mix:
        return 'Mixed (multiple modes)';
    }
  }

  /// Helper: Build timing context string from DailyTiming
  String _buildTimingContext(DailyTiming timing) {
    final parts = <String>[];
    if (timing.wakeUpTime != null) {
      parts.add('Wake up: ${timing.wakeUpTime}');
    }
    if (timing.sleepTime != null) {
      parts.add('Sleep: ${timing.sleepTime}');
    }
    if (timing.breakfastTime != null) {
      parts.add('Breakfast: ${timing.breakfastTime}');
    }
    if (timing.lunchTime != null) {
      parts.add('Lunch: ${timing.lunchTime}');
    }
    if (timing.dinnerTime != null) {
      parts.add('Dinner: ${timing.dinnerTime}');
    }

    if (parts.isEmpty) return '';

    return 'Daily Schedule: ${parts.join(', ')}';
  }

  /// Helper: Format date as readable string
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Refine an existing itinerary based on user's refinement request
  /// This method understands that we're MODIFYING an existing itinerary, not creating a new one
  Future<AiGeneratedItinerary> refineItinerary({
    required AiGeneratedItinerary currentItinerary,
    required String refinementRequest,
  }) async {
    debugPrint('ðŸ"„ GroqService.refineItinerary() called');
    debugPrint('ðŸ" Refinement request: $refinementRequest');
    debugPrint('ðŸ" Current destination: ${currentItinerary.destination}');

    final prompt = _buildItineraryRefinementPrompt(
      currentItinerary: currentItinerary,
      refinementRequest: refinementRequest,
    );
    debugPrint('ðŸ" Refinement prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('ðŸŒ Making POST request to Groq API for itinerary refinement (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': '''You are an expert travel planner helping to MODIFY an existing itinerary.
Your job is to REFINE the itinerary based on the user's request while keeping everything else the same.

IMPORTANT RULES:
1. You are UPDATING an existing itinerary, NOT creating a new one
2. Only change what the user specifically asks for
3. Keep the same destination, dates, and duration unless explicitly asked to change
4. Keep activities that weren't mentioned - only modify/add/remove what was requested
5. Maintain the same JSON structure exactly
6. You MUST respond with valid JSON only - no markdown, no code blocks, no explanations''',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.5, // Lower temperature for more consistent refinements
        'max_tokens': 8192,
      };

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('ðŸ"¥ Refinement response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('âŒ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error during refinement: ${response.statusCode}');
        }
        await _sleep(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('âŒ Groq API Error during refinement: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API refinement error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('âœ… Groq API refinement returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = jsonResponse['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw Exception('No refinement response from Groq AI');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('Empty refinement response from Groq AI');
      }

      debugPrint('ðŸ"„ Refined itinerary text length: ${content.length} chars');

      try {
        final cleanContent = _cleanJsonResponse(content);
        final itineraryJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final itinerary = AiGeneratedItinerary.fromJson({
          ...itineraryJson,
          'destination': currentItinerary.destination,
          'duration_days': currentItinerary.durationDays,
          'budget': currentItinerary.budget,
          'currency': currentItinerary.currency,
          'interests': currentItinerary.interests,
          'generated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('âœ… Successfully parsed refined itinerary');
        debugPrint('   - Days: ${itinerary.days.length}');
        return itinerary;
      } catch (e) {
        debugPrint('âŒ Failed to parse refined itinerary response: $content');
        debugPrint('Error: $e');
        throw Exception('Failed to parse refined itinerary response');
      }
    }

    throw Exception('Failed to refine itinerary after multiple attempts');
  }

  /// Build prompt for refining an existing itinerary
  String _buildItineraryRefinementPrompt({
    required AiGeneratedItinerary currentItinerary,
    required String refinementRequest,
  }) {
    // Build the current itinerary as text
    final itineraryText = currentItinerary.days.map((d) => '''
Day ${d.dayNumber}: ${d.title ?? 'Day ${d.dayNumber}'}
${d.activities.map((a) => '  â€¢ ${a.startTime ?? ''} - ${a.title}${a.description != null ? ' (${a.description})' : ''}').join('\n')}
''').join('\n');

    // Build packing list
    final packingText = currentItinerary.packingList.map((p) => 'â€¢ ${p.item}').join('\n');

    // Get currency symbol
    final currencySymbol = _getCurrencySymbol(currentItinerary.currency);

    return '''
CURRENT ITINERARY (This is what you need to MODIFY):

**TRIP DETAILS:**
- Destination: ${currentItinerary.destination}
- Duration: ${currentItinerary.durationDays} days
- Budget: ${currentItinerary.budget != null ? '$currencySymbol${currentItinerary.budget!.toStringAsFixed(0)} ${currentItinerary.currency}' : 'Flexible'}
- Summary: ${currentItinerary.summary ?? 'N/A'}

**CURRENT DAILY ITINERARY:**
$itineraryText

**CURRENT PACKING LIST:**
$packingText

---

**USER'S REFINEMENT REQUEST:** "$refinementRequest"

---

**YOUR TASK:**
1. UNDERSTAND what the user wants to change (could be in any language - English, Hindi, Tamil, etc.)
2. MODIFY the itinerary accordingly:

   *For ITINERARY changes:*
   - If they want to ADD an activity: Add it to the appropriate day(s) in the "days" array
   - If they want to REMOVE an activity: Remove it from the itinerary
   - If they want to CHANGE an activity: Replace/modify that activity
   - If they want MORE of something: Add more similar activities
   - If they want LESS of something: Remove some of those activities
   - If they want different timing: Adjust start_time and end_time

   *For PACKING LIST changes:*
   - If they mention packing items, clothes, gear, equipment: Modify the "packing_list" array
   - "Add hiking shoes" â†' Add to packing_list
   - "Remove formal clothes" â†' Remove matching items from packing_list

   *For TRANSPORT/BUDGET changes:*
   - "Use cheaper transport" â†' Change Uber to bus in activities
   - "More luxury" â†' Upgrade transport and restaurants
   - "Budget-friendly meals" â†' Replace expensive restaurants with affordable options

3. KEEP everything else the same (destination, duration, unmentioned activities/items)
4. Ensure the modified itinerary is still logical and well-structured

**EXAMPLES OF REFINEMENT REQUESTS:**

*Itinerary Changes:*
- "Add a cooking class" â†' Add a cooking class activity to an appropriate day
- "Remove the museum visit" â†' Find and remove museum activities
- "I want more temple visits" â†' Add more temple activities
- "Add beach time on day 2" â†' Add beach activities specifically to day 2
- "Change dinner to vegetarian restaurant" â†' Update restaurant recommendations
- "Start days earlier, I wake up at 6 AM" â†' Adjust all start times to begin around 6-7 AM

*Packing List Changes:*
- "Add sunscreen" â†' Add sunscreen to packing_list
- "I need warm clothes" â†' Add jacket, sweater to packing_list
- "Remove beach stuff" â†' Remove swimwear, beach items from packing_list

*Budget/Transport Changes:*
- "Make it more budget-friendly" â†' Replace Uber with bus, expensive restaurants with affordable ones
- "I want to use local buses" â†' Change transport activities to use buses instead of cabs

**OUTPUT FORMAT:**
Return the COMPLETE updated itinerary in the exact same JSON format:
{
  "summary": "string (1-2 sentences describing the updated itinerary)",
  "days": [
    {
      "day_number": number,
      "title": "string",
      "description": "string",
      "activities": [
        {
          "title": "string",
          "description": "string",
          "location": "string",
          "start_time": "HH:MM",
          "end_time": "HH:MM",
          "duration_minutes": number,
          "category": "sightseeing|food|transport|activity|accommodation",
          "estimated_cost": number,
          "tip": "string"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "item": "string",
      "category": "string",
      "is_essential": boolean
    }
  ],
  "tips": [
    "string"
  ]
}

IMPORTANT: Return ONLY the JSON object, no explanation, no markdown.
''';
  }

  /// Generate checklist items using Groq API
  /// Primary provider for checklist generation (14,400 RPD vs Gemini's 25 RPD)
  Future<List<AiChecklistItem>> generateChecklistItems({
    required String voicePrompt,
    required String destination,
    required String tripType,
    int? durationDays,
  }) async {
    debugPrint('🚀 GroqService.generateChecklistItems() called');
    debugPrint('🎤 Voice prompt: $voicePrompt');
    debugPrint('📍 Destination: $destination');

    final prompt = _buildChecklistPrompt(
      voicePrompt: voicePrompt,
      destination: destination,
      tripType: tripType,
      durationDays: durationDays,
    );

    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Groq API for checklist (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final requestBody = {
        'model': _fastModel,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert travel packing assistant. You MUST respond with valid JSON only. Do not include any markdown, code blocks, or explanations. Only output the raw JSON object.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 4096,
      };

      final response = await _httpClient.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Checklist response status: ${response.statusCode}');

      if (response.statusCode == 429) {
        debugPrint('❌ Groq rate limited (429) for checklist. NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error: ${response.statusCode}');
        }
        await _sleep(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Groq checklist API Error: ${response.statusCode}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

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

      try {
        final cleanContent = _cleanJsonResponse(content);
        final itemsJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final items = (itemsJson['items'] as List?)
            ?.map((e) => AiChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        debugPrint('✅ Groq generated ${items.length} checklist items');
        return items;
      } catch (e) {
        debugPrint('❌ Failed to parse Groq checklist response: $e');
        throw Exception('Failed to parse Groq AI response');
      }
    }

    throw Exception('Failed to generate checklist after multiple attempts');
  }

  /// Build prompt for checklist generation
  String _buildChecklistPrompt({
    required String voicePrompt,
    required String destination,
    required String tripType,
    int? durationDays,
  }) {
    return '''
You are an expert travel packing assistant with deep knowledge of Indian destinations. Generate a SMART, PRACTICAL packing checklist.

USER REQUEST: "$voicePrompt"

TRIP DETAILS:
- Destination: $destination
- Trip Type: $tripType
${durationDays != null ? '- Duration: $durationDays days' : ''}

CRITICAL PACKING REQUIREMENTS:
1. Include destination-specific items for weather and activities
2. Calculate smart quantities based on trip duration
3. Mark only truly essential items (passport, medications, charger)
4. Avoid generic items easily bought at destination

CATEGORIES: documents, clothing, toiletries, electronics, medicines, accessories, misc

RESPOND WITH VALID JSON ONLY. No markdown, no code blocks - just the raw JSON:
{
  "items": [
    {
      "title": "Item name",
      "category": "documents|clothing|toiletries|electronics|medicines|accessories|misc",
      "is_essential": true,
      "quantity": 1,
      "notes": "Optional helpful note"
    }
  ]
}

IMPORTANT: Use "title" as the field name for each item's name. Generate the checklist now:
''';
  }
}
