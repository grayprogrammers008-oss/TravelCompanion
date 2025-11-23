import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../providers/itinerary_providers.dart';

class AddEditItineraryItemPage extends ConsumerStatefulWidget {
  final String tripId;
  final String? itemId; // null for add, non-null for edit

  const AddEditItineraryItemPage({
    super.key,
    required this.tripId,
    this.itemId,
  });

  @override
  ConsumerState<AddEditItineraryItemPage> createState() =>
      _AddEditItineraryItemPageState();
}

class _AddEditItineraryItemPageState
    extends ConsumerState<AddEditItineraryItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  int? _dayNumber;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadExistingItem();
    }
  }

  Future<void> _loadExistingItem() async {
    try {
      final repository = ref.read(itineraryRepositoryProvider);
      final item = await repository.getItineraryItem(widget.itemId!);

      setState(() {
        _titleController.text = item.title;
        _descriptionController.text = item.description ?? '';
        _locationController.text = item.location ?? '';
        _startTime = item.startTime;
        _endTime = item.endTime;
        _dayNumber = item.dayNumber;
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime != null
          ? TimeOfDay.fromDateTime(_startTime!)
          : TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _startTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime != null
          ? TimeOfDay.fromDateTime(_endTime!)
          : TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _endTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
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
          SnackBar(
            content: const Text('End time must be after start time'),
            backgroundColor: context.errorColor,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(itineraryControllerProvider.notifier);

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
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving activity: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemId != null;

    // Show loading while fetching existing item
    if (isEdit && !_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: AppLoadingIndicator(
            message: 'Loading activity...',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Activity' : 'Add Activity'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Visit Eiffel Tower',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add details about this activity',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Location Field
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Champ de Mars, Paris',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
            ),

            const SizedBox(height: 16),

            // Day Number Picker
            DropdownButtonFormField<int>(
              initialValue: _dayNumber,
              decoration: const InputDecoration(
                labelText: 'Day',
                hintText: 'Select day number',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
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
                      setState(() {
                        _dayNumber = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

            // Start Time Picker
            InkWell(
              onTap: _isLoading ? null : _selectStartTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _startTime != null
                          ? DateFormat.Hm().format(_startTime!)
                          : 'Select time',
                      style: context.bodyLarge.copyWith(
                        color: _startTime != null
                            ? context.textColor
                            : context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    if (_startTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _startTime = null;
                                });
                              },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // End Time Picker
            InkWell(
              onTap: _isLoading ? null : _selectEndTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  prefixIcon: Icon(Icons.access_time_filled),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _endTime != null
                          ? DateFormat.Hm().format(_endTime!)
                          : 'Select time',
                      style: context.bodyLarge.copyWith(
                        color: _endTime != null
                            ? context.textColor
                            : context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    if (_endTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _endTime = null;
                                });
                              },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'Update Activity' : 'Add Activity',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 8),

            // Cancel Button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      context.pop();
                    },
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 16),

            // Help Text
            Text(
              '* Required fields',
              style: context.bodySmall.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
