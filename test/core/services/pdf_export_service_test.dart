// Tests for PdfExportService.buildTripPdfBytes — pure-Dart byte generation
// path that does NOT touch the file system or the Share plugin.

import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/core/services/pdf_export_service.dart';
import 'package:pathio/features/checklists/domain/entities/checklist_entity.dart';
import 'package:pathio/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:pathio/shared/models/trip_model.dart';
import 'package:pathio/shared/models/itinerary_model.dart';

TripModel _trip({
  String? name,
  String? destination = 'Bali',
  DateTime? start,
  DateTime? end,
  String? description,
  bool isCompleted = false,
  double? cost,
  String currency = 'INR',
}) {
  return TripModel(
    id: 't1',
    name: name ?? 'Trip',
    description: description,
    destination: destination,
    startDate: start ?? DateTime(2024, 6, 1),
    endDate: end ?? DateTime(2024, 6, 5),
    createdBy: 'user-1',
    isCompleted: isCompleted,
    cost: cost,
    currency: currency,
  );
}

TripMemberModel _member({String? fullName = 'Alice', String role = 'admin'}) {
  return TripMemberModel(
    id: 'm-1',
    tripId: 't1',
    userId: 'u-1',
    role: role,
    fullName: fullName,
  );
}

ChecklistWithItemsEntity _checklist({
  required String name,
  required List<ChecklistItemEntity> items,
}) {
  return ChecklistWithItemsEntity(
    checklist: ChecklistEntity(id: 'c1', tripId: 't1', name: name),
    items: items,
  );
}

ChecklistItemEntity _item({
  String? id,
  String title = 'Item',
  bool completed = false,
}) {
  return ChecklistItemEntity(
    id: id ?? 'i-${DateTime.now().microsecondsSinceEpoch}',
    checklistId: 'c1',
    title: title,
    isCompleted: completed,
  );
}

ItineraryItemEntity _itinItem({
  String id = 'a',
  String title = 'Activity',
  String? location,
  String? description,
  DateTime? startTime,
  int? dayNumber,
  int orderIndex = 0,
}) {
  return ItineraryItemModel(
    id: id,
    tripId: 't1',
    title: title,
    description: description,
    location: location,
    startTime: startTime,
    dayNumber: dayNumber,
    orderIndex: orderIndex,
  );
}

bool _isPdf(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

void main() {
  group('PdfExportService.buildTripPdfBytes', () {
    test('produces non-empty PDF for minimal input', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
      );
      expect(bytes, isNotEmpty);
      expect(_isPdf(bytes), isTrue);
    });

    test('handles trip without destination', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(destination: null),
        members: [_member()],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles trip without dates', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: TripModel(
          id: 't',
          name: 'X',
          createdBy: 'u',
        ),
        members: [_member()],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles completed trip status', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(isCompleted: true),
        members: [_member()],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles trip description', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(description: 'A wonderful holiday in paradise'),
        members: [_member()],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles trip with cost', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(cost: 15000),
        members: [_member()],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles multiple members', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [
          _member(fullName: 'Alice'),
          _member(fullName: 'Bob'),
          _member(fullName: 'Charlie'),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles itinerary with startTime', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        itinerary: [
          _itinItem(
            id: 'a1',
            title: 'Morning hike',
            location: 'Mountain',
            startTime: DateTime(2024, 6, 1, 8, 0),
          ),
          _itinItem(
            id: 'a2',
            title: 'Lunch',
            startTime: DateTime(2024, 6, 1, 13, 0),
          ),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles itinerary grouped by dayNumber', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        itinerary: [
          _itinItem(id: 'a', title: 'Day1Act', dayNumber: 1),
          _itinItem(id: 'b', title: 'Day2Act', dayNumber: 2),
          _itinItem(id: 'c', title: 'Day2Act2', dayNumber: 2, orderIndex: 1),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles itinerary with missing day info (Unscheduled)', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: TripModel(id: 't', name: 'X', createdBy: 'u'),
        members: [_member()],
        itinerary: [
          _itinItem(id: 'a', title: 'Unscheduled'),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles itinerary with location and description', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        itinerary: [
          _itinItem(
            id: 'a',
            title: 'Sightseeing',
            location: 'Old Town',
            description: 'A walking tour of the city',
            startTime: DateTime(2024, 6, 1, 10, 0),
          ),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles checklists section with progress', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        checklists: [
          _checklist(name: 'Packing', items: [
            _item(id: 'i1', title: 'Passport', completed: true),
            _item(id: 'i2', title: 'Sunscreen'),
            _item(id: 'i3', title: 'Camera', completed: true),
          ]),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles all-complete checklist', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        checklists: [
          _checklist(name: 'Done List', items: [
            _item(id: 'i1', completed: true),
            _item(id: 'i2', completed: true),
          ]),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles checklist with > 6 items (truncates with "+N more")',
        () async {
      final items = List.generate(
        10,
        (i) => _item(id: 'i$i', title: 'Item $i', completed: i.isEven),
      );
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        checklists: [_checklist(name: 'Big List', items: items)],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles empty checklists list (skipped)', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        checklists: const [],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles empty itinerary list (skipped)', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        itinerary: const [],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('full trip with itinerary and checklists', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(
          name: 'Full Trip',
          description: 'Everything together',
          cost: 25000,
        ),
        members: [_member(fullName: 'A'), _member(fullName: 'B')],
        itinerary: [
          _itinItem(
            id: 'a1',
            title: 'Day 1 Activity',
            startTime: DateTime(2024, 6, 1, 9, 0),
            location: 'Beach',
          ),
        ],
        checklists: [
          _checklist(name: 'Packing', items: [
            _item(id: 'i1', title: 'Passport', completed: true),
          ]),
        ],
      );
      expect(_isPdf(bytes), isTrue);
    });

    test('handles checklist with 0 items (empty)', () async {
      final bytes = await PdfExportService.buildTripPdfBytes(
        trip: _trip(),
        members: [_member()],
        checklists: [_checklist(name: 'Empty', items: const [])],
      );
      expect(_isPdf(bytes), isTrue);
    });
  });
}
