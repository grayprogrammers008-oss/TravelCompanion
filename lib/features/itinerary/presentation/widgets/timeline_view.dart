import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/models/itinerary_model.dart';

/// Activity status based on current time
enum ActivityStatus {
  completed,
  current,
  upcoming,
}

/// Visual Timeline View for displaying itinerary items
/// Shows activities in a vertical timeline with time markers and status indicators
class TimelineView extends StatefulWidget {
  final List<ItineraryDay> days;
  final int initialDay;
  final int? todaysDayNumber;
  final DateTime? tripStartDate;
  final bool canEdit;
  final Function(ItineraryItemModel item)? onItemTap;
  final Function(ItineraryItemModel item)? onItemDelete;

  const TimelineView({
    super.key,
    required this.days,
    this.initialDay = 1,
    this.todaysDayNumber,
    this.tripStartDate,
    this.canEdit = false,
    this.onItemTap,
    this.onItemDelete,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late PageController _pageController;
  late int _currentDayIndex;

  @override
  void initState() {
    super.initState();
    // Find initial day index
    _currentDayIndex = widget.days.indexWhere((d) => d.dayNumber == widget.initialDay);
    if (_currentDayIndex < 0) _currentDayIndex = 0;
    _pageController = PageController(initialPage: _currentDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Get the actual date for a day number
  DateTime? _getDateForDay(int dayNumber) {
    if (widget.tripStartDate == null) return null;
    return widget.tripStartDate!.add(Duration(days: dayNumber - 1));
  }

  /// Determine activity status based on current time
  ActivityStatus _getActivityStatus(ItineraryItemModel item, bool isToday) {
    if (!isToday) {
      // If not today, check if this day is in the past or future
      final dayDate = _getDateForDay(item.dayNumber ?? 1);
      if (dayDate != null) {
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final dayOnly = DateTime(dayDate.year, dayDate.month, dayDate.day);

        if (dayOnly.isBefore(todayOnly)) return ActivityStatus.completed;
        if (dayOnly.isAfter(todayOnly)) return ActivityStatus.upcoming;
      }
      return ActivityStatus.upcoming;
    }

    // For today, check against current time
    final now = DateTime.now();

    if (item.startTime == null) {
      return ActivityStatus.upcoming;
    }

    final itemStart = item.startTime!;
    final itemEnd = item.endTime;

    // If current time is before start time
    if (now.isBefore(itemStart)) {
      return ActivityStatus.upcoming;
    }

    // If current time is after end time (or 1 hour after start if no end)
    final effectiveEnd = itemEnd ?? itemStart.add(const Duration(hours: 1));
    if (now.isAfter(effectiveEnd)) {
      return ActivityStatus.completed;
    }

    // Currently happening
    return ActivityStatus.current;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) {
      return const Center(
        child: Text('No activities yet'),
      );
    }

    return Column(
      children: [
        // Day navigation header
        _buildDayNavigationHeader(context),

        // Timeline content with swipe
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _currentDayIndex = index;
              });
            },
            itemCount: widget.days.length,
            itemBuilder: (context, index) {
              final day = widget.days[index];
              final isToday = widget.todaysDayNumber == day.dayNumber;
              final dayDate = _getDateForDay(day.dayNumber);

              return _buildDayTimeline(context, day, isToday, dayDate);
            },
          ),
        ),
      ],
    );
  }

  /// Build the day navigation header with left/right arrows
  Widget _buildDayNavigationHeader(BuildContext context) {
    final currentDay = widget.days[_currentDayIndex];
    final isToday = widget.todaysDayNumber == currentDay.dayNumber;
    final dayDate = _getDateForDay(currentDay.dayNumber);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.orange.withValues(alpha: 0.1)
            : context.primaryColor.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: isToday ? Colors.orange : context.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left arrow
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: _currentDayIndex > 0
                  ? context.textColor
                  : context.textColor.withValues(alpha: 0.3),
            ),
            onPressed: _currentDayIndex > 0
                ? () {
                    HapticFeedback.selectionClick();
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),

          // Day info (centered)
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Day ${currentDay.dayNumber}',
                      style: context.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.orange : context.textColor,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
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
                if (dayDate != null)
                  Text(
                    DateFormat('EEEE, MMMM d').format(dayDate),
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),

          // Right arrow
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _currentDayIndex < widget.days.length - 1
                  ? context.textColor
                  : context.textColor.withValues(alpha: 0.3),
            ),
            onPressed: _currentDayIndex < widget.days.length - 1
                ? () {
                    HapticFeedback.selectionClick();
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// Build the timeline for a single day
  Widget _buildDayTimeline(
    BuildContext context,
    ItineraryDay day,
    bool isToday,
    DateTime? dayDate,
  ) {
    if (day.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: context.textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No activities for Day ${day.dayNumber}',
              style: context.bodyLarge.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Sort items by start time
    final sortedItems = List<ItineraryItemModel>.from(day.items);
    sortedItems.sort((a, b) {
      if (a.startTime == null && b.startTime == null) {
        return a.orderIndex.compareTo(b.orderIndex);
      }
      if (a.startTime == null) return 1;
      if (b.startTime == null) return -1;
      return a.startTime!.compareTo(b.startTime!);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        final status = _getActivityStatus(item, isToday);
        final isLast = index == sortedItems.length - 1;

        return _buildTimelineItem(context, item, status, isLast, isToday);
      },
    );
  }

  /// Build a single timeline item with connector line
  Widget _buildTimelineItem(
    BuildContext context,
    ItineraryItemModel item,
    ActivityStatus status,
    bool isLast,
    bool isToday,
  ) {
    // Colors based on status
    final Color dotColor;
    final Color lineColor;
    final Color bgColor;

    switch (status) {
      case ActivityStatus.completed:
        dotColor = Colors.green;
        lineColor = Colors.green.withValues(alpha: 0.3);
        bgColor = Colors.green.withValues(alpha: 0.05);
        break;
      case ActivityStatus.current:
        dotColor = Colors.orange;
        lineColor = Colors.orange.withValues(alpha: 0.3);
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case ActivityStatus.upcoming:
        dotColor = context.textColor.withValues(alpha: 0.4);
        lineColor = context.textColor.withValues(alpha: 0.15);
        bgColor = Colors.transparent;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: item.startTime != null
                ? Text(
                    DateFormat('HH:mm').format(item.startTime!),
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: status == ActivityStatus.current
                          ? Colors.orange
                          : context.textColor.withValues(alpha: 0.7),
                    ),
                  )
                : Text(
                    '—',
                    style: context.bodyMedium.copyWith(
                      color: context.textColor.withValues(alpha: 0.3),
                    ),
                  ),
          ),

          // Timeline connector (dot + line)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Status dot/icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: status == ActivityStatus.current
                        ? dotColor
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: status == ActivityStatus.current ? 0 : 2,
                    ),
                    boxShadow: status == ActivityStatus.current
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: status == ActivityStatus.completed
                      ? Icon(Icons.check, size: 14, color: dotColor)
                      : status == ActivityStatus.current
                          ? const Icon(Icons.circle, size: 8, color: Colors.white)
                          : null,
                ),

                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),

          // Activity content
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (widget.onItemTap != null) {
                  HapticFeedback.lightImpact();
                  widget.onItemTap!(item);
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: status == ActivityStatus.current
                      ? Border.all(color: Colors.orange, width: 2)
                      : Border.all(
                          color: context.textColor.withValues(alpha: 0.1),
                          width: 1,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOW badge for current activity
                    if (status == ActivityStatus.current) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Title
                    Text(
                      item.title,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: status == ActivityStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: status == ActivityStatus.completed
                            ? context.textColor.withValues(alpha: 0.6)
                            : context.textColor,
                      ),
                    ),

                    // Location
                    if (item.location != null && item.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: context.textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location!,
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

                    // Description
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description!,
                        style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // End time
                    if (item.endTime != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: context.textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Until ${DateFormat('HH:mm').format(item.endTime!)}',
                            style: context.bodySmall.copyWith(
                              color: context.textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
