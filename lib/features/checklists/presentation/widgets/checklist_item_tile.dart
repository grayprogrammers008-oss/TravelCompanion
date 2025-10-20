import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/checklist_entity.dart';

class ChecklistItemTile extends StatelessWidget {
  final ChecklistItemEntity item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Remove "${item.title}" from this checklist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete(),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(
            color: item.isCompleted ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.neutral200,
            width: item.isCompleted ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onToggle,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (_) => onToggle(),
                  activeColor: AppTheme.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                              color: item.isCompleted ? AppTheme.neutral500 : AppTheme.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (item.assignedToName != null || item.completedByName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.assignedToName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 12,
                                      color: AppTheme.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.assignedToName!,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.info,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            if (item.completedByName != null) ...[
                              const SizedBox(width: AppTheme.spacingXs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingXs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 12,
                                      color: AppTheme.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'by ${item.completedByName}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.success,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Status icon
                if (item.isCompleted)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppTheme.success,
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
