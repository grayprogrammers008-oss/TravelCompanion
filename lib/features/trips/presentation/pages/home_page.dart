import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/easy_mode_provider.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/premium_header.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../shared/models/trip_model.dart';
import '../../../../shared/models/itinerary_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../itinerary/presentation/providers/itinerary_providers.dart';
import '../providers/trip_providers.dart';
import '../widgets/ai_suggestions_card.dart';

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

  // Filter state variables
  double? _minBudget;
  double? _maxBudget;
  DateTime? _createdAfter;
  DateTime? _createdBefore;

  // Status filter: 'all', 'active', 'upcoming', 'completed'
  String _statusFilter = 'all';

  // Sort options: 'recent', 'name', 'startDate', 'budget'
  String _sortBy = 'recent';

  // Simplified view state
  bool _pastTripsExpanded = false;

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

  /// Show bottom sheet with trip creation options
  void _showCreateTripOptions(BuildContext context, AppThemeData themeData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Handle bar
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

              // JOIN A TRIP SECTION - Primary CTA for users with invite codes
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: _buildCreateOption(
                  context: context,
                  icon: Icons.group_add,
                  iconColor: Colors.green,
                  title: 'Join a Trip',
                  subtitle: 'Have an invite code? Enter it here',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/join-trip');
                  },
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Divider with "or create" text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingSm,
                ),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.neutral200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: Text(
                        'or create',
                        style: TextStyle(
                          color: AppTheme.neutral400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.neutral200)),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // Option 0: Quick Trip (NEW - Highlighted)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeData.primaryColor.withValues(alpha: 0.1),
                      themeData.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: themeData.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: _buildCreateOption(
                  context: context,
                  icon: Icons.rocket_launch,
                  iconColor: themeData.primaryColor,
                  title: 'Quick Trip',
                  subtitle: 'Just destination & dates - create in 3 taps!',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/trips/quick');
                  },
                  showBadge: true,
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),

              // Option: AI Trip Wizard (Most powerful - creates everything!)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withValues(alpha: 0.2),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildCreateOption(
                  context: context,
                  icon: Icons.auto_awesome,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'AI Trip Wizard',
                  subtitle: 'Voice → Trip + Itinerary + Packing List in one!',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/trips/ai-wizard');
                  },
                  showAiBadge: true,
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Divider with "or manual" text
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingSm,
                ),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.neutral200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: Text(
                        'or manual',
                        style: TextStyle(
                          color: AppTheme.neutral400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.neutral200)),
                  ],
                ),
              ),

              // Option 1: From Scratch
              _buildCreateOption(
                context: context,
                icon: Icons.edit_note,
                iconColor: AppTheme.neutral600,
                title: 'Start from Scratch',
                subtitle: 'Create a blank trip and customize everything',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/trips/create');
                },
              ),

              // Option 2: Use Template
              _buildCreateOption(
                context: context,
                icon: Icons.dashboard_customize,
                iconColor: const Color(0xFF9C27B0),
                title: 'Use a Template',
                subtitle: 'Browse pre-built itineraries for popular destinations',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/templates');
                },
              ),

              const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a single create option tile
  Widget _buildCreateOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showBadge = false,
    bool showAiBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FAST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      if (showAiBadge) ...[
                        const SizedBox(width: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D9FF), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.neutral400,
            ),
          ],
        ),
      ),
    );
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
    });
  }

  /// Show filter options in a bottom sheet
  void _showFilterBottomSheet(BuildContext context, dynamic themeData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacingMd),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_hasAnyFilters)
                    TextButton(
                      onPressed: () {
                        _clearAllFilters();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: themeData.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Sort Options
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: [
                      _buildSortChip('Recent', 'recent', themeData),
                      _buildSortChip('Name', 'name', themeData),
                      _buildSortChip('Start Date', 'startDate', themeData),
                      _buildSortChip('Budget', 'budget', themeData),
                    ],
                  ),
                ],
              ),
            ),
            // Budget Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBudgetField('Min', _minBudget, (value) {
                          setState(() => _minBudget = value);
                          Navigator.pop(context);
                        }),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: _buildBudgetField('Max', _maxBudget, (value) {
                          setState(() => _maxBudget = value);
                          Navigator.pop(context);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            // Apply Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, dynamic themeData) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? themeData.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? themeData.primaryColor : AppTheme.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.neutral700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetField(String label, double? value, Function(double?) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        filled: true,
        fillColor: AppTheme.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
      ),
      controller: TextEditingController(text: value?.toStringAsFixed(0) ?? ''),
      onSubmitted: (text) {
        final parsed = double.tryParse(text);
        onChanged(parsed);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userTripsAsync = ref.watch(userTripsProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    final easyModeConfig = ref.watch(easyModeConfigProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.whenOrNull(data: (user) => user?.id);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: RefreshIndicator(
          displacement: 80,
          edgeOffset: 80,
          onRefresh: () async {
            ref.invalidate(userTripsProvider);
            await ref.read(userTripsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              // Personalized greeting header
              SliverAppBar(
                expandedHeight: _shouldShowSearchBar(userTripsAsync) ? 140 : 90,
                floating: true,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                  child: _buildProfileAvatar(ref),
                ),
                leadingWidth: 60,
                title: _buildGreetingTitle(ref, userTripsAsync),
                centerTitle: false,
                titleSpacing: 4,
                actions: [
                  // Settings Icon only (consolidated menu)
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
                          // Spacer for the toolbar area (avatar + greeting + settings)
                          const SizedBox(height: kToolbarHeight),
                          // Search bar row - only show when user has > 3 trips
                          if (_shouldShowSearchBar(userTripsAsync))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppTheme.spacingMd,
                                AppTheme.spacingSm,
                                AppTheme.spacingMd,
                                AppTheme.spacingMd,
                              ),
                              child: Row(
                                children: [
                                  // Search Field - Solid white background for better text visibility
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
                                          hintText: 'Where to next? 🌍',
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
                                    onTap: () => _showFilterBottomSheet(context, themeData),
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
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.tune_rounded,
                                            color: _hasActiveFilters
                                                ? themeData.primaryColor
                                                : AppTheme.neutral600,
                                            size: 20,
                                          ),
                                          if (_hasActiveFilters)
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: themeData.primaryColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
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
                // AI Suggestions Card
                SliverToBoxAdapter(
                  child: AiSuggestionsCard(themeData: themeData),
                ),

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
                      ? _buildGroupedTripList(context, filteredTrips, themeData, currentUserId)
                      : [_buildFlatTripList(context, filteredTrips, currentUserId)]),

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
          onTap: () => _showCreateTripOptions(context, themeData),
          child: Container(
            // Easy Mode: ensure minimum touch target size
            constraints: BoxConstraints(
              minHeight: easyModeConfig.minTouchTargetSize,
            ),
            decoration: BoxDecoration(
              gradient: themeData.glossyGradient,
              borderRadius: BorderRadius.circular(
                easyModeConfig.scaleBorderRadius(AppTheme.radiusLg),
              ),
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
                borderRadius: BorderRadius.circular(
                  easyModeConfig.scaleBorderRadius(AppTheme.radiusLg),
                ),
              ),
              child: FloatingActionButton.extended(
                onPressed: null, // Handled by AnimatedScaleButton
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: easyModeConfig.scaleIconSize(24),
                ),
                label: Text(
                  'New Trip',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16 * easyModeConfig.textScaleFactor,
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
  Widget _buildFlatTripList(BuildContext context, List<TripWithMembers> trips, String? currentUserId) {
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
                currentUserId: currentUserId,
              ),
            );
          },
          childCount: trips.length,
        ),
      ),
    );
  }

  /// Build simplified grouped trip list focusing on what matters NOW
  List<Widget> _buildGroupedTripList(
    BuildContext context,
    List<TripWithMembers> trips,
    AppThemeData themeData,
    String? currentUserId,
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

    // Sort upcoming by start date
    upcomingTrips.sort((a, b) {
      final aDate = a.trip.startDate ?? DateTime(2100);
      final bDate = b.trip.startDate ?? DateTime(2100);
      return aDate.compareTo(bDate);
    });

    final slivers = <Widget>[];

    // 1. HAPPENING NOW - Hero card for active trip(s)
    if (activeTrips.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildHappeningNowSection(context, activeTrips, themeData, currentUserId),
      ));
    }

    // 2. QUICK ACTIONS - Big buttons when no active trip
    if (activeTrips.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildQuickActionsSection(context, themeData),
      ));
    }

    // 3. COMING UP - Compact list of upcoming trips
    if (upcomingTrips.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildComingUpSection(context, upcomingTrips, themeData, currentUserId),
      ));
    }

    // 4. PAST TRIPS - Collapsible section
    if (completedTrips.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: _buildPastTripsSection(context, completedTrips, themeData, currentUserId),
      ));
    }

    return slivers;
  }

  /// Build "Happening Now" hero section for active trips
  Widget _buildHappeningNowSection(
    BuildContext context,
    List<TripWithMembers> activeTrips,
    AppThemeData themeData,
    String? currentUserId,
  ) {
    // Take the first active trip as the primary
    final primaryTrip = activeTrips.first;
    final trip = primaryTrip.trip;
    final isOrganizer = currentUserId != null && trip.createdBy == currentUserId;

    // Calculate trip day
    int currentDay = 1;
    int totalDays = 1;
    if (trip.startDate != null) {
      final now = DateTime.now();
      currentDay = now.difference(trip.startDate!).inDays + 1;
      if (trip.endDate != null) {
        totalDays = trip.endDate!.difference(trip.startDate!).inDays + 1;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFFF7043)),
              ),
              const SizedBox(width: 10),
              const Text(
                'HAPPENING NOW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFFFF7043),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Hero trip card
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/trips/${trip.id}');
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeData.primaryColor,
                    themeData.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: themeData.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background image with overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Stack(
                        children: [
                          DestinationImage(
                            imageUrl: trip.coverImageUrl,
                            tripName: trip.destination ?? trip.name,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            showOverlay: false,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day badge + Role badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                'Day $currentDay of $totalDays',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (currentUserId != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOrganizer
                                      ? const Color(0xFFFF9800) // Orange for organizer
                                      : Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isOrganizer ? Icons.star : Icons.person,
                                      size: 12,
                                      color: isOrganizer ? Colors.white : AppTheme.neutral600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOrganizer ? 'Organizer' : 'Member',
                                      style: TextStyle(
                                        color: isOrganizer ? Colors.white : AppTheme.neutral700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Trip name
                        Text(
                          trip.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Destination
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              trip.destination ?? 'No destination',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // What's Next section
                        _buildWhatsNextPreview(context, trip.id, themeData),

                        const SizedBox(height: AppTheme.spacingMd),

                        // Members, SOS and Open button
                        Row(
                          children: [
                            // Member avatars
                            Row(
                              children: [
                                const Icon(Icons.people, color: Colors.white70, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${primaryTrip.members.length} travelers',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // SOS button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                _showSOSBottomSheet(context, primaryTrip);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                                  ),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE53935).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Open trip button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Open Trip',
                                    style: TextStyle(
                                      color: themeData.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 16, color: themeData.primaryColor),
                                ],
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
          ),

          // Show other active trips if any
          if (activeTrips.length > 1) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '+${activeTrips.length - 1} more active ${activeTrips.length == 2 ? 'trip' : 'trips'}',
              style: TextStyle(
                color: AppTheme.neutral600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build "What's Next" preview from itinerary
  Widget _buildWhatsNextPreview(BuildContext context, String tripId, AppThemeData themeData) {
    final itineraryAsync = ref.watch(tripItineraryProvider(tripId));

    return itineraryAsync.when(
      data: (items) {
        // Find the next upcoming activity
        final now = DateTime.now();
        ItineraryItemModel? nextItem;

        for (final item in items) {
          if (item.startTime != null && item.startTime!.isAfter(now)) {
            if (nextItem == null || item.startTime!.isBefore(nextItem.startTime!)) {
              nextItem = item;
            }
          }
        }

        if (nextItem == null) {
          return const SizedBox.shrink();
        }

        final timeFormat = DateFormat('h:mm a');

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.schedule, color: Colors.white, size: 16),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What's Next",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${nextItem.title} @ ${timeFormat.format(nextItem.startTime!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  /// Build quick actions section when no active trip
  Widget _buildQuickActionsSection(BuildContext context, AppThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          // New Trip button
          Expanded(
            child: _buildBigActionButton(
              context,
              icon: Icons.add_circle,
              label: 'New Trip',
              color: themeData.primaryColor,
              onTap: () => _showCreateTripOptions(context, themeData),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          // Ideas/Templates button
          Expanded(
            child: _buildBigActionButton(
              context,
              icon: Icons.lightbulb_outline,
              label: 'Get Ideas',
              color: const Color(0xFFFF9800),
              onTap: () => context.push('/templates'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a big action button
  Widget _buildBigActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build "Coming Up" section for upcoming trips
  Widget _buildComingUpSection(
    BuildContext context,
    List<TripWithMembers> upcomingTrips,
    AppThemeData themeData,
    String? currentUserId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule, size: 16, color: Color(0xFF5C6BC0)),
              ),
              const SizedBox(width: 10),
              const Text(
                'COMING UP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF5C6BC0),
                ),
              ),
              const Spacer(),
              Text(
                '${upcomingTrips.length} ${upcomingTrips.length == 1 ? 'trip' : 'trips'}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Compact trip list
          ...upcomingTrips.take(3).map((tripWithMembers) {
            return _buildCompactTripRow(context, tripWithMembers, themeData, currentUserId);
          }),

          // Show more if needed
          if (upcomingTrips.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = 'upcoming');
                },
                child: Text(
                  'See all ${upcomingTrips.length} upcoming trips →',
                  style: TextStyle(
                    color: themeData.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build compact trip row for upcoming/past trips
  Widget _buildCompactTripRow(
    BuildContext context,
    TripWithMembers tripWithMembers,
    AppThemeData themeData,
    String? currentUserId,
  ) {
    final trip = tripWithMembers.trip;
    final dateFormat = DateFormat('MMM d');
    final isOrganizer = currentUserId != null && trip.createdBy == currentUserId;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/trips/${trip.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingXs),
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.neutral200),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: 48,
                height: 48,
                child: DestinationImage(
                  imageUrl: trip.coverImageUrl,
                  tripName: trip.destination ?? trip.name,
                  height: 48,
                  width: 48,
                  fit: BoxFit.cover,
                  showOverlay: false,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (trip.startDate != null) ...[
                        Text(
                          dateFormat.format(trip.startDate!),
                          style: TextStyle(
                            color: AppTheme.neutral600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${tripWithMembers.members.length} travelers',
                        style: TextStyle(
                          color: AppTheme.neutral500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Role badge (small indicator for organizer)
            if (currentUserId != null && isOrganizer) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 10, color: const Color(0xFFFF9800)),
                    const SizedBox(width: 2),
                    Text(
                      'Organizer',
                      style: TextStyle(
                        color: const Color(0xFFFF9800),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
            // Arrow
            Icon(Icons.chevron_right, color: AppTheme.neutral400, size: 20),
          ],
        ),
      ),
    );
  }

  /// Build "Past Trips" collapsible section
  Widget _buildPastTripsSection(
    BuildContext context,
    List<TripWithMembers> completedTrips,
    AppThemeData themeData,
    String? currentUserId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (tappable to expand/collapse)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _pastTripsExpanded = !_pastTripsExpanded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_circle, size: 16, color: AppTheme.success),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PAST TRIPS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${completedTrips.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutral600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _pastTripsExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsed or expanded content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _pastTripsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: AppTheme.spacingSm),
                ...completedTrips.take(5).map((tripWithMembers) {
                  return _buildCompactTripRow(context, tripWithMembers, themeData, currentUserId);
                }),
                if (completedTrips.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _statusFilter = 'completed');
                      },
                      child: Text(
                        'See all ${completedTrips.length} past trips →',
                        style: TextStyle(
                          color: themeData.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// V2.0 Empty State - Trip-First Design
  /// Primary CTA: Plan a Trip (AI Voice)
  /// Secondary: Have a code? Join →
  /// Hint: Check Explore tab for public trips
  Widget _buildEmptyState(BuildContext context) {
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Backpack icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: themeData.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.luggage_outlined,
                size: 64,
                color: themeData.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Title
            Text(
              'No trips yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),

            // Subtitle - simplified
            Text(
              'Plan a trip in 30 seconds with AI,\nor join a friend\'s trip.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutral600,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),

            // PRIMARY CTA - Plan a Trip with AI (Big prominent button)
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF),
                      const Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/trips/ai-wizard'),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLg,
                        vertical: AppTheme.spacingMd + 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plan a Trip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'AI creates itinerary & packing list',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Secondary link - Have a code? Join
            TextButton.icon(
              onPressed: () => context.push('/join-trip'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.neutral700,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
              ),
              icon: const Icon(Icons.link, size: 18),
              label: const Text(
                'Have a trip code?  Join →',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Hint about Explore tab
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXs),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Check the Explore tab to browse public trips you can join!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutral600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  /// Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Get user's first name from full name or email
  String _getFirstName(String? fullName, String? email) {
    if (fullName != null && fullName.isNotEmpty) {
      return fullName.split(' ').first;
    }
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Explorer';
  }

  /// Get contextual subtitle based on trips
  String _getContextualSubtitle(List<TripWithMembers> trips) {
    if (trips.isEmpty) {
      return 'Plan your first adventure!';
    }

    final now = DateTime.now();
    final upcomingTrips = trips.where((t) =>
      t.trip.startDate != null && t.trip.startDate!.isAfter(now) && !t.trip.isCompleted
    ).toList();

    if (upcomingTrips.isNotEmpty) {
      // Sort by start date to get the nearest upcoming trip
      upcomingTrips.sort((a, b) => a.trip.startDate!.compareTo(b.trip.startDate!));
      final nextTrip = upcomingTrips.first;
      final daysUntil = nextTrip.trip.startDate!.difference(now).inDays;

      if (daysUntil == 0) {
        return '${nextTrip.trip.destination ?? nextTrip.trip.name} starts today!';
      } else if (daysUntil == 1) {
        return '${nextTrip.trip.destination ?? nextTrip.trip.name} tomorrow!';
      } else if (daysUntil <= 7) {
        return '${nextTrip.trip.destination ?? nextTrip.trip.name} in $daysUntil days';
      } else {
        return '${upcomingTrips.length} upcoming ${upcomingTrips.length == 1 ? 'adventure' : 'adventures'}';
      }
    }

    final activeTrips = trips.where((t) => !t.trip.isCompleted).length;
    if (activeTrips > 0) {
      return '$activeTrips active ${activeTrips == 1 ? 'trip' : 'trips'}';
    }

    return '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'} completed';
  }

  /// Check if search bar should be shown (when > 3 trips)
  bool _shouldShowSearchBar(AsyncValue<List<TripWithMembers>> tripsAsync) {
    return tripsAsync.maybeWhen(
      data: (trips) => trips.length > 3,
      orElse: () => false,
    );
  }

  /// Build personalized greeting title widget
  Widget _buildGreetingTitle(WidgetRef ref, AsyncValue<List<TripWithMembers>> tripsAsync) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        final greeting = _getGreeting();
        final firstName = _getFirstName(user?.fullName, user?.email);
        final subtitle = tripsAsync.maybeWhen(
          data: (trips) => _getContextualSubtitle(trips),
          orElse: () => 'Loading your trips...',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$greeting, $firstName!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      },
      loading: () => const Text(
        'Loading...',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      error: (_, __) => const Text(
        'My Trips',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

  // Packing luggage animation
  Widget _buildPackingAnimation(BuildContext context) {
    return Center(
      child: AppLoadingIndicator(
        message: 'Packing your trips...',
        size: 90,
      ),
    );
  }

  /// Show SOS emergency bottom sheet with emergency features
  void _showSOSBottomSheet(BuildContext context, TripWithMembers tripWithMembers) {
    final destination = tripWithMembers.trip.destination ?? 'Unknown';
    final members = tripWithMembers.members;
    final currentUserId = ref.read(authStateProvider).value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Location: $destination',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Emergency Services Section
                    _buildSOSSection(
                      title: 'Emergency Services',
                      icon: Icons.local_hospital_rounded,
                      color: const Color(0xFFE53935),
                      children: [
                        _buildEmergencyTile(
                          icon: Icons.local_police_rounded,
                          title: 'Police',
                          subtitle: 'Emergency: 100',
                          color: const Color(0xFF1976D2),
                          onTap: () => _makeEmergencyCall('100'),
                        ),
                        _buildEmergencyTile(
                          icon: Icons.local_hospital_rounded,
                          title: 'Ambulance',
                          subtitle: 'Emergency: 108',
                          color: const Color(0xFFE53935),
                          onTap: () => _makeEmergencyCall('108'),
                        ),
                        _buildEmergencyTile(
                          icon: Icons.fire_extinguisher,
                          title: 'Fire',
                          subtitle: 'Emergency: 101',
                          color: const Color(0xFFFF6D00),
                          onTap: () => _makeEmergencyCall('101'),
                        ),
                        _buildEmergencyTile(
                          icon: Icons.support_agent_rounded,
                          title: 'Women Helpline',
                          subtitle: 'Emergency: 1091',
                          color: const Color(0xFFE91E63),
                          onTap: () => _makeEmergencyCall('1091'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Contact Co-Travelers Section
                    _buildSOSSection(
                      title: 'Contact Co-Travelers',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF7E57C2),
                      children: [
                        ...members.map((member) => _buildMemberCallTile(context, member, currentUserId)),
                        if (members.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No co-travelers in this trip',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick Actions Section
                    _buildSOSSection(
                      title: 'Quick Actions',
                      icon: Icons.flash_on_rounded,
                      color: const Color(0xFFFF9800),
                      children: [
                        _buildSOSActionTile(
                          icon: Icons.broadcast_on_personal_rounded,
                          title: 'Emergency Broadcast',
                          subtitle: 'Send alert to all trip members',
                          color: const Color(0xFFE53935),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _sendEmergencyBroadcast(context, tripWithMembers);
                          },
                        ),
                        _buildSOSActionTile(
                          icon: Icons.location_on_rounded,
                          title: 'Share Live Location',
                          subtitle: 'Share your location with trip group',
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _shareLiveLocation(context);
                          },
                        ),
                        _buildSOSActionTile(
                          icon: Icons.navigate_next_rounded,
                          title: 'Find Nearest Hospital',
                          subtitle: 'Open maps for nearby hospitals',
                          color: const Color(0xFF2196F3),
                          onTap: () => _openNearbyHospitals(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.neutral800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCallTile(BuildContext context, TripMemberModel member, String? currentUserId) {
    final isCurrentUser = member.userId == currentUserId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrentUser ? null : () {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling ${member.fullName ?? 'Member'}...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF7E57C2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              UserAvatarWidget(
                imageUrl: member.avatarUrl,
                userName: member.fullName ?? 'User',
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.fullName ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      member.role == 'organizer' ? 'Organizer' : member.role == 'admin' ? 'Admin' : 'Member',
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCurrentUser)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Color(0xFF7E57C2), size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.neutral500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.neutral400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makeEmergencyCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not call $number'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sendEmergencyBroadcast(BuildContext context, TripWithMembers tripWithMembers) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.broadcast_on_personal_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Emergency alert sent to all trip members!')),
          ],
        ),
        backgroundColor: Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Navigate to trip detail
    context.push('/trips/${tripWithMembers.trip.id}');
  }

  void _shareLiveLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Live location sharing started for 1 hour')),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openNearbyHospitals() async {
    final uri = Uri.parse('https://www.google.com/maps/search/hospitals+near+me');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class TripCard extends StatelessWidget {
  final TripWithMembers tripWithMembers;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? currentUserId; // To determine if user is organizer

  const TripCard({
    super.key,
    required this.tripWithMembers,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.currentUserId,
  });

  /// Check if current user is the trip organizer (creator)
  bool get isOrganizer => currentUserId != null && tripWithMembers.trip.createdBy == currentUserId;

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
                  imageUrl: trip.coverImageUrl,
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
                            // Top Row: Status Badge + Role Badge + Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Left: Status Badge + Role Badge
                                Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    // Role Badge (Organizer or Member)
                                    if (currentUserId != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingSm,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOrganizer
                                              ? const Color(0xFFFF9800) // Orange for organizer
                                              : Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isOrganizer ? Icons.star : Icons.person,
                                              size: 12,
                                              color: isOrganizer ? Colors.white : AppTheme.neutral600,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              isOrganizer ? 'Organizer' : 'Member',
                                              style: TextStyle(
                                                color: isOrganizer ? Colors.white : AppTheme.neutral700,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
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
