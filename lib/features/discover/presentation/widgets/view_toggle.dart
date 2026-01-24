import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../../../../core/theme/theme_extensions.dart';

/// View mode for discover page
enum DiscoverViewMode {
  grid,
  map,
}

/// Toggle widget for switching between Grid and Map views
class ViewToggle extends StatelessWidget {
  final DiscoverViewMode currentMode;
  final ValueChanged<DiscoverViewMode> onModeChanged;
  final Color? activeColor;

  const ViewToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? context.primaryColor;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            isSelected: currentMode == DiscoverViewMode.grid,
            color: color,
            onTap: () {
              if (currentMode != DiscoverViewMode.grid) {
                HapticFeedback.selectionClick();
                onModeChanged(DiscoverViewMode.grid);
              }
            },
          ),
          _ToggleOption(
            icon: Icons.map_outlined,
            label: 'Map',
            isSelected: currentMode == DiscoverViewMode.map,
            color: color,
            onTap: () {
              if (currentMode != DiscoverViewMode.map) {
                HapticFeedback.selectionClick();
                onModeChanged(DiscoverViewMode.map);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : context.textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : context.textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact view toggle (icon only)
class CompactViewToggle extends StatelessWidget {
  final DiscoverViewMode currentMode;
  final ValueChanged<DiscoverViewMode> onModeChanged;

  const CompactViewToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactOption(
            icon: Icons.grid_view_rounded,
            isSelected: currentMode == DiscoverViewMode.grid,
            onTap: () {
              if (currentMode != DiscoverViewMode.grid) {
                HapticFeedback.selectionClick();
                onModeChanged(DiscoverViewMode.grid);
              }
            },
          ),
          _CompactOption(
            icon: Icons.map_outlined,
            isSelected: currentMode == DiscoverViewMode.map,
            onTap: () {
              if (currentMode != DiscoverViewMode.map) {
                HapticFeedback.selectionClick();
                onModeChanged(DiscoverViewMode.map);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CompactOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? context.primaryColor
              : context.textColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
