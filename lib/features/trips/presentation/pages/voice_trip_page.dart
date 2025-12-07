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
import '../../../../core/widgets/voice_wave_animation.dart';
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
    setState(() => _isInitialized = initialized);

    if (!initialized && mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Speech recognition not available on this device';
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
      await _voiceService.startListening();
    }
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
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

                        // Voice animation orb
                        _buildVoiceOrb(themeData, size),

                        const SizedBox(height: 32),

                        // Status text
                        _buildStatusText(themeData),

                        const Spacer(flex: 1),

                        // Transcribed text area
                        if (_transcribedText.isNotEmpty || _interimText.isNotEmpty)
                          _buildTranscriptionArea(themeData),

                        // Parsed details
                        if (_parsedDetails != null && _parsedDetails!.hasDestination)
                          _buildParsedDetails(themeData),

                        const Spacer(flex: 1),

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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _isInitialized ? _toggleListening : null,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeData.primaryColor.withValues(alpha: 0.3),
                      blurRadius: _isListening ? 60 : 30,
                      spreadRadius: _isListening ? 10 : 5,
                    ),
                  ],
                ),
                child: _isListening
                    ? VoiceWaveAnimation(
                        soundLevel: _soundLevel,
                        isListening: _isListening,
                        primaryColor: themeData.primaryColor,
                        secondaryColor: const Color(0xFF8B5CF6),
                        size: size.width * 0.6,
                      )
                    : _buildIdleOrb(themeData, size),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdleOrb(AppThemeData themeData, Size size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            themeData.primaryColor.withValues(alpha: 0.8),
            themeData.primaryColor.withValues(alpha: 0.4),
            themeData.primaryColor.withValues(alpha: 0.1),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Center(
        child: Container(
          width: size.width * 0.25,
          height: size.width * 0.25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.3),
                themeData.primaryColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: themeData.primaryColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.mic,
            size: 48,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(AppThemeData themeData) {
    String statusText;
    Color statusColor;

    if (_hasError) {
      statusText = _errorMessage;
      statusColor = Colors.redAccent;
    } else if (_isProcessing) {
      statusText = 'Creating your trip...';
      statusColor = Colors.amber;
    } else if (_isListening) {
      statusText = 'Listening...';
      statusColor = themeData.primaryColor;
    } else if (_parsedDetails != null && _parsedDetails!.hasDestination) {
      statusText = 'Trip details ready';
      statusColor = Colors.greenAccent;
    } else if (_transcribedText.isNotEmpty) {
      statusText = 'Processing...';
      statusColor = Colors.amber;
    } else if (!_isInitialized) {
      statusText = 'Initializing...';
      statusColor = Colors.white54;
    } else {
      statusText = 'Tap to start speaking';
      statusColor = Colors.white70;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        statusText,
        key: ValueKey(statusText),
        style: TextStyle(
          color: statusColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
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
        ],
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
