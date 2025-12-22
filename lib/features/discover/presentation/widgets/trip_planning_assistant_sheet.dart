import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/trip_plan.dart';
import '../providers/discover_providers.dart';

/// Bottom sheet for the AI-powered Trip Planning Assistant
class TripPlanningAssistantSheet extends ConsumerStatefulWidget {
  const TripPlanningAssistantSheet({super.key});

  /// Shows the trip planning assistant sheet
  static Future<bool?> show(BuildContext context) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TripPlanningAssistantSheet(),
    );
  }

  @override
  ConsumerState<TripPlanningAssistantSheet> createState() =>
      _TripPlanningAssistantSheetState();
}

class _TripPlanningAssistantSheetState
    extends ConsumerState<TripPlanningAssistantSheet> {
  // Steps: 0 = select places, 1 = select trip, 2 = configure preferences, 3 = review plan
  int _currentStep = 0;
  final Set<String> _selectedPlaceIds = {};
  TripModel? _selectedTrip;
  TripPlanPreferences _preferences = const TripPlanPreferences();
  GeneratedTripPlan? _generatedPlan;
  bool _isGenerating = false;
  bool _isAddingToTrip = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              _buildHeader(context),
              // Progress indicator
              _buildProgressIndicator(context),
              // Content
              Expanded(
                child: _buildStepContent(context, scrollController),
              ),
              // Action buttons
              _buildActionButtons(context),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Planning Assistant',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStepTitle(),
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select places from your favorites';
      case 1:
        return 'Choose a trip to add activities';
      case 2:
        return 'Set your travel preferences';
      case 3:
        return 'Review your generated itinerary';
      default:
        return '';
    }
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isComplete = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? (isComplete ? Colors.green : context.primaryColor)
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, ScrollController scrollController) {
    switch (_currentStep) {
      case 0:
        return _buildPlaceSelectionStep(context, scrollController);
      case 1:
        return _buildTripSelectionStep(context, scrollController);
      case 2:
        return _buildPreferencesStep(context, scrollController);
      case 3:
        return _buildReviewStep(context, scrollController);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: Select places from favorites
  Widget _buildPlaceSelectionStep(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final discoverState = ref.watch(discoverStateProvider);
    final favoriteIds = discoverState.favoriteIds;

    // Get favorite places from the current places list
    final favoritePlaces = discoverState.places
        .where((p) => favoriteIds.contains(p.placeId))
        .toList();

    if (favoritePlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No Favorites Yet',
                style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add places to your favorites first, then use the planning assistant to create a smart itinerary.',
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: context.textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.explore),
                label: const Text('Explore Places'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: context.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_selectedPlaceIds.length} of ${favoritePlaces.length} selected',
                style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedPlaceIds.length == favoritePlaces.length) {
                      _selectedPlaceIds.clear();
                    } else {
                      _selectedPlaceIds.addAll(favoritePlaces.map((p) => p.placeId));
                    }
                  });
                },
                child: Text(
                  _selectedPlaceIds.length == favoritePlaces.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favoritePlaces.length,
            itemBuilder: (context, index) {
              final place = favoritePlaces[index];
              final isSelected = _selectedPlaceIds.contains(place.placeId);

              return _buildPlaceSelectionCard(context, place, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceSelectionCard(
    BuildContext context,
    DiscoverPlace place,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? context.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            if (isSelected) {
              _selectedPlaceIds.remove(place.placeId);
            } else {
              _selectedPlaceIds.add(place.placeId);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? context.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? context.primaryColor : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: place.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  place.category.icon,
                  color: place.category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: place.category.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            place.category.displayName,
                            style: context.bodySmall.copyWith(
                              color: place.category.color,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (place.rating != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 12, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            place.ratingText,
                            style: context.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 1: Select trip
  Widget _buildTripSelectionStep(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final tripsAsync = ref.watch(userTripsProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 12),
            Text('Error loading trips: $error'),
          ],
        ),
      ),
      data: (trips) {
        // Filter to active trips only
        final activeTrips = trips.where((t) => !t.trip.isCompleted).toList();

        if (activeTrips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 64,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Trips',
                    style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a trip first to use the planning assistant.',
                    textAlign: TextAlign.center,
                    style: context.bodyMedium.copyWith(
                      color: context.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: activeTrips.length,
          itemBuilder: (context, index) {
            final tripWithMembers = activeTrips[index];
            final trip = tripWithMembers.trip;
            final isSelected = _selectedTrip?.id == trip.id;

            return _buildTripCard(context, trip, isSelected);
          },
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip, bool isSelected) {
    final daysCount = trip.startDate != null && trip.endDate != null
        ? trip.endDate!.difference(trip.startDate!).inDays + 1
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? context.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTrip = trip);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Trip icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flight,
                  color: context.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Trip info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name,
                      style: context.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (trip.destination != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: context.textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trip.destination!,
                              style: context.bodySmall.copyWith(
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (trip.startDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: context.textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(trip.startDate!),
                            style: context.bodySmall.copyWith(
                              color: context.textColor.withValues(alpha: 0.6),
                            ),
                          ),
                          if (daysCount != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$daysCount days',
                                style: context.bodySmall.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Selection indicator
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 2: Configure preferences
  Widget _buildPreferencesStep(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Pace selection
        Text(
          'Travel Pace',
          style: context.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: TripPace.values.map((pace) {
            final isSelected = _preferences.pace == pace;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: pace != TripPace.packed ? 8 : 0,
                ),
                child: _buildPaceCard(context, pace, isSelected),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Time preferences
        Text(
          'Daily Schedule',
          style: context.titleSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTimeRow(
                  context,
                  'Start Time',
                  _preferences.startTime,
                  (time) {
                    if (time != null) {
                      setState(() {
                        _preferences = _preferences.copyWith(startTime: time);
                      });
                    }
                  },
                ),
                const Divider(height: 24),
                _buildTimeRow(
                  context,
                  'End Time',
                  _preferences.endTime,
                  (time) {
                    if (time != null) {
                      setState(() {
                        _preferences = _preferences.copyWith(endTime: time);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Breaks
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: const Text('Include Lunch Break'),
            subtitle: Text('1 hour break around noon'),
            value: _preferences.includeBreaks,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(includeBreaks: value);
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: context.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Planning Summary',
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedPlaceIds.length} places selected',
                style: context.bodySmall,
              ),
              Text(
                '~${_preferences.activeHours.toStringAsFixed(1)} active hours per day',
                style: context.bodySmall,
              ),
              Text(
                '${_preferences.pace.activitiesPerDay} activities per day (${_preferences.pace.displayName})',
                style: context.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaceCard(BuildContext context, TripPace pace, bool isSelected) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? pace.color : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _preferences = _preferences.copyWith(pace: pace);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(pace.icon, color: pace.color, size: 28),
              const SizedBox(height: 8),
              Text(
                pace.displayName,
                style: context.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pace.description,
                style: context.bodySmall.copyWith(
                  color: context.textColor.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    TimeOfDay time,
    Function(TimeOfDay?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        onChanged(newTime);
      },
      child: Row(
        children: [
          Icon(Icons.access_time, color: context.primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(label, style: context.bodyMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time.format(context),
              style: context.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 3: Review generated plan
  Widget _buildReviewStep(
    BuildContext context,
    ScrollController scrollController,
  ) {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Creating your perfect itinerary...',
              style: context.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Optimizing routes and scheduling activities',
              style: context.bodyMedium.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_generatedPlan == null) {
      return const Center(child: Text('No plan generated'));
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Your Itinerary',
                    style: context.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSummaryChip(
                    context,
                    '${_generatedPlan!.days.length} Days',
                    Icons.calendar_today,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryChip(
                    context,
                    '${_generatedPlan!.totalActivities} Activities',
                    Icons.place,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Days
        ..._generatedPlan!.days.map((day) => _buildDayCard(context, day)),

        // Unscheduled places
        if (_generatedPlan!.unscheduledPlaces.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_generatedPlan!.unscheduledPlaces.length} places not scheduled',
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Add more days or increase pace to include all places.',
                  style: context.bodySmall.copyWith(
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, PlannedDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Day ${day.dayNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.theme ?? '',
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${day.activityCount} activities',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Activities
          ...day.activities.map((activity) => _buildActivityRow(context, activity)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(BuildContext context, PlannedActivity activity) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.suggestedStartTime.format(context),
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  activity.durationText,
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Connector
          Container(
            width: 2,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: activity.place.category.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Activity info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      activity.place.category.icon,
                      size: 16,
                      color: activity.place.category.color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activity.place.name,
                        style: context.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (activity.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.notes!,
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          // Next/Generate/Add button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _getNextAction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 3 ? Colors.green : null,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isAddingToTrip
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_getNextButtonLabel()),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Continue (${_selectedPlaceIds.length} selected)';
      case 1:
        return 'Configure Preferences';
      case 2:
        return 'Generate Itinerary';
      case 3:
        return 'Add to Trip';
      default:
        return 'Next';
    }
  }

  VoidCallback? _getNextAction() {
    switch (_currentStep) {
      case 0:
        return _selectedPlaceIds.isEmpty
            ? null
            : () => setState(() => _currentStep = 1);
      case 1:
        return _selectedTrip == null
            ? null
            : () => setState(() => _currentStep = 2);
      case 2:
        return _generatePlan;
      case 3:
        return _isAddingToTrip ? null : _addPlanToTrip;
      default:
        return null;
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _currentStep = 3;
      _isGenerating = true;
    });

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 800));

    final discoverState = ref.read(discoverStateProvider);
    final selectedPlaces = discoverState.places
        .where((p) => _selectedPlaceIds.contains(p.placeId))
        .toList();

    final numberOfDays = _selectedTrip?.startDate != null &&
            _selectedTrip?.endDate != null
        ? _selectedTrip!.endDate!.difference(_selectedTrip!.startDate!).inDays + 1
        : 3;

    final plan = TripPlanEngine.generatePlan(
      places: selectedPlaces,
      numberOfDays: numberOfDays,
      preferences: _preferences,
      userLatitude: discoverState.userLatitude,
      userLongitude: discoverState.userLongitude,
    );

    setState(() {
      _generatedPlan = plan;
      _isGenerating = false;
    });
  }

  Future<void> _addPlanToTrip() async {
    if (_generatedPlan == null || _selectedTrip == null) return;

    setState(() => _isAddingToTrip = true);

    try {
      final controller = ref.read(itineraryControllerProvider.notifier);

      for (final day in _generatedPlan!.days) {
        for (final activity in day.activities) {
          // Calculate start time
          DateTime? startTime;
          if (_selectedTrip!.startDate != null) {
            final tripStart = _selectedTrip!.startDate!;
            final dayDate = tripStart.add(Duration(days: day.dayNumber - 1));
            startTime = DateTime(
              dayDate.year,
              dayDate.month,
              dayDate.day,
              activity.suggestedStartTime.hour,
              activity.suggestedStartTime.minute,
            );
          }

          await controller.createItem(
            tripId: _selectedTrip!.id,
            title: activity.place.name,
            location: activity.place.vicinity,
            latitude: activity.place.latitude,
            longitude: activity.place.longitude,
            placeId: activity.place.placeId,
            dayNumber: day.dayNumber,
            startTime: startTime,
            description: activity.notes,
            orderIndex: activity.orderIndex,
          );
        }
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_generatedPlan!.totalActivities} activities added to ${_selectedTrip!.name}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToTrip = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add activities: $e'),
            backgroundColor: context.errorColor,
          ),
        );
      }
    }
  }
}
