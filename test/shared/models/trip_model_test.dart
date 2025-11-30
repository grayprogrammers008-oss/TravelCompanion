import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

void main() {
  group('TripModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final endDate = DateTime(2024, 1, 20, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        const trip = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
        );

        expect(trip.id, 'trip-1');
        expect(trip.name, 'Beach Vacation');
        expect(trip.createdBy, 'user-1');
        expect(trip.isCompleted, false);
        expect(trip.rating, 0.0);
        expect(trip.currency, 'INR');
      });

      test('should create instance with all fields', () {
        final trip = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          description: 'Annual team outing',
          destination: 'Goa',
          startDate: testDate,
          endDate: endDate,
          coverImageUrl: 'https://example.com/cover.jpg',
          createdBy: 'user-1',
          createdAt: testDate,
          updatedAt: testDate,
          isCompleted: true,
          completedAt: endDate,
          rating: 4.5,
          budget: 50000.0,
          currency: 'USD',
        );

        expect(trip.description, 'Annual team outing');
        expect(trip.destination, 'Goa');
        expect(trip.startDate, testDate);
        expect(trip.endDate, endDate);
        expect(trip.coverImageUrl, 'https://example.com/cover.jpg');
        expect(trip.createdAt, testDate);
        expect(trip.updatedAt, testDate);
        expect(trip.isCompleted, true);
        expect(trip.completedAt, endDate);
        expect(trip.rating, 4.5);
        expect(trip.budget, 50000.0);
        expect(trip.currency, 'USD');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'trip-1',
          'name': 'Beach Vacation',
          'description': 'Annual team outing',
          'destination': 'Goa',
          'start_date': '2024-01-15T10:30:00.000Z',
          'end_date': '2024-01-20T10:30:00.000Z',
          'cover_image_url': 'https://example.com/cover.jpg',
          'created_by': 'user-1',
          'created_at': '2024-01-10T10:30:00.000Z',
          'updated_at': '2024-01-12T10:30:00.000Z',
          'is_completed': true,
          'completed_at': '2024-01-20T18:00:00.000Z',
          'rating': 4.5,
          'budget': 50000.0,
          'currency': 'USD',
        };

        final trip = TripModel.fromJson(json);

        expect(trip.id, 'trip-1');
        expect(trip.name, 'Beach Vacation');
        expect(trip.description, 'Annual team outing');
        expect(trip.destination, 'Goa');
        expect(trip.isCompleted, true);
        expect(trip.rating, 4.5);
        expect(trip.budget, 50000.0);
        expect(trip.currency, 'USD');
      });

      test('should use defaults when missing', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
        };

        final trip = TripModel.fromJson(json);
        expect(trip.isCompleted, false);
        expect(trip.rating, 0.0);
        expect(trip.currency, 'INR');
      });

      test('should handle null dates', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
        };

        final trip = TripModel.fromJson(json);
        expect(trip.startDate, isNull);
        expect(trip.endDate, isNull);
        expect(trip.createdAt, isNull);
        expect(trip.updatedAt, isNull);
        expect(trip.completedAt, isNull);
      });

      test('should handle numeric rating as int', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'rating': 4,
        };

        final trip = TripModel.fromJson(json);
        expect(trip.rating, 4.0);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final trip = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          description: 'Annual team outing',
          destination: 'Goa',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 20),
          coverImageUrl: 'https://example.com/cover.jpg',
          createdBy: 'user-1',
          isCompleted: true,
          rating: 4.5,
          budget: 50000.0,
          currency: 'USD',
        );

        final json = trip.toJson();

        expect(json['id'], 'trip-1');
        expect(json['name'], 'Beach Vacation');
        expect(json['description'], 'Annual team outing');
        expect(json['destination'], 'Goa');
        expect(json['created_by'], 'user-1');
        expect(json['is_completed'], true);
        expect(json['rating'], 4.5);
        expect(json['budget'], 50000.0);
        expect(json['currency'], 'USD');
      });

      test('should handle null optional fields', () {
        const trip = TripModel(
          id: 'trip-1',
          name: 'Trip',
          createdBy: 'user-1',
        );

        final json = trip.toJson();

        expect(json['description'], isNull);
        expect(json['destination'], isNull);
        expect(json['start_date'], isNull);
        expect(json['end_date'], isNull);
        expect(json['cover_image_url'], isNull);
        expect(json['created_at'], isNull);
        expect(json['updated_at'], isNull);
        expect(json['completed_at'], isNull);
        expect(json['budget'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = TripModel(
          id: 'trip-1',
          name: 'Original',
          createdBy: 'user-1',
          isCompleted: false,
        );

        final copied = original.copyWith(
          name: 'Updated',
          isCompleted: true,
          rating: 5.0,
        );

        expect(copied.id, 'trip-1');
        expect(copied.name, 'Updated');
        expect(copied.isCompleted, true);
        expect(copied.rating, 5.0);
        expect(copied.createdBy, 'user-1');
      });

      test('should keep original values when not specified', () {
        final original = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          description: 'Team outing',
          destination: 'Goa',
          startDate: testDate,
          endDate: endDate,
          coverImageUrl: 'https://example.com/cover.jpg',
          createdBy: 'user-1',
          createdAt: testDate,
          updatedAt: testDate,
          isCompleted: true,
          completedAt: endDate,
          rating: 4.5,
          budget: 50000.0,
          currency: 'USD',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.name, original.name);
        expect(copied.description, original.description);
        expect(copied.destination, original.destination);
        expect(copied.startDate, original.startDate);
        expect(copied.endDate, original.endDate);
        expect(copied.coverImageUrl, original.coverImageUrl);
        expect(copied.createdBy, original.createdBy);
        expect(copied.createdAt, original.createdAt);
        expect(copied.updatedAt, original.updatedAt);
        expect(copied.isCompleted, original.isCompleted);
        expect(copied.completedAt, original.completedAt);
        expect(copied.rating, original.rating);
        expect(copied.budget, original.budget);
        expect(copied.currency, original.currency);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final trip1 = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
          createdAt: testDate,
        );

        final trip2 = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
          createdAt: testDate,
        );

        expect(trip1, equals(trip2));
      });

      test('should not be equal when different id', () {
        const trip1 = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
        );

        const trip2 = TripModel(
          id: 'trip-2',
          name: 'Beach Vacation',
          createdBy: 'user-1',
        );

        expect(trip1, isNot(equals(trip2)));
      });

      test('should be identical to itself', () {
        const trip = TripModel(
          id: 'trip-1',
          name: 'Trip',
          createdBy: 'user-1',
        );

        expect(trip == trip, true);
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal objects', () {
        final trip1 = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
          createdAt: testDate,
        );

        final trip2 = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
          createdAt: testDate,
        );

        expect(trip1.hashCode, equals(trip2.hashCode));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        const trip = TripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
        );

        final str = trip.toString();
        expect(str, contains('TripModel'));
        expect(str, contains('trip-1'));
        expect(str, contains('Beach Vacation'));
      });
    });
  });

  group('TripMemberModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        const member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'admin',
        );

        expect(member.id, 'member-1');
        expect(member.tripId, 'trip-1');
        expect(member.userId, 'user-1');
        expect(member.role, 'admin');
      });

      test('should create instance with all fields', () {
        final member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'member',
          joinedAt: testDate,
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          email: 'john@example.com',
        );

        expect(member.joinedAt, testDate);
        expect(member.fullName, 'John Doe');
        expect(member.avatarUrl, 'https://example.com/avatar.jpg');
        expect(member.email, 'john@example.com');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'id': 'member-1',
          'trip_id': 'trip-1',
          'user_id': 'user-1',
          'role': 'admin',
          'joined_at': '2024-01-15T10:30:00.000Z',
          'full_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'email': 'john@example.com',
        };

        final member = TripMemberModel.fromJson(json);

        expect(member.id, 'member-1');
        expect(member.tripId, 'trip-1');
        expect(member.userId, 'user-1');
        expect(member.role, 'admin');
        expect(member.fullName, 'John Doe');
        expect(member.email, 'john@example.com');
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'member-1',
          'trip_id': 'trip-1',
          'user_id': 'user-1',
          'role': 'member',
        };

        final member = TripMemberModel.fromJson(json);
        expect(member.joinedAt, isNull);
        expect(member.fullName, isNull);
        expect(member.avatarUrl, isNull);
        expect(member.email, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: DateTime(2024, 1, 15),
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          email: 'john@example.com',
        );

        final json = member.toJson();

        expect(json['id'], 'member-1');
        expect(json['trip_id'], 'trip-1');
        expect(json['user_id'], 'user-1');
        expect(json['role'], 'admin');
        expect(json['full_name'], 'John Doe');
        expect(json['email'], 'john@example.com');
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'member',
        );

        final copied = original.copyWith(
          role: 'admin',
          fullName: 'John Doe',
        );

        expect(copied.id, 'member-1');
        expect(copied.role, 'admin');
        expect(copied.fullName, 'John Doe');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final member1 = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: testDate,
        );

        final member2 = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'admin',
          joinedAt: testDate,
        );

        expect(member1, equals(member2));
      });

      test('should be identical to itself', () {
        const member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-1',
          userId: 'user-1',
          role: 'admin',
        );

        expect(member == member, true);
      });
    });
  });

  group('TripWithMembers', () {
    test('should create instance', () {
      const trip = TripModel(
        id: 'trip-1',
        name: 'Beach Vacation',
        createdBy: 'user-1',
      );

      const member = TripMemberModel(
        id: 'member-1',
        tripId: 'trip-1',
        userId: 'user-1',
        role: 'admin',
      );

      const tripWithMembers = TripWithMembers(
        trip: trip,
        members: [member],
        memberCount: 1,
      );

      expect(tripWithMembers.trip, trip);
      expect(tripWithMembers.members.length, 1);
      expect(tripWithMembers.memberCount, 1);
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'trip': {
            'id': 'trip-1',
            'name': 'Beach Vacation',
            'created_by': 'user-1',
          },
          'members': [
            {
              'id': 'member-1',
              'trip_id': 'trip-1',
              'user_id': 'user-1',
              'role': 'admin',
            }
          ],
          'member_count': 1,
        };

        final tripWithMembers = TripWithMembers.fromJson(json);

        expect(tripWithMembers.trip.id, 'trip-1');
        expect(tripWithMembers.members.length, 1);
        expect(tripWithMembers.memberCount, 1);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        const tripWithMembers = TripWithMembers(
          trip: TripModel(
            id: 'trip-1',
            name: 'Beach Vacation',
            createdBy: 'user-1',
          ),
          members: [
            TripMemberModel(
              id: 'member-1',
              tripId: 'trip-1',
              userId: 'user-1',
              role: 'admin',
            )
          ],
          memberCount: 1,
        );

        final json = tripWithMembers.toJson();

        expect(json['trip']['id'], 'trip-1');
        expect((json['members'] as List).length, 1);
        expect(json['member_count'], 1);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = TripWithMembers(
          trip: TripModel(
            id: 'trip-1',
            name: 'Beach Vacation',
            createdBy: 'user-1',
          ),
          members: [],
          memberCount: 0,
        );

        final newTrip = original.trip.copyWith(name: 'Updated Trip');
        final copied = original.copyWith(trip: newTrip, memberCount: 5);

        expect(copied.trip.name, 'Updated Trip');
        expect(copied.memberCount, 5);
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        const tripWithMembers1 = TripWithMembers(
          trip: TripModel(
            id: 'trip-1',
            name: 'Beach Vacation',
            createdBy: 'user-1',
          ),
          members: [
            TripMemberModel(
              id: 'member-1',
              tripId: 'trip-1',
              userId: 'user-1',
              role: 'admin',
            )
          ],
          memberCount: 1,
        );

        const tripWithMembers2 = TripWithMembers(
          trip: TripModel(
            id: 'trip-1',
            name: 'Beach Vacation',
            createdBy: 'user-1',
          ),
          members: [
            TripMemberModel(
              id: 'member-1',
              tripId: 'trip-1',
              userId: 'user-1',
              role: 'admin',
            )
          ],
          memberCount: 1,
        );

        expect(tripWithMembers1, equals(tripWithMembers2));
      });

      test('should not be equal when different members', () {
        const tripWithMembers1 = TripWithMembers(
          trip: TripModel(
            id: 'trip-1',
            name: 'Beach Vacation',
            createdBy: 'user-1',
          ),
          members: [],
        );

        const tripWithMembers2 = TripWithMembers(
          trip: TripModel(
            id: 'trip-1',
            name: 'Beach Vacation',
            createdBy: 'user-1',
          ),
          members: [
            TripMemberModel(
              id: 'member-1',
              tripId: 'trip-1',
              userId: 'user-1',
              role: 'admin',
            )
          ],
        );

        expect(tripWithMembers1, isNot(equals(tripWithMembers2)));
      });
    });
  });
}
