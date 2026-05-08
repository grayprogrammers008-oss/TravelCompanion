import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/messaging/domain/entities/conversation_entity.dart';
import 'package:travel_crew/features/messaging/presentation/pages/conversation_info_page.dart';
import 'package:travel_crew/features/messaging/presentation/providers/conversation_providers.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

void main() {
  void expandViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  const tripId = 'trip-1';
  const conversationId = 'conv-1';
  const currentUserId = 'user-current';

  final now = DateTime.now();
  final testTheme = AppThemeData.getThemeData(AppThemeType.ocean);

  ConversationMemberEntity makeMember({
    required String userId,
    String role = 'member',
    String? userName,
  }) {
    return ConversationMemberEntity(
      id: 'cm-$userId',
      conversationId: conversationId,
      userId: userId,
      role: role,
      joinedAt: now,
      userName: userName,
    );
  }

  ConversationEntity makeConversation({
    bool isAdmin = true,
    String? description,
    bool isDefaultGroup = false,
  }) {
    return ConversationEntity(
      id: conversationId,
      tripId: tripId,
      name: 'Trip Planners',
      description: description,
      createdBy: currentUserId,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isDefaultGroup: isDefaultGroup,
      memberCount: 3,
      members: [
        makeMember(
          userId: currentUserId,
          role: isAdmin ? 'admin' : 'member',
          userName: 'Me',
        ),
        makeMember(userId: 'u2', role: 'member', userName: 'Alice'),
        makeMember(userId: 'u3', role: 'member', userName: 'Bob'),
      ],
    );
  }

  TripWithMembers makeTrip() {
    final trip = TripModel(
      id: tripId,
      name: 'Beach Trip',
      createdBy: currentUserId,
    );
    return TripWithMembers(
      trip: trip,
      members: [
        TripMemberModel(
          id: 'tm-1',
          tripId: tripId,
          userId: currentUserId,
          role: 'owner',
          fullName: 'Me Person',
          email: 'me@x.com',
        ),
        TripMemberModel(
          id: 'tm-2',
          tripId: tripId,
          userId: 'u2',
          role: 'admin',
          fullName: 'Alice Admin',
        ),
        TripMemberModel(
          id: 'tm-3',
          tripId: tripId,
          userId: 'u3',
          role: 'member',
          fullName: 'Bob Member',
        ),
      ],
    );
  }

  Widget buildPage({
    bool isDefaultGroup = false,
    ConversationEntity? conversation,
    List<ConversationMemberEntity>? members,
    Stream<TripWithMembers>? tripStream,
    Future<ConversationEntity>? conversationFuture,
  }) {
    final convo = conversation ?? makeConversation();
    final memberList = members ?? convo.members;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => ConversationInfoPage(
          tripId: tripId,
          conversationId: conversationId,
          currentUserId: currentUserId,
          isDefaultGroup: isDefaultGroup,
        ),
      ),
      GoRoute(
        path: '/trips/:id/conversations',
        builder: (_, _) => const Scaffold(body: Text('back to list')),
      ),
    ]);

    return ProviderScope(
      overrides: [
        theme_provider.currentThemeDataProvider.overrideWith((_) => testTheme),
        conversationProvider(
          const ConversationParams(
            conversationId: conversationId,
            userId: currentUserId,
          ),
        ).overrideWith((ref) => conversationFuture ?? Future.value(convo)),
        conversationMembersProvider(conversationId)
            .overrideWith((ref) => Future.value(memberList)),
        tripProvider(tripId).overrideWith(
          (ref) => tripStream ?? Stream.value(makeTrip()),
        ),
      ],
      child: AppThemeProvider(
        themeData: testTheme,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('ConversationInfoPage - normal group', () {
    testWidgets('renders Group Info app bar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Group Info'), findsOneWidget);
    });

    testWidgets('renders conversation name', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Trip Planners'), findsOneWidget);
    });

    testWidgets('renders member count subtitle', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('3 members'), findsOneWidget);
    });

    testWidgets('renders Created date', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Created '), findsOneWidget);
    });

    testWidgets('renders edit icon for admin', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('hides edit icon for non-admin', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        conversation: makeConversation(isAdmin: false),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('renders description section when description exists',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        conversation: makeConversation(description: 'Our planning chat'),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Our planning chat'), findsOneWidget);
    });

    testWidgets('renders Members section header', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Members'), findsOneWidget);
    });

    testWidgets('renders members list with names', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows You badge on current user tile', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('renders ADMIN/MEMBER role badges', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('MEMBER'), findsWidgets);
    });

    testWidgets('renders Add button for admin', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('Add button shows snackbar', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(find.text('Add members feature coming soon!'), findsOneWidget);
    });

    testWidgets('renders Mute Notifications switch', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Mute Notifications'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders Leave Group action', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Leave Group'), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
    });

    testWidgets('renders Delete Group only for admin', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      expect(find.text('Delete Group'), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('hides Delete Group for non-admin', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(
        conversation: makeConversation(isAdmin: false),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('Delete Group'), findsNothing);
    });

    testWidgets('Leave Group opens confirmation dialog', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Leave Group'));
      await tester.pump();

      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Delete Group opens confirmation dialog', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Delete Group'));
      await tester.pump();

      expect(find.text('Delete'), findsOneWidget);
      expect(
        find.textContaining('cannot be undone'),
        findsOneWidget,
      );
    });

    testWidgets('Mute switch shows snackbar when toggled', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('Mute feature coming soon!'), findsOneWidget);
    });

    testWidgets('Edit icon opens edit dialog', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(find.text('Edit Group'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('ConversationInfoPage - default "All Members" group', () {
    testWidgets('renders All Members title when isDefaultGroup=true',
        (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(isDefaultGroup: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('All Members'), findsOneWidget);
    });

    testWidgets('shows the default-group badge text', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(isDefaultGroup: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('📢 All Members'), findsOneWidget);
    });

    testWidgets('shows ALL MEMBERS badge', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(isDefaultGroup: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('ALL MEMBERS'), findsOneWidget);
    });

    testWidgets('shows trip member names', (tester) async {
      expandViewport(tester);
      await tester.pumpWidget(buildPage(isDefaultGroup: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('Me Person'), findsOneWidget);
      expect(find.text('Alice Admin'), findsOneWidget);
      expect(find.text('Bob Member'), findsOneWidget);
    });
  });
}
