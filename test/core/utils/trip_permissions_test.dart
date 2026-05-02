import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/utils/trip_permissions.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

TripModel _trip({
  String createdBy = 'owner-1',
  bool isCompleted = false,
  String id = 'trip-1',
}) =>
    TripModel(
      id: id,
      name: 'Test Trip',
      createdBy: createdBy,
      isCompleted: isCompleted,
    );

TripMemberModel _member(String userId, {String role = 'member', String tripId = 'trip-1'}) =>
    TripMemberModel(
      id: 'm-$userId',
      tripId: tripId,
      userId: userId,
      role: role,
    );

TripWithMembers _build({
  required TripModel trip,
  List<TripMemberModel>? members,
}) =>
    TripWithMembers(
      trip: trip,
      members: members ?? const [],
    );

void main() {
  group('TripPermissions.canEditTrip', () {
    test('returns false when currentUserId is null', () {
      final t = _build(trip: _trip());
      expect(TripPermissions.canEditTrip(currentUserId: null, tripWithMembers: t), false);
    });

    test('returns false when trip is completed even for owner', () {
      final t = _build(trip: _trip(createdBy: 'me', isCompleted: true));
      expect(TripPermissions.canEditTrip(currentUserId: 'me', tripWithMembers: t), false);
    });

    test('returns true for owner of an active trip', () {
      final t = _build(trip: _trip(createdBy: 'me'));
      expect(TripPermissions.canEditTrip(currentUserId: 'me', tripWithMembers: t), true);
    });

    test('returns false for non-owner', () {
      final t = _build(trip: _trip(createdBy: 'someone'));
      expect(TripPermissions.canEditTrip(currentUserId: 'me', tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canDeleteTrip', () {
    test('only owner can delete', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(TripPermissions.canDeleteTrip(currentUserId: 'owner', tripWithMembers: t), true);
      expect(TripPermissions.canDeleteTrip(currentUserId: 'other', tripWithMembers: t), false);
      expect(TripPermissions.canDeleteTrip(currentUserId: null, tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canEditItinerary', () {
    test('owner can edit when active', () {
      final t = _build(trip: _trip(createdBy: 'me'));
      expect(TripPermissions.canEditItinerary(currentUserId: 'me', tripWithMembers: t), true);
    });

    test('admin member can edit', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('admin-1', role: 'admin')],
      );
      expect(TripPermissions.canEditItinerary(currentUserId: 'admin-1', tripWithMembers: t), true);
    });

    test('regular member cannot edit', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('member-1', role: 'member')],
      );
      expect(TripPermissions.canEditItinerary(currentUserId: 'member-1', tripWithMembers: t), false);
    });

    test('completed trip cannot be edited even by owner', () {
      final t = _build(trip: _trip(createdBy: 'me', isCompleted: true));
      expect(TripPermissions.canEditItinerary(currentUserId: 'me', tripWithMembers: t), false);
    });

    test('null user cannot edit', () {
      final t = _build(trip: _trip());
      expect(TripPermissions.canEditItinerary(currentUserId: null, tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canEditChecklists', () {
    test('owner can edit', () {
      final t = _build(trip: _trip(createdBy: 'me'));
      expect(TripPermissions.canEditChecklists(currentUserId: 'me', tripWithMembers: t), true);
    });

    test('admin can edit', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('a', role: 'admin')],
      );
      expect(TripPermissions.canEditChecklists(currentUserId: 'a', tripWithMembers: t), true);
    });

    test('member cannot edit', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('m', role: 'member')],
      );
      expect(TripPermissions.canEditChecklists(currentUserId: 'm', tripWithMembers: t), false);
    });

    test('cannot edit when trip is completed', () {
      final t = _build(
        trip: _trip(createdBy: 'me', isCompleted: true),
      );
      expect(TripPermissions.canEditChecklists(currentUserId: 'me', tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canAddExpenses', () {
    test('any member (incl. admin) can add', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [
          _member('member-1', role: 'member'),
          _member('admin-1', role: 'admin'),
        ],
      );
      expect(TripPermissions.canAddExpenses(currentUserId: 'member-1', tripWithMembers: t), true);
      expect(TripPermissions.canAddExpenses(currentUserId: 'admin-1', tripWithMembers: t), true);
    });

    test('non-member cannot add', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(TripPermissions.canAddExpenses(currentUserId: 'rando', tripWithMembers: t), false);
    });

    test('null user cannot add', () {
      final t = _build(trip: _trip());
      expect(TripPermissions.canAddExpenses(currentUserId: null, tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canEditExpense', () {
    test('user can edit their own expense', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(
        TripPermissions.canEditExpense(
          currentUserId: 'me',
          expenseCreatedBy: 'me',
          tripWithMembers: t,
        ),
        true,
      );
    });

    test('owner can edit any expense', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(
        TripPermissions.canEditExpense(
          currentUserId: 'owner',
          expenseCreatedBy: 'someone-else',
          tripWithMembers: t,
        ),
        true,
      );
    });

    test('admin can edit any expense', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('admin-1', role: 'admin')],
      );
      expect(
        TripPermissions.canEditExpense(
          currentUserId: 'admin-1',
          expenseCreatedBy: 'someone-else',
          tripWithMembers: t,
        ),
        true,
      );
    });

    test('regular member cannot edit other people\'s expenses', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('member-1', role: 'member')],
      );
      expect(
        TripPermissions.canEditExpense(
          currentUserId: 'member-1',
          expenseCreatedBy: 'someone-else',
          tripWithMembers: t,
        ),
        false,
      );
    });

    test('null user cannot edit', () {
      final t = _build(trip: _trip());
      expect(
        TripPermissions.canEditExpense(
          currentUserId: null,
          expenseCreatedBy: 'me',
          tripWithMembers: t,
        ),
        false,
      );
    });
  });

  group('TripPermissions.canManageMembers', () {
    test('owner can manage', () {
      final t = _build(trip: _trip(createdBy: 'me'));
      expect(TripPermissions.canManageMembers(currentUserId: 'me', tripWithMembers: t), true);
    });

    test('admin can manage', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('a', role: 'admin')],
      );
      expect(TripPermissions.canManageMembers(currentUserId: 'a', tripWithMembers: t), true);
    });

    test('member cannot manage', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('m', role: 'member')],
      );
      expect(TripPermissions.canManageMembers(currentUserId: 'm', tripWithMembers: t), false);
    });

    test('completed trip blocks management', () {
      final t = _build(trip: _trip(createdBy: 'me', isCompleted: true));
      expect(TripPermissions.canManageMembers(currentUserId: 'me', tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canCompletTrip', () {
    test('only owner can complete', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(TripPermissions.canCompletTrip(currentUserId: 'owner', tripWithMembers: t), true);
      expect(TripPermissions.canCompletTrip(currentUserId: 'other', tripWithMembers: t), false);
      expect(TripPermissions.canCompletTrip(currentUserId: null, tripWithMembers: t), false);
    });
  });

  group('TripPermissions.canEditRating', () {
    test('owner can edit even after completion', () {
      final completed = _build(trip: _trip(createdBy: 'me', isCompleted: true));
      expect(TripPermissions.canEditRating(currentUserId: 'me', tripWithMembers: completed), true);
    });

    test('non-owner cannot rate', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(TripPermissions.canEditRating(currentUserId: 'me', tripWithMembers: t), false);
    });
  });

  group('TripPermissions.getPermissionLevel', () {
    test('null user => none', () {
      final t = _build(trip: _trip());
      expect(
        TripPermissions.getPermissionLevel(currentUserId: null, tripWithMembers: t),
        TripPermissionLevel.none,
      );
    });

    test('owner => owner', () {
      final t = _build(trip: _trip(createdBy: 'me'));
      expect(
        TripPermissions.getPermissionLevel(currentUserId: 'me', tripWithMembers: t),
        TripPermissionLevel.owner,
      );
    });

    test('admin role => admin', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('a', role: 'admin')],
      );
      expect(
        TripPermissions.getPermissionLevel(currentUserId: 'a', tripWithMembers: t),
        TripPermissionLevel.admin,
      );
    });

    test('member role => member', () {
      final t = _build(
        trip: _trip(createdBy: 'owner'),
        members: [_member('m', role: 'member')],
      );
      expect(
        TripPermissions.getPermissionLevel(currentUserId: 'm', tripWithMembers: t),
        TripPermissionLevel.member,
      );
    });

    test('not a member => none', () {
      final t = _build(trip: _trip(createdBy: 'owner'));
      expect(
        TripPermissions.getPermissionLevel(currentUserId: 'rando', tripWithMembers: t),
        TripPermissionLevel.none,
      );
    });
  });

  group('TripPermissionLevel enum', () {
    test('has four distinct values', () {
      expect(TripPermissionLevel.values.length, 4);
      expect(TripPermissionLevel.values.toSet().length, 4);
    });
  });
}
