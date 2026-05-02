import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/widgets/member_picker.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

import 'test_helpers.dart';

TripMemberModel _member(String id, {String? name, String? email}) {
  return TripMemberModel(
    id: 'tm-$id',
    tripId: 'trip-1',
    userId: id,
    role: 'member',
    fullName: name,
    email: email,
  );
}

void main() {
  group('MemberWithFrequency', () {
    test('frequency defaults to 0', () {
      final mwf = MemberWithFrequency(member: _member('a', name: 'A'));
      expect(mwf.frequency, 0);
    });

    test('stores explicit frequency', () {
      final mwf = MemberWithFrequency(
        member: _member('a', name: 'A'),
        frequency: 7,
      );
      expect(mwf.frequency, 7);
    });
  });

  group('MemberPickerWidget', () {
    testWidgets('renders the hint text when nothing is selected',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(
        MemberPickerWidget(
          members: [
            _member('u1', name: 'Alice', email: 'alice@example.com'),
            _member('u2', name: 'Bob', email: 'bob@example.com'),
          ],
          selectedMemberIds: const [],
          onSelectionChanged: (_) {},
          hintText: 'Pick someone',
          labelText: 'Members',
        ),
      ));
      await tester.pump();

      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Pick someone'), findsOneWidget);
    });

    testWidgets('shows selected count when members are selected',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(
        MemberPickerWidget(
          members: [
            _member('u1', name: 'Alice'),
            _member('u2', name: 'Bob'),
            _member('u3', name: 'Carol'),
          ],
          selectedMemberIds: const ['u1', 'u3'],
          onSelectionChanged: (_) {},
        ),
      ));
      await tester.pump();
      expect(find.text('2 of 3 members selected'), findsOneWidget);
    });

    testWidgets('renders +N indicator when more than 4 are selected',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final members = List.generate(
        7,
        (i) => _member('u$i', name: 'User $i'),
      );

      await tester.pumpWidget(wrapWithTheme(
        MemberPickerWidget(
          members: members,
          selectedMemberIds: members.map((m) => m.userId).toList(),
          onSelectionChanged: (_) {},
        ),
      ));
      await tester.pump();
      expect(find.text('+3'), findsOneWidget);
    });
  });
}
