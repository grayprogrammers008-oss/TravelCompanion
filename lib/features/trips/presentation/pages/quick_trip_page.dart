// Quick Trip Page
//
// Simplified trip creation with just 2 fields:
// 1. Destination (required)
// 2. Dates (with smart presets)
//
// Auto-generates trip name and uses smart defaults for other fields.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/widgets/place_search_delegate.dart';
import '../../../../core/services/place_search_service.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../providers/trip_providers.dart';

class QuickTripPage extends ConsumerStatefulWidget {
  const QuickTripPage({super.key});

  @override
  ConsumerState<QuickTripPage> createState() => _QuickTripPageState();
}

class _QuickTripPageState extends ConsumerState<QuickTripPage> {
  final _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;

  // Current step: 0 = destination, 1 = dates
  int _currentStep = 0;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  /// Open place search for destination
  Future<void> _searchDestination() async {
    final result = await showSearch<Place?>(
      context: context,
      delegate: PlaceSearchDelegate(),
    );

    if (result != null && mounted) {
      setState(() {
        _destinationController.text = result.shortName;
        // Auto-advance to dates step
        _currentStep = 1;
      });
    }
  }

  /// Select date preset
  void _selectDatePreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      switch (preset) {
        case 'this_weekend':
          // Find this coming Saturday (or today if it's Saturday/Sunday)
          final (saturday, sunday) = _getThisWeekend(today);
          _startDate = saturday;
          _endDate = sunday;
          break;
        case 'next_weekend':
          // Find the weekend AFTER this coming weekend
          final (saturday, sunday) = _getNextWeekend(today);
          _startDate = saturday;
          _endDate = sunday;
          break;
        case 'next_week':
          // Next Monday to Friday
          final daysUntilMonday = (DateTime.monday - today.weekday) % 7;
          final monday = today.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
          _startDate = monday;
          _endDate = monday.add(const Duration(days: 4)); // Friday
          break;
        case 'custom':
          _showCustomDatePicker();
          return;
      }
    });
  }

  /// Get this weekend's Saturday and Sunday
  (DateTime, DateTime) _getThisWeekend(DateTime today) {
    final weekday = today.weekday;
    DateTime saturday;

    if (weekday == DateTime.saturday) {
      // Today is Saturday
      saturday = today;
    } else if (weekday == DateTime.sunday) {
      // Today is Sunday - still consider it "this weekend"
      saturday = today.subtract(const Duration(days: 1));
    } else {
      // Weekday - find coming Saturday
      final daysUntilSaturday = DateTime.saturday - weekday;
      saturday = today.add(Duration(days: daysUntilSaturday));
    }

    return (saturday, saturday.add(const Duration(days: 1)));
  }

  /// Get next weekend's Saturday and Sunday (the weekend AFTER this one)
  (DateTime, DateTime) _getNextWeekend(DateTime today) {
    final (thisSaturday, _) = _getThisWeekend(today);
    // Next weekend is 7 days after this weekend
    final nextSaturday = thisSaturday.add(const Duration(days: 7));
    return (nextSaturday, nextSaturday.add(const Duration(days: 1)));
  }

  /// Show custom date range picker
  Future<void> _showCustomDatePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final themeData = ref.read(theme_provider.currentThemeDataProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeData.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  /// Create the trip
  Future<void> _createTrip() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a destination'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select dates for your trip'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final controller = ref.read(tripControllerProvider.notifier);

      // Auto-generate trip name from destination
      final destination = _destinationController.text;
      final tripName = 'Trip to $destination';

      final trip = await controller.createTrip(
        name: tripName,
        destination: destination,
        startDate: _startDate,
        endDate: _endDate,
        isPublic: false, // Private by default for quick trips
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tripName created!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh home page trip list
        ref.invalidate(userTripsProvider);
        // Navigate to the new trip
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
        setState(() => _isCreating = false);
      }
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get day name
  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final hasDestination = _destinationController.text.isNotEmpty;
    final hasDates = _startDate != null;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        backgroundColor: themeData.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Quick Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          // AI Wizard button
          IconButton(
            onPressed: () => context.push('/trips/ai-wizard'),
            tooltip: 'AI Trip Wizard',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Destination', hasDestination),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: hasDestination ? themeData.primaryColor : AppTheme.neutral200,
                    ),
                  ),
                  _buildStepIndicator(1, 'Dates', hasDates),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Destination
                    _buildSectionCard(
                      title: 'Where are you going?',
                      subtitle: 'Search for a city, place, or destination',
                      icon: Icons.location_on,
                      iconColor: themeData.primaryColor,
                      isActive: _currentStep == 0,
                      child: InkWell(
                        onTap: _searchDestination,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentStep == 0
                                  ? themeData.primaryColor
                                  : AppTheme.neutral200,
                              width: _currentStep == 0 ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            color: _currentStep == 0
                                ? themeData.primaryColor.withValues(alpha: 0.05)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: hasDestination
                                    ? themeData.primaryColor
                                    : AppTheme.neutral400,
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: Text(
                                  hasDestination
                                      ? _destinationController.text
                                      : 'Search destination...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: hasDestination
                                        ? Colors.black87
                                        : AppTheme.neutral400,
                                    fontWeight: hasDestination
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasDestination)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingLg),

                    // Step 2: Dates
                    _buildSectionCard(
                      title: 'When are you traveling?',
                      subtitle: 'Pick dates or choose a preset',
                      icon: Icons.calendar_today,
                      iconColor: const Color(0xFFFF9800),
                      isActive: _currentStep == 1 && hasDestination,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date presets
                          Wrap(
                            spacing: AppTheme.spacingSm,
                            runSpacing: AppTheme.spacingSm,
                            children: [
                              _buildDatePresetChip(
                                'This Weekend',
                                'this_weekend',
                                themeData,
                              ),
                              _buildDatePresetChip(
                                'Next Weekend',
                                'next_weekend',
                                themeData,
                              ),
                              _buildDatePresetChip(
                                'Next Week',
                                'next_week',
                                themeData,
                              ),
                              _buildDatePresetChip(
                                'Pick Dates',
                                'custom',
                                themeData,
                                icon: Icons.edit_calendar,
                              ),
                            ],
                          ),

                          // Selected dates display
                          if (hasDates) ...[
                            const SizedBox(height: AppTheme.spacingMd),
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: AppTheme.spacingSm),
                                  Text(
                                    '${_getDayName(_startDate!)}, ${_formatDate(_startDate!)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const Text(' → '),
                                  Text(
                                    '${_getDayName(_endDate!)}, ${_formatDate(_endDate!)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_endDate!.difference(_startDate!).inDays + 1} days',
                                    style: TextStyle(
                                      color: AppTheme.neutral600,
                                      fontSize: 13,
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

                    // Trip preview
                    if (hasDestination && hasDates) ...[
                      Container(
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
                                Icon(Icons.auto_awesome,
                                    color: themeData.primaryColor, size: 20),
                                const SizedBox(width: AppTheme.spacingSm),
                                Text(
                                  'Your trip will be created as:',
                                  style: TextStyle(
                                    color: AppTheme.neutral600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Text(
                              'Trip to ${_destinationController.text}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)} • ${_endDate!.difference(_startDate!).inDays + 1} days',
                              style: TextStyle(
                                color: AppTheme.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom action button
            Container(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingMd,
                AppTheme.spacingLg,
                AppTheme.spacingMd + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (hasDestination && hasDates && !_isCreating)
                      ? _createTrip
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    disabledBackgroundColor: AppTheme.neutral200,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch, size: 20),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text(
                              hasDestination && hasDates
                                  ? 'Create Trip'
                                  : hasDestination
                                      ? 'Select Dates'
                                      : 'Enter Destination',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildStepIndicator(int step, String label, bool isComplete) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final isActive = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? Colors.green
                : isActive
                    ? themeData.primaryColor
                    : AppTheme.neutral200,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.neutral500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isComplete || isActive
                ? Colors.black87
                : AppTheme.neutral400,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isActive,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: isActive ? AppTheme.shadowMd : AppTheme.shadowSm,
        border: isActive
            ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }

  Widget _buildDatePresetChip(
    String label,
    String preset,
    AppThemeData themeData, {
    IconData? icon,
  }) {
    final isSelected = _isPresetSelected(preset);

    return ActionChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: isSelected ? Colors.white : themeData.primaryColor)
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: isSelected ? themeData.primaryColor : Colors.white,
      side: BorderSide(
        color: isSelected ? themeData.primaryColor : AppTheme.neutral300,
      ),
      onPressed: () => _selectDatePreset(preset),
    );
  }

  bool _isPresetSelected(String preset) {
    if (_startDate == null || _endDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case 'this_weekend':
        final (saturday, sunday) = _getThisWeekend(today);
        return _startDate == saturday && _endDate == sunday;
      case 'next_weekend':
        final (saturday, sunday) = _getNextWeekend(today);
        return _startDate == saturday && _endDate == sunday;
      case 'next_week':
        final daysUntilMonday = (DateTime.monday - today.weekday) % 7;
        final monday = today.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
        return _startDate == monday && _endDate == monday.add(const Duration(days: 4));
      default:
        return false;
    }
  }
}
