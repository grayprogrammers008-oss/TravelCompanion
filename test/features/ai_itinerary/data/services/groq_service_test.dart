// Tests for GroqService.
//
// All HTTP traffic is faked through the [GroqHttpClient] interface and
// the artificial delay is replaced with a no-op so retry logic runs
// instantly. We exercise:
//
//  * Each public method (generateCompleteTripPlan,
//    generateCompleteTripPlanFromVoice, refineTripPlan, refineItinerary,
//    generateItinerary).
//  * 200 happy path including parsing.
//  * 429 NOT retried (Groq policy: save quota by failing fast).
//  * 5xx retry-with-backoff happy + exhaustion paths.
//  * Other non-200 status codes including error-message extraction.
//  * Missing-choices / missing-content / empty-content validations.
//  * Malformed inner JSON parse errors and the markdown ```json``` cleaner.
//  * Currency-symbol logic (USD/EUR/GBP/etc).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pathio/features/ai_itinerary/data/services/gemini_service.dart'
    show AiCompleteTripPlan;
import 'package:pathio/features/ai_itinerary/data/services/groq_service.dart';
// `AiItineraryDay` and `AiItineraryActivity` are also declared by
// gemini_service.dart, so hide the domain copies to avoid ambiguity.
import 'package:pathio/features/ai_itinerary/domain/entities/ai_itinerary.dart'
    hide AiItineraryDay, AiItineraryActivity;

/// A queue-driven fake of [GroqHttpClient]. Calls to [post] return the
/// next queued response, or throw if [enqueueThrow] was scheduled.
class _FakeHttpClient implements GroqHttpClient {
  _FakeHttpClient();

  final List<Object> queue = [];
  int callCount = 0;
  final List<Uri> calledUrls = [];
  final List<Map<String, String>?> calledHeaders = [];
  final List<Object?> calledBodies = [];

  void enqueueResponse(http.Response response) => queue.add(response);

  void enqueueResponseWith({required int statusCode, required String body}) =>
      queue.add(http.Response(body, statusCode));

  void enqueueThrow(Object error) => queue.add(error);

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    callCount++;
    calledUrls.add(url);
    calledHeaders.add(headers);
    calledBodies.add(body);
    if (queue.isEmpty) {
      throw StateError(
        'No queued response for call #$callCount to ${url.toString()}',
      );
    }
    final next = queue.removeAt(0);
    if (next is http.Response) return next;
    throw next;
  }
}

/// Builds a Groq API success body wrapping [contentText] inside the standard
/// choices/message envelope used by OpenAI-compatible APIs.
String _wrap(String contentText) => jsonEncode({
      'choices': [
        {
          'message': {
            'content': contentText,
          },
        },
      ],
    });

String _validCompleteTripJson({String? destination, int? durationDays}) =>
    jsonEncode({
      'trip_name': 'Goan Paradise',
      'summary': 'sunny',
      'destination': destination ?? 'Goa',
      'duration_days': durationDays ?? 3,
      'start_date': '2024-07-01',
      'end_date': '2024-07-03',
      'trip_theme': 'beach',
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
      'packing_list': [
        {'title': 'Passport', 'is_essential': true},
      ],
      'tips': ['T1', 'T2'],
    });

String _validItineraryJson() => jsonEncode({
      'days': [
        {
          'day_number': 1,
          'title': 'Arrival',
          'description': 'desc',
          'activities': [
            {
              'title': 'A1',
              'category': 'sightseeing',
            },
          ],
        },
      ],
      'packing_list': [
        {'item': 'Sunscreen', 'category': 'toiletries', 'is_essential': true},
      ],
      'tips': ['Tip 1'],
      'summary': 'A nice trip',
    });

GroqService _service(_FakeHttpClient client) => GroqService(
      'KEY',
      httpClient: client,
      // Replace the real delay with a no-op so retry tests run instantly.
      delay: (_) async {},
    );

const _request = AiItineraryRequest(
  destination: 'Goa',
  durationDays: 3,
  budget: 10000,
  currency: 'INR',
  interests: ['beach', 'food'],
  travelStyle: 'budget',
  groupSize: 4,
);

AiCompleteTripPlan _samplePlan() => AiCompleteTripPlan.fromJson(
      jsonDecode(_validCompleteTripJson()) as Map<String, dynamic>,
    );

AiGeneratedItinerary _sampleItinerary() => AiGeneratedItinerary.fromJson({
      ...jsonDecode(_validItineraryJson()) as Map<String, dynamic>,
      'destination': 'Goa',
      'duration_days': 3,
      'currency': 'INR',
      'budget': 10000,
      'interests': ['beach'],
      'generated_at': '2024-01-01T00:00:00Z',
    });

void main() {
  group('GroqService.generateCompleteTripPlan', () {
    test('200 OK returns parsed plan with bearer auth header', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );

      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'goa beach trip',
        destination: 'Goa',
        durationDays: 3,
        tripType: 'beach',
        budget: 12000,
        interests: const ['beach'],
        groupSize: 2,
      );

      expect(plan.tripName, 'Goan Paradise');
      expect(plan.destination, 'Goa');
      expect(plan.durationDays, 3);
      expect(plan.tripTheme, 'beach');
      expect(plan.days, hasLength(1));
      expect(plan.packingList, hasLength(1));
      expect(plan.tips, hasLength(2));

      // Bearer auth header was sent, request body uses llama-3.3-70b model.
      expect(client.callCount, 1);
      expect(client.calledHeaders.single?['Authorization'], 'Bearer KEY');
      expect(client.calledHeaders.single?['Content-Type'], 'application/json');
      final sentBody = jsonDecode(client.calledBodies.single as String)
          as Map<String, dynamic>;
      expect(sentBody['model'], 'llama-3.3-70b-versatile');
      expect(sentBody['max_tokens'], 8192);
      expect(sentBody['temperature'], 0.7);
      expect(sentBody['messages'], hasLength(2));
      expect(sentBody['messages'][0]['role'], 'system');
      expect(sentBody['messages'][1]['role'], 'user');
    });

    test('429 immediately fails (no retry) to save quota', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq rate limited'))),
      );
      // No retries on 429.
      expect(client.callCount, 1);
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 503, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.days, isNotEmpty);
      expect(client.callCount, 2);
    });

    test('repeated 500 exhausts retries and throws server error', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Groq server error'))),
      );
      // 1 initial + 3 retries = 4 calls
      expect(client.callCount, 4);
    });

    test('400 with structured error body extracts error.message', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 400,
        body: jsonEncode({
          'error': {'message': 'invalid request payload'},
        }),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('invalid request payload'))),
      );
    });

    test('400 with non-JSON body still throws Groq API error', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 400, body: 'not json');
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Groq API error: 400'))),
      );
    });

    test('throws when choices is empty', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'choices': []}),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from Groq'))),
      );
    });

    test('throws when choices is missing', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'foo': 'bar'}),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from Groq'))),
      );
    });

    test('throws when content is null', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'choices': [
            {
              'message': {'content': null},
            },
          ],
        }),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Empty response'))),
      );
    });

    test('throws when content is empty string', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(''),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Empty response'))),
      );
    });

    test('bad inner JSON throws Failed to parse', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('not json {{{'),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse Groq AI response'))),
      );
    });

    test('strips ```json fenced markdown wrapper before parsing', () async {
      final client = _FakeHttpClient();
      final fenced = '```json\n${_validCompleteTripJson()}\n```';
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(fenced),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.tripName, 'Goan Paradise');
    });

    test('strips bare ``` fenced markdown wrapper', () async {
      final client = _FakeHttpClient();
      final fenced = '```\n${_validCompleteTripJson()}\n```';
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(fenced),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.tripName, 'Goan Paradise');
    });

    test('trims preamble before first { and trailing text after last }',
        () async {
      final client = _FakeHttpClient();
      final padded =
          'Here is the plan you asked for:\n${_validCompleteTripJson()}\nThanks!';
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(padded),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.tripName, 'Goan Paradise');
    });

    test('omits optional params successfully', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
        // tripType, budget, interests, groupSize all omitted/defaulted
      );
      expect(plan, isNotNull);
      expect(plan.days, isNotEmpty);
    });

    test('uses USD currency symbol when specified', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'NYC',
        durationDays: 3,
        budget: 1500,
        currency: 'USD',
      );
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      // Prompt content includes the dollar symbol when currency=USD
      final userMsg = body['messages'][1]['content'] as String;
      expect(userMsg, contains('USD'));
      expect(userMsg, contains(r'$'));
    });

    test('uses default INR currency symbol', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
        budget: 25000,
      );
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      final userMsg = body['messages'][1]['content'] as String;
      expect(userMsg, contains('INR'));
      expect(userMsg, contains('₹'));
    });

    test('exotic currency falls back to currency code with space', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Cairo',
        durationDays: 3,
        budget: 5000,
        currency: 'EGP',
      );
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      final userMsg = body['messages'][1]['content'] as String;
      expect(userMsg, contains('EGP'));
    });
  });

  group('GroqService.generateCompleteTripPlanFromVoice', () {
    test('200 OK returns parsed plan', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      final plan = await _service(client).generateCompleteTripPlanFromVoice(
        voiceInput: 'I want to go to Goa for 3 days',
      );
      expect(plan.destination, 'Goa');
      expect(plan.durationDays, 3);
      expect(plan.startDate, isNotNull);
      expect(plan.endDate, isNotNull);
      expect(plan.tripTheme, 'beach');
    });

    test('429 fails fast (Groq does not retry to save quota)', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'goa'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq rate limited'))),
      );
      expect(client.callCount, 1);
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 502, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      final plan = await _service(client).generateCompleteTripPlanFromVoice(
        voiceInput: 'goa',
      );
      expect(plan.days, isNotEmpty);
      expect(client.callCount, 2);
    });

    test('repeated 5xx exhausts retries and throws', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq server error'))),
      );
    });

    test('400 with error.message included', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 400,
        body: jsonEncode({
          'error': {'message': 'bad input'},
        }),
      );
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('bad input'))),
      );
    });

    test('400 without parsable error body still throws', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 401, body: 'unauthenticated');
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq API error: 401'))),
      );
    });

    test('empty choices throws No response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'choices': []}),
      );
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from Groq'))),
      );
    });

    test('null content throws Empty response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'choices': [
            {
              'message': {'content': null},
            },
          ],
        }),
      );
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Empty response'))),
      );
    });

    test('bad inner JSON throws Failed to parse', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('garbage'),
      );
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse Groq AI response'))),
      );
    });

    test('handles markdown-wrapped response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('```json\n${_validCompleteTripJson()}\n```'),
      );
      final plan = await _service(client).generateCompleteTripPlanFromVoice(
        voiceInput: 'goa trip',
      );
      expect(plan.destination, 'Goa');
    });
  });

  group('GroqService.refineTripPlan', () {
    test('200 OK returns refined plan with lower temperature in request',
        () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      final plan = await _service(client).refineTripPlan(
        currentPlan: _samplePlan(),
        refinementRequest: 'Add temple visits',
      );
      expect(plan.tripName, 'Goan Paradise');
      // Refinement uses lower temperature for consistency
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      expect(body['temperature'], 0.5);
    });

    test('429 fails fast', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'add stuff',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq rate limited'))),
      );
      expect(client.callCount, 1);
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 503, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      final plan = await _service(client).refineTripPlan(
        currentPlan: _samplePlan(),
        refinementRequest: 'do it',
      );
      expect(plan.days, isNotEmpty);
      expect(client.callCount, 2);
    });

    test('repeated 5xx exhausts retries and throws', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Groq server error during refinement'))),
      );
    });

    test('400 with error.message included', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 400,
        body: jsonEncode({
          'error': {'message': 'context too long'},
        }),
      );
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('context too long'))),
      );
    });

    test('400 plain body throws Groq API refinement error', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 422, body: 'broken');
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Groq API refinement error'))),
      );
    });

    test('empty choices throws No refinement response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'choices': []}),
      );
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('No refinement response'))),
      );
    });

    test('null content throws Empty refinement response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'choices': [
            {
              'message': {'content': null},
            },
          ],
        }),
      );
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Empty refinement response'))),
      );
    });

    test('bad inner JSON throws Failed to parse refined plan', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('not json'),
      );
      await expectLater(
        _service(client).refineTripPlan(
          currentPlan: _samplePlan(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse refined plan'))),
      );
    });

    test('refinement prompt includes refinement request text', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripJson()),
      );
      await _service(client).refineTripPlan(
        currentPlan: _samplePlan(),
        refinementRequest: 'Add a camel ride on day 2',
      );
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      final userMsg = body['messages'][1]['content'] as String;
      expect(userMsg, contains('Add a camel ride on day 2'));
      expect(userMsg, contains('Goan Paradise'));
    });
  });

  group('GroqService.refineItinerary', () {
    test('200 OK returns refined itinerary', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      final itinerary = await _service(client).refineItinerary(
        currentItinerary: _sampleItinerary(),
        refinementRequest: 'add yoga',
      );
      expect(itinerary.days, isNotEmpty);
      expect(itinerary.destination, 'Goa');

      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      expect(body['temperature'], 0.5);
    });

    test('429 fails fast', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq rate limited'))),
      );
      expect(client.callCount, 1);
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 502, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      final itinerary = await _service(client).refineItinerary(
        currentItinerary: _sampleItinerary(),
        refinementRequest: 'x',
      );
      expect(itinerary.days, isNotEmpty);
      expect(client.callCount, 2);
    });

    test('repeated 5xx exhausts retries and throws', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Groq server error during refinement'))),
      );
    });

    test('400 with error.message', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 400,
        body: jsonEncode({
          'error': {'message': 'too many tokens'},
        }),
      );
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('too many tokens'))),
      );
    });

    test('400 plain body throws Groq API refinement error', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 418, body: 'teapot');
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Groq API refinement error'))),
      );
    });

    test('empty choices throws', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'choices': []}),
      );
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('No refinement response'))),
      );
    });

    test('null content throws Empty refinement response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'choices': [
            {
              'message': {'content': null},
            },
          ],
        }),
      );
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Empty refinement response'))),
      );
    });

    test('bad inner JSON throws Failed to parse', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('garbage'),
      );
      await expectLater(
        _service(client).refineItinerary(
          currentItinerary: _sampleItinerary(),
          refinementRequest: 'x',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse refined itinerary'))),
      );
    });

    test('preserves destination/duration/budget/currency from current',
        () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      final itinerary = await _service(client).refineItinerary(
        currentItinerary: _sampleItinerary(),
        refinementRequest: 'add yoga',
      );
      // The refined itinerary inherits the original metadata.
      expect(itinerary.destination, 'Goa');
      expect(itinerary.durationDays, 3);
      expect(itinerary.budget, 10000);
      expect(itinerary.currency, 'INR');
    });
  });

  group('GroqService.generateItinerary', () {
    test('200 OK returns itinerary with forwarded request fields', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      final result = await _service(client).generateItinerary(_request);
      expect(result.destination, 'Goa');
      expect(result.durationDays, 3);
      expect(result.budget, 10000);
      expect(result.currency, 'INR');
      expect(result.interests, ['beach', 'food']);
      expect(result.days, hasLength(1));
      expect(result.packingList, hasLength(1));
      expect(result.tips, ['Tip 1']);
      expect(result.summary, 'A nice trip');
    });

    test('429 fails fast (no retry)', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq rate limited'))),
      );
      expect(client.callCount, 1);
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 502, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      final result = await _service(client).generateItinerary(_request);
      expect(result.destination, 'Goa');
      expect(client.callCount, 2);
    });

    test('repeated 500 exhausts retries and throws', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq server error'))),
      );
    });

    test('400 with structured error.message', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 400,
        body: jsonEncode({
          'error': {'message': 'invalid model'},
        }),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('invalid model'))),
      );
    });

    test('400 plain body throws Groq API error', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 400, body: 'oops');
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Groq API error: 400'))),
      );
    });

    test('empty choices throws No response from Groq', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'choices': []}),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from Groq'))),
      );
    });

    test('empty content string throws Empty response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(''),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Empty response'))),
      );
    });

    test('bad inner JSON throws Failed to parse', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('not json {{{'),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse Groq AI response'))),
      );
    });

    test('AiItineraryRequest with no budget/interests is accepted', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      const minimal = AiItineraryRequest(
        destination: 'Manali',
        durationDays: 5,
      );
      final result = await _service(client).generateItinerary(minimal);
      expect(result.destination, 'Manali');
      expect(result.durationDays, 5);
    });

    test('handles markdown-wrapped itinerary response', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('```json\n${_validItineraryJson()}\n```'),
      );
      final result = await _service(client).generateItinerary(_request);
      expect(result.days, hasLength(1));
    });

    test('uses USD currency in itinerary prompt', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      const usdRequest = AiItineraryRequest(
        destination: 'NYC',
        durationDays: 3,
        budget: 1500,
        currency: 'USD',
      );
      await _service(client).generateItinerary(usdRequest);
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      final userMsg = body['messages'][1]['content'] as String;
      expect(userMsg, contains('USD'));
    });

    test('forwards companions/transport in prompt context', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryJson()),
      );
      final richRequest = AiItineraryRequest(
        destination: 'Goa',
        durationDays: 3,
        currency: 'INR',
        companions: const [
          TripCompanion(name: 'Alice', relation: 'partner', age: 30),
        ],
        primaryTransport: TransportMode.flight,
        localTransport: TransportMode.uber,
        weatherContext: 'sunny',
        localEvents: 'Carnival',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 7, 3),
        preferredTiming: const DailyTiming(
          wakeUpTime: '06:00',
          sleepTime: '22:00',
          breakfastTime: '08:00',
          lunchTime: '13:00',
          dinnerTime: '20:00',
        ),
      );
      await _service(client).generateItinerary(richRequest);
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      final userMsg = body['messages'][1]['content'] as String;
      expect(userMsg, contains('Alice'));
      expect(userMsg, contains('partner'));
      expect(userMsg, contains('Carnival'));
      expect(userMsg, contains('06:00'));
    });
  });

  group('Default constructor wiring', () {
    test('default GroqService has working _DefaultGroqHttpClient instance',
        () {
      // Just ensure construction succeeds without httpClient param. We do
      // not invoke methods (which would touch real network).
      final service = GroqService('KEY');
      expect(service, isA<GroqService>());
    });

    test('default delay is real Future.delayed (not crashing on construction)',
        () {
      // Construct without delay parameter; the field is null and _sleep
      // routes to Future.delayed in production.
      final service = GroqService('KEY');
      expect(service, isA<GroqService>());
    });
  });
}
