import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/trips/presentation/pages/create_trip_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page_new.dart';
import '../../features/expenses/presentation/pages/expense_test_page.dart';
import '../../features/trip_invites/presentation/pages/accept_invite_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_list_page.dart';
import '../../features/itinerary/presentation/pages/add_edit_itinerary_item_page_new.dart';
import '../../features/checklists/presentation/pages/checklist_list_page.dart';
import '../../features/checklists/presentation/pages/checklist_detail_page.dart';
import '../../features/settings/presentation/pages/theme_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page_enhanced.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../presentation/main_scaffold.dart';

// Route names
class AppRoutes {
  static const String login = '/';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String tripDetail = '/trips/:tripId';
  static const String createTrip = '/trips/create';
  static const String editTrip = '/trips/:tripId/edit';
  static const String expenseList = '/trips/:tripId/expenses';
  static const String addExpense = '/trips/:tripId/expenses/add';
  static const String addStandaloneExpense = '/expenses/add';
  static const String expenseTest = '/expenses/test';
  static const String acceptInvite = '/invite/:inviteCode';
  static const String itinerary = '/trips/:tripId/itinerary';
  static const String addItineraryItem = '/trips/:tripId/itinerary/add';
  static const String editItineraryItem = '/trips/:tripId/itinerary/:itemId/edit';
  static const String checklistList = '/trips/:tripId/checklists';
  static const String checklistDetail = '/trips/:tripId/checklists/:checklistId';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String themeSettings = '/settings/theme';
  static const String onboarding = '/onboarding';
}

// Router provider with auth and onboarding redirect
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final onboardingState = ref.watch(onboardingStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      // Check if user is authenticated
      final isAuthenticated = authState.value != null;
      final needsOnboarding = onboardingState.value == false;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isSignupRoute = state.matchedLocation == AppRoutes.signup;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;
      final isInviteRoute = state.matchedLocation.startsWith('/invite/');

      // Allow invite routes without authentication
      if (isInviteRoute) {
        return null;
      }

      // If not authenticated and not on login/signup, redirect to login
      if (!isAuthenticated && !isLoginRoute && !isSignupRoute) {
        return AppRoutes.login;
      }

      // If authenticated but needs onboarding, show onboarding
      if (isAuthenticated && needsOnboarding && !isOnboardingRoute) {
        return AppRoutes.onboarding;
      }

      // If authenticated, completed onboarding, and on onboarding page, go to home
      if (isAuthenticated && !needsOnboarding && isOnboardingRoute) {
        return AppRoutes.home;
      }

      // If authenticated and on login/signup, redirect to home
      if (isAuthenticated && (isLoginRoute || isSignupRoute)) {
        return AppRoutes.home;
      }

      return null; // No redirect needed
    },
    routes: [
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
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        name: 'expenses',
        builder: (context, state) => const ExpensesShell(),
      ),
      GoRoute(
        path: AppRoutes.createTrip,
        name: 'createTrip',
        builder: (context, state) => const CreateTripPage(),
      ),
      GoRoute(
        path: AppRoutes.addStandaloneExpense,
        name: 'addStandaloneExpense',
        builder: (context, state) => const AddExpensePageNew(),
      ),
      GoRoute(
        path: AppRoutes.tripDetail,
        name: 'tripDetail',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return TripDetailPage(tripId: tripId);
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
          return AddExpensePageNew(tripId: tripId);
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
          return AddEditItineraryItemPageNew(tripId: tripId);
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
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPageEnhanced(),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        name: 'themeSettings',
        builder: (context, state) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
