// AI Trip Wizard Page
//
// Unified AI-powered voice input for complete trip creation
// Creates: Trip + AI Itinerary + AI Packing Checklist in one go
// Features stunning Perplexity-like animations and real-time speech recognition

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/widgets/ai_orb_animation.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/checklist_model.dart';
import '../../../ai_itinerary/data/services/gemini_service.dart';
import '../../../ai_itinerary/presentation/providers/ai_itinerary_providers.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../providers/trip_providers.dart';
import 'package:uuid/uuid.dart';

class AiTripWizardPage extends ConsumerStatefulWidget {
  const AiTripWizardPage({super.key});

  @override
  ConsumerState<AiTripWizardPage> createState() => _AiTripWizardPageState();
}

class _AiTripWizardPageState extends ConsumerState<AiTripWizardPage>
    with TickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _hasError = false;
  bool _isSimulator = false;
  bool _isPermissionDenied = false; // Microphone permission denied
  bool _isPermissionPermanentlyDenied = false; // User needs to go to Settings
  String _errorMessage = '';
  String _transcribedText = '';
  String _interimText = '';
  double _soundLevel = 0.0;

  // Language selection for speech recognition
  // Key languages: English (en_IN), Tamil (ta_IN), Hindi (hi_IN)
  String _selectedLanguage = 'en_IN'; // Default to English
  static const Map<String, String> _languages = {
    'en_IN': 'English',
    'ta_IN': 'தமிழ்',
    'hi_IN': 'हिंदी',
  };

  // Track which languages are actually available for speech recognition
  final Map<String, bool> _languageAvailability = {
    'en_IN': true, // English is always available
    'ta_IN': false,
    'hi_IN': false,
  };

  /// Update language availability based on device's speech recognition locales
  void _updateLanguageAvailability() {
    for (final localeId in _languages.keys) {
      _languageAvailability[localeId] = _voiceService.isLocaleAvailable(localeId);
    }
    debugPrint('🌐 Language availability: $_languageAvailability');
  }

  // AI Generation state
  bool _isGenerating = false;
  String _generationStatus = '';
  int _generationStep = 0; // 0: none, 1: trip, 2: itinerary, 3: checklist

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initVoiceService();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Start entrance animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _initVoiceService() async {
    _voiceService.onResult = (text, isFinal) {
      setState(() {
        if (isFinal) {
          // If continuing from previous text, append the new text
          if (_isContinuing && _previousText.isNotEmpty) {
            _transcribedText = '$_previousText. $text';
            _isContinuing = false; // Reset after appending
          } else {
            _transcribedText = text;
          }
          _interimText = '';
          // No more local parsing - AI will handle everything
        } else {
          // Show interim text (with previous text if continuing)
          if (_isContinuing && _previousText.isNotEmpty) {
            _interimText = '$_previousText. $text';
          } else {
            _interimText = text;
          }
        }
      });
    };

    _voiceService.onSoundLevelChange = (level) {
      setState(() => _soundLevel = level);
    };

    _voiceService.onError = (error) {
      setState(() {
        _hasError = true;
        _isListening = false;
        _isContinuing = false; // Reset on error

        // Handle special permission error codes
        if (error == 'PERMISSION_DENIED') {
          _isPermissionDenied = true;
          _isPermissionPermanentlyDenied = false;
          _errorMessage = 'Microphone permission required. Tap to allow.';
        } else if (error == 'PERMISSION_PERMANENTLY_DENIED') {
          _isPermissionDenied = true;
          _isPermissionPermanentlyDenied = true;
          _errorMessage = 'Microphone permission denied. Tap to open Settings.';
        } else {
          _isPermissionDenied = false;
          _isPermissionPermanentlyDenied = false;
          _errorMessage = error;
        }
      });
    };

    _voiceService.onListeningStarted = () {
      setState(() {
        _isListening = true;
        _hasError = false;
        // Only clear if NOT continuing
        if (!_isContinuing) {
          _transcribedText = '';
        }
        _interimText = '';
      });
      HapticFeedback.mediumImpact();
    };

    _voiceService.onListeningStopped = () {
      setState(() {
        _isListening = false;
        _isContinuing = false; // Reset when stopped
      });
    };

    // Check if we already have microphone permission before initializing
    final hasPermission = await _voiceService.hasMicrophonePermission();
    debugPrint('🎤 Current microphone permission: $hasPermission');

    if (!hasPermission) {
      // Don't initialize yet - wait for user to tap the mic button
      // This defers permission request to when user actually wants to use voice input
      debugPrint('🎤 Microphone permission not granted yet - will request on first mic tap');
      setState(() {
        _isInitialized = false;
        _isSimulator = false; // Assume physical device until we check
        _hasError = false; // Not an error - just not initialized yet
      });
      return;
    }

    final initialized = await _voiceService.initialize();

    // Update which languages are actually available for speech recognition
    _updateLanguageAvailability();

    // Set the selected language locale for speech recognition
    _voiceService.setLocale(_selectedLanguage);

    setState(() {
      _isInitialized = initialized;
      _isSimulator = _voiceService.isRunningOnSimulator;
    });

    debugPrint('🎤 AI Trip Wizard: initialized=$initialized, isSimulator=$_isSimulator');
    debugPrint('🎤 Using language: $_selectedLanguage (${_languages[_selectedLanguage]})');

    if (!initialized && _isSimulator && mounted) {
      // ONLY enable demo mode for actual simulators/emulators
      debugPrint('🎤 Enabling demo mode for simulator/emulator');
      setState(() {
        _hasError = false;
        _isInitialized = true; // Allow demo mode on simulator
      });
    } else if (!initialized && !_isSimulator && mounted) {
      // Physical device but speech failed - show error, DO NOT enable demo mode
      debugPrint('❌ Speech recognition failed on PHYSICAL device - NOT enabling demo mode');
      setState(() {
        _hasError = true;
        _errorMessage = 'Speech recognition not available. Please check microphone permissions in Settings.';
      });
    }
  }

  /// Change language for speech recognition
  void _changeLanguage(String locale) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLanguage = locale;
      // Clear any previous error when changing language
      _hasError = false;
      _errorMessage = '';
    });
    _voiceService.setLocale(locale);
    debugPrint('🌐 Language changed to: $locale (${_languages[locale]})');

    // Note: We don't show a warning here anymore because:
    // 1. The voice service will automatically fall back to device default if locale unavailable
    // 2. Speech will still work with device default language
    // 3. Only show error if actual speech recognition fails
  }

  /// Handle permission button tap - request permission or open settings
  Future<void> _handlePermissionButtonTap() async {
    HapticFeedback.lightImpact();

    if (_isPermissionPermanentlyDenied) {
      // Open app settings so user can enable microphone permission
      debugPrint('🔧 Opening app settings for microphone permission...');
      final opened = await _voiceService.openMicrophoneSettings();
      if (opened) {
        // Show a snackbar to guide the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enable microphone permission in Settings, then return to the app'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      // Request permission directly
      debugPrint('🎤 Requesting microphone permission...');
      final granted = await _voiceService.requestMicrophonePermission();
      if (granted) {
        // Permission granted - reinitialize the voice service
        setState(() {
          _hasError = false;
          _isPermissionDenied = false;
          _isPermissionPermanentlyDenied = false;
          _errorMessage = '';
        });
        await _initVoiceService();
      } else {
        // Permission denied - check if permanently denied
        final isPermanentlyDenied = await _voiceService.isMicrophonePermissionPermanentlyDenied();
        setState(() {
          _isPermissionPermanentlyDenied = isPermanentlyDenied;
          _errorMessage = isPermanentlyDenied
              ? 'Microphone permission denied. Tap to open Settings.'
              : 'Microphone permission required. Tap to allow.';
        });
      }
    }
  }

  /// Track if user is continuing their input (appending to existing text)
  bool _isContinuing = false;
  String _previousText = '';

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();
    debugPrint('🎤🎤🎤 _toggleListening CALLED 🎤🎤🎤');
    debugPrint('🎤 State: _isListening=$_isListening, _isSimulator=$_isSimulator, _isInitialized=$_isInitialized');

    if (_isListening) {
      debugPrint('🎤 Already listening, stopping...');
      await _voiceService.stopListening();
    } else {
      // ALWAYS check and request microphone permission FIRST before anything else
      debugPrint('🎤 Not listening, starting permission check...');
      debugPrint('🎤 Calling hasMicrophonePermission()...');
      final hasPermission = await _voiceService.hasMicrophonePermission();
      debugPrint('🎤 hasMicrophonePermission returned: $hasPermission');

      if (!hasPermission) {
        debugPrint('🎤🎤🎤 PERMISSION NOT GRANTED - REQUESTING NOW 🎤🎤🎤');
        final granted = await _voiceService.requestMicrophonePermission();
        debugPrint('🎤🎤🎤 PERMISSION REQUEST RESULT: granted=$granted 🎤🎤🎤');

        if (!granted) {
          // Permission denied - update UI state
          debugPrint('🎤 Permission was DENIED, checking if permanently denied...');
          final isPermanentlyDenied = await _voiceService.isMicrophonePermissionPermanentlyDenied();
          debugPrint('🎤 isPermanentlyDenied=$isPermanentlyDenied');
          setState(() {
            _hasError = true;
            _isPermissionDenied = true;
            _isPermissionPermanentlyDenied = isPermanentlyDenied;
            _errorMessage = isPermanentlyDenied
                ? 'Microphone permission denied. Tap to open Settings.'
                : 'Microphone permission required. Tap to allow.';
          });
          return; // Don't proceed without permission
        }
        debugPrint('✅✅✅ Microphone permission GRANTED! ✅✅✅');
        // Re-initialize voice service now that we have permission
        await _initVoiceService();
      } else {
        debugPrint('🎤 Permission already granted, proceeding...');
      }

      // If there's already text, we're continuing (appending)
      // Otherwise, starting fresh
      if (_transcribedText.isNotEmpty) {
        _isContinuing = true;
        _previousText = _transcribedText;
      } else {
        _isContinuing = false;
        _previousText = '';
      }

      setState(() {
        _hasError = false;
        _isPermissionDenied = false;
        _isPermissionPermanentlyDenied = false;
        // Don't clear text if continuing
        if (!_isContinuing) {
          _transcribedText = '';
        }
      });

      if (_isSimulator) {
        await _runWizardDemoMode();
      } else {
        await _voiceService.startListening();
      }
    }
  }

  /// Demo mode specifically for the wizard - randomly selects from India-wide destinations
  Future<void> _runWizardDemoMode() async {
    _voiceService.onListeningStarted?.call();

    // Randomly select a destination from India-wide list
    final random = math.Random();
    final idea = _randomTripIdeas[random.nextInt(_randomTripIdeas.length)];

    // Generate varied demo phrases
    final demoPhrases = [
      'Plan a ${idea['duration']} day ${idea['type']} to ${idea['destination']}',
      '${idea['duration']} day trip to ${idea['destination']} for ${idea['type']?.toString().toLowerCase()}',
      'I want to visit ${idea['destination']} for ${idea['duration']} days',
      'Plan my ${idea['type']?.toString().toLowerCase()} vacation to ${idea['destination']}',
    ];
    final demoPhrase = demoPhrases[random.nextInt(demoPhrases.length)];
    final words = demoPhrase.split(' ');

    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 180));

      _soundLevel = 0.3 + (i % 3) * 0.25;
      _voiceService.onSoundLevelChange?.call(_soundLevel);

      final interim = words.sublist(0, i + 1).join(' ');
      _voiceService.onResult?.call(interim, false);

      await Future.delayed(const Duration(milliseconds: 80));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    _soundLevel = 0.0;
    _voiceService.onSoundLevelChange?.call(_soundLevel);
    _voiceService.onResult?.call(demoPhrase, true);

    _voiceService.onListeningStopped?.call();
  }

  /// Random trip ideas - comprehensive list
  static const List<Map<String, dynamic>> _randomTripIdeas = [
    {'destination': 'Kerala', 'duration': 5, 'type': 'Family beach & backwaters'},
    {'destination': 'Goa', 'duration': 4, 'type': 'Beach party adventure'},
    {'destination': 'Ladakh', 'duration': 7, 'type': 'Ultimate road trip'},
    {'destination': 'Rajasthan', 'duration': 6, 'type': 'Heritage & culture tour'},
    {'destination': 'Himachal', 'duration': 5, 'type': 'Mountain adventure'},
    {'destination': 'Andaman', 'duration': 6, 'type': 'Island paradise'},
    {'destination': 'Varanasi', 'duration': 3, 'type': 'Spiritual journey'},
    {'destination': 'Darjeeling', 'duration': 4, 'type': 'Tea garden retreat'},
    {'destination': 'Udaipur', 'duration': 3, 'type': 'Romantic getaway'},
    {'destination': 'Rishikesh', 'duration': 4, 'type': 'Adventure & yoga'},
    {'destination': 'Coorg', 'duration': 3, 'type': 'Coffee plantation bliss'},
    {'destination': 'Jaipur', 'duration': 3, 'type': 'Pink city heritage'},
    {'destination': 'Manali', 'duration': 5, 'type': 'Snow & adventure'},
    {'destination': 'Munnar', 'duration': 4, 'type': 'Hill station retreat'},
    {'destination': 'Sikkim', 'duration': 6, 'type': 'Northeast exploration'},
  ];

  void _generateRandomTrip() {
    HapticFeedback.mediumImpact();

    final random = math.Random();
    final idea = _randomTripIdeas[random.nextInt(_randomTripIdeas.length)];

    final phrases = [
      'Plan a ${idea['duration']} day ${idea['type']} to ${idea['destination']}',
      '${idea['duration']} day ${idea['type'].toString().toLowerCase()} in ${idea['destination']}',
      'Family trip to ${idea['destination']} for ${idea['duration']} days',
    ];
    final phrase = phrases[random.nextInt(phrases.length)];

    setState(() {
      _hasError = false;
      _transcribedText = phrase;
      // AI will parse this phrase - no local parsing needed
    });

    _scaleController.reset();
    _scaleController.forward();
  }

  /// Create complete trip with AI-generated itinerary and checklist
  /// The AI will parse the voice input and extract destination, duration, etc.
  Future<void> _createCompleteTrip() async {
    // Prevent multiple API calls
    if (_isGenerating) {
      debugPrint('⚠️ Already generating trip, ignoring duplicate request');
      return;
    }

    // Only need transcribed text - AI will parse everything
    if (_transcribedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your trip first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStep = 1;
      _generationStatus = 'AI is understanding your request...';
    });
    HapticFeedback.mediumImpact();

    try {
      debugPrint('🚀 Starting AI trip generation...');
      debugPrint('   Raw voice input: $_transcribedText');
      debugPrint('   AI will parse destination, duration, and preferences from this text');

      // Step 1: Let AI parse and generate complete trip plan
      // The AI will extract destination, duration, trip type from the raw text
      // Primary: Groq (1,000 RPD) -> Fallback: Gemini (25 RPD)
      debugPrint('📡 Calling multiProviderAiService.generateCompleteTripPlanFromVoice()...');
      final aiService = ref.read(multiProviderAiServiceProvider);
      final tripPlan = await aiService.generateCompleteTripPlanFromVoice(
        voiceInput: _transcribedText,
      );
      debugPrint('✅ AI trip plan generated successfully!');
      debugPrint('   AI extracted destination: ${tripPlan.destination}');
      debugPrint('   AI extracted duration: ${tripPlan.durationDays} days');

      // Step 2: Create the trip in database
      setState(() {
        _generationStep = 2;
        _generationStatus = 'Creating your trip...';
      });

      final controller = ref.read(tripControllerProvider.notifier);
      final tripName = _ensurePeppyName(tripPlan.tripName, tripPlan.destination);

      // Use AI-extracted dates (or fallback to 7 days from now)
      final durationDays = tripPlan.durationDays;
      DateTime startDate = tripPlan.startDate ?? DateTime.now().add(const Duration(days: 7));
      DateTime endDate = tripPlan.endDate ?? startDate.add(Duration(days: durationDays - 1));

      debugPrint('📅 Trip dates: ${startDate.toString()} to ${endDate.toString()}');

      final trip = await controller.createTrip(
        name: tripName,
        destination: tripPlan.destination, // Use AI-extracted destination
        startDate: startDate,
        endDate: endDate,
        isPublic: false,
      );

      // Step 3: Save itinerary items to database
      setState(() {
        _generationStep = 3;
        _generationStatus = 'Saving your itinerary...';
      });

      final itineraryDataSource = ref.read(itineraryRemoteDataSourceProvider);
      for (final day in tripPlan.days) {
        for (final activity in day.activities) {
          // Parse start time string to DateTime
          DateTime? activityStartTime;
          DateTime? activityEndTime;
          if (activity.startTime != null) {
            final timeParts = activity.startTime!.split(':');
            if (timeParts.length >= 2) {
              activityStartTime = DateTime(
                startDate.year,
                startDate.month,
                startDate.day + day.dayNumber - 1,
                int.tryParse(timeParts[0]) ?? 9,
                int.tryParse(timeParts[1]) ?? 0,
              );
            }
          }
          if (activity.endTime != null) {
            final timeParts = activity.endTime!.split(':');
            if (timeParts.length >= 2) {
              final endHour = int.tryParse(timeParts[0]) ?? 10;
              final endMinute = int.tryParse(timeParts[1]) ?? 0;

              // Calculate the base day for this activity
              var activityDay = startDate.day + day.dayNumber - 1;

              // If we have a start time and end time is earlier than start time,
              // the activity spans midnight - end time should be next day
              if (activityStartTime != null && endHour < activityStartTime.hour) {
                activityDay += 1; // Move end time to next day
              }

              activityEndTime = DateTime(
                startDate.year,
                startDate.month,
                activityDay,
                endHour,
                endMinute,
              );
            }
          }

          await itineraryDataSource.createItem(
            tripId: trip.id,
            title: activity.title,
            description: activity.description ?? activity.tip,
            location: activity.location,
            startTime: activityStartTime,
            endTime: activityEndTime,
            dayNumber: day.dayNumber,
          );
        }
      }

      // Step 4: Save checklist and items to database
      setState(() {
        _generationStep = 4;
        _generationStatus = 'Saving your packing list...';
      });

      final checklistDataSource = ref.read(checklistRemoteDataSourceProvider);
      final userId = SupabaseClientWrapper.currentUserId;
      final uuid = const Uuid();
      final now = DateTime.now();

      // Create checklist
      final checklistId = uuid.v4();
      final checklist = await checklistDataSource.upsertChecklist(
        ChecklistModel(
          id: checklistId,
          tripId: trip.id,
          name: 'Packing List',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Add checklist items
      for (int i = 0; i < tripPlan.packingList.length; i++) {
        final item = tripPlan.packingList[i];
        await checklistDataSource.upsertChecklistItem(
          ChecklistItemModel(
            id: uuid.v4(),
            checklistId: checklist.id,
            title: item.title,
            isCompleted: false,
            orderIndex: i,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // Success!
      setState(() {
        _generationStep = 5;
        _generationStatus = 'Your trip is ready!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessAndNavigate(trip.id, tripName, tripPlan);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating trip: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        // Parse error message for user-friendly display
        String userMessage = 'Failed to create trip';
        if (e.toString().contains('rate limit') || e.toString().contains('429')) {
          userMessage = 'AI service is busy. Please wait a moment and try again.';
        } else if (e.toString().contains('400')) {
          userMessage = 'AI request failed. Please try again.';
        } else if (e.toString().contains('unavailable')) {
          userMessage = 'AI service temporarily unavailable. Please try again later.';
        } else if (e.toString().contains('parse')) {
          userMessage = 'AI response error. Please try again.';
        } else {
          userMessage = e.toString().replaceAll('Exception:', '').trim();
        }

        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = userMessage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _createCompleteTrip,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showSuccessAndNavigate(
    String tripId,
    String tripName,
    AiCompleteTripPlan tripPlan,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.withValues(alpha: 0.3),
                    Colors.cyanAccent.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Trip Created!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tripName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildSuccessStat(
              Icons.calendar_view_day,
              '${tripPlan.days.length} days planned',
              Colors.cyanAccent,
            ),
            const SizedBox(height: 8),
            _buildSuccessStat(
              Icons.place,
              '${_countActivities(tripPlan)} activities',
              Colors.orangeAccent,
            ),
            const SizedBox(height: 8),
            _buildSuccessStat(
              Icons.checklist,
              '${tripPlan.packingList.length} packing items',
              Colors.purpleAccent,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/trips/$tripId');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'View Trip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  int _countActivities(AiCompleteTripPlan tripPlan) {
    return tripPlan.days.fold(0, (sum, day) => sum + day.activities.length);
  }

  /// Ensures the trip name is peppy and creative, not boring "Trip to X"
  String _ensurePeppyName(String aiName, String destination) {
    // If AI gave us a good name, use it
    if (aiName.isNotEmpty &&
        !aiName.toLowerCase().startsWith('trip to') &&
        !aiName.toLowerCase().startsWith('my trip')) {
      return aiName;
    }

    // Generate a peppy fallback name based on destination
    final peppyPrefixes = [
      'Amazing', 'Magical', 'Dreamy', 'Epic', 'Blissful',
      'Enchanting', 'Wanderlust', 'Spectacular', 'Vibrant', 'Glorious',
    ];
    final peppySuffixes = [
      'Adventure', 'Escape', 'Getaway', 'Journey', 'Expedition',
      'Voyage', 'Quest', 'Odyssey', 'Safari', 'Retreat',
    ];

    final random = math.Random();
    final prefix = peppyPrefixes[random.nextInt(peppyPrefixes.length)];
    final suffix = peppySuffixes[random.nextInt(peppySuffixes.length)];

    // Extract clean destination name
    final cleanDest = destination.split(',').first.trim();

    return '$prefix $cleanDest $suffix';
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    (math.sin(_backgroundController.value * 2 * math.pi) + 1) / 2,
                  )!,
                  Color.lerp(
                    const Color(0xFF0f3460),
                    const Color(0xFF1a1a2e),
                    (math.cos(_backgroundController.value * 2 * math.pi) + 1) / 2,
                  )!,
                  Color.lerp(
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                    (math.sin(_backgroundController.value * 2 * math.pi + 1) + 1) / 2,
                  )!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(themeData),
              Expanded(
                child: _isGenerating
                    ? _buildGeneratingView(themeData)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: size.height - 150,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildVoiceOrb(themeData, size),
                                  const SizedBox(height: 24),
                                  _buildStatusText(themeData),
                                  const SizedBox(height: 16),
                                  if (_transcribedText.isNotEmpty || _interimText.isNotEmpty)
                                    _buildTranscriptionArea(themeData),
                                  if (_transcribedText.isNotEmpty)
                                    _buildAiWillCreateSection(themeData),
                                  const SizedBox(height: 16),
                                  if (!_isListening && _transcribedText.isEmpty)
                                    _buildHintText(),
                                  _buildActionButtons(themeData),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingView(AppThemeData themeData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated orb during generation
          AiOrbAnimation(
            size: 200,
            isActive: true,
            soundLevel: 0.5,
          ),
          const SizedBox(height: 40),
          // Generation status
          Text(
            _generationStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, 'Trip', Icons.flight_takeoff),
              _buildStepConnector(_generationStep >= 2),
              _buildStepIndicator(2, 'Itinerary', Icons.calendar_month),
              _buildStepConnector(_generationStep >= 3),
              _buildStepIndicator(3, 'Packing', Icons.checklist),
            ],
          ),
          const SizedBox(height: 40),
          if (_generationStep < 4)
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _generationStep >= step;
    final isCompleted = _generationStep > step;

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.greenAccent.withValues(alpha: 0.3)
                : isActive
                    ? const Color(0xFF00D9FF).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: isCompleted
                  ? Colors.greenAccent
                  : isActive
                      ? const Color(0xFF00D9FF)
                      : Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted
                ? Colors.greenAccent
                : isActive
                    ? const Color(0xFF00D9FF)
                    : Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive
          ? const Color(0xFF00D9FF)
          : Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildAppBar(AppThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D9FF).withValues(alpha: 0.3),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF00D9FF),
                  size: 18,
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
                  ).createShader(bounds),
                  child: const Text(
                    'AI Trip Wizard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Language selector button
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  /// Language selector widget - tap to show language picker with availability
  Widget _buildLanguageSelector() {
    final isCurrentLanguageAvailable = _languageAvailability[_selectedLanguage] ?? false;

    return GestureDetector(
      onTap: _showLanguagePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentLanguageAvailable
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate,
              color: Colors.white.withValues(alpha: 0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _languages[_selectedLanguage] ?? 'English',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isCurrentLanguageAvailable ? Icons.arrow_drop_down : Icons.warning_amber,
              color: isCurrentLanguageAvailable
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.orange,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Show language picker bottom sheet with availability status
  void _showLanguagePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.white70, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Speech Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a language for voice input',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Language options
            ..._languages.entries.map((entry) {
              final localeId = entry.key;
              final languageName = entry.value;
              final isAvailable = _languageAvailability[localeId] ?? false;
              final isSelected = _selectedLanguage == localeId;

              return _buildLanguageOption(
                localeId: localeId,
                languageName: languageName,
                isAvailable: isAvailable,
                isSelected: isSelected,
              );
            }),

            const SizedBox(height: 16),

            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Languages marked unavailable need to be enabled in your device\'s Keyboard/Dictation settings.',
                      style: TextStyle(
                        color: Colors.blue.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Build a single language option in the picker
  Widget _buildLanguageOption({
    required String localeId,
    required String languageName,
    required bool isAvailable,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isAvailable) {
              _changeLanguage(localeId);
              Navigator.pop(context);
            } else {
              // Show setup instructions
              Navigator.pop(context);
              _showLanguageSetupDialog(localeId, languageName);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.cyan.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.cyan.withValues(alpha: 0.5)
                    : isAvailable
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Language name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageName,
                        style: TextStyle(
                          color: isAvailable ? Colors.white : Colors.white60,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (!isAvailable)
                        Text(
                          'Tap to setup',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status indicator
                if (isAvailable)
                  Icon(
                    isSelected ? Icons.check_circle : Icons.check_circle_outline,
                    color: isSelected ? Colors.cyan : Colors.green.withValues(alpha: 0.5),
                    size: 24,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, color: Colors.orange.shade300, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Setup',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show dialog with instructions to enable a language
  void _showLanguageSetupDialog(String localeId, String languageName) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.language, color: Colors.cyan),
            const SizedBox(width: 12),
            Text(
              'Enable $languageName',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$languageName speech recognition needs to be downloaded on your device.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              isIOS ? 'On iPhone:' : 'On Android:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (isIOS) ...[
              _buildSetupStep('1', 'Open Settings'),
              _buildSetupStep('2', 'Go to General → Keyboard'),
              _buildSetupStep('3', 'Tap Dictation Languages'),
              _buildSetupStep('4', 'Enable $languageName'),
              _buildSetupStep('5', 'Return to this app'),
            ] else ...[
              _buildSetupStep('1', 'Open Settings'),
              _buildSetupStep('2', 'Go to System → Languages & Input'),
              _buildSetupStep('3', 'Tap On-screen keyboard → Gboard'),
              _buildSetupStep('4', 'Tap Languages → Add $languageName'),
              _buildSetupStep('5', 'Return to this app'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _voiceService.openMicrophoneSettings();
            },
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a setup step row
  Widget _buildSetupStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOrb(AppThemeData themeData, Size size) {
    final sphereSize = size.width * 0.6;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        // Always allow tapping - _toggleListening will request permission if needed
        onTap: _toggleListening,
        child: SizedBox(
          width: sphereSize,
          height: sphereSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AiOrbAnimation(
                size: sphereSize,
                isActive: _isListening,
                soundLevel: _soundLevel,
              ),
              if (!_isListening)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(AppThemeData themeData) {
    String statusText;
    String? subText;
    Color statusColor;
    IconData? statusIcon;
    bool showPermissionButton = false;

    if (_hasError) {
      statusText = _errorMessage;
      statusColor = Colors.redAccent;
      statusIcon = Icons.error_outline;

      // Show permission button for permission errors
      if (_isPermissionDenied) {
        showPermissionButton = true;
        statusIcon = _isPermissionPermanentlyDenied ? Icons.settings : Icons.mic_off;
        statusColor = Colors.orangeAccent;
      }
    } else if (_isListening) {
      statusText = 'Listening... take your time';
      subText = 'You have 20 seconds between thoughts';
      statusColor = const Color(0xFF00D9FF);
      statusIcon = Icons.hearing;
    } else if (_transcribedText.isNotEmpty) {
      // Text recognized - AI will parse destination
      statusText = 'Ready! AI will understand your request';
      subText = 'Tap mic to add more, or tap Create Trip';
      statusColor = Colors.greenAccent;
      statusIcon = Icons.rocket_launch;
    } else if (_isSimulator) {
      statusText = 'Demo Mode - Tap to simulate';
      statusColor = Colors.cyanAccent;
      statusIcon = Icons.play_circle_outline;
    } else {
      statusText = 'Tap to plan your complete trip';
      subText = 'Take your time - we\'ll wait while you think';
      statusColor = Colors.white70;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(statusText),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (statusIcon != null) ...[
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (subText != null) ...[
              const SizedBox(height: 6),
              Text(
                subText,
                style: TextStyle(
                  color: statusColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Permission button when microphone access is denied
            if (showPermissionButton) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handlePermissionButtonTap,
                icon: Icon(
                  _isPermissionPermanentlyDenied ? Icons.settings : Icons.mic,
                  size: 18,
                ),
                label: Text(
                  _isPermissionPermanentlyDenied ? 'Open Settings' : 'Allow Microphone',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionArea(AppThemeData themeData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your trip idea:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _transcribedText.isNotEmpty ? _transcribedText : _interimText,
            style: TextStyle(
              color: _transcribedText.isNotEmpty
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
              fontStyle:
                  _transcribedText.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Shows what AI will create from the voice input
  Widget _buildAiWillCreateSection(AppThemeData themeData) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00D9FF).withValues(alpha: 0.2),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.greenAccent.withValues(alpha: 0.3),
                      Colors.cyanAccent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Will Create:',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.psychology,
            'Understanding',
            'AI will parse your request',
            const Color(0xFF00D9FF),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.flight_takeoff,
            'Trip',
            'Complete trip with destination',
            Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_month,
            'Itinerary',
            'Day-by-day activities',
            Colors.purpleAccent,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.checklist,
            'Packing List',
            'AI-generated essentials',
            Colors.pinkAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Speak or tap an example to try:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildHintItem('"5 day family trip to Kerala with beaches"'),
          const SizedBox(height: 8),
          _buildHintItem('"Adventure trip to Ladakh for a week"'),
          const SizedBox(height: 8),
          _buildHintItem('"Romantic getaway to Udaipur for 3 days"'),
          const SizedBox(height: 8),
          _buildHintItem('"Weekend trip to Goa with friends"'),
          const SizedBox(height: 16),
          _buildSurpriseMeButton(),
        ],
      ),
    );
  }

  Widget _buildSurpriseMeButton() {
    return GestureDetector(
      onTap: _generateRandomTrip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              const Color(0xFF00D9FF).withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle_rounded, color: Colors.white.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: 10),
            Text(
              'Surprise Me!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome, color: Colors.amber.withValues(alpha: 0.8), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHintItem(String text) {
    // Remove quotes from the display text for cleaner tap action
    final cleanText = text.replaceAll('"', '');

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Set the example as transcribed text so user can see it and create trip
        setState(() {
          _transcribedText = cleanText;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Icon(Icons.touch_app, color: Colors.white.withValues(alpha: 0.3), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (_transcribedText.isNotEmpty) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleListening,
                icon: const Icon(Icons.replay),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: _transcribedText.isNotEmpty ? 2 : 1,
            child: ElevatedButton(
              onPressed: _isGenerating
                  ? null // Disable button while generating to prevent multiple API calls
                  : (_transcribedText.isNotEmpty
                      ? _createCompleteTrip // AI will parse the voice input
                      : (_isListening ? _toggleListening : null)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _transcribedText.isNotEmpty
                    ? Colors.greenAccent
                    : const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: (_transcribedText.isNotEmpty
                        ? Colors.greenAccent
                        : const Color(0xFF00D9FF))
                    .withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _transcribedText.isNotEmpty
                        ? Icons.auto_awesome
                        : (_isListening ? Icons.stop : Icons.mic),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _transcribedText.isNotEmpty
                        ? 'Create Complete Trip'
                        : (_isListening ? 'Stop' : 'Start Speaking'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
