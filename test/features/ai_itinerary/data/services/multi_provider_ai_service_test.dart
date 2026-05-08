// Tests for MultiProviderAiService.
//
// MultiProviderAiService composes a Groq + Gemini service. We exercise the
// failover and refinement-only paths by faking the underlying HTTP clients
// and queueing scripted responses, exactly as the gemini/groq-service
// tests do — no codegen mocks.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:travel_crew/features/ai_itinerary/data/services/gemini_service.dart';
import 'package:travel_crew/features/ai_itinerary/data/services/groq_service.dart';
import 'package:travel_crew/features/ai_itinerary/data/services/multi_provider_ai_service.dart';
import 'package:travel_crew/features/ai_itinerary/domain/entities/ai_itinerary.dart'
    hide AiItineraryDay, AiItineraryActivity;

class _GroqFake implements GroqHttpClient {
  final List<Object> queue = [];
  int callCount = 0;

  void enqueueResponseWith({required int statusCode, required String body}) =>
      queue.add(http.Response(body, statusCode));

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    callCount++;
    if (queue.isEmpty) {
      throw StateError('No queued Groq response (#$callCount)');
    }
    final next = queue.removeAt(0);
    if (next is http.Response) return next;
    throw next;
  }
}

class _GeminiFake implements GeminiHttpClient {
  final List<Object> queue = [];
  int callCount = 0;

  void enqueueResponseWith({required int statusCode, required String body}) =>
      queue.add(http.Response(body, statusCode));

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    callCount++;
    if (queue.isEmpty) {
      throw StateError('No queued Gemini response (#$callCount)');
    }
    final next = queue.removeAt(0);
    if (next is http.Response) return next;
    throw next;
  }
}

String _wrapGroq(String content) => jsonEncode({
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    });

String _wrapGemini(String text) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    });

String _validCompleteTrip({String? destination, int? days}) => jsonEncode({
      'trip_name': 'Plan',
      'summary': 's',
      'destination': destination ?? 'Goa',
      'duration_days': days ?? 3,
      'days': [
        {
          'day_number': 1,
          'title': 'D1',
          'description': '',
          'activities': [
            {'title': 'A', 'category': 'sightseeing'},
          ],
        },
      ],
      'packing_list': [],
      'tips': [],
    });

String _validItinerary() => jsonEncode({
      'days': [
        {
          'day_number': 1,
          'title': 'Arrival',
          'description': '',
          'activities': [
            {'title': 'A', 'category': 'sightseeing'},
          ],
        },
      ],
      'packing_list': [],
      'tips': [],
      'summary': 'sum',
    });

String _validChecklist() => jsonEncode({
      'items': [
        {'title': 'Sunscreen', 'is_essential': true},
      ],
    });

({MultiProviderAiService service, _GroqFake groq, _GeminiFake gemini})
    _build() {
  final groq = _GroqFake();
  final gemini = _GeminiFake();
  final service = MultiProviderAiService(
    groqService: GroqService('GK', httpClient: groq, delay: (_) async {}),
    geminiService:
        GeminiService('GEMK', httpClient: gemini, delay: (_) async {}),
  );
  return (service: service, groq: groq, gemini: gemini);
}

void main() {
  group('generateCompleteTripPlan failover', () {
    test('Groq succeeds on first try, Gemini never called', () async {
      final h = _build();
      h.groq.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGroq(_validCompleteTrip()),
      );
      final plan = await h.service.generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.destination, 'Goa');
      expect(h.groq.callCount, 1);
      expect(h.gemini.callCount, 0);
    });

    test('Groq 429 -> falls back to Gemini and succeeds', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      h.gemini.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGemini(_validCompleteTrip()),
      );
      final plan = await h.service.generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.destination, 'Goa');
      expect(h.groq.callCount, 1);
      expect(h.gemini.callCount, 1);
    });

    test('Both providers fail -> throws unavailable', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      // Gemini exhausts its 4 attempts on 429.
      for (var i = 0; i < 4; i++) {
        h.gemini.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        h.service.generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('AI service is currently unavailable'))),
      );
    });
  });

  group('generateCompleteTripPlanFromVoice failover', () {
    test('Groq succeeds, Gemini not called', () async {
      final h = _build();
      h.groq.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGroq(_validCompleteTrip()),
      );
      final plan = await h.service.generateCompleteTripPlanFromVoice(
        voiceInput: 'goa 3 days',
      );
      expect(plan.destination, 'Goa');
      expect(h.gemini.callCount, 0);
    });

    test('Groq fails -> Gemini fallback succeeds', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      h.gemini.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGemini(_validCompleteTrip()),
      );
      final plan = await h.service.generateCompleteTripPlanFromVoice(
        voiceInput: 'x',
      );
      expect(plan.destination, 'Goa');
      expect(h.gemini.callCount, 1);
    });

    test('Both fail -> throws unavailable', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      for (var i = 0; i < 4; i++) {
        h.gemini.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        h.service.generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('AI service is currently unavailable'))),
      );
    });
  });

  group('refineTripPlan (Groq only, no fallback)', () {
    test('Groq success returns refined plan', () async {
      final h = _build();
      h.groq.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGroq(_validCompleteTrip()),
      );
      final base = AiCompleteTripPlan.fromJson(
          jsonDecode(_validCompleteTrip()) as Map<String, dynamic>);
      final plan = await h.service.refineTripPlan(
        currentPlan: base,
        refinementRequest: 'add yoga',
      );
      expect(plan.destination, 'Goa');
      expect(h.gemini.callCount, 0);
    });

    test('Groq failure throws (no fallback)', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      final base = AiCompleteTripPlan.fromJson(
          jsonDecode(_validCompleteTrip()) as Map<String, dynamic>);
      await expectLater(
        h.service.refineTripPlan(
          currentPlan: base,
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to refine trip plan'))),
      );
      expect(h.gemini.callCount, 0);
    });
  });

  group('refineItinerary (Groq only, no fallback)', () {
    test('Groq success returns refined itinerary', () async {
      final h = _build();
      h.groq.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGroq(_validItinerary()),
      );
      final base = AiGeneratedItinerary.fromJson({
        ...jsonDecode(_validItinerary()) as Map<String, dynamic>,
        'destination': 'Goa',
        'duration_days': 3,
        'currency': 'INR',
        'budget': 1000,
        'interests': [],
        'generated_at': '2024-01-01T00:00:00Z',
      });
      final refined = await h.service.refineItinerary(
        currentItinerary: base,
        refinementRequest: 'add yoga',
      );
      expect(refined.destination, 'Goa');
      expect(h.gemini.callCount, 0);
    });

    test('Groq failure rethrows (no fallback)', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      final base = AiGeneratedItinerary.fromJson({
        ...jsonDecode(_validItinerary()) as Map<String, dynamic>,
        'destination': 'Goa',
        'duration_days': 3,
        'currency': 'INR',
        'budget': 1000,
        'interests': [],
        'generated_at': '2024-01-01T00:00:00Z',
      });
      await expectLater(
        h.service.refineItinerary(
          currentItinerary: base,
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>()),
      );
      expect(h.gemini.callCount, 0);
    });
  });

  group('generateItinerary failover', () {
    const request = AiItineraryRequest(
      destination: 'Goa',
      durationDays: 3,
      currency: 'INR',
    );

    test('Groq succeeds first', () async {
      final h = _build();
      h.groq.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGroq(_validItinerary()),
      );
      final result = await h.service.generateItinerary(request);
      expect(result.destination, 'Goa');
      expect(h.gemini.callCount, 0);
    });

    test('Groq fails -> Gemini succeeds', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      h.gemini.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGemini(_validItinerary()),
      );
      final result = await h.service.generateItinerary(request);
      expect(result.destination, 'Goa');
      expect(h.gemini.callCount, 1);
    });

    test('Both fail -> throws unavailable (generic message)', () async {
      final h = _build();
      h.groq.enqueueResponseWith(statusCode: 429, body: '');
      for (var i = 0; i < 4; i++) {
        h.gemini.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        h.service.generateItinerary(request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('AI service is currently unavailable'))),
      );
    });
  });

  group('generateChecklistItems (Gemini-only delegation)', () {
    test('delegates to Gemini and returns parsed items', () async {
      final h = _build();
      h.gemini.enqueueResponseWith(
        statusCode: 200,
        body: _wrapGemini(_validChecklist()),
      );
      final items = await h.service.generateChecklistItems(
        voicePrompt: 'pack for goa',
        destination: 'Goa',
        tripType: 'beach',
      );
      expect(items, hasLength(1));
      expect(items.first.title, 'Sunscreen');
      // Groq is never consulted for checklist.
      expect(h.groq.callCount, 0);
    });

    test('Gemini failure propagates', () async {
      final h = _build();
      // Gemini retries 4x on 429
      for (var i = 0; i < 4; i++) {
        h.gemini.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        h.service.generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AiProvider enum', () {
    test('contains groq and gemini', () {
      expect(AiProvider.values, contains(AiProvider.groq));
      expect(AiProvider.values, contains(AiProvider.gemini));
      expect(AiProvider.values.length, 2);
    });
  });
}
