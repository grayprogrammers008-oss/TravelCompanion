import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_trip.dart';

void main() {
  group('AdminTripModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final endDate = DateTime(2024, 1, 20, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        const trip = AdminTripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          createdBy: 'user-1',
          creatorName: 'John Doe',
          creatorEmail: 'john@example.com',
        );

        expect(trip.id, 'trip-1');
        expect(trip.name, 'Beach Vacation');
        expect(trip.createdBy, 'user-1');
        expect(trip.creatorName, 'John Doe');
        expect(trip.creatorEmail, 'john@example.com');
        expect(trip.isCompleted, false);
        expect(trip.rating, 0.0);
        expect(trip.currency, 'INR');
        expect(trip.memberCount, 0);
      });

      test('should create instance with all fields', () {
        final trip = AdminTripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          description: 'Annual team outing',
          destination: 'Goa',
          startDate: testDate,
          endDate: endDate,
          coverImageUrl: 'https://example.com/cover.jpg',
          createdBy: 'user-1',
          creatorName: 'John Doe',
          creatorEmail: 'john@example.com',
          createdAt: testDate,
          updatedAt: testDate,
          isCompleted: true,
          completedAt: endDate,
          rating: 4.5,
          budget: 50000.0,
          currency: 'USD',
          memberCount: 5,
          totalExpenses: 45000.0,
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
        expect(trip.memberCount, 5);
        expect(trip.totalExpenses, 45000.0);
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
          'creator_name': 'John Doe',
          'creator_email': 'john@example.com',
          'created_at': '2024-01-10T10:30:00.000Z',
          'updated_at': '2024-01-12T10:30:00.000Z',
          'is_completed': true,
          'completed_at': '2024-01-20T18:00:00.000Z',
          'rating': 4.5,
          'budget': 50000.0,
          'currency': 'USD',
          'member_count': 5,
          'total_expenses': 45000.0,
        };

        final trip = AdminTripModel.fromJson(json);

        expect(trip.id, 'trip-1');
        expect(trip.name, 'Beach Vacation');
        expect(trip.description, 'Annual team outing');
        expect(trip.destination, 'Goa');
        expect(trip.startDate, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(trip.endDate, DateTime.parse('2024-01-20T10:30:00.000Z'));
        expect(trip.coverImageUrl, 'https://example.com/cover.jpg');
        expect(trip.createdBy, 'user-1');
        expect(trip.creatorName, 'John Doe');
        expect(trip.creatorEmail, 'john@example.com');
        expect(trip.createdAt, DateTime.parse('2024-01-10T10:30:00.000Z'));
        expect(trip.updatedAt, DateTime.parse('2024-01-12T10:30:00.000Z'));
        expect(trip.isCompleted, true);
        expect(trip.completedAt, DateTime.parse('2024-01-20T18:00:00.000Z'));
        expect(trip.rating, 4.5);
        expect(trip.budget, 50000.0);
        expect(trip.currency, 'USD');
        expect(trip.memberCount, 5);
        expect(trip.totalExpenses, 45000.0);
      });

      test('should handle null id with empty string', () {
        final json = {
          'id': null,
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.id, '');
      });

      test('should handle null name with default', () {
        final json = {
          'id': 'trip-1',
          'name': null,
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.name, 'Unnamed Trip');
      });

      test('should handle null creator_name with default', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': null,
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.creatorName, 'Unknown');
      });

      test('should handle null created_by with empty string', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': null,
          'creator_name': 'John',
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.createdBy, '');
      });

      test('should handle null creator_email with empty string', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': null,
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.creatorEmail, '');
      });

      test('should use default currency when missing', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.currency, 'INR');
      });

      test('should handle is_completed as false when null', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
          'is_completed': null,
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.isCompleted, false);
      });

      test('should handle is_completed as false when not true', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
          'is_completed': false,
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.isCompleted, false);
      });

      test('should handle default rating when missing', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.rating, 0.0);
      });

      test('should handle default member_count when missing', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.memberCount, 0);
      });

      test('should handle invalid date strings', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
          'start_date': 'invalid',
          'end_date': 'also-invalid',
          'created_at': 'bad-date',
          'updated_at': 'wrong',
          'completed_at': 'nope',
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.startDate, isNull);
        expect(trip.endDate, isNull);
        expect(trip.createdAt, isNull);
        expect(trip.updatedAt, isNull);
        expect(trip.completedAt, isNull);
      });

      test('should handle numeric values as num', () {
        final json = {
          'id': 'trip-1',
          'name': 'Trip',
          'created_by': 'user-1',
          'creator_name': 'John',
          'creator_email': 'john@example.com',
          'rating': 4,
          'budget': 50000,
          'member_count': 5.0,
          'total_expenses': 45000,
        };

        final trip = AdminTripModel.fromJson(json);
        expect(trip.rating, 4.0);
        expect(trip.budget, 50000.0);
        expect(trip.memberCount, 5);
        expect(trip.totalExpenses, 45000.0);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final trip = AdminTripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          description: 'Annual team outing',
          destination: 'Goa',
          startDate: DateTime(2024, 1, 15, 10, 30),
          endDate: DateTime(2024, 1, 20, 10, 30),
          coverImageUrl: 'https://example.com/cover.jpg',
          createdBy: 'user-1',
          creatorName: 'John Doe',
          creatorEmail: 'john@example.com',
          createdAt: DateTime(2024, 1, 10, 10, 30),
          updatedAt: DateTime(2024, 1, 12, 10, 30),
          isCompleted: true,
          completedAt: DateTime(2024, 1, 20, 18, 0),
          rating: 4.5,
          budget: 50000.0,
          currency: 'USD',
          memberCount: 5,
          totalExpenses: 45000.0,
        );

        final json = trip.toJson();

        expect(json['id'], 'trip-1');
        expect(json['name'], 'Beach Vacation');
        expect(json['description'], 'Annual team outing');
        expect(json['destination'], 'Goa');
        expect(json['cover_image_url'], 'https://example.com/cover.jpg');
        expect(json['created_by'], 'user-1');
        expect(json['creator_name'], 'John Doe');
        expect(json['creator_email'], 'john@example.com');
        expect(json['is_completed'], true);
        expect(json['rating'], 4.5);
        expect(json['budget'], 50000.0);
        expect(json['currency'], 'USD');
        expect(json['member_count'], 5);
        expect(json['total_expenses'], 45000.0);
      });

      test('should handle null optional fields', () {
        const trip = AdminTripModel(
          id: 'trip-1',
          name: 'Trip',
          createdBy: 'user-1',
          creatorName: 'John',
          creatorEmail: 'john@example.com',
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
        expect(json['total_expenses'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = AdminTripModel(
          id: 'trip-1',
          name: 'Original Trip',
          createdBy: 'user-1',
          creatorName: 'John',
          creatorEmail: 'john@example.com',
          isCompleted: false,
          rating: 3.0,
        );

        final copied = original.copyWith(
          name: 'Updated Trip',
          isCompleted: true,
          rating: 5.0,
        );

        expect(copied.id, 'trip-1');
        expect(copied.name, 'Updated Trip');
        expect(copied.isCompleted, true);
        expect(copied.rating, 5.0);
        expect(copied.creatorName, 'John');
      });

      test('should keep original values when not specified', () {
        final original = AdminTripModel(
          id: 'trip-1',
          name: 'Beach Vacation',
          description: 'Team outing',
          destination: 'Goa',
          startDate: testDate,
          endDate: endDate,
          coverImageUrl: 'https://example.com/cover.jpg',
          createdBy: 'user-1',
          creatorName: 'John Doe',
          creatorEmail: 'john@example.com',
          createdAt: testDate,
          updatedAt: testDate,
          isCompleted: true,
          completedAt: endDate,
          rating: 4.5,
          budget: 50000.0,
          currency: 'USD',
          memberCount: 5,
          totalExpenses: 45000.0,
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
        expect(copied.creatorName, original.creatorName);
        expect(copied.creatorEmail, original.creatorEmail);
        expect(copied.createdAt, original.createdAt);
        expect(copied.updatedAt, original.updatedAt);
        expect(copied.isCompleted, original.isCompleted);
        expect(copied.completedAt, original.completedAt);
        expect(copied.rating, original.rating);
        expect(copied.budget, original.budget);
        expect(copied.currency, original.currency);
        expect(copied.memberCount, original.memberCount);
        expect(copied.totalExpenses, original.totalExpenses);
      });
    });
  });

  group('TripListParams', () {
    group('constructor', () {
      test('should create with default values', () {
        const params = TripListParams();
        expect(params.limit, 50);
        expect(params.offset, 0);
        expect(params.search, isNull);
        expect(params.status, isNull);
      });

      test('should create with specified values', () {
        const params = TripListParams(
          limit: 20,
          offset: 10,
          search: 'beach',
          status: 'completed',
        );
        expect(params.limit, 20);
        expect(params.offset, 10);
        expect(params.search, 'beach');
        expect(params.status, 'completed');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        const params1 = TripListParams(limit: 20, search: 'test');
        const params2 = TripListParams(limit: 20, search: 'test');
        expect(params1, equals(params2));
      });

      test('should not be equal when different values', () {
        const params1 = TripListParams(limit: 20, search: 'test');
        const params2 = TripListParams(limit: 30, search: 'test');
        expect(params1, isNot(equals(params2)));
      });

      test('should not be equal when different status', () {
        const params1 = TripListParams(status: 'active');
        const params2 = TripListParams(status: 'completed');
        expect(params1, isNot(equals(params2)));
      });

      test('should be identical to itself', () {
        const params = TripListParams(limit: 20);
        expect(params == params, true);
      });

      test('should handle null values correctly', () {
        const params1 = TripListParams();
        const params2 = TripListParams();
        expect(params1, equals(params2));
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal objects', () {
        const params1 = TripListParams(limit: 20, status: 'active');
        const params2 = TripListParams(limit: 20, status: 'active');
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('should generally have different hashCode for different objects', () {
        const params1 = TripListParams(limit: 20, search: 'test');
        const params2 = TripListParams(limit: 30, search: 'other');
        expect(params1.hashCode, isNot(equals(params2.hashCode)));
      });
    });
  });
}
