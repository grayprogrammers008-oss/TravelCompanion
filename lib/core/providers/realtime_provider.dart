import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';

/// Provider for RealtimeService
///
/// Single instance shared across the app
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();

  // Cleanup when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for active realtime channel count
///
/// Useful for debugging and monitoring
final activeChannelCountProvider = Provider<int>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.activeChannelCount;
});
