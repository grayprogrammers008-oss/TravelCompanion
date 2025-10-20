import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../domain/entities/checklist_entity.dart';
import '../providers/checklist_providers.dart';

class ChecklistCard extends ConsumerWidget {
  final ChecklistEntity checklist;
  final String tripId;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChecklistCard({
    super.key,
    required this.checklist,
    required this.tripId,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = context.appThemeData;
    final checklistWithItemsAsync = ref.watch(checklistWithItemsProvider(checklist.id));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.neutral200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: checklistWithItemsAsync.when(
            data: (checklistWithItems) {
              final progress = checklistWithItems.progress;
              final completedCount = checklistWithItems.completedCount;
              final totalCount = checklistWithItems.items.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          gradient: themeData.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Icon(
                          Icons.checklist,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checklist.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.neutral900,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$completedCount of $totalCount items',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.neutral600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Action menu button
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.neutral600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!();
                          } else if (value == 'delete' && onDelete != null) {
                            onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppTheme.primaryTeal, size: 20),
                                SizedBox(width: AppTheme.spacingMd),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: AppTheme.error, size: 20),
                                SizedBox(width: AppTheme.spacingMd),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.neutral200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeData.primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutral600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              );
            },
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral200,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.checklist,
                        color: AppTheme.neutral400,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        checklist.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral900,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Loading items...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                ),
              ],
            ),
            error: (error, stack) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        checklist.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.neutral900,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Error loading items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
