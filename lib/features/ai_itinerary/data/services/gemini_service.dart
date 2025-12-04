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
  Future<AiGeneratedItinerary> generateItinerary(AiItineraryRequest request) async {
    debugPrint('🤖 GeminiService.generateItinerary() called');
    debugPrint('📍 Destination: ${request.destination}');
    debugPrint('📅 Duration: ${request.durationDays} days');

    final prompt = _buildPrompt(request);
    debugPrint('📝 Prompt built (${prompt.length} chars)');

    final url = '$_baseUrl?key=$_apiKey';
    debugPrint('🌐 Making POST request to Gemini API...');

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

    if (response.statusCode != 200) {
      debugPrint('❌ Gemini API Error: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      throw Exception('Failed to generate itinerary: ${response.statusCode}');
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
