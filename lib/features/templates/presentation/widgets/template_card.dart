// Template Card Widget
//
// A card widget for displaying trip template information.

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/destination_image.dart';
import '../../domain/entities/trip_template.dart';

/// Get appropriate currency icon based on currency code
IconData _getCurrencyIcon(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return Icons.attach_money;
    case 'EUR':
      return Icons.euro;
    case 'GBP':
      return Icons.currency_pound;
    case 'JPY':
    case 'CNY':
      return Icons.currency_yen;
    case 'INR':
    default:
      return Icons.currency_rupee;
  }
}

class TemplateCard extends StatelessWidget {
  final TripTemplate template;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image with Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLg),
                      topRight: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: DestinationImage(
                      tripName: template.destination,
                      tripId: template.id,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      showOverlay: true,
                      overlayChild: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category & Featured Badge Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: AppTheme.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: template.category.color.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        template.category.icon,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        template.category.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (template.isFeatured) ...[
                                  const SizedBox(width: AppTheme.spacingXs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSm,
                                      vertical: AppTheme.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Featured',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Duration Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${template.durationDays} ${template.durationDays == 1 ? 'Day' : 'Days'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                ],
              ),

              // Template Details
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Name
                    Text(
                      template.name,
                      style: context.titleStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppTheme.spacingXs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: context.textColor.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            template.destinationState != null
                                ? '${template.destination}, ${template.destinationState}'
                                : template.destination,
                            style: context.bodyStyle.copyWith(
                              color: context.textColor.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (template.description != null && template.description!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        template.description!,
                        style: context.bodyStyle.copyWith(
                          color: context.textColor.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingMd),

                    // Info Row
                    Row(
                      children: [
                        // Budget Range
                        if (template.budgetMin != null || template.budgetMax != null)
                          _buildInfoChip(
                            context,
                            icon: _getCurrencyIcon(template.currency),
                            label: template.budgetDisplay,
                          ),

                        if (template.budgetMin != null || template.budgetMax != null)
                          const SizedBox(width: AppTheme.spacingSm),

                        // Difficulty
                        _buildInfoChip(
                          context,
                          icon: template.difficultyLevel.icon,
                          label: template.difficultyLevel.displayName,
                          color: template.difficultyLevel.color,
                        ),

                        const Spacer(),

                        // Use Count and Rating
                        if (template.useCount > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: context.textColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${template.useCount}',
                                style: context.bodyStyle.copyWith(
                                  fontSize: 12,
                                  color: context.textColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),

                        if (template.useCount > 0 && template.rating > 0)
                          const SizedBox(width: AppTheme.spacingSm),

                        if (template.rating > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                template.rating.toStringAsFixed(1),
                                style: context.bodyStyle.copyWith(
                                  fontSize: 12,
                                  color: context.textColor.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Best Season Tags
                    if (template.bestSeason.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Wrap(
                        spacing: AppTheme.spacingXs,
                        runSpacing: AppTheme.spacingXs,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 14,
                            color: context.textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Best: ${template.bestSeason.take(3).join(', ')}${template.bestSeason.length > 3 ? '...' : ''}',
                            style: context.bodyStyle.copyWith(
                              fontSize: 12,
                              color: context.textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.neutral400).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? context.textColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.bodyStyle.copyWith(
              fontSize: 12,
              color: color ?? context.textColor.withValues(alpha: 0.7),
              fontWeight: color != null ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
