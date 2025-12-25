// Hybrid Voice Service
//
// Combines device speech recognition (free, offline) with Groq Whisper (cloud, multilingual).
// Strategy:
// 1. Try device speech recognition first (free)
// 2. If language not available on device, use Groq Whisper
// 3. User can also force Whisper mode for better multilingual support

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'groq_whisper_service.dart';

/// Voice input mode
enum VoiceInputMode {
  /// Use device speech recognition (free, offline-capable)
  device,
  /// Use Groq Whisper (cloud, better multilingual)
  whisper,
  /// Auto-select: device if language available, whisper otherwise
  auto,
}

/// Result from voice input
class VoiceInputResult {
  final String text;
  final String? detectedLanguage;
  final VoiceInputMode modeUsed;
  final bool success;
  final String? error;

  const VoiceInputResult({
    required this.text,
    this.detectedLanguage,
    required this.modeUsed,
    this.success = true,
    this.error,
  });

  factory VoiceInputResult.error(String errorMessage, VoiceInputMode mode) {
    return VoiceInputResult(
      text: '',
      modeUsed: mode,
      success: false,
      error: errorMessage,
    );
  }

  @override
  String toString() {
    return 'VoiceInputResult(text: $text, mode: $modeUsed, success: $success)';
  }
}

/// Hybrid Voice Service - combines device and cloud speech recognition
class HybridVoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  GroqWhisperService? _whisperService;

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isRecording = false;
  String _recognizedText = '';
  String? _currentRecordingPath;
  VoiceInputMode _currentMode = VoiceInputMode.auto;
  String? _selectedLanguage;

  // Available locales from device
  List<LocaleName> _availableLocales = [];

  // Callbacks
  Function(String text)? onTextChanged;
  Function(double level)? onSoundLevelChanged;
  Function()? onListeningStarted;
  Function()? onListeningStopped;
  Function(String error)? onError;

  /// Language codes for common Indian languages
  static const Map<String, String> indianLanguages = {
    'en_IN': 'English',
    'ta_IN': 'தமிழ்',
    'hi_IN': 'हिंदी',
    'te_IN': 'తెలుగు',
    'kn_IN': 'ಕನ್ನಡ',
    'ml_IN': 'മലയാളം',
    'bn_IN': 'বাংলা',
    'gu_IN': 'ગુજરાતી',
    'mr_IN': 'मराठी',
    'pa_IN': 'ਪੰਜਾਬੀ',
  };

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isRecording => _isRecording;
  String get recognizedText => _recognizedText;
  VoiceInputMode get currentMode => _currentMode;
  String? get selectedLanguage => _selectedLanguage;
  List<LocaleName> get availableLocales => _availableLocales;

  /// Initialize the service
  Future<bool> initialize({String? groqApiKey}) async {
    if (_isInitialized) return true;

    debugPrint('🎤 HybridVoiceService.initialize()');

    try {
      // Initialize device speech recognition
      final deviceAvailable = await _speechToText.initialize(
        onError: (error) {
          debugPrint('❌ Device speech error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('🎤 Device speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningStopped?.call();
          }
        },
      );

      if (deviceAvailable) {
        _availableLocales = await _speechToText.locales();
        debugPrint('📋 Available device locales: ${_availableLocales.length}');
      }

      // Initialize Whisper service if API key provided
      if (groqApiKey != null && groqApiKey.isNotEmpty) {
        _whisperService = GroqWhisperService(groqApiKey);
        debugPrint('✅ Whisper service initialized');
      }

      _isInitialized = true;
      debugPrint('✅ HybridVoiceService initialized');
      return true;
    } catch (e) {
      debugPrint('❌ HybridVoiceService initialization error: $e');
      onError?.call('Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Set the voice input mode
  void setMode(VoiceInputMode mode) {
    _currentMode = mode;
    debugPrint('🎤 Voice input mode set to: $mode');
  }

  /// Set the language for recognition
  void setLanguage(String? languageCode) {
    _selectedLanguage = languageCode;
    debugPrint('🌐 Language set to: $languageCode');
  }

  /// Check if a language is available on device
  bool isLanguageAvailableOnDevice(String localeId) {
    if (_availableLocales.isEmpty) return false;

    // Check exact match
    if (_availableLocales.any((l) => l.localeId == localeId)) {
      return true;
    }

    // Check language code match (e.g., 'ta' for 'ta_IN')
    final languageCode = localeId.split('_')[0];
    return _availableLocales.any((l) => l.localeId.startsWith(languageCode));
  }

  /// Start listening for voice input
  Future<void> startListening({
    String? languageCode,
    VoiceInputMode? mode,
    Duration listenFor = const Duration(seconds: 120),
    Duration pauseFor = const Duration(seconds: 15),
  }) async {
    if (!_isInitialized) {
      onError?.call('Voice service not initialized');
      return;
    }

    if (_isListening || _isRecording) {
      debugPrint('⚠️ Already listening/recording');
      return;
    }

    final effectiveMode = mode ?? _currentMode;
    final effectiveLanguage = languageCode ?? _selectedLanguage;

    debugPrint('🎤 Starting voice input');
    debugPrint('   Mode: $effectiveMode');
    debugPrint('   Language: $effectiveLanguage');

    // Determine which mode to use
    VoiceInputMode actualMode = effectiveMode;

    if (effectiveMode == VoiceInputMode.auto) {
      // Check if language is available on device
      if (effectiveLanguage != null && !isLanguageAvailableOnDevice(effectiveLanguage)) {
        if (_whisperService != null) {
          actualMode = VoiceInputMode.whisper;
          debugPrint('🔄 Language not on device, using Whisper');
        } else {
          debugPrint('⚠️ Language not available and no Whisper service');
          // Fall back to device default
          actualMode = VoiceInputMode.device;
        }
      } else {
        actualMode = VoiceInputMode.device;
      }
    }

    if (actualMode == VoiceInputMode.whisper) {
      await _startWhisperRecording(effectiveLanguage);
    } else {
      await _startDeviceListening(effectiveLanguage, listenFor, pauseFor);
    }
  }

  /// Start device speech recognition
  Future<void> _startDeviceListening(
    String? languageCode,
    Duration listenFor,
    Duration pauseFor,
  ) async {
    _recognizedText = '';
    _isListening = true;
    onListeningStarted?.call();

    // Find best matching locale
    String? effectiveLocale;
    if (languageCode != null) {
      // Try exact match
      final exactMatch = _availableLocales.firstWhere(
        (l) => l.localeId == languageCode,
        orElse: () => LocaleName('', ''),
      );
      if (exactMatch.localeId.isNotEmpty) {
        effectiveLocale = exactMatch.localeId;
      } else {
        // Try language code match
        final langCode = languageCode.split('_')[0];
        final langMatch = _availableLocales.firstWhere(
          (l) => l.localeId.startsWith(langCode),
          orElse: () => LocaleName('', ''),
        );
        if (langMatch.localeId.isNotEmpty) {
          effectiveLocale = langMatch.localeId;
        }
      }
    }

    debugPrint('🎤 Starting device speech recognition');
    debugPrint('   Effective locale: ${effectiveLocale ?? "device default"}');

    try {
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          onTextChanged?.call(_recognizedText);
          debugPrint('📝 Text: $_recognizedText');
        },
        onSoundLevelChange: (level) {
          onSoundLevelChanged?.call(level);
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        localeId: effectiveLocale,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Device speech error: $e');
      _isListening = false;
      onError?.call('Speech recognition failed: $e');
      onListeningStopped?.call();
    }
  }

  /// Start recording for Whisper transcription
  Future<void> _startWhisperRecording(String? languageCode) async {
    if (_whisperService == null) {
      onError?.call('Whisper service not available');
      return;
    }

    _recognizedText = '';
    _isRecording = true;
    onListeningStarted?.call();

    debugPrint('🎙️ Starting Whisper recording');

    try {
      // Check permission
      if (!await _audioRecorder.hasPermission()) {
        onError?.call('Microphone permission denied');
        _isRecording = false;
        onListeningStopped?.call();
        return;
      }

      // Get temp directory for recording
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/whisper_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      debugPrint('🎙️ Recording started: $_currentRecordingPath');

      // Monitor audio levels
      _monitorAudioLevels();
    } catch (e) {
      debugPrint('❌ Recording error: $e');
      _isRecording = false;
      onError?.call('Failed to start recording: $e');
      onListeningStopped?.call();
    }
  }

  /// Monitor audio levels during recording
  void _monitorAudioLevels() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      _audioRecorder.getAmplitude().then((amplitude) {
        // Convert amplitude to 0-10 scale (similar to speech_to_text)
        final level = ((amplitude.current + 40) / 40 * 10).clamp(0.0, 10.0);
        onSoundLevelChanged?.call(level);
      });
    });
  }

  /// Stop listening/recording
  Future<VoiceInputResult> stopListening() async {
    debugPrint('🛑 Stopping voice input');

    if (_isListening) {
      // Stop device speech recognition
      await _speechToText.stop();
      _isListening = false;
      onListeningStopped?.call();

      return VoiceInputResult(
        text: _recognizedText,
        modeUsed: VoiceInputMode.device,
      );
    }

    if (_isRecording) {
      // Stop recording and transcribe with Whisper
      final path = await _audioRecorder.stop();
      _isRecording = false;

      debugPrint('🎙️ Recording stopped: $path');

      if (path != null && _whisperService != null) {
        // Get language code for Whisper (convert from locale to language code)
        String? whisperLanguage;
        if (_selectedLanguage != null) {
          whisperLanguage = _selectedLanguage!.split('_')[0];
        }

        debugPrint('🌐 Transcribing with Whisper (language: ${whisperLanguage ?? "auto"})');

        final result = await _whisperService!.transcribeFile(
          audioFilePath: path,
          language: whisperLanguage,
          prompt: 'Travel planning, trip to destination, dates, duration',
        );

        // Clean up recording file
        try {
          await File(path).delete();
        } catch (_) {}

        onListeningStopped?.call();

        if (result.success) {
          _recognizedText = result.text;
          onTextChanged?.call(_recognizedText);

          return VoiceInputResult(
            text: result.text,
            detectedLanguage: result.detectedLanguage,
            modeUsed: VoiceInputMode.whisper,
          );
        } else {
          return VoiceInputResult.error(
            result.error ?? 'Transcription failed',
            VoiceInputMode.whisper,
          );
        }
      }

      onListeningStopped?.call();
      return VoiceInputResult.error('Recording failed', VoiceInputMode.whisper);
    }

    return VoiceInputResult.error('Not listening', VoiceInputMode.device);
  }

  /// Cancel current listening/recording
  Future<void> cancel() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
    }

    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;

      // Clean up recording file
      if (_currentRecordingPath != null) {
        try {
          await File(_currentRecordingPath!).delete();
        } catch (_) {}
      }
    }

    _recognizedText = '';
    onListeningStopped?.call();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await cancel();
    await _audioRecorder.dispose();
  }

  /// Get language name from code
  String getLanguageName(String localeId) {
    return indianLanguages[localeId] ?? localeId;
  }
}
