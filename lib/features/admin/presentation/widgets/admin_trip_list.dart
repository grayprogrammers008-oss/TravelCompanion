import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/widgets/destination_image.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_trip.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_trip_providers.dart';

/// Admin Trip List Widget
/// Displays all trips with search, filter, and management capabilities
class AdminTripList extends ConsumerStatefulWidget {
  const AdminTripList({super.key});

  @override
  ConsumerState<AdminTripList> createState() => _AdminTripListState();
}

class _AdminTripListState extends ConsumerState<AdminTripList> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all'; // 'all', 'active', 'completed'
  int _currentPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TripListParams get _currentParams => TripListParams(
        limit: 50,
        offset: _currentPage * 50,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

  void _applyFilters() {
    setState(() {
      _currentPage = 0; // Reset to first page when filters change
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(adminTripsProvider(_currentParams));

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          color: Colors.white,
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or destination...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Status Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Trips', 'all', Icons.list),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildFilterChip('Active', 'active', Icons.play_circle_outline),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildFilterChip('Completed', 'completed', Icons.check_circle_outline),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Trip List
        Expanded(
          child: tripsAsync.when(
            data: (trips) {
              if (trips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.explore_outlined,
                          size: 64,
                          color: AppTheme.neutral400,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        'No trips found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral700,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Try adjusting your search'
                            : 'Trips will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutral600,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminTripsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(context, trip);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Error loading trips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.neutral600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedStatus == value;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.neutral700,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: AppTheme.neutral100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.neutral700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          _selectedStatus = value;
        });
        _applyFilters();
      },
    );
  }

  Widget _buildTripCard(BuildContext context, AdminTripModel trip) {
    final startDate = trip.startDate != null
        ? DateFormat('MMM dd, yyyy').format(trip.startDate!)
        : 'Not set';
    final endDate = trip.endDate != null
        ? DateFormat('MMM dd, yyyy').format(trip.endDate!)
        : 'Not set';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: InkWell(
        onTap: () => _showTripDetail(trip),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Image Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    topRight: Radius.circular(AppTheme.radiusMd),
                  ),
                  child: DestinationImage(
                    destination: trip.destination,
                    height: 150,
                  ),
                ),
                // Status Badge
                Positioned(
                  top: AppTheme.spacingMd,
                  right: AppTheme.spacingMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: trip.isCompleted
                          ? AppTheme.success
                          : AppTheme.info,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trip.isCompleted
                              ? Icons.check_circle
                              : Icons.play_circle,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          trip.isCompleted ? 'Completed' : 'Active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Trip Details
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip Name
                  Text(
                    trip.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),

                  // Destination
                  if (trip.destination != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.neutral600,
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Expanded(
                          child: Text(
                            trip.destination!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.neutral600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Date Range
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(
                          '$startDate - $endDate',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.neutral700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Stats Row
                  Row(
                    children: [
                      // Members
                      _buildStatChip(
                        icon: Icons.people,
                        label: '${trip.memberCount} Members',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),

                      // Expenses
                      if (trip.totalExpenses != null && trip.totalExpenses! > 0)
                        _buildStatChip(
                          icon: Icons.attach_money,
                          label: '${trip.currency} ${trip.totalExpenses!.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Creator Info
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppTheme.neutral600,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Expanded(
                              child: Text(
                                'Created by ${trip.creatorName}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.neutral600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () => _editTrip(trip),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 20,
                        color: AppTheme.error,
                        onPressed: () => _confirmDeleteTrip(trip),
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetail(AdminTripModel trip) {
    // Navigate to trip detail page
    context.push('/trips/${trip.id}');
  }

  void _editTrip(AdminTripModel trip) {
    // TODO: Implement edit trip functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit trip: ${trip.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _confirmDeleteTrip(AdminTripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text(
          'Are you sure you want to delete "${trip.name}"? This action cannot be undone and will delete all associated data (expenses, checklists, itinerary).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTrip(trip);
    }
  }

  Future<void> _deleteTrip(AdminTripModel trip) async {
    try {
      await ref.read(adminTripRepositoryProvider).deleteTrip(trip.id);

      if (mounted) {
        // Refresh the list
        ref.invalidate(adminTripsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip "${trip.name}" deleted successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete trip: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
