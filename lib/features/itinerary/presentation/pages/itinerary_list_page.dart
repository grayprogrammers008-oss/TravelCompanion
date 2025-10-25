import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../../../shared/models/itinerary_model.dart';
import '../providers/itinerary_providers.dart';

class ItineraryListPage extends ConsumerWidget {
  final String tripId;

  const ItineraryListPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = context.appThemeData;
    final itineraryAsync = ref.watch(itineraryByDaysProvider(tripId));

    // Listen for success/error messages
    ref.listen<ItineraryState>(itineraryControllerProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: context.successColor,
          ),
        );
        ref.read(itineraryControllerProvider.notifier).clearSuccessMessage();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: context.errorColor,
          ),
        );
        ref.read(itineraryControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary'),
        elevation: 0,
      ),
      body: itineraryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: context.errorColor),
              const SizedBox(height: 16),
              Text(
                'Error loading itinerary',
                style: context.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: context.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(itineraryByDaysProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (days) {
          if (days.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(itineraryByDaysProvider);
            },
            child: StaggeredListAnimation(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return _buildDaySection(context, ref, day);
              },
            ),
          );
        },
      ),
      floatingActionButton: ScaleAnimation(
        duration: AppAnimations.slow,
        curve: AppAnimations.spring,
        child: AnimatedScaleButton(
          onTap: () => _navigateToAddItem(context),
          child: Container(
            decoration: BoxDecoration(
              gradient: themeData.glossyGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: themeData.glossyShadow,
            ),
            child: FloatingActionButton.extended(
              onPressed: null, // Handled by AnimatedScaleButton
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: Icon(Icons.add, color: context.primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 24),
              label: Text(
                'Add Activity',
                style: TextStyle(
                  color: context.primaryColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 120,
              color: context.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Activities Yet',
              style: context.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start planning your trip by adding activities to your itinerary',
              style: context.bodyLarge.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddItem(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Activity'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(BuildContext context, WidgetRef ref, ItineraryDay day) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: context.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Day ${day.dayNumber}',
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${day.items.length} ${day.items.length == 1 ? 'activity' : 'activities'}',
                  style: context.bodyMedium.copyWith(
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Day Items
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: day.items.length,
            onReorder: (oldIndex, newIndex) {
              _handleReorder(ref, day, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = day.items[index];
              return _buildItineraryItem(context, ref, item, key: ValueKey(item.id));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryItem(
    BuildContext context,
    WidgetRef ref,
    ItineraryItemModel item, {
    Key? key,
  }) {
    return Dismissible(
      key: key ?? ValueKey(item.id),
      background: Container(
        color: context.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Activity'),
            content: const Text('Are you sure you want to delete this activity?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: context.errorColor),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ref.read(itineraryControllerProvider.notifier).deleteItem(item.id);
      },
      child: InkWell(
        onTap: () => _navigateToEditItem(context, item.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time indicator
              if (item.startTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat.Hm().format(item.startTime!),
                    style: context.bodySmall.copyWith(
                      color: context.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(width: 52),

              const SizedBox(width: 12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: context.textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location!,
                              style: context.bodyMedium.copyWith(
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: context.bodyMedium.copyWith(
                          color: context.textColor.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.endTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Until ${DateFormat.Hm().format(item.endTime!)}',
                        style: context.bodySmall.copyWith(
                          color: context.textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Reorder handle
              Icon(
                Icons.drag_handle,
                color: context.textColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReorder(WidgetRef ref, ItineraryDay day, int oldIndex, int newIndex) {
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create new order
    final items = List<ItineraryItemModel>.from(day.items);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Extract item IDs in new order
    final itemIds = items.map((item) => item.id).toList();

    // Call reorder use case
    ref.read(itineraryControllerProvider.notifier).reorderItems(
          tripId: tripId,
          dayNumber: day.dayNumber,
          itemIds: itemIds,
        );
  }

  void _navigateToAddItem(BuildContext context) {
    context.push('/trips/$tripId/itinerary/add');
  }

  void _navigateToEditItem(BuildContext context, String itemId) {
    context.push('/trips/$tripId/itinerary/$itemId/edit');
  }
}
