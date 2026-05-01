import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/google_place_search_delegate.dart';
import '../../../../core/services/google_places_service.dart';
import '../providers/trip_providers.dart';
import '../../../templates/presentation/providers/template_providers.dart';

class CreateTripPage extends ConsumerStatefulWidget {
  final String? tripId; // If provided, page is in edit mode

  // Pre-fill parameters from AI Itinerary Generator
  final String? prefillDestination;
  final DateTime? prefillStartDate;
  final DateTime? prefillEndDate;
  final double? prefillCost;

  // Template parameters
  final String? templateId;
  final int? templateDurationDays;

  const CreateTripPage({
    super.key,
    this.tripId,
    this.prefillDestination,
    this.prefillStartDate,
    this.prefillEndDate,
    this.prefillCost,
    this.templateId,
    this.templateDurationDays,
  });

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationController = TextEditingController();
  final _costController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _currency = 'INR'; // Default currency
  bool _isPublic = true; // Trip visibility: true = public, false = private
  bool _isLoading = false;

  // Cover image from Google Places
  String? _coverImageUrl;

  // Template-related state
  int? _templateDurationDays;
  bool _hasTemplateWarning = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    _animationController.forward();

    // Load trip data if editing
    if (widget.tripId != null) {
      // Use addPostFrameCallback to ensure the widget is fully built
      // before refreshing the provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kDebugMode) {
          debugPrint('DEBUG: ========== EDIT PAGE OPENED ==========');
          debugPrint('DEBUG: Trip ID: ${widget.tripId}');
        }
        _loadTripData();
      });
    } else {
      // Pre-fill form fields from AI Itinerary Generator (for new trips)
      _applyPrefillData();
    }
  }

  /// Apply pre-fill data from AI Itinerary Generator or Template
  void _applyPrefillData() {
    if (kDebugMode) {
      debugPrint('DEBUG: ========== PREFILL DATA ==========');
      debugPrint('DEBUG: templateId: ${widget.templateId}');
      debugPrint('DEBUG: templateDurationDays: ${widget.templateDurationDays}');
      debugPrint('DEBUG: prefillDestination: ${widget.prefillDestination}');
      debugPrint('DEBUG: prefillCost: ${widget.prefillCost}');
    }

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
    if (widget.prefillCost != null) {
      _costController.text = _formatCurrency(widget.prefillCost!);
      if (kDebugMode) {
        debugPrint('DEBUG: Pre-filled cost: ${widget.prefillCost}');
      }
    }

    // Template-specific: Store duration for auto-calculating end date
    if (widget.templateDurationDays != null) {
      _templateDurationDays = widget.templateDurationDays;
      if (kDebugMode) {
        debugPrint('DEBUG: Template duration: ${widget.templateDurationDays} days');
      }
    }
  }

  /// Format currency to show whole numbers without decimals (50000)
  /// or with 2 decimal places when needed (50000.50)
  String _formatCurrency(double amount) {
    if (amount == amount.truncateToDouble()) {
      // Whole number - no decimals
      return amount.toStringAsFixed(0);
    } else {
      // Has decimal part - show 2 decimal places
      return amount.toStringAsFixed(2);
    }
  }

  Future<void> _loadTripData() async {
    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        debugPrint('DEBUG: ========== LOADING TRIP DATA FOR EDIT ==========');
        debugPrint('DEBUG: Trip ID: ${widget.tripId}');
      }

      // Fetch trip data directly via repository for reliability.
      final repository = ref.read(tripRepositoryProvider);
      final trip = await repository.getTripById(widget.tripId!);

      if (kDebugMode) {
        debugPrint('DEBUG: Loaded Trip Name: ${trip.trip.name}');
        debugPrint('DEBUG: Loaded Trip Description: ${trip.trip.description ?? "NULL"}');
        debugPrint('DEBUG: Loaded Trip Destination: ${trip.trip.destination ?? "NULL"}');
        debugPrint('DEBUG: Loaded Trip Start Date: ${trip.trip.startDate}');
        debugPrint('DEBUG: Loaded Trip End Date: ${trip.trip.endDate}');
        debugPrint('DEBUG: Loaded Trip Cost: ${trip.trip.cost ?? "NULL"}');
        debugPrint('DEBUG: Loaded Trip Currency: ${trip.trip.currency}');
      }

      if (mounted) {
        setState(() {
          _nameController.text = trip.trip.name;
          _descriptionController.text = trip.trip.description ?? '';
          _destinationController.text = trip.trip.destination ?? '';
          // Format cost properly - show whole numbers without decimals
          _costController.text = trip.trip.cost != null
              ? _formatCurrency(trip.trip.cost!)
              : '';
          _currency = trip.trip.currency;
          _isPublic = trip.trip.isPublic;
          _startDate = trip.trip.startDate;
          _endDate = trip.trip.endDate;
          _isLoading = false;
        });

        if (kDebugMode) {
          debugPrint('DEBUG: Form fields populated successfully');
          debugPrint('DEBUG: Name: "${_nameController.text}"');
          debugPrint('DEBUG: Description: "${_descriptionController.text}"');
          debugPrint('DEBUG: Destination: "${_destinationController.text}"');
          debugPrint('DEBUG: Cost: "${_costController.text}"');
          debugPrint('DEBUG: Currency: "$_currency"');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('DEBUG: ========== ERROR LOADING TRIP ==========');
        debugPrint('DEBUG: Error: $e');
        debugPrint('DEBUG: Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _destinationController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final isEditMode = widget.tripId != null;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      // Allow past dates when editing existing trips
      firstDate: isEditMode
          ? DateTime(2020) // Allow dates from 2020 onwards for editing
          : DateTime.now(), // Only future dates for new trips
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;

        // Auto-calculate end date when template is active
        if (_templateDurationDays != null && _templateDurationDays! > 0) {
          _endDate = picked.add(Duration(days: _templateDurationDays! - 1));
          _hasTemplateWarning = false;

          if (kDebugMode) {
            debugPrint('DEBUG: Template auto-calculated end date: $_endDate ($_templateDurationDays days)');
          }
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final isEditMode = widget.tripId != null;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      // End date must be >= start date, or >= now for new trips
      firstDate: _startDate ??
          (isEditMode
              ? DateTime(2020) // Allow past dates when editing
              : DateTime.now()), // Only future dates for new trips
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;

        // Check if duration matches template and show warning if not
        if (_templateDurationDays != null && _startDate != null) {
          final selectedDuration = picked.difference(_startDate!).inDays + 1;
          _hasTemplateWarning = selectedDuration != _templateDurationDays;

          if (_hasTemplateWarning && kDebugMode) {
            debugPrint('DEBUG: Template warning - selected $selectedDuration days, template has $_templateDurationDays days');
          }
        }
      });
    }
  }

  Future<void> _searchDestination() async {
    debugPrint('🔍 [CreateTrip] Opening destination search...');

    final PlaceDetails? result = await showSearch<PlaceDetails?>(
      context: context,
      delegate: GooglePlaceSearchDelegate(),
    );

    debugPrint('🔍 [CreateTrip] Search returned: ${result != null ? result.name : "null"}');

    if (result != null && mounted) {
      debugPrint('🔍 [CreateTrip] Place: ${result.name}');
      debugPrint('🔍 [CreateTrip] Photos count: ${result.photos.length}');

      setState(() {
        _destinationController.text = result.shortName;
        // Get cover image from Google Places photos
        if (result.photos.isNotEmpty) {
          debugPrint('🔍 [CreateTrip] First photo reference: ${result.photos.first.photoReference.substring(0, 50)}...');
          _coverImageUrl = GooglePlacesService().getPhotoUrl(
            photoReference: result.photos.first.photoReference,
            maxWidth: 800,
          );
          debugPrint('📸 [CreateTrip] Cover image URL set: ${_coverImageUrl?.substring(0, 80)}...');
        } else {
          debugPrint('⚠️ [CreateTrip] No photos available for this place');
        }
      });
    }
  }

  Future<void> _handleCreateTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final isEditMode = widget.tripId != null;
      if (isEditMode) {
        // Update existing trip
        if (kDebugMode) {
          debugPrint('DEBUG: ========== EDIT MODE ==========');
          debugPrint('DEBUG: Trip ID: ${widget.tripId}');
          debugPrint('DEBUG: Name: "${_nameController.text.trim()}"');
          debugPrint('DEBUG: Description: "${_descriptionController.text.trim()}"');
          debugPrint('DEBUG: Description (null if empty): ${_descriptionController.text.trim().isEmpty ? 'NULL' : '"${_descriptionController.text.trim()}"'}');
          debugPrint('DEBUG: Destination: "${_destinationController.text.trim()}"');
          debugPrint('DEBUG: Destination (null if empty): ${_destinationController.text.trim().isEmpty ? 'NULL' : '"${_destinationController.text.trim()}"'}');
          debugPrint('DEBUG: Start Date: $_startDate');
          debugPrint('DEBUG: End Date: $_endDate');
          debugPrint('DEBUG: Cost: ${_costController.text.isEmpty ? 'NULL' : _costController.text}');
          debugPrint('DEBUG: Currency: $_currency');
        }

        final cost = _costController.text.trim().isEmpty
            ? null
            : double.tryParse(_costController.text.trim());

        final updatedTrip = await ref.read(tripControllerProvider.notifier).updateTrip(
              tripId: widget.tripId!,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              destination: _destinationController.text.trim().isEmpty
                  ? null
                  : _destinationController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              cost: cost,
              currency: _currency,
              isPublic: _isPublic,
            );

        if (kDebugMode) {
          debugPrint('DEBUG: ========== UPDATE SUCCESSFUL ==========');
          debugPrint('DEBUG: Updated Trip Name: ${updatedTrip.name}');
          debugPrint('DEBUG: Updated Trip Description: ${updatedTrip.description ?? "NULL"}');
          debugPrint('DEBUG: Updated Trip Destination: ${updatedTrip.destination ?? "NULL"}');
          debugPrint('DEBUG: Updated Trip Cost: ${updatedTrip.cost ?? "NULL"}');
          debugPrint('DEBUG: Updated Trip Currency: ${updatedTrip.currency}');
        }
      } else {
        // Create new trip
        if (kDebugMode) {
          debugPrint('DEBUG: Creating trip with name: ${_nameController.text.trim()}');
          debugPrint('DEBUG: Cost: ${_costController.text.isEmpty ? 'NULL' : _costController.text}');
          debugPrint('DEBUG: Currency: $_currency');
        }

        final cost = _costController.text.trim().isEmpty
            ? null
            : double.tryParse(_costController.text.trim());

        final trip = await ref
            .read(tripControllerProvider.notifier)
            .createTrip(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              destination: _destinationController.text.trim().isEmpty
                  ? null
                  : _destinationController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              coverImageUrl: _coverImageUrl,
              cost: cost,
              currency: _currency,
              isPublic: _isPublic,
            );

        if (kDebugMode) {
          debugPrint('DEBUG: Trip created with ID: ${trip.id}');
          debugPrint('DEBUG: Trip Cost: ${trip.cost ?? "NULL"}');
          debugPrint('DEBUG: Trip Currency: ${trip.currency}');
        }

        // Apply template if one was selected
        if (kDebugMode) {
          debugPrint('DEBUG: Checking for template - widget.templateId = ${widget.templateId}');
        }

        if (widget.templateId != null) {
          if (kDebugMode) {
            debugPrint('DEBUG: Applying template ${widget.templateId} to trip ${trip.id}');
          }

          final success = await ref
              .read(templateControllerProvider.notifier)
              .applyTemplateToTrip(
                templateId: widget.templateId!,
                tripId: trip.id,
              );

          if (kDebugMode) {
            debugPrint('DEBUG: Template applied: $success');
          }
        } else {
          if (kDebugMode) {
            debugPrint('DEBUG: No template to apply (templateId is null)');
          }
        }
      }

      if (mounted) {
        if (kDebugMode) {
          debugPrint('DEBUG: ========== SAVE SUCCESSFUL ==========');
          debugPrint('DEBUG: Invalidating providers to refresh all pages...');
        }

        // Invalidate and await fresh data before navigating back
        ref.invalidate(userTripsProvider);

        // If editing, also invalidate the specific trip provider
        if (isEditMode && widget.tripId != null) {
          ref.invalidate(tripProvider(widget.tripId!));
        }

        // Wait for the fresh trip list to load so home page is ready
        await ref.read(userTripsProvider.future);

        if (!mounted) return;

        context.pop();

        String successMessage;
        if (isEditMode) {
          successMessage = 'Trip updated successfully!';
        } else if (widget.templateId != null) {
          successMessage = 'Trip created with template applied!';
        } else {
          successMessage = 'Trip created successfully!';
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: Error saving trip: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.tripId != null;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: WaveGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: context.textColor.withValues(alpha: 0.87)),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Header Section with Animation
                FadeSlideAnimation(
                  delay: Duration.zero,
                  child: GlossyCard(
                    useHeaderGradient: true,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flight_takeoff,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'Plan Your Adventure',
                          style: context.headlineStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          'Tell us about your upcoming trip',
                          style: context.bodyStyle.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Form Fields with Staggered Animation
                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall,
                  child: _buildFormField(
                    controller: _nameController,
                    label: 'Trip Name',
                    icon: Icons.flight_takeoff,
                    hint: 'e.g., Summer Beach Vacation',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a trip name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 2,
                  child: _buildDestinationField(),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 3,
                  child: _buildFormField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    icon: Icons.description,
                    hint: 'Tell us about your trip...',
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Cost Section
                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 4,
                  child: Column(
                    children: [
                      // Currency Dropdown
                      _buildCurrencyDropdown(),
                      const SizedBox(height: AppTheme.spacingMd),
                      // Trip Cost
                      _buildFormField(
                        controller: _costController,
                        label: 'Trip Cost (Optional)',
                        icon: Icons.payments_outlined,
                        hint: 'e.g., 50000 per person',
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final cost = double.tryParse(value);
                            if (cost == null) {
                              return 'Please enter a valid number';
                            }
                            if (cost < 0) {
                              return 'Cost must be positive';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Trip Visibility Section
                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 5,
                  child: _buildVisibilityToggle(),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Date Section
                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 6,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Start Date',
                              icon: Icons.calendar_today,
                              date: _startDate,
                              onTap: _selectStartDate,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: _buildDateField(
                              label: 'End Date',
                              icon: Icons.event,
                              date: _endDate,
                              onTap: _selectEndDate,
                            ),
                          ),
                        ],
                      ),
                      // Template duration info/warning
                      if (_templateDurationDays != null) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: AppTheme.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: _hasTemplateWarning
                                ? AppTheme.warning.withValues(alpha: 0.1)
                                : context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(
                              color: _hasTemplateWarning
                                  ? AppTheme.warning.withValues(alpha: 0.3)
                                  : context.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _hasTemplateWarning
                                    ? Icons.warning_amber_rounded
                                    : Icons.auto_awesome,
                                size: 18,
                                color: _hasTemplateWarning
                                    ? AppTheme.warning
                                    : context.primaryColor,
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  _hasTemplateWarning
                                      ? 'Selected dates don\'t match template duration ($_templateDurationDays days). Template itinerary may not align perfectly.'
                                      : 'Template: $_templateDurationDays days - End date auto-calculated',
                                  style: context.bodyStyle.copyWith(
                                    fontSize: 12,
                                    color: _hasTemplateWarning
                                        ? AppTheme.warning
                                        : context.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Create Button with Animation
                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 5,
                  child: GlossyButton(
                    label: isEditMode ? 'Save Changes' : 'Create Trip',
                    icon: isEditMode ? Icons.save : Icons.add,
                    onPressed: _isLoading ? null : _handleCreateTrip,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the input field with padding
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingXs,
            bottom: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.primaryColor),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: context.titleStyle.copyWith(
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
        // Input field - NO LABEL INSIDE
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowSm,
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              // NO labelText - only hint text inside the field
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.neutral400,
                fontSize: 14,
              ),
              // Remove any label behavior
              floatingLabelBehavior: FloatingLabelBehavior.never,
              // Borders
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.neutral200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: context.primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: const BorderSide(color: AppTheme.error, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: maxLines > 1 ? AppTheme.spacingMd : AppTheme.spacingMd,
              ),
            ),
            validator: validator,
            enabled: !_isLoading,
            maxLines: maxLines,
            minLines: maxLines > 1 ? 3 : 1,
            style: context.bodyStyle.copyWith(
                  color: context.textColor,
                  fontSize: 16,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationField() {
    final hasValue = _destinationController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingXs,
            bottom: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 20, color: context.primaryColor),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Destination',
                style: context.titleStyle.copyWith(
                  color: context.textColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Tappable search field
        GestureDetector(
          onTap: _isLoading ? null : _searchDestination,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.neutral200, width: 1.5),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue
                        ? _destinationController.text
                        : 'Search city, town, or country...',
                    style: TextStyle(
                      color: hasValue ? context.textColor : AppTheme.neutral400,
                      fontSize: 16,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.search,
                  color: context.primaryColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return AnimatedScaleButton(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: context.primaryColor),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  label,
                  style: context.bodyStyle.copyWith(
                        color: context.textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              date != null ? date.toFormattedDate() : 'Select date',
              style: context.bodyStyle.copyWith(
                    color: date != null
                        ? context.textColor
                        : AppTheme.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    const currencies = [
      'INR', // Indian Rupee
      'USD', // US Dollar
      'EUR', // Euro
      'GBP', // British Pound
      'AUD', // Australian Dollar
      'CAD', // Canadian Dollar
      'JPY', // Japanese Yen
      'CNY', // Chinese Yuan
      'AED', // UAE Dirham
      'SGD', // Singapore Dollar
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the dropdown
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingXs,
            bottom: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Icon(Icons.currency_exchange, size: 20, color: context.primaryColor),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Currency',
                style: context.titleStyle.copyWith(
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
        // Dropdown field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowSm,
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: InputDecoration(
              hintText: 'Select currency',
              hintStyle: TextStyle(
                color: AppTheme.neutral400,
                fontSize: 14,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.neutral200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: context.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingMd,
              ),
            ),
            items: currencies.map((String currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Text(
                  currency,
                  style: context.bodyStyle.copyWith(
                        color: context.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }).toList(),
            onChanged: _isLoading
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currency = newValue;
                      });
                    }
                  },
            style: context.bodyStyle.copyWith(
                  color: context.textColor,
                  fontSize: 16,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
        border: Border.all(
          color: AppTheme.neutral200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon and label
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            size: 20,
            color: _isPublic ? context.primaryColor : AppTheme.neutral600,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Visibility',
                  style: context.titleStyle.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPublic
                      ? 'Public - Anyone can discover this trip'
                      : 'Private - Only members can see this trip',
                  style: context.bodyStyle.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Toggle switch
          Switch(
            value: _isPublic,
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
            activeTrackColor: context.primaryColor.withValues(alpha: 0.5),
            activeThumbColor: context.primaryColor,
          ),
        ],
      ),
    );
  }
}
