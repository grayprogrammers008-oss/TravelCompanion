import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../providers/trip_providers.dart';

class CreateTripPage extends ConsumerStatefulWidget {
  final String? tripId; // If provided, page is in edit mode

  const CreateTripPage({super.key, this.tripId});

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

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
    }
  }

  Future<void> _loadTripData() async {
    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        debugPrint('DEBUG: ========== REFRESHING TRIP DATA ==========');
        debugPrint('DEBUG: Trip ID: ${widget.tripId}');
        debugPrint('DEBUG: Using ref.refresh() to force fresh data from backend...');
      }

      // CRITICAL FIX: Use ref.refresh() instead of ref.invalidate()
      // This forces an immediate re-fetch of data from the backend
      // and returns the fresh data directly
      final trip = await ref.refresh(tripProvider(widget.tripId!).future);

      if (kDebugMode) {
        debugPrint('DEBUG: Loaded Trip Name: ${trip.trip.name}');
        debugPrint('DEBUG: Loaded Trip Description: ${trip.trip.description ?? "NULL"}');
        debugPrint('DEBUG: Loaded Trip Destination: ${trip.trip.destination ?? "NULL"}');
        debugPrint('DEBUG: Loaded Trip Start Date: ${trip.trip.startDate}');
        debugPrint('DEBUG: Loaded Trip End Date: ${trip.trip.endDate}');
      }

      if (mounted) {
        setState(() {
          _nameController.text = trip.trip.name;
          _descriptionController.text = trip.trip.description ?? '';
          _destinationController.text = trip.trip.destination ?? '';
          _startDate = trip.trip.startDate;
          _endDate = trip.trip.endDate;
          _isLoading = false;
        });

        if (kDebugMode) {
          debugPrint('DEBUG: Form fields populated');
          debugPrint('DEBUG: Name Controller: "${_nameController.text}"');
          debugPrint('DEBUG: Description Controller: "${_descriptionController.text}"');
          debugPrint('DEBUG: Destination Controller: "${_destinationController.text}"');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG: ========== ERROR LOADING TRIP ==========');
        debugPrint('DEBUG: Error: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trip: $e'),
            backgroundColor: Colors.red,
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
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
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
        }

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
            );

        if (kDebugMode) {
          debugPrint('DEBUG: ========== UPDATE SUCCESSFUL ==========');
          debugPrint('DEBUG: Updated Trip Name: ${updatedTrip.name}');
          debugPrint('DEBUG: Updated Trip Description: ${updatedTrip.description ?? "NULL"}');
          debugPrint('DEBUG: Updated Trip Destination: ${updatedTrip.destination ?? "NULL"}');
        }
      } else {
        // Create new trip
        if (kDebugMode) {
          debugPrint('DEBUG: Creating trip with name: ${_nameController.text.trim()}');
        }

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
            );

        if (kDebugMode) {
          debugPrint('DEBUG: Trip created with ID: ${trip.id}');
        }
      }

      if (mounted) {
        if (kDebugMode) {
          debugPrint('DEBUG: ========== SAVE SUCCESSFUL ==========');
          debugPrint('DEBUG: Invalidating providers to refresh all pages...');
        }

        // Refresh the trips list - this will update the home page
        ref.invalidate(userTripsProvider);
        if (kDebugMode) {
          debugPrint('DEBUG: ✓ userTripsProvider invalidated');
        }

        // If editing, also invalidate the specific trip provider
        // This is CRITICAL - ensures the next time edit page opens, it will fetch fresh data
        if (isEditMode && widget.tripId != null) {
          ref.invalidate(tripProvider(widget.tripId!));
          if (kDebugMode) {
            debugPrint('DEBUG: ✓ tripProvider(${widget.tripId}) invalidated');
            debugPrint('DEBUG: Next time edit page opens, it will fetch fresh data');
          }
        }

        if (kDebugMode) {
          debugPrint('DEBUG: Navigating back to previous screen...');
        }

        // Pop back to previous screen
        // The invalidation above will cause pages to rebuild with fresh data
        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isEditMode ? 'Trip updated successfully!' : 'Trip created successfully!'),
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
      backgroundColor: AppTheme.neutral50,
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
                      icon: const Icon(Icons.arrow_back, color: AppTheme.neutral700),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          'Tell us about your upcoming trip',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  child: _buildFormField(
                    controller: _destinationController,
                    label: 'Destination',
                    icon: Icons.location_on,
                    hint: 'e.g., Bali, Indonesia',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a destination';
                      }
                      return null;
                    },
                  ),
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

                // Date Section
                FadeSlideAnimation(
                  delay: AppAnimations.staggerSmall * 4,
                  child: Row(
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
    final themeData = context.appThemeData;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeData.primaryColor),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
        ),
        validator: validator,
        enabled: !_isLoading,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final themeData = context.appThemeData;
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
                Icon(icon, size: 16, color: themeData.primaryColor),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral600,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              date != null ? date.toFormattedDate() : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: date != null
                        ? AppTheme.neutral900
                        : AppTheme.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
