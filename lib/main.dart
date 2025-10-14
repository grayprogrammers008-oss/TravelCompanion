import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// SUPABASE DISABLED - Using SQLite for local development
// import 'core/network/supabase_client.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for premium look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize SQLite Database (replaces Supabase)
  try {
    await DatabaseHelper.instance.database;
    debugPrint('SQLite database initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize SQLite: $e');
  }

  // SUPABASE INITIALIZATION - DISABLED FOR LOCAL DEVELOPMENT
  // Uncomment when ready to migrate to Supabase:
  // try {
  //   await SupabaseClientWrapper.initialize();
  // } catch (e) {
  //   debugPrint('Failed to initialize Supabase: $e');
  // }

  runApp(
    // ProviderScope enables Riverpod state management
    const ProviderScope(child: TravelCrewApp()),
  );
}

class TravelCrewApp extends ConsumerWidget {
  const TravelCrewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      // Premium scrolling physics
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            scrollbars: false,
          ),
          child: child!,
        );
      },
    );
  }
}
