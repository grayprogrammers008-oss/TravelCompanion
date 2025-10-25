import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/checklist_providers.dart';
import '../widgets/checklist_card.dart';
import '../widgets/edit_checklist_dialog.dart';
import 'add_checklist_page.dart';

class ChecklistListPage extends ConsumerWidget {
  final String tripId;

  const ChecklistListPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = context.appThemeData;
    final checklistsAsync = ref.watch(tripChecklistsProvider(tripId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Checklists',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: themeData.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: themeData.primaryGradient,
          ),
        ),
      ),
      body: checklistsAsync.when(
        data: (checklists) {
          if (checklists.isEmpty) {
            return _buildEmptyState(context, themeData);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tripChecklistsProvider(tripId));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              itemCount: checklists.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
              itemBuilder: (context, index) {
                final checklist = checklists[index];
                return ChecklistCard(
                  checklist: checklist,
                  tripId: tripId,
                  onTap: () {
                    context.push('/trips/$tripId/checklists/${checklist.id}');
                  },
                  onEdit: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => EditChecklistDialog(checklist: checklist),
                    );
                    if (result == true) {
                      ref.invalidate(tripChecklistsProvider(tripId));
                    }
                  },
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Checklist'),
                        content: Text('Are you sure you want to delete "${checklist.name}"? This will also delete all its items.'),
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

                    if (confirmed == true) {
                      final controller = ref.read(checklistControllerProvider.notifier);
                      final success = await controller.deleteChecklist(checklist.id);
                      if (success && context.mounted) {
                        ref.invalidate(tripChecklistsProvider(tripId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checklist deleted'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } else if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete checklist'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  gradient: themeData.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: themeData.primaryShadow,
                ),
                child: const Icon(
                  Icons.checklist,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Loading checklists...',
                style: context.titleMedium.copyWith(
                      color: context.textColor.withValues(alpha: 0.7),
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
                  'Error loading checklists',
                  style: context.headlineSmall.copyWith(
                        color: context.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: context.bodyMedium.copyWith(
                        color: context.textColor.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(tripChecklistsProvider(tripId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddChecklistPage(tripId: tripId),
            ),
          );

          if (result == true) {
            ref.invalidate(tripChecklistsProvider(tripId));
          }
        },
        backgroundColor: themeData.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Checklist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                size: 80,
                color: themeData.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              'No Checklists Yet',
              style: context.headlineMedium.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Create your first checklist to start organizing\nyour trip tasks and packing items',
              textAlign: TextAlign.center,
              style: context.bodyLarge.copyWith(
                    color: context.textColor.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: AppTheme.spacing2xl),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddChecklistPage(tripId: tripId),
                  ),
                );

                if (result == true && context.mounted) {
                  // Refresh will be handled by the provider
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                  vertical: AppTheme.spacingMd,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Checklist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
