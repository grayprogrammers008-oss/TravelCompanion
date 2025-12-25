// Groq Whisper Service
//
// Cloud-based speech-to-text using Groq's Whisper API.
// Supports 99+ languages including Tamil, Hindi, and all Indian languages.
// Free tier: 2,000 requests/day (~28 hours of audio)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Result from Whisper transcription
class WhisperTranscriptionResult {
  final String text;
  final String? detectedLanguage;
  final double? duration;
  final bool success;
  final String? error;

  const WhisperTranscriptionResult({
    required this.text,
    this.detectedLanguage,
    this.duration,
    this.success = true,
    this.error,
  });

  factory WhisperTranscriptionResult.error(String errorMessage) {
    return WhisperTranscriptionResult(
      text: '',
      success: false,
      error: errorMessage,
    );
  }

  @override
  String toString() {
    return 'WhisperTranscriptionResult(text: $text, language: $detectedLanguage, success: $success)';
  }
}

/// Groq Whisper Service for multilingual speech-to-text
class GroqWhisperService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';

  // Available Whisper models on Groq:
  // - whisper-large-v3-turbo: Faster, cheaper ($0.04/hr), good for English
  // - whisper-large-v3: Full model ($0.111/hr), better for non-English languages
  //
  // For Indian languages (Tamil, Hindi, etc.), using the full model provides
  // significantly better accuracy at the cost of slightly more processing time.
  static const String _modelTurbo = 'whisper-large-v3-turbo';
  static const String _modelFull = 'whisper-large-v3';

  // Languages that benefit from the full model (low-resource languages)
  static const Set<String> _lowResourceLanguages = {
    'ta', // Tamil
    'te', // Telugu
    'kn', // Kannada
    'ml', // Malayalam
    'mr', // Marathi
    'bn', // Bengali
    'gu', // Gujarati
    'pa', // Punjabi
    'or', // Odia
    'as', // Assamese
    'ne', // Nepali
    'si', // Sinhala
    'ur', // Urdu
  };

  final String _apiKey;
  final bool useFullModelForIndianLanguages;

  GroqWhisperService(this._apiKey, {this.useFullModelForIndianLanguages = true});

  /// Get the appropriate model based on language
  String _getModelForLanguage(String? language) {
    if (useFullModelForIndianLanguages &&
        language != null &&
        _lowResourceLanguages.contains(language)) {
      debugPrint('🔧 Using full Whisper model for better $language accuracy');
      return _modelFull;
    }
    return _modelTurbo;
  }

  /// Supported languages with their codes
  /// Whisper auto-detects language, but you can specify for better accuracy
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ta': 'Tamil',
    'hi': 'Hindi',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'bn': 'Bengali',
    'gu': 'Gujarati',
    'mr': 'Marathi',
    'pa': 'Punjabi',
    'ur': 'Urdu',
    'or': 'Odia',
    'as': 'Assamese',
    'ne': 'Nepali',
    'si': 'Sinhala',
    // International
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'ru': 'Russian',
    'pt': 'Portuguese',
    'it': 'Italian',
  };

  /// Transcribe audio file to text
  ///
  /// [audioFilePath] - Path to the audio file (WAV, MP3, M4A, FLAC, etc.)
  /// [language] - Optional language code (e.g., 'ta' for Tamil). If null, auto-detects.
  /// [prompt] - Optional prompt to guide transcription (helps with domain-specific terms)
  /// [temperature] - Controls randomness (0.0 = most accurate, 1.0 = most creative). Default 0.0
  Future<WhisperTranscriptionResult> transcribeFile({
    required String audioFilePath,
    String? language,
    String? prompt,
    double temperature = 0.0,
  }) async {
    debugPrint('🎙️ GroqWhisperService.transcribeFile() called');
    debugPrint('📁 Audio file: $audioFilePath');
    debugPrint('🌐 Language hint: ${language ?? "auto-detect"}');
    debugPrint('🌡️ Temperature: $temperature');
    if (prompt != null) {
      debugPrint('📝 Prompt preview: ${prompt.substring(0, prompt.length.clamp(0, 100))}...');
    }

    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        return WhisperTranscriptionResult.error('Audio file not found: $audioFilePath');
      }

      final fileSize = await file.length();
      debugPrint('📊 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

      // Whisper has a 25MB file size limit
      if (fileSize > 25 * 1024 * 1024) {
        return WhisperTranscriptionResult.error('Audio file too large (max 25MB)');
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // Add headers
      request.headers['Authorization'] = 'Bearer $_apiKey';

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        audioFilePath,
      ));

      // Select appropriate model based on language
      // Use full model for Indian languages for better accuracy
      final model = _getModelForLanguage(language);
      request.fields['model'] = model;

      // Add response format
      request.fields['response_format'] = 'verbose_json';

      // Note: Groq uses /audio/transcriptions endpoint (not /translations)
      // This should preserve original language, not translate to English

      // Add language if specified (helps with accuracy)
      if (language != null && language.isNotEmpty) {
        request.fields['language'] = language;
        debugPrint('📌 [WHISPER API] Language field set: $language');
      } else {
        debugPrint('📌 [WHISPER API] Language field NOT set (auto-detect mode)');
      }

      // Add prompt if specified (helps with domain-specific terms)
      if (prompt != null && prompt.isNotEmpty) {
        request.fields['prompt'] = prompt;
        debugPrint('📌 [WHISPER API] Prompt field set: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');
      } else {
        debugPrint('📌 [WHISPER API] Prompt field NOT set');
      }

      // Add temperature for accuracy control (0.0 = most accurate)
      request.fields['temperature'] = temperature.toString();

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📤 [WHISPER API REQUEST]');
      debugPrint('   Model: $model');
      debugPrint('   Language: ${language ?? "auto-detect"}');
      debugPrint('   Temperature: $temperature');
      debugPrint('   Response format: verbose_json');
      debugPrint('   File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      debugPrint('═══════════════════════════════════════════════════════');

      debugPrint('🌐 Sending request to Groq Whisper API...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ Whisper API Error: ${response.body}');
        String errorMessage = 'Transcription failed';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorJson['error'] as Map<String, dynamic>?;
          errorMessage = error?['message'] as String? ?? 'Transcription failed';
        } catch (_) {}
        return WhisperTranscriptionResult.error(errorMessage);
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final text = jsonResponse['text'] as String? ?? '';
      final detectedLanguage = jsonResponse['language'] as String?;
      final duration = (jsonResponse['duration'] as num?)?.toDouble();

      debugPrint('✅ Transcription successful');
      debugPrint('📝 Text: ${text.substring(0, text.length.clamp(0, 100))}...');
      debugPrint('🌐 Detected language: $detectedLanguage');
      debugPrint('⏱️ Duration: ${duration?.toStringAsFixed(1)}s');

      return WhisperTranscriptionResult(
        text: text.trim(),
        detectedLanguage: detectedLanguage,
        duration: duration,
      );
    } catch (e) {
      debugPrint('❌ Whisper transcription error: $e');
      return WhisperTranscriptionResult.error('Transcription error: $e');
    }
  }

  /// Transcribe audio bytes to text
  /// Useful when audio is in memory (e.g., from recording)
  Future<WhisperTranscriptionResult> transcribeBytes({
    required Uint8List audioBytes,
    required String fileName,
    String? language,
    String? prompt,
  }) async {
    debugPrint('🎙️ GroqWhisperService.transcribeBytes() called');
    debugPrint('📊 Audio size: ${(audioBytes.length / 1024).toStringAsFixed(1)} KB');

    try {
      // Save bytes to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(audioBytes);

      // Transcribe the file
      final result = await transcribeFile(
        audioFilePath: tempFile.path,
        language: language,
        prompt: prompt,
      );

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      return result;
    } catch (e) {
      debugPrint('❌ Whisper transcription error: $e');
      return WhisperTranscriptionResult.error('Transcription error: $e');
    }
  }

  /// Get language name from code
  static String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }

  /// Check if a language is supported
  static bool isLanguageSupported(String code) {
    return supportedLanguages.containsKey(code);
  }
}
