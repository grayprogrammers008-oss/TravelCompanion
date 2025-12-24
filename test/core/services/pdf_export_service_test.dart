import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/shared/models/expense_model.dart';
import 'package:travel_crew/features/checklists/domain/entities/checklist_entity.dart';
import 'package:travel_crew/features/itinerary/domain/entities/itinerary_entity.dart';

void main() {
  group('PdfExportService data preparation', () {
    final testDate = DateTime(2025, 1, 24);
    final endDate = DateTime(2025, 1, 28);

    group('TripModel for PDF', () {
      test('should prepare trip with all fields for PDF', () {
        final trip = TripModel(
          id: 'trip-123',
          name: 'Beach Vacation',
          description: 'A relaxing trip to the beach',
          destination: 'Goa, India',
          startDate: testDate,
          endDate: endDate,
          createdBy: 'user-1',
          isCompleted: false,
          rating: 4.5,
          cost: 50000,
          currency: 'INR',
        );

        expect(trip.id, 'trip-123');
        expect(trip.name, 'Beach Vacation');
        expect(trip.destination, 'Goa, India');
        expect(trip.startDate, testDate);
        expect(trip.endDate, endDate);
        expect(trip.isCompleted, false);
        expect(trip.cost, 50000);
        expect(trip.currency, 'INR');
      });

      test('should calculate trip duration for PDF', () {
        final trip = TripModel(
          id: 'trip-123',
          name: 'Trip',
          startDate: testDate,
          endDate: endDate,
          createdBy: 'user-1',
        );

        final duration = trip.endDate!.difference(trip.startDate!).inDays + 1;
        expect(duration, 5);
      });

      test('should handle completed trip status for PDF', () {
        final trip = TripModel(
          id: 'trip-123',
          name: 'Completed Trip',
          createdBy: 'user-1',
          isCompleted: true,
          completedAt: testDate,
        );

        expect(trip.isCompleted, true);
        expect(trip.completedAt, testDate);
      });

      test('should handle trip without dates', () {
        final trip = TripModel(
          id: 'trip-123',
          name: 'Trip',
          createdBy: 'user-1',
        );

        expect(trip.startDate, isNull);
        expect(trip.endDate, isNull);
      });

      test('should handle trip without cost', () {
        final trip = TripModel(
          id: 'trip-123',
          name: 'Trip',
          createdBy: 'user-1',
        );

        expect(trip.cost, isNull);
        expect(trip.currency, 'INR'); // Default
      });
    });

    group('TripMemberModel for PDF', () {
      test('should prepare member with profile data for PDF', () {
        final member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-123',
          userId: 'user-1',
          role: 'admin',
          fullName: 'John Doe',
          email: 'john@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        expect(member.fullName, 'John Doe');
        expect(member.role, 'admin');
        expect(member.email, 'john@example.com');
      });

      test('should handle member without full profile', () {
        final member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-123',
          userId: 'user-1',
          role: 'member',
        );

        expect(member.fullName, isNull);
        expect(member.role, 'member');
      });

      test('should get first letter for avatar initial', () {
        final member = TripMemberModel(
          id: 'member-1',
          tripId: 'trip-123',
          userId: 'user-1',
          role: 'member',
          fullName: 'John Doe',
        );

        final initial = (member.fullName ?? 'U')[0].toUpperCase();
        expect(initial, 'J');
      });
    });

    group('ExpenseModel for PDF', () {
      test('should prepare expense with all fields for PDF', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          tripId: 'trip-123',
          title: 'Dinner',
          description: 'Team dinner at restaurant',
          amount: 2500,
          currency: 'INR',
          category: 'Food',
          paidBy: 'user-1',
          transactionDate: testDate,
        );

        expect(expense.title, 'Dinner');
        expect(expense.description, 'Team dinner at restaurant');
        expect(expense.amount, 2500);
        expect(expense.category, 'Food');
        expect(expense.transactionDate, testDate);
      });

      test('should calculate expense total for PDF', () {
        final expenses = [
          ExpenseModel(
            id: 'e1',
            title: 'Food',
            amount: 1000,
            paidBy: 'user-1',
          ),
          ExpenseModel(
            id: 'e2',
            title: 'Transport',
            amount: 500,
            paidBy: 'user-1',
          ),
          ExpenseModel(
            id: 'e3',
            title: 'Hotel',
            amount: 5000,
            paidBy: 'user-1',
          ),
        ];

        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        expect(total, 6500);
      });

      test('should group expenses by category for PDF', () {
        final expenses = [
          ExpenseModel(id: 'e1', title: 'Lunch', amount: 500, paidBy: 'u1', category: 'Food'),
          ExpenseModel(id: 'e2', title: 'Dinner', amount: 800, paidBy: 'u1', category: 'Food'),
          ExpenseModel(id: 'e3', title: 'Taxi', amount: 300, paidBy: 'u1', category: 'Transport'),
          ExpenseModel(id: 'e4', title: 'Hotel', amount: 3000, paidBy: 'u1', category: 'Accommodation'),
        ];

        final byCategory = <String, double>{};
        for (final expense in expenses) {
          final category = expense.category ?? 'Other';
          byCategory[category] = (byCategory[category] ?? 0) + expense.amount;
        }

        expect(byCategory['Food'], 1300);
        expect(byCategory['Transport'], 300);
        expect(byCategory['Accommodation'], 3000);
      });

      test('should handle expense without category', () {
        final expense = ExpenseModel(
          id: 'expense-1',
          title: 'Misc',
          amount: 100,
          paidBy: 'user-1',
        );

        final category = expense.category ?? 'Other';
        expect(category, 'Other');
      });
    });

    group('ChecklistEntity for PDF', () {
      test('should prepare checklist with items for PDF', () {
        final checklist = ChecklistEntity(
          id: 'checklist-1',
          tripId: 'trip-123',
          name: 'Packing List',
          createdBy: 'user-1',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(checklist.name, 'Packing List');
        expect(checklist.tripId, 'trip-123');
      });

      test('should calculate checklist progress for PDF', () {
        final items = [
          ChecklistItemEntity(
            id: 'item-1',
            checklistId: 'checklist-1',
            title: 'Passport',
            isCompleted: true,
            createdAt: testDate,
            updatedAt: testDate,
          ),
          ChecklistItemEntity(
            id: 'item-2',
            checklistId: 'checklist-1',
            title: 'Clothes',
            isCompleted: true,
            createdAt: testDate,
            updatedAt: testDate,
          ),
          ChecklistItemEntity(
            id: 'item-3',
            checklistId: 'checklist-1',
            title: 'Sunscreen',
            isCompleted: false,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        final completedCount = items.where((i) => i.isCompleted).length;
        final totalCount = items.length;

        expect(completedCount, 2);
        expect(totalCount, 3);
        expect('$completedCount/$totalCount', '2/3');
      });

      test('should handle checklist with all items completed', () {
        final items = [
          ChecklistItemEntity(
            id: 'item-1',
            checklistId: 'checklist-1',
            title: 'Item 1',
            isCompleted: true,
            createdAt: testDate,
            updatedAt: testDate,
          ),
          ChecklistItemEntity(
            id: 'item-2',
            checklistId: 'checklist-1',
            title: 'Item 2',
            isCompleted: true,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        final allCompleted = items.every((i) => i.isCompleted);
        expect(allCompleted, true);
      });
    });

    group('ItineraryItemEntity for PDF', () {
      test('should prepare itinerary item for PDF', () {
        final item = ItineraryItemEntity(
          id: 'itinerary-1',
          tripId: 'trip-123',
          title: 'Visit Beach',
          description: 'Morning beach visit',
          location: 'Baga Beach',
          startTime: DateTime(2025, 1, 24, 9, 0),
          endTime: DateTime(2025, 1, 24, 12, 0),
          dayNumber: 1,
          orderIndex: 0,
        );

        expect(item.title, 'Visit Beach');
        expect(item.location, 'Baga Beach');
        expect(item.dayNumber, 1);
      });

      test('should group itinerary by date for PDF', () {
        final items = [
          ItineraryItemEntity(
            id: 'i1',
            tripId: 'trip-1',
            title: 'Morning Activity',
            startTime: DateTime(2025, 1, 24, 9, 0),
            dayNumber: 1,
            orderIndex: 0,
          ),
          ItineraryItemEntity(
            id: 'i2',
            tripId: 'trip-1',
            title: 'Afternoon Activity',
            startTime: DateTime(2025, 1, 24, 14, 0),
            dayNumber: 1,
            orderIndex: 1,
          ),
          ItineraryItemEntity(
            id: 'i3',
            tripId: 'trip-1',
            title: 'Day 2 Activity',
            startTime: DateTime(2025, 1, 25, 10, 0),
            dayNumber: 2,
            orderIndex: 0,
          ),
        ];

        final grouped = <int, List<ItineraryItemEntity>>{};
        for (final item in items) {
          final day = item.dayNumber ?? 0;
          grouped.putIfAbsent(day, () => []).add(item);
        }

        expect(grouped[1]?.length, 2);
        expect(grouped[2]?.length, 1);
      });

      test('should handle itinerary item without time', () {
        final item = ItineraryItemEntity(
          id: 'itinerary-1',
          tripId: 'trip-123',
          title: 'Free Time',
          dayNumber: 1,
          orderIndex: 0,
        );

        expect(item.startTime, isNull);
        expect(item.endTime, isNull);
      });

      test('should check if item has location coordinates', () {
        final itemWithLocation = ItineraryItemEntity(
          id: 'i1',
          tripId: 'trip-1',
          title: 'Beach',
          latitude: 15.5524,
          longitude: 73.7512,
          dayNumber: 1,
          orderIndex: 0,
        );

        final itemWithoutLocation = ItineraryItemEntity(
          id: 'i2',
          tripId: 'trip-1',
          title: 'Rest',
          dayNumber: 1,
          orderIndex: 1,
        );

        expect(itemWithLocation.hasMapLocation, true);
        expect(itemWithoutLocation.hasMapLocation, false);
      });
    });

    group('PDF export limits', () {
      test('should limit expenses to 20 for PDF', () {
        final expenses = List.generate(
          30,
          (i) => ExpenseModel(
            id: 'e$i',
            title: 'Expense $i',
            amount: 100.0,
            paidBy: 'user-1',
          ),
        );

        final limitedExpenses = expenses.take(20).toList();
        expect(limitedExpenses.length, 20);
        expect(expenses.length, 30);
      });

      test('should indicate more expenses exist when over limit', () {
        final expenses = List.generate(
          25,
          (i) => ExpenseModel(
            id: 'e$i',
            title: 'Expense $i',
            amount: 100.0,
            paidBy: 'user-1',
          ),
        );

        final hasMore = expenses.length > 20;
        final moreCount = expenses.length - 20;

        expect(hasMore, true);
        expect(moreCount, 5);
      });

      test('should limit checklist items to 10 per checklist for PDF', () {
        final items = List.generate(
          15,
          (i) => ChecklistItemEntity(
            id: 'item-$i',
            checklistId: 'checklist-1',
            title: 'Item $i',
            isCompleted: i % 2 == 0,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        );

        final limitedItems = items.take(10).toList();
        expect(limitedItems.length, 10);
        expect(items.length, 15);
      });
    });
  });
}
