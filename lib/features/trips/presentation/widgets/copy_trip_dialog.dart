import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/models/trip_model.dart';
import '../providers/trip_providers.dart';

/// Dialog for copying a trip with optional itinerary and checklists
class CopyTripDialog extends ConsumerStatefulWidget {
  final TripModel trip;
  final int itineraryCount;
  final int checklistCount;
  final int checklistItemsCount;

  const CopyTripDialog({
    super.key,
    required this.trip,
    required this.itineraryCount,
    required this.checklistCount,
    required this.checklistItemsCount,
  });

  /// Shows the copy trip dialog and returns the new trip ID if successful
  static Future<String?> show(
    BuildContext context, {
    required TripModel trip,
    required int itineraryCount,
    required int checklistCount,
    required int checklistItemsCount,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CopyTripDialog(
        trip: trip,
        itineraryCount: itineraryCount,
        checklistCount: checklistCount,
        checklistItemsCount: checklistItemsCount,
      ),
    );
  }

  @override
  ConsumerState<CopyTripDialog> createState() => _CopyTripDialogState();
}

class _CopyTripDialogState extends ConsumerState<CopyTripDialog> {
  late TextEditingController _nameController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _copyItinerary = true;
  bool _copyChecklists = true;
  bool _isLoading = false;

  final _dateFormat = DateFormat('MMM d, yyyy');

  /// Calculate the original trip duration in days
  int get _originalTripDuration {
    if (widget.trip.startDate != null && widget.trip.endDate != null) {
      return widget.trip.endDate!.difference(widget.trip.startDate!).inDays;
    }
    return 0; // Same day trip
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '${widget.trip.name} (Copy)');

    // Set default dates - start tomorrow, end based on original trip duration
    _startDate = DateTime.now().add(const Duration(days: 1));
    _endDate = _startDate!.add(Duration(days: _originalTripDuration));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _startDate != null &&
      _endDate != null &&
      !_isLoading;

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Auto-calculate end date based on original trip duration
        _endDate = picked.add(Duration(days: _originalTripDuration));
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date first'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _copyTrip() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a trip name'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final useCase = ref.read(copyTripUseCaseProvider);
      final newTripId = await useCase(
        sourceTripId: widget.trip.id,
        newName: name,
        newStartDate: _startDate!,
        newEndDate: _endDate!,
        copyItinerary: _copyItinerary,
        copyChecklists: _copyChecklists,
      );

      // Invalidate trips provider to refresh the list
      ref.invalidate(userTripsProvider);

      if (mounted) {
        Navigator.of(context).pop(newTripId);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy trip: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.copy, color: context.primaryColor),
          const SizedBox(width: 8),
          const Text('Copy Trip'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g., Beach Trip',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: context.textColor.withValues(alpha: 0.23)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: context.primaryColor, width: 2),
                ),
                prefixIcon: Icon(Icons.edit, color: context.primaryColor),
              ),
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Date pickers row
            Row(
              children: [
                // Start date
                Expanded(
                  child: _buildDateField(
                    label: 'Start Date',
                    value: _startDate,
                    onTap: _selectStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                // End date (disabled - auto-calculated based on trip duration)
                Expanded(
                  child: _buildDateField(
                    label: 'End Date',
                    value: _endDate,
                    onTap: _selectEndDate,
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Copy options
            Text(
              'What to copy:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),

            // Copy itinerary checkbox
            CheckboxListTile(
              value: _copyItinerary,
              onChanged: widget.itineraryCount > 0
                  ? (value) => setState(() => _copyItinerary = value ?? true)
                  : null,
              title: Text(
                'Copy Itinerary',
                style: TextStyle(
                  color: widget.itineraryCount > 0
                      ? context.textColor
                      : AppTheme.neutral400,
                ),
              ),
              subtitle: Text(
                widget.itineraryCount > 0
                    ? '${widget.itineraryCount} activities'
                    : 'No activities to copy',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral500,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: context.primaryColor,
            ),

            // Copy checklists checkbox
            CheckboxListTile(
              value: _copyChecklists,
              onChanged: widget.checklistCount > 0
                  ? (value) => setState(() => _copyChecklists = value ?? true)
                  : null,
              title: Text(
                'Copy Checklists',
                style: TextStyle(
                  color: widget.checklistCount > 0
                      ? context.textColor
                      : AppTheme.neutral400,
                ),
              ),
              subtitle: Text(
                widget.checklistCount > 0
                    ? '${widget.checklistCount} lists, ${widget.checklistItemsCount} items (all reset to unchecked)'
                    : 'No checklists to copy',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral500,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: context.primaryColor,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSubmit ? _copyTrip : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.neutral200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create Copy'),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final isDisabled = !enabled || _isLoading;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled ? AppTheme.neutral100 : null,
          border: Border.all(
            color: isDisabled
                ? AppTheme.neutral300
                : value != null
                    ? context.primaryColor.withValues(alpha: 0.5)
                    : context.textColor.withValues(alpha: 0.23),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDisabled ? AppTheme.neutral400 : AppTheme.neutral500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isDisabled ? Icons.lock_outline : Icons.calendar_today,
                  size: 16,
                  color: isDisabled
                      ? AppTheme.neutral400
                      : value != null
                          ? context.primaryColor
                          : AppTheme.neutral400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null ? _dateFormat.format(value) : 'Select',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDisabled
                          ? AppTheme.neutral500
                          : value != null
                              ? context.textColor
                              : AppTheme.neutral400,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
