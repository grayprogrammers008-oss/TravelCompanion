// AI Itinerary Generator Page
//
// Allows users to generate AI-powered trip itineraries.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../templates/presentation/providers/template_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../domain/entities/ai_itinerary.dart';
import '../providers/ai_itinerary_providers.dart';
import '../widgets/ai_itinerary_result.dart';

class AiItineraryGeneratorPage extends ConsumerStatefulWidget {
  final String? tripId; // Optional: Apply to existing trip

  // Pre-fill parameters from trip data
  final String? prefillDestination;
  final DateTime? prefillStartDate;
  final DateTime? prefillEndDate;
  final double? prefillBudget;

  // Voice prompt from voice input - adds context to AI generation
  final String? voicePrompt;

  const AiItineraryGeneratorPage({
    super.key,
    this.tripId,
    this.prefillDestination,
    this.prefillStartDate,
    this.prefillEndDate,
    this.prefillBudget,
    this.voicePrompt,
  });

  @override
  ConsumerState<AiItineraryGeneratorPage> createState() =>
      _AiItineraryGeneratorPageState();
}

class _AiItineraryGeneratorPageState
    extends ConsumerState<AiItineraryGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();

  // Date-based duration
  DateTime? _startDate;
  DateTime? _endDate;
  int get _durationDays {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays + 1;
    }
    return 3; // Default
  }

  String _travelStyle = 'Moderate';
  int _groupSize = 2;
  final Set<String> _selectedInterests = {};

  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    // Apply pre-fill data from trip
    _applyPrefillData();
  }

  /// Apply pre-fill data from trip when launched from itinerary page
  void _applyPrefillData() {
    if (widget.prefillDestination != null) {
      _destinationController.text = widget.prefillDestination!;
      if (kDebugMode) {
        debugPrint('DEBUG: Pre-filled destination: ${widget.prefillDestination}');
      }
    }
    if (widget.prefillStartDate != null) {
      _startDate = widget.prefillStartDate;
      if (kDebugMode) {
        debugPrint('DEBUG: Pre-filled start date: ${widget.prefillStartDate}');
      }
    }
    if (widget.prefillEndDate != null) {
      _endDate = widget.prefillEndDate;
      if (kDebugMode) {
        debugPrint('DEBUG: Pre-filled end date: ${widget.prefillEndDate}');
      }
    }
    if (widget.prefillBudget != null) {
      _budgetController.text = widget.prefillBudget!.toStringAsFixed(0);
      if (kDebugMode) {
        debugPrint('DEBUG: Pre-filled budget: ${widget.prefillBudget}');
      }
    }
    if (widget.voicePrompt != null && kDebugMode) {
      debugPrint('DEBUG: Voice prompt received: ${widget.voicePrompt}');
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select start date',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, reset it
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 2)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 30)), // Max 30 days trip
      helpText: 'Select end date',
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _generateItinerary() async {
    debugPrint('🚀 Generate Itinerary button pressed');

    // Dismiss keyboard first for cleaner UX
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    // Validate dates
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select trip dates')),
      );
      return;
    }

    debugPrint('✅ Form validated');
    debugPrint('📍 Destination: ${_destinationController.text.trim()}');
    debugPrint('📅 Dates: $_startDate to $_endDate ($_durationDays days)');
    debugPrint('💰 Budget: ${_budgetController.text}');
    debugPrint('🎯 Interests: $_selectedInterests');
    if (widget.voicePrompt != null) {
      debugPrint('🎤 Voice prompt: ${widget.voicePrompt}');
    }

    // Fetch trip data if tripId is provided to get comprehensive context
    List<TripCompanion>? companions;
    if (widget.tripId != null) {
      debugPrint('🔍 Fetching trip data for tripId: ${widget.tripId}');
      try {
        final tripData = await ref.read(tripProvider(widget.tripId!).future);
        final members = tripData.members;

        // Convert trip members to companions
        if (members.isNotEmpty) {
          companions = members.map((member) {
            return TripCompanion(
              name: member.fullName ?? 'Traveler',
              relation: null, // We don't store relation in trip_members yet
              age: null, // We don't store age in trip_members yet
            );
          }).toList();
          debugPrint('👥 Found ${companions!.length} trip members as companions');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch trip data: $e');
        // Continue without companions - not critical
      }
    }

    final request = AiItineraryRequest(
      destination: _destinationController.text.trim(),
      durationDays: _durationDays,
      budget: _budgetController.text.isNotEmpty
          ? double.tryParse(_budgetController.text)
          : null,
      interests: _selectedInterests.toList(),
      travelStyle: _travelStyle.toLowerCase(),
      groupSize: _groupSize,
      voicePrompt: widget.voicePrompt,
      companions: companions,
      startDate: _startDate,
      endDate: _endDate,
      // TODO: Add UI to collect transport mode and daily timing preferences
      // For now, these will be null and AI will use sensible defaults
    );

    debugPrint('📤 Calling generateItinerary...');
    final itinerary = await ref.read(aiItineraryControllerProvider.notifier).generateItinerary(request);
    debugPrint('📥 generateItinerary completed');

    // Store dates for later use when creating trip
    if (itinerary != null) {
      _storedStartDate = _startDate;
      _storedEndDate = _endDate;
    }
  }

  // Store dates for passing to trip creation
  DateTime? _storedStartDate;
  DateTime? _storedEndDate;

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final aiState = ref.watch(aiItineraryControllerProvider);
    final canGenerateAsync = ref.watch(canGenerateAiProvider);
    final remainingAsync = ref.watch(remainingGenerationsProvider);

    // If we have a generated itinerary, show the result
    if (aiState.itinerary != null) {
      return AiItineraryResultPage(
        itinerary: aiState.itinerary!,
        tripId: widget.tripId,
        startDate: _storedStartDate,
        endDate: _storedEndDate,
        budget: _budgetController.text.isNotEmpty
            ? double.tryParse(_budgetController.text)
            : null,
        onBack: () {
          ref.read(aiItineraryControllerProvider.notifier).clearItinerary();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: themeData.primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacing3xl,
                        AppTheme.spacingLg,
                        AppTheme.spacingLg,
                        AppTheme.spacingMd,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingSm),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Trip Planner',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      'Let AI create your perfect itinerary',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Usage Banner
            SliverToBoxAdapter(
              child: canGenerateAsync.when(
                data: (canGenerate) {
                  return remainingAsync.when(
                    data: (remaining) {
                      if (remaining == -1) {
                        // Premium user
                        return Container(
                          margin: const EdgeInsets.all(AppTheme.spacingMd),
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium, color: Colors.green),
                              const SizedBox(width: AppTheme.spacingSm),
                              Text(
                                'Premium: Unlimited AI generations',
                                style: context.bodyStyle.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final color = canGenerate ? Colors.blue : Colors.orange;
                      return Container(
                        margin: const EdgeInsets.all(AppTheme.spacingMd),
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              canGenerate ? Icons.auto_awesome : Icons.warning_amber,
                              color: color,
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    canGenerate
                                        ? '$remaining free generations remaining'
                                        : 'Free limit reached',
                                    style: context.bodyStyle.copyWith(
                                      color: color.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!canGenerate)
                                    Text(
                                      'Upgrade to Premium for unlimited generations',
                                      style: context.bodyStyle.copyWith(
                                        fontSize: 12,
                                        color: color.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!canGenerate)
                              TextButton(
                                onPressed: () {
                                  // TODO: Navigate to premium page
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Premium coming soon!'),
                                    ),
                                  );
                                },
                                child: const Text('Upgrade'),
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Voice Prompt Banner (if provided)
            if (widget.voicePrompt != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    0,
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00D9FF).withValues(alpha: 0.15),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Color(0xFF00D9FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Request',
                              style: context.bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00D9FF),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${widget.voicePrompt}"',
                              style: context.bodyStyle.copyWith(
                                fontStyle: FontStyle.italic,
                                color: context.textColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Form
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Destination
                      Text(
                        'Where do you want to go?',
                        style: context.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      TextFormField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Goa, Jaipur, Kerala',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a destination';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Trip Dates
                      Text(
                        'Trip Dates',
                        style: context.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectStartDate(context),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacingMd),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: _startDate != null
                                          ? themeData.primaryColor
                                          : AppTheme.neutral400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start',
                                            style: context.bodyStyle.copyWith(
                                              fontSize: 11,
                                              color: AppTheme.neutral500,
                                            ),
                                          ),
                                          Text(
                                            _startDate != null
                                                ? _dateFormat.format(_startDate!)
                                                : 'Select date',
                                            style: context.bodyStyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _startDate != null
                                                  ? null
                                                  : AppTheme.neutral400,
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
                          const SizedBox(width: AppTheme.spacingSm),
                          // End Date
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectEndDate(context),
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spacingMd),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      color: _endDate != null
                                          ? themeData.primaryColor
                                          : AppTheme.neutral400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppTheme.spacingSm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'End',
                                            style: context.bodyStyle.copyWith(
                                              fontSize: 11,
                                              color: AppTheme.neutral500,
                                            ),
                                          ),
                                          Text(
                                            _endDate != null
                                                ? _dateFormat.format(_endDate!)
                                                : 'Select date',
                                            style: context.bodyStyle.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: _endDate != null
                                                  ? null
                                                  : AppTheme.neutral400,
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
                        ],
                      ),
                      // Duration indicator
                      if (_startDate != null && _endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMd,
                              vertical: AppTheme.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: themeData.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              '$_durationDays ${_durationDays == 1 ? 'day' : 'days'}',
                              style: context.bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeData.primaryColor,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Budget
                      Text(
                        'Budget (Optional)',
                        style: context.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g., 30000',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Travel Style
                      Text(
                        'Travel Style',
                        style: context.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Wrap(
                        spacing: AppTheme.spacingSm,
                        children: travelStyles.map((style) {
                          final isSelected = _travelStyle == style;
                          return ChoiceChip(
                            label: Text(style),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _travelStyle = style);
                              }
                            },
                            selectedColor: themeData.primaryColor.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? themeData.primaryColor : null,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Group Size
                      Text(
                        'Group Size',
                        style: context.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline),
                            const SizedBox(width: AppTheme.spacingMd),
                            IconButton(
                              onPressed: _groupSize > 1
                                  ? () => setState(() => _groupSize--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.neutral100,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(
                                '$_groupSize',
                                style: context.titleStyle.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _groupSize < 20
                                  ? () => setState(() => _groupSize++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text(
                              _groupSize == 1 ? 'Solo' : '$_groupSize people',
                              style: context.bodyStyle.copyWith(
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingLg),

                      // Interests
                      Text(
                        'What interests you?',
                        style: context.titleStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Wrap(
                        spacing: AppTheme.spacingSm,
                        runSpacing: AppTheme.spacingSm,
                        children: availableInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                            selectedColor: themeData.primaryColor.withValues(alpha: 0.2),
                            checkmarkColor: themeData.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? themeData.primaryColor : null,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppTheme.spacing2xl),

                      // Error Message
                      if (aiState.error != null)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.error),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  aiState.error!,
                                  style: context.bodyStyle.copyWith(
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: aiState.isLoading ? null : _generateItinerary,
                          icon: aiState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            aiState.isLoading
                                ? 'Generating your itinerary...'
                                : 'Generate Itinerary',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeData.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingMd),

                      // Disclaimer
                      Text(
                        'AI-generated itineraries are suggestions. Please verify timings, prices, and availability before your trip.',
                        style: context.bodyStyle.copyWith(
                          fontSize: 12,
                          color: context.textColor.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacing2xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
