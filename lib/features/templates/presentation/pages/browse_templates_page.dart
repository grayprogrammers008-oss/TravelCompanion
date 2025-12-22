// Browse Templates Page
//
// A page for browsing and selecting trip templates.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/gradient_page_backgrounds.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/animations/animation_constants.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../domain/entities/trip_template.dart';
import '../providers/template_providers.dart';
import '../widgets/template_card.dart';
import '../widgets/template_category_chip.dart';

class BrowseTemplatesPage extends ConsumerStatefulWidget {
  const BrowseTemplatesPage({super.key});

  @override
  ConsumerState<BrowseTemplatesPage> createState() => _BrowseTemplatesPageState();
}

class _BrowseTemplatesPageState extends ConsumerState<BrowseTemplatesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _searchController = TextEditingController();
  TemplateCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  TemplateFilters? get _currentFilters {
    if (_selectedCategory == null && _searchController.text.isEmpty) {
      return null;
    }
    return TemplateFilters(
      category: _selectedCategory,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider(_currentFilters));
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: MeshGradientBackground(
        intensity: 0.5,
        child: RefreshIndicator(
          displacement: 120,
          edgeOffset: 120,
          onRefresh: () async {
            ref.invalidate(templatesProvider(_currentFilters));
            await ref.read(templatesProvider(_currentFilters).future);
          },
          child: CustomScrollView(
            slivers: [
              // Personalized header matching Home Page design
              SliverAppBar(
                expandedHeight: 180,
                floating: true,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                ),
                leadingWidth: 60,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Trip Templates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Ready-made travel plans',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                titleSpacing: 4,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: themeData.primaryGradient,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Spacer for the toolbar area
                          const SizedBox(height: kToolbarHeight),
                          // Search bar row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppTheme.spacingMd,
                              AppTheme.spacingSm,
                              AppTheme.spacingMd,
                              AppTheme.spacingMd,
                            ),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.neutral900,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search templates ✨',
                                  hintStyle: TextStyle(
                                    color: AppTheme.neutral400,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMd,
                                    vertical: 12,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: themeData.primaryColor,
                                    size: 22,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: AppTheme.neutral400,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ),
                          // Category Filters
                          SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                              ),
                              children: [
                                TemplateCategoryChip(
                                  label: 'All',
                                  icon: Icons.apps,
                                  isSelected: _selectedCategory == null,
                                  onTap: () => setState(() => _selectedCategory = null),
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                ...TemplateCategory.values.map((category) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                                    child: TemplateCategoryChip(
                                      label: category.displayName,
                                      icon: category.icon,
                                      isSelected: _selectedCategory == category,
                                      onTap: () => setState(() => _selectedCategory = category),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return SliverFillRemaining(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildEmptyState(context),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final template = templates[index];
                          return FadeSlideAnimation(
                            delay: AppAnimations.staggerMedium * index,
                            duration: AppAnimations.medium,
                            child: TemplateCard(
                              key: ValueKey(template.id),
                              template: template,
                              onTap: () => context.push('/templates/${template.id}'),
                            ),
                          );
                        },
                        childCount: templates.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLoadingIndicator(),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'Loading templates...',
                          style: context.bodyStyle.copyWith(
                            color: context.textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(context, error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              decoration: BoxDecoration(
                color: AppTheme.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: AppTheme.neutral400,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Templates Found',
              style: context.titleStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _selectedCategory != null
                  ? 'No templates available for ${_selectedCategory!.displayName}.\nTry another category!'
                  : 'No templates match your search.\nTry different keywords!',
              style: context.bodyStyle.copyWith(
                color: context.textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedCategory != null || _searchController.text.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingXl),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
              'Failed to Load Templates',
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
                ref.invalidate(templatesProvider(_currentFilters));
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
