import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/checklist_providers.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/edit_item_dialog.dart';

class ChecklistDetailPage extends ConsumerWidget {
  final String tripId;
  final String checklistId;

  const ChecklistDetailPage({
    super.key,
    required this.tripId,
    required this.checklistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = context.appThemeData;
    // Use future provider with ref.invalidate for immediate updates
    final checklistAsync = ref.watch(checklistWithItemsProvider(checklistId));

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: checklistAsync.when(
        data: (checklistWithItems) {
          final checklist = checklistWithItems.checklist;
          final items = checklistWithItems.items;
          final progress = checklistWithItems.progress;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Text(
                    checklist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: themeData.primaryGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingLg,
                          AppTheme.spacingLg,
                          AppTheme.spacingLg,
                          60, // Space for title
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Progress indicator
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${checklistWithItems.completedCount} / ${items.length} items',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingXs),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 6,
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
                ),
              ),

              // Items list
              if (items.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context, themeData),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                          child: ChecklistItemTile(
                            item: item,
                            onToggle: () async {
                              final authDataSource = ref.read(authLocalDataSourceProvider);
                              final userId = authDataSource.currentUserId;
                              if (userId == null) return;

                              final controller = ref.read(checklistControllerProvider.notifier);
                              final success = await controller.toggleItemCompletion(
                                itemId: item.id,
                                isCompleted: !item.isCompleted,
                                userId: userId,
                              );
                              // Trigger immediate UI update if successful
                              if (success) {
                                ref.invalidate(checklistWithItemsProvider(checklistId));
                              }
                            },
                            onEdit: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => EditItemDialog(item: item),
                              );
                              if (result == true) {
                                // Refresh checklist after edit
                                ref.invalidate(checklistWithItemsProvider(checklistId));
                              }
                            },
                            onDelete: () async {
                              // Confirmation dialog is already handled by Dismissible widget
                              try {
                                final controller = ref.read(checklistControllerProvider.notifier);
                                final success = await controller.deleteItem(item.id);
                                if (success) {
                                  // Force immediate refresh
                                  ref.invalidate(checklistWithItemsProvider(checklistId));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Item deleted'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                } else {
                                  // Show error if delete failed
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to delete item. Please try again.'),
                                        backgroundColor: AppTheme.error,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                // Catch any exceptions and show error
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting item: ${e.toString()}'),
                                      backgroundColor: AppTheme.error,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  gradient: context.appThemeData.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: context.appThemeData.primaryShadow,
                ),
                child: const Icon(
                  Icons.checklist,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Loading checklist...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.neutral600,
                    ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
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
                  'Error loading checklist',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutral600,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: themeData.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeData.primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: themeData.primaryColor.withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddItemBottomSheet(checklistId: checklistId),
              );
              if (result == true) {
                // Force immediate refresh when item added
                ref.invalidate(checklistWithItemsProvider(checklistId));
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic themeData) {
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
              child: Icon(
                Icons.checklist_outlined,
                size: 64,
                color: themeData.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'No Items Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Tap the + button below to add your first item',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.neutral600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
