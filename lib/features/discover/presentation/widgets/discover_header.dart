import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/discover_place.dart';
import '../providers/discover_providers.dart';

/// Simplified header for Discover page with location pill and search
class DiscoverHeader extends ConsumerWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onLocationTap;

  const DiscoverHeader({
    super.key,
    required this.onSearchTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverState = ref.watch(discoverStateProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Main row: Location pill + Search + Distance
          Row(
            children: [
              // Location Pill (tap to change)
              Expanded(
                child: _LocationPill(
                  locationName: discoverState.locationName,
                  isGettingLocation: discoverState.isGettingLocation,
                  selectedCountry: discoverState.selectedCountry,
                  onTap: onLocationTap,
                ),
              ),
              const SizedBox(width: 8),
              // Search button
              _SearchButton(onTap: onSearchTap),
              const SizedBox(width: 8),
              // Distance indicator (only for current location)
              if (discoverState.selectedCountry == null)
                _DistanceIndicator(
                  distance: discoverState.selectedDistance,
                  onDistanceChanged: (distance) {
                    HapticFeedback.selectionClick();
                    ref.read(discoverStateProvider.notifier).changeDistance(distance);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Location pill showing current location with tap-to-change
class _LocationPill extends StatelessWidget {
  final String? locationName;
  final bool isGettingLocation;
  final String? selectedCountry;
  final VoidCallback onTap;

  const _LocationPill({
    required this.locationName,
    required this.isGettingLocation,
    required this.selectedCountry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentLocation = selectedCountry == null;
    final displayText = isGettingLocation
        ? 'Getting location...'
        : (locationName ?? 'Current Location');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location icon with pulse animation when getting location
              _LocationIcon(
                isGettingLocation: isGettingLocation,
                isCurrentLocation: isCurrentLocation,
              ),
              const SizedBox(width: 8),
              // Location text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCurrentLocation ? 'Near You' : 'Exploring',
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      displayText,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Change location indicator
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: context.textColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Location icon with animation
class _LocationIcon extends StatefulWidget {
  final bool isGettingLocation;
  final bool isCurrentLocation;

  const _LocationIcon({
    required this.isGettingLocation,
    required this.isCurrentLocation,
  });

  @override
  State<_LocationIcon> createState() => _LocationIconState();
}

class _LocationIconState extends State<_LocationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isGettingLocation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_LocationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGettingLocation && !oldWidget.isGettingLocation) {
      _controller.repeat(reverse: true);
    } else if (!widget.isGettingLocation && oldWidget.isGettingLocation) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isGettingLocation
        ? Icons.location_searching
        : (widget.isCurrentLocation ? Icons.my_location : Icons.public);

    final iconWidget = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: context.primaryColor,
      ),
    );

    if (widget.isGettingLocation) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}

/// Search button
class _SearchButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.search,
            size: 22,
            color: context.primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Visual distance indicator with mini radius visualization
class _DistanceIndicator extends StatelessWidget {
  final DiscoverDistance distance;
  final ValueChanged<DiscoverDistance> onDistanceChanged;

  const _DistanceIndicator({
    required this.distance,
    required this.onDistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDistancePicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini radius visualization
              _MiniRadiusIndicator(distance: distance),
              const SizedBox(width: 6),
              // Distance text
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${distance.kilometers}',
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    'km',
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.5),
                      fontSize: 9,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDistancePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DistancePickerSheet(
        currentDistance: distance,
        onDistanceSelected: (selected) {
          onDistanceChanged(selected);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Mini radius visualization
class _MiniRadiusIndicator extends StatelessWidget {
  final DiscoverDistance distance;

  const _MiniRadiusIndicator({required this.distance});

  @override
  Widget build(BuildContext context) {
    // Calculate relative size based on distance
    final maxRadius = 14.0;
    final minRadius = 6.0;
    final radiusRange = maxRadius - minRadius;

    // Map distance to radius (5km = min, 100km = max)
    final distanceRatio = (distance.kilometers - 5) / (100 - 5);
    final radius = minRadius + (radiusRange * distanceRatio.clamp(0.0, 1.0));

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle (max range)
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          // Current radius circle
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryColor.withValues(alpha: 0.2),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          // Center dot (user location)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distance picker bottom sheet with visual radius
class _DistancePickerSheet extends StatelessWidget {
  final DiscoverDistance currentDistance;
  final ValueChanged<DiscoverDistance> onDistanceSelected;

  const _DistancePickerSheet({
    required this.currentDistance,
    required this.onDistanceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.radar,
                    color: context.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search Radius',
                    style: context.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'How far do you want to explore?',
                style: context.bodyMedium.copyWith(
                  color: context.textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Distance options with visual indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: DiscoverDistance.values.map((distance) {
                  final isSelected = distance == currentDistance;
                  return _DistanceOption(
                    distance: distance,
                    isSelected: isSelected,
                    onTap: () => onDistanceSelected(distance),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Individual distance option in picker
class _DistanceOption extends StatelessWidget {
  final DiscoverDistance distance;
  final bool isSelected;
  final VoidCallback onTap;

  const _DistanceOption({
    required this.distance,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.15)
                : context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? context.primaryColor
                  : context.textColor.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual radius
              _MiniRadiusIndicator(distance: distance),
              const SizedBox(height: 8),
              // Distance text
              Text(
                '${distance.kilometers} km',
                style: context.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? context.primaryColor
                      : context.textColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              // Description
              Text(
                _getDistanceLabel(distance),
                style: context.bodySmall.copyWith(
                  fontSize: 9,
                  color: context.textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDistanceLabel(DiscoverDistance distance) {
    switch (distance.kilometers) {
      case 5:
        return 'Nearby';
      case 10:
        return 'Walking';
      case 25:
        return 'Short trip';
      case 50:
        return 'Day trip';
      case 100:
        return 'Road trip';
      default:
        return '';
    }
  }
}

/// Location picker bottom sheet
class LocationPickerSheet extends ConsumerWidget {
  const LocationPickerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverState = ref.watch(discoverStateProvider);
    final countries = DiscoverStateNotifier.getAvailableCountries();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: context.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Location',
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Current location option
              _LocationOption(
                icon: Icons.my_location,
                iconColor: context.primaryColor,
                title: 'Current Location',
                subtitle: discoverState.locationName ?? 'Use GPS',
                isSelected: discoverState.selectedCountry == null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(discoverStateProvider.notifier).clearCountry();
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              // Country list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final info = _getCountryInfo(country);
                    final isSelected = discoverState.selectedCountry == country;

                    return _LocationOption(
                      icon: Icons.public,
                      iconColor: info.color,
                      emoji: info.flag,
                      title: country,
                      subtitle: 'Explore $country',
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(discoverStateProvider.notifier).setCountry(country);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _CountryDisplayInfo _getCountryInfo(String country) {
    const countryData = <String, _CountryDisplayInfo>{
      'Australia': _CountryDisplayInfo('🇦🇺', Color(0xFF00BCD4)),
      'Brazil': _CountryDisplayInfo('🇧🇷', Color(0xFF4CAF50)),
      'Cambodia': _CountryDisplayInfo('🇰🇭', Color(0xFFE91E63)),
      'Canada': _CountryDisplayInfo('🇨🇦', Color(0xFFF44336)),
      'Egypt': _CountryDisplayInfo('🇪🇬', Color(0xFFFF9800)),
      'France': _CountryDisplayInfo('🇫🇷', Color(0xFF2196F3)),
      'Germany': _CountryDisplayInfo('🇩🇪', Color(0xFF212121)),
      'Greece': _CountryDisplayInfo('🇬🇷', Color(0xFF2196F3)),
      'India': _CountryDisplayInfo('🇮🇳', Color(0xFFFF9933)),
      'Indonesia': _CountryDisplayInfo('🇮🇩', Color(0xFFF44336)),
      'Italy': _CountryDisplayInfo('🇮🇹', Color(0xFF4CAF50)),
      'Japan': _CountryDisplayInfo('🇯🇵', Color(0xFFE91E63)),
      'Malaysia': _CountryDisplayInfo('🇲🇾', Color(0xFFFFEB3B)),
      'Maldives': _CountryDisplayInfo('🇲🇻', Color(0xFF00BCD4)),
      'Mexico': _CountryDisplayInfo('🇲🇽', Color(0xFF4CAF50)),
      'Myanmar': _CountryDisplayInfo('🇲🇲', Color(0xFFFFEB3B)),
      'Nepal': _CountryDisplayInfo('🇳🇵', Color(0xFFF44336)),
      'New Zealand': _CountryDisplayInfo('🇳🇿', Color(0xFF212121)),
      'Philippines': _CountryDisplayInfo('🇵🇭', Color(0xFF2196F3)),
      'Singapore': _CountryDisplayInfo('🇸🇬', Color(0xFFF44336)),
      'South Africa': _CountryDisplayInfo('🇿🇦', Color(0xFF4CAF50)),
      'Spain': _CountryDisplayInfo('🇪🇸', Color(0xFFF44336)),
      'Sri Lanka': _CountryDisplayInfo('🇱🇰', Color(0xFFFF9800)),
      'Switzerland': _CountryDisplayInfo('🇨🇭', Color(0xFFF44336)),
      'Thailand': _CountryDisplayInfo('🇹🇭', Color(0xFF2196F3)),
      'Turkey': _CountryDisplayInfo('🇹🇷', Color(0xFFF44336)),
      'UAE': _CountryDisplayInfo('🇦🇪', Color(0xFF4CAF50)),
      'UK': _CountryDisplayInfo('🇬🇧', Color(0xFF3F51B5)),
      'USA': _CountryDisplayInfo('🇺🇸', Color(0xFF2196F3)),
      'Vietnam': _CountryDisplayInfo('🇻🇳', Color(0xFFF44336)),
    };
    return countryData[country] ?? const _CountryDisplayInfo('🌍', Color(0xFF607D8B));
  }
}

/// Location option item
class _LocationOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationOption({
    required this.icon,
    required this.iconColor,
    this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Icon or emoji
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 24))
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.bodyLarge.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? context.primaryColor : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Selected indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: context.primaryColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for country display info
class _CountryDisplayInfo {
  final String flag;
  final Color color;

  const _CountryDisplayInfo(this.flag, this.color);
}
