import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/voice_input_bottom_sheet.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../../core/services/google_maps_url_parser.dart';
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
  bool _isTimelineView = false; // Toggle between cards and timeline view
  bool _isFabExpanded = false;

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
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips/${widget.tripId}');
            }
          },
        ),
        title: const Text('Itinerary'),
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
          // AI Generate button
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate with AI',
            onPressed: () => _navigateToAiGenerator(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              0,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search activities...',
                  hintStyle: TextStyle(
                    color: AppTheme.neutral400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.neutral400,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppTheme.neutral400,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
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
                return _buildDaySection(context, ref, day, isToday: isToday, dayDate: dayDate, canEdit: canEditItinerary, allDays: filteredDays);
              },
            ),
          );
        },
      ),
      // Only show FAB if user can edit itinerary
      floatingActionButton: canEditItinerary
          ? _buildExpandableFab(context, themeData)
          : null,
    );
  }

  Widget _buildExpandableFab(BuildContext context, dynamic themeData) {
    final textColor = context.primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Voice input option
        if (_isFabExpanded) ...[
          _buildFabOption(
            context: context,
            icon: Icons.mic,
            label: 'Voice Input',
            color: const Color(0xFF00D9FF),
            onTap: () {
              setState(() => _isFabExpanded = false);
              _showVoiceInput(context);
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            context: context,
            icon: Icons.map,
            label: 'Paste from Maps',
            color: Colors.teal,
            onTap: () {
              setState(() => _isFabExpanded = false);
              _pasteFromMaps(context);
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            context: context,
            icon: Icons.edit,
            label: 'Add Manually',
            color: context.primaryColor,
            onTap: () {
              setState(() => _isFabExpanded = false);
              _navigateToAddItem(context);
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            context: context,
            icon: Icons.auto_awesome,
            label: 'AI Generate',
            color: Colors.purple,
            onTap: () {
              setState(() => _isFabExpanded = false);
              _navigateToAiGenerator(context);
            },
          ),
          const SizedBox(height: 16),
        ],
        // Main FAB
        ScaleAnimation(
          duration: AppAnimations.slow,
          curve: AppAnimations.spring,
          child: AnimatedScaleButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isFabExpanded = !_isFabExpanded);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: themeData.glossyGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: themeData.glossyShadow,
              ),
              child: FloatingActionButton.extended(
                onPressed: null,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: AnimatedRotation(
                  turns: _isFabExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.add, color: textColor, size: 24),
                ),
                label: Text(
                  _isFabExpanded ? 'Close' : 'Add Activity',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showVoiceInput(BuildContext context) async {
    final voiceText = await VoiceInputBottomSheet.show(
      context: context,
      title: 'Plan with AI Voice',
      hintText: 'Describe what you want to do',
      exampleText: 'I want to explore temples and beaches, have local food',
      icon: Icons.auto_awesome,
      primaryColor: const Color(0xFF00D9FF),
      demoPhrase: 'I want to visit temples in the morning, try local seafood for lunch, and watch sunset at the beach',
    );

    if (voiceText != null && voiceText.isNotEmpty && mounted) {
      // Navigate to AI generator with voice input as additional context
      _navigateToAiGeneratorWithVoice(context, voiceText);
    }
  }

  /// Paste a Google Maps URL from clipboard and add as itinerary item
  Future<void> _pasteFromMaps(BuildContext context) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text;

    if (text == null || text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty. Copy a Google Maps link first.'),
          ),
        );
      }
      return;
    }

    // Try to extract a Google Maps URL from the clipboard
    final url = GoogleMapsUrlParser.extractUrl(text);
    if (url == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No Google Maps link found in clipboard'),
          ),
        );
      }
      return;
    }

    final parsedLocation = GoogleMapsUrlParser.parse(url);
    if (parsedLocation != null && context.mounted) {
      // Show add dialog with pre-filled location
      _showAddFromMapsDialog(context, parsedLocation);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not parse the Google Maps link'),
        ),
      );
    }
  }

  /// Show dialog to add location from Google Maps
  void _showAddFromMapsDialog(BuildContext context, ParsedLocation location) {
    final titleController = TextEditingController(
      text: location.placeName ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade50,
                    Colors.teal.shade100.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.teal.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Google Maps badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.map,
                                size: 16,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Google Maps',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (location.hasCoordinates)
                        Icon(
                          Icons.verified,
                          size: 18,
                          color: Colors.teal.shade600,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.placeName ?? 'Location',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (location.hasCoordinates) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${location.latitude!.toStringAsFixed(6)}, ${location.longitude!.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Open in Maps button
                  if (location.hasCoordinates) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 14,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Open in Google Maps',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title input
            Text(
              'Activity Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: location.placeName ?? 'e.g., Visit Marina Beach',
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: location.placeName == null,
            ),
            const SizedBox(height: 20),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  var title = titleController.text.trim();
                  if (title.isEmpty) {
                    title = location.placeName ?? 'New Location';
                  }

                  Navigator.pop(context);

                  try {
                    final controller = ref.read(itineraryControllerProvider.notifier);
                    await controller.createItem(
                      tripId: widget.tripId,
                      title: title,
                      location: location.placeName,
                      latitude: location.latitude,
                      longitude: location.longitude,
                    );

                    if (mounted) {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Added "$title" to itinerary')),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add to Itinerary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToAiGeneratorWithVoice(BuildContext context, String voicePrompt) {
    // Get trip data to pre-fill the AI generator
    final tripAsync = ref.read(tripProvider(widget.tripId));

    final queryParams = <String, String>{
      'tripId': widget.tripId,
      'voicePrompt': voicePrompt, // Pass voice input as additional context
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
      if (trip.cost != null) {
        queryParams['budget'] = trip.cost.toString();
      }
    });

    final uri = Uri(path: '/ai-itinerary', queryParameters: queryParams);
    context.push(uri.toString());
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
    List<ItineraryDay> allDays = const [],
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
                HapticFeedback.mediumImpact();
                _handleReorder(ref, day, oldIndex, newIndex);
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final double elevation = Tween<double>(begin: 0, end: 8).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ).value;
                    final double scale = Tween<double>(begin: 1.0, end: 1.02).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ).value;
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        elevation: elevation,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        shadowColor: context.primaryColor.withValues(alpha: 0.3),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final item = day.items[index];
                return _buildItineraryItem(context, ref, item, key: ValueKey(item.id), canEdit: canEdit, currentDayNumber: day.dayNumber, allDays: allDays, itemIndex: index);
              },
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: day.items.length,
              itemBuilder: (context, index) {
                final item = day.items[index];
                return _buildItineraryItem(context, ref, item, key: ValueKey(item.id), canEdit: canEdit, currentDayNumber: day.dayNumber, allDays: allDays, itemIndex: index);
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
    int currentDayNumber = 1,
    List<ItineraryDay> allDays = const [],
    int itemIndex = 0,
  }) {
    // Build the item content widget
    final itemContent = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location image thumbnail or time indicator
          if (item.hasMapLocation)
            // Show location image
            GestureDetector(
              onTap: () => _openInMaps(context, item),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Use DestinationImage for location photo
                      DestinationImage(
                        destination: item.location ?? item.title,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                color: Colors.white,
                                size: 11,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'View Map',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Map pin icon overlay
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (item.startTime != null)
            // Time indicator for items without map
            Container(
              width: 52,
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
                textAlign: TextAlign.center,
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
                // Title with time badge if has map
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: context.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Show time badge next to title if has map location
                    if (item.hasMapLocation && item.startTime != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          DateFormat.Hm().format(item.startTime!),
                          style: context.bodySmall.copyWith(
                            color: context.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: item.hasMapLocation
                            ? Colors.teal
                            : context.textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location!,
                          style: context.bodySmall.copyWith(
                            color: item.hasMapLocation
                                ? Colors.teal.shade700
                                : context.textColor.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.endTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: context.textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Until ${DateFormat.Hm().format(item.endTime!)}',
                        style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

        ],
      ),
    );

    // If user can edit, wrap with Dismissible for swipe-to-delete and add long-press menu
    if (canEdit) {
      // Build item with drag handle that uses ReorderableDragStartListener
      final itemWithDragHandle = Row(
        key: key ?? ValueKey(item.id),
        children: [
          // Main content area - tappable and long-pressable
          Expanded(
            child: InkWell(
              onTap: () => _navigateToEditItem(context, item.id),
              onLongPress: () => _showItemOptionsMenu(context, ref, item, currentDayNumber: currentDayNumber, allDays: allDays),
              child: itemContent,
            ),
          ),
          // Drag handle - uses ReorderableDragStartListener for proper drag initiation
          ReorderableDragStartListener(
            index: itemIndex,
            child: _AnimatedDragHandle(primaryColor: context.primaryColor),
          ),
        ],
      );

      return Dismissible(
        key: key ?? ValueKey(item.id),
        background: Container(
          color: context.errorColor,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(width: 16),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          final confirmed = await _showDeleteConfirmation(context, item.title);
          if (confirmed) {
            // Perform deletion here before the widget is dismissed
            await ref.read(itineraryControllerProvider.notifier).deleteItem(item.id);
            if (context.mounted) {
              HapticFeedback.mediumImpact();
            }
          }
          return confirmed;
        },
        // onDismissed not needed since we handle deletion in confirmDismiss
        child: itemWithDragHandle,
      );
    }

    // Read-only view for members without edit permission
    return Container(
      key: key ?? ValueKey(item.id),
      child: InkWell(
        onTap: () => _navigateToEditItem(context, item.id),
        child: itemContent,
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context, String itemTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "$itemTitle"?'),
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
    ) ?? false;
  }

  /// Show options menu for an itinerary item (long-press)
  void _showItemOptionsMenu(
    BuildContext context,
    WidgetRef ref,
    ItineraryItemModel item, {
    int currentDayNumber = 1,
    List<ItineraryDay> allDays = const [],
  }) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),

            // Item title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.location != null)
                          Text(
                            item.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Edit option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.blue, size: 20),
              ),
              title: const Text('Edit Activity'),
              subtitle: const Text('Modify details, time, or location'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditItem(context, item.id);
              },
            ),

            // Open in Maps (if has coordinates)
            if (item.hasMapLocation)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map, color: Colors.teal, size: 20),
                ),
                title: const Text('Open in Maps'),
                subtitle: const Text('View location in Google Maps'),
                onTap: () {
                  Navigator.pop(context);
                  _openInMaps(context, item);
                },
              ),

            // Move to Day option (only show if there are multiple days)
            if (allDays.length > 1)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.swap_horiz, color: Colors.purple, size: 20),
                ),
                title: const Text('Move to Another Day'),
                subtitle: Text('Currently on Day $currentDayNumber'),
                onTap: () {
                  Navigator.pop(context);
                  _showMoveToDayDialog(context, ref, item, currentDayNumber: currentDayNumber, allDays: allDays);
                },
              ),

            // Delete option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
              title: const Text('Delete Activity', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Remove from itinerary'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _showDeleteConfirmation(context, item.title);
                if (confirmed && context.mounted) {
                  ref.read(itineraryControllerProvider.notifier).deleteItem(item.id);
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('"${item.title}" deleted')),
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
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show dialog to move item to another day
  void _showMoveToDayDialog(
    BuildContext context,
    WidgetRef ref,
    ItineraryItemModel item, {
    required int currentDayNumber,
    required List<ItineraryDay> allDays,
  }) {
    // Get available days (exclude current day)
    final availableDays = allDays.where((day) => day.dayNumber != currentDayNumber).toList();

    if (availableDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No other days available to move to'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Move to Day',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select destination for "${item.title}"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // Day options
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableDays.length,
                itemBuilder: (context, index) {
                  final day = availableDays[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        '${day.dayNumber}',
                        style: TextStyle(
                          color: context.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('Day ${day.dayNumber}'),
                    subtitle: Text(
                      '${day.items.length} ${day.items.length == 1 ? 'activity' : 'activities'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();

                      try {
                        await ref.read(itineraryControllerProvider.notifier).moveItemToDay(
                          itemId: item.id,
                          newDayNumber: day.dayNumber,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Moved "${item.title}" to Day ${day.dayNumber}'),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('Failed to move activity')),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
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

  Future<void> _openInMaps(BuildContext context, ItineraryItemModel item) async {
    if (!item.hasMapLocation) return;

    // Use url_launcher to open in maps
    final url = 'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open maps')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
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
      if (trip.cost != null) {
        queryParams['budget'] = trip.cost.toString();
      }
    });

    final uri = Uri(path: '/ai-itinerary', queryParameters: queryParams);
    context.push(uri.toString());
  }
}

/// Animated drag handle widget with platform-specific icons
/// Shows 6-dot pattern (drag_indicator) on Android
/// Shows 3 horizontal lines (drag_handle) on iOS
class _AnimatedDragHandle extends StatefulWidget {
  final Color primaryColor;

  const _AnimatedDragHandle({required this.primaryColor});

  @override
  State<_AnimatedDragHandle> createState() => _AnimatedDragHandleState();
}

class _AnimatedDragHandleState extends State<_AnimatedDragHandle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start subtle pulse animation
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Opacity(
            opacity: _pulseAnimation.value,
            child: Icon(
              Platform.isIOS ? Icons.drag_handle : Icons.drag_indicator,
              color: widget.primaryColor.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
