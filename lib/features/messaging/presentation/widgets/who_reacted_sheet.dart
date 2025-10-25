import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/message_entity.dart';

/// Who Reacted Bottom Sheet
/// Shows list of users who reacted to a message, grouped by emoji
class WhoReactedSheet extends StatefulWidget {
  final List<MessageReaction> reactions;
  final Map<String, String> userNames; // userId -> userName mapping

  const WhoReactedSheet({
    super.key,
    required this.reactions,
    required this.userNames,
  });

  /// Show who reacted bottom sheet
  static void show(
    BuildContext context, {
    required List<MessageReaction> reactions,
    required Map<String, String> userNames,
    String? selectedEmoji,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WhoReactedSheet(
        reactions: reactions,
        userNames: userNames,
      ),
    );
  }

  @override
  State<WhoReactedSheet> createState() => _WhoReactedSheetState();
}

class _WhoReactedSheetState extends State<WhoReactedSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _uniqueEmojis;
  late Map<String, List<MessageReaction>> _reactionsByEmoji;

  @override
  void initState() {
    super.initState();
    _groupReactionsByEmoji();
    _tabController = TabController(
      length: _uniqueEmojis.length + 1, // +1 for "All" tab
      vsync: this,
    );
  }

  void _groupReactionsByEmoji() {
    _reactionsByEmoji = {};
    for (final reaction in widget.reactions) {
      if (!_reactionsByEmoji.containsKey(reaction.emoji)) {
        _reactionsByEmoji[reaction.emoji] = [];
      }
      _reactionsByEmoji[reaction.emoji]!.add(reaction);
    }
    _uniqueEmojis = _reactionsByEmoji.keys.toList()
      ..sort((a, b) {
        // Sort by count (descending)
        return _reactionsByEmoji[b]!.length
            .compareTo(_reactionsByEmoji[a]!.length);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalReactions = widget.reactions.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingMd),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Row(
              children: [
                const Text(
                  'Reactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutral900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.neutral600,
                ),
              ],
            ),
          ),

          // Tab bar with emoji filters
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: context.primaryColor,
            unselectedLabelColor: AppTheme.neutral500,
            indicatorColor: context.primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
            ),
            tabs: [
              // "All" tab
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: _tabController.index == 0
                        ? Theme.of(context).colorScheme.primaryContainer
                        : AppTheme.neutral100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('All'),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        '$totalReactions',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Emoji tabs
              ..._uniqueEmojis.map((emoji) {
                final count = _reactionsByEmoji[emoji]!.length;
                final index = _uniqueEmojis.indexOf(emoji) + 1;
                return Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: _tabController.index == index
                          ? Theme.of(context).colorScheme.primaryContainer
                          : AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          const Divider(height: 1),

          // Reactions list
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All reactions
                _buildReactionsList(widget.reactions),
                // Reactions by emoji
                ..._uniqueEmojis.map((emoji) {
                  return _buildReactionsList(_reactionsByEmoji[emoji]!);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsList(List<MessageReaction> reactions) {
    // Sort by date (newest first)
    final sortedReactions = List<MessageReaction>.from(reactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      itemCount: sortedReactions.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: AppTheme.spacingLg,
        endIndent: AppTheme.spacingLg,
      ),
      itemBuilder: (context, index) {
        final reaction = sortedReactions[index];
        final userName =
            widget.userNames[reaction.userId] ?? 'Unknown User';
        final timeAgo = _getTimeAgo(reaction.createdAt);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.neutral900,
            ),
          ),
          subtitle: Text(
            timeAgo,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.neutral600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Text(
              reaction.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
