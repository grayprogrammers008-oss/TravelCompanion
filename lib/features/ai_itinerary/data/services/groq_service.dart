// Groq AI Service
//
// Primary AI provider with 1,000 requests/day free tier.
// Uses Llama 3.3 70B Versatile for high-quality trip planning.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';
import '../../domain/entities/ai_itinerary.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Using Llama 3.3 70B Versatile (latest version, replaces 3.1)
  static const String _model = 'llama-3.3-70b-versatile';

  final String _apiKey;

  GroqService(this._apiKey);

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

      // Handle rate limiting (429) - DON'T retry to save quota
      // Groq free tier: 30 RPM, 1000 RPD - retrying wastes requests
      if (response.statusCode == 429) {
        debugPrint('❌ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
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
        // Clean up response - remove markdown code blocks if present
        final cleanContent = _cleanJsonResponse(content);
        final planJson = jsonDecode(cleanContent) as Map<String, dynamic>;
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

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('❌ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
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
        // Clean up response - remove markdown code blocks if present
        final cleanContent = _cleanJsonResponse(content);
        final planJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('✅ Successfully parsed complete trip plan from voice');
        debugPrint('   - Destination: ${plan.destination}');
        debugPrint('   - Duration: ${plan.durationDays} days');
        debugPrint('   - Start Date: ${plan.startDate?.toString() ?? 'Not specified'}');
        debugPrint('   - End Date: ${plan.endDate?.toString() ?? 'Not specified'}');
        debugPrint('   - Trip Theme: ${plan.tripTheme ?? 'mixed'}');
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

  /// Refine an existing trip plan based on user's refinement request
  /// This method understands that we're MODIFYING an existing plan, not creating a new one
  Future<AiCompleteTripPlan> refineTripPlan({
    required AiCompleteTripPlan currentPlan,
    required String refinementRequest,
  }) async {
    debugPrint('🔄 GroqService.refineTripPlan() called');
    debugPrint('📝 Refinement request: $refinementRequest');
    debugPrint('📍 Current destination: ${currentPlan.destination}');

    final prompt = _buildRefinementPrompt(
      currentPlan: currentPlan,
      refinementRequest: refinementRequest,
    );
    debugPrint('📝 Refinement prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Groq API for refinement (attempt ${retryCount + 1}/${maxRetries + 1})...');

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

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Refinement response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('❌ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error during refinement: ${response.statusCode}');
        }
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Groq API Error during refinement: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API refinement error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('✅ Groq API refinement returned 200 OK');

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

      debugPrint('📄 Refined plan text length: ${content.length} chars');

      try {
        final cleanContent = _cleanJsonResponse(content);
        final planJson = jsonDecode(cleanContent) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('✅ Successfully parsed refined trip plan');
        debugPrint('   - Destination: ${plan.destination}');
        debugPrint('   - Duration: ${plan.durationDays} days');
        return plan;
      } catch (e) {
        debugPrint('❌ Failed to parse refined plan response: $content');
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
${d.activities.map((a) => '  • ${a.startTime ?? ''} - ${a.title}${a.description != null ? ' (${a.description})' : ''}').join('\n')}
''').join('\n');

    // Build packing list
    final packingText = currentPlan.packingList.map((p) => '• ${p.title}').join('\n');

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
   - "Add hiking shoes" → Add to packing_list with appropriate category
   - "Remove formal clothes" → Remove matching items from packing_list
   - "Add warm clothes" → Add jacket, sweater, etc. to packing_list

3. KEEP everything else the same (dates, destination, unmentioned activities/items)
4. Ensure the modified plan is still logical and well-structured

**EXAMPLES OF REFINEMENT REQUESTS:**

*Itinerary Changes:*
- "Add camel ride" → Add a camel ride activity to an appropriate day
- "Remove the museum visit" → Find and remove museum activities
- "I want more temples" → Add more temple visits across days
- "Add beach activities on day 2" → Add beach activities specifically to day 2
- "Change dinner to a vegetarian restaurant" → Update restaurant recommendations
- "ஒட்டகச் சவாரி சேர்க்கவும்" (Tamil: Add camel ride) → Add camel ride activity

*Packing List Changes:*
- "Add hiking shoes" → Add hiking shoes to packing_list
- "Add sunscreen and hat" → Add sunscreen and hat items to packing_list
- "Remove formal clothes" → Remove formal clothing items from packing_list
- "Add camera and tripod" → Add photography equipment to packing_list
- "I need warm clothes" → Add warm clothing items (jacket, sweater, etc.) to packing_list
- "Add medicines" → Add first aid/medicine items to packing_list
- "பெட்டி பொருள்கள் சேர்க்கவும்" (Tamil: Add packing items) → Add relevant items

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
    debugPrint('🚀 GroqService.generateItinerary() called');
    debugPrint('📍 Destination: ${request.destination}');
    debugPrint('📅 Duration: ${request.durationDays} days');

    final prompt = _buildItineraryPrompt(request);
    debugPrint('📝 Prompt built (${prompt.length} chars)');

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

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('❌ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
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
        debugPrint('✅ Successfully parsed itinerary from Groq');
        debugPrint('   - Days: ${itinerary.days.length}');
        debugPrint('   - Packing items: ${itinerary.packingList.length}');
        return itinerary;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to parse Groq response: $content');
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
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      case 'AUD': return 'A\$';
      case 'CAD': return 'C\$';
      case 'SGD': return 'S\$';
      case 'AED': return 'AED ';
      case 'THB': return '฿';
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
    // Get current date/time for context
    final now = DateTime.now();
    final currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentDayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    final currentMonth = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][now.month - 1];

    return '''
You are an EXPERT travel planner and LOCAL GUIDE with encyclopedic knowledge of REAL tourist destinations, attractions, restaurants, and hidden gems across India and the world.

**CURRENT DATE CONTEXT:**
- Today's date: $currentDate ($currentDayOfWeek, $currentMonth ${now.day}, ${now.year})
- Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}

Your job is to:
1. UNDERSTAND what they said (could be in any language - English, Hindi, Tamil, Telugu, Kannada, Malayalam, etc.)
2. EXTRACT the destination(s), duration, trip type, dates, and ALL PREFERENCES intelligently
3. **DETECT MULTI-DESTINATION TRIPS** and intelligently split days between destinations
4. GENERATE an INTELLIGENTLY OPTIMIZED trip plan with REAL, SPECIFIC places that actually exist

**🚨 CRITICAL: MULTI-DESTINATION TRIP HANDLING:**

When user mentions MULTIPLE destinations (e.g., "Jaipur and Udaipur", "Kerala and Goa", "Rajasthan tour"):

**⚠️ ABSOLUTELY CRITICAL - USER-SPECIFIED DURATIONS ARE MANDATORY!**

When user specifies EXACT days per destination, you MUST follow it EXACTLY:
- "Singapore 5 days, Malaysia 2 days" = EXACTLY 5 days of Singapore activities + 2 days of Malaysia activities
- Total trip = 5 + 2 + travel days (if needed)
- DO NOT reduce Singapore days to add travel days - travel is EXTRA
- DO NOT redistribute days "intelligently" - follow user's EXACT request

WRONG ❌: Singapore 3 days + Travel 1 day + Malaysia 3 days (ignores user's 5-2 split)
CORRECT ✅: Singapore 5 days + Travel to Malaysia + Malaysia 2 days

Parse the user's input carefully:
- "சிங்கப்பூருக்கு 5 நாட்கள்" = Singapore for 5 days (FIVE days)
- "மலேஷியாக்கு 2 நாட்கள்" = Malaysia for 2 days (TWO days)
- Numbers in Tamil: ஐந்து=5, நான்கு=4, மூன்று=3, இரண்டு=2, ஒன்று=1

1. **DETECT** all destinations mentioned (explicit like "Jaipur and Udaipur" OR implicit like "Rajasthan" which includes Jaipur, Udaipur, Jodhpur)
2. **RESPECT USER-SPECIFIED DURATIONS** - If user says "X for 5 days, Y for 2 days", use EXACTLY those durations
3. **ONLY intelligently split days** if user does NOT specify per-destination duration (e.g., "Singapore and Malaysia for 7 days" without specifying split)
4. **INCLUDE TRAVEL BETWEEN DESTINATIONS** as explicit activities:
   - Show travel time and mode (drive/train/flight)
   - Plan departure after hotel checkout, arrival before evening
   - If distance > 5 hours, dedicate half day or full day to travel
5. **OPTIMIZE ROUTE** for minimal backtracking:
   - Go in one direction geographically
   - Example: Delhi → Jaipur → Udaipur → Mumbai (linear) NOT Delhi → Udaipur → Jaipur (zigzag)

**MULTI-DESTINATION EXAMPLES:**

Example 1 (USER SPECIFIES EXACT DAYS - MANDATORY!):
Input: "Singapore 5 days, Malaysia 2 days" OR "சிங்கப்பூருக்கு 5 நாட்கள், மலேஷியாக்கு 2 நாட்கள்"

CORRECT OUTPUT (8 days total):
→ Day 1: Singapore - Arrival and Exploration
→ Day 2: Singapore - Marina Bay and Gardens
→ Day 3: Singapore - Sentosa Island
→ Day 4: Singapore - Cultural Districts
→ Day 5: Singapore - Shopping and Departure Prep
→ Day 6: Travel to Malaysia + Kuala Lumpur Arrival
→ Day 7: Malaysia - Petronas Towers and City
→ Day 8: Malaysia - Final Day and Departure

Key: Singapore gets 5 FULL days (Day 1-5), Malaysia gets 2 FULL days (Day 7-8), Travel is Day 6

Example 2 (No specific days - AI splits intelligently):
"Jaipur and Udaipur for 4 days"
→ Split: Jaipur 2 days, Travel 0.5 day, Udaipur 1.5 days
→ Day 1-2: Jaipur activities
→ Day 3 Morning: Drive Jaipur → Udaipur (5-6 hours)
→ Day 3 Evening + Day 4: Udaipur activities

Example 3 (No specific days - AI splits intelligently):
"Kerala and Goa for 7 days"
→ Split: Kerala 3.5 days, Flight day 0.5, Goa 3 days
→ Day 1-3: Kerala (Kochi, Munnar, Alleppey)
→ Day 4 Morning: Flight Kerala → Goa
→ Day 4-7: Goa beaches and activities

**MULTI-DESTINATION OUTPUT FORMAT:**
- In the "destination" field: Include ALL destinations comma-separated (e.g., "Jaipur, Udaipur")
- In day titles: Clearly indicate which destination (e.g., "Day 1: Jaipur - Pink City Exploration")
- Include "Travel" activities between destinations with realistic times
- In summary: Mention the multi-destination split

USER'S VOICE INPUT: "$voiceInput"

**⚠️ CRITICAL - REAL PLACES ONLY:**
- You MUST include REAL, ACTUAL tourist attractions that exist
- You MUST include REAL restaurant names (popular local restaurants, not generic "local restaurant")
- You MUST include REAL hotel areas and neighborhoods
- Do NOT invent fictional places - use only real destinations you have knowledge about
- Include SPECIFIC addresses/areas (e.g., "Marina Beach, Chennai" not just "Beach")
- For restaurants: Use ACTUAL restaurant names like "Saravana Bhavan", "Murugan Idli Shop", "Buhari", "Anjappar", etc.

CRITICAL PLANNING REQUIREMENTS (FOLLOW STRICTLY):

**1. EXTRACT FROM VOICE (INCLUDING DATES & PREFERENCES):**
- Identify the DESTINATION from what the user said
- Identify the DURATION (number of days) - if not specified, assume 3 days
- **EXTRACT ALL PREFERENCES & TRIP THEMES:**
  - PILGRIMAGE/SPIRITUAL: temples, churches, mosques, gurudwaras, ashrams, spiritual experiences
  - ADVENTURE: trekking, water sports, paragliding, camping, wildlife safari
  - BEACH/RELAXATION: beaches, resorts, spas, sunset points
  - CULTURAL/HERITAGE: museums, forts, palaces, historical sites, art galleries
  - FOOD/CULINARY: local cuisine, street food tours, cooking classes, food markets
  - NATURE: hill stations, waterfalls, forests, botanical gardens, scenic drives
  - SHOPPING: local markets, handicrafts, malls, specialty items
  - FAMILY-FRIENDLY: theme parks, zoos, child-safe activities, family restaurants
  - ROMANTIC: couple activities, scenic spots, fine dining, sunset cruises
  - BUDGET: affordable options, free attractions, local transport
  - LUXURY: premium experiences, 5-star dining, exclusive tours
- **If user mentions specific themes like "pilgrimage", "temples", "spiritual" → FOCUS 70-80% of itinerary on those activities**
- **IMPORTANT - EXTRACT START DATE:**
  - If user mentions specific dates like "December 25th", "25th December", "on 25/12" → use that date
  - If user says "this weekend" → calculate the upcoming Saturday from today's date
  - If user says "next weekend" → calculate the Saturday after this weekend
  - If user says "next week" → calculate Monday of next week
  - If user says "tomorrow" → use tomorrow's date
  - If user says "in 2 days" or "after 2 days" → add 2 days to today
  - If user says "next month" → use 1st of next month
  - If user says "January", "February", etc. → use 1st of that month (in current or next year, whichever makes sense)
  - If user says "January last" or "last week of January" → use the last week of that month
  - If user says "end of January" → use around 25th-31st of that month
  - If user says "mid January" → use around 15th of that month
  - If NO date is mentioned → default to 7 days from today (gives time to prepare)
- Calculate END DATE = START DATE + (duration_days - 1)

**2. TRIP NAME:**
- Generate a creative, peppy trip name reflecting the THEME (NOT "Trip to X")
- For pilgrimage: "Sacred Varanasi Sojourn", "Divine South Temple Trail"
- For beach: "Goan Paradise Escape", "Andaman Azure Adventure"
- For adventure: "Himalayan Heights Quest", "Rishikesh Rapids Rush"
- Use alliteration, rhymes, wordplay that matches the trip's spirit

**FAMOUS ATTRACTIONS DATABASE (USE THESE REAL PLACES):**

**GOA:**
- Beaches: Baga Beach, Calangute Beach, Anjuna Beach, Palolem Beach, Vagator Beach, Morjim Beach
- Attractions: Fort Aguada, Basilica of Bom Jesus, Se Cathedral, Dudhsagar Falls, Chapora Fort
- Nightlife: Tito's Lane Baga, Club Cubana, LPK Waterfront, Mambo's
- Restaurants: Fisherman's Wharf, Britto's, Curlies, Brittos, Martin's Corner, Thalassa

**KERALA:**
- Backwaters: Alleppey Houseboats, Kumarakom, Vembanad Lake
- Beaches: Kovalam Beach, Varkala Cliff Beach, Marari Beach
- Hill Stations: Munnar Tea Gardens, Thekkady (Periyar), Wayanad
- Attractions: Fort Kochi, Chinese Fishing Nets, Mattancherry Palace, Jewish Synagogue
- Restaurants: Paragon Restaurant Calicut, Kayees Rahmathulla Hotel, Dhe Puttu

**RAJASTHAN:**
- Jaipur: Amber Fort, Hawa Mahal, City Palace, Nahargarh Fort, Jantar Mantar
- Udaipur: City Palace Udaipur, Lake Pichola, Jag Mandir, Fateh Sagar Lake
- Jodhpur: Mehrangarh Fort, Jaswant Thada, Clock Tower Market
- Jaisalmer: Jaisalmer Fort, Sam Sand Dunes, Patwon Ki Haveli
- Restaurants: Laxmi Mishthan Bhandar (LMB) Jaipur, Chokhi Dhani, Ambrai Udaipur

**TAMIL NADU:**
- Chennai: Marina Beach, Kapaleeshwarar Temple, Fort St. George, San Thome Basilica
- Temples: Meenakshi Temple Madurai, Brihadeeswara Temple Thanjavur, Rameshwaram Temple
- Hill Stations: Ooty, Kodaikanal, Yercaud, Coonoor
- Restaurants: Saravana Bhavan, Murugan Idli Shop, Anjappar, Ponnusamy, Dindigul Thalappakatti

**KARNATAKA:**
- Bangalore: Lalbagh, Cubbon Park, ISKCON Temple, Nandi Hills, Ulsoor Lake
- Mysore: Mysore Palace, Chamundi Hills, Brindavan Gardens
- Hampi: Virupaksha Temple, Vittala Temple, Hampi Bazaar
- Coorg: Abbey Falls, Raja's Seat, Dubare Elephant Camp
- Restaurants: Vidyarthi Bhavan, MTR Mavalli Tiffin Rooms, Nagarjuna, Empire Restaurant

**HIMACHAL:**
- Shimla: Mall Road, Ridge, Jakhu Temple, Christ Church, Kufri
- Manali: Solang Valley, Rohtang Pass, Hadimba Temple, Old Manali
- Dharamshala: McLeod Ganj, Dalai Lama Temple, Bhagsu Falls, Triund Trek
- Restaurants: Cafe Illiterati McLeod Ganj, Johnson's Cafe Manali, Wake & Bake Cafe

**3. INTELLIGENT ROUTE OPTIMIZATION (VERY IMPORTANT):**
- **GEOGRAPHIC CLUSTERING:** Group nearby attractions together to minimize travel
- **FUEL/TIME EFFICIENCY:** Plan routes in a logical loop - don't zigzag across the city
- **DIRECTIONAL FLOW:** If visiting multiple areas, go in one direction (e.g., North→South→East→West) rather than back-and-forth
- **EXAMPLE:** If visiting temples in Varanasi: Start from one ghat, visit nearby temples in sequence along the riverbank, don't jump between distant locations

**4. CROWD AVOIDANCE & QUEUE MANAGEMENT (CRITICAL):**
- **EARLY BIRD STRATEGY:** Popular temples/attractions → Visit at opening time (5-6 AM for temples)
- **AVOID PEAK HOURS:**
  - Temples: Avoid 10 AM - 12 PM and 5 PM - 7 PM (peak pooja times with long queues)
  - Tourist spots: Avoid 11 AM - 3 PM (maximum crowds)
  - Beaches: Avoid 4 PM - 6 PM on weekends
- **WEEKDAY ADVANTAGE:** If trip includes weekdays, schedule popular spots on weekdays
- **MEAL TIMING STRATEGY:** Have lunch during peak crowd hours at attractions, then visit when crowds thin
- **VIP/SPECIAL DARSHAN:** Recommend paid special darshan tickets if available to skip queues
- **SUNSET SPOTS:** Arrive 1 hour before sunset to get good spots
- **INCLUDE QUEUE TIME IN SCHEDULE:** Add 30-60 min buffer for popular temples

**5. WEATHER & TIME-OF-DAY OPTIMIZATION:**
- **MORNING (5 AM - 10 AM):**
  - Temples (cooler, less crowded, morning aarti)
  - Sunrise points, nature walks
  - Outdoor activities before heat
- **MIDDAY (10 AM - 4 PM):**
  - Indoor activities: Museums, AC malls, restaurants
  - Rest time at hotel (especially in hot climates)
  - Air-conditioned temples if available
- **EVENING (4 PM - 9 PM):**
  - Sunset points, evening aarti at temples
  - Markets and shopping (cooler, shops fully open)
  - Riverfront walks, beach activities
  - Cultural shows, local performances
- **NIGHT (After 9 PM):**
  - Night markets (if destination has them)
  - Illuminated monuments (if open)
  - Local food streets

**6. TEMPLE/PILGRIMAGE SPECIFIC INTELLIGENCE:**
- **DRESS CODE ALERTS:** Mention if specific dress required (e.g., "Men must remove shirts at Padmanabhaswamy Temple")
- **POOJA TIMINGS:** Include important aarti/pooja times worth attending
- **SPECIAL DAYS:** Note if trip dates coincide with special temple days or festivals
- **OFFERINGS:** Suggest what offerings to carry for specific temples
- **PHOTOGRAPHY RULES:** Note where photography is prohibited
- **SHOE STORAGE:** Mention paid vs free shoe storage options
- **BEST VIEWING SPOTS:** Recommend best spots for darshan or viewing ceremonies

**7. REALISTIC TIME MANAGEMENT:**
- Day 1: Start activities from arrival/check-in time (2-3 PM), NOT early morning
- Last Day: End by checkout (11 AM-12 PM), plan only morning activities
- Include realistic TRAVEL TIME between locations (30-60 mins city, 2-4 hours inter-city)
- Add 30-60 min buffer for temples (queues + darshan)
- Limit to 4-5 major activities per day

**8. SENSIBLE DAILY STRUCTURE:**
- Breakfast: 7:30-9:00 AM | Lunch: 12:30-2:00 PM | Dinner: 7:30-9:00 PM
- Include 1-2 hours rest/free time in afternoon
- For pilgrimage: Plan early wake-up (4-5 AM) for morning temple visits
- Don't pack every minute - allow spontaneity

**9. WEATHER & SEASON AWARENESS:**
- Consider current month's typical weather for the destination
- Adjust outdoor activity timing based on climate
- Include rain contingency plans for monsoon destinations
- Summer: Schedule outdoor activities before 10 AM and after 4 PM
- Winter: Can schedule throughout day, but check fog advisories (especially North India)

**10. PRACTICAL COST ESTIMATES (2024-2025 INR):**
- Entry fees: ₹50-500 local, ₹500-1500 premium attractions
- Temple special darshan: ₹300-1000 typically
- Meals: ₹200-400 budget, ₹500-1000 mid-range, ₹1500+ fine dining
- Transport: ₹500-1500/day for local travel

**11. COMPLETE PACKING LIST (INCLUDE ALL NECESSARY ITEMS):**

Generate a COMPLETE packing list with ALL items the traveler needs. Go through EACH CATEGORY and include EVERY relevant item:

**DOCUMENTS (Include ALL):**
- ID proof (Aadhaar/PAN/Passport/Driving License)
- Travel tickets (flight/train/bus) - printed & digital
- Hotel booking confirmations
- Travel insurance documents
- Photocopies of all important documents
- Emergency contact list
- Credit/debit cards
- Some cash in local currency

**CLOTHING (Based on destination weather & duration):**
- T-shirts/shirts (one per day or duration-1 with laundry)
- Pants/trousers/jeans
- Shorts (if weather permits)
- Underwear (duration + 2 extra)
- Socks (duration + 2 extra)
- Sleepwear/nightclothes
- Comfortable walking shoes
- Sandals/flip-flops
- Light jacket/sweater (for AC/evenings)
- Raincoat/umbrella (check weather)
- Hat/cap for sun protection
- Traditional/formal wear (if temples/events)

**TOILETRIES (Complete kit):**
- Toothbrush & toothpaste
- Shampoo & conditioner (travel size)
- Soap/body wash
- Deodorant
- Sunscreen SPF 50+
- Moisturizer/lotion
- Lip balm
- Razor & shaving cream
- Comb/hairbrush
- Wet wipes
- Hand sanitizer
- Tissues/toilet paper roll
- Feminine hygiene products (if needed)

**ELECTRONICS (All essentials):**
- Phone charger (original)
- Power bank (10000+ mAh)
- Earphones/headphones
- Camera (if separate from phone)
- Travel adapter (if needed)
- Laptop/tablet charger (if carrying)

**MEDICINES (Complete first-aid):**
- Personal prescription medicines
- Painkillers (Paracetamol/Ibuprofen)
- Antacids/digestive aids (Eno/Digene)
- Anti-diarrhea medicine (Imodium)
- Anti-nausea/motion sickness (Avomine)
- Antihistamine for allergies
- Band-aids & antiseptic cream
- Mosquito repellent (cream/spray)
- ORS packets
- Thermometer
- Any vitamins you take regularly

**ACCESSORIES (All useful items):**
- Sunglasses
- Watch
- Day backpack/small bag
- Wallet
- Water bottle (reusable)
- Neck pillow (for long travel)
- Eye mask & earplugs
- Luggage locks
- Plastic bags (for wet/dirty clothes)
- Small torch/flashlight
- Pen (for forms)
- Book/Kindle for reading

**ACTIVITY-SPECIFIC (Based on your itinerary):**
- If TEMPLES: Traditional clothing, head covering, offerings bag
- If BEACHES: Swimwear, beach towel, waterproof phone pouch, after-sun lotion
- If TREKKING: Trekking shoes, quick-dry clothes, headlamp, trekking poles
- If HILL STATIONS: Warm layers, thermals, gloves, woolen cap, thermal socks
- If WATER SPORTS: Quick-dry clothes, waterproof bag, goggles
- If WILDLIFE/SAFARI: Binoculars, earth-toned clothes, camera with zoom lens
- If PHOTOGRAPHY: Extra memory cards, camera cleaning kit, tripod

Mark ESSENTIAL items (documents, medicines, phone charger) as is_essential: true.
Include helpful notes referencing specific activities from your itinerary.

**12. ACTIONABLE TIPS (INCLUDE SMART INSIDER TIPS):**
- Destination-specific advice (local customs, scams to avoid, best transport options)
- **Crowd-beating tips:** Best times to visit to avoid queues
- **Money-saving tips:** Free darshan timings, combo tickets, local transport hacks
- **Local insider tips:** Best local food spots, hidden gems, lesser-known viewpoints
- Emergency info (nearest hospital, police station, emergency numbers)
- **Route tips:** Best order to visit attractions for efficiency

RESPOND WITH VALID JSON ONLY. No markdown, no code blocks, no explanations - just the raw JSON object.
CRITICAL: Follow this EXACT schema - field names must match EXACTLY as shown. The parser will FAIL if you use different field names:
{
  "destination": "The destination extracted from user input",
  "duration_days": 3,
  "start_date": "YYYY-MM-DD (calculated from user's voice input or default to 7 days from today)",
  "end_date": "YYYY-MM-DD (start_date + duration_days - 1)",
  "trip_theme": "pilgrimage|adventure|beach|cultural|nature|food|shopping|family|romantic|mixed",
  "trip_name": "Creative peppy name reflecting the theme (e.g., 'Sacred Varanasi Sojourn', 'Divine Temple Trail')",
  "summary": "A brief 2-3 sentence summary highlighting the theme and key experiences",
  "days": [
    {
      "day_number": 1,
      "title": "Day title reflecting activities (e.g., 'Sacred Morning at Kashi Vishwanath')",
      "description": "Brief overview explaining the day's route logic and timing strategy",
      "activities": [
        {
          "title": "Activity name",
          "description": "What to do here + WHY this timing (e.g., 'Visit early to avoid 2-hour queues')",
          "location": "Specific location name with area (e.g., 'Kashi Vishwanath Temple, Varanasi Old City')",
          "start_time": "05:30",
          "end_time": "07:30",
          "duration_minutes": 120,
          "category": "temple|sightseeing|food|transport|activity|accommodation|shopping|rest",
          "estimated_cost": 500,
          "tip": "Insider tip (e.g., 'Use Gate 4 for shorter queue', 'Special aarti at 7 PM')",
          "crowd_level": "low|medium|high",
          "best_time_reason": "Why this time slot is optimal (e.g., 'Before morning rush', 'Sunset views')"
        }
      ]
    }
  ],
  "packing_list": [
    {
      "title": "Item name (REQUIRED - must use 'title' NOT 'item')",
      "category": "documents|clothing|toiletries|electronics|medicines|accessories|pilgrimage|misc",
      "is_essential": true,
      "quantity": 1,
      "notes": "Why needed for this trip (reference specific activity if applicable)"
    }
  ],
  "tips": [
    "Smart tip 1 (e.g., 'Book special darshan tickets online to skip 3-hour queues')",
    "Smart tip 2 (e.g., 'Visit Meenakshi Temple at 5 AM opening for crowd-free darshan')",
    "Route tip (e.g., 'Start from south gate, temples are in walking sequence northward')"
  ]
}

IMPORTANT: For packing_list items, you MUST use "title" as the field name for the item name, NOT "item". This is critical for parsing.

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
    debugPrint('🔄 GroqService.refineItinerary() called');
    debugPrint('📝 Refinement request: $refinementRequest');
    debugPrint('📍 Current destination: ${currentItinerary.destination}');

    final prompt = _buildItineraryRefinementPrompt(
      currentItinerary: currentItinerary,
      refinementRequest: refinementRequest,
    );
    debugPrint('📝 Refinement prompt built (${prompt.length} chars)');

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Groq API for itinerary refinement (attempt ${retryCount + 1}/${maxRetries + 1})...');

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

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Refinement response status code: ${response.statusCode}');

      // Handle rate limiting (429) - DON'T retry to save quota
      if (response.statusCode == 429) {
        debugPrint('❌ Groq rate limited (429). NOT retrying to save quota.');
        throw Exception('Groq rate limited: 429. Please wait a moment.');
      }

      // Handle server errors with retry (5xx are transient)
      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('Groq server error during refinement: ${response.statusCode}');
        }
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Groq API Error during refinement: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        String errorDetail = '';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorDetail = error?['message'] as String? ?? '';
        } catch (_) {}
        throw Exception('Groq API refinement error: ${response.statusCode}${errorDetail.isNotEmpty ? ' - $errorDetail' : ''}');
      }

      debugPrint('✅ Groq API refinement returned 200 OK');

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

      debugPrint('📄 Refined itinerary text length: ${content.length} chars');

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
        debugPrint('✅ Successfully parsed refined itinerary');
        debugPrint('   - Days: ${itinerary.days.length}');
        return itinerary;
      } catch (e) {
        debugPrint('❌ Failed to parse refined itinerary response: $content');
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
${d.activities.map((a) => '  • ${a.startTime ?? ''} - ${a.title}${a.description != null ? ' (${a.description})' : ''}').join('\n')}
''').join('\n');

    // Build packing list
    final packingText = currentItinerary.packingList.map((p) => '• ${p.item}').join('\n');

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
   - "Add hiking shoes" → Add to packing_list
   - "Remove formal clothes" → Remove matching items from packing_list

   *For TRANSPORT/BUDGET changes:*
   - "Use cheaper transport" → Change Uber to bus in activities
   - "More luxury" → Upgrade transport and restaurants
   - "Budget-friendly meals" → Replace expensive restaurants with affordable options

3. KEEP everything else the same (destination, duration, unmentioned activities/items)
4. Ensure the modified itinerary is still logical and well-structured

**EXAMPLES OF REFINEMENT REQUESTS:**

*Itinerary Changes:*
- "Add a cooking class" → Add a cooking class activity to an appropriate day
- "Remove the museum visit" → Find and remove museum activities
- "I want more temple visits" → Add more temple activities
- "Add beach time on day 2" → Add beach activities specifically to day 2
- "Change dinner to vegetarian restaurant" → Update restaurant recommendations
- "Start days earlier, I wake up at 6 AM" → Adjust all start times to begin around 6-7 AM

*Packing List Changes:*
- "Add sunscreen" → Add sunscreen to packing_list
- "I need warm clothes" → Add jacket, sweater to packing_list
- "Remove beach stuff" → Remove swimwear, beach items from packing_list

*Budget/Transport Changes:*
- "Make it more budget-friendly" → Replace Uber with bus, expensive restaurants with affordable ones
- "I want to use local buses" → Change transport activities to use buses instead of cabs

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
}
