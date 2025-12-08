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
You are an expert travel planner specializing in Indian destinations. Generate a detailed day-by-day itinerary for the following trip:

TRIP DETAILS:
- Destination: ${request.destination}, India
- Duration: ${request.durationDays} days
- $budgetStr
${interestsStr.isNotEmpty ? '- $interestsStr' : ''}
${styleStr.isNotEmpty ? '- $styleStr' : ''}
${groupStr.isNotEmpty ? '- $groupStr' : ''}

REQUIREMENTS:
1. Create a realistic, well-paced itinerary
2. Include specific places, restaurants, and activities
3. Add estimated costs in INR for each activity
4. Include practical tips for each activity
5. Suggest best times for activities
6. Consider travel time between locations
7. Include a packing list specific to the destination
8. Add general travel tips for the destination

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
You are an expert travel packing assistant. Generate a comprehensive packing checklist based on the user's request.

USER REQUEST: "$voicePrompt"

TRIP DETAILS:
- Destination: $destination
- Trip Type: $tripType
${durationDays != null ? '- Duration: $durationDays days' : ''}

REQUIREMENTS:
1. Generate relevant items based on the user's voice request
2. Consider the destination's climate and culture
3. Group items by category
4. Mark essential items
5. Be practical and comprehensive
6. Include quantities where appropriate

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
   - "Beachy Keen in Andaman" instead of "Trip to Andaman"
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
5. Create a realistic day-by-day itinerary
6. Include a comprehensive packing list
7. Add practical travel tips

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
