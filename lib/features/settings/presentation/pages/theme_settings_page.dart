import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_data.dart';
import '../../../../core/theme/theme_provider.dart' as theme_provider;
import '../../../../core/animations/animated_widgets.dart';
import '../../../../core/animations/animation_constants.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(theme_provider.themeProvider);
    final themeData = ref.watch(theme_provider.currentThemeDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeSlideAnimation(
                delay: Duration.zero,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: themeData.primaryShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingSm),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Icon(
                              Icons.palette,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose Your Style',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppTheme.spacing2xs),
                                Text(
                                  'Select a theme that matches your vibe',
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Theme Grid - 2 columns
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppTheme.spacingMd,
                  mainAxisSpacing: AppTheme.spacingMd,
                  childAspectRatio: 0.75, // Adjusted to give more height
                ),
                itemCount: AppThemeType.values.length,
                itemBuilder: (context, index) {
                  final themeType = AppThemeType.values[index];
                  final themeData = AppThemeData.getThemeData(themeType);
                  final isSelected = currentTheme == themeType;

                  return FadeSlideAnimation(
                    delay: AppAnimations.staggerSmall * (index + 1),
                    child: _ThemeTile(
                      themeData: themeData,
                      themeType: themeType,
                      isSelected: isSelected,
                      onTap: () async {
                        // Apply theme
                        await ref.read(theme_provider.themeProvider.notifier).setTheme(themeType);

                        // Show feedback
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${themeData.name} theme applied!'),
                              backgroundColor: themeData.primaryColor,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme preview tile for grid layout
class _ThemeTile extends StatelessWidget {
  final AppThemeData themeData;
  final AppThemeType themeType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.themeData,
    required this.themeType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isSelected
                  ? themeData.primaryColor
                  : AppTheme.neutral200,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: isSelected
                ? themeData.primaryShadow
                : [
                    BoxShadow(
                      color: AppTheme.neutral900.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gradient preview with icon
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: themeData.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusMd),
                      topRight: Radius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      themeData.icon,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),

              // Theme info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme name with active badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              themeData.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? themeData.primaryColor
                                        : AppTheme.neutral900,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: themeData.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Description
                      Flexible(
                        child: Text(
                          themeData.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.neutral600,
                                    fontSize: 10,
                                    height: 1.2,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing2xs),

                      // Color swatches
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _ColorSwatch(color: themeData.primaryColor, size: 14),
                          const SizedBox(width: 3),
                          _ColorSwatch(color: themeData.primaryDeep, size: 14),
                          const SizedBox(width: 3),
                          _ColorSwatch(color: themeData.primaryLight, size: 14),
                          const SizedBox(width: 3),
                          _ColorSwatch(color: themeData.accentColor, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color swatch preview
class _ColorSwatch extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorSwatch({required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.neutral200,
          width: 1,
        ),
      ),
    );
  }
}
