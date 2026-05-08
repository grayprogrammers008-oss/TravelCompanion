import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:travel_crew/core/services/groq_whisper_service.dart';

/// Hand-rolled fake of [WhisperHttpSender]. Each `send` call captures the
/// request and returns the next queued response.
class _FakeWhisperSender implements WhisperHttpSender {
  final List<Object> queue = [];
  final List<http.MultipartRequest> sentRequests = [];

  void enqueue({required int statusCode, required String body}) {
    queue.add(http.Response(body, statusCode));
  }

  void enqueueThrow(Object error) {
    queue.add(error);
  }

  @override
  Future<http.Response> send(http.MultipartRequest request) async {
    sentRequests.add(request);
    if (queue.isEmpty) {
      throw StateError('No queued response');
    }
    final next = queue.removeAt(0);
    if (next is http.Response) return next;
    throw next;
  }
}

GroqWhisperService _service(_FakeWhisperSender sender) =>
    GroqWhisperService('test-key', httpSender: sender);

/// Create a temporary file with given size for upload.
Future<File> _makeTempAudio({int sizeBytes = 100}) async {
  final dir = await Directory.systemTemp.createTemp('whisper_test_');
  final file = File('${dir.path}/audio.wav');
  await file.writeAsBytes(List<int>.filled(sizeBytes, 0));
  return file;
}

void main() {
  group('WhisperTranscriptionResult', () {
    test('default constructor sets success=true', () {
      const r = WhisperTranscriptionResult(text: 'hi');
      expect(r.success, isTrue);
      expect(r.error, isNull);
      expect(r.text, 'hi');
    });

    test('factory error sets text=empty and success=false', () {
      final r = WhisperTranscriptionResult.error('oops');
      expect(r.text, '');
      expect(r.success, isFalse);
      expect(r.error, 'oops');
    });

    test('toString includes core fields', () {
      const r = WhisperTranscriptionResult(text: 'hi', detectedLanguage: 'en');
      final s = r.toString();
      expect(s, contains('hi'));
      expect(s, contains('en'));
      expect(s, contains('true'));
    });
  });

  group('GroqWhisperService.supportedLanguages', () {
    test('contains common Indian languages', () {
      expect(GroqWhisperService.supportedLanguages.containsKey('ta'), isTrue);
      expect(GroqWhisperService.supportedLanguages.containsKey('hi'), isTrue);
      expect(GroqWhisperService.supportedLanguages.containsKey('en'), isTrue);
    });

    test('getLanguageName returns name for known code', () {
      expect(GroqWhisperService.getLanguageName('ta'), 'Tamil');
      expect(GroqWhisperService.getLanguageName('hi'), 'Hindi');
      expect(GroqWhisperService.getLanguageName('en'), 'English');
    });

    test('getLanguageName returns code for unknown code', () {
      expect(GroqWhisperService.getLanguageName('xx'), 'xx');
    });

    test('isLanguageSupported returns true/false', () {
      expect(GroqWhisperService.isLanguageSupported('ta'), isTrue);
      expect(GroqWhisperService.isLanguageSupported('xx'), isFalse);
    });
  });

  group('GroqWhisperService.transcribeFile', () {
    test('200 OK parses text/language/duration', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(
        statusCode: 200,
        body: jsonEncode({
          'text': 'Hello world  ',
          'language': 'en',
          'duration': 1.5,
        }),
      );
      final file = await _makeTempAudio();
      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
      );
      expect(result.success, isTrue);
      expect(result.text, 'Hello world'); // Trimmed
      expect(result.detectedLanguage, 'en');
      expect(result.duration, 1.5);

      // Verify request configuration
      final req = sender.sentRequests.single;
      expect(req.method, 'POST');
      expect(req.url.toString(),
          'https://api.groq.com/openai/v1/audio/transcriptions');
      expect(req.headers['Authorization'], 'Bearer test-key');
      expect(req.fields['model'], 'whisper-large-v3-turbo');
      expect(req.fields['response_format'], 'verbose_json');
      expect(req.fields['temperature'], '0.0');
      // language not set when not provided
      expect(req.fields.containsKey('language'), isFalse);
      expect(req.fields.containsKey('prompt'), isFalse);
    });

    test('uses full model for Tamil (low-resource language)', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(
        statusCode: 200,
        // Use ASCII-safe text since http.Response uses latin-1 encoding.
        body: jsonEncode({'text': 'Vanakkam', 'language': 'ta'}),
      );
      final file = await _makeTempAudio();
      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
        language: 'ta',
        prompt: 'travel context here',
        temperature: 0.2,
      );
      expect(result.success, isTrue);
      final req = sender.sentRequests.single;
      expect(req.fields['model'], 'whisper-large-v3');
      expect(req.fields['language'], 'ta');
      expect(req.fields['prompt'], 'travel context here');
      expect(req.fields['temperature'], '0.2');
    });

    test('uses turbo model for English', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(
        statusCode: 200,
        body: jsonEncode({'text': 'Hello'}),
      );
      final file = await _makeTempAudio();
      await _service(sender).transcribeFile(
        audioFilePath: file.path,
        language: 'en',
      );
      final req = sender.sentRequests.single;
      expect(req.fields['model'], 'whisper-large-v3-turbo');
      expect(req.fields['language'], 'en');
    });

    test('useFullModelForIndianLanguages=false keeps turbo for ta', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(
        statusCode: 200,
        body: jsonEncode({'text': 'x'}),
      );
      final file = await _makeTempAudio();
      final svc = GroqWhisperService(
        'k',
        httpSender: sender,
        useFullModelForIndianLanguages: false,
      );
      await svc.transcribeFile(
        audioFilePath: file.path,
        language: 'ta',
      );
      final req = sender.sentRequests.single;
      expect(req.fields['model'], 'whisper-large-v3-turbo');
    });

    test('returns error result when file does not exist', () async {
      final sender = _FakeWhisperSender();
      final result = await _service(sender).transcribeFile(
        audioFilePath: '/nonexistent/path/audio.wav',
      );
      expect(result.success, isFalse);
      expect(result.error, contains('Audio file not found'));
      expect(sender.sentRequests, isEmpty);
    });

    test('returns error when file >25MB', () async {
      final sender = _FakeWhisperSender();
      final dir = await Directory.systemTemp.createTemp('whisper_big_');
      final file = File('${dir.path}/big.wav');
      // Create a sparse 26MB file by writing 1 byte at offset 26MB.
      final raf = await file.open(mode: FileMode.write);
      await raf.setPosition(26 * 1024 * 1024);
      await raf.writeByte(0);
      await raf.close();

      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
      );
      expect(result.success, isFalse);
      expect(result.error, contains('too large'));
      expect(sender.sentRequests, isEmpty);
    });

    test('non-200 returns error result with parsed message', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(
        statusCode: 401,
        body: jsonEncode({
          'error': {'message': 'Invalid API key'}
        }),
      );
      final file = await _makeTempAudio();
      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
      );
      expect(result.success, isFalse);
      expect(result.error, 'Invalid API key');
    });

    test('non-200 with non-JSON body uses default error message', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(statusCode: 500, body: 'internal');
      final file = await _makeTempAudio();
      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
      );
      expect(result.success, isFalse);
      expect(result.error, 'Transcription failed');
    });

    test('exception during send returns error result', () async {
      final sender = _FakeWhisperSender();
      sender.enqueueThrow(Exception('network'));
      final file = await _makeTempAudio();
      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
      );
      expect(result.success, isFalse);
      expect(result.error, contains('Transcription error'));
    });

    test('handles missing optional fields in success response', () async {
      final sender = _FakeWhisperSender();
      sender.enqueue(statusCode: 200, body: jsonEncode({}));
      final file = await _makeTempAudio();
      final result = await _service(sender).transcribeFile(
        audioFilePath: file.path,
      );
      expect(result.success, isTrue);
      expect(result.text, '');
      expect(result.detectedLanguage, isNull);
      expect(result.duration, isNull);
    });
  });
}
