import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/trip_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  // Filter state variables
  double? _minBudget;
  double? _maxBudget;
  DateTime? _createdAfter;
  DateTime? _createdBefore;

  // Status filter: 'all', 'active', 'upcoming', 'completed'
  String _statusFilter = 'all';

  // Sort options: 'recent', 'name', 'startDate', 'budget'
  String _sortBy = 'recent';

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

  /// Get trip status category
  String _getTripStatusCategory(TripModel trip) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (trip.isCompleted) return 'completed';

    if (trip.startDate != null) {
      final startDate = DateTime(trip.startDate!.year, trip.startDate!.month, trip.startDate!.day);

      if (startDate.isAfter(today)) return 'upcoming';

      if (trip.endDate != null) {
        final endDate = DateTime(trip.endDate!.year, trip.endDate!.month, trip.endDate!.day);
        if (today.isAfter(endDate)) return 'completed';
      }
      return 'active'; // Started but not ended
    }

    return 'active'; // No dates = active
  }

  /// Get trip stats counts
  ({int all, int active, int upcoming, int completed}) _getTripStats(List<TripWithMembers> trips) {
    int active = 0;
    int upcoming = 0;
    int completed = 0;

    for (final t in trips) {
      final status = _getTripStatusCategory(t.trip);
      switch (status) {
        case 'active':
          active++;
          break;
        case 'upcoming':
          upcoming++;
          break;
        case 'completed':
          completed++;
          break;
      }
    }

    return (all: trips.length, active: active, upcoming: upcoming, completed: completed);
  }

  List<TripWithMembers> _filterTrips(List<TripWithMembers> trips) {
    final query = _searchController.text.toLowerCase().trim();

    var filtered = trips.where((tripWithMembers) {
      final trip = tripWithMembers.trip;

      // Status filter
      if (_statusFilter != 'all') {
        final status = _getTripStatusCategory(trip);
        if (status != _statusFilter) return false;
      }

      // Search filter
      if (query.isNotEmpty) {
        final nameMatch = trip.name.toLowerCase().contains(query);
        final destinationMatch = trip.destination?.toLowerCase().contains(query) ?? false;
        final descriptionMatch = trip.description?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !destinationMatch && !descriptionMatch) {
          return false;
        }
      }

      // Budget filter (treat null budget as 0)
      if (_minBudget != null) {
        final tripBudget = trip.budget ?? 0.0;
        if (tripBudget < _minBudget!) return false;
      }
      if (_maxBudget != null) {
        final tripBudget = trip.budget ?? 0.0;
        if (tripBudget > _maxBudget!) return false;
      }

      // Date created filter
      if (_createdAfter != null && trip.createdAt != null) {
        if (trip.createdAt!.isBefore(_createdAfter!)) return false;
      }
      if (_createdBefore != null && trip.createdAt != null) {
        final endOfDay = DateTime(_createdBefore!.year, _createdBefore!.month, _createdBefore!.day, 23, 59, 59);
        if (trip.createdAt!.isAfter(endOfDay)) return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.trip.name.toLowerCase().compareTo(b.trip.name.toLowerCase()));
        break;
      case 'startDate':
        filtered.sort((a, b) {
          final aDate = a.trip.startDate ?? DateTime(2100);
          final bDate = b.trip.startDate ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });
        break;
      case 'budget':
        filtered.sort((a, b) {
          final aBudget = a.trip.budget ?? 0.0;
          final bBudget = b.trip.budget ?? 0.0;
          return bBudget.compareTo(aBudget); // High to low
        });
        break;
      case 'recent':
      default:
        filtered.sort((a, b) {
          final aDate = a.trip.createdAt ?? DateTime(1970);
          final bDate = b.trip.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate); // Newest first
        });
        break;
    }

    return filtered;
  }

  bool get _hasActiveFilters {
    return _minBudget != null ||
           _maxBudget != null ||
           _createdAfter != null ||
           _createdBefore != null;
  }

  bool get _hasAnyFilters {
    return _hasActiveFilters || _statusFilter != 'all' || _sortBy != 'recent';
  }

  void _clearAllFilters() {
    setState(() {
      _minBudget = null;
      _maxBudget = null;
      _createdAfter = null;
      _createdBefore = null;
      _statusFilter = 'all';
      _sortBy = 'recent';
      _searchController.clear();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userTripsAsync = ref.watch(userTripsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: RefreshIndicator(
          displacement: 120, // Push indicator below the SliverAppBar
          edgeOffset: 120, // Start detecting pull below the app bar
          onRefresh: () async {
            ref.invalidate(userTripsProvider);
            await ref.read(userTripsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              // Premium App Bar with gradient
              SliverAppBar(
            expandedHeight: _isSearching ? 160 : 120,
            floating: false,
            pinned: true,
            backgroundColor: themeData.primaryColor,
            actions: [
              // Search Icon
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                    }
                  });
                },
              ),
              // Filter Icon
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () => _navigateToFilterPage(context),
                  ),
                  if (_hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              // Menu Icon
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showProfileMenu(context, ref),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: themeData.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // User Avatar
                            UserAvatarWidget(
                              imageUrl: currentUser.value?.avatarUrl,
                              userName: currentUser.value?.fullName,
                              size: 48,
                              showBorder: true,
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                  ),
                                  Text(
                                    currentUser.value?.fullName
                                            ?.split(' ')
                                            .first ??
                                        'Traveler',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_isSearching) ...[
                                    const SizedBox(height: AppTheme.spacingXs),
                                    SizedBox(
                                      height: 42,
                                      child: TextField(
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
                                          hintText: 'Search trips...',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withValues(alpha: 0.2),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingSm,
                                            vertical: AppTheme.spacingXs,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          ...userTripsAsync.when(
            data: (trips) {
              final filteredTrips = _filterTrips(trips);
              final stats = _getTripStats(trips);

              if (trips.isEmpty) {
                return [
                  SliverFillRemaining(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildEmptyState(context),
                    ),
                  ),
                ];
              }

              return [
                // Quick Stats Header
                SliverToBoxAdapter(
                  child: _buildStatsHeader(context, stats, themeData),
                ),

                // Status Filter Chips + Sort
                SliverToBoxAdapter(
                  child: _buildStatusFiltersAndSort(context, stats, themeData),
                ),

                // Trip List or No Results
                if (filteredTrips.isEmpty && (_searchController.text.isNotEmpty || _hasActiveFilters || _statusFilter != 'all'))
                  SliverFillRemaining(
                    child: _buildNoSearchResults(context),
                  )
                else
                  // Show grouped sections when viewing "All" and no search/filters active
                  ...(_statusFilter == 'all' && _searchController.text.isEmpty && !_hasActiveFilters
                      ? _buildGroupedTripList(context, filteredTrips, themeData)
                      : [_buildFlatTripList(context, filteredTrips)]),

                // Bottom padding for FAB
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ];
            },
            loading: () => [
              SliverFillRemaining(
                child: _buildPackingAnimation(context),
              ),
            ],
            error: (error, stack) => [
              SliverFillRemaining(
                child: _buildErrorState(context, error.toString(), ref, themeData),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleAnimation(
        duration: AppAnimations.slow,
        curve: AppAnimations.spring,
        child: AnimatedScaleButton(
          onTap: () => context.push('/trips/create'),
          child: Container(
            decoration: BoxDecoration(
              gradient: themeData.glossyGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: themeData.glossyShadow,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: FloatingActionButton.extended(
                onPressed: null, // Handled by AnimatedScaleButton
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                label: const Text(
                  'New Trip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact stats header showing trip counts
  Widget _buildStatsHeader(
    BuildContext context,
    ({int all, int active, int upcoming, int completed}) stats,
    AppThemeData themeData,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Total', stats.all, themeData.primaryColor),
          _buildStatDivider(),
          _buildStatItem(context, 'Active', stats.active, const Color(0xFFFF7043)),
          _buildStatDivider(),
          _buildStatItem(context, 'Upcoming', stats.upcoming, const Color(0xFF5C6BC0)),
          _buildStatDivider(),
          _buildStatItem(context, 'Done', stats.completed, AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.neutral600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppTheme.neutral200,
    );
  }

  /// Build status filter chips and sort dropdown
  Widget _buildStatusFiltersAndSort(
    BuildContext context,
    ({int all, int active, int upcoming, int completed}) stats,
    AppThemeData themeData,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingXs,
      ),
      child: Row(
        children: [
          // Status filter chips (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', stats.all, themeData),
                  const SizedBox(width: 8),
                  _buildFilterChip('active', 'Active', stats.active, themeData),
                  const SizedBox(width: 8),
                  _buildFilterChip('upcoming', 'Upcoming', stats.upcoming, themeData),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed', stats.completed, themeData),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort dropdown
          _buildSortButton(context, themeData),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count, AppThemeData themeData) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? themeData.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? themeData.primaryColor : AppTheme.neutral300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.neutral700,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppTheme.neutral100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.neutral600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, AppThemeData themeData) {
    final sortLabels = {
      'recent': 'Recent',
      'name': 'Name',
      'startDate': 'Date',
      'budget': 'Budget',
    };

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _sortBy = value;
        });
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppTheme.neutral300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 16,
              color: AppTheme.neutral600,
            ),
            const SizedBox(width: 4),
            Text(
              sortLabels[_sortBy] ?? 'Sort',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.neutral700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppTheme.neutral600,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildSortMenuItem('recent', 'Recently Created', Icons.access_time, themeData),
        _buildSortMenuItem('name', 'Name (A-Z)', Icons.sort_by_alpha, themeData),
        _buildSortMenuItem('startDate', 'Start Date', Icons.calendar_today, themeData),
        _buildSortMenuItem('budget', 'Budget (High-Low)', Icons.account_balance_wallet, themeData),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label, IconData icon, AppThemeData themeData) {
    final isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? themeData.primaryColor : AppTheme.neutral600,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? themeData.primaryColor : AppTheme.neutral800,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 16,
              color: themeData.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  /// Build a flat list of trips (used when filtering/searching)
  Widget _buildFlatTripList(BuildContext context, List<TripWithMembers> trips) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tripWithMembers = trips[index];
            return FadeSlideAnimation(
              delay: AppAnimations.staggerMedium * index,
              duration: AppAnimations.medium,
              child: TripCard(
                key: ValueKey(tripWithMembers.trip.id),
                tripWithMembers: tripWithMembers,
                onTap: () => context.push('/trips/${tripWithMembers.trip.id}'),
                onEdit: () => _editTrip(context, tripWithMembers.trip),
                onDelete: () => _deleteTrip(context, ref, tripWithMembers.trip),
              ),
            );
          },
          childCount: trips.length,
        ),
      ),
    );
  }

  /// Build grouped trip list with section headers (Active → Upcoming → Completed)
  List<Widget> _buildGroupedTripList(
    BuildContext context,
    List<TripWithMembers> trips,
    AppThemeData themeData,
  ) {
    // Group trips by status
    final activeTrips = <TripWithMembers>[];
    final upcomingTrips = <TripWithMembers>[];
    final completedTrips = <TripWithMembers>[];

    for (final trip in trips) {
      final status = _getTripStatusCategory(trip.trip);
      switch (status) {
        case 'active':
          activeTrips.add(trip);
          break;
        case 'upcoming':
          upcomingTrips.add(trip);
          break;
        case 'completed':
          completedTrips.add(trip);
          break;
      }
    }

    final slivers = <Widget>[];
    int animationIndex = 0;

    // Active trips section
    if (activeTrips.isNotEmpty) {
      slivers.add(_buildSectionHeader(
        context,
        'Active Now',
        Icons.directions_walk,
        const Color(0xFFFF7043),
        activeTrips.length,
      ));
      slivers.add(_buildTripSection(context, activeTrips, animationIndex));
      animationIndex += activeTrips.length;
    }

    // Upcoming trips section
    if (upcomingTrips.isNotEmpty) {
      slivers.add(_buildSectionHeader(
        context,
        'Upcoming',
        Icons.schedule,
        const Color(0xFF5C6BC0),
        upcomingTrips.length,
      ));
      slivers.add(_buildTripSection(context, upcomingTrips, animationIndex));
      animationIndex += upcomingTrips.length;
    }

    // Completed trips section
    if (completedTrips.isNotEmpty) {
      slivers.add(_buildSectionHeader(
        context,
        'Completed',
        Icons.check_circle,
        AppTheme.success,
        completedTrips.length,
      ));
      slivers.add(_buildTripSection(context, completedTrips, animationIndex));
    }

    return slivers;
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMd,
          AppTheme.spacingMd,
          AppTheme.spacingMd,
          AppTheme.spacingXs,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutral800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSection(
    BuildContext context,
    List<TripWithMembers> trips,
    int startIndex,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tripWithMembers = trips[index];
            return FadeSlideAnimation(
              delay: AppAnimations.staggerMedium * (startIndex + index),
              duration: AppAnimations.medium,
              child: TripCard(
                key: ValueKey(tripWithMembers.trip.id),
                tripWithMembers: tripWithMembers,
                onTap: () => context.push('/trips/${tripWithMembers.trip.id}'),
                onEdit: () => _editTrip(context, tripWithMembers.trip),
                onDelete: () => _deleteTrip(context, ref, tripWithMembers.trip),
              ),
            );
          },
          childCount: trips.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      title: 'No trips yet',
      description:
          'Start your journey by creating your first trip.\nPlan, share, and explore together!',
      icon: Icons.explore,
      actionLabel: 'Create Your First Trip',
      onAction: () => context.push('/trips/create'),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    // Determine context-aware message
    String title;
    String subtitle;
    IconData icon;

    if (_statusFilter != 'all' && _searchController.text.isEmpty && !_hasActiveFilters) {
      // Only status filter active
      switch (_statusFilter) {
        case 'active':
          title = 'No active trips';
          subtitle = 'You don\'t have any trips in progress right now';
          icon = Icons.directions_walk;
          break;
        case 'upcoming':
          title = 'No upcoming trips';
          subtitle = 'Plan your next adventure!';
          icon = Icons.schedule;
          break;
        case 'completed':
          title = 'No completed trips';
          subtitle = 'Complete a trip to see it here';
          icon = Icons.check_circle_outline;
          break;
        default:
          title = 'No trips found';
          subtitle = 'Try adjusting your filters';
          icon = Icons.search_off;
      }
    } else {
      title = 'No trips found';
      subtitle = _hasActiveFilters
          ? 'Try adjusting your filters or search terms'
          : 'Try a different search term';
      icon = Icons.search_off;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppTheme.spacingMd * 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: AppTheme.neutral400,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.neutral900,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Show different buttons based on context
                if (_statusFilter == 'upcoming' && _searchController.text.isEmpty && !_hasActiveFilters)
                  GlossyButton(
                    label: 'Create a Trip',
                    icon: Icons.add,
                    onPressed: () => context.push('/trips/create'),
                  )
                else if (_hasAnyFilters)
                  GlossyButton(
                    label: 'Clear All Filters',
                    icon: Icons.clear,
                    onPressed: _clearAllFilters,
                  )
                else
                  GlossyButton(
                    label: 'Clear Search',
                    icon: Icons.clear,
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _isSearching = false;
                      });
                    },
                  ),

                // Show "Browse Public Trips" as secondary action
                if (_statusFilter != 'all' || _searchController.text.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  TextButton.icon(
                    onPressed: () => context.push('/trips/browse'),
                    icon: Icon(Icons.explore, size: 18, color: AppTheme.neutral600),
                    label: Text(
                      'Browse Public Trips',
                      style: TextStyle(color: AppTheme.neutral600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref, AppThemeData themeData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            GlossyButton(
              label: 'Try Again',
              icon: Icons.refresh,
              onPressed: () => ref.invalidate(userTripsProvider),
            ),
          ],
        ),
      ),
    );
  }

  void _editTrip(BuildContext context, TripModel trip) {
    // TODO: Navigate to edit trip page
    context.push('/trips/${trip.id}/edit');
  }

  Future<void> _deleteTrip(
      BuildContext context, WidgetRef ref, TripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.delete_outline, color: AppTheme.error),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            const Text('Delete Trip?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${trip.name}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutral600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(tripRepositoryProvider).deleteTrip(trip.id);
        ref.invalidate(userTripsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Trip deleted successfully'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete trip: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      }
    }
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    // Capture the parent context that has router access
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Menu Items - Trip-specific actions only (Profile/Settings/Theme accessible via bottom nav)
                ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.fitonistPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.card_membership,
                    color: AppTheme.fitonistPurple,
                  ),
                ),
                title: const Text('Join Trip by Code'),
                subtitle: const Text('Enter an invite code'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/join-trip');
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: AppTheme.success,
                  ),
                ),
                title: const Text('Trip History'),
                subtitle: const Text('View completed trips'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/trip-history');
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: AppTheme.error,
                  ),
                ),
                title: const Text('Emergency Services'),
                subtitle: const Text('SOS, hospitals & emergency help'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/emergency');
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.purple,
                  ),
                ),
                title: const Text('Control Room'),
                subtitle: const Text('User management & analytics'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/settings/admin');
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppTheme.error,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (parentContext.mounted) {
                    parentContext.go('/');
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Navigate to filter page using GoRouter (fixes _dependents.isEmpty error)
  Future<void> _navigateToFilterPage(BuildContext context) async {
    // Build query parameters with current filter values
    final queryParams = <String, String>{};

    if (_minBudget != null) {
      queryParams['minBudget'] = _minBudget!.toStringAsFixed(0);
    }
    if (_maxBudget != null) {
      queryParams['maxBudget'] = _maxBudget!.toStringAsFixed(0);
    }
    if (_createdAfter != null) {
      queryParams['createdAfter'] = _createdAfter!.toIso8601String();
    }
    if (_createdBefore != null) {
      queryParams['createdBefore'] = _createdBefore!.toIso8601String();
    }

    // Navigate to filter page using NAMED route (not path) to avoid route matching issues
    final result = await context.pushNamed<Map<String, dynamic>>(
      'tripFilter',
      queryParameters: queryParams,
    );

    // Apply returned filters - GoRouter handles navigation lifecycle properly
    if (result != null && mounted) {
      setState(() {
        _minBudget = result['minBudget'] as double?;
        _maxBudget = result['maxBudget'] as double?;
        _createdAfter = result['createdAfter'] as DateTime?;
        _createdBefore = result['createdBefore'] as DateTime?;
      });
    }
  }

  // Packing luggage animation
  Widget _buildPackingAnimation(BuildContext context) {
    return Center(
      child: AppLoadingIndicator(
        message: 'Packing your trips...',
        size: 90,
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final TripWithMembers tripWithMembers;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.tripWithMembers,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  /// Get trip status info (label, color, icon)
  ({String label, Color color, IconData icon}) _getTripStatus(TripModel trip) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (trip.isCompleted) {
      return (label: 'Completed', color: AppTheme.success, icon: Icons.check_circle);
    }

    if (trip.startDate != null && trip.endDate != null) {
      final startDate = DateTime(trip.startDate!.year, trip.startDate!.month, trip.startDate!.day);
      final endDate = DateTime(trip.endDate!.year, trip.endDate!.month, trip.endDate!.day);

      if (today.isBefore(startDate)) {
        final daysLeft = startDate.difference(today).inDays;
        return (
          label: daysLeft == 1 ? 'Starts tomorrow' : 'In $daysLeft days',
          color: const Color(0xFF5C6BC0), // Indigo
          icon: Icons.schedule,
        );
      } else if (today.isAfter(endDate)) {
        return (label: 'Ended', color: AppTheme.neutral500, icon: Icons.event_busy);
      } else {
        final dayNumber = today.difference(startDate).inDays + 1;
        final totalDays = endDate.difference(startDate).inDays + 1;
        return (
          label: 'Day $dayNumber of $totalDays',
          color: const Color(0xFFFF7043), // Deep orange
          icon: Icons.directions_walk,
        );
      }
    }

    return (label: 'Upcoming', color: const Color(0xFF5C6BC0), icon: Icons.schedule);
  }

  /// Format date range in compact format: "Dec 1-5" or "Dec 1 - Jan 3"
  String _formatCompactDateRange(DateTime start, DateTime end) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (start.month == end.month && start.year == end.year) {
      return '${months[start.month - 1]} ${start.day}-${end.day}';
    }
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final status = _getTripStatus(trip);

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
              // Cover Image with Overlay - Reduced height from 180 to 140
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                ),
                child: DestinationImage(
                  tripName: trip.destination ?? trip.name,
                  height: 140,
                  fit: BoxFit.cover,
                  showOverlay: true,
                  overlayChild: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Status Badge + Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.color,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    boxShadow: [
                                      BoxShadow(
                                        color: status.color.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status.icon,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Actions
                                Row(
                                  children: [
                                    _buildActionButton(
                                      context,
                                      Icons.edit_outlined,
                                      onEdit,
                                    ),
                                    const SizedBox(width: 4),
                                    _buildActionButton(
                                      context,
                                      Icons.delete_outline,
                                      onDelete,
                                      isDestructive: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Bottom: Trip Name
                            Text(
                              trip.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      const Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

              // Trip Details - Consolidated layout
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consolidated Row: Location + Dates
                    Row(
                      children: [
                        // Location
                        if (trip.destination != null) ...[
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              trip.destination!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.neutral700,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        // Separator
                        if (trip.destination != null && trip.startDate != null && trip.endDate != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(color: AppTheme.neutral400),
                            ),
                          ),
                        // Dates
                        if (trip.startDate != null && trip.endDate != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppTheme.neutral500,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatCompactDateRange(trip.startDate!, trip.endDate!),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.neutral600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppTheme.spacingXs),

                    // Bottom Row: Budget + Members
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Budget chip
                        if (trip.budget != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 12,
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCurrency(trip.budget!, trip.currency),
                                  style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        // Members
                        _buildCompactMemberAvatars(members, tripWithMembers.memberCount ?? members.length),
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

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive
            ? AppTheme.error.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isDestructive ? Colors.white : AppTheme.neutral700,
        ),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildCompactMemberAvatars(List<TripMemberModel> members, int totalCount) {
    const maxVisible = 3;
    final visibleMembers = members.take(maxVisible).toList();
    final showCount = visibleMembers.isNotEmpty && totalCount > 0;

    // Smart count formatting
    String formatCount(int count) {
      if (count >= 1000000) {
        return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M+';
      } else if (count >= 1000) {
        return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}K+';
      }
      return '$count';
    }

    if (!showCount) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Overlapping avatars - only show up to maxVisible
        SizedBox(
          width: visibleMembers.length == 1
              ? 32.0
              : (visibleMembers.length * 22.0) + 10.0, // 22px overlap between circles
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(visibleMembers.length, (index) {
              final member = visibleMembers[index];
              return Positioned(
                left: index * 22.0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: UserAvatarWidget(
                      imageUrl: member.avatarUrl,
                      userName: member.fullName ?? member.email,
                      size: 28, // Slightly smaller to account for border
                      showBorder: false,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        // Member count with smart formatting
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: AppTheme.neutral100,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(color: AppTheme.neutral300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people,
                size: 14,
                color: AppTheme.neutral600,
              ),
              const SizedBox(width: 4),
              Text(
                formatCount(totalCount),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount, String currency) {
    // Format currency symbol
    String symbol = '₹';
    if (currency == 'USD') {
      symbol = '\$';
    } else if (currency == 'EUR') {
      symbol = '€';
    } else if (currency == 'GBP') {
      symbol = '£';
    }

    // Format amount with proper separators (no decimals if whole number)
    final wholePart = amount.truncate();
    if (amount == wholePart) {
      // Format as integer with thousand separators
      final formattedAmount = wholePart.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '$symbol$formattedAmount';
    } else {
      // Format with 2 decimal places
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }
}
