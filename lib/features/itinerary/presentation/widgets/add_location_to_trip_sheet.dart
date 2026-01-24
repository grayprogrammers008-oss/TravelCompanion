import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/services/google_maps_url_parser.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/itinerary_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bottom sheet for adding a shared location to a trip's itinerary
/// Flow: Select Trip → Choose Day → Set Time → Add
class AddLocationToTripSheet extends ConsumerStatefulWidget {
  final ParsedLocation location;

  const AddLocationToTripSheet({
    super.key,
    required this.location,
  });

  /// Shows the bottom sheet and returns true if location was added
  static Future<bool> show(BuildContext context, ParsedLocation location) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLocationToTripSheet(location: location),
    );
    return result ?? false;
  }

  @override
  ConsumerState<AddLocationToTripSheet> createState() => _AddLocationToTripSheetState();
}

class _AddLocationToTripSheetState extends ConsumerState<AddLocationToTripSheet> {
  static const String _lastSelectedTripKey = 'last_selected_trip_id';

  // Step: 0 = select trip, 1 = select day/time
  int _step = 0;
  TripModel? _selectedTrip;
  String? _selectedTripId;
  String _activityTitle = '';
  int? _selectedDay;
  TimeOfDay? _selectedTime;
  bool _isAdding = false;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastSelectedTrip();
    // Pre-fill title with place name if available
    if (widget.location.placeName != null) {
      _activityTitle = widget.location.placeName!;
      _titleController.text = _activityTitle;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSelectedTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTripId = prefs.getString(_lastSelectedTripKey);
    if (lastTripId != null && mounted) {
      setState(() => _selectedTripId = lastTripId);
    }
  }

  Future<void> _saveLastSelectedTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSelectedTripKey, tripId);
  }

  void _selectTrip(TripModel trip) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTrip = trip;
      _step = 1;
      // Set to first valid day (today or day 1 if trip hasn't started)
      _selectedDay = _getFirstValidDayForTrip(trip);
    });
  }

  /// Get first valid day for a specific trip (before _selectedTrip is set)
  int _getFirstValidDayForTrip(TripModel trip) {
    if (trip.startDate == null) return 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripStart = DateTime(trip.startDate!.year, trip.startDate!.month, trip.startDate!.day);

    if (today.isBefore(tripStart)) {
      return 1;
    } else {
      return today.difference(tripStart).inDays + 1;
    }
  }

  Future<void> _addToTrip() async {
    if (_activityTitle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an activity title'),
          backgroundColor: context.errorColor,
        ),
      );
      return;
    }

    if (_selectedTrip == null) return;

    setState(() => _isAdding = true);

    try {
      await _saveLastSelectedTrip(_selectedTrip!.id);

      // Calculate start time from selected day and time
      DateTime? startTime;
      if (_selectedTime != null && _selectedTrip!.startDate != null && _selectedDay != null) {
        final tripStart = _selectedTrip!.startDate!;
        final dayDate = tripStart.add(Duration(days: _selectedDay! - 1));
        startTime = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      // Create itinerary item
      final controller = ref.read(itineraryControllerProvider.notifier);
      await controller.createItem(
        tripId: _selectedTrip!.id,
        title: _activityTitle.trim(),
        location: widget.location.placeName,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        dayNumber: _selectedDay,
        startTime: startTime,
        description: null,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added to ${_selectedTrip!.name}${_selectedDay != null ? " (Day $_selectedDay)" : ""}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }

  int _getTripDays(TripModel trip) {
    if (trip.startDate != null && trip.endDate != null) {
      return trip.endDate!.difference(trip.startDate!).inDays + 1;
    }
    return 7; // Default to 7 days if dates not set
  }

  DateTime? _getDateForDay(int dayNumber) {
    if (_selectedTrip?.startDate == null) return null;
    return _selectedTrip!.startDate!.add(Duration(days: dayNumber - 1));
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(userTripsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Show step 1 (select trip) or step 2 (day/time)
              if (_step == 0)
                _buildTripSelectionStep(context, tripsAsync, scrollController)
              else
                _buildDayTimeStep(context, scrollController),
            ],
          );
        },
      ),
    );
  }

  /// Step 1: Select trip
  Widget _buildTripSelectionStep(
    BuildContext context,
    AsyncValue<List<TripWithMembers>> tripsAsync,
    ScrollController scrollController,
  ) {
    return Expanded(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_location_alt, color: Colors.teal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.location.placeName ?? 'Add Location',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.location.hasCoordinates)
                            Text(
                              '${widget.location.latitude!.toStringAsFixed(4)}, ${widget.location.longitude!.toStringAsFixed(4)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a trip to add this location:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // Trip list
          Expanded(
            child: tripsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: context.errorColor),
                    const SizedBox(height: 12),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (trips) {
                if (trips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flight_takeoff, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No trips yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Create a trip first', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                final sortedTrips = _sortTrips(trips);

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  itemCount: sortedTrips.length,
                  itemBuilder: (context, index) => _buildTripCard(context, sortedTrips[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripWithMembers tripWithMembers) {
    final trip = tripWithMembers.trip;
    final isLastSelected = trip.id == _selectedTripId;
    final now = DateTime.now();
    final isOngoing = trip.startDate != null &&
        trip.endDate != null &&
        trip.startDate!.isBefore(now) &&
        trip.endDate!.isAfter(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isLastSelected ? Colors.teal.withValues(alpha: 0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectTrip(trip),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLastSelected ? Colors.teal : Colors.grey[200]!,
                width: isLastSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flight, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trip.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLastSelected)
                            _buildBadge('Last', Colors.teal),
                          if (isOngoing && !isLastSelected)
                            _buildBadge('Active', Colors.green),
                        ],
                      ),
                      if (trip.destination != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              trip.destination!,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Step 2: Select day and time
  Widget _buildDayTimeStep(BuildContext context, ScrollController scrollController) {
    final validDays = _getValidDays();

    return Expanded(
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _step = 0;
                    _selectedTrip = null;
                  }),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTrip!.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.location.placeName ?? 'Location',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity title
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Activity Title',
                      hintText: widget.location.placeName ?? 'e.g., Visit the beach',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) => setState(() => _activityTitle = value),
                    enabled: !_isAdding,
                  ),

                  const SizedBox(height: 20),

                  // Day selection
                  Text('Select Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 8),

                  if (validDays.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No upcoming days available for this trip',
                              style: TextStyle(color: Colors.orange[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: validDays.length,
                        itemBuilder: (context, index) {
                          final dayNumber = validDays[index];
                          final isSelected = _selectedDay == dayNumber;
                          final dayDate = _getDateForDay(dayNumber);
                          final isToday = !_isDayPast(dayNumber) && dayDate != null &&
                              DateTime.now().year == dayDate.year &&
                              DateTime.now().month == dayDate.month &&
                              DateTime.now().day == dayDate.day;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedDay = dayNumber);
                              },
                              child: Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.teal : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.teal : (isToday ? Colors.teal.withValues(alpha: 0.5) : Colors.grey[300]!),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isToday ? 'Today' : 'Day',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected ? Colors.white70 : (isToday ? Colors.teal : Colors.grey[600]),
                                      ),
                                    ),
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (dayDate != null)
                                      Text(
                                        DateFormat('MMM d').format(dayDate),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isSelected ? Colors.white70 : Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Time selection
                  Text('Time (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Tap to set time',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedTime != null ? Colors.black87 : Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          if (_selectedTime != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => setState(() => _selectedTime = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Add button (fixed at bottom) with safe area
          Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spacingMd,
              right: AppTheme.spacingMd,
              top: AppTheme.spacingMd,
              bottom: AppTheme.spacingMd + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isAdding || validDays.isEmpty) ? null : _addToTrip,
                icon: _isAdding
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_location_alt),
                label: Text(_isAdding ? 'Adding...' : 'Add to Day $_selectedDay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  List<TripWithMembers> _sortTrips(List<TripWithMembers> trips) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Sort trips by relevance: Last Selected → Ongoing → Upcoming → Past
    return trips.toList()..sort((a, b) {
        final tripA = a.trip;
        final tripB = b.trip;

        // 1. Last selected trip comes first
        if (tripA.id == _selectedTripId) return -1;
        if (tripB.id == _selectedTripId) return 1;

        // 2. Ongoing trips come next
        final aOngoing = tripA.startDate != null && tripA.endDate != null &&
            tripA.startDate!.isBefore(now) && tripA.endDate!.isAfter(now);
        final bOngoing = tripB.startDate != null && tripB.endDate != null &&
            tripB.startDate!.isBefore(now) && tripB.endDate!.isAfter(now);

        if (aOngoing && !bOngoing) return -1;
        if (bOngoing && !aOngoing) return 1;

        // 3. Upcoming trips before past trips
        if (tripA.startDate != null && tripB.startDate != null) {
          final aIsFuture = tripA.startDate!.isAfter(today);
          final bIsFuture = tripB.startDate!.isAfter(today);

          if (aIsFuture && !bIsFuture) return -1;
          if (bIsFuture && !aIsFuture) return 1;

          // Within same category (both future or both past), sort by date
          return tripA.startDate!.compareTo(tripB.startDate!);
        }

        return 0;
      });
  }

  /// Get the first valid day based on trip status
  int _getFirstValidDay() {
    if (_selectedTrip?.startDate == null) return 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripStart = DateTime(_selectedTrip!.startDate!.year, _selectedTrip!.startDate!.month, _selectedTrip!.startDate!.day);
    final tripEnd = _selectedTrip!.endDate != null
        ? DateTime(_selectedTrip!.endDate!.year, _selectedTrip!.endDate!.month, _selectedTrip!.endDate!.day)
        : null;

    // Past trip: Allow all days
    if (tripEnd != null && tripEnd.isBefore(today)) {
      return 1;
    }

    // Future trip: Start from day 1
    if (today.isBefore(tripStart)) {
      return 1;
    }

    // Ongoing trip: Start from today's day number
    final currentDay = today.difference(tripStart).inDays + 1;
    final totalDays = _getTripDays(_selectedTrip!);

    // Ensure we don't go beyond trip duration
    return currentDay > totalDays ? totalDays : currentDay;
  }

  /// Get valid days for the selected trip
  List<int> _getValidDays() {
    final totalDays = _getTripDays(_selectedTrip!);
    final firstValid = _getFirstValidDay();

    // For past trips or when firstValid is 1, show all days
    if (firstValid == 1) {
      return List.generate(totalDays, (index) => index + 1);
    }

    // For ongoing trips, show from current day to end
    final remainingDays = totalDays - firstValid + 1;
    if (remainingDays <= 0) {
      // Trip has ended, show all days
      return List.generate(totalDays, (index) => index + 1);
    }

    return List.generate(remainingDays, (index) => firstValid + index);
  }

  /// Check if a day is in the past
  bool _isDayPast(int dayNumber) {
    if (_selectedTrip?.startDate == null) return false;

    final dayDate = _getDateForDay(dayNumber);
    if (dayDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dayDate.year, dayDate.month, dayDate.day);

    return day.isBefore(today);
  }
}
