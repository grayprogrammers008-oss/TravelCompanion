import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/core/router/app_router.dart';
import 'package:travel_crew/core/constants/app_constants.dart';
import 'package:travel_crew/core/theme/theme_extensions.dart';
import 'package:travel_crew/core/widgets/app_loading_indicator.dart';

/// Splash screen that handles initial app routing
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    // Show splash for minimum 2 seconds, then navigate based on auth state
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasNavigated) {
        _checkAuthAndNavigate();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_hasNavigated) return;

    // Use authStateProvider (stream-based) which is what the router uses
    // This properly waits for Supabase auth initialization
    final authState = ref.read(authStateProvider);

    await authState.when(
      data: (userId) async {
        if (!mounted || _hasNavigated) return;

        if (userId != null) {
          // User is logged in - check if they have trips
          try {
            final hasTrips = await ref.read(hasTripsProvider.future);

            if (!mounted || _hasNavigated) return;
            _hasNavigated = true;

            if (hasTrips) {
              // User has trips, go directly to dashboard
              context.go(AppRoutes.dashboard);
            } else {
              // User has no trips, show welcome choice page
              context.go(AppRoutes.welcomeChoice);
            }
          } catch (e) {
            // On error, default to welcome choice
            if (mounted && !_hasNavigated) {
              _hasNavigated = true;
              context.go(AppRoutes.welcomeChoice);
            }
          }
        } else {
          // User is not logged in, go to login
          if (!_hasNavigated) {
            _hasNavigated = true;
            context.go(AppRoutes.login);
          }
        }
      },
      loading: () {
        // Still loading auth state, wait a bit and try again
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_hasNavigated) {
            _checkAuthAndNavigate();
          }
        });
      },
      error: (error, stack) {
        // On error, go to login
        if (!_hasNavigated) {
          _hasNavigated = true;
          context.go(AppRoutes.login);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryColor,
              context.accentColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_takeoff, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: context.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: context.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const AppLoadingIndicator(
                size: 80,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
