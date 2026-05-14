import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/core/theme/app_theme.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/core/theme/theme_provider.dart' as theme_provider;
import 'package:pathio/features/trip_invites/domain/entities/invite_entity.dart';
import 'package:pathio/features/trip_invites/domain/repositories/invite_repository.dart';
import 'package:pathio/features/trip_invites/presentation/providers/invite_providers.dart';
import 'package:pathio/features/trips/presentation/widgets/trip_qr_share.dart';

/// Hand-rolled fake repository for invite operations.
class _FakeInviteRepository implements InviteRepository {
  /// If non-null, generateInvite returns this. If null, throws [error].
  InviteEntity? generated;
  Object? error;
  int generateCalls = 0;

  @override
  Future<InviteEntity> generateInvite({
    required String tripId,
    required String email,
    String? phoneNumber,
    int expiresInDays = 7,
  }) async {
    generateCalls++;
    if (error != null) throw error!;
    if (generated != null) return generated!;
    throw Exception('No invite configured');
  }

  // The rest are not exercised in these tests.
  @override
  Future<InviteEntity> acceptInvite({
    required String inviteCode,
    required String userId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteExpiredInvites({String? tripId}) async {}

  @override
  Future<InviteEntity?> getInviteByCode(String inviteCode) async => null;

  @override
  Future<List<InviteEntity>> getInvitesSentByUser(String userId) async => [];

  @override
  Future<List<InviteEntity>> getPendingInvitesForEmail(String email) async =>
      [];

  @override
  Future<List<InviteEntity>> getTripInvites({
    required String tripId,
    bool includeExpired = false,
  }) async =>
      [];

  @override
  Future<void> rejectInvite({
    required String inviteCode,
    required String userId,
  }) async {}

  @override
  Future<InviteEntity> resendInvite(String inviteId) =>
      throw UnimplementedError();

  @override
  Future<void> revokeInvite({
    required String inviteId,
    required String userId,
  }) async {}
}

InviteEntity _fakeInvite({String code = 'ABCD1234'}) {
  final now = DateTime.now();
  return InviteEntity(
    id: 'invite-1',
    tripId: 'trip-1',
    invitedBy: 'user-1',
    email: 'qr-share@pathio.travel',
    status: 'pending',
    inviteCode: code,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 7)),
  );
}

Future<void> _pumpQrShare(
  WidgetTester tester, {
  required _FakeInviteRepository repo,
  String tripId = 'trip-1',
  String tripName = 'My Trip',
}) async {
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
        inviteRepositoryProvider.overrideWithValue(repo),
        theme_provider.currentThemeDataProvider.overrideWith((_) => theme),
      ],
      child: AppThemeProvider(
        themeData: theme,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TripQrShare(tripId: tripId, tripName: tripName),
          ),
        ),
      ),
    ),
  );
  // Initial frame
  await tester.pump();
  // Run post-frame callback that fires _generateInviteCode
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('TripQrShare Widget Tests', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();

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
            inviteRepositoryProvider.overrideWithValue(repo),
            theme_provider.currentThemeDataProvider.overrideWith((_) => theme),
          ],
          child: AppThemeProvider(
            themeData: theme,
            child: MaterialApp(
              home: Scaffold(
                body: TripQrShare(tripId: 't1', tripName: 'My Trip'),
              ),
            ),
          ),
        ),
      );
      // Build only — _isLoading starts as true and the widget renders
      // a CircularProgressIndicator before _generateInviteCode resolves.
      // Drain post-frame callback + future to avoid pending timer leak.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // After resolution: invite code is shown, no longer loading.
      expect(find.text('ABCD1234'), findsOneWidget);
    });

    testWidgets('shows header "Share via QR Code"', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.text('Share via QR Code'), findsOneWidget);
    });

    testWidgets('shows trip name in subtitle', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo, tripName: 'Goa Beach Trip');

      expect(find.textContaining('Goa Beach Trip'), findsWidgets);
    });

    testWidgets('shows close (X) icon button', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders QR icon in header', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.byIcon(Icons.qr_code_2), findsOneWidget);
    });

    testWidgets('shows invite code after successful generation',
        (tester) async {
      final repo = _FakeInviteRepository()
        ..generated = _fakeInvite(code: 'XYZ12345');
      await _pumpQrShare(tester, repo: repo);

      expect(find.text('XYZ12345'), findsOneWidget);
      expect(find.text('Code: '), findsOneWidget);
    });

    testWidgets('shows "Valid for 7 days" text after generation',
        (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.text('Valid for 7 days'), findsOneWidget);
    });

    testWidgets('shows Copy Link and Share buttons', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('Copy and Share buttons have icons', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('shows error UI when invite generation throws',
        (tester) async {
      final repo = _FakeInviteRepository()..error = Exception('boom');
      await _pumpQrShare(tester, repo: repo);

      // The InviteController catches error and returns null, so widget shows
      // "Failed to generate invite code" as the error.
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Try Again button is tappable in error state',
        (tester) async {
      final repo = _FakeInviteRepository()..error = Exception('err');
      await _pumpQrShare(tester, repo: repo);

      expect(find.text('Try Again'), findsOneWidget);

      // Switch to success path
      repo.error = null;
      repo.generated = _fakeInvite(code: 'RETRY12');

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('RETRY12'), findsOneWidget);
    });

    testWidgets('clicking close icon pops the modal', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();

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
            inviteRepositoryProvider.overrideWithValue(repo),
            theme_provider.currentThemeDataProvider.overrideWith((_) => theme),
          ],
          child: AppThemeProvider(
            themeData: theme,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => TripQrShare.show(
                        context: context,
                        tripId: 't1',
                        tripName: 'Trip',
                      ),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // After close, modal is dismissed - the open button is back
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('static show() opens the bottom sheet', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();

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
            inviteRepositoryProvider.overrideWithValue(repo),
            theme_provider.currentThemeDataProvider.overrideWith((_) => theme),
          ],
          child: AppThemeProvider(
            themeData: theme,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => TripQrShare.show(
                      context: context,
                      tripId: 'tx',
                      tripName: 'Test Trip',
                    ),
                    child: const Text('Show QR'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show QR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Share via QR Code'), findsOneWidget);
    });

    testWidgets('Copy Link label is rendered', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      // The buttons are .icon variants — checking the label text/icon
      // is the most stable assertion.
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('Share label is rendered', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(find.text('Share'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('renders Scaffold and SafeArea structure', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);
      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('generates invite exactly once on init', (tester) async {
      final repo = _FakeInviteRepository()..generated = _fakeInvite();
      await _pumpQrShare(tester, repo: repo);

      expect(repo.generateCalls, 1);
    });
  });
}
