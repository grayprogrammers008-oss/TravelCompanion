import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/popular_destination.dart';

/// Section widget to display popular destinations by country
class PopularDestinationsSection extends StatefulWidget {
  final Function(PopularDestination) onDestinationTapped;
  final Function(PopularDestination)? onExploreNearby;

  const PopularDestinationsSection({
    super.key,
    required this.onDestinationTapped,
    this.onExploreNearby,
  });

  @override
  State<PopularDestinationsSection> createState() => _PopularDestinationsSectionState();
}

class _PopularDestinationsSectionState extends State<PopularDestinationsSection> {
  String? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    final countries = PopularDestinations.getCountries();
    final destinationsByCountry = PopularDestinations.groupByCountry();

    // Get destinations to show
    final List<PopularDestination> destinationsToShow;
    if (_selectedCountry != null) {
      destinationsToShow = destinationsByCountry[_selectedCountry] ?? [];
    } else {
      // Show all destinations shuffled for variety
      destinationsToShow = List.from(PopularDestinations.all)..shuffle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Popular Destinations',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // See all button
              TextButton(
                onPressed: () {
                  _showAllDestinations(context);
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),

        // Country filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // All countries chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: _selectedCountry == null,
                  onSelected: (_) {
                    setState(() => _selectedCountry = null);
                  },
                  avatar: const Text('🌍', style: TextStyle(fontSize: 14)),
                  label: const Text('All'),
                  selectedColor: context.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: context.primaryColor,
                ),
              ),
              // Country chips
              ...countries.map((country) {
                final info = CountryInfo.getInfo(country);
                final isSelected = _selectedCountry == country;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCountry = isSelected ? null : country);
                    },
                    avatar: Text(info.flag, style: const TextStyle(fontSize: 14)),
                    label: Text(country),
                    selectedColor: info.color.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? info.color : context.textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: info.color,
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal list of destination cards
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: destinationsToShow.length,
            itemBuilder: (context, index) {
              final destination = destinationsToShow[index];
              return _DestinationCard(
                destination: destination,
                onTap: () => widget.onDestinationTapped(destination),
                onExploreNearby: widget.onExploreNearby != null
                    ? () => widget.onExploreNearby!(destination)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllDestinations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllDestinationsSheet(
        onDestinationTapped: widget.onDestinationTapped,
        onExploreNearby: widget.onExploreNearby,
      ),
    );
  }
}

/// Card widget for a single destination
class _DestinationCard extends StatelessWidget {
  final PopularDestination destination;
  final VoidCallback onTap;
  final VoidCallback? onExploreNearby;

  const _DestinationCard({
    required this.destination,
    required this.onTap,
    this.onExploreNearby,
  });

  @override
  Widget build(BuildContext context) {
    final countryInfo = CountryInfo.getInfo(destination.country);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: destination.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: countryInfo.color.withValues(alpha: 0.2),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: countryInfo.color,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: countryInfo.color.withValues(alpha: 0.2),
                child: Icon(
                  countryInfo.icon,
                  size: 48,
                  color: countryInfo.color,
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Country badge with flag
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: countryInfo.color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(countryInfo.flag, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      destination.country.length > 8
                          ? destination.country.substring(0, 8)
                          : destination.country,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destination.bestTimeToVisit,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Explore nearby button
            if (onExploreNearby != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onExploreNearby,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.explore,
                      size: 16,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing all destinations grouped by country
class _AllDestinationsSheet extends StatelessWidget {
  final Function(PopularDestination) onDestinationTapped;
  final Function(PopularDestination)? onExploreNearby;

  const _AllDestinationsSheet({
    required this.onDestinationTapped,
    this.onExploreNearby,
  });

  @override
  Widget build(BuildContext context) {
    final destinationsByCountry = PopularDestinations.groupByCountry();
    final countries = destinationsByCountry.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.public, color: context.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Destinations Worldwide',
                        style: context.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${PopularDestinations.all.length} places',
                        style: context.bodySmall.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List grouped by country
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final destinations = destinationsByCountry[country]!;
                    final info = CountryInfo.getInfo(country);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country header with flag
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: info.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(info.flag, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  country,
                                  style: context.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: info.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: info.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${destinations.length}',
                                  style: context.bodySmall.copyWith(
                                    color: info.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Destinations in this country
                        ...destinations.map((dest) => _DestinationListTile(
                          destination: dest,
                          onTap: () {
                            Navigator.pop(context);
                            onDestinationTapped(dest);
                          },
                          onExploreNearby: onExploreNearby != null
                              ? () {
                                  Navigator.pop(context);
                                  onExploreNearby!(dest);
                                }
                              : null,
                        )),
                        const SizedBox(height: 16),
                      ],
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
}

/// List tile for a destination in the all destinations sheet
class _DestinationListTile extends StatelessWidget {
  final PopularDestination destination;
  final VoidCallback onTap;
  final VoidCallback? onExploreNearby;

  const _DestinationListTile({
    required this.destination,
    required this.onTap,
    this.onExploreNearby,
  });

  @override
  Widget build(BuildContext context) {
    final countryInfo = CountryInfo.getInfo(destination.country);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: destination.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: countryInfo.color.withValues(alpha: 0.1),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: countryInfo.color.withValues(alpha: 0.1),
                    child: Icon(countryInfo.icon, color: countryInfo.color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            destination.name,
                            style: context.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            destination.region,
                            style: context.bodySmall.copyWith(
                              color: context.textColor.withValues(alpha: 0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.description,
                      style: context.bodySmall.copyWith(
                        color: context.textColor.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Explore button
              if (onExploreNearby != null)
                IconButton(
                  onPressed: onExploreNearby,
                  icon: Icon(
                    Icons.explore,
                    color: context.primaryColor,
                  ),
                  tooltip: 'Explore nearby',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
