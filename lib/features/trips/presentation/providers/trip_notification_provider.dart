import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/services/trip_notification_service.dart';

/// Trip Notification Service Provider
final tripNotificationServiceProvider = Provider<TripNotificationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TripNotificationService(supabase);
});
