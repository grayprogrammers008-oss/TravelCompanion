import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/voice_input_service.dart';
import 'ai_sphere_animation.dart';

/// Callback for when voice input is completed
typedef VoiceInputCallback = void Function(String text);

/// Reusable voice input bottom sheet with animation
class VoiceInputBottomSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String exampleText;
  final IconData icon;
  final Color? primaryColor;
  final VoiceInputCallback onComplete;
  final String? demoPhrase;

  const VoiceInputBottomSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.exampleText,
    required this.icon,
    this.primaryColor,
    required this.onComplete,
    this.demoPhrase,
  });

  @override
  State<VoiceInputBottomSheet> createState() => _VoiceInputBottomSheetState();

  /// Show the voice input bottom sheet
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String hintText,
    required String exampleText,
    required IconData icon,
    Color? primaryColor,
    String? demoPhrase,
  }) async {
    String? result;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceInputBottomSheet(
        title: title,
        hintText: hintText,
        exampleText: exampleText,
        icon: icon,
        primaryColor: primaryColor,
        demoPhrase: demoPhrase,
        onComplete: (text) {
          result = text;
          Navigator.of(context).pop();
        },
      ),
    );
    return result;
  }
}

class _VoiceInputBottomSheetState extends State<VoiceInputBottomSheet>
    with TickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSimulator = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _transcribedText = '';
  String _interimText = '';
  double _soundLevel = 0.0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initVoiceService();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  Future<void> _initVoiceService() async {
    _voiceService.onResult = _onSpeechResult;
    _voiceService.onSoundLevelChange = _onSoundLevelChange;
    _voiceService.onError = _onSpeechError;
    _voiceService.onListeningStarted = _onListeningStarted;
    _voiceService.onListeningStopped = _onListeningStopped;

    final initialized = await _voiceService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = initialized;
        _isSimulator = _voiceService.isRunningOnSimulator;
      });
    }
  }

  void _onSpeechResult(String text, bool isFinal) {
    if (mounted) {
      setState(() {
        if (isFinal) {
          _transcribedText = text;
          _interimText = '';
        } else {
          _interimText = text;
        }
        _hasError = false;
      });
    }
  }

  void _onSoundLevelChange(double level) {
    if (mounted) {
      setState(() => _soundLevel = level);
    }
  }

  void _onSpeechError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _isListening = false;
      });
    }
  }

  void _onListeningStarted() {
    if (mounted) {
      setState(() {
        _isListening = true;
        _hasError = false;
      });
    }
  }

  void _onListeningStopped() {
    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    }
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();

    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      setState(() {
        _transcribedText = '';
        _interimText = '';
        _hasError = false;
      });

      if (_isSimulator && widget.demoPhrase != null) {
        await _runDemoMode();
      } else {
        await _voiceService.startListening();
      }
    }
  }

  Future<void> _runDemoMode() async {
    setState(() {
      _isListening = true;
      _transcribedText = '';
    });

    final words = widget.demoPhrase!.split(' ');

    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      setState(() {
        _soundLevel = 0.3 + (i % 3) * 0.2;
        _interimText = words.sublist(0, i + 1).join(' ');
      });

      await Future.delayed(const Duration(milliseconds: 100));
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _soundLevel = 0.0;
        _transcribedText = widget.demoPhrase!;
        _interimText = '';
        _isListening = false;
      });
    }
  }

  void _confirmInput() {
    final text = _transcribedText.isNotEmpty ? _transcribedText : _interimText;
    if (text.isNotEmpty) {
      HapticFeedback.mediumImpact();
      widget.onComplete(text);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    final displayText = _interimText.isNotEmpty ? _interimText : _transcribedText;
    final hasText = displayText.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.hintText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Voice orb
          GestureDetector(
            onTap: _isInitialized || _isSimulator ? _toggleListening : null,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AISphereAnimation(
                    size: 160,
                    isActive: _isListening,
                    soundLevel: _soundLevel,
                    primaryColor: primaryColor,
                    glowColor: primaryColor,
                  ),
                  if (!_isListening)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.mic,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status text
          if (_hasError)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (_isListening)
            Text(
              'Listening...',
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_isSimulator)
            Text(
              'Demo Mode - Tap to simulate',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            )
          else
            Text(
              'Tap to speak',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 20),

          // Transcribed text area
          if (hasText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                'Example: "${widget.exampleText}"',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: hasText ? _confirmInput : null,
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Add Items'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
