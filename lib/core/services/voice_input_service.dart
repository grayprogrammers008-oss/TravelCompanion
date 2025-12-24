import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Available locales for speech recognition
  final List<LocaleName> _availableLocales = [];
  List<LocaleName> get availableLocales => _availableLocales;

  /// Current selected locale - null means use device default (auto-detect)
  String? _currentLocaleId;
  String? get currentLocaleId => _currentLocaleId;

  /// Supported Indian language locales
  /// Tamil: ta_IN, Hindi: hi_IN, Telugu: te_IN, Kannada: kn_IN, Malayalam: ml_IN
  static const Map<String, String> indianLanguages = {
    'en_IN': 'English (India)',
    'ta_IN': 'தமிழ் (Tamil)',
    'hi_IN': 'हिन्दी (Hindi)',
    'te_IN': 'తెలుగు (Telugu)',
    'kn_IN': 'ಕನ್ನಡ (Kannada)',
    'ml_IN': 'മലയാളം (Malayalam)',
    'mr_IN': 'मराठी (Marathi)',
    'bn_IN': 'বাংলা (Bengali)',
    'gu_IN': 'ગુજરાતી (Gujarati)',
    'pa_IN': 'ਪੰਜਾਬੀ (Punjabi)',
  };

  /// Set the locale for speech recognition
  /// Pass null to use device default (auto-detect language)
  void setLocale(String? localeId) {
    _currentLocaleId = localeId;
    debugPrint('🎤 Locale set to: ${localeId ?? "device default (auto-detect)"}');
  }

  /// Get available Indian language locales that are supported on this device
  List<MapEntry<String, String>> getAvailableIndianLanguages() {
    final available = <MapEntry<String, String>>[];
    for (final entry in indianLanguages.entries) {
      // Check if this locale is available on the device
      final isAvailable = _availableLocales.any(
        (locale) => locale.localeId.startsWith(entry.key.split('_')[0]),
      );
      if (isAvailable) {
        available.add(entry);
      }
    }
    // If no specific locales found, at least return English
    if (available.isEmpty) {
      available.add(const MapEntry('en_IN', 'English (India)'));
    }
    return available;
  }

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
        final isSimulator = !iosInfo.isPhysicalDevice;
        debugPrint('📱 iOS device check: isPhysicalDevice=${iosInfo.isPhysicalDevice}, isSimulator=$isSimulator');
        return isSimulator;
      } else if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final isEmulator = !androidInfo.isPhysicalDevice;
        debugPrint('📱 Android device check: model=${androidInfo.model}, isPhysicalDevice=${androidInfo.isPhysicalDevice}, isEmulator=$isEmulator');
        return isEmulator;
      }
    } catch (e) {
      debugPrint('⚠️ Could not determine if running on simulator: $e');
    }
    return false;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    debugPrint('🎤 hasMicrophonePermission check: status=$status, isGranted=${status.isGranted}, isDenied=${status.isDenied}, isPermanentlyDenied=${status.isPermanentlyDenied}, isRestricted=${status.isRestricted}, isLimited=${status.isLimited}');
    return status.isGranted;
  }

  /// Check if microphone permission is permanently denied
  Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Request microphone permission (and speech recognition on iOS)
  /// Returns true if permission is granted, false otherwise
  ///
  /// Uses speech_to_text's built-in permission request which triggers
  /// the native iOS permission dialog properly
  Future<bool> requestMicrophonePermission() async {
    debugPrint('🎤 Requesting microphone permission via speech_to_text...');

    // First, try to initialize speech_to_text which triggers the permission dialog
    // This is more reliable than permission_handler for speech permissions
    final hasPermission = await _speech.initialize(
      onStatus: (status) => debugPrint('🎤 Permission request status: $status'),
      onError: (error) => debugPrint('🎤 Permission request error: ${error.errorMsg}'),
    );

    debugPrint('🎤 speech_to_text.initialize() returned: $hasPermission');

    if (hasPermission) {
      _isInitialized = true;
      return true;
    }

    // If speech_to_text didn't grant permission, try permission_handler as fallback
    debugPrint('🎤 Falling back to permission_handler...');
    final micStatus = await Permission.microphone.request();
    debugPrint('🎤 Microphone permission status: $micStatus');

    if (!micStatus.isGranted) {
      return false;
    }

    // On iOS, also request speech recognition permission
    if (Platform.isIOS) {
      debugPrint('🎤 Requesting speech recognition permission on iOS...');
      final speechStatus = await Permission.speech.request();
      debugPrint('🎤 Speech recognition permission status: $speechStatus');
    }

    return true;
  }

  /// Open app settings so user can enable microphone permission
  Future<bool> openMicrophoneSettings() async {
    debugPrint('⚙️ Opening app settings for permission...');
    return await openAppSettings();
  }

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if running on simulator/emulator FIRST
      _isSimulator = await _checkIsSimulator();
      debugPrint('🔍 Device detection: isSimulator/Emulator = $_isSimulator');

      if (_isSimulator) {
        debugPrint('⚠️ Running on simulator/emulator - speech recognition may not work');
        debugPrint('⚠️ Demo mode will be available instead');
      } else {
        debugPrint('📱 Running on PHYSICAL device - real speech recognition will be used');

        // Check current microphone permission status
        final currentStatus = await Permission.microphone.status;
        debugPrint('🎤 Current microphone permission status: $currentStatus');

        if (currentStatus.isPermanentlyDenied) {
          // Permission was permanently denied - user needs to go to Settings
          debugPrint('❌ Microphone permission permanently denied - user must enable in Settings');
          onError?.call('PERMISSION_PERMANENTLY_DENIED');
          return false;
        }

        if (!currentStatus.isGranted) {
          // Request microphone permission
          debugPrint('🎤 Requesting microphone permission...');
          final micStatus = await Permission.microphone.request();
          debugPrint('🎤 Microphone permission result: $micStatus');

          if (micStatus.isDenied) {
            debugPrint('❌ Microphone permission denied');
            onError?.call('PERMISSION_DENIED');
            return false;
          }

          if (micStatus.isPermanentlyDenied) {
            debugPrint('❌ Microphone permission permanently denied');
            onError?.call('PERMISSION_PERMANENTLY_DENIED');
            return false;
          }
        }

        // Also request speech recognition permission on iOS (needed for iOS 10+)
        if (Platform.isIOS) {
          debugPrint('🎤 Checking speech recognition permission on iOS...');
          final speechStatus = await Permission.speech.status;
          debugPrint('🎤 Speech permission status: $speechStatus');
          if (!speechStatus.isGranted) {
            final result = await Permission.speech.request();
            debugPrint('🎤 Speech permission result: $result');
          }
        }

        // Also request speech recognition permission on Android (needed for some devices)
        if (Platform.isAndroid) {
          debugPrint('🎤 Requesting speech recognition permission...');
          final speechStatus = await Permission.speech.request();
          debugPrint('🎤 Speech recognition permission status: $speechStatus');
        }
      }

      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      debugPrint('🎤 Speech initialization result: $_isInitialized');

      if (_isInitialized) {
        debugPrint('🎤 Voice input service initialized successfully');
        final locales = await _speech.locales();
        _availableLocales.clear();
        _availableLocales.addAll(locales);
        debugPrint('🎤 Available locales: ${locales.length}');
        // Log Indian language locales
        for (final locale in locales) {
          if (locale.localeId.contains('_IN') ||
              locale.localeId.startsWith('ta') ||
              locale.localeId.startsWith('hi') ||
              locale.localeId.startsWith('te') ||
              locale.localeId.startsWith('kn') ||
              locale.localeId.startsWith('ml')) {
            debugPrint('   🇮🇳 ${locale.localeId}: ${locale.name}');
          }
        }
      } else {
        debugPrint('❌ Voice input service failed to initialize');
        debugPrint('❌ hasPermission check needed - user may need to grant microphone permission');
        if (_isSimulator) {
          onError?.call('Voice input requires a physical device. Simulators do not have microphone access.');
        } else {
          // On physical device, initialization failure usually means permission issue
          onError?.call('PERMISSION_PERMANENTLY_DENIED');
        }
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Voice input initialization error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (_isSimulator) {
        onError?.call('Voice input requires a physical device. Simulators do not have microphone access.');
      } else {
        onError?.call('Speech recognition error: $e');
      }
      return false;
    }
  }

  /// Check if a specific locale is available for speech recognition
  bool isLocaleAvailable(String localeId) {
    if (_availableLocales.isEmpty) return false;

    // Check exact match first
    if (_availableLocales.any((l) => l.localeId == localeId)) {
      return true;
    }

    // Check if language code matches (e.g., 'ta' for 'ta_IN')
    final languageCode = localeId.split('_')[0];
    return _availableLocales.any((l) => l.localeId.startsWith(languageCode));
  }

  /// Find the best matching locale for a given locale ID
  /// Returns null if no match found (will use device default)
  String? _findBestMatchingLocale(String? requestedLocale) {
    if (requestedLocale == null) return null;
    if (_availableLocales.isEmpty) return null;

    // Check exact match first
    final exactMatch = _availableLocales.firstWhere(
      (l) => l.localeId == requestedLocale,
      orElse: () => LocaleName('', ''),
    );
    if (exactMatch.localeId.isNotEmpty) {
      return exactMatch.localeId;
    }

    // Check if language code matches (e.g., 'ta' for 'ta_IN')
    final languageCode = requestedLocale.split('_')[0];
    final languageMatch = _availableLocales.firstWhere(
      (l) => l.localeId.startsWith(languageCode),
      orElse: () => LocaleName('', ''),
    );
    if (languageMatch.localeId.isNotEmpty) {
      debugPrint('🎤 Found alternative locale: ${languageMatch.localeId} for requested: $requestedLocale');
      return languageMatch.localeId;
    }

    return null;
  }

  /// Start listening for speech
  /// VERY PATIENT settings: waits longer for speech and allows extended pauses
  /// If localeId is null and _currentLocaleId is null, uses device default (auto-detect)
  ///
  /// Patient Mode Features:
  /// - listenFor: 3 minutes total (180 seconds) - plenty of time for detailed descriptions
  /// - pauseFor: 20 seconds pause tolerance - allows natural thinking time between thoughts
  /// - Users can form complete sentences without being cut off
  Future<void> startListening({
    String? localeId, // If null, uses _currentLocaleId or device default
    Duration? listenFor,
    Duration? pauseFor,
    bool veryPatient = true, // Flag for extra patient mode (default: true)
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

    // Use provided locale, or current locale, or device default (null = auto-detect)
    final requestedLocale = localeId ?? _currentLocaleId;

    // Validate and find best matching locale
    String? effectiveLocale;
    bool usingFallback = false;
    if (requestedLocale != null) {
      effectiveLocale = _findBestMatchingLocale(requestedLocale);
      if (effectiveLocale == null) {
        // Language not available on device - fall back silently to device default
        final languageName = indianLanguages[requestedLocale] ?? requestedLocale;
        debugPrint('⚠️ Requested locale $requestedLocale ($languageName) is not available on this device');
        debugPrint('📋 Available locales: ${_availableLocales.map((l) => l.localeId).join(", ")}');
        debugPrint('🎤 Falling back to device default language (will still work!)');

        // Don't show error here - let it try with device default first
        // Only show error if the actual speech recognition fails
        usingFallback = true;
      }
    }

    try {
      // VERY PATIENT listening settings:
      // - listenFor: 3 minutes total listening time (plenty of time to describe a detailed trip)
      // - pauseFor: 20 seconds pause tolerance (allows thinking time between sentences)
      //
      // This prevents the "cuts off too quickly" problem where users are still forming thoughts
      final effectiveListenFor = listenFor ?? Duration(seconds: veryPatient ? 180 : 120);
      final effectivePauseFor = pauseFor ?? Duration(seconds: veryPatient ? 20 : 10);

      if (effectiveLocale == null) {
        debugPrint('🎤 Starting speech recognition with DEVICE DEFAULT locale (auto-detect)');
        debugPrint('🎤 This will use your phone\'s language settings');
      } else {
        debugPrint('🎤 Starting speech recognition with locale: $effectiveLocale');
        debugPrint('🎤 Language: ${indianLanguages[effectiveLocale] ?? effectiveLocale}');
      }
      debugPrint('🎤 listenFor: $effectiveListenFor (${veryPatient ? "VERY patient" : "patient"} mode)');
      debugPrint('🎤 pauseFor: $effectivePauseFor (allows ${veryPatient ? "extended" : "natural"} thinking time)');
      debugPrint('🎤 TIP: Take your time - the mic will wait for you to finish your thoughts');

      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onSoundLevelChange,
        localeId: effectiveLocale, // null = device default
        listenFor: effectiveListenFor, // 3 minutes - plenty of time for detailed trip planning
        pauseFor: effectivePauseFor, // 20 seconds - allows natural thinking pauses without cutoff
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation, // Dictation mode is more patient
          autoPunctuation: true, // Enable auto punctuation for better results
          enableHapticFeedback: true, // Haptic feedback on Android
        ),
      );
      debugPrint('🎤 Started listening successfully!');
    } catch (e) {
      debugPrint('❌ Error starting speech recognition: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Was using fallback: $usingFallback');
      _isListening = false;

      // Provide more helpful error message
      String errorMessage;
      if (e.toString().contains('ListenFailed')) {
        final languageName = indianLanguages[requestedLocale] ?? requestedLocale ?? 'Selected language';
        if (usingFallback) {
          // The selected language wasn't available AND the fallback also failed
          errorMessage = '$languageName is not available for speech recognition. Please download it in Settings → General → Keyboard → Dictation Languages.';
        } else {
          errorMessage = '$languageName speech recognition failed. Please try using device default language or check your device language settings.';
        }
      } else {
        errorMessage = 'Failed to start listening: $e';
      }

      onError?.call(errorMessage);
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
    debugPrint('🎤 Speech status changed: $status');

    // Status values: listening, notListening, done
    if (status == 'listening') {
      debugPrint('🎤 Now actively listening for speech...');
    } else if (status == 'done' || status == 'notListening') {
      debugPrint('🎤 Stopped listening (status: $status, hadRecognizedText: ${_recognizedText.isNotEmpty})');
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
        return 'No speech detected. Tap the mic and start speaking right away.';

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
    debugPrint('🔍 VoiceTripParser.parse() called with: "$text"');
    final lowerText = text.toLowerCase();

    final destination = _extractDestination(lowerText);
    final duration = _extractDuration(lowerText);
    final startDate = _extractStartDate(lowerText);
    final numberOfDays = _extractNumberOfDays(lowerText);
    final companions = _extractCompanions(lowerText);
    final tripType = _extractTripType(lowerText);

    debugPrint('📋 Parsed results:');
    debugPrint('   - destination: $destination');
    debugPrint('   - duration: $duration');
    debugPrint('   - numberOfDays: $numberOfDays');
    debugPrint('   - tripType: $tripType');
    debugPrint('   - hasDestination: ${destination != null}');

    return VoiceTripDetails(
      destination: destination,
      duration: duration,
      startDate: startDate,
      numberOfDays: numberOfDays,
      companions: companions,
      tripType: tripType,
      rawText: text,
    );
  }

  /// Extract destination from text
  static String? _extractDestination(String text) {
    debugPrint('🔍 VoiceTripParser._extractDestination: "$text"');

    // Known Indian destinations (common ones)
    final knownDestinations = [
      'kerala', 'goa', 'ladakh', 'rajasthan', 'himachal', 'andaman', 'varanasi',
      'darjeeling', 'udaipur', 'rishikesh', 'coorg', 'jaipur', 'manali', 'munnar',
      'sikkim', 'kashmir', 'ooty', 'kodaikanal', 'shimla', 'mussoorie', 'nainital',
      'agra', 'delhi', 'mumbai', 'bangalore', 'chennai', 'kolkata', 'hyderabad',
      'pune', 'ahmedabad', 'jaisalmer', 'jodhpur', 'mysore', 'hampi', 'pondicherry',
      'alleppey', 'kochi', 'trivandrum', 'wayanad', 'leh', 'spiti', 'mcleodganj',
      'dharamshala', 'amritsar', 'chandigarh', 'dehradun', 'haridwar', 'pushkar',
      'khajuraho', 'varanasi', 'bodhgaya', 'gangtok', 'shillong', 'meghalaya',
      'assam', 'arunachal', 'nagaland', 'manipur', 'mizoram', 'tripura',
      // International
      'bali', 'bangkok', 'singapore', 'dubai', 'maldives', 'thailand', 'vietnam',
      'malaysia', 'sri lanka', 'nepal', 'bhutan', 'europe', 'paris', 'london',
      'new york', 'tokyo', 'sydney', 'hong kong', 'macau', 'phuket', 'krabi',
    ];

    // First, check for known destinations directly in the text
    for (final dest in knownDestinations) {
      if (text.contains(dest)) {
        debugPrint('✅ Found known destination: $dest');
        return dest.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
    }

    // Common patterns: "trip to X", "going to X", "visit X", "travel to X"
    final patterns = [
      // More flexible patterns
      RegExp(r'(?:trip|going|travel|visit|planning|plan|vacation|holiday)\s+to\s+([a-zA-Z\s]+?)(?:\s+for|\s+in|\s+on|\s+with|\s+next|\s+this|\s+\d|$)', caseSensitive: false),
      RegExp(r'(?:to|visiting|explore|exploring)\s+([a-zA-Z\s]+?)(?:\s+for|\s+in|\s+on|\s+with|\s+next|\s+this|\s+\d|$)', caseSensitive: false),
      // "X trip" pattern (e.g., "goa trip", "kerala vacation")
      RegExp(r'([a-zA-Z]+)\s+(?:trip|vacation|holiday|getaway|adventure)', caseSensitive: false),
      // Just destination name with days (e.g., "5 days in Kerala")
      RegExp(r'\d+\s*(?:day|days|night|nights)\s+(?:in|at|to)\s+([a-zA-Z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final destination = match.group(1)!.trim();
        // Filter out common non-destination words
        final skipWords = ['a', 'the', 'my', 'our', 'for', 'with', 'and', 'or', 'some', 'few', 'beach', 'mountain', 'adventure'];
        if (skipWords.contains(destination.toLowerCase()) || destination.length < 2) {
          continue;
        }
        debugPrint('✅ Extracted destination via pattern: $destination');
        // Capitalize first letter of each word
        return destination.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
    }

    debugPrint('❌ No destination found in text');
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

/// Parser for checklist items from voice input
/// Handles multiple items separated by commas, "and", periods, etc.
class VoiceChecklistParser {
  /// Parse voice input to extract individual checklist items
  static List<String> parse(String text) {
    if (text.trim().isEmpty) return [];

    // Normalize the text
    String normalized = text.trim();

    // Remove common prefixes
    final prefixes = [
      'add', 'pack', 'bring', 'get', 'buy', 'remember to',
      'don\'t forget', 'need', 'i need', 'we need',
      'make sure to', 'please add', 'also add',
    ];
    for (final prefix in prefixes) {
      if (normalized.toLowerCase().startsWith(prefix)) {
        normalized = normalized.substring(prefix.length).trim();
      }
    }

    // Split by various delimiters
    // First replace "and" with comma
    normalized = normalized.replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ', ');

    // Split by comma, period, semicolon, "then", "also"
    final items = normalized
        .split(RegExp(r'[,;.]|\s+then\s+|\s+also\s+', caseSensitive: false))
        .map((item) => _cleanItem(item))
        .where((item) => item.isNotEmpty)
        .toList();

    return items;
  }

  /// Clean up individual item text
  static String _cleanItem(String item) {
    String cleaned = item.trim();

    // Remove leading articles
    cleaned = cleaned.replaceFirst(RegExp(r'^(a|an|the|my|some)\s+', caseSensitive: false), '');

    // Remove trailing punctuation
    cleaned = cleaned.replaceAll(RegExp(r'[.!?]+$'), '');

    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned.trim();
  }
}

/// Parser for itinerary items from voice input
/// Extracts activity title, time, location, and duration
class VoiceItineraryParser {
  /// Parse voice input to extract itinerary item details
  static ItineraryItemDetails parse(String text) {
    final lowerText = text.toLowerCase();

    return ItineraryItemDetails(
      title: _extractTitle(text),
      location: _extractLocation(lowerText),
      startTime: _extractTime(lowerText),
      duration: _extractDuration(lowerText),
      description: _extractDescription(text),
      rawText: text,
    );
  }

  /// Parse multiple itinerary items from voice input
  static List<ItineraryItemDetails> parseMultiple(String text) {
    // Split by "then", "after that", "next", numbered items
    final splits = text.split(RegExp(
      r'(?:,?\s*then\s+)|(?:,?\s*after that\s+)|(?:,?\s*next\s+)|(?:\d+\.\s*)',
      caseSensitive: false,
    ));

    return splits
        .map((item) => parse(item.trim()))
        .where((item) => item.title.isNotEmpty)
        .toList();
  }

  /// Extract the main activity title
  static String _extractTitle(String text) {
    String title = text.trim();

    // Remove time expressions
    title = title.replaceAll(RegExp(
      r'(?:at|around|by|from)\s*\d{1,2}(?::\d{2})?\s*(?:am|pm|AM|PM)?',
      caseSensitive: false,
    ), '');

    // Remove location phrases (at the end)
    title = title.replaceAll(RegExp(
      r'\s+(?:at|in|near)\s+[^,]+$',
      caseSensitive: false,
    ), '');

    // Remove duration phrases
    title = title.replaceAll(RegExp(
      r'\s+for\s+(?:\d+\s*(?:hour|minute|hr|min)s?|\d+:\d+)',
      caseSensitive: false,
    ), '');

    // Clean up common prefixes
    final prefixes = ['visit', 'go to', 'head to', 'explore', 'check out', 'see'];
    for (final prefix in prefixes) {
      if (title.toLowerCase().startsWith(prefix)) {
        title = title.substring(prefix.length).trim();
      }
    }

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return title.trim();
  }

  /// Extract location from text
  static String? _extractLocation(String text) {
    // Patterns: "at X", "in X", "near X"
    final patterns = [
      RegExp(r'(?:at|in|near)\s+([A-Za-z\s]+?)(?:\s+at\s+\d|\s+for\s+|$)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final location = match.group(1)!.trim();
        if (location.length > 2) {
          // Capitalize each word
          return location.split(' ').map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');
        }
      }
    }

    return null;
  }

  /// Extract time from text
  static TimeOfDay? _extractTime(String text) {
    // Match patterns like "at 10", "at 10:30", "at 10am", "at 10:30 PM"
    final timePattern = RegExp(
      r'(?:at|around|by|from)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );

    final match = timePattern.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final amPm = match.group(3)?.toLowerCase();

      // Handle AM/PM
      if (amPm == 'pm' && hour < 12) {
        hour += 12;
      } else if (amPm == 'am' && hour == 12) {
        hour = 0;
      } else if (amPm == null && hour < 7) {
        // Assume PM for times 1-6 without AM/PM specified
        hour += 12;
      }

      return TimeOfDay(hour: hour, minute: minute);
    }

    // Handle special times
    if (text.contains('morning')) return const TimeOfDay(hour: 9, minute: 0);
    if (text.contains('afternoon')) return const TimeOfDay(hour: 14, minute: 0);
    if (text.contains('evening')) return const TimeOfDay(hour: 18, minute: 0);
    if (text.contains('noon') || text.contains('lunch')) return const TimeOfDay(hour: 12, minute: 0);
    if (text.contains('breakfast')) return const TimeOfDay(hour: 8, minute: 0);
    if (text.contains('dinner')) return const TimeOfDay(hour: 19, minute: 0);
    if (text.contains('sunrise')) return const TimeOfDay(hour: 6, minute: 0);
    if (text.contains('sunset')) return const TimeOfDay(hour: 18, minute: 0);

    return null;
  }

  /// Extract duration in minutes from text
  static int? _extractDuration(String text) {
    // Match patterns like "for 2 hours", "for 30 minutes", "for 1.5 hours"
    final hourPattern = RegExp(r'for\s+(\d+(?:\.\d+)?)\s*(?:hour|hr)s?', caseSensitive: false);
    final minutePattern = RegExp(r'for\s+(\d+)\s*(?:minute|min)s?', caseSensitive: false);

    final hourMatch = hourPattern.firstMatch(text);
    if (hourMatch != null) {
      final hours = double.parse(hourMatch.group(1)!);
      return (hours * 60).round();
    }

    final minuteMatch = minutePattern.firstMatch(text);
    if (minuteMatch != null) {
      return int.parse(minuteMatch.group(1)!);
    }

    return null;
  }

  /// Extract description (anything extra that's not title/time/location)
  static String? _extractDescription(String text) {
    // For now, return null - description can be added manually
    return null;
  }
}

/// Parsed itinerary item details from voice input
class ItineraryItemDetails {
  final String title;
  final String? location;
  final TimeOfDay? startTime;
  final int? duration; // in minutes
  final String? description;
  final String rawText;

  ItineraryItemDetails({
    required this.title,
    this.location,
    this.startTime,
    this.duration,
    this.description,
    required this.rawText,
  });

  bool get hasTitle => title.isNotEmpty;
  bool get hasTime => startTime != null;
  bool get hasLocation => location != null && location!.isNotEmpty;

  /// Calculate end time based on start time and duration
  TimeOfDay? get endTime {
    if (startTime == null || duration == null) return null;

    final totalMinutes = startTime!.hour * 60 + startTime!.minute + duration!;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  @override
  String toString() {
    return 'ItineraryItemDetails(title: $title, location: $location, '
        'startTime: $startTime, duration: $duration, description: $description)';
  }
}
