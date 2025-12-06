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
  bool _isSearching = false;

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
              // App Bar
              SliverAppBar(
                expandedHeight: _isSearching ? 210 : 180,
                floating: false,
                pinned: true,
                backgroundColor: themeData.primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: themeData.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacing3xl,
                          AppTheme.spacingSm,
                          AppTheme.spacingLg,
                          AppTheme.spacingSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Trip Templates',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        'Pre-built itineraries for popular destinations',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_isSearching) ...[
                              const SizedBox(height: AppTheme.spacingMd),
                              SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search destinations...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    ),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingMd,
                                      vertical: AppTheme.spacingSm,
                                    ),
                                  ),
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppTheme.spacingMd),
                            // Category Filters
                            SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
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
                          ],
                        ),
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
