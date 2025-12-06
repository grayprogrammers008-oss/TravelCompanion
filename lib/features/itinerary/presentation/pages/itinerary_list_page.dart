import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../../shared/models/itinerary_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/itinerary_providers.dart';
import '../widgets/timeline_view.dart';

class ItineraryListPage extends ConsumerStatefulWidget {
  final String tripId;

  const ItineraryListPage({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<ItineraryListPage> createState() => _ItineraryListPageState();
}

class _ItineraryListPageState extends ConsumerState<ItineraryListPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isTimelineView = false; // Toggle between cards and timeline view

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Calculate today's day number based on trip start date
  /// Returns null if trip hasn't started yet or has ended
  int? _getTodaysDayNumber(DateTime? tripStartDate, DateTime? tripEndDate) {
    if (tripStartDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(tripStartDate.year, tripStartDate.month, tripStartDate.day);

    // Check if trip has started
    if (today.isBefore(startDay)) return null;

    // Check if trip has ended (if end date is set)
    if (tripEndDate != null) {
      final endDay = DateTime(tripEndDate.year, tripEndDate.month, tripEndDate.day);
      if (today.isAfter(endDay)) return null;
    }

    // Calculate day number (1-based)
    return today.difference(startDay).inDays + 1;
  }

  /// Get the actual date for a day number
  DateTime? _getDateForDay(int dayNumber, DateTime? tripStartDate) {
    if (tripStartDate == null) return null;
    return tripStartDate.add(Duration(days: dayNumber - 1));
  }

  /// Filter itinerary days based on search query
  List<ItineraryDay> _filterDays(List<ItineraryDay> days) {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return days;
    }

    // Filter days to only include items matching the search
    return days.map((day) {
      final filteredItems = day.items.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final locationMatch = item.location?.toLowerCase().contains(query) ?? false;
        final descriptionMatch = item.description?.toLowerCase().contains(query) ?? false;
        return titleMatch || locationMatch || descriptionMatch;
      }).toList();

      return ItineraryDay(
        dayNumber: day.dayNumber,
        items: filteredItems,
      );
    }).where((day) => day.items.isNotEmpty).toList(); // Remove empty days
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final itineraryAsync = ref.watch(itineraryByDaysProvider(widget.tripId));
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final currentUserId = ref.watch(authStateProvider).value;

    // Check edit permissions
    final canEditItinerary = tripAsync.whenOrNull(
      data: (tripWithMembers) => TripPermissions.canEditItinerary(
        currentUserId: currentUserId,
        tripWithMembers: tripWithMembers,
      ),
    ) ?? false;

    // Get today's day number from trip data
    final todaysDayNumber = tripAsync.whenOrNull(
      data: (tripWithMembers) => _getTodaysDayNumber(
        tripWithMembers.trip.startDate,
        tripWithMembers.trip.endDate,
      ),
    );
    final tripStartDate = tripAsync.whenOrNull(
      data: (tripWithMembers) => tripWithMembers.trip.startDate,
    );

    // Listen for success/error messages
    ref.listen<ItineraryState>(itineraryControllerProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: context.successColor,
          ),
        );
        ref.read(itineraryControllerProvider.notifier).clearSuccessMessage();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: context.errorColor,
          ),
        );
        ref.read(itineraryControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop, otherwise go to trip detail
            if (context.canPop()) {
              context.pop();
            } else {
              // Navigate to trip detail page if no history
              context.go('/trips/${widget.tripId}');
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search activities...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Itinerary'),
        elevation: 0,
        actions: [
          // View toggle button (Cards vs Timeline)
          IconButton(
            icon: Icon(_isTimelineView ? Icons.view_agenda : Icons.view_timeline),
            tooltip: _isTimelineView ? 'Card View' : 'Timeline View',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isTimelineView = !_isTimelineView;
              });
            },
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          // AI Generate button
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate with AI',
            onPressed: () => _navigateToAiGenerator(context),
          ),
        ],
      ),
      body: itineraryAsync.when(
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading itinerary...'),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: context.errorColor),
              const SizedBox(height: 16),
              Text(
                'Error loading itinerary',
                style: context.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: context.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(itineraryByDaysProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (days) {
          if (days.isEmpty) {
            return _buildEmptyState(context);
          }

          // Apply search filter
          final filteredDays = _filterDays(days);

          // Show "no results" if search returns nothing
          if (filteredDays.isEmpty && _searchController.text.isNotEmpty) {
            return _buildNoSearchResults(context);
          }

          // Timeline View
          if (_isTimelineView) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(itineraryByDaysProvider);
              },
              child: TimelineView(
                days: filteredDays,
                initialDay: todaysDayNumber ?? 1,
                todaysDayNumber: todaysDayNumber,
                tripStartDate: tripStartDate,
                canEdit: canEditItinerary,
                onItemTap: (item) => _navigateToEditItem(context, item.id),
              ),
            );
          }

          // Card View (default)
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(itineraryByDaysProvider);
            },
            child: StaggeredListAnimation(
              itemCount: filteredDays.length,
              itemBuilder: (context, index) {
                final day = filteredDays[index];
                final isToday = todaysDayNumber != null && day.dayNumber == todaysDayNumber;
                final dayDate = _getDateForDay(day.dayNumber, tripStartDate);
                return _buildDaySection(context, ref, day, isToday: isToday, dayDate: dayDate, canEdit: canEditItinerary);
              },
            ),
          );
        },
      ),
      // Only show FAB if user can edit itinerary
      floatingActionButton: canEditItinerary
          ? ScaleAnimation(
              duration: AppAnimations.slow,
              curve: AppAnimations.spring,
              child: AnimatedScaleButton(
                onTap: () => _navigateToAddItem(context),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: themeData.glossyGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: themeData.glossyShadow,
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: null, // Handled by AnimatedScaleButton
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: Icon(Icons.add, color: context.primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 24),
                    label: Text(
                      'Add Activity',
                      style: TextStyle(
                        color: context.primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note_outlined,
                size: 120,
                color: context.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Activities Yet',
                style: context.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start planning your trip by adding activities to your itinerary',
                style: context.bodyLarge.copyWith(
                  color: context.textColor.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // AI Generate button - primary action
              ElevatedButton.icon(
                onPressed: () => _navigateToAiGenerator(context),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate with AI'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              // Manual add button - secondary action
              OutlinedButton.icon(
                onPressed: () => _navigateToAddItem(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Manually'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 120,
                color: context.textColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'No Activities Found',
                style: context.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try searching with different keywords',
                style: context.bodyLarge.copyWith(
                  color: context.textColor.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _isSearching = false;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    WidgetRef ref,
    ItineraryDay day, {
    bool isToday = false,
    DateTime? dayDate,
    bool canEdit = false,
  }) {
    // Colors for today highlighting
    final todayColor = Colors.orange;
    final headerColor = isToday ? todayColor : context.primaryColor;
    final headerBgColor = isToday
        ? todayColor.withValues(alpha: 0.15)
        : context.primaryColor.withValues(alpha: 0.1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: isToday
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: todayColor, width: 2),
            )
          : null,
      elevation: isToday ? 4 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isToday ? Icons.today : Icons.calendar_today,
                  size: 20,
                  color: headerColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Day ${day.dayNumber}',
                            style: context.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: headerColor,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: todayColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (dayDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM d').format(dayDate),
                          style: context.bodySmall.copyWith(
                            color: headerColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${day.items.length} ${day.items.length == 1 ? 'activity' : 'activities'}',
                  style: context.bodyMedium.copyWith(
                    color: headerColor,
                  ),
                ),
              ],
            ),
          ),

          // Day Items
          if (canEdit)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: day.items.length,
              onReorder: (oldIndex, newIndex) {
                _handleReorder(ref, day, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final item = day.items[index];
                return _buildItineraryItem(context, ref, item, key: ValueKey(item.id), canEdit: canEdit);
              },
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: day.items.length,
              itemBuilder: (context, index) {
                final item = day.items[index];
                return _buildItineraryItem(context, ref, item, key: ValueKey(item.id), canEdit: canEdit);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(
    BuildContext context,
    WidgetRef ref,
    ItineraryItemModel item, {
    Key? key,
    bool canEdit = false,
  }) {
    // Build the item content widget
    final itemContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time indicator
          if (item.startTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat.Hm().format(item.startTime!),
                style: context.bodySmall.copyWith(
                  color: context.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const SizedBox(width: 52),

          const SizedBox(width: 12),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location!,
                          style: context.bodyMedium.copyWith(
                            color: context.textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: context.bodyMedium.copyWith(
                      color: context.textColor.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.endTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Until ${DateFormat.Hm().format(item.endTime!)}',
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reorder handle - only show if can edit
          if (canEdit)
            Icon(
              Icons.drag_handle,
              color: context.textColor.withValues(alpha: 0.3),
            ),
        ],
      ),
    );

    // If user can edit, wrap with Dismissible for swipe-to-delete
    if (canEdit) {
      return Dismissible(
        key: key ?? ValueKey(item.id),
        background: Container(
          color: context.errorColor,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Activity'),
              content: const Text('Are you sure you want to delete this activity?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: context.errorColor),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          ref.read(itineraryControllerProvider.notifier).deleteItem(item.id);
        },
        child: InkWell(
          onTap: () => _navigateToEditItem(context, item.id),
          child: itemContent,
        ),
      );
    }

    // Read-only view for members without edit permission
    return Container(
      key: key ?? ValueKey(item.id),
      child: itemContent,
    );
  }

  void _handleReorder(WidgetRef ref, ItineraryDay day, int oldIndex, int newIndex) {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create new order
    final items = List<ItineraryItemModel>.from(day.items);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Extract item IDs in new order
    final itemIds = items.map((item) => item.id).toList();

    // Call reorder use case
    ref.read(itineraryControllerProvider.notifier).reorderItems(
          tripId: widget.tripId,
          dayNumber: day.dayNumber,
          itemIds: itemIds,
        );
  }

  void _navigateToAddItem(BuildContext context) {
    context.push('/trips/${widget.tripId}/itinerary/add');
  }

  void _navigateToEditItem(BuildContext context, String itemId) {
    context.push('/trips/${widget.tripId}/itinerary/$itemId/edit');
  }

  void _navigateToAiGenerator(BuildContext context) {
    // Get trip data to pre-fill the AI generator
    final tripAsync = ref.read(tripProvider(widget.tripId));

    final queryParams = <String, String>{
      'tripId': widget.tripId,
    };

    tripAsync.whenData((tripData) {
      final trip = tripData.trip;
      if (trip.destination != null && trip.destination!.isNotEmpty) {
        queryParams['destination'] = trip.destination!;
      }
      if (trip.startDate != null) {
        queryParams['startDate'] = trip.startDate!.toIso8601String();
      }
      if (trip.endDate != null) {
        queryParams['endDate'] = trip.endDate!.toIso8601String();
      }
      if (trip.budget != null) {
        queryParams['budget'] = trip.budget.toString();
      }
    });

    final uri = Uri(path: '/ai-itinerary', queryParameters: queryParams);
    context.push(uri.toString());
  }
}
