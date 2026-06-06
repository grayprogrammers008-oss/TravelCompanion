import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/data/services/trip_notification_service.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../domain/entities/poll_entity.dart';
import '../../domain/entities/poll_option_entity.dart';
import '../../domain/entities/poll_result_entity.dart';
import '../providers/poll_providers.dart';

class PollDetailPage extends ConsumerStatefulWidget {
  const PollDetailPage({
    super.key,
    required this.tripId,
    required this.pollId,
  });

  final String tripId;
  final String pollId;

  @override
  ConsumerState<PollDetailPage> createState() => _PollDetailPageState();
}

class _PollDetailPageState extends ConsumerState<PollDetailPage> {
  String? _pendingOptionId;

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    // Derive the poll header from the trip-polls stream we already subscribe
    // to from the list page. Avoids a second RPC roundtrip and a rebuild loop
    // we hit earlier when a separate FutureProvider competed with the stream.
    final tripPollsAsync = ref.watch(tripPollsProvider(widget.tripId));
    final optionsAsync = ref.watch(pollOptionsProvider(widget.pollId));
    final resultsAsync = ref.watch(pollResultsProvider(widget.pollId));
    final currentUserId = ref.watch(authStateProvider).value;

    final pollAsync = tripPollsAsync.whenData((polls) {
      for (final p in polls) {
        if (p.id == widget.pollId) return p;
      }
      return null;
    });

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Poll',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: themeData.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: themeData.primaryGradient),
        ),
        actions: _buildAppBarActions(
          poll: pollAsync.value,
          currentUserId: currentUserId,
          results: resultsAsync.value,
        ),
      ),
      body: pollAsync.when(
        data: (poll) {
          if (poll == null) return const Center(child: Text('Poll not found'));
          return optionsAsync.when(
            data: (options) => resultsAsync.when(
              data: (results) => _buildBody(poll, options, results),
              loading: () => _buildBody(poll, options, null),
              error: (e, _) => _buildBody(poll, options, null, error: e),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorView(e),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorView(e),
      ),
    );
  }

  Widget _errorView(Object e) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Text(
            e.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: context.bodyMedium,
          ),
        ),
      );

  Widget _buildBody(
    PollEntity poll,
    List<PollOptionEntity> options,
    PollResultEntity? results, {
    Object? error,
  }) {
    final canVote = poll.isOpenForVoting;
    final deadlineLabel = DateFormat('EEE, MMM d • h:mm a').format(poll.deadline);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tripPollsProvider(widget.tripId));
        ref.invalidate(pollOptionsProvider(widget.pollId));
        ref.invalidate(pollResultsProvider(widget.pollId));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          _statusBanner(poll),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            poll.question,
            style: context.headlineSmall.copyWith(
              color: context.textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              Icon(Icons.event,
                  size: 14, color: context.textColor.withValues(alpha: 0.55)),
              const SizedBox(width: 4),
              Text(
                canVote ? 'Closes $deadlineLabel' : 'Closed',
                style: context.bodySmall.copyWith(
                  color: context.textColor.withValues(alpha: 0.6),
                ),
              ),
              if (poll.creatorName != null) ...[
                const SizedBox(width: AppTheme.spacingSm),
                Text('•',
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.4),
                    )),
                const SizedBox(width: AppTheme.spacingSm),
                Flexible(
                  child: Text(
                    'by ${poll.creatorName}',
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ...options.map((opt) => _optionTile(poll, opt, results, canVote)),
          if (results != null) ...[
            const SizedBox(height: AppTheme.spacingLg),
            _tallyFooter(results),
          ],
          if (error != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: context.bodySmall.copyWith(color: AppTheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(PollEntity poll) {
    final isOpen = poll.isOpenForVoting;
    final color = isOpen
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(isOpen ? Icons.how_to_vote : Icons.lock_outline,
              color: color, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              isOpen
                  ? poll.timeRemainingLabel
                  : 'This poll is closed',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionTile(
    PollEntity poll,
    PollOptionEntity opt,
    PollResultEntity? results,
    bool canVote,
  ) {
    final isSelected = poll.currentUserOptionId == opt.id;
    final isDefault = poll.defaultOptionId == opt.id;
    final isPending = _pendingOptionId == opt.id;

    int explicit = 0;
    int effective = 0;
    int denom = 0;
    if (results != null) {
      final row = results.rows.firstWhere(
        (r) => r.optionId == opt.id,
        orElse: () => PollResultRowEntity(
          optionId: opt.id,
          label: opt.label,
          position: opt.position,
          isDefault: isDefault,
          explicitVotes: 0,
          effectiveVotes: 0,
        ),
      );
      explicit = row.explicitVotes;
      effective = row.effectiveVotes;
      denom = results.totalMembers > 0 ? results.totalMembers : 1;
    }
    final fraction = denom == 0 ? 0.0 : effective / denom;

    final primary = Theme.of(context).colorScheme.primary;
    final accent = isSelected ? primary : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: InkWell(
        onTap: canVote && !isPending ? () => _vote(opt.id) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: accent.withValues(alpha: isSelected ? 0.8 : 0.25),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: accent,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      opt.label,
                      style: context.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB8860B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (isPending)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if (results != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      results.isFinal
                          ? '$effective vote${effective == 1 ? "" : "s"}'
                          : '$explicit cast${isDefault && results.totalNonVoters > 0 ? " (+${results.totalNonVoters} if no-show)" : ""}',
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: context.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.textColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tallyFooter(PollResultEntity results) {
    final winner = results.winner;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.textColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            results.isFinal ? 'Final result' : 'Live results',
            style: context.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          if (winner != null)
            Text(
              results.isFinal
                  ? '${winner.label} wins'
                  : '${winner.label} is currently ahead',
              style: context.bodyMedium.copyWith(
                color: context.textColor.withValues(alpha: 0.85),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${results.totalVoted} of ${results.totalMembers} member${results.totalMembers == 1 ? "" : "s"} voted${results.totalNonVoters > 0 && !results.isFinal ? " — ${results.totalNonVoters} default-bound if they don't" : ""}',
            style: context.bodySmall.copyWith(
              color: context.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _vote(String optionId) async {
    setState(() => _pendingOptionId = optionId);
    final ok = await ref
        .read(pollControllerProvider.notifier)
        .castVote(pollId: widget.pollId, optionId: optionId);
    if (!mounted) return;
    setState(() => _pendingOptionId = null);
    if (ok) {
      ref.invalidate(tripPollsProvider(widget.tripId));
    } else {
      final err = ref.read(pollControllerProvider).error ?? 'Could not vote';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  List<Widget> _buildAppBarActions({
    required PollEntity? poll,
    required String? currentUserId,
    required PollResultEntity? results,
  }) {
    debugPrint(
        '🧭 [actions] poll=${poll?.id} createdBy=${poll?.createdBy} '
        'currentUserId=$currentUserId isEffectivelyClosed=${poll?.isEffectivelyClosed}');
    if (poll == null) {
      debugPrint('🧭 [actions] -> no icons (poll is null)');
      return const [];
    }
    final isOrganizer = poll.createdBy == currentUserId;
    if (!isOrganizer) {
      debugPrint('🧭 [actions] -> no icons (not organizer)');
      return const [];
    }
    debugPrint(
        '🧭 [actions] -> showing icons (flag=${!poll.isEffectivelyClosed}, delete=true)');
    return [
      if (!poll.isEffectivelyClosed)
        IconButton(
          tooltip: 'Close poll',
          icon: const Icon(Icons.flag, color: Colors.white),
          onPressed: () => _confirmClose(poll, results),
        ),
      IconButton(
        tooltip: 'Delete poll',
        icon: const Icon(Icons.delete_outline, color: Colors.white),
        onPressed: () => _confirmDelete(poll),
      ),
    ];
  }

  Future<void> _confirmClose(PollEntity poll, PollResultEntity? results) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close poll now?'),
        content: const Text(
          'Anyone who hasn\'t voted will be counted as voting for the default. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Close poll'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok =
        await ref.read(pollControllerProvider.notifier).closePoll(widget.pollId);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(pollControllerProvider).error ?? 'Could not close';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ref.invalidate(tripPollsProvider(widget.tripId));
    ref.invalidate(pollResultsProvider(widget.pollId));
    unawaited(_notifyMembersOfClose(poll, results));
  }

  Future<void> _confirmDelete(PollEntity poll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this poll?'),
        content: Text(
          'This permanently removes "${poll.question}" and all of its '
          'options and votes. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(pollControllerProvider.notifier)
        .deletePoll(widget.pollId);
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(pollControllerProvider).error ?? 'Could not delete';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    // Pop back to the polls list and let the trip-polls stream refresh.
    ref.invalidate(tripPollsProvider(widget.tripId));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll deleted')),
    );
  }

  Future<void> _notifyMembersOfClose(
    PollEntity poll,
    PollResultEntity? results,
  ) async {
    try {
      // Refetch to get the *final* tally that includes default-fill.
      final finalResults = results?.isFinal == true
          ? results
          : await ref
              .read(pollRepositoryProvider)
              .getPollResults(widget.pollId);
      final winnerLabel = finalResults?.winner?.label ?? '—';
      final trip = await ref.read(tripProvider(widget.tripId).future);
      final userId = ref.read(authStateProvider).value ?? '';
      final user = await ref.read(currentUserProvider.future);
      final service = TripNotificationService(SupabaseClientWrapper.client);
      await service.notifyPollClosed(
        tripId: widget.tripId,
        tripName: trip.trip.name,
        pollId: widget.pollId,
        question: poll.question,
        winnerLabel: winnerLabel,
        closerId: userId,
        closerName: user?.fullName ?? 'Organizer',
      );
    } catch (_) {
      // best-effort
    }
  }
}
