// Voice Trip Creation Page
//
// Advanced AI-powered voice input for trip creation
// Features stunning Perplexity-like animations and real-time speech recognition
// Uses on-device speech recognition (free, no API costs)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/widgets/ai_sphere_animation.dart';
import '../providers/trip_providers.dart';

class VoiceTripPage extends ConsumerStatefulWidget {
  const VoiceTripPage({super.key});

  @override
  ConsumerState<VoiceTripPage> createState() => _VoiceTripPageState();
}

class _VoiceTripPageState extends ConsumerState<VoiceTripPage>
    with TickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _hasError = false;
  bool _isSimulator = false;
  String _errorMessage = '';
  String _transcribedText = '';
  String _interimText = '';
  double _soundLevel = 0.0;
  VoiceTripDetails? _parsedDetails;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
          _transcribedText = text;
          _interimText = '';
          _parsedDetails = VoiceTripParser.parse(text);
        } else {
          _interimText = text;
        }
      });
    };

    _voiceService.onSoundLevelChange = (level) {
      setState(() => _soundLevel = level);
    };

    _voiceService.onError = (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _isListening = false;
      });
    };

    _voiceService.onListeningStarted = () {
      setState(() {
        _isListening = true;
        _hasError = false;
        _transcribedText = '';
        _interimText = '';
        _parsedDetails = null;
      });
      HapticFeedback.mediumImpact();
    };

    _voiceService.onListeningStopped = () {
      setState(() => _isListening = false);
    };

    final initialized = await _voiceService.initialize();

    setState(() {
      _isInitialized = initialized;
      _isSimulator = _voiceService.isRunningOnSimulator;
    });

    debugPrint('🎤 Voice Trip Page: initialized=$initialized, isSimulator=$_isSimulator');

    // On simulator, show demo mode message instead of error
    if (!initialized && _isSimulator && mounted) {
      // ONLY enable demo mode for actual simulators/emulators
      debugPrint('🎤 Enabling demo mode for simulator/emulator');
      setState(() {
        _hasError = false; // Not an error, just demo mode
        _isInitialized = true; // Allow interaction for demo
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

  Future<void> _toggleListening() async {
    HapticFeedback.lightImpact();

    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      setState(() {
        _hasError = false;
        _transcribedText = '';
        _parsedDetails = null;
      });

      // Use demo mode on simulator
      if (_isSimulator) {
        await _voiceService.runDemoMode();
      } else {
        await _voiceService.startListening();
      }
    }
  }

  /// Random trip ideas for "Surprise Me" feature
  /// Covers all regions of India: North, South, East, West, Northeast, Central + Islands
  /// 100+ diverse destinations across the country
  static const List<Map<String, dynamic>> _randomTripIdeas = [
    // === NORTH INDIA ===
    // Himachal Pradesh
    {'destination': 'Manali', 'duration': 5, 'type': 'Mountain adventure'},
    {'destination': 'Shimla', 'duration': 4, 'type': 'Colonial hill station'},
    {'destination': 'Dharamshala', 'duration': 4, 'type': 'Tibetan culture & peace'},
    {'destination': 'Kasol', 'duration': 3, 'type': 'Backpacker paradise'},
    {'destination': 'Spiti Valley', 'duration': 6, 'type': 'Cold desert adventure'},
    {'destination': 'Bir Billing', 'duration': 3, 'type': 'Paragliding capital'},
    {'destination': 'Dalhousie', 'duration': 3, 'type': 'Quiet hill retreat'},
    {'destination': 'Kullu', 'duration': 4, 'type': 'Valley of Gods'},
    {'destination': 'Kinnaur', 'duration': 5, 'type': 'Apple orchards & temples'},
    // Uttarakhand
    {'destination': 'Rishikesh', 'duration': 4, 'type': 'Adventure & yoga'},
    {'destination': 'Haridwar', 'duration': 2, 'type': 'Spiritual gateway'},
    {'destination': 'Nainital', 'duration': 3, 'type': 'Lake district charm'},
    {'destination': 'Mussoorie', 'duration': 3, 'type': 'Queen of hills'},
    {'destination': 'Auli', 'duration': 4, 'type': 'Skiing paradise'},
    {'destination': 'Chopta', 'duration': 3, 'type': 'Mini Switzerland trek'},
    {'destination': 'Valley of Flowers', 'duration': 5, 'type': 'UNESCO floral trek'},
    {'destination': 'Jim Corbett', 'duration': 3, 'type': 'Tiger safari'},
    // Jammu & Kashmir / Ladakh
    {'destination': 'Srinagar', 'duration': 4, 'type': 'Dal Lake houseboat'},
    {'destination': 'Gulmarg', 'duration': 3, 'type': 'Meadow of flowers'},
    {'destination': 'Pahalgam', 'duration': 3, 'type': 'Valley of shepherds'},
    {'destination': 'Ladakh', 'duration': 7, 'type': 'Ultimate road trip'},
    {'destination': 'Leh', 'duration': 5, 'type': 'High altitude adventure'},
    {'destination': 'Nubra Valley', 'duration': 4, 'type': 'Double hump camels'},
    {'destination': 'Pangong Lake', 'duration': 3, 'type': 'Blue waters wonder'},
    // Rajasthan
    {'destination': 'Jaipur', 'duration': 3, 'type': 'Pink city heritage'},
    {'destination': 'Udaipur', 'duration': 3, 'type': 'City of lakes'},
    {'destination': 'Jodhpur', 'duration': 3, 'type': 'Blue city magic'},
    {'destination': 'Jaisalmer', 'duration': 4, 'type': 'Golden desert city'},
    {'destination': 'Pushkar', 'duration': 2, 'type': 'Holy lake & camels'},
    {'destination': 'Mount Abu', 'duration': 3, 'type': 'Rajasthan\'s only hill station'},
    {'destination': 'Bikaner', 'duration': 2, 'type': 'Camel country'},
    {'destination': 'Ranthambore', 'duration': 3, 'type': 'Tiger territory'},
    // Punjab & Haryana
    {'destination': 'Amritsar', 'duration': 2, 'type': 'Golden Temple & food'},
    // Delhi & UP
    {'destination': 'Agra', 'duration': 2, 'type': 'Taj Mahal wonder'},
    {'destination': 'Varanasi', 'duration': 3, 'type': 'Spiritual awakening'},
    {'destination': 'Lucknow', 'duration': 3, 'type': 'Nawabi heritage & food'},
    {'destination': 'Allahabad', 'duration': 2, 'type': 'Sangam pilgrimage'},

    // === SOUTH INDIA ===
    // Kerala
    {'destination': 'Munnar', 'duration': 4, 'type': 'Tea gardens paradise'},
    {'destination': 'Alleppey', 'duration': 3, 'type': 'Backwater houseboat'},
    {'destination': 'Kumarakom', 'duration': 3, 'type': 'Luxury backwaters'},
    {'destination': 'Thekkady', 'duration': 3, 'type': 'Periyar wildlife'},
    {'destination': 'Wayanad', 'duration': 3, 'type': 'Misty hill forests'},
    {'destination': 'Kochi', 'duration': 2, 'type': 'Queen of Arabian Sea'},
    {'destination': 'Kovalam', 'duration': 3, 'type': 'Beach & ayurveda'},
    {'destination': 'Varkala', 'duration': 3, 'type': 'Cliff beach vibes'},
    // Tamil Nadu
    {'destination': 'Ooty', 'duration': 3, 'type': 'Nilgiri toy train'},
    {'destination': 'Kodaikanal', 'duration': 3, 'type': 'Princess of hills'},
    {'destination': 'Mahabalipuram', 'duration': 2, 'type': 'Shore temple heritage'},
    {'destination': 'Pondicherry', 'duration': 3, 'type': 'French colony charm'},
    {'destination': 'Madurai', 'duration': 2, 'type': 'Temple city'},
    {'destination': 'Rameswaram', 'duration': 2, 'type': 'Island pilgrimage'},
    {'destination': 'Kanyakumari', 'duration': 2, 'type': 'Land\'s end sunrise'},
    {'destination': 'Chettinad', 'duration': 2, 'type': 'Heritage mansions & cuisine'},
    // Karnataka
    {'destination': 'Coorg', 'duration': 3, 'type': 'Coffee plantation bliss'},
    {'destination': 'Hampi', 'duration': 3, 'type': 'Boulder wonderland'},
    {'destination': 'Mysore', 'duration': 3, 'type': 'Palace city'},
    {'destination': 'Gokarna', 'duration': 3, 'type': 'Beach & temples'},
    {'destination': 'Chikmagalur', 'duration': 3, 'type': 'Coffee hills retreat'},
    {'destination': 'Badami', 'duration': 2, 'type': 'Cave temple heritage'},
    {'destination': 'Kabini', 'duration': 3, 'type': 'Luxury wildlife'},
    // Andhra Pradesh & Telangana
    {'destination': 'Hyderabad', 'duration': 3, 'type': 'Biryani & heritage'},
    {'destination': 'Tirupati', 'duration': 2, 'type': 'Divine darshan'},
    {'destination': 'Araku Valley', 'duration': 3, 'type': 'Eastern Ghats beauty'},
    {'destination': 'Vizag', 'duration': 3, 'type': 'City of destiny'},

    // === WEST INDIA ===
    // Goa
    {'destination': 'North Goa', 'duration': 4, 'type': 'Beach party vibes'},
    {'destination': 'South Goa', 'duration': 4, 'type': 'Serene beach escape'},
    // Maharashtra
    {'destination': 'Mumbai', 'duration': 3, 'type': 'Maximum city experience'},
    {'destination': 'Lonavala', 'duration': 2, 'type': 'Monsoon getaway'},
    {'destination': 'Mahabaleshwar', 'duration': 3, 'type': 'Strawberry hills'},
    {'destination': 'Ajanta Ellora', 'duration': 2, 'type': 'Cave art wonder'},
    {'destination': 'Kolhapur', 'duration': 2, 'type': 'Temple & misal pav'},
    {'destination': 'Alibaug', 'duration': 2, 'type': 'Beach weekend'},
    {'destination': 'Panchgani', 'duration': 2, 'type': 'Table land views'},
    {'destination': 'Nashik', 'duration': 2, 'type': 'Wine capital'},
    {'destination': 'Tarkarli', 'duration': 3, 'type': 'Scuba & beaches'},
    // Gujarat
    {'destination': 'Rann of Kutch', 'duration': 4, 'type': 'White desert wonder'},
    {'destination': 'Gir Forest', 'duration': 3, 'type': 'Asiatic lion safari'},
    {'destination': 'Dwarka', 'duration': 2, 'type': 'Krishna\'s kingdom'},
    {'destination': 'Somnath', 'duration': 2, 'type': 'Jyotirlinga pilgrimage'},
    {'destination': 'Ahmedabad', 'duration': 2, 'type': 'Heritage city walk'},
    {'destination': 'Statue of Unity', 'duration': 2, 'type': 'World\'s tallest statue'},
    {'destination': 'Saputara', 'duration': 2, 'type': 'Gujarat\'s hill station'},
    {'destination': 'Diu', 'duration': 3, 'type': 'Beach & Portuguese heritage'},

    // === EAST INDIA ===
    // West Bengal
    {'destination': 'Kolkata', 'duration': 3, 'type': 'City of joy'},
    {'destination': 'Darjeeling', 'duration': 4, 'type': 'Tea & toy train'},
    {'destination': 'Kalimpong', 'duration': 3, 'type': 'Orchid paradise'},
    {'destination': 'Sundarbans', 'duration': 3, 'type': 'Mangrove tiger safari'},
    {'destination': 'Shantiniketan', 'duration': 2, 'type': 'Tagore\'s abode'},
    {'destination': 'Digha', 'duration': 2, 'type': 'Beach weekend'},
    // Odisha
    {'destination': 'Puri', 'duration': 3, 'type': 'Jagannath & beach'},
    {'destination': 'Konark', 'duration': 2, 'type': 'Sun temple marvel'},
    {'destination': 'Bhubaneswar', 'duration': 2, 'type': 'Temple city'},
    {'destination': 'Chilika Lake', 'duration': 2, 'type': 'Bird watching paradise'},
    // Bihar & Jharkhand
    {'destination': 'Bodh Gaya', 'duration': 2, 'type': 'Buddha\'s enlightenment'},
    {'destination': 'Rajgir', 'duration': 2, 'type': 'Ancient Buddhist site'},
    {'destination': 'Deoghar', 'duration': 2, 'type': 'Baidyanath pilgrimage'},
    {'destination': 'Netarhat', 'duration': 3, 'type': 'Queen of Chotanagpur'},

    // === NORTHEAST INDIA ===
    {'destination': 'Shillong', 'duration': 4, 'type': 'Scotland of the East'},
    {'destination': 'Cherrapunji', 'duration': 3, 'type': 'Living root bridges'},
    {'destination': 'Kaziranga', 'duration': 3, 'type': 'One-horned rhino safari'},
    {'destination': 'Majuli', 'duration': 3, 'type': 'World\'s largest river island'},
    {'destination': 'Tawang', 'duration': 5, 'type': 'Monastery & mountains'},
    {'destination': 'Ziro Valley', 'duration': 4, 'type': 'Music festival & tribes'},
    {'destination': 'Gangtok', 'duration': 4, 'type': 'Sikkim capital charm'},
    {'destination': 'Pelling', 'duration': 3, 'type': 'Kanchenjunga views'},
    {'destination': 'Imphal', 'duration': 3, 'type': 'Loktak Lake floating'},
    {'destination': 'Kohima', 'duration': 3, 'type': 'WWII history & hornbill'},
    {'destination': 'Dimapur', 'duration': 2, 'type': 'Gateway to Nagaland'},
    {'destination': 'Agartala', 'duration': 2, 'type': 'Ujjayanta Palace'},
    {'destination': 'Dawki', 'duration': 2, 'type': 'Crystal clear river'},

    // === CENTRAL INDIA ===
    {'destination': 'Khajuraho', 'duration': 2, 'type': 'Temple sculptures'},
    {'destination': 'Orchha', 'duration': 2, 'type': 'Medieval town frozen'},
    {'destination': 'Pachmarhi', 'duration': 3, 'type': 'Queen of Satpura'},
    {'destination': 'Kanha', 'duration': 3, 'type': 'Jungle Book safari'},
    {'destination': 'Bandhavgarh', 'duration': 3, 'type': 'White tiger homeland'},
    {'destination': 'Bhopal', 'duration': 2, 'type': 'City of lakes'},
    {'destination': 'Sanchi', 'duration': 1, 'type': 'Buddhist stupa'},
    {'destination': 'Jabalpur', 'duration': 2, 'type': 'Marble rocks wonder'},

    // === ISLANDS ===
    {'destination': 'Andaman Islands', 'duration': 6, 'type': 'Tropical paradise'},
    {'destination': 'Havelock Island', 'duration': 4, 'type': 'Radhanagar beach'},
    {'destination': 'Neil Island', 'duration': 3, 'type': 'Natural bridge'},
    {'destination': 'Lakshadweep', 'duration': 5, 'type': 'Coral island escape'},
  ];

  /// Generate a random trip idea
  void _generateRandomTrip() {
    HapticFeedback.mediumImpact();

    final random = math.Random();
    final idea = _randomTripIdeas[random.nextInt(_randomTripIdeas.length)];

    // Create a simulated voice input phrase
    final phrases = [
      'Plan a trip to ${idea['destination']} for ${idea['duration']} days',
      '${idea['duration']} day ${idea['type'].toString().toLowerCase()} to ${idea['destination']}',
      'Let\'s go to ${idea['destination']} for a ${idea['type'].toString().toLowerCase()}',
      'Book a ${idea['duration']} day trip to ${idea['destination']}',
    ];
    final phrase = phrases[random.nextInt(phrases.length)];

    // Calculate dates
    final startDaysFromNow = random.nextInt(30) + 7; // 7-37 days from now
    final startDate = DateTime.now().add(Duration(days: startDaysFromNow));
    final endDate = startDate.add(Duration(days: (idea['duration'] as int) - 1));

    setState(() {
      _hasError = false;
      _transcribedText = phrase;
      _parsedDetails = VoiceTripDetails(
        destination: idea['destination'] as String,
        startDate: startDate,
        endDate: endDate,
        numberOfDays: idea['duration'] as int,
        tripType: idea['type'] as String?,
        companions: const [],
        rawText: phrase,
      );
    });

    // Show a subtle animation by triggering the pulse
    _scaleController.reset();
    _scaleController.forward();
  }

  Future<void> _createTrip() async {
    if (_parsedDetails == null || !_parsedDetails!.hasDestination) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please say a destination for your trip'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final controller = ref.read(tripControllerProvider.notifier);
      final details = _parsedDetails!;

      // Generate trip name
      final tripName = 'Trip to ${details.destination}';

      // Calculate dates
      DateTime? startDate = details.startDate;
      DateTime? endDate;

      if (startDate != null && details.numberOfDays != null) {
        endDate = startDate.add(Duration(days: details.numberOfDays! - 1));
      } else if (startDate == null && details.numberOfDays != null) {
        // If no start date but has duration, start tomorrow
        startDate = DateTime.now().add(const Duration(days: 1));
        endDate = startDate.add(Duration(days: details.numberOfDays! - 1));
      }

      final trip = await controller.createTrip(
        name: tripName,
        destination: details.destination!,
        startDate: startDate,
        endDate: endDate,
        isPublic: false,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('$tripName created!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/trips/${trip.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
              // App bar
              _buildAppBar(themeData),

              // Main content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: size.height - 150, // Account for app bar and safe area
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(height: 16),

                            // Voice animation orb
                            _buildVoiceOrb(themeData, size),

                            const SizedBox(height: 24),

                            // Status text
                            _buildStatusText(themeData),

                            const SizedBox(height: 16),

                            // Transcribed text area
                            if (_transcribedText.isNotEmpty || _interimText.isNotEmpty)
                              _buildTranscriptionArea(themeData),

                            // Parsed details
                            if (_parsedDetails != null && _parsedDetails!.hasDestination)
                              _buildParsedDetails(themeData),

                            const SizedBox(height: 16),

                            // Hint text
                            if (!_isListening && _transcribedText.isEmpty)
                              _buildHintText(),

                            // Action buttons
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
              color: themeData.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeData.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: themeData.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Voice Trip',
                  style: TextStyle(
                    color: themeData.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildVoiceOrb(AppThemeData themeData, Size size) {
    final sphereSize = size.width * 0.7;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _isInitialized ? _toggleListening : null,
        child: SizedBox(
          width: sphereSize,
          height: sphereSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // AI Sphere Animation - Sci-Fi mesh sphere
              AISphereAnimation(
                size: sphereSize,
                isActive: _isListening,
                soundLevel: _soundLevel,
                primaryColor: const Color(0xFF00D9FF), // Cyan
                glowColor: const Color(0xFF00D9FF),
              ),
              // Microphone icon overlay when not listening
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
              // When listening, just show the ring animation without any center overlay
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(AppThemeData themeData) {
    String statusText;
    Color statusColor;
    IconData? statusIcon;
    bool isSimulatorError = _errorMessage.contains('simulator') ||
                            _errorMessage.contains('physical device');

    if (_hasError) {
      statusText = _errorMessage;
      statusColor = isSimulatorError ? Colors.orangeAccent : Colors.redAccent;
      statusIcon = isSimulatorError ? Icons.phone_iphone : Icons.error_outline;
    } else if (_isProcessing) {
      statusText = 'Creating your trip...';
      statusColor = Colors.amber;
      statusIcon = Icons.auto_awesome;
    } else if (_isListening) {
      statusText = 'Listening...';
      statusColor = themeData.primaryColor;
      statusIcon = Icons.hearing;
    } else if (_parsedDetails != null && _parsedDetails!.hasDestination) {
      statusText = 'Trip details ready';
      statusColor = Colors.greenAccent;
      statusIcon = Icons.check_circle;
    } else if (_transcribedText.isNotEmpty) {
      statusText = 'Processing...';
      statusColor = Colors.amber;
      statusIcon = Icons.psychology;
    } else if (!_isInitialized) {
      statusText = 'Initializing...';
      statusColor = Colors.white54;
    } else if (_isSimulator) {
      statusText = 'Demo Mode - Tap to simulate voice input';
      statusColor = Colors.cyanAccent;
      statusIcon = Icons.play_circle_outline;
    } else {
      statusText = 'Tap to start speaking';
      statusColor = Colors.white70;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(statusText),
        padding: _hasError
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : EdgeInsets.zero,
        margin: _hasError
            ? const EdgeInsets.symmetric(horizontal: 24)
            : EdgeInsets.zero,
        decoration: _hasError
            ? BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (statusIcon != null) ...[
              Icon(
                statusIcon,
                color: statusColor,
                size: _hasError ? 22 : 20,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: _hasError ? 14 : 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
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
                'You said:',
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
              fontStyle: _transcribedText.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParsedDetails(AppThemeData themeData) {
    final details = _parsedDetails!;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeData.primaryColor.withValues(alpha: 0.2),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeData.primaryColor.withValues(alpha: 0.3),
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
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Trip Details Extracted',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Destination
          _buildDetailRow(
            Icons.location_on,
            'Destination',
            details.destination ?? 'Not specified',
            themeData.primaryColor,
          ),

          if (details.numberOfDays != null || details.duration != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.schedule,
              'Duration',
              details.duration ?? '${details.numberOfDays} days',
              Colors.amber,
            ),
          ],

          if (details.startDate != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'Start Date',
              _formatDate(details.startDate!),
              Colors.cyanAccent,
            ),
          ],

          if (details.companions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.people,
              'With',
              details.companions.join(', '),
              Colors.pinkAccent,
            ),
          ],

          if (details.tripType != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.category,
              'Type',
              details.tripType!.substring(0, 1).toUpperCase() +
                  details.tripType!.substring(1),
              Colors.orangeAccent,
            ),
          ],
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
            'Try saying:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildHintItem('"Plan a trip to Goa for this weekend"'),
          const SizedBox(height: 8),
          _buildHintItem('"Family vacation to Kerala for 5 days"'),
          const SizedBox(height: 8),
          _buildHintItem('"Solo trip to Manali next month"'),
          const SizedBox(height: 16),
          // Surprise Me button
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shuffle_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Surprise Me!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.auto_awesome,
              color: Colors.amber.withValues(alpha: 0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: Colors.amber.withValues(alpha: 0.7),
          size: 16,
        ),
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
      ],
    );
  }

  Widget _buildActionButtons(AppThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Retry button (if has text)
          if (_transcribedText.isNotEmpty) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _toggleListening,
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

          // Main action button
          Expanded(
            flex: _transcribedText.isNotEmpty ? 2 : 1,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : (_parsedDetails != null && _parsedDetails!.hasDestination
                      ? _createTrip
                      : (_isListening ? _toggleListening : null)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _parsedDetails != null && _parsedDetails!.hasDestination
                    ? Colors.greenAccent
                    : themeData.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: (_parsedDetails != null && _parsedDetails!.hasDestination
                        ? Colors.greenAccent
                        : themeData.primaryColor)
                    .withValues(alpha: 0.5),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _parsedDetails != null && _parsedDetails!.hasDestination
                              ? Icons.rocket_launch
                              : (_isListening ? Icons.stop : Icons.mic),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _parsedDetails != null && _parsedDetails!.hasDestination
                              ? 'Create Trip'
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
