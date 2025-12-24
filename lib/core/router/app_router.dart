import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/trips/presentation/pages/create_trip_page.dart';
import '../../features/trips/presentation/pages/trip_filter_page.dart';
import '../../features/trips/presentation/pages/browse_trips_page.dart';
import '../../features/trips/presentation/pages/trip_members_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/expenses/presentation/pages/expense_test_page.dart';
import '../../features/expenses/presentation/pages/settlement_summary_page.dart';
import '../../features/trip_invites/presentation/pages/accept_invite_page.dart';
import '../../features/trip_invites/presentation/pages/join_trip_by_code_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_list_page.dart';
import '../../features/itinerary/presentation/pages/add_edit_itinerary_item_page_new.dart';
import '../../features/checklists/presentation/pages/checklist_list_page.dart';
import '../../features/checklists/presentation/pages/checklist_detail_page.dart';
import '../../features/messaging/presentation/pages/chat_screen.dart';
import '../../features/messaging/presentation/pages/message_queue_screen.dart';
import '../../features/messaging/presentation/pages/conversation_list_page.dart';
import '../../features/messaging/presentation/pages/create_conversation_page.dart';
import '../../features/messaging/presentation/pages/group_chat_page.dart';
import '../../features/messaging/presentation/pages/conversation_info_page.dart';
import '../../features/settings/presentation/pages/theme_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page_enhanced.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/statistics/presentation/pages/travel_statistics_page.dart';
import '../../features/trips/presentation/pages/trip_history_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/emergency/presentation/pages/emergency_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_user_detail_page.dart';
import '../../features/templates/presentation/pages/browse_templates_page.dart';
import '../../features/templates/presentation/pages/template_detail_page.dart';
import '../../features/ai_itinerary/presentation/pages/ai_itinerary_generator_page.dart';
import '../../features/trips/presentation/pages/quick_trip_page.dart';
import '../../features/trips/presentation/pages/voice_trip_page.dart';
import '../../features/trips/presentation/pages/ai_trip_wizard_page.dart';
import '../../features/onboarding/presentation/pages/welcome_choice_page.dart';
import '../../features/trips/presentation/providers/trip_providers.dart';
import '../presentation/main_scaffold.dart';

// Custom page builder that removes the white transition overlay
Page<void> buildPageWithoutTransition<T>({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // No transition animation - instant page swap
      return child;
    },
  );
}

// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String dashboard = '/dashboard';
  static const String home = '/home'; // Legacy - redirects to dashboard
  static const String trips = '/trips';
  static const String explore = '/explore';
  static const String discover = '/discover';
  static const String expenses = '/expenses';
  static const String tripDetail = '/trips/:tripId';
  static const String createTrip = '/trips/create';
  static const String quickTrip = '/trips/quick';
  static const String voiceTrip = '/trips/voice';
  static const String aiTripWizard = '/trips/ai-wizard';
  static const String editTrip = '/trips/:tripId/edit';
  static const String tripMembers = '/trips/:tripId/members';
  static const String tripFilter = '/trips/filter';
  static const String browseTrips = '/trips/browse';
  static const String expenseList = '/trips/:tripId/expenses';
  static const String addExpense = '/trips/:tripId/expenses/add';
  static const String settlementSummary = '/trips/:tripId/expenses/settle';
  static const String addStandaloneExpense = '/expenses/add';
  static const String expenseTest = '/expenses/test';
  static const String acceptInvite = '/invite/:inviteCode';
  static const String joinByCode = '/join-trip';
  static const String itinerary = '/trips/:tripId/itinerary';
  static const String addItineraryItem = '/trips/:tripId/itinerary/add';
  static const String editItineraryItem = '/trips/:tripId/itinerary/:itemId/edit';
  static const String checklistList = '/trips/:tripId/checklists';
  static const String checklistDetail = '/trips/:tripId/checklists/:checklistId';
  static const String chat = '/trips/:tripId/chat';
  static const String messageQueue = '/trips/:tripId/messages/queue';
  static const String conversations = '/trips/:tripId/conversations';
  static const String createConversation = '/trips/:tripId/conversations/create';
  static const String groupChat = '/trips/:tripId/conversations/:conversationId';
  static const String conversationInfo = '/trips/:tripId/conversations/:conversationId/info';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String themeSettings = '/settings/theme';
  static const String statistics = '/settings/statistics';
  static const String admin = '/settings/admin';
  static const String adminUserDetail = '/settings/admin/users/:userId';
  static const String tripHistory = '/trip-history';
  static const String emergency = '/emergency';
  static const String onboarding = '/onboarding';
  static const String welcomeChoice = '/welcome';
  static const String templates = '/templates';
  static const String templateDetail = '/templates/:templateId';
  static const String aiItinerary = '/ai-itinerary';
}

// Router provider with auth and onboarding redirect
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingState = ref.watch(onboardingStateProvider);
  final hasTripsState = ref.watch(hasTripsProvider);
  // Watch password reset state to prevent redirects during OTP verification
  final passwordResetState = ref.watch(passwordResetProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash, // Start at splash screen
    redirect: (context, state) {
      final isForgotPasswordRoute = state.matchedLocation == AppRoutes.forgotPassword;

      // CRITICAL: Password reset flow check MUST be first, before ANY other logic
      // This prevents redirects after OTP verification creates a session
      // The router rebuilds when authState changes, but we must stay on forgot-password
      if (passwordResetState.isInFlow) {
        debugPrint('🔐 [Router] Password reset flow active - BLOCKING ALL REDIRECTS');
        debugPrint('   isInFlow: ${passwordResetState.isInFlow}');
        debugPrint('   currentStep: ${passwordResetState.currentStep}');
        debugPrint('   evaluating route: ${state.matchedLocation}');
        debugPrint('   authState: ${authState.value != null ? "authenticated" : "not authenticated"}');

        // If evaluating any route while in flow, force to forgot-password
        if (!isForgotPasswordRoute) {
          debugPrint('   → Redirecting to forgot-password');
          return AppRoutes.forgotPassword;
        }
        debugPrint('   → Staying on forgot-password (no redirect)');
        return null;
      }

      // Check if user is authenticated
      final isAuthenticated = authState.value != null;
      final needsOnboarding = onboardingState.value == false;
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isSignupRoute = state.matchedLocation == AppRoutes.signup;
      final isResetPasswordRoute = state.matchedLocation.startsWith('/auth/reset-password');
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;
      final isInviteRoute = state.matchedLocation.startsWith('/invite/');
      final isWelcomeChoiceRoute = state.matchedLocation == AppRoutes.welcomeChoice;

      // Allow splash screen to handle its own routing (no redirect)
      if (isSplashRoute) {
        return null;
      }

      // Allow reset password and forgot password routes without authentication
      if (isResetPasswordRoute || isForgotPasswordRoute) {
        return null;
      }

      // If not authenticated and not on login/signup/splash, redirect to login
      // Store invite code in query parameter to redirect after login
      if (!isAuthenticated && !isLoginRoute && !isSignupRoute) {
        // If user is trying to access an invite, save the path for after login
        if (isInviteRoute) {
          return '${AppRoutes.login}?redirect=${Uri.encodeComponent(state.matchedLocation)}';
        }
        return AppRoutes.login;
      }

      // If authenticated but needs onboarding, show onboarding
      if (isAuthenticated && needsOnboarding && !isOnboardingRoute) {
        return AppRoutes.onboarding;
      }

      // Check if user has trips to determine redirect destination
      // IMPORTANT: Wait for hasTripsProvider to resolve before redirecting
      // This prevents the flash of Welcome page for returning users
      final hasTripsLoading = hasTripsState.isLoading;
      final hasTrips = hasTripsState.value ?? false;

      // If authenticated, completed onboarding, and on onboarding page
      if (isAuthenticated && !needsOnboarding && isOnboardingRoute) {
        // Wait for trips data to load before deciding where to go
        if (hasTripsLoading) {
          return null; // Stay on onboarding while loading
        }
        // V2.0: All users go to Trips tab (the new primary hub)
        // New users see empty state with create/join options
        // Returning users see their trip list
        return AppRoutes.trips;
      }

      // If authenticated and on login/signup, redirect based on trip status
      if (isAuthenticated && (isLoginRoute || isSignupRoute)) {
        // Wait for trips data to load before deciding where to go
        // This prevents the flash of Welcome page for returning users
        if (hasTripsLoading) {
          return null; // Stay on login page while loading (shows loading indicator)
        }
        // V2.0: All users go to Trips tab
        return AppRoutes.trips;
      }

      // If user has trips but is on welcome choice page, redirect to trips
      // (This handles returning users who navigate back to welcome page)
      if (isAuthenticated && hasTrips && isWelcomeChoiceRoute) {
        return AppRoutes.trips;
      }

      // V2.0: Redirect legacy /dashboard route to /trips
      final isDashboardRoute = state.matchedLocation == AppRoutes.dashboard;
      if (isAuthenticated && isDashboardRoute) {
        return AppRoutes.trips;
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash screen - handles initial auth check and routing
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          // Supabase can send either 'access_token' or 'code' parameter
          final accessToken = state.uri.queryParameters['access_token'] ??
                             state.uri.queryParameters['code'];
          return ResetPasswordPage(accessToken: accessToken);
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const DashboardShell(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        redirect: (context, state) => AppRoutes.dashboard, // Legacy redirect
      ),
      GoRoute(
        path: AppRoutes.trips,
        name: 'trips',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const TripsShell(),
        ),
      ),
      GoRoute(
        path: AppRoutes.explore,
        name: 'explore',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const ExploreShell(),
        ),
      ),
      GoRoute(
        path: AppRoutes.discover,
        name: 'discover',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const DiscoverShell(),
        ),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const ExpensesShell(),
        ),
      ),
      GoRoute(
        path: AppRoutes.createTrip,
        name: 'createTrip',
        pageBuilder: (context, state) {
          // Extract query parameters for pre-filling from AI Itinerary or Template
          final destination = state.uri.queryParameters['destination'];
          final startDateStr = state.uri.queryParameters['startDate'];
          final endDateStr = state.uri.queryParameters['endDate'];
          final budgetStr = state.uri.queryParameters['budget'];
          final templateId = state.uri.queryParameters['templateId'];
          final durationDaysStr = state.uri.queryParameters['durationDays'];

          return NoTransitionPage(
            key: state.pageKey,
            child: CreateTripPage(
              prefillDestination: destination,
              prefillStartDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
              prefillEndDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
              prefillCost: budgetStr != null ? double.tryParse(budgetStr) : null,
              templateId: templateId,
              templateDurationDays: durationDaysStr != null ? int.tryParse(durationDaysStr) : null,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quickTrip,
        name: 'quickTrip',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const QuickTripPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.voiceTrip,
        name: 'voiceTrip',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const VoiceTripPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.aiTripWizard,
        name: 'aiTripWizard',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const AiTripWizardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addStandaloneExpense,
        name: 'addStandaloneExpense',
        builder: (context, state) => const AddExpensePage(),
      ),
      // IMPORTANT: Specific routes must come BEFORE parameterized routes
      GoRoute(
        path: AppRoutes.tripFilter,
        name: 'tripFilter',
        builder: (context, state) {
          print('🔍 DEBUG: tripFilter route matched! Path: ${state.matchedLocation}');
          final minBudget = state.uri.queryParameters['minBudget'];
          final maxBudget = state.uri.queryParameters['maxBudget'];
          final createdAfter = state.uri.queryParameters['createdAfter'];
          final createdBefore = state.uri.queryParameters['createdBefore'];

          return TripFilterPage(
            initialMinBudget: minBudget != null ? double.tryParse(minBudget) : null,
            initialMaxBudget: maxBudget != null ? double.tryParse(maxBudget) : null,
            initialCreatedAfter: createdAfter != null ? DateTime.tryParse(createdAfter) : null,
            initialCreatedBefore: createdBefore != null ? DateTime.tryParse(createdBefore) : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.browseTrips,
        name: 'browseTrips',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const BrowseTripsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.tripDetail,
        name: 'tripDetail',
        pageBuilder: (context, state) {
          print('🔍 DEBUG: tripDetail route matched! TripId: ${state.pathParameters['tripId']}');
          final tripId = state.pathParameters['tripId']!;
          return NoTransitionPage(
            key: state.pageKey,
            child: TripDetailShell(tripId: tripId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editTrip,
        name: 'editTrip',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return CreateTripPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.tripMembers,
        name: 'tripMembers',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripMembersPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.expenseList,
        name: 'expenseList',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return ExpenseListPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.addExpense,
        name: 'addExpense',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return AddExpensePage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.settlementSummary,
        name: 'settlementSummary',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return SettlementSummaryPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.expenseTest,
        name: 'expenseTest',
        builder: (context, state) => const ExpenseTestPage(),
      ),
      GoRoute(
        path: AppRoutes.acceptInvite,
        name: 'acceptInvite',
        builder: (context, state) {
          final inviteCode = state.pathParameters['inviteCode']!;
          return AcceptInvitePage(inviteCode: inviteCode);
        },
      ),
      GoRoute(
        path: AppRoutes.joinByCode,
        name: 'joinByCode',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const JoinTripByCodePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.itinerary,
        name: 'itinerary',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return ItineraryListPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.addItineraryItem,
        name: 'addItineraryItem',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          // Extract prefill data from extra (used by "Add to Trip" flow)
          final extra = state.extra as Map<String, dynamic>?;
          return AddEditItineraryItemPageNew(
            tripId: tripId,
            prefillTitle: extra?['prefillTitle'] as String?,
            prefillLocation: extra?['prefillLocation'] as String?,
            prefillDescription: extra?['prefillDescription'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editItineraryItem,
        name: 'editItineraryItem',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final itemId = state.pathParameters['itemId']!;
          return AddEditItineraryItemPageNew(tripId: tripId, itemId: itemId);
        },
      ),
      GoRoute(
        path: AppRoutes.checklistList,
        name: 'checklistList',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return ChecklistListPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.checklistDetail,
        name: 'checklistDetail',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final checklistId = state.pathParameters['checklistId']!;
          return ChecklistDetailPage(tripId: tripId, checklistId: checklistId);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final tripName = state.uri.queryParameters['tripName'] ?? 'Chat';
          final currentUserId = state.uri.queryParameters['userId'] ?? '';
          return ChatScreen(
            tripId: tripId,
            tripName: tripName,
            currentUserId: currentUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.messageQueue,
        name: 'messageQueue',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return MessageQueueScreen(tripId: tripId);
        },
      ),
      // Group Chat / Conversations routes
      GoRoute(
        path: AppRoutes.createConversation,
        name: 'createConversation',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final currentUserId = state.uri.queryParameters['userId'] ?? '';
          final preselectedUserId = state.uri.queryParameters['dmWith'];
          return CreateConversationPage(
            tripId: tripId,
            currentUserId: currentUserId,
            preselectedUserId: preselectedUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.conversationInfo,
        name: 'conversationInfo',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final conversationId = state.pathParameters['conversationId']!;
          final currentUserId = state.uri.queryParameters['userId'] ?? '';
          final isDefaultGroup = state.uri.queryParameters['isDefaultGroup'] == 'true';
          return ConversationInfoPage(
            tripId: tripId,
            conversationId: conversationId,
            currentUserId: currentUserId,
            isDefaultGroup: isDefaultGroup,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.groupChat,
        name: 'groupChat',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final conversationId = state.pathParameters['conversationId']!;
          final currentUserId = state.uri.queryParameters['userId'] ?? '';
          return GroupChatPage(
            tripId: tripId,
            conversationId: conversationId,
            currentUserId: currentUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.conversations,
        name: 'conversations',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final tripName = state.uri.queryParameters['tripName'] ?? 'Trip';
          final currentUserId = state.uri.queryParameters['userId'] ?? '';
          return ConversationListPage(
            tripId: tripId,
            tripName: tripName,
            currentUserId: currentUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          final fullName = state.uri.queryParameters['fullName'];
          final email = state.uri.queryParameters['email'];
          final role = state.uri.queryParameters['role'];

          // If viewing another user's profile (has userId param), show without bottom nav
          if (userId != null && userId.isNotEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: ProfilePage(
                userId: userId,
                fullName: fullName,
                email: email,
                role: role,
              ),
            );
          }

          // Own profile - show with bottom nav via ProfileShell
          return NoTransitionPage(
            key: state.pageKey,
            child: const ProfileShell(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SettingsPageEnhanced(),
        ),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        name: 'themeSettings',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const ThemeSettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const TravelStatisticsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUserDetail,
        name: 'adminUserDetail',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return AdminUserDetailPage(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.tripHistory,
        name: 'tripHistory',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const TripHistoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        name: 'emergency',
        builder: (context, state) {
          final tripId = state.uri.queryParameters['tripId'];
          return EmergencyPage(tripId: tripId);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Welcome choice page for new users
      GoRoute(
        path: AppRoutes.welcomeChoice,
        name: 'welcomeChoice',
        builder: (context, state) => const WelcomeChoicePage(),
      ),
      // Trip Templates routes
      GoRoute(
        path: AppRoutes.templates,
        name: 'templates',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const BrowseTemplatesPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.templateDetail,
        name: 'templateDetail',
        builder: (context, state) {
          final templateId = state.pathParameters['templateId']!;
          return TemplateDetailPage(templateId: templateId);
        },
      ),
      // AI Itinerary Generator route
      GoRoute(
        path: AppRoutes.aiItinerary,
        name: 'aiItinerary',
        pageBuilder: (context, state) {
          // Extract query parameters (for launching from itinerary page)
          final tripId = state.uri.queryParameters['tripId'];
          final destination = state.uri.queryParameters['destination'];
          final startDateStr = state.uri.queryParameters['startDate'];
          final endDateStr = state.uri.queryParameters['endDate'];
          final budgetStr = state.uri.queryParameters['budget'];
          final voicePrompt = state.uri.queryParameters['voicePrompt'];

          return NoTransitionPage(
            key: state.pageKey,
            child: AiItineraryGeneratorPage(
              tripId: tripId,
              prefillDestination: destination,
              prefillStartDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
              prefillEndDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
              prefillBudget: budgetStr != null ? double.tryParse(budgetStr) : null,
              voicePrompt: voicePrompt,
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
