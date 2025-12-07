import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Voice input service for speech-to-text functionality
/// Uses on-device recognition (free, no API costs)
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSimulator = false;

  /// Current recognized text
  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  /// Whether the service is currently listening
  bool get isListening => _isListening;

  /// Whether the service is initialized and available
  bool get isAvailable => _isInitialized;

  /// Whether running on simulator (for demo mode)
  bool get isRunningOnSimulator => _isSimulator;

  /// Sound level for visualization (0.0 to 1.0)
  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  /// Callbacks
  Function(String text, bool isFinal)? onResult;
  Function(double level)? onSoundLevelChange;
  Function(String error)? onError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;

  /// Check if running on simulator/emulator
  Future<bool> _checkIsSimulator() async {
    try {
      if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      } else if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return !androidInfo.isPhysicalDevice;
      }
    } catch (e) {
      debugPrint('⚠️ Could not determine if running on simulator: $e');
    }
    return false;
  }

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if running on simulator
      _isSimulator = await _checkIsSimulator();
      if (_isSimulator) {
        debugPrint('⚠️ Running on simulator - speech recognition may not work');
      }

      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        debugPrint('🎤 Voice input service initialized successfully');
      } else {
        debugPrint('❌ Voice input service failed to initialize');
        if (_isSimulator) {
          onError?.call('Voice input requires a physical device. Simulators do not have microphone access.');
        }
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Voice input initialization error: $e');
      if (_isSimulator) {
        onError?.call('Voice input requires a physical device. Simulators do not have microphone access.');
      }
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    String localeId = 'en_US',
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      debugPrint('🎤 Already listening');
      return;
    }

    _recognizedText = '';
    _isListening = true;
    onListeningStarted?.call();

    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onSoundLevelChange,
        localeId: localeId,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
      debugPrint('🎤 Started listening...');
    } catch (e) {
      debugPrint('❌ Error starting speech recognition: $e');
      _isListening = false;
      onError?.call('Failed to start listening: $e');
      onListeningStopped?.call();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      _soundLevel = 0.0;
      onListeningStopped?.call();
      debugPrint('🎤 Stopped listening');
    } catch (e) {
      debugPrint('❌ Error stopping speech recognition: $e');
    }
  }

  /// Cancel current listening session
  Future<void> cancel() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _soundLevel = 0.0;
      _recognizedText = '';
      onListeningStopped?.call();
      debugPrint('🎤 Cancelled listening');
    } catch (e) {
      debugPrint('❌ Error cancelling speech recognition: $e');
    }
  }

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Handle speech recognition results
  void _onResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    onResult?.call(_recognizedText, result.finalResult);

    if (result.finalResult) {
      debugPrint('🎤 Final result: $_recognizedText');
    }
  }

  /// Handle sound level changes for visualization
  void _onSoundLevelChange(double level) {
    // Normalize level to 0.0 - 1.0 range
    // Speech recognition returns levels from about -2 to 10
    _soundLevel = ((level + 2) / 12).clamp(0.0, 1.0);
    onSoundLevelChange?.call(_soundLevel);
  }

  /// Handle status changes
  void _onStatus(String status) {
    debugPrint('🎤 Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      if (_isListening) {
        _isListening = false;
        _soundLevel = 0.0;
        onListeningStopped?.call();
      }
    }
  }

  /// Handle errors with user-friendly messages
  void _onError(SpeechRecognitionError error) {
    debugPrint('❌ Speech error: ${error.errorMsg} (permanent: ${error.permanent})');
    _isListening = false;
    _soundLevel = 0.0;

    // Provide user-friendly error messages
    String friendlyMessage = _getFriendlyErrorMessage(error.errorMsg);
    onError?.call(friendlyMessage);
    onListeningStopped?.call();
  }

  /// Convert technical error codes to user-friendly messages
  String _getFriendlyErrorMessage(String errorCode) {
    // Handle common speech recognition error codes
    switch (errorCode.toLowerCase()) {
      case 'error_audio':
        if (_isSimulator) {
          return 'Voice input requires a physical device. The simulator cannot access the microphone.';
        }
        return 'Microphone error. Please check your microphone permissions.';

      case 'error_no_match':
        return 'Could not understand. Please speak clearly and try again.';

      case 'error_speech_timeout':
        return 'No speech detected. Please try again.';

      case 'error_network':
        return 'Network error. Please check your connection.';

      case 'error_network_timeout':
        return 'Network timeout. Please try again.';

      case 'error_permission':
        return 'Microphone permission denied. Please enable it in Settings.';

      case 'error_busy':
        return 'Speech recognition is busy. Please wait and try again.';

      case 'error_not_recognized':
      case 'error_retry':
        if (_isSimulator) {
          return 'Voice input requires a physical device. The simulator cannot access the microphone.';
        }
        return 'Speech not recognized. Please try again.';

      case 'error_server':
        return 'Speech recognition server error. Please try again later.';

      default:
        if (_isSimulator) {
          return 'Voice input requires a physical device. The simulator cannot access the microphone.';
        }
        return 'Speech recognition error. Please try again.';
    }
  }

  /// Run demo mode with simulated voice input (for simulator testing)
  Future<void> runDemoMode() async {
    if (!_isSimulator) return;

    // Simulate listening state
    _isListening = true;
    _recognizedText = '';
    onListeningStarted?.call();

    // Demo phrases to simulate
    final demoPhrase = 'Plan a trip to Goa for this weekend with family';
    final words = demoPhrase.split(' ');

    // Simulate speaking word by word with varying sound levels
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));

      // Simulate sound level
      _soundLevel = 0.3 + (i % 3) * 0.25;
      onSoundLevelChange?.call(_soundLevel);

      // Build interim result
      final interim = words.sublist(0, i + 1).join(' ');
      onResult?.call(interim, false);

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Final result
    await Future.delayed(const Duration(milliseconds: 300));
    _soundLevel = 0.0;
    onSoundLevelChange?.call(_soundLevel);
    _recognizedText = demoPhrase;
    onResult?.call(demoPhrase, true);

    _isListening = false;
    onListeningStopped?.call();
  }

  /// Dispose the service
  void dispose() {
    _speech.cancel();
    _isInitialized = false;
    _isListening = false;
  }
}

/// Parsed trip details from voice input
class VoiceTripDetails {
  final String? destination;
  final String? duration;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? numberOfDays;
  final List<String> companions;
  final String? tripType; // family, friends, solo, business
  final String rawText;

  VoiceTripDetails({
    this.destination,
    this.duration,
    this.startDate,
    this.endDate,
    this.numberOfDays,
    this.companions = const [],
    this.tripType,
    required this.rawText,
  });

  bool get hasDestination => destination != null && destination!.isNotEmpty;
  bool get hasDates => startDate != null || numberOfDays != null;

  @override
  String toString() {
    return 'VoiceTripDetails(destination: $destination, duration: $duration, '
        'startDate: $startDate, endDate: $endDate, numberOfDays: $numberOfDays, '
        'companions: $companions, tripType: $tripType)';
  }
}

/// Simple local parser for trip details from voice input
/// This extracts basic info without needing an API call
class VoiceTripParser {
  /// Parse voice input to extract trip details
  static VoiceTripDetails parse(String text) {
    final lowerText = text.toLowerCase();

    return VoiceTripDetails(
      destination: _extractDestination(lowerText),
      duration: _extractDuration(lowerText),
      startDate: _extractStartDate(lowerText),
      numberOfDays: _extractNumberOfDays(lowerText),
      companions: _extractCompanions(lowerText),
      tripType: _extractTripType(lowerText),
      rawText: text,
    );
  }

  /// Extract destination from text
  static String? _extractDestination(String text) {
    // Common patterns: "trip to X", "going to X", "visit X", "travel to X"
    final patterns = [
      RegExp(r'(?:trip|going|travel|visit|planning|plan)\s+to\s+([a-zA-Z\s]+?)(?:\s+for|\s+in|\s+on|\s+with|\s+next|\s+this|$)', caseSensitive: false),
      RegExp(r'(?:to|visiting|explore)\s+([a-zA-Z\s]+?)(?:\s+for|\s+in|\s+on|\s+with|\s+next|\s+this|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final destination = match.group(1)!.trim();
        // Capitalize first letter of each word
        return destination.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
    }

    return null;
  }

  /// Extract duration from text
  static String? _extractDuration(String text) {
    // Patterns: "3 days", "a week", "5 nights", "weekend"
    final patterns = [
      RegExp(r'(\d+)\s*(?:day|days)', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:night|nights)', caseSensitive: false),
      RegExp(r'(?:a|one)\s*(week|weekend)', caseSensitive: false),
      RegExp(r'(\d+)\s*(?:week|weeks)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }

    if (text.contains('weekend')) return 'weekend';

    return null;
  }

  /// Extract start date from text
  static DateTime? _extractStartDate(String text) {
    final now = DateTime.now();

    // Handle relative dates
    if (text.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1);
    }

    if (text.contains('next weekend') || text.contains('this weekend')) {
      // Find next Saturday
      int daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
      if (daysUntilSaturday == 0 && text.contains('next')) {
        daysUntilSaturday = 7;
      }
      return DateTime(now.year, now.month, now.day + daysUntilSaturday);
    }

    if (text.contains('next week')) {
      // Next Monday
      int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
      if (daysUntilMonday == 0) daysUntilMonday = 7;
      return DateTime(now.year, now.month, now.day + daysUntilMonday);
    }

    // Handle month names
    final months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    for (final entry in months.entries) {
      if (text.contains(entry.key)) {
        // Try to find a day number near the month
        final dayPattern = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s*(?:of\s*)?' + entry.key, caseSensitive: false);
        final dayMatch = dayPattern.firstMatch(text);
        if (dayMatch != null) {
          final day = int.parse(dayMatch.group(1)!);
          var year = now.year;
          if (entry.value < now.month || (entry.value == now.month && day < now.day)) {
            year++; // Next year if date has passed
          }
          return DateTime(year, entry.value, day);
        }

        // Just month mentioned, use 1st of that month
        var year = now.year;
        if (entry.value < now.month) year++;
        return DateTime(year, entry.value, 1);
      }
    }

    return null;
  }

  /// Extract number of days from text
  static int? _extractNumberOfDays(String text) {
    // Handle specific day counts
    final dayPattern = RegExp(r'(\d+)\s*(?:day|days)', caseSensitive: false);
    final dayMatch = dayPattern.firstMatch(text);
    if (dayMatch != null) {
      return int.parse(dayMatch.group(1)!);
    }

    // Handle nights (typically days = nights + 1 for travel)
    final nightPattern = RegExp(r'(\d+)\s*(?:night|nights)', caseSensitive: false);
    final nightMatch = nightPattern.firstMatch(text);
    if (nightMatch != null) {
      return int.parse(nightMatch.group(1)!) + 1;
    }

    // Handle week patterns
    if (text.contains('weekend')) return 2;

    final weekPattern = RegExp(r'(\d+)\s*(?:week|weeks)', caseSensitive: false);
    final weekMatch = weekPattern.firstMatch(text);
    if (weekMatch != null) {
      return int.parse(weekMatch.group(1)!) * 7;
    }

    if (text.contains('a week') || text.contains('one week')) return 7;

    return null;
  }

  /// Extract companions from text
  static List<String> _extractCompanions(String text) {
    final companions = <String>[];

    if (text.contains('family')) companions.add('Family');
    if (text.contains('friends') || text.contains('friend')) companions.add('Friends');
    if (text.contains('wife') || text.contains('husband') || text.contains('spouse')) {
      companions.add('Spouse');
    }
    if (text.contains('kids') || text.contains('children')) companions.add('Kids');
    if (text.contains('parents') || text.contains('mom') || text.contains('dad')) {
      companions.add('Parents');
    }
    if (text.contains('colleagues') || text.contains('coworkers')) companions.add('Colleagues');

    return companions;
  }

  /// Extract trip type from text
  static String? _extractTripType(String text) {
    if (text.contains('family')) return 'family';
    if (text.contains('friends') || text.contains('friend')) return 'friends';
    if (text.contains('solo') || text.contains('alone') || text.contains('myself')) {
      return 'solo';
    }
    if (text.contains('business') || text.contains('work') || text.contains('office')) {
      return 'business';
    }
    if (text.contains('honeymoon') || text.contains('romantic')) return 'romantic';
    if (text.contains('adventure')) return 'adventure';

    return null;
  }
}
