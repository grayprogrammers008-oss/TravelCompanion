import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/trip_providers.dart';

/// Page for browsing and joining public trips created by other users
class BrowseTripsPage extends ConsumerStatefulWidget {
  const BrowseTripsPage({super.key});

  @override
  ConsumerState<BrowseTripsPage> createState() => _BrowseTripsPageState();
}

class _BrowseTripsPageState extends ConsumerState<BrowseTripsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _searchController = TextEditingController();

  // Filter state variables
  String _sortBy = 'nearest_date'; // nearest_date, farthest_date, most_members, recently_created
  String _statusFilter = 'all'; // all, upcoming, in_progress, ended
  int? _minMembers;
  int? _maxMembers;
  bool _showFavoritesOnly = false; // Filter to show only favorited trips

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Filter and sort trips based on search query and filters
  List<TripWithMembers> _filterTrips(List<TripWithMembers> trips) {
    final query = _searchController.text.toLowerCase().trim();
    final now = DateTime.now();

    // Step 1: Apply search filter
    var filteredTrips = trips.where((tripWithMembers) {
      final trip = tripWithMembers.trip;
      if (query.isNotEmpty) {
        final nameMatch = trip.name.toLowerCase().contains(query);
        final destinationMatch = trip.destination?.toLowerCase().contains(query) ?? false;
        final descriptionMatch = trip.description?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !destinationMatch && !descriptionMatch) {
          return false;
        }
      }
      return true;
    }).toList();

    // Step 2: Apply status filter
    if (_statusFilter != 'all') {
      filteredTrips = filteredTrips.where((tripWithMembers) {
        final trip = tripWithMembers.trip;
        final hasStarted = trip.startDate != null && trip.startDate!.isBefore(now);
        final hasEnded = trip.endDate != null && trip.endDate!.isBefore(now);
        final isOngoing = hasStarted && (trip.endDate == null || trip.endDate!.isAfter(now));

        switch (_statusFilter) {
          case 'upcoming':
            return !hasStarted; // Not yet started
          case 'in_progress':
            return isOngoing; // Started but not ended
          case 'ended':
            return hasEnded; // Already ended
          default:
            return true;
        }
      }).toList();
    }

    // Step 3: Apply member count filter
    if (_minMembers != null || _maxMembers != null) {
      filteredTrips = filteredTrips.where((tripWithMembers) {
        final memberCount = tripWithMembers.members.length;
        if (_minMembers != null && memberCount < _minMembers!) {
          return false;
        }
        if (_maxMembers != null && memberCount > _maxMembers!) {
          return false;
        }
        return true;
      }).toList();
    }

    // Step 4: Apply favorites filter
    if (_showFavoritesOnly) {
      filteredTrips = filteredTrips.where((tripWithMembers) {
        return tripWithMembers.isFavorite;
      }).toList();
    }

    // Step 5: Apply sorting
    switch (_sortBy) {
      case 'nearest_date':
        filteredTrips.sort((a, b) {
          final aDate = a.trip.startDate;
          final bDate = b.trip.startDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        break;
      case 'farthest_date':
        filteredTrips.sort((a, b) {
          final aDate = a.trip.startDate;
          final bDate = b.trip.startDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        break;
      case 'most_members':
        filteredTrips.sort((a, b) => b.members.length.compareTo(a.members.length));
        break;
      case 'recently_created':
        filteredTrips.sort((a, b) {
          final aCreated = a.trip.createdAt;
          final bCreated = b.trip.createdAt;
          if (aCreated == null && bCreated == null) return 0;
          if (aCreated == null) return 1;
          if (bCreated == null) return -1;
          return bCreated.compareTo(aCreated);
        });
        break;
    }

    return filteredTrips;
  }

  /// Show filter bottom sheet with sort and filter options
  void _showFilterBottomSheet(BuildContext context) {
    final themeData = ref.read(theme_provider.currentThemeDataProvider);

    // Use local variables for modal state management
    String localSortBy = _sortBy;
    String localStatusFilter = _statusFilter;
    int? localMinMembers = _minMembers;
    int? localMaxMembers = _maxMembers;

    // Controllers for member count fields
    final minMembersController = TextEditingController(
      text: localMinMembers?.toString() ?? '',
    );
    final maxMembersController = TextEditingController(
      text: localMaxMembers?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (builderContext, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXl),
              topRight: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                          color: AppTheme.neutral300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: themeData.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: themeData.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            const Text(
                              'Filter & Sort',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        // Reset button
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              localSortBy = 'nearest_date';
                              localStatusFilter = 'all';
                              localMinMembers = null;
                              localMaxMembers = null;
                              minMembersController.clear();
                              maxMembersController.clear();
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: themeData.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Sort By Section
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: [
                        _buildSortChipStateful('Nearest Date', 'nearest_date', themeData, localSortBy, (value) {
                          setModalState(() => localSortBy = value);
                        }),
                        _buildSortChipStateful('Farthest Date', 'farthest_date', themeData, localSortBy, (value) {
                          setModalState(() => localSortBy = value);
                        }),
                        _buildSortChipStateful('Most Members', 'most_members', themeData, localSortBy, (value) {
                          setModalState(() => localSortBy = value);
                        }),
                        _buildSortChipStateful('Recently Created', 'recently_created', themeData, localSortBy, (value) {
                          setModalState(() => localSortBy = value);
                        }),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Status Filter Section
                    Text(
                      'Trip Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Wrap(
                      spacing: AppTheme.spacingSm,
                      runSpacing: AppTheme.spacingSm,
                      children: [
                        _buildStatusChipStateful('All', 'all', themeData, localStatusFilter, (value) {
                          setModalState(() => localStatusFilter = value);
                        }),
                        _buildStatusChipStateful('Upcoming', 'upcoming', themeData, localStatusFilter, (value) {
                          setModalState(() => localStatusFilter = value);
                        }),
                        _buildStatusChipStateful('In Progress', 'in_progress', themeData, localStatusFilter, (value) {
                          setModalState(() => localStatusFilter = value);
                        }),
                        _buildStatusChipStateful('Ended', 'ended', themeData, localStatusFilter, (value) {
                          setModalState(() => localStatusFilter = value);
                        }),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // Member Count Filter Section
                    Text(
                      'Member Count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMemberFieldStateful(
                            'Min',
                            minMembersController,
                            (value) {
                              setModalState(() => localMinMembers = value);
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(
                          'to',
                          style: TextStyle(
                            color: AppTheme.neutral500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _buildMemberFieldStateful(
                            'Max',
                            maxMembersController,
                            (value) {
                              setModalState(() => localMaxMembers = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingMd,
                              ),
                              side: BorderSide(color: AppTheme.neutral300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppTheme.neutral600),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Apply filters to parent state
                              setState(() {
                                _sortBy = localSortBy;
                                _statusFilter = localStatusFilter;
                                _minMembers = localMinMembers;
                                _maxMembers = localMaxMembers;
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Apply Filters'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingMd,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build sort chip with stateful support for modal bottom sheet
  Widget _buildSortChipStateful(String label, String value, dynamic themeData, String currentSortBy, Function(String) onSelect) {
    final isSelected = currentSortBy == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? themeData.primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? themeData.primaryColor : AppTheme.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? themeData.primaryColor : AppTheme.neutral600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Build status chip with stateful support for modal bottom sheet
  Widget _buildStatusChipStateful(String label, String value, dynamic themeData, String currentStatus, Function(String) onSelect) {
    final isSelected = currentStatus == value;

    // Define status-specific colors
    Color chipColor;
    switch (value) {
      case 'upcoming':
        chipColor = themeData.primaryColor;
        break;
      case 'in_progress':
        chipColor = Colors.orange;
        break;
      case 'ended':
        chipColor = AppTheme.neutral500;
        break;
      default:
        chipColor = themeData.primaryColor;
    }

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppTheme.neutral600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Build member count field with stateful support for modal bottom sheet
  Widget _buildMemberFieldStateful(String label, TextEditingController controller, Function(int?) onChanged) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (text) {
        final parsed = int.tryParse(text);
        onChanged(parsed);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        filled: true,
        fillColor: AppTheme.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: AppTheme.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: AppTheme.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: AppTheme.neutral400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        prefixIcon: Icon(
          Icons.people_outline,
          color: AppTheme.neutral400,
          size: 20,
        ),
      ),
    );
  }

  /// Show confirmation dialog before joining a trip
  Future<bool> _showJoinConfirmationDialog(
    BuildContext context,
    TripWithMembers tripWithMembers,
  ) async {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final themeData = ref.read(theme_provider.currentThemeDataProvider);

    // Calculate trip status
    final now = DateTime.now();
    final daysUntilStart = trip.startDate?.difference(now).inDays;
    final hasStarted = trip.startDate != null && trip.startDate!.isBefore(now);
    final isOngoing = hasStarted && (trip.endDate == null || trip.endDate!.isAfter(now));
    final hasEnded = trip.endDate != null && trip.endDate!.isBefore(now);

    // Find organizer (creator)
    final organizer = members.isNotEmpty
        ? members.firstWhere(
            (m) => m.userId == trip.createdBy,
            orElse: () => members.first,
          )
        : TripMemberModel(
            id: '',
            tripId: trip.id,
            userId: trip.createdBy,
            role: 'admin',
          );

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                        color: AppTheme.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: const Icon(
                          Icons.group_add,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      const Text(
                        'Join This Trip?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Trip Preview Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.neutral50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Trip Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusMd),
                            topRight: Radius.circular(AppTheme.radiusMd),
                          ),
                          child: DestinationImage(
                            tripName: trip.destination ?? trip.name,
                            tripId: trip.id,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trip Name
                              Text(
                                trip.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (trip.destination != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppTheme.neutral500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.destination!,
                                      style: TextStyle(
                                        color: AppTheme.neutral600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppTheme.spacingSm),

                              // Date info
                              if (trip.startDate != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppTheme.neutral500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${trip.startDate!.toLocal().toShortDate()}${trip.endDate != null ? ' - ${trip.endDate!.toLocal().toShortDate()}' : ''}',
                                      style: TextStyle(
                                        color: AppTheme.neutral600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: AppTheme.spacingSm),

                              // Members count
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 14,
                                    color: AppTheme.neutral500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                                    style: TextStyle(
                                      color: AppTheme.neutral600,
                                      fontSize: 13,
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
                  const SizedBox(height: AppTheme.spacingMd),

                  // Organizer Info
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: themeData.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: themeData.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: themeData.primaryColor.withValues(alpha: 0.2),
                          backgroundImage: organizer.avatarUrl != null
                              ? NetworkImage(organizer.avatarUrl!)
                              : null,
                          child: organizer.avatarUrl == null
                              ? Text(
                                  (organizer.fullName ?? organizer.email ?? 'O')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: themeData.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organized by',
                                style: TextStyle(
                                  color: AppTheme.neutral500,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                organizer.fullName ?? organizer.email ?? 'Trip Creator',
                                style: TextStyle(
                                  color: themeData.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: AppTheme.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.public, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Public',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Warning (if trip has started or ending soon)
                  if (hasEnded) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_busy, color: AppTheme.error, size: 20),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              'This trip has already ended',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isOngoing) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_run, color: Colors.orange, size: 20),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              'This trip is already in progress! You can still join and catch up.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (daysUntilStart != null && daysUntilStart <= 3 && daysUntilStart >= 0) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.amber, size: 20),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              daysUntilStart == 0
                                  ? 'Trip starts today! Join now to be part of it.'
                                  : daysUntilStart == 1
                                      ? 'Trip starts tomorrow! Join now to be part of it.'
                                      : 'Trip starts in $daysUntilStart days!',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingXl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd,
                            ),
                            side: BorderSide(color: AppTheme.neutral300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppTheme.neutral600),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: hasEnded ? null : () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(hasEnded ? 'Trip Ended' : 'Join Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasEnded ? AppTheme.neutral400 : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMd,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return result ?? false;
  }

  /// Handle joining a trip with confirmation
  Future<void> _joinTrip(BuildContext context, TripWithMembers tripWithMembers) async {
    final trip = tripWithMembers.trip;
    final tripId = trip.id;
    final tripName = trip.name;

    // Show confirmation dialog first
    final confirmed = await _showJoinConfirmationDialog(context, tripWithMembers);
    if (!confirmed) return;

    if (!context.mounted) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLoadingIndicator(),
                  SizedBox(height: AppTheme.spacingMd),
                  Text('Joining trip...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Call the join trip use case
      final useCase = ref.read(joinTripUseCaseProvider);
      await useCase(tripId);

      // Brief wait to ensure Supabase has committed the new member row
      // before we invalidate providers and navigate to the trip detail
      await Future.delayed(const Duration(milliseconds: 300));

      // Refresh all trip data
      ref.invalidate(discoverableTripsProvider);
      ref.invalidate(userTripsProvider);
      ref.invalidate(tripProvider(tripId));

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text('Successfully joined "$tripName"!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Auto-navigate to trip detail (consistent with JoinTripByCodePage)
        context.go('/trips/$tripId');
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text('Failed to join trip: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Get contextual subtitle based on available trips
  String _getExploreSubtitle(List<TripWithMembers> allTrips) {
    final now = DateTime.now();

    // Filter out ended/completed trips first
    final trips = allTrips.where((t) {
      if (t.trip.isCompleted) return false;
      if (t.trip.endDate != null && t.trip.endDate!.isBefore(now)) return false;
      return true;
    }).toList();

    if (trips.isEmpty) {
      return 'Discover amazing adventures';
    }

    // Count trips starting soon (within 30 days)
    final upcomingTrips = trips.where((t) {
      final startDate = t.trip.startDate;
      if (startDate == null) return false;
      final daysUntil = startDate.difference(now).inDays;
      return daysUntil >= 0 && daysUntil <= 30;
    }).toList();

    // Get unique destinations
    final destinations = trips
        .map((t) => t.trip.destination)
        .where((d) => d != null && d.isNotEmpty)
        .toSet()
        .take(3)
        .toList();

    // Priority 1: Show upcoming trips count
    if (upcomingTrips.isNotEmpty) {
      if (upcomingTrips.length == 1) {
        final trip = upcomingTrips.first;
        final daysUntil = trip.trip.startDate!.difference(now).inDays;
        if (daysUntil == 0) {
          return '${trip.trip.destination ?? "A trip"} starts today!';
        } else if (daysUntil == 1) {
          return '${trip.trip.destination ?? "A trip"} starts tomorrow';
        } else {
          return '${trip.trip.destination ?? "A trip"} in $daysUntil days';
        }
      }
      return '${upcomingTrips.length} trips starting soon';
    }

    // Priority 2: Show total trips with popular destinations
    if (destinations.isNotEmpty) {
      return '${trips.length} trips · ${destinations.first}${destinations.length > 1 ? " & more" : ""}';
    }

    // Default: Show count
    return '${trips.length} ${trips.length == 1 ? "adventure" : "adventures"} waiting';
  }

  /// Build profile avatar for the app bar leading widget
  Widget _buildProfileAvatar(WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.spacingMd),
      child: GestureDetector(
        onTap: () => context.push('/profile'),
        child: Center(
          child: userAsync.when(
            data: (user) => UserAvatarWidget(
              imageUrl: user?.avatarUrl,
              userName: user?.fullName ?? user?.email,
              size: 36,
              showBorder: true,
            ),
            loading: () => Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            error: (_, _) => Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverableTripsAsync = ref.watch(discoverableTripsWithFavoritesProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: RefreshIndicator(
          displacement: 120,
          edgeOffset: 120,
          onRefresh: () async {
            // Invalidate raw trips provider to refetch from server
            ref.invalidate(discoverableTripsProvider);
            ref.invalidate(favoriteTripIdsProvider);
            // Wait for trips to load
            await ref.read(discoverableTripsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              // Personalized header matching Home Page design
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                  child: _buildProfileAvatar(ref),
                ),
                leadingWidth: 60,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Explore',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      discoverableTripsAsync.maybeWhen(
                        data: (trips) => _getExploreSubtitle(trips),
                        orElse: () => 'Finding adventures...',
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                titleSpacing: 4,
                actions: [
                  // Favorites filter
                  IconButton(
                    icon: Icon(
                      _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                      color: _showFavoritesOnly ? Colors.red[300] : Colors.white,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                      });
                    },
                    tooltip: _showFavoritesOnly ? 'Show all trips' : 'Show favorites only',
                  ),
                  // Settings Icon
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => context.push('/settings'),
                    tooltip: 'Settings',
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: themeData.primaryGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Spacer for the toolbar area
                          const SizedBox(height: kToolbarHeight),
                          // Search bar row with filter button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spacingMd,
                              AppTheme.spacingSm,
                              AppTheme.spacingMd,
                              AppTheme.spacingMd,
                            ),
                            child: Row(
                              children: [
                                // Search Field - Solid white background
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.neutral900,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Find your next adventure 🧭',
                                        hintStyle: TextStyle(
                                          color: AppTheme.neutral400,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingMd,
                                          vertical: 12,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: themeData.primaryColor,
                                          size: 22,
                                        ),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear_rounded,
                                                  color: AppTheme.neutral400,
                                                  size: 20,
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
                                const SizedBox(width: AppTheme.spacingMd),
                                // Filter Button - Matching white style
                                GestureDetector(
                                  onTap: () => _showFilterBottomSheet(context),
                                  child: Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.tune_rounded,
                                      color: AppTheme.neutral600,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              discoverableTripsAsync.when(
                data: (trips) {
                  final filteredTrips = _filterTrips(trips);

                  if (trips.isEmpty) {
                    return SliverFillRemaining(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildEmptyState(context),
                      ),
                    );
                  }

                  if (filteredTrips.isEmpty && _searchController.text.isNotEmpty) {
                    return SliverFillRemaining(
                      child: _buildNoSearchResults(context),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tripWithMembers = filteredTrips[index];
                          return FadeSlideAnimation(
                            delay: AppAnimations.staggerMedium * index,
                            duration: AppAnimations.medium,
                            child: DiscoverableTripCard(
                              key: ValueKey(tripWithMembers.trip.id),
                              tripWithMembers: tripWithMembers,
                              onTap: () => context.push('/trips/${tripWithMembers.trip.id}'),
                              onJoin: () => _joinTrip(context, tripWithMembers),
                            ),
                          );
                        },
                        childCount: filteredTrips.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLoadingIndicator(),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'Finding public trips...',
                          style: context.bodyStyle.copyWith(
                            color: context.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(context, error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state - no public trips available
  Widget _buildEmptyState(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join by Code Card - Primary action
          _buildJoinByCodeCard(context, themeData),
          const SizedBox(height: AppTheme.spacingXl),

          // No public trips message
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 64,
                  color: context.textColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'No Public Trips',
                  style: context.titleStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'There are no public trips available right now.',
                  style: context.bodyStyle.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }

  /// Join by Code card - prominent CTA for users with invite codes
  Widget _buildJoinByCodeCard(BuildContext context, dynamic themeData) {
    return GestureDetector(
      onTap: () => context.push('/join-trip'),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeData.primaryColor.withValues(alpha: 0.1),
              themeData.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: themeData.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeData.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                color: themeData.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have a trip code?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: themeData.primaryColor,
                    ),
                  ),
                  Text(
                    'Join a friend\'s trip instantly',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeData.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.neutral400,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Results Found',
              style: context.titleStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Try different search terms',
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
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
              'Failed to Load Trips',
              style: context.titleStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error,
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(discoverableTripsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying discoverable trips
class DiscoverableTripCard extends ConsumerWidget {
  final TripWithMembers tripWithMembers;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const DiscoverableTripCard({
    super.key,
    required this.tripWithMembers,
    required this.onTap,
    required this.onJoin,
  });

  /// Toggle favorite status with haptic feedback
  void _toggleFavorite(WidgetRef ref, String tripId) {
    HapticFeedback.lightImpact();
    ref.read(tripFavoritesControllerProvider.notifier).toggleFavorite(tripId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final memberCount = members.length;
    final isFavorite = tripWithMembers.isFavorite;

    // Calculate trip status
    final now = DateTime.now();
    final daysLeft = trip.startDate?.difference(now).inDays;
    final hasStarted = trip.startDate != null && trip.startDate!.isBefore(now);
    final isOngoing = hasStarted && (trip.endDate == null || trip.endDate!.isAfter(now));
    final hasEnded = trip.endDate != null && trip.endDate!.isBefore(now);

    // Find organizer (creator)
    final organizer = members.isNotEmpty
        ? members.firstWhere(
            (m) => m.userId == trip.createdBy,
            orElse: () => members.first,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image with Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLg),
                      topRight: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: DestinationImage(
                      tripName: trip.destination ?? trip.name,
                      tripId: trip.id,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      showOverlay: true,
                      overlayChild: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Public Badge and Favorite Button Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: AppTheme.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.public,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Public',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Favorite Button
                                GestureDetector(
                                  onTap: () => _toggleFavorite(ref, trip.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isFavorite
                                          ? const Color(0xFFE91E63).withValues(alpha: 0.9)
                                          : Colors.black.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Trip Status Badge
                            if (hasEnded)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm,
                                  vertical: AppTheme.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.neutral500,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event_busy, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ended',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isOngoing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm,
                                  vertical: AppTheme.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.directions_run, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'In Progress',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (daysLeft != null && daysLeft >= 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm,
                                  vertical: AppTheme.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: daysLeft <= 3 ? Colors.amber : context.accentColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      daysLeft == 0 ? Icons.today : Icons.access_time,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      daysLeft == 0
                                          ? 'Starts Today!'
                                          : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
                      style: context.titleStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (trip.destination != null) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: context.textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trip.destination!,
                              style: context.bodyStyle.copyWith(
                                color: context.textColor.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (trip.description != null && trip.description!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        trip.description!,
                        style: context.bodyStyle.copyWith(
                          color: context.textColor.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingMd),

                    // Info Row
                    Row(
                      children: [
                        // Member Count
                        Flexible(
                          child: _buildInfoChip(
                            context,
                            icon: Icons.people_outline,
                            label: '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                          ),
                        ),

                        const SizedBox(width: AppTheme.spacingSm),

                        // Date
                        if (trip.startDate != null)
                          Flexible(
                            child: _buildInfoChip(
                              context,
                              icon: Icons.calendar_today_outlined,
                              label: trip.startDate!.toLocal().toShortDate(),
                            ),
                          ),
                      ],
                    ),

                    // Organizer Info
                    if (organizer != null) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral100,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: AppTheme.neutral300,
                              backgroundImage: organizer.avatarUrl != null
                                  ? NetworkImage(organizer.avatarUrl!)
                                  : null,
                              child: organizer.avatarUrl == null
                                  ? Text(
                                      (organizer.fullName ?? organizer.email ?? 'O')[0].toUpperCase(),
                                      style: TextStyle(
                                        color: AppTheme.neutral600,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'by ${organizer.fullName ?? organizer.email ?? 'Unknown'}',
                                style: TextStyle(
                                  color: AppTheme.neutral600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingMd),

                    // Join Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onJoin,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Join Trip'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                      ),
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

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: context.textColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: context.bodyStyle.copyWith(
                fontSize: 12,
                color: context.textColor.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
