import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/services/google_maps_url_parser.dart';
import '../../../itinerary/presentation/widgets/add_location_to_trip_sheet.dart';
import '../../domain/entities/discover_place.dart';
import '../../domain/entities/place_category.dart';
import '../providers/discover_providers.dart';

/// Bottom sheet to show place details
class PlaceDetailSheet extends ConsumerWidget {
  final DiscoverPlace place;

  const PlaceDetailSheet({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(placeDetailsProvider(place.placeId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Image
                    _buildImage(context, ref),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      place.name,
                      style: context.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category chip
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            place.category.icon,
                            size: 16,
                            color: place.category.color,
                          ),
                          label: Text(place.category.displayName),
                          backgroundColor: place.category.color.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                        if (place.statusText != null)
                          Chip(
                            avatar: Icon(
                              place.openNow == true ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: place.openNow == true ? Colors.green : Colors.red,
                            ),
                            label: Text(place.statusText!),
                            backgroundColor: (place.openNow == true
                                    ? Colors.green
                                    : Colors.red)
                                .withValues(alpha: 0.1),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rating and reviews
                    if (place.rating != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Rating stars
                            Column(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    final rating = place.rating ?? 0;
                                    if (index < rating.floor()) {
                                      return Icon(Icons.star, color: Colors.amber[700], size: 24);
                                    } else if (index < rating) {
                                      return Icon(Icons.star_half, color: Colors.amber[700], size: 24);
                                    } else {
                                      return Icon(Icons.star_border, color: Colors.amber[700], size: 24);
                                    }
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  place.reviewsText,
                                  style: context.bodySmall.copyWith(
                                    color: context.textColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Rating number
                            Text(
                              place.ratingText,
                              style: context.headlineMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Vicinity
                    if (place.vicinity != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: context.textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.vicinity!,
                              style: context.bodyMedium.copyWith(
                                color: context.textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Additional details from API
                    detailsAsync.when(
                      data: (details) {
                        if (details == null) return const SizedBox.shrink();
                        return _buildDetailsSection(context, details);
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    _buildActionButtons(context, ref, detailsAsync),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context, WidgetRef ref) {
    if (place.hasPhotos) {
      final photoUrlAsync = ref.watch(
        placePhotoUrlProvider(place.firstPhotoReference!),
      );

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: photoUrlAsync.when(
            data: (url) {
              if (url == null) {
                return _buildFallbackImage(context);
              }
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingImage(context),
                errorWidget: (context, url, error) => _buildFallbackImage(context),
              );
            },
            loading: () => _buildLoadingImage(context),
            error: (error, stackTrace) => _buildFallbackImage(context),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: _buildFallbackImage(context),
      ),
    );
  }

  Widget _buildLoadingImage(BuildContext context) {
    return Container(
      color: place.category.color.withValues(alpha: 0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: place.category.color,
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            place.category.color.withValues(alpha: 0.3),
            place.category.color.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          place.category.icon,
          size: 64,
          color: place.category.color.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, dynamic details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Website
        if (details.website != null) ...[
          _buildDetailRow(
            context,
            icon: Icons.language,
            label: 'Website',
            value: details.website,
            onTap: () => _launchUrl(details.website),
          ),
          const SizedBox(height: 12),
        ],
        // Google Maps link
        if (details.url != null) ...[
          _buildDetailRow(
            context,
            icon: Icons.map,
            label: 'View on Google Maps',
            value: 'Open in Maps',
            onTap: () => _launchUrl(details.url),
          ),
          const SizedBox(height: 12),
        ],
        // Full address
        if (details.formattedAddress != null && details.formattedAddress.isNotEmpty)
          _buildDetailRow(
            context,
            icon: Icons.pin_drop,
            label: 'Address',
            value: details.formattedAddress,
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: context.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.bodySmall.copyWith(
                      color: context.textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    value,
                    style: context.bodyMedium.copyWith(
                      color: onTap != null ? context.primaryColor : null,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 16,
                color: context.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, AsyncValue<dynamic> detailsAsync) {
    return Row(
      children: [
        // Add to Trip button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to create itinerary item with this place
              _showAddToTripDialog(context, ref);
            },
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add to Trip'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Directions button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              if (place.latitude != null && place.longitude != null) {
                _launchMapsDirections(place.latitude!, place.longitude!);
              }
            },
            icon: const Icon(Icons.directions),
            label: const Text('Directions'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddToTripDialog(BuildContext context, WidgetRef ref) {
    // Convert DiscoverPlace to ParsedLocation for the AddLocationToTripSheet
    final location = ParsedLocation(
      latitude: place.latitude,
      longitude: place.longitude,
      placeName: place.name,
      placeId: place.placeId,
      originalUrl: 'https://www.google.com/maps/place/?q=place_id:${place.placeId}',
    );

    // Show the Add to Trip sheet
    AddLocationToTripSheet.show(context, location);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMapsDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    await _launchUrl(url);
  }
}
