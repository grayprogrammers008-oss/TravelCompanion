import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:travel_crew/core/services/email_service.dart';

/// Hand-rolled fake of [EmailHttpClient]. Each `get`/`post` call pops
/// the next queued response or rethrows the next queued exception.
class _FakeEmailHttpClient implements EmailHttpClient {
  final List<Object> getQueue = [];
  final List<Object> postQueue = [];
  final List<Uri> postedUrls = [];
  final List<Map<String, String>?> postedHeaders = [];
  final List<Object?> postedBodies = [];
  final List<Uri> getUrls = [];
  final List<Map<String, String>?> getHeaders = [];

  void enqueueGet({required int statusCode, required String body}) =>
      getQueue.add(http.Response(body, statusCode));
  void enqueueGetThrow(Object error) => getQueue.add(error);

  void enqueuePost({required int statusCode, required String body}) =>
      postQueue.add(http.Response(body, statusCode));
  void enqueuePostThrow(Object error) => postQueue.add(error);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    getUrls.add(url);
    getHeaders.add(headers);
    if (getQueue.isEmpty) {
      throw StateError('No queued GET response');
    }
    final next = getQueue.removeAt(0);
    if (next is http.Response) return next;
    throw next;
  }

  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    postedUrls.add(url);
    postedHeaders.add(headers);
    postedBodies.add(body);
    if (postQueue.isEmpty) {
      throw StateError('No queued POST response');
    }
    final next = postQueue.removeAt(0);
    if (next is http.Response) return next;
    throw next;
  }
}

EmailService _service(_FakeEmailHttpClient client) => EmailService.test(
      httpClient: client,
      apiKey: 'test-key',
      senderEmail: 'sender@test.com',
      senderName: 'Test Sender',
    );

void main() {
  group('EmailService.testConnection', () {
    test('returns true on 200 with body', () async {
      final client = _FakeEmailHttpClient();
      client.enqueueGet(
        statusCode: 200,
        body: jsonEncode({
          'email': 'a@b.com',
          'companyName': 'Co',
          'plan': 'free',
        }),
      );
      final ok = await _service(client).testConnection();
      expect(ok, isTrue);
      expect(client.getUrls.single.toString(),
          'https://api.brevo.com/v3/account');
      expect(client.getHeaders.single, containsPair('api-key', 'test-key'));
      expect(client.getHeaders.single,
          containsPair('Accept', 'application/json'));
    });

    test('returns false on non-200', () async {
      final client = _FakeEmailHttpClient();
      client.enqueueGet(statusCode: 401, body: 'unauthorized');
      expect(await _service(client).testConnection(), isFalse);
    });

    test('returns false when an exception is thrown', () async {
      final client = _FakeEmailHttpClient();
      client.enqueueGetThrow(Exception('network down'));
      expect(await _service(client).testConnection(), isFalse);
    });

    test('returns false on 500', () async {
      final client = _FakeEmailHttpClient();
      client.enqueueGet(statusCode: 500, body: '');
      expect(await _service(client).testConnection(), isFalse);
    });
  });

  group('EmailService.sendTripInvite', () {
    test('returns true on 201 and posts to correct URL with API key', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(
        statusCode: 201,
        body: jsonEncode({'messageId': 'msg-1'}),
      );
      final ok = await _service(client).sendTripInvite(
        toEmail: 'a@b.com',
        toName: 'Alice',
        tripName: 'Bali Trip',
        inviterName: 'Bob',
        inviteCode: 'ABC123',
        tripDestination: 'Bali',
        tripStartDate: 'Jan 1',
        tripEndDate: 'Jan 8',
      );
      expect(ok, isTrue);
      expect(client.postedUrls.single.toString(),
          'https://api.brevo.com/v3/smtp/email');
      final body =
          jsonDecode(client.postedBodies.single as String) as Map<String, dynamic>;
      expect(body['sender'], {
        'name': 'Test Sender',
        'email': 'sender@test.com',
      });
      expect(body['to'], [
        {'email': 'a@b.com', 'name': 'Alice'}
      ]);
      expect(body['subject'], contains('Bali Trip'));
      // HTML and plain text contents include trip + invite info.
      final html = body['htmlContent'] as String;
      expect(html, contains('Bali Trip'));
      expect(html, contains('ABC123'));
      expect(html, contains('Bali'));
      expect(html, contains('Jan 1 - Jan 8'));
      expect(html, contains('Hi Alice'));
      expect(html, contains('Bob'));
      final text = body['textContent'] as String;
      expect(text, contains('Hi Alice'));
      expect(text, contains('ABC123'));
      expect(text, contains('Bob'));
    });

    test('omits destination/dates section when not provided', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 201, body: jsonEncode({}));
      await _service(client).sendTripInvite(
        toEmail: 'x@y.com',
        toName: 'X',
        tripName: 'T',
        inviterName: 'Y',
        inviteCode: 'C',
      );
      final body =
          jsonDecode(client.postedBodies.single as String) as Map<String, dynamic>;
      final html = body['htmlContent'] as String;
      // No destination text marker
      expect(html, isNot(contains('📍')));
      // No date range marker (would contain '📅')
      expect(html, isNot(contains('📅')));
    });

    test('returns false on non-201 status', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 400, body: 'bad request');
      final ok = await _service(client).sendTripInvite(
        toEmail: 'a@b.com',
        toName: 'A',
        tripName: 'T',
        inviterName: 'I',
        inviteCode: 'C',
      );
      expect(ok, isFalse);
    });

    test('returns false on http error', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePostThrow(Exception('timeout'));
      final ok = await _service(client).sendTripInvite(
        toEmail: 'a@b.com',
        toName: 'A',
        tripName: 'T',
        inviterName: 'I',
        inviteCode: 'C',
      );
      expect(ok, isFalse);
    });
  });

  group('EmailService.sendEmail', () {
    test('sends with all optional fields', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 201, body: '{}');
      final ok = await _service(client).sendEmail(
        toEmail: 'a@b.com',
        subject: 'Hi',
        htmlContent: '<b>Body</b>',
        textContent: 'Body',
        toName: 'Alice',
      );
      expect(ok, isTrue);
      final body =
          jsonDecode(client.postedBodies.single as String) as Map<String, dynamic>;
      expect(body['subject'], 'Hi');
      expect(body['htmlContent'], '<b>Body</b>');
      expect(body['textContent'], 'Body');
      expect(body['to'], [
        {'email': 'a@b.com', 'name': 'Alice'}
      ]);
    });

    test('omits textContent and toName when not provided', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 201, body: '{}');
      final ok = await _service(client).sendEmail(
        toEmail: 'a@b.com',
        subject: 'Hi',
        htmlContent: '<b>x</b>',
      );
      expect(ok, isTrue);
      final body =
          jsonDecode(client.postedBodies.single as String) as Map<String, dynamic>;
      expect(body.containsKey('textContent'), isFalse);
      expect(body['to'], [
        {'email': 'a@b.com'}
      ]);
    });

    test('returns false on non-201', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 500, body: '');
      final ok = await _service(client).sendEmail(
        toEmail: 'a@b.com',
        subject: 's',
        htmlContent: 'h',
      );
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePostThrow(Exception('boom'));
      final ok = await _service(client).sendEmail(
        toEmail: 'a@b.com',
        subject: 's',
        htmlContent: 'h',
      );
      expect(ok, isFalse);
    });
  });

  group('EmailService.sendBulkEmail', () {
    test('formats recipients list and posts JSON', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 201, body: '{}');
      final ok = await _service(client).sendBulkEmail(
        toEmails: const ['a@x.com', 'b@x.com'],
        subject: 'Hello',
        htmlContent: '<p>Hi</p>',
        textContent: 'Hi',
      );
      expect(ok, isTrue);
      final body =
          jsonDecode(client.postedBodies.single as String) as Map<String, dynamic>;
      expect(body['to'], [
        {'email': 'a@x.com'},
        {'email': 'b@x.com'},
      ]);
      expect(body['textContent'], 'Hi');
    });

    test('omits textContent when null', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 201, body: '{}');
      await _service(client).sendBulkEmail(
        toEmails: const ['a@x.com'],
        subject: 's',
        htmlContent: 'h',
      );
      final body =
          jsonDecode(client.postedBodies.single as String) as Map<String, dynamic>;
      expect(body.containsKey('textContent'), isFalse);
    });

    test('returns false on non-201', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePost(statusCode: 400, body: '');
      final ok = await _service(client).sendBulkEmail(
        toEmails: const ['a@x.com'],
        subject: 's',
        htmlContent: 'h',
      );
      expect(ok, isFalse);
    });

    test('returns false on exception', () async {
      final client = _FakeEmailHttpClient();
      client.enqueuePostThrow(Exception('net'));
      final ok = await _service(client).sendBulkEmail(
        toEmails: const ['a@x.com'],
        subject: 's',
        htmlContent: 'h',
      );
      expect(ok, isFalse);
    });
  });

  group('EmailService default constructor', () {
    test('singleton instances are identical', () {
      final a = EmailService();
      final b = EmailService();
      expect(identical(a, b), isTrue);
    });
  });
}
