// AI Trip Wizard Page
//
// Unified AI-powered voice input for complete trip creation
// Uses Groq Whisper for speech-to-text (supports 99+ languages)
// Flow: Record → Process → Show Preview → Generate Trip

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/services/groq_whisper_service.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/widgets/ai_orb_animation.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../shared/models/checklist_model.dart';
import '../../../ai_itinerary/data/services/gemini_service.dart';
import '../../../ai_itinerary/presentation/providers/ai_itinerary_providers.dart';
import '../../../checklists/presentation/providers/checklist_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../providers/trip_providers.dart';
import 'package:uuid/uuid.dart';

/// Voice input states for clear UX flow
enum VoiceState {
  idle,           // Ready to record
  recording,      // Recording audio
  processing,     // Transcribing with Whisper
  preview,        // Showing parsed preview (text only)
  generatingPlan, // AI generating itinerary preview
  planPreview,    // Showing full itinerary for review/refinement
  refining,       // AI refining the plan based on user feedback
  creating,       // Creating trip in database
}

class AiTripWizardPage extends ConsumerStatefulWidget {
  const AiTripWizardPage({super.key});

  @override
  ConsumerState<AiTripWizardPage> createState() => _AiTripWizardPageState();
}

class _AiTripWizardPageState extends ConsumerState<AiTripWizardPage>
    with TickerProviderStateMixin {
  // Groq Whisper service for cloud speech-to-text
  late GroqWhisperService _whisperService;
  late AudioRecorder _audioRecorder;
  String? _currentRecordingPath;

  // Voice state machine
  VoiceState _voiceState = VoiceState.idle;
  String _transcribedText = '';
  String? _errorMessage;
  double _soundLevel = 0.0;

  // Selected language for speech recognition
  String _selectedLanguage = 'ta'; // Default to Tamil for better accuracy

  // Auto-detected language from Whisper
  String? _detectedLanguage;

  // Language names for display
  static const Map<String, String> _languageNames = {
    'en': 'English',
    'ta': 'Tamil',
    'hi': 'Hindi',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'mr': 'Marathi',
    'bn': 'Bengali',
    'gu': 'Gujarati',
    'pa': 'Punjabi',
    'ur': 'Urdu',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'ru': 'Russian',
  };

  // AI Generation state
  String _generationStatus = '';
  int _generationStep = 0;

  // Plan preview and refinement state
  AiCompleteTripPlan? _currentPlan;
  int _refinementCount = 0;
  static const int _maxRefinements = 3;
  final TextEditingController _refinementController = TextEditingController();
  bool _isRefiningWithVoice = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late AnimationController _recordingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initWhisperService();
    _initAnimations();
  }

  void _initWhisperService() {
    const groqApiKey = String.fromEnvironment(
      'GROQ_API_KEY',
      defaultValue: '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',
    );
    _whisperService = GroqWhisperService(groqApiKey);
    _audioRecorder = AudioRecorder();
    debugPrint('✅ Whisper service initialized');
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

    _recordingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Start entrance animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  /// Start recording audio for Whisper transcription
  Future<void> _startRecording() async {
    // Check microphone permission
    if (!await _audioRecorder.hasPermission()) {
      setState(() {
        _errorMessage = 'Microphone permission required';
      });
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/whisper_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Use WAV format at 16kHz for optimal Whisper transcription
      // Whisper works best with uncompressed audio at 16kHz sample rate
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,  // Whisper's native sample rate
          numChannels: 1,     // Mono is sufficient for speech
        ),
        path: _currentRecordingPath!,
      );

      setState(() {
        _voiceState = VoiceState.recording;
        _errorMessage = null;
        _transcribedText = '';
      });

      HapticFeedback.mediumImpact();
      _recordingController.repeat(reverse: true);
      _monitorAudioLevels();
      debugPrint('🎙️ Recording started');
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      setState(() {
        _errorMessage = 'Failed to start recording';
      });
    }
  }

  /// Monitor audio levels during recording
  void _monitorAudioLevels() async {
    while (_voiceState == VoiceState.recording) {
      try {
        final amplitude = await _audioRecorder.getAmplitude();
        if (mounted && _voiceState == VoiceState.recording) {
          setState(() {
            // Convert amplitude to 0-1 scale
            _soundLevel = ((amplitude.current + 50) / 50).clamp(0.0, 1.0);
          });
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Get language-specific prompt to improve Whisper accuracy
  /// Note: Groq Whisper has 896 character limit for prompts
  /// These prompts include common travel vocabulary to guide transcription
  String? _getLanguagePrompt(String langCode) {
    switch (langCode) {
      case 'ta':
        // Tamil travel vocabulary (under 896 chars)
        return 'தமிழ் பயண திட்டமிடல். பயணம், சுற்றுலா, விடுமுறை, கோவில், கடற்கரை, மலை. '
            'நாட்கள், வாரம். குடும்பம், நண்பர்கள். '
            'கேரளா, கோவா, ஊட்டி, மூணார், மதுரை, திருப்பதி. '
            'ஐந்து நாட்கள், மூன்று நாட்கள், ஒரு வாரம். '
            'போக வேண்டும், செல்ல வேண்டும். அடுத்த வாரம், அடுத்த மாதம்.';
      case 'hi':
        // Hindi travel vocabulary (under 896 chars)
        return 'हिंदी यात्रा योजना। यात्रा, घूमना, छुट्टी, मंदिर, समुद्र तट, पहाड़। '
            'दिन, हफ्ता। परिवार, दोस्त। '
            'गोवा, केरला, मनाली, शिमला, जयपुर, वाराणसी, लद्दाख। '
            'पांच दिन, तीन दिन, एक हफ्ता। '
            'जाना है, घूमना है। अगले हफ्ते, अगले महीने।';
      case 'te':
        // Telugu travel vocabulary
        return 'తెలుగు ప్రయాణ ప్రణాళిక. ప్రయాణం, పర్యటన, సెలవు, గుడి, బీచ్, కొండలు. '
            'రోజులు, వారం. కుటుంబం, స్నేహితులు. '
            'గోవా, కేరళ, ఊటీ, తిరుపతి. ఐదు రోజులు, మూడు రోజులు.';
      case 'kn':
        // Kannada travel vocabulary
        return 'ಕನ್ನಡ ಪ್ರಯಾಣ ಯೋಜನೆ. ಪ್ರಯಾಣ, ಪ್ರವಾಸ, ರಜೆ, ದೇವಸ್ಥಾನ, ಬೀಚ್, ಬೆಟ್ಟ. '
            'ದಿನಗಳು, ವಾರ. ಕುಟುಂಬ, ಸ್ನೇಹಿತರು. '
            'ಗೋವಾ, ಕೇರಳ, ಊಟಿ, ಮೈಸೂರು. ಐದು ದಿನ, ಮೂರು ದಿನ.';
      case 'ml':
        // Malayalam travel vocabulary
        return 'മലയാളം യാത്രാ ആസൂത്രണം. യാത്ര, പര്യടനം, അവധി, ക്ഷേത്രം, ബീച്ച്, മല. '
            'ദിവസങ്ങൾ, ആഴ്ച. കുടുംബം, സുഹൃത്തുക്കൾ. '
            'ഗോവ, കേരളം, ഊട്ടി, മൂന്നാർ. അഞ്ച് ദിവസം, മൂന്ന് ദിവസം.';
      case 'mr':
        // Marathi travel vocabulary
        return 'मराठी प्रवास नियोजन. प्रवास, सहल, सुट्टी, मंदिर, समुद्रकिनारा, डोंगर. '
            'दिवस, आठवडा. कुटुंब, मित्र. '
            'गोवा, केरळ, महाबळेश्वर. पाच दिवस, तीन दिवस.';
      default:
        return null; // No prompt needed for English
    }
  }

  /// Stop recording and transcribe with Whisper
  Future<void> _stopAndTranscribe() async {
    if (_voiceState != VoiceState.recording) return;

    _recordingController.stop();
    HapticFeedback.lightImpact();

    setState(() {
      _voiceState = VoiceState.processing;
      _soundLevel = 0;
    });

    try {
      final path = await _audioRecorder.stop();
      debugPrint('🎙️ Recording stopped: $path');

      if (path != null) {
        // Get file size for debugging
        final file = File(path);
        final fileSize = await file.length();
        debugPrint('📊 [DEBUG] Audio file size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
        debugPrint('🌐 [DEBUG] Selected language for Whisper: $_selectedLanguage');

        // Build language-specific prompt to help with accuracy
        final prompt = _getLanguagePrompt(_selectedLanguage);
        debugPrint('📝 [DEBUG] Language prompt: ${prompt ?? "none (English)"}');

        // Pass selected language + prompt for better accuracy
        final result = await _whisperService.transcribeFile(
          audioFilePath: path,
          language: _selectedLanguage,
          prompt: prompt,
        );

        // Clean up recording file
        try {
          await File(path).delete();
        } catch (_) {}

        // Detailed debug output
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('📊 [WHISPER RESULT]');
        debugPrint('   Success: ${result.success}');
        debugPrint('   Detected Language: ${result.detectedLanguage}');
        debugPrint('   Duration: ${result.duration?.toStringAsFixed(1)}s');
        debugPrint('   Error: ${result.error ?? "none"}');
        debugPrint('───────────────────────────────────────────────────────');
        debugPrint('   TRANSCRIBED TEXT:');
        debugPrint('   "${result.text}"');
        debugPrint('═══════════════════════════════════════════════════════');

        // Check for language mismatch
        if (result.detectedLanguage != null &&
            result.detectedLanguage != _selectedLanguage) {
          debugPrint('⚠️ [WARNING] Language mismatch!');
          debugPrint('   Expected: $_selectedLanguage');
          debugPrint('   Detected: ${result.detectedLanguage}');
          debugPrint('   This could cause transcription issues.');
        }

        if (result.success && result.text.trim().isNotEmpty) {
          setState(() {
            _transcribedText = result.text.trim();
            _detectedLanguage = result.detectedLanguage;
            _voiceState = VoiceState.preview;
          });
          HapticFeedback.mediumImpact();
          debugPrint('✅ Transcription stored: $_transcribedText');
        } else {
          setState(() {
            _voiceState = VoiceState.idle;
            _errorMessage = result.error ?? 'Could not understand. Please try again.';
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Transcription error: $e');
      debugPrint('📚 Stack: $stackTrace');
      setState(() {
        _voiceState = VoiceState.idle;
        _errorMessage = 'Transcription failed. Please try again.';
      });
    }
  }

  /// Toggle recording on/off
  Future<void> _toggleRecording() async {
    if (_voiceState == VoiceState.recording) {
      await _stopAndTranscribe();
    } else if (_voiceState == VoiceState.idle || _voiceState == VoiceState.preview) {
      // If in preview, user wants to re-record
      if (_voiceState == VoiceState.preview) {
        setState(() {
          _transcribedText = '';
        });
      }
      await _startRecording();
    }
  }

  /// Generate AI plan preview (Step 1: Generate plan for review)
  Future<void> _generatePlanPreview() async {
    if (_voiceState == VoiceState.generatingPlan) return;
    if (_transcribedText.trim().isEmpty) return;

    setState(() {
      _voiceState = VoiceState.generatingPlan;
      _generationStep = 1;
      _generationStatus = 'AI is planning your trip...';
      _refinementCount = 0;
    });
    HapticFeedback.mediumImpact();

    try {
      debugPrint('🚀 Generating AI trip plan preview...');
      debugPrint('   Voice input: $_transcribedText');

      final aiService = ref.read(multiProviderAiServiceProvider);
      final tripPlan = await aiService.generateCompleteTripPlanFromVoice(
        voiceInput: _transcribedText,
      );
      debugPrint('✅ AI generated plan: ${tripPlan.destination}, ${tripPlan.durationDays} days');

      if (mounted) {
        setState(() {
          _currentPlan = tripPlan;
          _voiceState = VoiceState.planPreview;
          _errorMessage = null;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating plan: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        String userMessage = 'Failed to generate plan. Please try again.';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('rate limit') || errorStr.contains('429') || errorStr.contains('busy')) {
          userMessage = 'AI service is rate limited. Please wait 1-2 minutes and tap "Generate Plan" again.';
        } else if (errorStr.contains('unavailable')) {
          userMessage = 'AI service temporarily unavailable. Please wait a moment and try again.';
        }

        setState(() {
          _voiceState = VoiceState.preview;
          _errorMessage = userMessage;
        });

        // Show snackbar with retry hint
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _generatePlanPreview,
            ),
          ),
        );
      }
    }
  }

  /// Refine the plan based on user feedback
  Future<void> _refinePlan(String refinementRequest) async {
    if (_currentPlan == null) return;
    if (_refinementCount >= _maxRefinements) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum refinements reached. Please create the trip or start over.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _voiceState = VoiceState.refining;
      _generationStatus = 'AI is refining your plan...';
    });
    HapticFeedback.mediumImpact();

    try {
      debugPrint('🔄 Refining plan with: $refinementRequest');

      final aiService = ref.read(multiProviderAiServiceProvider);

      // Use dedicated refinement method that understands we're UPDATING, not creating
      final refinedPlan = await aiService.refineTripPlan(
        currentPlan: _currentPlan!,
        refinementRequest: refinementRequest,
      );

      if (mounted) {
        setState(() {
          _currentPlan = refinedPlan;
          _refinementCount++;
          _voiceState = VoiceState.planPreview;
          _refinementController.clear();
          _isRefiningWithVoice = false;
        });
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated! ${_maxRefinements - _refinementCount} refinements remaining.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error refining plan: $e');
      if (mounted) {
        setState(() {
          _voiceState = VoiceState.planPreview;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refine plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Start voice recording for refinement
  Future<void> _startRefinementRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      setState(() => _errorMessage = 'Microphone permission required');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/refinement_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      setState(() {
        _isRefiningWithVoice = true;
      });
      HapticFeedback.mediumImpact();
      _recordingController.repeat(reverse: true);
      debugPrint('🎙️ Refinement recording started');
    } catch (e) {
      debugPrint('❌ Failed to start refinement recording: $e');
    }
  }

  /// Stop refinement recording and transcribe
  Future<void> _stopRefinementRecording() async {
    if (!_isRefiningWithVoice) return;

    _recordingController.stop();
    HapticFeedback.lightImpact();

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final prompt = _getLanguagePrompt(_selectedLanguage);
        final result = await _whisperService.transcribeFile(
          audioFilePath: path,
          language: _selectedLanguage,
          prompt: prompt,
        );

        try {
          await File(path).delete();
        } catch (_) {}

        if (result.success && result.text.trim().isNotEmpty) {
          await _refinePlan(result.text.trim());
        } else {
          setState(() {
            _isRefiningWithVoice = false;
            _errorMessage = 'Could not understand. Please try again.';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Refinement transcription error: $e');
      setState(() {
        _isRefiningWithVoice = false;
      });
    }
  }

  /// Create the trip from the current plan (Step 2: Save to database)
  Future<void> _createTripFromPlan() async {
    if (_currentPlan == null) return;
    if (_voiceState == VoiceState.creating) return;

    final tripPlan = _currentPlan!;

    setState(() {
      _voiceState = VoiceState.creating;
      _generationStep = 2;
      _generationStatus = 'Creating your trip...';
    });
    HapticFeedback.mediumImpact();

    try {
      final controller = ref.read(tripControllerProvider.notifier);
      final tripName = _ensurePeppyName(tripPlan.tripName, tripPlan.destination);

      final durationDays = tripPlan.durationDays;
      DateTime startDate = tripPlan.startDate ?? DateTime.now().add(const Duration(days: 7));
      DateTime endDate = tripPlan.endDate ?? startDate.add(Duration(days: durationDays - 1));

      final trip = await controller.createTrip(
        name: tripName,
        destination: tripPlan.destination,
        startDate: startDate,
        endDate: endDate,
        isPublic: false,
      );

      // Step 3: Save itinerary
      setState(() {
        _generationStep = 3;
        _generationStatus = 'Saving your itinerary...';
      });

      final itineraryDataSource = ref.read(itineraryRemoteDataSourceProvider);
      for (final day in tripPlan.days) {
        for (final activity in day.activities) {
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
              var activityDay = startDate.day + day.dayNumber - 1;
              if (activityStartTime != null && endHour < activityStartTime.hour) {
                activityDay += 1;
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

      // Step 4: Save checklist
      setState(() {
        _generationStep = 4;
        _generationStatus = 'Saving your packing list...';
      });

      final checklistDataSource = ref.read(checklistRemoteDataSourceProvider);
      final userId = SupabaseClientWrapper.currentUserId;
      final uuid = const Uuid();
      final now = DateTime.now();

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
        String userMessage = 'Failed to create trip. Please try again.';
        if (e.toString().contains('rate limit') || e.toString().contains('429')) {
          userMessage = 'AI service is busy. Please wait a moment and try again.';
        }

        setState(() {
          _voiceState = VoiceState.planPreview;
          _errorMessage = userMessage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _createTripFromPlan,
            ),
          ),
        );
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
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trip Created!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              tripName,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildSuccessStat(Icons.calendar_view_day, '${tripPlan.days.length} days planned', Colors.cyanAccent),
            const SizedBox(height: 8),
            _buildSuccessStat(Icons.place, '${_countActivities(tripPlan)} activities', Colors.orangeAccent),
            const SizedBox(height: 8),
            _buildSuccessStat(Icons.checklist, '${tripPlan.packingList.length} packing items', Colors.purpleAccent),
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
                gradient: const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text('View Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
      ],
    );
  }

  int _countActivities(AiCompleteTripPlan tripPlan) {
    return tripPlan.days.fold(0, (sum, day) => sum + day.activities.length);
  }

  String _ensurePeppyName(String aiName, String destination) {
    if (aiName.isNotEmpty &&
        !aiName.toLowerCase().startsWith('trip to') &&
        !aiName.toLowerCase().startsWith('my trip')) {
      return aiName;
    }

    final peppyPrefixes = ['Amazing', 'Magical', 'Dreamy', 'Epic', 'Blissful', 'Enchanting'];
    final peppySuffixes = ['Adventure', 'Escape', 'Getaway', 'Journey', 'Expedition', 'Voyage'];

    final random = math.Random();
    final prefix = peppyPrefixes[random.nextInt(peppyPrefixes.length)];
    final suffix = peppySuffixes[random.nextInt(peppySuffixes.length)];
    final cleanDest = destination.split(',').first.trim();

    return '$prefix $cleanDest $suffix';
  }

  /// Random trip ideas
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

  /// Allow user to edit the transcribed text
  void _editTranscription() {
    final controller = TextEditingController(text: _transcribedText);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white70, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Trip Request',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                'Correct or modify the transcribed text:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g., 5 day family trip to Goa with beach activities',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final newText = controller.text.trim();
                        if (newText.isNotEmpty) {
                          setState(() {
                            _transcribedText = newText;
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _generateRandomTrip() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    final idea = _randomTripIdeas[random.nextInt(_randomTripIdeas.length)];

    final phrases = [
      'Plan a ${idea['duration']} day ${idea['type']} to ${idea['destination']}',
      '${idea['duration']} day ${idea['type'].toString().toLowerCase()} in ${idea['destination']}',
      'Family trip to ${idea['destination']} for ${idea['duration']} days',
    ];

    setState(() {
      _transcribedText = phrases[random.nextInt(phrases.length)];
      _voiceState = VoiceState.preview;
      _errorMessage = null;
    });

    _scaleController.reset();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _refinementController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _recordingController.dispose();
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
                child: _buildMainContent(themeData, size),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build main content based on current voice state
  Widget _buildMainContent(AppThemeData themeData, Size size) {
    // Show generating/refining/creating view with progress
    if (_voiceState == VoiceState.generatingPlan ||
        _voiceState == VoiceState.refining ||
        _voiceState == VoiceState.creating) {
      return _buildGeneratingView(themeData);
    }

    // Show full plan preview with refinement options
    if (_voiceState == VoiceState.planPreview) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: _buildPlanPreviewSection(themeData),
        ),
      );
    }

    // Default: show voice input UI (idle, recording, processing, preview)
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 16),
                _buildVoiceOrb(themeData, size),
                const SizedBox(height: 24),
                _buildStatusSection(themeData),
                const SizedBox(height: 16),
                if (_voiceState == VoiceState.preview)
                  _buildPreviewSection(themeData),
                if (_voiceState == VoiceState.idle && _transcribedText.isEmpty)
                  _buildHintSection(themeData),
                _buildActionButtons(themeData),
                const SizedBox(height: 24),
              ],
            ),
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
          AiOrbAnimation(size: 200, isActive: true, soundLevel: 0.5),
          const SizedBox(height: 40),
          Text(
            _generationStatus,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, 'Parse', Icons.psychology),
              _buildStepConnector(_generationStep >= 2),
              _buildStepIndicator(2, 'Trip', Icons.flight_takeoff),
              _buildStepConnector(_generationStep >= 3),
              _buildStepIndicator(3, 'Plan', Icons.calendar_month),
              _buildStepConnector(_generationStep >= 4),
              _buildStepIndicator(4, 'Pack', Icons.checklist),
            ],
          ),
          const SizedBox(height: 40),
          if (_generationStep < 5)
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
          width: 44,
          height: 44,
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
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? const Color(0xFF00D9FF) : Colors.white.withValues(alpha: 0.2),
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
              border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF00D9FF), size: 18),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
                  ).createShader(bounds),
                  child: const Text(
                    'AI Trip Wizard',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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

  Widget _buildLanguageSelector() {
    final langName = _languageNames[_selectedLanguage] ?? _selectedLanguage.toUpperCase();

    return PopupMenuButton<String>(
      onSelected: (lang) {
        setState(() {
          _selectedLanguage = lang;
        });
        HapticFeedback.selectionClick();
      },
      itemBuilder: (context) => [
        _buildLanguageMenuItem('ta', 'தமிழ் (Tamil)'),
        _buildLanguageMenuItem('hi', 'हिंदी (Hindi)'),
        _buildLanguageMenuItem('en', 'English'),
        _buildLanguageMenuItem('te', 'తెలుగు (Telugu)'),
        _buildLanguageMenuItem('kn', 'ಕನ್ನಡ (Kannada)'),
        _buildLanguageMenuItem('ml', 'മലയാളം (Malayalam)'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              langName,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildLanguageMenuItem(String code, String name) {
    final isSelected = _selectedLanguage == code;
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check, color: Color(0xFF00D9FF), size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF00D9FF) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceOrb(AppThemeData themeData, Size size) {
    final sphereSize = size.width * 0.55;
    final isRecording = _voiceState == VoiceState.recording;
    final isProcessing = _voiceState == VoiceState.processing;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: isProcessing ? null : _toggleRecording,
        child: SizedBox(
          width: sphereSize,
          height: sphereSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AiOrbAnimation(
                size: sphereSize,
                isActive: isRecording || isProcessing,
                soundLevel: _soundLevel,
              ),
              // Center icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isProcessing
                    ? Column(
                        key: const ValueKey('processing'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : isRecording
                        // When recording, show nothing in center - let the animation be clean
                        ? const SizedBox.shrink(key: ValueKey('recording'))
                        : Container(
                            key: const ValueKey('idle'),
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
                            child: const Icon(Icons.mic, size: 30, color: Colors.white),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(AppThemeData themeData) {
    String statusText;
    String? subText;
    Color statusColor;
    IconData? statusIcon;

    switch (_voiceState) {
      case VoiceState.idle:
        if (_errorMessage != null) {
          statusText = _errorMessage!;
          statusColor = Colors.redAccent;
          statusIcon = Icons.error_outline;
        } else {
          statusText = 'Tap to start recording';
          subText = 'Speak in any language';
          statusColor = Colors.white70;
          statusIcon = Icons.mic_none;
        }
        break;
      case VoiceState.recording:
        statusText = 'Listening...';
        subText = 'Tap the orb when done';
        statusColor = Colors.redAccent;
        statusIcon = Icons.graphic_eq;
        break;
      case VoiceState.processing:
        statusText = 'Transcribing your speech...';
        statusColor = const Color(0xFF00D9FF);
        statusIcon = Icons.cloud_sync;
        break;
      case VoiceState.preview:
        statusText = 'Ready to generate your plan!';
        subText = 'Review below and tap Generate';
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        break;
      case VoiceState.generatingPlan:
        statusText = _generationStatus;
        statusColor = const Color(0xFF00D9FF);
        statusIcon = Icons.auto_awesome;
        break;
      case VoiceState.planPreview:
        statusText = 'Review your trip plan';
        subText = 'Refine or create trip';
        statusColor = Colors.greenAccent;
        statusIcon = Icons.visibility;
        break;
      case VoiceState.refining:
        statusText = _generationStatus;
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = Icons.edit_note;
        break;
      case VoiceState.creating:
        statusText = _generationStatus;
        statusColor = const Color(0xFF00D9FF);
        statusIcon = Icons.rocket_launch;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey('$_voiceState$_errorMessage'),
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
                    style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w500),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(AppThemeData themeData) {
    // Get detected language name for display
    final detectedLangName = _detectedLanguage != null
        ? _languageNames[_detectedLanguage] ?? _detectedLanguage!.toUpperCase()
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Transcribed text
          Container(
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
                    Icon(Icons.record_voice_over, color: Colors.white.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detectedLangName != null ? 'Transcribed ($detectedLangName):' : 'Transcribed:',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Edit button to modify transcription
                    GestureDetector(
                      onTap: _editTranscription,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.6), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _transcribedText,
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // AI will create section
          Container(
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
              border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.3)),
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
                      style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPreviewRow(Icons.place, 'Destination', 'Extracted from your speech', Colors.orangeAccent),
                const SizedBox(height: 10),
                _buildPreviewRow(Icons.calendar_today, 'Duration', 'Days & dates identified', Colors.cyanAccent),
                const SizedBox(height: 10),
                _buildPreviewRow(Icons.calendar_month, 'Itinerary', 'Day-by-day activities', Colors.purpleAccent),
                const SizedBox(height: 10),
                _buildPreviewRow(Icons.checklist, 'Packing List', 'Trip-specific essentials', Colors.pinkAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildHintSection(AppThemeData themeData) {
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
            'Try saying:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildHintItem('"5 day family trip to Kerala"'),
          const SizedBox(height: 8),
          _buildHintItem('"Adventure in Ladakh for a week"'),
          const SizedBox(height: 8),
          _buildHintItem('"Romantic Udaipur getaway"'),
          const SizedBox(height: 16),
          _buildSurpriseMeButton(),
        ],
      ),
    );
  }

  Widget _buildHintItem(String text) {
    final cleanText = text.replaceAll('"', '');
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _transcribedText = cleanText;
          _voiceState = VoiceState.preview;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), width: 1.5),
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

  Widget _buildActionButtons(AppThemeData themeData) {
    final isPreview = _voiceState == VoiceState.preview;
    final isRecording = _voiceState == VoiceState.recording;
    final isProcessing = _voiceState == VoiceState.processing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isPreview) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleRecording,
                icon: const Icon(Icons.replay),
                label: const Text('Re-record'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: isPreview ? 2 : 1,
            child: ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : isPreview
                      ? _generatePlanPreview  // Changed: now generates preview first
                      : isRecording
                          ? _stopAndTranscribe
                          : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPreview
                    ? Colors.greenAccent
                    : isRecording
                        ? Colors.redAccent
                        : const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: (isPreview
                        ? Colors.greenAccent
                        : isRecording
                            ? Colors.redAccent
                            : const Color(0xFF00D9FF))
                    .withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPreview
                        ? Icons.auto_awesome
                        : isRecording
                            ? Icons.stop
                            : Icons.mic,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPreview
                        ? 'Generate Plan'  // Changed text
                        : isRecording
                            ? 'Stop Recording'
                            : 'Start Recording',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the full plan preview with itinerary and checklist
  Widget _buildPlanPreviewSection(AppThemeData themeData) {
    if (_currentPlan == null) return const SizedBox.shrink();

    final plan = _currentPlan!;
    final remainingRefinements = _maxRefinements - _refinementCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip header
          Container(
            padding: const EdgeInsets.all(16),
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
              border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.tripName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${plan.durationDays} days',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      plan.destination,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (plan.startDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${plan.startDate!.day}/${plan.startDate!.month}/${plan.startDate!.year}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Itinerary section
          Text(
            'Itinerary',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Day cards
          ...plan.days.map((day) => _buildDayCard(day)),

          const SizedBox(height: 16),

          // Packing list section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist, color: Colors.pinkAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Packing List (${plan.packingList.length} items)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: plan.packingList.take(10).map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  )).toList(),
                ),
                if (plan.packingList.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${plan.packingList.length - 10} more items',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Refinement input section
          if (remainingRefinements > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Refine Plan ($remainingRefinements left)',
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _refinementController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g., "Add a sunset point visit"',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _refinePlan(value.trim());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Voice refinement button
                      GestureDetector(
                        onTap: _isRefiningWithVoice
                            ? _stopRefinementRecording
                            : _startRefinementRecording,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isRefiningWithVoice
                                ? Colors.redAccent
                                : const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isRefiningWithVoice ? Icons.stop : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send text refinement
                      GestureDetector(
                        onTap: () {
                          final text = _refinementController.text.trim();
                          if (text.isNotEmpty) {
                            _refinePlan(text);
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D9FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try: "Add camel ride", "Remove museum", "Add hiking shoes to packing"',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],

          // Action buttons for plan preview
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentPlan = null;
                      _voiceState = VoiceState.preview;
                      _refinementCount = 0;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _createTripFromPlan,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Create Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Build a single day card for the itinerary
  Widget _buildDayCard(AiItineraryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white54,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withValues(alpha: 0.3),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${day.dayNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${day.activities.length} activities',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          children: day.activities.map((activity) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.startTime != null)
                  SizedBox(
                    width: 50,
                    child: Text(
                      activity.startTime!,
                      style: TextStyle(
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 50),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: _getActivityColor(activity.category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                      if (activity.location != null && activity.location!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  activity.location!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  /// Get color for activity category
  Color _getActivityColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'sightseeing':
        return Colors.orangeAccent;
      case 'food':
        return Colors.pinkAccent;
      case 'transport':
        return Colors.blueAccent;
      case 'accommodation':
        return Colors.purpleAccent;
      case 'activity':
      case 'adventure':
        return Colors.greenAccent;
      case 'shopping':
        return Colors.amberAccent;
      default:
        return Colors.cyanAccent;
    }
  }
}
