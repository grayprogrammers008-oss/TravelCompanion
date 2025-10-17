import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/trip_providers.dart';

class CreateTripPage extends ConsumerStatefulWidget {
  const CreateTripPage({super.key});

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
      print('DEBUG: Creating trip with name: ${_nameController.text.trim()}');

      // Create trip using trip controller
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

      print('DEBUG: Trip created with ID: ${trip.id}');

      if (mounted) {
        // Refresh the trips list
        print('DEBUG: Invalidating userTripsProvider');
        ref.invalidate(userTripsProvider);

        print('DEBUG: Navigating back to home');
        context.pop(); // Go back to trips list

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error creating trip: $e');
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
    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Create New Trip'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section with Animation
                FadeSlideAnimation(
                  delay: Duration.zero,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.shadowTeal,
                    ),
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
                  child: AnimatedScaleButton(
                    onTap: _isLoading ? null : _handleCreateTrip,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.shadowTeal,
                      ),
                      child: ElevatedButton(
                        onPressed: null, // Handled by AnimatedScaleButton
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline,
                                      color: Colors.white),
                                  const SizedBox(width: AppTheme.spacingXs),
                                  Text(
                                    'Create Trip',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
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
          prefixIcon: Icon(icon, color: AppTheme.primaryTeal),
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
                Icon(icon, size: 16, color: AppTheme.primaryTeal),
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
