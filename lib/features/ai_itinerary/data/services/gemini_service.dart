// Gemini AI Service
//
// Handles communication with Google's Gemini API for itinerary generation.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/ai_itinerary.dart';

class GeminiService {
  // Using Gemini 2.0 Flash for speed and cost efficiency
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final String _apiKey;

  GeminiService(this._apiKey);

  /// Generate an itinerary using Gemini AI
  /// Includes retry logic with exponential backoff for rate limiting (429 errors)
  Future<AiGeneratedItinerary> generateItinerary(AiItineraryRequest request) async {
    debugPrint('🤖 GeminiService.generateItinerary() called');
    debugPrint('📍 Destination: ${request.destination}');
    debugPrint('📅 Duration: ${request.durationDays} days');

    final prompt = _buildPrompt(request);
    debugPrint('📝 Prompt built (${prompt.length} chars)');

    final url = '$_baseUrl?key=$_apiKey';

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Gemini API (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 8192,
            'responseMimeType': 'application/json',
          },
        }),
      );

      debugPrint('📥 Response status code: ${response.statusCode}');

      // Handle rate limiting (429) with exponential backoff
      if (response.statusCode == 429) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Max retries exceeded for rate limiting');
          throw Exception('AI service is busy. Please try again in a few moments.');
        }
        debugPrint('⏳ Rate limited (429). Waiting ${delaySeconds}s before retry $retryCount/$maxRetries...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      // Handle other server errors (500, 503) with retry
      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Max retries exceeded for server error');
          throw Exception('AI service temporarily unavailable. Please try again.');
        }
        debugPrint('⏳ Server error (${response.statusCode}). Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Gemini API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to generate itinerary. Please try again.');
      }

      debugPrint('✅ Gemini API returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      // Extract the generated text from Gemini's response
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from AI');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Invalid response format');
      }

      final generatedText = parts[0]['text'] as String;

      // Parse the JSON response from Gemini
      try {
        final itineraryJson = jsonDecode(generatedText) as Map<String, dynamic>;
        return AiGeneratedItinerary.fromJson({
          ...itineraryJson,
          'destination': request.destination,
          'duration_days': request.durationDays,
          'budget': request.budget,
          'currency': request.currency,
          'interests': request.interests,
          'generated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to parse Gemini response: $generatedText');
          debugPrint('Error: $e');
        }
        throw Exception('Failed to parse AI response');
      }
    }

    throw Exception('Failed to generate itinerary after multiple attempts');
  }

  /// Build the prompt for Gemini
  String _buildPrompt(AiItineraryRequest request) {
    final budgetStr = request.budget != null
        ? 'Budget: ₹${request.budget!.toStringAsFixed(0)} ${request.currency}'
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

    return '''
You are an expert travel planner specializing in Indian destinations. Generate a detailed, PRACTICAL day-by-day itinerary.

TRIP DETAILS:
- Destination: ${request.destination}, India
- Duration: ${request.durationDays} days
- $budgetStr
${interestsStr.isNotEmpty ? '- $interestsStr' : ''}
${styleStr.isNotEmpty ? '- $styleStr' : ''}
${groupStr.isNotEmpty ? '- $groupStr' : ''}

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

**4. WEATHER & SEASON AWARENESS:**
- Consider current month's typical weather
- Adjust outdoor activity timing based on climate
- Include rain contingency plans if monsoon season

**5. PRACTICAL COST ESTIMATES (2024-2025 INR):**
- Entry fees: ₹50-500 local, ₹500-1500 premium attractions
- Meals: ₹200-400 budget, ₹500-1000 mid-range, ₹1500+ fine dining
- Transport: ₹500-1500/day local travel

**6. SMART PACKING LIST:**
- ONLY items needed for THIS trip (destination climate + activities)
- Specify quantities based on ${request.durationDays}-day duration
- Don't add generic irrelevant items

**7. ACTIONABLE TIPS:**
- Destination-specific advice (local customs, scams to avoid)
- Best times to visit specific attractions
- Emergency info (hospital, police numbers)

RESPOND WITH VALID JSON in this exact format:
{
  "summary": "A brief 2-3 sentence summary of the trip",
  "days": [
    {
      "day_number": 1,
      "title": "Day title (e.g., 'Arrival & City Exploration')",
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
      "item": "Item name",
      "category": "clothing|toiletries|electronics|documents|medicines|misc",
      "is_essential": true
    }
  ],
  "tips": [
    "General tip 1",
    "General tip 2"
  ]
}

Generate a complete itinerary now:
''';
  }

  /// Generate checklist items using AI based on voice input
  /// Includes retry logic with exponential backoff for rate limiting (429 errors)
  Future<List<AiChecklistItem>> generateChecklistItems({
    required String voicePrompt,
    required String destination,
    required String tripType,
    int? durationDays,
  }) async {
    debugPrint('🤖 GeminiService.generateChecklistItems() called');
    debugPrint('🎤 Voice prompt: $voicePrompt');
    debugPrint('📍 Destination: $destination');

    final prompt = _buildChecklistPrompt(
      voicePrompt: voicePrompt,
      destination: destination,
      tripType: tripType,
      durationDays: durationDays,
    );

    final url = '$_baseUrl?key=$_apiKey';

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Gemini API (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 4096,
            'responseMimeType': 'application/json',
          },
        }),
      );

      debugPrint('📥 Response status code: ${response.statusCode}');

      // Handle rate limiting (429) with exponential backoff
      if (response.statusCode == 429) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Max retries exceeded for rate limiting');
          throw Exception('AI service is busy. Please try again in a few moments.');
        }
        debugPrint('⏳ Rate limited (429). Waiting ${delaySeconds}s before retry $retryCount/$maxRetries...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      // Handle other server errors (500, 503) with retry
      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Max retries exceeded for server error');
          throw Exception('AI service temporarily unavailable. Please try again.');
        }
        debugPrint('⏳ Server error (${response.statusCode}). Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Gemini API Error: ${response.statusCode}');
        throw Exception('Failed to generate checklist. Please try again.');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from AI');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Invalid response format');
      }

      final generatedText = parts[0]['text'] as String;

      try {
        final itemsJson = jsonDecode(generatedText) as Map<String, dynamic>;
        final items = (itemsJson['items'] as List?)?.map((e) {
          return AiChecklistItem.fromJson(e as Map<String, dynamic>);
        }).toList() ?? [];
        return items;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to parse checklist response: $generatedText');
        }
        throw Exception('Failed to parse AI response');
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

CRITICAL PACKING REQUIREMENTS (FOLLOW STRICTLY):

**1. DESTINATION-SPECIFIC ITEMS:**
- Consider the destination's typical weather/climate
- Include items needed for planned activities (beach gear for coastal, warm layers for hills)
- Add culturally appropriate clothing if visiting religious sites

**2. SMART QUANTITY CALCULATION:**
- Base clothing quantity on trip duration (e.g., ${durationDays ?? 3} days = ${((durationDays ?? 3) * 0.7).ceil()} t-shirts with laundry option)
- Don't overpack - consider laundry availability
- One pair of comfortable walking shoes is usually enough

**3. ESSENTIAL VS NICE-TO-HAVE:**
- Mark only truly ESSENTIAL items (passport, medications, phone charger)
- Non-essential items should be marked accordingly
- Don't include items easily available at destination

**4. PRACTICAL NOTES:**
- Add helpful notes only when genuinely useful
- Include specific product recommendations where relevant (e.g., "SPF 50+ for beach trips")
- Mention multi-purpose items to reduce packing

**5. AVOID GENERIC FILLER:**
- DON'T include obvious items everyone has (basic underwear unless special type needed)
- DON'T add items unrelated to this specific trip
- Focus on destination and activity-specific needs

**6. CATEGORY ORGANIZATION:**
- documents: ID, tickets, bookings, insurance
- clothing: Appropriate for weather and activities
- toiletries: Only travel-specific or hard-to-find items
- electronics: Chargers, adapters, camera
- medicines: Personal prescriptions, first-aid basics
- accessories: Sunglasses, bags, travel-specific gear
- misc: Snacks, entertainment, other

RESPOND WITH VALID JSON in this exact format:
{
  "items": [
    {
      "title": "Item name (e.g., Passport, Sunscreen SPF 50)",
      "category": "documents|clothing|toiletries|electronics|medicines|accessories|misc",
      "is_essential": true,
      "quantity": 1,
      "notes": "Optional helpful note"
    }
  ]
}

Generate the checklist now:
''';
  }

  /// Generate complete trip plan (itinerary + checklist) in a single API call
  /// This is more efficient than calling generateItinerary and generateChecklistItems separately
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
    debugPrint('🤖 GeminiService.generateCompleteTripPlan() called');
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

    debugPrint('📝 Unified prompt built (${prompt.length} chars)');

    final url = '$_baseUrl?key=$_apiKey';

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2; // Start with 2 second delay

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Gemini API (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 12288, // Larger for complete plan
            'responseMimeType': 'application/json',
          },
        }),
      );

      debugPrint('📥 Response status code: ${response.statusCode}');

      // Handle rate limiting (429) with exponential backoff
      if (response.statusCode == 429) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Max retries exceeded for rate limiting');
          throw Exception('AI service is busy. Please try again in a few moments.');
        }
        debugPrint('⏳ Rate limited (429). Waiting ${delaySeconds}s before retry $retryCount/$maxRetries...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2; // Exponential backoff: 2s, 4s, 8s
        continue;
      }

      // Handle other server errors (500, 503) with retry
      if (response.statusCode >= 500 && response.statusCode < 600) {
        retryCount++;
        if (retryCount > maxRetries) {
          debugPrint('❌ Max retries exceeded for server error');
          throw Exception('AI service temporarily unavailable. Please try again.');
        }
        debugPrint('⏳ Server error (${response.statusCode}). Waiting ${delaySeconds}s before retry...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Gemini API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to generate trip plan. Please try again.');
      }

      debugPrint('✅ Gemini API returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from AI');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Invalid response format');
      }

      final generatedText = parts[0]['text'] as String;
      debugPrint('📄 Generated text length: ${generatedText.length} chars');

      try {
        final planJson = jsonDecode(generatedText) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('✅ Successfully parsed complete trip plan');
        debugPrint('   - Trip name: ${plan.tripName}');
        debugPrint('   - Days: ${plan.days.length}');
        debugPrint('   - Packing items: ${plan.packingList.length}');
        debugPrint('   - Tips: ${plan.tips.length}');
        return plan;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to parse complete trip plan: $generatedText');
          debugPrint('Error: $e');
        }
        throw Exception('Failed to parse AI response');
      }
    }

    // This should never be reached, but just in case
    throw Exception('Failed to generate trip plan after multiple attempts');
  }

  /// Build unified prompt for complete trip plan generation
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
    debugPrint('🤖 GeminiService.generateCompleteTripPlanFromVoice() called');
    debugPrint('🎤 Voice input: $voiceInput');

    final prompt = _buildVoiceParsingPrompt(voiceInput: voiceInput);
    debugPrint('📝 Voice parsing prompt built (${prompt.length} chars)');

    final url = '$_baseUrl?key=$_apiKey';

    // Retry logic with exponential backoff
    const maxRetries = 3;
    int retryCount = 0;
    int delaySeconds = 2;

    while (retryCount <= maxRetries) {
      debugPrint('🌐 Making POST request to Gemini API (attempt ${retryCount + 1}/${maxRetries + 1})...');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 12288,
            'responseMimeType': 'application/json',
          },
        }),
      );

      debugPrint('📥 Response status code: ${response.statusCode}');

      if (response.statusCode == 429) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('AI service is busy. Please try again in a few moments.');
        }
        debugPrint('⏳ Rate limited. Waiting ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode >= 500) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('AI service temporarily unavailable.');
        }
        await Future.delayed(Duration(seconds: delaySeconds));
        delaySeconds *= 2;
        continue;
      }

      if (response.statusCode != 200) {
        debugPrint('❌ Gemini API Error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to generate trip plan.');
      }

      debugPrint('✅ Gemini API returned 200 OK');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from AI');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Invalid response format');
      }

      final generatedText = parts[0]['text'] as String;
      debugPrint('📄 Generated text length: ${generatedText.length} chars');

      try {
        final planJson = jsonDecode(generatedText) as Map<String, dynamic>;
        final plan = AiCompleteTripPlan.fromJson(planJson);
        debugPrint('✅ Successfully parsed complete trip plan from voice');
        debugPrint('   - Destination: ${plan.destination}');
        debugPrint('   - Duration: ${plan.durationDays} days');
        debugPrint('   - Trip name: ${plan.tripName}');
        return plan;
      } catch (e) {
        debugPrint('❌ Failed to parse: $e');
        throw Exception('Failed to parse AI response');
      }
    }

    throw Exception('Failed after multiple attempts');
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

/// AI-generated checklist item
class AiChecklistItem {
  final String title;
  final String? category;
  final bool isEssential;
  final int quantity;
  final String? notes;

  const AiChecklistItem({
    required this.title,
    this.category,
    this.isEssential = false,
    this.quantity = 1,
    this.notes,
  });

  factory AiChecklistItem.fromJson(Map<String, dynamic> json) {
    return AiChecklistItem(
      title: json['title'] as String,
      category: json['category'] as String?,
      isEssential: json['is_essential'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }
}

/// Service result wrapper
class GeminiResult<T> {
  final T? data;
  final String? error;
  final int? durationMs;

  const GeminiResult({
    this.data,
    this.error,
    this.durationMs,
  });

  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;
}

/// Complete trip plan generated by AI (itinerary + checklist in one call)
/// Now includes destination and duration extracted by AI from voice input
class AiCompleteTripPlan {
  final String tripName;
  final String summary;
  final String destination; // AI-extracted destination
  final int durationDays; // AI-extracted duration
  final List<AiItineraryDay> days;
  final List<AiChecklistItem> packingList;
  final List<String> tips;

  const AiCompleteTripPlan({
    required this.tripName,
    required this.summary,
    required this.destination,
    required this.durationDays,
    required this.days,
    required this.packingList,
    required this.tips,
  });

  factory AiCompleteTripPlan.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List?)?.map((d) => AiItineraryDay.fromJson(d)).toList() ?? [];
    return AiCompleteTripPlan(
      tripName: json['trip_name'] as String? ?? 'My Trip',
      summary: json['summary'] as String? ?? '',
      destination: json['destination'] as String? ?? 'Unknown',
      durationDays: json['duration_days'] as int? ?? days.length,
      days: days,
      packingList: (json['packing_list'] as List?)?.map((i) => AiChecklistItem.fromJson(i)).toList() ?? [],
      tips: (json['tips'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}

/// Day in the itinerary
class AiItineraryDay {
  final int dayNumber;
  final String title;
  final String description;
  final List<AiItineraryActivity> activities;

  const AiItineraryDay({
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.activities,
  });

  factory AiItineraryDay.fromJson(Map<String, dynamic> json) {
    return AiItineraryDay(
      dayNumber: json['day_number'] as int? ?? 1,
      title: json['title'] as String? ?? 'Day ${json['day_number'] ?? 1}',
      description: json['description'] as String? ?? '',
      activities: (json['activities'] as List?)?.map((a) => AiItineraryActivity.fromJson(a)).toList() ?? [],
    );
  }
}

/// Activity in the itinerary
class AiItineraryActivity {
  final String title;
  final String? description;
  final String? location;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final String? category;
  final double? estimatedCost;
  final String? tip;

  const AiItineraryActivity({
    required this.title,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.category,
    this.estimatedCost,
    this.tip,
  });

  factory AiItineraryActivity.fromJson(Map<String, dynamic> json) {
    return AiItineraryActivity(
      title: json['title'] as String? ?? 'Activity',
      description: json['description'] as String?,
      location: json['location'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      category: json['category'] as String?,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      tip: json['tip'] as String?,
    );
  }
}
