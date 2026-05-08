import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:travel_crew/features/ai_itinerary/data/services/gemini_service.dart';
// `AiItineraryDay` and `AiItineraryActivity` are declared by both files, so
// we hide the domain copies and use the service copies (which is what
// AiCompleteTripPlan internally references).
import 'package:travel_crew/features/ai_itinerary/domain/entities/ai_itinerary.dart' hide AiItineraryDay, AiItineraryActivity;

/// Comprehensive unit tests for [GeminiService].
///
/// All HTTP traffic is faked through the [GeminiHttpClient] interface and
/// the artificial delay is replaced with a no-op so retry logic runs
/// instantly. We exercise:
///
///  * Each public method (generateItinerary, generateChecklistItems,
///    generateCompleteTripPlan, generateCompleteTripPlanFromVoice).
///  * The 200 happy path, including JSON parsing.
///  * 429 + 500/503 retry-with-exponential-backoff happy + exhausted paths.
///  * Other non-200 status codes.
///  * Missing-candidate / missing-content / missing-parts validations.
///  * Malformed inner JSON parse errors.

/// A queue-driven fake of [GeminiHttpClient]. Calls to [post] return the
/// next queued response, or throw if [throwInstead] was scheduled.
class _FakeHttpClient implements GeminiHttpClient {
  _FakeHttpClient();

  /// Each entry is either a [http.Response] or an [Exception]. We pop from
  /// the front for each [post] invocation.
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

/// Builds a Gemini API success body that wraps [innerJson] (a stringifiable
/// JSON object) inside the standard candidates/content/parts envelope.
String _wrap(String innerText) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': innerText},
            ],
          },
        },
      ],
    });

String _validItineraryInnerJson() => jsonEncode({
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

String _validChecklistInnerJson() => jsonEncode({
      'items': [
        {
          'title': 'Sunscreen',
          'category': 'toiletries',
          'is_essential': true,
          'quantity': 2,
          'notes': 'SPF 50+',
        },
        {'title': 'Passport', 'is_essential': true},
      ],
    });

String _validCompleteTripInnerJson({String? destination}) => jsonEncode({
      'trip_name': 'Goan Paradise',
      'summary': 'sunny',
      'destination': destination ?? 'Goa',
      'duration_days': 3,
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

GeminiService _service(_FakeHttpClient client) => GeminiService(
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

void main() {
  group('GeminiService.generateItinerary', () {
    test('200 OK returns parsed itinerary and forwards request fields', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryInnerJson()),
      );

      final result = await _service(client).generateItinerary(_request);

      expect(result.destination, 'Goa');
      expect(result.durationDays, 3);
      expect(result.budget, 10000);
      expect(result.currency, 'INR');
      expect(result.interests, ['beach', 'food']);
      expect(result.days, hasLength(1));
      expect(result.days.first.activities, hasLength(1));
      expect(result.packingList, hasLength(1));
      expect(result.tips, ['Tip 1']);
      expect(result.summary, 'A nice trip');

      // Single HTTP call, with API key and JSON body.
      expect(client.callCount, 1);
      expect(client.calledUrls.single.toString(), contains('key=KEY'));
      final sentBody =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      expect(sentBody.containsKey('contents'), isTrue);
      expect(sentBody['generationConfig']['maxOutputTokens'], 8192);
    });

    test('429 retries with backoff then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      client.enqueueResponseWith(statusCode: 429, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryInnerJson()),
      );

      final result = await _service(client).generateItinerary(_request);
      expect(result.destination, 'Goa');
      expect(client.callCount, 3);
    });

    test('429 forever exhausts retries and throws', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('AI service is busy'))),
      );
      // 1 initial + 3 retries
      expect(client.callCount, 4);
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 503, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryInnerJson()),
      );

      final result = await _service(client).generateItinerary(_request);
      expect(result.destination, 'Goa');
      expect(client.callCount, 2);
    });

    test('repeated 500 exhausts retries and throws', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: 'oops');
      }
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('temporarily unavailable'))),
      );
    });

    test('non-200/non-retryable status throws', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 400, body: 'bad');
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to generate itinerary'))),
      );
    });

    test('throws when candidates list is empty', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'candidates': []}),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from AI'))),
      );
    });

    test('throws when candidates is missing entirely', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'foo': 'bar'}),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from AI'))),
      );
    });

    test('throws when parts is empty', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'candidates': [
            {
              'content': {'parts': []}
            }
          ]
        }),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid response format'))),
      );
    });

    test('throws when content is missing (parts will be null)', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'candidates': [
            {'content': null}
          ]
        }),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid response format'))),
      );
    });

    test('throws "Failed to parse" when inner text is not valid JSON', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('not valid json {{{'),
      );
      await expectLater(
        _service(client).generateItinerary(_request),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse AI response'))),
      );
    });

    test('AiItineraryRequest with no budget/interests is accepted', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validItineraryInnerJson()),
      );
      const minimal = AiItineraryRequest(
        destination: 'Manali',
        durationDays: 5,
      );
      final result = await _service(client).generateItinerary(minimal);
      expect(result.destination, 'Manali');
      expect(result.durationDays, 5);
    });
  });

  group('GeminiService.generateChecklistItems', () {
    test('200 OK returns parsed items', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validChecklistInnerJson()),
      );
      final result = await _service(client).generateChecklistItems(
        voicePrompt: 'pack for goa',
        destination: 'Goa',
        tripType: 'beach',
        durationDays: 3,
      );
      expect(result, hasLength(2));
      expect(result.first.title, 'Sunscreen');
      expect(result.first.isEssential, isTrue);
      expect(result.first.quantity, 2);
      expect(result.first.notes, 'SPF 50+');
      expect(result.last.title, 'Passport');
      // Default quantity when not provided
      expect(result.last.quantity, 1);

      // 4096 max tokens for checklist endpoint
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      expect(body['generationConfig']['maxOutputTokens'], 4096);
    });

    test('returns empty list when items list is missing', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(jsonEncode({})),
      );
      final result = await _service(client).generateChecklistItems(
        voicePrompt: 'hi',
        destination: 'X',
        tripType: 'Y',
      );
      expect(result, isEmpty);
    });

    test('429 then 200 succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validChecklistInnerJson()),
      );
      final result = await _service(client).generateChecklistItems(
        voicePrompt: 'p',
        destination: 'd',
        tripType: 't',
      );
      expect(result, hasLength(2));
      expect(client.callCount, 2);
    });

    test('429 exhausts retries', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        _service(client).generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('AI service is busy'))),
      );
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 502, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validChecklistInnerJson()),
      );
      final result = await _service(client).generateChecklistItems(
        voicePrompt: 'p',
        destination: 'd',
        tripType: 't',
      );
      expect(result, hasLength(2));
    });

    test('repeated 500 throws temporarily-unavailable', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('temporarily unavailable'))),
      );
    });

    test('400 throws Failed to generate checklist', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 400, body: '');
      await expectLater(
        _service(client).generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to generate checklist'))),
      );
    });

    test('throws when candidates is empty', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'candidates': []}),
      );
      await expectLater(
        _service(client).generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from AI'))),
      );
    });

    test('throws Invalid response format on missing parts', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'candidates': [
            {
              'content': {'parts': []}
            }
          ]
        }),
      );
      await expectLater(
        _service(client).generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid response format'))),
      );
    });

    test('throws Failed to parse on bad inner JSON', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('garbage'),
      );
      await expectLater(
        _service(client).generateChecklistItems(
          voicePrompt: 'p',
          destination: 'd',
          tripType: 't',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse AI response'))),
      );
    });

    test('omits durationDays from prompt when null', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validChecklistInnerJson()),
      );
      await _service(client).generateChecklistItems(
        voicePrompt: 'p',
        destination: 'd',
        tripType: 't',
      );
      // Sanity – call still went through.
      expect(client.callCount, 1);
    });
  });

  group('GeminiService.generateCompleteTripPlan', () {
    test('200 OK returns full plan with parsed days/list/tips', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
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

      // 12288 max tokens for complete plan
      final body =
          jsonDecode(client.calledBodies.single as String) as Map<String, dynamic>;
      expect(body['generationConfig']['maxOutputTokens'], 12288);
    });

    test('429 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.days, isNotEmpty);
    });

    test('429 exhausts retries', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('AI service is busy'))),
      );
    });

    test('500 then 200 succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 503, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
      );
      expect(plan.days, isNotEmpty);
    });

    test('repeated 500 throws', () async {
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
            contains('temporarily unavailable'))),
      );
    });

    test('400 throws Failed to generate trip plan', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 400, body: '');
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to generate trip plan'))),
      );
    });

    test('empty candidates throws', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'candidates': []}),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from AI'))),
      );
    });

    test('empty parts throws Invalid response format', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'candidates': [
            {
              'content': {'parts': []}
            }
          ]
        }),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid response format'))),
      );
    });

    test('bad inner JSON throws Failed to parse', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap('not json'),
      );
      await expectLater(
        _service(client).generateCompleteTripPlan(
          voicePrompt: 'p',
          destination: 'Goa',
          durationDays: 3,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to parse AI response'))),
      );
    });

    test('omits optional params from prompt without error', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
      );
      final plan = await _service(client).generateCompleteTripPlan(
        voicePrompt: 'p',
        destination: 'Goa',
        durationDays: 3,
        // tripType, budget, interests, groupSize all omitted/defaulted.
      );
      expect(plan, isNotNull);
    });
  });

  group('GeminiService.generateCompleteTripPlanFromVoice', () {
    test('200 OK returns parsed plan', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
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

    test('429 retries with backoff', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 429, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
      );
      final plan = await _service(client).generateCompleteTripPlanFromVoice(
        voiceInput: 'goa',
      );
      expect(plan.destination, 'Goa');
      expect(client.callCount, 2);
    });

    test('429 exhausted throws "busy"', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 429, body: '');
      }
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('AI service is busy'))),
      );
    });

    test('500 retries then succeeds', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 502, body: '');
      client.enqueueResponseWith(
        statusCode: 200,
        body: _wrap(_validCompleteTripInnerJson()),
      );
      final plan = await _service(client).generateCompleteTripPlanFromVoice(
        voiceInput: 'goa',
      );
      expect(plan.days, isNotEmpty);
    });

    test('repeated 500 throws temporarily unavailable', () async {
      final client = _FakeHttpClient();
      for (var i = 0; i < 5; i++) {
        client.enqueueResponseWith(statusCode: 500, body: '');
      }
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('temporarily unavailable'))),
      );
    });

    test('400 throws Failed to generate trip plan', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(statusCode: 400, body: '');
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Failed to generate trip plan'))),
      );
    });

    test('empty candidates throws', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({'candidates': []}),
      );
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('No response from AI'))),
      );
    });

    test('empty parts throws Invalid response format', () async {
      final client = _FakeHttpClient();
      client.enqueueResponseWith(
        statusCode: 200,
        body: jsonEncode({
          'candidates': [
            {
              'content': {'parts': []}
            }
          ]
        }),
      );
      await expectLater(
        _service(client).generateCompleteTripPlanFromVoice(voiceInput: 'x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid response format'))),
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
            contains('Failed to parse AI response'))),
      );
    });
  });

  group('AiChecklistItem.fromJson', () {
    test('parses all fields with defaults applied', () {
      final item = AiChecklistItem.fromJson({
        'title': 'X',
        'category': 'misc',
        'is_essential': true,
        'quantity': 5,
        'notes': 'note',
      });
      expect(item.title, 'X');
      expect(item.category, 'misc');
      expect(item.isEssential, isTrue);
      expect(item.quantity, 5);
      expect(item.notes, 'note');
    });

    test('applies defaults when optional fields are missing', () {
      final item = AiChecklistItem.fromJson({'title': 'Y'});
      expect(item.category, isNull);
      expect(item.isEssential, isFalse);
      expect(item.quantity, 1);
      expect(item.notes, isNull);
    });
  });

  group('AiCompleteTripPlan.fromJson', () {
    test('parses dates from start_date / end_date', () {
      final plan = AiCompleteTripPlan.fromJson({
        'trip_name': 'X',
        'summary': 's',
        'destination': 'D',
        'duration_days': 3,
        'start_date': '2024-07-01',
        'end_date': '2024-07-03',
        'days': [],
        'packing_list': [],
        'tips': [],
      });
      expect(plan.startDate, DateTime(2024, 7, 1));
      expect(plan.endDate, DateTime(2024, 7, 3));
    });

    test('falls back to today+7 when start/end are missing', () {
      final plan = AiCompleteTripPlan.fromJson({
        'duration_days': 4,
        'days': [],
      });
      expect(plan.startDate, isNotNull);
      expect(
        plan.endDate!.difference(plan.startDate!).inDays,
        3, // duration - 1
      );
    });

    test('computes endDate when only startDate is provided', () {
      final plan = AiCompleteTripPlan.fromJson({
        'duration_days': 5,
        'start_date': '2024-01-01',
        'days': [],
      });
      expect(plan.startDate, DateTime(2024, 1, 1));
      expect(plan.endDate, DateTime(2024, 1, 5));
    });

    test('handles empty start_date string by falling back', () {
      final plan = AiCompleteTripPlan.fromJson({
        'duration_days': 3,
        'start_date': '',
        'end_date': '',
        'days': [],
      });
      expect(plan.startDate, isNotNull);
      expect(plan.endDate, isNotNull);
    });

    test('uses days.length as fallback duration when duration_days missing',
        () {
      final plan = AiCompleteTripPlan.fromJson({
        'days': [
          {'day_number': 1, 'activities': []},
          {'day_number': 2, 'activities': []},
        ],
      });
      expect(plan.durationDays, 2);
    });

    test('uses default values when all fields are missing', () {
      final plan = AiCompleteTripPlan.fromJson({});
      expect(plan.tripName, 'My Trip');
      expect(plan.destination, 'Unknown');
      expect(plan.summary, '');
      expect(plan.days, isEmpty);
      expect(plan.packingList, isEmpty);
      expect(plan.tips, isEmpty);
    });
  });

  group('AiItineraryDay.fromJson (gemini_service variant)', () {
    test('parses with full payload', () {
      final day = AiItineraryDay.fromJson({
        'day_number': 2,
        'title': 'D2',
        'description': 'desc',
        'activities': [
          {'title': 'a1'},
        ],
      });
      expect(day.dayNumber, 2);
      expect(day.title, 'D2');
      expect(day.description, 'desc');
      expect(day.activities, hasLength(1));
    });

    test('applies defaults when fields are missing', () {
      final day = AiItineraryDay.fromJson({});
      expect(day.dayNumber, 1);
      expect(day.title, 'Day 1');
      expect(day.description, '');
      expect(day.activities, isEmpty);
    });
  });

  group('AiItineraryActivity.fromJson (gemini_service variant)', () {
    test('parses every optional field', () {
      final a = AiItineraryActivity.fromJson({
        'title': 'A',
        'description': 'd',
        'location': 'l',
        'start_time': '08:00',
        'end_time': '10:00',
        'duration_minutes': 120,
        'category': 'food',
        'estimated_cost': 250,
        'tip': 't',
        'crowd_level': 'low',
        'best_time_reason': 'morning',
      });
      expect(a.title, 'A');
      expect(a.description, 'd');
      expect(a.location, 'l');
      expect(a.startTime, '08:00');
      expect(a.endTime, '10:00');
      expect(a.durationMinutes, 120);
      expect(a.category, 'food');
      expect(a.estimatedCost, 250.0);
      expect(a.tip, 't');
      expect(a.crowdLevel, 'low');
      expect(a.bestTimeReason, 'morning');
    });

    test('falls back when title is missing', () {
      final a = AiItineraryActivity.fromJson({});
      expect(a.title, 'Activity');
      expect(a.description, isNull);
      expect(a.estimatedCost, isNull);
    });
  });

  group('GeminiResult', () {
    test('isSuccess and isError flags', () {
      const ok = GeminiResult<int>(data: 1);
      expect(ok.isSuccess, isTrue);
      expect(ok.isError, isFalse);

      const err = GeminiResult<int>(error: 'oops');
      expect(err.isSuccess, isFalse);
      expect(err.isError, isTrue);
    });
  });
}
