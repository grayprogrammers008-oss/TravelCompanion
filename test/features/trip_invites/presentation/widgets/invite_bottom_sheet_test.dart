import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/core/theme/theme_provider.dart' as theme_provider;
import 'package:pathio/features/trip_invites/domain/entities/invite_entity.dart';
import 'package:pathio/features/trip_invites/domain/repositories/invite_repository.dart';
import 'package:pathio/features/trip_invites/presentation/providers/invite_providers.dart';
import 'package:pathio/features/trip_invites/presentation/widgets/invite_bottom_sheet.dart';

/// Hand-rolled fake repository for InviteRepository.
///
/// Mirrors the canonical pattern in invite_providers_test.dart so we can
/// exercise the controller through the real provider stack without mocks.
class _FakeInviteRepository implements InviteRepository {
  InviteEntity? generateResult;
  Object? generateError;

  final List<Map<String, dynamic>> generateCalls = [];

  @override
  Future<InviteEntity> generateInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    generateCalls.add({
      'tripId': tripId,
      'email': email,
      'phoneNumber': phoneNumber,
      'expiresInDays': expiresInDays,
    });
    if (generateError != null) throw generateError!;
    return generateResult!;
  }

  // The remaining members are not exercised by this widget but are
  // required by the interface.
  @override
  Future<InviteEntity> acceptInvite({
    required String inviteCode,
    required String userId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> rejectInvite({
    required String inviteCode,
    required String userId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> revokeInvite({
    required String inviteId,
    required String userId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<InviteEntity>> getTripInvites({
    required String tripId,
    bool includeExpired = false,
  }) async =>
      const [];

  @override
  Future<InviteEntity?> getInviteByCode(String inviteCode) async => null;

  @override
  Future<List<InviteEntity>> getInvitesSentByUser(String userId) async => const [];

  @override
  Future<List<InviteEntity>> getPendingInvitesForEmail(String email) async => const [];

  @override
  Future<InviteEntity> resendInvite(String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteExpiredInvites({String? tripId}) async {}
}

InviteEntity _makeInvite({
  String inviteCode = 'ABCDEFGH',
  String tripId = 'trip-1',
}) {
  final now = DateTime(2026, 1, 1);
  return InviteEntity(
    id: 'invite-1',
    tripId: tripId,
    invitedBy: 'inviter-1',
    email: 'guest@example.com',
    status: 'pending',
    inviteCode: inviteCode,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 7)),
  );
}

/// Pumps the [InviteBottomSheet] inside a launcher widget that opens the
/// modal sheet on tap. Returns after the sheet is fully visible.
Future<void> _pumpAndOpenSheet(
  WidgetTester tester, {
  required _FakeInviteRepository fakeRepo,
  String tripId = 'trip-1',
  String tripName = 'Bali Adventure',
}) async {
  // Use a tall viewport — the bottom sheet contains many fields and chips.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final theme = AppThemeData.getThemeData(AppThemeType.ocean);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inviteRepositoryProvider.overrideWithValue(fakeRepo),
        theme_provider.currentThemeDataProvider.overrideWith((_) => theme),
      ],
      child: AppThemeProvider(
        themeData: theme,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => InviteBottomSheet.show(
                    context: ctx,
                    tripId: tripId,
                    tripName: tripName,
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('OPEN'));
  // Pump the sheet's open animation — short pump avoids waiting on the
  // continuous AnimationController inside the sheet.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('InviteBottomSheet', () {
    late _FakeInviteRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeInviteRepository();
    });

    testWidgets('renders form fields and the Generate Invite button',
        (tester) async {
      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      // Header text
      expect(find.text('Invite Crew Member'), findsOneWidget);
      expect(
        find.textContaining('Send an invitation to join Bali Adventure'),
        findsOneWidget,
      );

      // Form fields are present.
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number (Optional)'), findsOneWidget);

      // Expiry chips render all 5 options.
      expect(find.text('1 day'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('14 days'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);

      // Generate button.
      expect(find.text('Generate Invite'), findsOneWidget);
    });

    testWidgets('email validator rejects empty and invalid input',
        (tester) async {
      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      // Tap Generate with empty email — validator runs.
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();

      expect(find.text('Please enter an email address'), findsOneWidget);
      // Repository should NOT have been called.
      expect(fakeRepo.generateCalls, isEmpty);

      // Type something invalid.
      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(fakeRepo.generateCalls, isEmpty);
    });

    testWidgets('selecting an expiry chip updates the chosen expiry',
        (tester) async {
      fakeRepo.generateResult = _makeInvite();

      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      await tester.tap(find.text('14 days'));
      await tester.pump();

      // Type a valid email then submit so we can verify the value flowed
      // through to the repository call.
      await tester.enterText(
        find.byType(TextFormField).first,
        'guest@example.com',
      );
      await tester.tap(find.text('Generate Invite'));
      // Allow async generate to settle and the success card to render.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.generateCalls, hasLength(1));
      expect(fakeRepo.generateCalls.first['expiresInDays'], 14);
    });

    testWidgets('successful generate shows the invite code success card',
        (tester) async {
      final invite = _makeInvite(inviteCode: 'CODE1234');
      fakeRepo.generateResult = invite;

      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      await tester.enterText(
        find.byType(TextFormField).first,
        'guest@example.com',
      );
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Success state: header copy changes, code is displayed, action
      // buttons appear.
      expect(find.text('Invite Created!'), findsOneWidget);
      expect(find.text('CODE1234'), findsOneWidget);
      expect(find.text('Share Invite'), findsOneWidget);
      expect(find.text('Copy Code'), findsOneWidget);
      expect(find.text('Send Another Invite'), findsOneWidget);

      // Email + phone passed through.
      expect(fakeRepo.generateCalls.single['tripId'], 'trip-1');
      expect(fakeRepo.generateCalls.single['email'], 'guest@example.com');
      expect(fakeRepo.generateCalls.single['phoneNumber'], isNull);
    });

    testWidgets('phone field forwards trimmed value to repository',
        (tester) async {
      fakeRepo.generateResult = _makeInvite();

      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'guest@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '+1 234 567 8900',
      );
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.generateCalls.single['phoneNumber'], '+1 234 567 8900');
    });

    testWidgets('error from repository surfaces in the error card',
        (tester) async {
      fakeRepo.generateError = Exception('Email already invited');

      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      await tester.enterText(
        find.byType(TextFormField).first,
        'guest@example.com',
      );
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Error message rendered (the controller strips the "Exception: " prefix).
      expect(find.text('Email already invited'), findsOneWidget);
      // Success card NOT rendered.
      expect(find.text('Invite Created!'), findsNothing);
    });

    testWidgets('"Send Another Invite" resets the form back to input mode',
        (tester) async {
      fakeRepo.generateResult = _makeInvite(inviteCode: 'ABCDEFGH');

      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      await tester.enterText(
        find.byType(TextFormField).first,
        'guest@example.com',
      );
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Invite Created!'), findsOneWidget);

      // Tap "Send Another Invite" — form should return.
      await tester.tap(find.text('Send Another Invite'));
      // Pump enough frames to flush any FadeSlideAnimation timers triggered
      // by toggling back to the input view.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Invite Crew Member'), findsOneWidget);
      expect(find.text('Generate Invite'), findsOneWidget);
      expect(find.text('Invite Created!'), findsNothing);
    });

    testWidgets('Copy Code button writes the invite code to the clipboard',
        (tester) async {
      // Stub the platform Clipboard channel so Clipboard.setData() resolves
      // without a real platform handler.
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      String? clipboardText;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      fakeRepo.generateResult = _makeInvite(inviteCode: 'COPYME12');

      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      await tester.enterText(
        find.byType(TextFormField).first,
        'guest@example.com',
      );
      await tester.tap(find.text('Generate Invite'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Copy Code'), findsOneWidget);
      await tester.tap(find.text('Copy Code'));
      await tester.pump();
      await tester.pump();

      expect(clipboardText, 'COPYME12');
      // Snackbar confirms copy.
      expect(find.textContaining('Invite code copied'), findsOneWidget);
    });

    testWidgets('static InviteBottomSheet.show opens the bottom sheet',
        (tester) async {
      // Sanity check that the convenience static helper is wired correctly.
      await _pumpAndOpenSheet(tester, fakeRepo: fakeRepo);

      // Sheet is visible: header text proves the InviteBottomSheet itself
      // (not just the host widget) is in the tree.
      expect(find.byType(InviteBottomSheet), findsOneWidget);
    });
  });
}
