// Tests for the AppRoutes route table.
//
// We test the constants/path table directly. The full GoRouter instance is
// not constructed because building it requires a fully initialized Supabase
// auth state (and several other providers). These tests focus on the
// invariants of the route table that can be verified without runtime setup.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/core/router/app_router.dart';

void main() {
  group('AppRoutes constants', () {
    test('splash is the root path', () {
      expect(AppRoutes.splash, equals('/'));
    });

    test('auth routes have expected paths', () {
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.signup, equals('/signup'));
      expect(AppRoutes.forgotPassword, equals('/forgot-password'));
      expect(AppRoutes.resetPassword, equals('/auth/reset-password'));
    });

    test('top-level shell routes have expected paths', () {
      expect(AppRoutes.dashboard, equals('/dashboard'));
      expect(AppRoutes.home, equals('/home'));
      expect(AppRoutes.trips, equals('/trips'));
      expect(AppRoutes.explore, equals('/explore'));
      expect(AppRoutes.discover, equals('/discover'));
      expect(AppRoutes.expenses, equals('/expenses'));
    });

    test('trip routes use :tripId param', () {
      expect(AppRoutes.tripDetail, contains(':tripId'));
      expect(AppRoutes.editTrip, contains(':tripId'));
      expect(AppRoutes.tripMembers, contains(':tripId'));
      expect(AppRoutes.expenseList, contains(':tripId'));
      expect(AppRoutes.addExpense, contains(':tripId'));
      expect(AppRoutes.settlementSummary, contains(':tripId'));
      expect(AppRoutes.itinerary, contains(':tripId'));
      expect(AppRoutes.checklistList, contains(':tripId'));
      expect(AppRoutes.chat, contains(':tripId'));
      expect(AppRoutes.conversations, contains(':tripId'));
    });

    test('checklistDetail uses both :tripId and :checklistId', () {
      expect(AppRoutes.checklistDetail, contains(':tripId'));
      expect(AppRoutes.checklistDetail, contains(':checklistId'));
    });

    test('editItineraryItem uses both :tripId and :itemId', () {
      expect(AppRoutes.editItineraryItem, contains(':tripId'));
      expect(AppRoutes.editItineraryItem, contains(':itemId'));
    });

    test('groupChat uses both :tripId and :conversationId', () {
      expect(AppRoutes.groupChat, contains(':tripId'));
      expect(AppRoutes.groupChat, contains(':conversationId'));
    });

    test('conversationInfo uses both :tripId and :conversationId', () {
      expect(AppRoutes.conversationInfo, contains(':tripId'));
      expect(AppRoutes.conversationInfo, contains(':conversationId'));
    });

    test('acceptInvite uses :inviteCode', () {
      expect(AppRoutes.acceptInvite, contains(':inviteCode'));
    });

    test('templateDetail uses :templateId', () {
      expect(AppRoutes.templateDetail, contains(':templateId'));
    });

    test('adminUserDetail uses :userId', () {
      expect(AppRoutes.adminUserDetail, contains(':userId'));
    });

    test('settings sub-routes are nested under /settings', () {
      expect(AppRoutes.themeSettings.startsWith('/settings/'), isTrue);
      expect(AppRoutes.statistics.startsWith('/settings/'), isTrue);
      expect(AppRoutes.admin.startsWith('/settings/'), isTrue);
      expect(AppRoutes.adminUserDetail.startsWith('/settings/admin/'), isTrue);
    });

    test('all top-level paths start with /', () {
      final allPaths = <String>[
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
        AppRoutes.dashboard,
        AppRoutes.home,
        AppRoutes.trips,
        AppRoutes.explore,
        AppRoutes.discover,
        AppRoutes.expenses,
        AppRoutes.tripDetail,
        AppRoutes.createTrip,
        AppRoutes.quickTrip,
        AppRoutes.voiceTrip,
        AppRoutes.aiTripWizard,
        AppRoutes.editTrip,
        AppRoutes.tripMembers,
        AppRoutes.tripFilter,
        AppRoutes.browseTrips,
        AppRoutes.expenseList,
        AppRoutes.addExpense,
        AppRoutes.settlementSummary,
        AppRoutes.addStandaloneExpense,
        AppRoutes.scanBill,
        AppRoutes.scanBillForTrip,
        AppRoutes.expenseTest,
        AppRoutes.acceptInvite,
        AppRoutes.joinByCode,
        AppRoutes.itinerary,
        AppRoutes.addItineraryItem,
        AppRoutes.editItineraryItem,
        AppRoutes.checklistList,
        AppRoutes.checklistDetail,
        AppRoutes.chat,
        AppRoutes.messageQueue,
        AppRoutes.conversations,
        AppRoutes.createConversation,
        AppRoutes.groupChat,
        AppRoutes.conversationInfo,
        AppRoutes.profile,
        AppRoutes.settings,
        AppRoutes.themeSettings,
        AppRoutes.statistics,
        AppRoutes.admin,
        AppRoutes.adminUserDetail,
        AppRoutes.tripHistory,
        AppRoutes.emergency,
        AppRoutes.onboarding,
        AppRoutes.welcomeChoice,
        AppRoutes.templates,
        AppRoutes.templateDetail,
        AppRoutes.aiItinerary,
      ];

      for (final p in allPaths) {
        expect(p.startsWith('/'), isTrue, reason: '"$p" does not start with /');
      }
    });

    test('all paths are unique', () {
      final allPaths = <String>[
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
        AppRoutes.dashboard,
        AppRoutes.home,
        AppRoutes.trips,
        AppRoutes.explore,
        AppRoutes.discover,
        AppRoutes.expenses,
        AppRoutes.tripDetail,
        AppRoutes.createTrip,
        AppRoutes.quickTrip,
        AppRoutes.voiceTrip,
        AppRoutes.aiTripWizard,
        AppRoutes.editTrip,
        AppRoutes.tripMembers,
        AppRoutes.tripFilter,
        AppRoutes.browseTrips,
        AppRoutes.expenseList,
        AppRoutes.addExpense,
        AppRoutes.settlementSummary,
        AppRoutes.addStandaloneExpense,
        AppRoutes.scanBill,
        AppRoutes.scanBillForTrip,
        AppRoutes.expenseTest,
        AppRoutes.acceptInvite,
        AppRoutes.joinByCode,
        AppRoutes.itinerary,
        AppRoutes.addItineraryItem,
        AppRoutes.editItineraryItem,
        AppRoutes.checklistList,
        AppRoutes.checklistDetail,
        AppRoutes.chat,
        AppRoutes.messageQueue,
        AppRoutes.conversations,
        AppRoutes.createConversation,
        AppRoutes.groupChat,
        AppRoutes.conversationInfo,
        AppRoutes.profile,
        AppRoutes.settings,
        AppRoutes.themeSettings,
        AppRoutes.statistics,
        AppRoutes.admin,
        AppRoutes.adminUserDetail,
        AppRoutes.tripHistory,
        AppRoutes.emergency,
        AppRoutes.onboarding,
        AppRoutes.welcomeChoice,
        AppRoutes.templates,
        AppRoutes.templateDetail,
        AppRoutes.aiItinerary,
      ];

      expect(allPaths.toSet().length, equals(allPaths.length),
          reason: 'Route table contains duplicate paths');
    });
  });

  group('buildPageWithoutTransition', () {
    test('returns a CustomTransitionPage with the supplied child and key', () {
      const key = ValueKey('test-key');
      const child = SizedBox(width: 42);
      final page = buildPageWithoutTransition(
        child: child,
        key: key,
      );

      expect(page.key, equals(key));
      expect(page, isA<CustomTransitionPage<void>>());
      expect((page as CustomTransitionPage).child, same(child));
    });
  });
}
