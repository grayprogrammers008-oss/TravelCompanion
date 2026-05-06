import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/animations/animated_widgets.dart';
import 'package:travel_crew/core/widgets/app_loading_indicator.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_trip_history_usecase.dart';
import 'package:travel_crew/features/trips/domain/usecases/filter_trips_usecase.dart';
import '../../../../shared/models/trip_model.dart';
import 'package:intl/intl.dart';

/// Trip History Page - Shows completed trips with ratings and statistics
class TripHistoryPage extends ConsumerStatefulWidget {
  const TripHistoryPage({super.key});

  @override
  ConsumerState<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends ConsumerState<TripHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(tripHistoryProvider);
    final filteredTrips = ref.watch(filteredTripHistoryProvider);
    final filterParams = ref.watch(tripHistoryFilterProvider);
    final statistics = ref.watch(tripHistoryStatisticsProvider);
    final themeData = context.appThemeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        elevation: 0,
        actions: [
          // Filter button with badge when filters are active
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: Colors.white,
                ),
                onPressed: () => _showFilterBottomSheet(context, ref),
                tooltip: 'Filter & Sort',
              ),
              // Active filter indicator badge
              if (filterParams != const TripFilterParams())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: historyAsync.when(
        data: (completedTrips) {
          if (completedTrips.isEmpty) {
            return _buildEmptyState(context);
          }
          return Column(
            children: [
              // Statistics header - automatically updates when trips change
              _buildStatisticsHeader(context, statistics, themeData),
              const SizedBox(height: AppTheme.spacingMd),
              // Search bar
              _buildSearchBar(context, filterParams, themeData),
              const SizedBox(height: AppTheme.spacingMd),
              // Active filter chips
              if (filterParams.sortBy != TripSortBy.dateNewest ||
                  filterParams.minRating != null ||
                  (filterParams.searchQuery != null && filterParams.searchQuery!.isNotEmpty) ||
                  filterParams.customStartDate != null ||
                  filterParams.customEndDate != null)
                _buildActiveFilters(context, ref, filterParams, themeData),
              // Trip history list (filtered and sorted)
              Expanded(
                child: filteredTrips.isEmpty
                    ? _buildNoResultsState(context)
                    : _buildHistoryList(context, ref, filteredTrips),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(
            message: 'Loading trip history...',
          ),
        ),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildStatisticsHeader(
    BuildContext context,
    TripHistoryStatistics stats,
    themeData,
  ) {
    if (!stats.hasAnyTrips) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: themeData.glossyGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: themeData.glossyShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Travel Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context,
                'Total Trips',
                stats.totalCompletedTrips.toString(),
                Icons.flight_takeoff,
              ),
              _buildStatCard(
                context,
                'Avg Rating',
                stats.hasRatedTrips ? stats.formattedAverageRating : 'N/A',
                Icons.star,
              ),
              _buildStatCard(
                context,
                'Rated',
                '${stats.totalRatedTrips}/${stats.totalCompletedTrips}',
                Icons.rate_review,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spacing2xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    TripFilterParams filterParams,
    themeData,
  ) {
    // Sync controller with filter params (e.g., when cleared via chip)
    if (filterParams.searchQuery == null || filterParams.searchQuery!.isEmpty) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(tripHistoryFilterProvider.notifier).updateSearchQuery(
            value.isEmpty ? null : value,
          );
        },
        decoration: InputDecoration(
          hintText: 'Search trips by name, destination...',
          prefixIcon: Icon(Icons.search, color: themeData.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(tripHistoryFilterProvider.notifier).updateSearchQuery(null);
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide: BorderSide(color: themeData.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    WidgetRef ref,
    List<TripWithMembers> trips,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final tripWithMembers = trips[index];
        return FadeInAnimation(
          delay: Duration(milliseconds: index * 50),
          child: _buildTripHistoryCard(context, tripWithMembers),
        );
      },
    );
  }

  Widget _buildTripHistoryCard(
    BuildContext context,
    TripWithMembers tripWithMembers,
  ) {
    final trip = tripWithMembers.trip;
    final themeData = context.appThemeData;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AnimatedScaleButton(
      onTap: () => context.push('/trips/${trip.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip image or placeholder
            if (trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd),
                ),
                child: Image.network(
                  trip.coverImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderImage(trip.name),
                ),
              )
            else
              _buildPlaceholderImage(trip.name),

            // Trip details
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trip.rating > 0) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        _buildRatingBadge(context, trip.rating),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingSm),

                  // Destination
                  if (trip.destination != null && trip.destination!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: themeData.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: Text(
                            trip.destination!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppTheme.spacingSm),

                  // Date range
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        _formatDateRange(trip, dateFormat),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingSm),

                  // Completion date
                  if (trip.completedAt != null)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          'Completed: ${dateFormat.format(trip.completedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),

                  // Member count
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        '${tripWithMembers.members.length} ${tripWithMembers.members.length == 1 ? "member" : "members"}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String tripName) {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Center(
        child: Text(
          tripName.isNotEmpty ? tripName[0].toUpperCase() : 'T',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context, double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(TripModel trip, DateFormat dateFormat) {
    if (trip.startDate == null && trip.endDate == null) {
      return 'No dates set';
    }
    if (trip.startDate != null && trip.endDate != null) {
      return '${dateFormat.format(trip.startDate!)} - ${dateFormat.format(trip.endDate!)}';
    }
    if (trip.startDate != null) {
      return 'From ${dateFormat.format(trip.startDate!)}';
    }
    return 'Until ${dateFormat.format(trip.endDate!)}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 120, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No completed trips yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your trip history will appear here once you\ncomplete and rate your trips',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading trip history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(
    BuildContext context,
    WidgetRef ref,
    TripFilterParams params,
    themeData,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Wrap(
        spacing: AppTheme.spacingSm,
        children: [
          if (params.searchQuery != null && params.searchQuery!.isNotEmpty)
            Chip(
              label: Text('Search: "${params.searchQuery}"'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(tripHistoryFilterProvider.notifier).updateSearchQuery(null);
              },
            ),
          if (params.sortBy != TripSortBy.dateNewest)
            Chip(
              label: Text(_getSortLabel(params.sortBy)),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(tripHistoryFilterProvider.notifier).updateSortBy(TripSortBy.dateNewest);
              },
            ),
          if (params.minRating != null)
            Chip(
              label: Text('Rating ≥ ${params.minRating!.toStringAsFixed(1)}★'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(tripHistoryFilterProvider.notifier).updateRatingRange(null, params.maxRating);
              },
            ),
          if (params.customStartDate != null || params.customEndDate != null)
            Chip(
              label: Text(
                'Date: ${params.customStartDate != null ? dateFormat.format(params.customStartDate!) : "Any"} - ${params.customEndDate != null ? dateFormat.format(params.customEndDate!) : "Any"}',
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(tripHistoryFilterProvider.notifier).updateDateRange(null, null);
              },
            ),
          // Clear all button
          if (params.sortBy != TripSortBy.dateNewest ||
              params.minRating != null ||
              (params.searchQuery != null && params.searchQuery!.isNotEmpty) ||
              params.customStartDate != null ||
              params.customEndDate != null)
            ActionChip(
              label: const Text('Clear All'),
              onPressed: () {
                ref.read(tripHistoryFilterProvider.notifier).reset();
              },
            ),
        ],
      ),
    );
  }

  String _getSortLabel(TripSortBy sortBy) {
    switch (sortBy) {
      case TripSortBy.dateNewest:
        return 'Newest First';
      case TripSortBy.dateOldest:
        return 'Oldest First';
      case TripSortBy.createdNewest:
        return 'Recently Created';
      case TripSortBy.createdOldest:
        return 'First Created';
      case TripSortBy.ratingHighest:
        return 'Highest Rated';
      case TripSortBy.ratingLowest:
        return 'Lowest Rated';
      case TripSortBy.priceHighest:
        return 'Highest Price';
      case TripSortBy.priceLowest:
        return 'Lowest Price';
      default:
        return sortBy.name;
    }
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No trips match your filters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final currentParams = ref.watch(tripHistoryFilterProvider);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter & Sort',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(tripHistoryFilterProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Sort By Section
              Text(
                'Sort By',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingSm,
                children: [
                  _buildSortChip(context, ref, 'Date Created (New → Old)', TripSortBy.createdNewest, currentParams),
                  _buildSortChip(context, ref, 'Date Created (Old → New)', TripSortBy.createdOldest, currentParams),
                  _buildSortChip(context, ref, 'Highest Rated', TripSortBy.ratingHighest, currentParams),
                  _buildSortChip(context, ref, 'Lowest Rated', TripSortBy.ratingLowest, currentParams),
                  _buildSortChip(context, ref, 'Trip Date (Newest)', TripSortBy.dateNewest, currentParams),
                  _buildSortChip(context, ref, 'Trip Date (Oldest)', TripSortBy.dateOldest, currentParams),
                ],
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Filter by Rating Section
              Text(
                'Filter by Rating',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: AppTheme.spacingSm,
                children: [
                  _buildRatingFilterChip(context, ref, 'All Ratings', null, currentParams),
                  _buildRatingFilterChip(context, ref, '4+ Stars', 4.0, currentParams),
                  _buildRatingFilterChip(context, ref, '3+ Stars', 3.0, currentParams),
                  _buildRatingFilterChip(context, ref, '2+ Stars', 2.0, currentParams),
                ],
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Custom Date Range Section
              Text(
                'Custom Date Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildDateRangeSelector(context, ref, currentParams),

              const SizedBox(height: AppTheme.spacingLg),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    TripSortBy sortBy,
    TripFilterParams currentParams,
  ) {
    final themeData = context.appThemeData;
    final isSelected = currentParams.sortBy == sortBy;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: themeData.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: themeData.primaryColor,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? themeData.primaryColor : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      onSelected: (selected) {
        debugPrint('🔘 Filter chip tapped: $label, selected: $selected');
        if (selected) {
          debugPrint('📝 Updating sort to: $sortBy');
          ref.read(tripHistoryFilterProvider.notifier).updateSortBy(sortBy);
        }
      },
    );
  }

  Widget _buildRatingFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    double? minRating,
    TripFilterParams currentParams,
  ) {
    final themeData = context.appThemeData;
    final isSelected = currentParams.minRating == minRating;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: themeData.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: themeData.primaryColor,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? themeData.primaryColor : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      onSelected: (selected) {
        debugPrint('⭐ Rating filter tapped: $label, selected: $selected');
        // Always update to the new rating filter (allows toggling back to "All Ratings")
        debugPrint('📝 Updating rating filter to: $minRating');
        ref.read(tripHistoryFilterProvider.notifier).updateRatingRange(minRating, null);
      },
    );
  }

  Widget _buildDateRangeSelector(
    BuildContext context,
    WidgetRef ref,
    TripFilterParams currentParams,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final themeData = context.appThemeData;

    return Column(
      children: [
        // Start Date
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: currentParams.customStartDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Select Start Date',
            );
            if (pickedDate != null) {
              ref.read(tripHistoryFilterProvider.notifier).updateDateRange(
                pickedDate,
                currentParams.customEndDate,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: themeData.primaryColor),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      currentParams.customStartDate != null
                          ? 'From: ${dateFormat.format(currentParams.customStartDate!)}'
                          : 'Select Start Date',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (currentParams.customStartDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      ref.read(tripHistoryFilterProvider.notifier).updateDateRange(
                        null,
                        currentParams.customEndDate,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // End Date
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: currentParams.customEndDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              helpText: 'Select End Date',
            );
            if (pickedDate != null) {
              ref.read(tripHistoryFilterProvider.notifier).updateDateRange(
                currentParams.customStartDate,
                pickedDate,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: themeData.primaryColor),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      currentParams.customEndDate != null
                          ? 'To: ${dateFormat.format(currentParams.customEndDate!)}'
                          : 'Select End Date',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (currentParams.customEndDate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      ref.read(tripHistoryFilterProvider.notifier).updateDateRange(
                        currentParams.customStartDate,
                        null,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
