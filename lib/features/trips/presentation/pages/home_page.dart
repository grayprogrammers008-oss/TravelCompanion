import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/extensions.dart';
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

  // Filter state
  double? _minBudget;
  double? _maxBudget;
  DateTime? _createdAfter;
  DateTime? _createdBefore;

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

  List<TripWithMembers> _filterTrips(List<TripWithMembers> trips) {
    final query = _searchController.text.toLowerCase().trim();

    return trips.where((tripWithMembers) {
      final trip = tripWithMembers.trip;

      // Search filter
      if (query.isNotEmpty) {
        final nameMatch = trip.name.toLowerCase().contains(query);
        final destinationMatch = trip.destination?.toLowerCase().contains(query) ?? false;
        final descriptionMatch = trip.description?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !destinationMatch && !descriptionMatch) {
          return false;
        }
      }

      // Budget filter
      if (_minBudget != null && trip.budget != null) {
        if (trip.budget! < _minBudget!) return false;
      }
      if (_maxBudget != null && trip.budget != null) {
        if (trip.budget! > _maxBudget!) return false;
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
  }

  bool get _hasActiveFilters {
    return _minBudget != null ||
           _maxBudget != null ||
           _createdAfter != null ||
           _createdBefore != null;
  }

  void _clearFilters() {
    setState(() {
      _minBudget = null;
      _maxBudget = null;
      _createdAfter = null;
      _createdBefore = null;
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
                    onPressed: () => _showFilterSheet(context),
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
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
          userTripsAsync.when(
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
                      // Staggered animation for each card
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
                    childCount: filteredTrips.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: _buildPackingAnimation(context),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: _buildErrorState(context, error.toString(), ref, themeData),
            ),
          ),
        ],
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
                    Icons.search_off,
                    size: 48,
                    color: AppTheme.neutral400,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'No trips found',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.neutral900,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Try a different search term',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
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

                // Menu Items
                ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: context.primaryColor,
                  ),
                ),
                title: const Text('Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/profile');
                  }
                },
              ),
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
                    color: context.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: context.accentColor,
                  ),
                ),
                title: const Text('Theme'),
                subtitle: const Text('Customize app colors'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/settings/theme');
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppTheme.neutral600,
                  ),
                ),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  // Wait for bottom sheet to close before navigating
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (parentContext.mounted) {
                    parentContext.push('/settings');
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

  void _showFilterSheet(BuildContext context) {
    final TextEditingController minBudgetController = TextEditingController(
      text: _minBudget?.toStringAsFixed(0) ?? '',
    );
    final TextEditingController maxBudgetController = TextEditingController(
      text: _maxBudget?.toStringAsFixed(0) ?? '',
    );

    DateTime? tempCreatedAfter = _createdAfter;
    DateTime? tempCreatedBefore = _createdBefore;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXl),
              topRight: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: AppTheme.spacingMd),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title and Clear button
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Trips',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (_hasActiveFilters)
                          TextButton(
                            onPressed: () {
                              // Clear the main state
                              _clearFilters();
                              minBudgetController.clear();
                              maxBudgetController.clear();

                              // Update modal state
                              setModalState(() {
                                tempCreatedAfter = null;
                                tempCreatedBefore = null;
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                  ),

                  // Budget Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_money, size: 20, color: AppTheme.success),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              'Budget Range',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minBudgetController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min Budget',
                                  hintText: '0',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingSm,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: TextField(
                                controller: maxBudgetController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max Budget',
                                  hintText: '100000',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingSm,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Date Created Filter Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: AppTheme.info),
                            const SizedBox(width: AppTheme.spacingXs),
                            Text(
                              'Date Created',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: tempCreatedAfter ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() {
                                      tempCreatedAfter = date;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingMd,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.neutral300),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 20),
                                      const SizedBox(width: AppTheme.spacingSm),
                                      Expanded(
                                        child: Text(
                                          tempCreatedAfter != null
                                              ? '${tempCreatedAfter!.day.toString().padLeft(2, '0')}/${tempCreatedAfter!.month.toString().padLeft(2, '0')}/${tempCreatedAfter!.year}'
                                              : 'From Date',
                                          style: TextStyle(
                                            color: tempCreatedAfter != null
                                                ? AppTheme.neutral900
                                                : AppTheme.neutral500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (tempCreatedAfter != null)
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              tempCreatedAfter = null;
                                            });
                                          },
                                          child: const Icon(
                                            Icons.clear,
                                            size: 18,
                                            color: AppTheme.neutral600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: tempCreatedBefore ?? DateTime.now(),
                                    firstDate: tempCreatedAfter ?? DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setModalState(() {
                                      tempCreatedBefore = date;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: AppTheme.spacingMd,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.neutral300),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month, size: 20),
                                      const SizedBox(width: AppTheme.spacingSm),
                                      Expanded(
                                        child: Text(
                                          tempCreatedBefore != null
                                              ? '${tempCreatedBefore!.day.toString().padLeft(2, '0')}/${tempCreatedBefore!.month.toString().padLeft(2, '0')}/${tempCreatedBefore!.year}'
                                              : 'To Date',
                                          style: TextStyle(
                                            color: tempCreatedBefore != null
                                                ? AppTheme.neutral900
                                                : AppTheme.neutral500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (tempCreatedBefore != null)
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              tempCreatedBefore = null;
                                            });
                                          },
                                          child: const Icon(
                                            Icons.clear,
                                            size: 18,
                                            color: AppTheme.neutral600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Store values before closing
                          final minBudget = minBudgetController.text.isNotEmpty
                              ? double.tryParse(minBudgetController.text)
                              : null;
                          final maxBudget = maxBudgetController.text.isNotEmpty
                              ? double.tryParse(maxBudgetController.text)
                              : null;
                          final createdAfter = tempCreatedAfter;
                          final createdBefore = tempCreatedBefore;

                          // Close the bottom sheet
                          Navigator.pop(context);

                          // Wait a bit for navigation to complete
                          await Future.delayed(const Duration(milliseconds: 100));

                          // Update state after sheet is closed
                          if (mounted) {
                            setState(() {
                              _minBudget = minBudget;
                              _maxBudget = maxBudget;
                              _createdAfter = createdAfter;
                              _createdBefore = createdBefore;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
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
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      minBudgetController.dispose();
      maxBudgetController.dispose();
    });
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

  @override
  Widget build(BuildContext context) {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final daysLeft = trip.startDate?.difference(DateTime.now()).inDays;

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
                            // Actions Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Edit Button
                                _buildActionButton(
                                  context,
                                  Icons.edit_outlined,
                                  onEdit,
                                ),
                                const SizedBox(width: AppTheme.spacingXs),
                                // Delete Button
                                _buildActionButton(
                                  context,
                                  Icons.delete_outline,
                                  onDelete,
                                  isDestructive: true,
                                ),
                              ],
                            ),

                            // Trip Info Overlay
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Days Left Badge
                                if (daysLeft != null && daysLeft > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSm,
                                      vertical: AppTheme.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.accentColor,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusFull),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$daysLeft days left',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: AppTheme.spacingXs),

                                // Trip Name
                                Text(
                                  trip.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          const Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
                    // Destination
                    if (trip.destination != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral100,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              trip.destination!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.neutral700,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Dates
                    if (trip.startDate != null || trip.endDate != null) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.neutral100,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              _formatDateRange(trip.startDate, trip.endDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.neutral600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingMd),

                    // Members in bottom right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return 'Dates not set';
    if (startDate != null && endDate != null) {
      return '${startDate.toFormattedDate()} - ${endDate.toFormattedDate()}';
    }
    if (startDate != null) {
      return 'From ${startDate.toFormattedDate()}';
    }
    return 'Until ${endDate!.toFormattedDate()}';
  }
}
