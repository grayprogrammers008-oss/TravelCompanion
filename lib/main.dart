import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/network/supabase_client.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_access.dart';
import 'features/messaging/data/initialization/messaging_initialization.dart';

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

  // Initialize messaging module (opens Hive boxes for messages)
  await MessagingInitialization.initialize();

  // Initialize Supabase Backend (online-only mode)
  try {
    await SupabaseClientWrapper.initialize();
    debugPrint('✅ Supabase initialized successfully (online-only mode)');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    debugPrint('⚠️  App requires internet connection to function');
  }

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
    final themeData = ref.watch(currentThemeDataProvider);

    return AppThemeProvider(
      themeData: themeData,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: themeData.toThemeData(),
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
      ),
    );
  }
}
