import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/voice_input_bottom_sheet.dart';
import '../../../ai_itinerary/data/services/gemini_service.dart';
import '../../../ai_itinerary/presentation/providers/ai_itinerary_providers.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/checklist_providers.dart';
import '../widgets/checklist_item_tile.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/edit_item_dialog.dart';

class ChecklistDetailPage extends ConsumerStatefulWidget {
  final String tripId;
  final String checklistId;

  const ChecklistDetailPage({
    super.key,
    required this.tripId,
    required this.checklistId,
  });

  @override
  ConsumerState<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends ConsumerState<ChecklistDetailPage> {
  bool _isFabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    // Use future provider with ref.invalidate for immediate updates
    final checklistAsync = ref.watch(checklistWithItemsProvider(widget.checklistId));

    return Scaffold(
      backgroundColor: context.backgroundColor,
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
                              // Get current user ID from Supabase (online-only mode)
                              final userId = SupabaseClientWrapper.currentUserId;
                              if (userId == null) return;

                              final controller = ref.read(checklistControllerProvider.notifier);
                              final success = await controller.toggleItemCompletion(
                                itemId: item.id,
                                isCompleted: !item.isCompleted,
                                userId: userId,
                              );
                              // Trigger immediate UI update if successful
                              if (success) {
                                ref.invalidate(checklistWithItemsProvider(widget.checklistId));
                              }
                            },
                            onEdit: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => EditItemDialog(item: item),
                              );
                              if (result == true) {
                                // Refresh checklist after edit
                                ref.invalidate(checklistWithItemsProvider(widget.checklistId));
                              }
                            },
                            onDelete: () async {
                              // Confirmation dialog is already handled by Dismissible widget
                              try {
                                final controller = ref.read(checklistControllerProvider.notifier);
                                final success = await controller.deleteItem(item.id);
                                if (success) {
                                  // Force immediate refresh
                                  ref.invalidate(checklistWithItemsProvider(widget.checklistId));
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
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading checklist...'),
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
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildExpandableFab(context, themeData),
    );
  }

  Widget _buildExpandableFab(BuildContext context, dynamic themeData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Voice input option
        if (_isFabExpanded) ...[
          _buildFabOption(
            context: context,
            themeData: themeData,
            icon: Icons.mic,
            label: 'Voice Input',
            color: const Color(0xFF00D9FF),
            onTap: () {
              setState(() => _isFabExpanded = false);
              _showVoiceInput(context, themeData);
            },
          ),
          const SizedBox(height: 12),
          _buildFabOption(
            context: context,
            themeData: themeData,
            icon: Icons.edit,
            label: 'Type Item',
            color: themeData.primaryColor,
            onTap: () {
              setState(() => _isFabExpanded = false);
              _showManualInput(context);
            },
          ),
          const SizedBox(height: 16),
        ],
        // Main FAB
        Container(
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
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _isFabExpanded = !_isFabExpanded);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: AnimatedRotation(
                  turns: _isFabExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption({
    required BuildContext context,
    required dynamic themeData,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showVoiceInput(BuildContext context, dynamic themeData) async {
    final voiceText = await VoiceInputBottomSheet.show(
      context: context,
      title: 'AI Packing Assistant',
      hintText: 'Describe what you need to pack',
      exampleText: 'I need items for a beach vacation with snorkeling',
      icon: Icons.auto_awesome,
      primaryColor: const Color(0xFF00D9FF),
      demoPhrase: 'I need essentials for a beach vacation, including snorkeling gear and sun protection',
    );

    if (voiceText != null && voiceText.isNotEmpty && mounted) {
      // Show loading indicator
      _showLoadingDialog(context, 'AI is generating your packing list...');

      try {
        // Get trip info for context
        final tripAsync = ref.read(tripProvider(widget.tripId));
        final destination = tripAsync.value?.trip.destination ?? 'Unknown';
        final tripName = tripAsync.value?.trip.name ?? 'Trip';
        final durationDays = tripAsync.value?.trip.startDate != null &&
                            tripAsync.value?.trip.endDate != null
            ? tripAsync.value!.trip.endDate!.difference(tripAsync.value!.trip.startDate!).inDays + 1
            : null;

        // Get Gemini service
        final geminiService = ref.read(geminiServiceProvider);

        // Generate checklist items using AI
        final aiItems = await geminiService.generateChecklistItems(
          voicePrompt: voiceText,
          destination: destination,
          tripType: tripName,
          durationDays: durationDays,
        );

        // Dismiss loading dialog
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (aiItems.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI could not generate items. Please try again.'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
          return;
        }

        // Show preview dialog before adding
        if (mounted) {
          final confirmed = await _showAiItemsPreview(context, aiItems, themeData);
          if (confirmed == true) {
            await _addAiItemsToChecklist(aiItems);
          }
        }
      } catch (e) {
        // Dismiss loading dialog
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showAiItemsPreview(
    BuildContext context,
    List<AiChecklistItem> items,
    dynamic themeData,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF00D9FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('AI Generated Items'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  item.isEssential ? Icons.star : Icons.check_circle_outline,
                  color: item.isEssential ? Colors.amber : Colors.grey,
                  size: 20,
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: item.category != null
                    ? Text(
                        item.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
                trailing: item.quantity > 1
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: themeData.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeData.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add ${items.length} Items'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeData.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAiItemsToChecklist(List<AiChecklistItem> aiItems) async {
    final controller = ref.read(checklistControllerProvider.notifier);
    int addedCount = 0;

    for (final aiItem in aiItems) {
      // Create title with quantity if > 1
      final title = aiItem.quantity > 1
          ? '${aiItem.title} (x${aiItem.quantity})'
          : aiItem.title;

      final item = await controller.addItem(
        checklistId: widget.checklistId,
        title: title,
      );
      if (item != null) {
        addedCount++;
      }
    }

    if (mounted) {
      ref.invalidate(checklistWithItemsProvider(widget.checklistId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 8),
              Text('AI added $addedCount item${addedCount == 1 ? '' : 's'}'),
            ],
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _showManualInput(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemBottomSheet(checklistId: widget.checklistId),
    );
    if (result == true) {
      ref.invalidate(checklistWithItemsProvider(widget.checklistId));
    }
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
              style: context.headlineMedium.copyWith(
                    color: context.textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Tap the + button below to add your first item',
              textAlign: TextAlign.center,
              style: context.bodyLarge.copyWith(
                    color: context.textColor.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
