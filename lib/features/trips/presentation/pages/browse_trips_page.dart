import 'package:flutter/material.dart';
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

  /// Filter trips based on search query
  List<TripWithMembers> _filterTrips(List<TripWithMembers> trips) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return trips;

    return trips.where((tripWithMembers) {
      final trip = tripWithMembers.trip;
      final nameMatch = trip.name.toLowerCase().contains(query);
      final destinationMatch = trip.destination?.toLowerCase().contains(query) ?? false;
      final descriptionMatch = trip.description?.toLowerCase().contains(query) ?? false;
      return nameMatch || destinationMatch || descriptionMatch;
    }).toList();
  }

  /// Handle joining a trip
  Future<void> _joinTrip(BuildContext context, String tripId, String tripName) async {
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

      // Refresh both discoverable and user trips
      ref.invalidate(discoverableTripsProvider);
      ref.invalidate(userTripsProvider);

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "$tripName"!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                context.push('/trips/$tripId');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join trip: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _joinTrip(context, tripId, tripName),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoverableTripsAsync = ref.watch(discoverableTripsProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: RefreshIndicator(
          displacement: 120,
          edgeOffset: 120,
          onRefresh: () async {
            ref.invalidate(discoverableTripsProvider);
            await ref.read(discoverableTripsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              // Compact header with permanent search bar
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                ),
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
                          // Top row: Back button space + Title
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              56, // Space for back button
                              AppTheme.spacingSm,
                              AppTheme.spacingMd,
                              0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: const Icon(
                                    Icons.explore,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Browse Trips',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Discover and join public trips',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search bar row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spacingMd,
                              AppTheme.spacingSm,
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
                                  hintText: 'Search trips...',
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
                              onJoin: () => _joinTrip(
                                context,
                                tripWithMembers.trip.id,
                                tripWithMembers.trip.name,
                              ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
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
                Icons.explore_off,
                size: 64,
                color: AppTheme.neutral400,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Public Trips Available',
              style: context.titleStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'There are currently no public trips to join.\nCheck back later or create your own!',
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trips/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingMd,
                ),
              ),
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
class DiscoverableTripCard extends StatelessWidget {
  final TripWithMembers tripWithMembers;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const DiscoverableTripCard({
    super.key,
    required this.tripWithMembers,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final trip = tripWithMembers.trip;
    final members = tripWithMembers.members;
    final memberCount = members.length;

    // Calculate days until trip starts
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
                            // Public Badge
                            Row(
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
                              ],
                            ),

                            // Days Left Badge
                            if (daysLeft != null && daysLeft > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingSm,
                                  vertical: AppTheme.spacingXs,
                                ),
                                decoration: BoxDecoration(
                                  color: context.accentColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
                                      '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
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
                        _buildInfoChip(
                          context,
                          icon: Icons.people_outline,
                          label: '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                        ),

                        const SizedBox(width: AppTheme.spacingSm),

                        // Date
                        if (trip.startDate != null)
                          _buildInfoChip(
                            context,
                            icon: Icons.calendar_today_outlined,
                            label: trip.startDate!.toLocal().toShortDate(),
                          ),
                      ],
                    ),

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
          Text(
            label,
            style: context.bodyStyle.copyWith(
              fontSize: 12,
              color: context.textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
