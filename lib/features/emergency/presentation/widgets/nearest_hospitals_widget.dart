import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/hospital_model.dart';
import '../../domain/usecases/find_nearest_hospitals_usecase.dart';
import '../providers/emergency_providers.dart';

/// Provider for finding nearest hospitals based on current location
final nearestHospitalsProvider = FutureProvider.autoDispose<List<HospitalModel>>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  final useCase = ref.watch(findNearestHospitalsUseCaseProvider);

  // Get current location
  final position = await locationService.getCurrentLocation();

  // Find nearest hospitals
  return await useCase(
    latitude: position.latitude,
    longitude: position.longitude,
    maxDistanceKm: 50.0,
    limit: 10,
    onlyEmergency: true,
  );
});

/// Provider for the find nearest hospitals use case
final findNearestHospitalsUseCaseProvider = Provider<FindNearestHospitalsUseCase>((ref) {
  final repository = ref.watch(emergencyRepositoryProvider);
  return FindNearestHospitalsUseCase(repository);
});

/// Widget that displays a list of nearest hospitals for medical emergencies
class NearestHospitalsWidget extends ConsumerWidget {
  final double? userLatitude;
  final double? userLongitude;
  final double maxDistance;
  final int limit;
  final bool onlyEmergency;
  final bool only24_7;

  const NearestHospitalsWidget({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.maxDistance = 50.0,
    this.limit = 10,
    this.onlyEmergency = true,
    this.only24_7 = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalsAsync = ref.watch(nearestHospitalsProvider);

    return hospitalsAsync.when(
      data: (hospitals) {
        if (hospitals.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildHospitalsList(context, hospitals);
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spacingMd),
            Text('Finding nearest hospitals...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No Hospitals Found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'No hospitals found within $maxDistance km radius.\nTry expanding your search area.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Error Loading Hospitals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalsList(BuildContext context, List<HospitalModel> hospitals) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      itemCount: hospitals.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMd),
      itemBuilder: (context, index) {
        final hospital = hospitals[index];
        return HospitalCard(hospital: hospital);
      },
    );
  }
}

/// Card widget to display individual hospital information
class HospitalCard extends StatelessWidget {
  final HospitalModel hospital;

  const HospitalCard({
    super.key,
    required this.hospital,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showHospitalDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and distance
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          hospital.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hospital.distanceKm != null) ...[
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildDistanceBadge(context),
                  ],
                ],
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Hospital features
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingXs,
                children: [
                  if (hospital.hasTraumaCenter)
                    _buildFeatureChip(
                      context,
                      'Trauma ${hospital.traumaLevel?.displayName ?? ''}',
                      Icons.emergency,
                      Colors.red,
                    ),
                  if (hospital.hasEmergencyRoom)
                    _buildFeatureChip(
                      context,
                      'Emergency',
                      Icons.local_hospital,
                      Colors.orange,
                    ),
                  if (hospital.is24_7)
                    _buildFeatureChip(
                      context,
                      '24/7',
                      Icons.access_time,
                      Colors.blue,
                    ),
                  if (hospital.rating != null)
                    _buildRatingChip(context),
                ],
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callHospital(context),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openDirections(context),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                      ),
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

  Widget _buildDistanceBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            hospital.distanceText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRatingChip(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
      label: Text('${hospital.rating}/5.0'),
      labelStyle: Theme.of(context).textTheme.bodySmall,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showHospitalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  hospital.fullAddress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (hospital.phoneNumber != null) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  Text('Phone: ${hospital.phoneNumber}'),
                ],
                if (hospital.services.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Services',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: hospital.services
                        .map((service) => Chip(label: Text(service)))
                        .toList(),
                  ),
                ],
                if (hospital.specialties.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    'Specialties',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: hospital.specialties
                        .map((specialty) => Chip(label: Text(specialty)))
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _callHospital(BuildContext context) async {
    final phoneNumber = hospital.emergencyPhone ?? hospital.phoneNumber;
    if (phoneNumber == null) {
      _showSnackBar(context, 'Phone number not available');
      return;
    }

    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        _showSnackBar(context, 'Cannot make phone call');
      }
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        _showSnackBar(context, 'Cannot open directions');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
