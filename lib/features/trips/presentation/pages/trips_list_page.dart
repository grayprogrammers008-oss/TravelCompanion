import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/animations/animation_constants.dart';
import 'package:travel_crew/core/animations/animated_widgets.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/core/router/app_router.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/core/utils/extensions.dart';

/// Main page showing list of user's trips
class TripsListPage extends ConsumerWidget {
  const TripsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(userTripsProvider);
    final themeData = context.appThemeData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Trip History',
            onPressed: () => context.push(AppRoutes.tripHistory),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showProfileMenu(context, ref),
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildTripsList(context, ref, trips);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: ScaleAnimation(
        duration: AppAnimations.slow,
        curve: AppAnimations.spring,
        child: AnimatedScaleButton(
          onTap: () => context.push(AppRoutes.createTrip),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 120, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No trips yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.createTrip),
            icon: const Icon(Icons.add),
            label: const Text('Create Trip'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading trips',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ref.invalidate(userTripsProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(
    BuildContext context,
    WidgetRef ref,
    List<TripWithMembers> trips,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userTripsProvider);
        await ref.read(userTripsProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final tripWithMembers = trips[index];
          final trip = tripWithMembers.trip;
          final members = tripWithMembers.members;

          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                context.push(
                  AppRoutes.tripDetail.replaceAll(':tripId', trip.id),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image
                  if (trip.coverImageUrl != null)
                    Image.network(
                      trip.coverImageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage(context);
                      },
                    )
                  else
                    _buildPlaceholderImage(context),

                  // Trip Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (trip.destination != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip.destination!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (trip.startDate != null || trip.endDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateRange(trip.startDate, trip.endDate),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Member avatars
                            if (members.isNotEmpty) ...[
                              _buildMemberAvatars(context, members),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
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
        },
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.flight_takeoff, size: 60, color: Colors.white70),
      ),
    );
  }

  Widget _buildMemberAvatars(
    BuildContext context,
    List<TripMemberModel> members,
  ) {
    const maxVisible = 3;
    final visibleMembers = members.take(maxVisible).toList();
    final remaining = members.length - maxVisible;

    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < visibleMembers.length; i++)
            Positioned(
              left: i * 24.0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (visibleMembers[i].email ??
                          visibleMembers[i].fullName ??
                          '?')[0]
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: maxVisible * 24.0,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: Text(
                  '+$remaining',
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Dates not set';
    if (start != null && end != null) {
      return '${start.toFormattedDate()} - ${end.toFormattedDate()}';
    }
    if (start != null) return 'From ${start.toFormattedDate()}';
    return 'Until ${end!.toFormattedDate()}';
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile page
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
