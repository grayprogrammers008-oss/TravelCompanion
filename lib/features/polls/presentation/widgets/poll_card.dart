import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/poll_entity.dart';

class PollCard extends StatelessWidget {
  const PollCard({
    super.key,
    required this.poll,
    required this.onTap,
  });

  final PollEntity poll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOpen = poll.isOpenForVoting;
    final theme = Theme.of(context);
    final accent = isOpen ? theme.colorScheme.primary : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    poll.timeRemainingLabel,
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (poll.currentUserVoted)
                  const Icon(Icons.check_circle, size: 18, color: AppTheme.success),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              poll.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                Icon(Icons.how_to_vote, size: 14, color: context.textColor.withValues(alpha: 0.55)),
                const SizedBox(width: 4),
                Text(
                  '${poll.voteCount} of ${poll.optionCount > 0 ? poll.optionCount : "—"} option${poll.optionCount == 1 ? "" : "s"}',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (poll.defaultOptionLabel != null)
                  Flexible(
                    child: Text(
                      'Default: ${poll.defaultOptionLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
