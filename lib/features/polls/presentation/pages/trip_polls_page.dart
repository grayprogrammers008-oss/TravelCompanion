import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/trip_permissions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/poll_providers.dart';
import '../widgets/poll_card.dart';
import 'create_poll_page.dart';

class TripPollsPage extends ConsumerWidget {
  const TripPollsPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = context.appThemeData;
    final pollsAsync = ref.watch(tripPollsProvider(tripId));
    final tripAsync = ref.watch(tripProvider(tripId));
    final currentUserId = ref.watch(authStateProvider).value;

    final canManage = tripAsync.whenOrNull(
          data: (t) => TripPermissions.canManagePolls(
            currentUserId: currentUserId,
            tripWithMembers: t,
          ),
        ) ??
        false;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Polls',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: themeData.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: themeData.primaryGradient),
        ),
      ),
      body: pollsAsync.when(
        data: (polls) {
          if (polls.isEmpty) return _emptyState(context, themeData, canManage);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tripPollsProvider(tripId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              itemCount: polls.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacingMd),
              itemBuilder: (context, i) {
                final poll = polls[i];
                return PollCard(
                  poll: poll,
                  onTap: () => context.push('/trips/$tripId/polls/${poll.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppTheme.error),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Could not load polls', style: context.titleMedium),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(tripPollsProvider(tripId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: themeData.primaryColor,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreatePollPage(tripId: tripId),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Poll',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _emptyState(BuildContext context, dynamic themeData, bool canManage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing2xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeData.primaryColor.withValues(alpha: 0.1),
                    themeData.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.how_to_vote_outlined,
                  size: 80, color: themeData.primaryColor),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'No polls yet',
              style: context.headlineSmall.copyWith(
                color: context.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              canManage
                  ? 'Start a vote on where to go, what to do, or which option to pick. Non-voters will be counted as voting for your default.'
                  : 'When the organizer starts a poll, you\'ll see it here.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.textColor.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
