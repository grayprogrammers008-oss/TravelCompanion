// Template Detail Page
//
// Shows full details of a trip template with itinerary and checklists.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../domain/entities/trip_template.dart';
import '../providers/template_providers.dart';

class TemplateDetailPage extends ConsumerStatefulWidget {
  final String templateId;

  const TemplateDetailPage({
    super.key,
    required this.templateId,
  });

  @override
  ConsumerState<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends ConsumerState<TemplateDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templateAsync = ref.watch(templateDetailsProvider(widget.templateId));
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      body: templateAsync.when(
        data: (template) {
          if (template == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, template, themeData);
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLoadingIndicator(),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Loading template...',
                style: context.bodyStyle.copyWith(
                  color: context.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TripTemplate template, dynamic themeData) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: themeData.primaryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  // TODO: Implement share functionality
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(
                    tripName: template.destination,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppTheme.spacingMd,
                    right: AppTheme.spacingMd,
                    bottom: AppTheme.spacingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: AppTheme.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: template.category.color,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                template.category.icon,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                template.category.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        // Template Name
                        Text(
                          template.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        // Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              template.destinationState != null
                                  ? '${template.destination}, ${template.destinationState}'
                                  : template.destination,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildOverviewSection(context, template, themeData),
          ),
          SliverPersistentHeader(
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: themeData.primaryColor,
                unselectedLabelColor: context.textColor.withValues(alpha: 0.5),
                indicatorColor: themeData.primaryColor,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.info_outline, size: 20),
                    text: 'Overview',
                  ),
                  Tab(
                    icon: const Icon(Icons.route, size: 20),
                    text: 'Itinerary (${template.itineraryItems?.length ?? 0})',
                  ),
                  Tab(
                    icon: const Icon(Icons.checklist, size: 20),
                    text: 'Packing (${template.checklists?.length ?? 0})',
                  ),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, template),
          _buildItineraryTab(context, template),
          _buildChecklistsTab(context, template),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, TripTemplate template, dynamic themeData) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      color: Colors.white,
      child: Column(
        children: [
          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Duration',
                  value: '${template.durationDays} Days',
                  color: themeData.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.currency_rupee,
                  label: 'Budget',
                  value: template.budgetDisplay,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: template.difficultyLevel.icon,
                  label: 'Difficulty',
                  value: template.difficultyLevel.displayName,
                  color: template.difficultyLevel.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Use Template Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUseTemplateDialog(context, template),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Use This Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: context.titleStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: context.bodyStyle.copyWith(
              fontSize: 11,
              color: context.textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, TripTemplate template) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (template.description != null && template.description!.isNotEmpty) ...[
            Text(
              'About This Trip',
              style: context.titleStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              template.description!,
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Best Season
          if (template.bestSeason.isNotEmpty) ...[
            Text(
              'Best Time to Visit',
              style: context.titleStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: template.bestSeason.map((month) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        month,
                        style: context.bodyStyle.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Tags
          if (template.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: context.titleStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: template.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppTheme.neutral100,
                  labelStyle: context.bodyStyle.copyWith(fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Stats
          if (template.useCount > 0 || template.rating > 0) ...[
            Text(
              'Stats',
              style: context.titleStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                if (template.useCount > 0)
                  _buildStatRow(
                    context,
                    icon: Icons.people_outline,
                    label: '${template.useCount} travelers used this template',
                  ),
                if (template.rating > 0) ...[
                  const SizedBox(width: AppTheme.spacingLg),
                  _buildStatRow(
                    context,
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    label: '${template.rating.toStringAsFixed(1)} rating (${template.ratingCount} reviews)',
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? context.textColor.withValues(alpha: 0.6)),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          label,
          style: context.bodyStyle.copyWith(
            color: context.textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildItineraryTab(BuildContext context, TripTemplate template) {
    final items = template.itineraryItems ?? [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No itinerary available',
              style: context.titleStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Group by day
    final dayGroups = <int, List<TemplateItineraryItem>>{};
    for (final item in items) {
      dayGroups.putIfAbsent(item.dayNumber, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: dayGroups.length,
      itemBuilder: (context, index) {
        final dayNumber = dayGroups.keys.elementAt(index);
        final dayItems = dayGroups[dayNumber]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Day $dayNumber',
                    style: context.titleStyle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Day Items
            ...dayItems.map((item) => _buildItineraryItemCard(context, item)),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        );
      },
    );
  }

  Widget _buildItineraryItemCard(BuildContext context, TemplateItineraryItem item) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppTheme.spacingLg,
        bottom: AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: item.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  item.category.icon,
                  size: 18,
                  color: item.category.color,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  item.title,
                  style: context.titleStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.startTime != null)
                Text(
                  item.startTime!,
                  style: context.bodyStyle.copyWith(
                    fontSize: 12,
                    color: context.textColor.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              item.description!,
              style: context.bodyStyle.copyWith(
                fontSize: 13,
                color: context.textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (item.location != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: context.textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location!,
                    style: context.bodyStyle.copyWith(
                      fontSize: 12,
                      color: context.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (item.tips != null && item.tips!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.tips!,
                      style: context.bodyStyle.copyWith(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistsTab(BuildContext context, TripTemplate template) {
    final checklists = template.checklists ?? [];

    if (checklists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 64,
              color: AppTheme.neutral300,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No packing lists available',
              style: context.titleStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: checklists.length,
      itemBuilder: (context, index) {
        final checklist = checklists[index];
        return _buildChecklistCard(context, checklist);
      },
    );
  }

  Widget _buildChecklistCard(BuildContext context, TemplateChecklist checklist) {
    final items = checklist.items ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.checklist,
                  size: 18,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  checklist.name,
                  style: context.titleStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutral100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${items.length} items',
                  style: context.bodyStyle.copyWith(
                    fontSize: 12,
                    color: context.textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                0,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
              ),
              child: Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                    child: Row(
                      children: [
                        Icon(
                          item.isEssential
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 18,
                          color: item.isEssential
                              ? context.primaryColor
                              : context.textColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            item.content,
                            style: context.bodyStyle.copyWith(
                              fontWeight: item.isEssential
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (item.isEssential)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                            ),
                            child: Text(
                              'Essential',
                              style: context.bodyStyle.copyWith(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUseTemplateDialog(BuildContext context, TripTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXl),
            topRight: Radius.circular(AppTheme.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: context.primaryColor,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Use This Template',
              style: context.titleStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Create a new trip with this template\'s itinerary and packing lists pre-filled.',
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to create trip with template
                  context.push('/trips/create?templateId=${template.id}');
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create New Trip'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.neutral400,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Template Not Found',
            style: context.titleStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'This template may have been removed.',
            style: context.bodyStyle.copyWith(
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
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Failed to Load Template',
              style: context.titleStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error,
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(templateDetailsProvider(widget.templateId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
