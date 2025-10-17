import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/trips/presentation/pages/create_trip_page.dart';
import '../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/expenses/presentation/pages/expense_test_page.dart';
import '../../features/trip_invites/presentation/pages/accept_invite_page.dart';
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
}

// Router provider with auth redirect
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      // Check if user is authenticated
      final isAuthenticated = authState.value != null;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isSignupRoute = state.matchedLocation == AppRoutes.signup;
      final isInviteRoute = state.matchedLocation.startsWith('/invite/');

      // Allow invite routes without authentication
      if (isInviteRoute) {
        return null;
      }

      // If not authenticated and not on login/signup, redirect to login
      if (!isAuthenticated && !isLoginRoute && !isSignupRoute) {
        return AppRoutes.login;
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
        builder: (context, state) => const AddExpensePage(),
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
          return AddExpensePage(tripId: tripId);
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
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
