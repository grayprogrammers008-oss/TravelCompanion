import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
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
        side: BorderSide(color: context.textColor.withValues(alpha: 0.12), width: 1),
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
                              style: context.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.textColor,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$completedCount of $totalCount items',
                              style: context.bodySmall.copyWith(
                                    color: context.textColor.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Action menu button - only show if there are actions available
                      if (onEdit != null || onDelete != null)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: context.textColor.withValues(alpha: 0.7)),
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
                            if (onEdit != null)
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: context.primaryColor, size: 20),
                                    const SizedBox(width: AppTheme.spacingMd),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
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
                      backgroundColor: context.textColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeData.primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% Complete',
                    style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.7),
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
                        color: context.textColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.checklist,
                        color: context.textColor.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        checklist.name,
                        style: context.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
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
                  style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.7),
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
                        style: context.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
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
                  style: context.bodySmall.copyWith(
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
