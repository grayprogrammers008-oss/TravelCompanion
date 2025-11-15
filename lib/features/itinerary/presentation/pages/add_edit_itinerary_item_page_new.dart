import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/premium_form_fields.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/confetti_animation.dart';
import '../providers/itinerary_providers.dart';

class AddEditItineraryItemPageNew extends ConsumerStatefulWidget {
  final String tripId;
  final String? itemId; // null for add, non-null for edit

  const AddEditItineraryItemPageNew({
    super.key,
    required this.tripId,
    this.itemId,
  });

  @override
  ConsumerState<AddEditItineraryItemPageNew> createState() =>
      _AddEditItineraryItemPageNewState();
}

class _AddEditItineraryItemPageNewState
    extends ConsumerState<AddEditItineraryItemPageNew>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  int? _dayNumber;
  bool _isLoading = false;
  bool _isInitialized = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    _animationController.forward();

    if (widget.itemId != null) {
      _loadExistingItem();
    } else {
      _isInitialized = true;
    }
  }

  Future<void> _loadExistingItem() async {
    try {
      final repository = ref.read(itineraryRepositoryProvider);
      final item = await repository.getItineraryItem(widget.itemId!);

      if (mounted) {
        setState(() {
          _titleController.text = item.title;
          _descriptionController.text = item.description ?? '';
          _locationController.text = item.location ?? '';
          _startTime = item.startTime;
          _endTime = item.endTime;
          _dayNumber = item.dayNumber;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate time range
    if (_startTime != null && _endTime != null) {
      if (_endTime!.isBefore(_startTime!) ||
          _endTime!.isAtSameMomentAs(_startTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(itineraryControllerProvider.notifier);
      final scaffoldContext = context; // Store context before async

      if (widget.itemId == null) {
        // Create new item
        await controller.createItem(
          tripId: widget.tripId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          dayNumber: _dayNumber,
        );

        // Show confetti for new item!
        if (mounted && scaffoldContext.mounted) {
          ConfettiOverlay.show(scaffoldContext, particleCount: 80);
        }
      } else {
        // Update existing item
        await controller.updateItem(
          itemId: widget.itemId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          dayNumber: _dayNumber,
        );
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!scaffoldContext.mounted) return;
        scaffoldContext.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving activity: $e'),
            backgroundColor: AppTheme.error,
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
    final isEdit = widget.itemId != null;

    // Show loading while fetching existing item
    if (isEdit && !_isInitialized) {
      final themeData = context.appThemeData;
      return Scaffold(
        backgroundColor: AppTheme.neutral50,
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: themeData.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: themeData.primaryColor,
          ),
        ),
      );
    }

    final themeData = context.appThemeData;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Activity' : 'Add Activity'),
        backgroundColor: themeData.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: WaveGradientBackground(
        child: SafeArea(
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
                        gradient: themeData.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: themeData.primaryShadow,
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
                              Icons.event_note,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            isEdit ? 'Update Activity' : 'Plan Your Day',
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
                            isEdit
                                ? 'Modify your activity details'
                                : 'Add a new activity to your itinerary',
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

                  // Title Field
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall,
                    child: PremiumTextField(
                      controller: _titleController,
                      labelText: 'Activity Title *',
                      hintText: 'e.g., Visit Eiffel Tower',
                      prefixIcon: Icons.title,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                      enabled: !_isLoading,
                      maxLength: 100,
                      showCharacterCount: true,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Description Field
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 2,
                    child: PremiumTextField(
                      controller: _descriptionController,
                      labelText: 'Description',
                      hintText: 'Add details about this activity',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isLoading,
                      maxLength: 500,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Location Field
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 3,
                    child: PremiumTextField(
                      controller: _locationController,
                      labelText: 'Location',
                      hintText: 'e.g., Champ de Mars, Paris',
                      prefixIcon: Icons.location_on,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_isLoading,
                      maxLength: 200,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Day Number Dropdown
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 4,
                    child: PremiumDropdown<int>(
                      value: _dayNumber,
                      labelText: 'Day',
                      hintText: 'Select day number',
                      prefixIcon: Icons.calendar_today,
                      items: List.generate(
                        30,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('Day ${index + 1}'),
                        ),
                      ),
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() => _dayNumber = value);
                            },
                      enabled: !_isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Start & End Time
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 5,
                    child: Row(
                      children: [
                        Expanded(
                          child: PremiumDateTimePicker(
                            selectedTime: _startTime != null
                                ? TimeOfDay.fromDateTime(_startTime!)
                                : null,
                            labelText: 'Start Time',
                            prefixIcon: Icons.access_time,
                            pickDate: false,
                            pickTime: true,
                            onTimeChanged: (time) {
                              if (time != null) {
                                final now = DateTime.now();
                                setState(() {
                                  _startTime = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: PremiumDateTimePicker(
                            selectedTime: _endTime != null
                                ? TimeOfDay.fromDateTime(_endTime!)
                                : null,
                            labelText: 'End Time',
                            prefixIcon: Icons.access_time_filled,
                            pickDate: false,
                            pickTime: true,
                            onTimeChanged: (time) {
                              if (time != null) {
                                final now = DateTime.now();
                                setState(() {
                                  _endTime = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing2xl),

                  // Save Button
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 6,
                    child: GlossyButton(
                      label: isEdit ? 'Update Activity' : 'Add Activity',
                      icon: isEdit ? Icons.check : Icons.add,
                      onPressed: _isLoading ? null : _saveItem,
                      isLoading: _isLoading,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingMd),

                  // Cancel Button
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 7,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.neutral600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Help Text
                  FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * 8,
                    child: Center(
                      child: Text(
                        '* Required fields',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.neutral500,
                            ),
                      ),
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
}
