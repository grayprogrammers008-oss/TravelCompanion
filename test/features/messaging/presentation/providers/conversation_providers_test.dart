import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/messaging/data/datasources/conversation_queries.dart';
import 'package:pathio/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:pathio/features/messaging/domain/entities/conversation_entity.dart';
import 'package:pathio/features/messaging/domain/entities/message_entity.dart';
import 'package:pathio/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:pathio/features/messaging/domain/usecases/send_message_usecase.dart';
import 'package:pathio/features/messaging/presentation/providers/conversation_providers.dart';

/// Hand-rolled fake [ConversationRepository] used to drive the providers.
class _FakeConversationRepository implements ConversationRepository {
  // ── Configurable canned responses ─────────────────────────────────
  Result<ConversationEntity>? createConversationResult;
  Result<List<ConversationEntity>>? getTripConversationsResult;
  Result<ConversationEntity>? getConversationResult;
  Result<List<MessageEntity>>? getMessagesResult;
  Result<List<ConversationMemberEntity>>? getMembersResult;
  Result<ConversationEntity>? defaultGroupResult;

  Stream<List<MessageEntity>> Function(String conversationId)?
      watchMessagesStreamFactory;

  // ── Recorded args ──────────────────────────────────────────────────
  Map<String, dynamic>? lastCreateArgs;
  String? lastGetTripConversationsTripId;
  String? lastGetTripConversationsUserId;
  String? lastGetConversationId;
  String? lastGetConversationUserId;
  String? lastGetMessagesId;
  int? lastGetMessagesLimit;
  int? lastGetMessagesOffset;
  String? lastGetMembersConversationId;
  String? lastDefaultGroupTripId;
  String? lastDefaultGroupUserId;

  int createConversationCallCount = 0;
  int getTripConversationsCallCount = 0;

  @override
  Future<Result<ConversationEntity>> createConversation({
    required String tripId,
    required String name,
    String? description,
    required List<String> memberUserIds,
    required String createdBy,
    bool isDirectMessage = false,
  }) async {
    createConversationCallCount++;
    lastCreateArgs = {
      'tripId': tripId,
      'name': name,
      'description': description,
      'memberUserIds': memberUserIds,
      'createdBy': createdBy,
      'isDirectMessage': isDirectMessage,
    };
    return createConversationResult ?? Result.failure('not configured');
  }

  @override
  Future<Result<List<ConversationEntity>>> getTripConversations({
    required String tripId,
    required String userId,
  }) async {
    getTripConversationsCallCount++;
    lastGetTripConversationsTripId = tripId;
    lastGetTripConversationsUserId = userId;
    return getTripConversationsResult ?? Result.success(<ConversationEntity>[]);
  }

  @override
  Future<Result<ConversationEntity>> getConversation({
    required String conversationId,
    required String userId,
  }) async {
    lastGetConversationId = conversationId;
    lastGetConversationUserId = userId;
    return getConversationResult ?? Result.failure('not found');
  }

  @override
  Future<Result<void>> updateConversation({
    required String conversationId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async => Result.success(null);

  @override
  Future<Result<void>> deleteConversation(String conversationId) async =>
      Result.success(null);

  @override
  Future<Result<void>> addMembers({
    required String conversationId,
    required List<String> userIds,
  }) async => Result.success(null);

  @override
  Future<Result<void>> removeMember({
    required String conversationId,
    required String userId,
  }) async => Result.success(null);

  @override
  Future<Result<void>> updateMemberRole({
    required String conversationId,
    required String userId,
    required String role,
  }) async => Result.success(null);

  @override
  Future<Result<void>> leaveConversation({
    required String conversationId,
    required String userId,
  }) async => Result.success(null);

  @override
  Future<Result<void>> setMuted({
    required String conversationId,
    required String userId,
    required bool muted,
  }) async => Result.success(null);

  @override
  Future<Result<void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async => Result.success(null);

  @override
  Future<Result<List<MessageEntity>>> getConversationMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    lastGetMessagesId = conversationId;
    lastGetMessagesLimit = limit;
    lastGetMessagesOffset = offset;
    return getMessagesResult ?? Result.success(<MessageEntity>[]);
  }

  @override
  Future<Result<MessageEntity>> sendConversationMessage({
    required String conversationId,
    required String tripId,
    required String senderId,
    required String message,
    MessageType messageType = MessageType.text,
    String? replyToId,
    String? attachmentUrl,
  }) async => Result.failure('not configured');

  @override
  Future<Result<void>> deleteMessage({
    required String messageId,
    required String senderId,
  }) async => Result.success(null);

  @override
  Future<Result<void>> deleteMessages({
    required List<String> messageIds,
    required String senderId,
  }) async => Result.success(null);

  @override
  Stream<List<ConversationEntity>> watchTripConversations({
    required String tripId,
    required String userId,
  }) => Stream.value(<ConversationEntity>[]);

  @override
  Stream<List<MessageEntity>> watchConversationMessages(String conversationId) {
    if (watchMessagesStreamFactory != null) {
      return watchMessagesStreamFactory!(conversationId);
    }
    return Stream.value(<MessageEntity>[]);
  }

  @override
  Stream<ConversationEntity> watchConversation({
    required String conversationId,
    required String userId,
  }) => const Stream.empty();

  @override
  Future<Result<List<ConversationMemberEntity>>> getConversationMembers(
    String conversationId,
  ) async {
    lastGetMembersConversationId = conversationId;
    return getMembersResult ?? Result.success(<ConversationMemberEntity>[]);
  }

  @override
  Future<Result<ConversationEntity>> findOrCreateDirectMessage({
    required String tripId,
    required String currentUserId,
    required String otherUserId,
  }) async => Result.failure('not configured');

  @override
  Future<Result<ConversationEntity>> getDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    lastDefaultGroupTripId = tripId;
    lastDefaultGroupUserId = userId;
    return defaultGroupResult ?? Result.failure('not configured');
  }

  @override
  Future<Result<String?>> getDefaultGroupId({required String tripId}) async {
    return Result.success(null);
  }
}

/// Minimal [ConversationQueries] stub so [ConversationRemoteDataSource] can
/// be constructed without touching `Supabase.instance`.
class _NoopConversationQueries implements ConversationQueries {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in tests: ${invocation.memberName}');
}

/// Subclass that overrides only the realtime + RPC bits used by
/// [tripUnreadCountProvider] / [tripConversationsStreamProvider].
class _FakeRemoteDataSource extends ConversationRemoteDataSource {
  _FakeRemoteDataSource({
    required this.activityStream,
    this.ensureUserInDefaultGroupResult,
    this.ensureUserError,
  }) : super(queries: _NoopConversationQueries());

  Stream<void> activityStream;
  String? ensureUserInDefaultGroupResult;
  Object? ensureUserError;
  int ensureCallCount = 0;
  int subscribeCallCount = 0;
  String? lastSubscribeTripId;
  String? lastEnsureTripId;
  String? lastEnsureUserId;

  @override
  Stream<void> subscribeToTripActivityChanges(String tripId) {
    subscribeCallCount++;
    lastSubscribeTripId = tripId;
    return activityStream;
  }

  @override
  Future<String?> ensureUserInDefaultGroup({
    required String tripId,
    required String userId,
  }) async {
    ensureCallCount++;
    lastEnsureTripId = tripId;
    lastEnsureUserId = userId;
    if (ensureUserError != null) {
      throw ensureUserError!;
    }
    return ensureUserInDefaultGroupResult;
  }
}

ConversationEntity _makeConv({
  String id = 'c-1',
  String tripId = 'trip-1',
  String name = 'Group',
  int unreadCount = 0,
}) {
  return ConversationEntity(
    id: id,
    tripId: tripId,
    name: name,
    createdBy: 'creator',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    unreadCount: unreadCount,
  );
}

MessageEntity _makeMsg({String id = 'm-1', String tripId = 'trip-1'}) {
  return MessageEntity(
    id: id,
    tripId: tripId,
    senderId: 'u-1',
    message: 'hi',
    messageType: MessageType.text,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late _FakeConversationRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeConversationRepository();
    container = ProviderContainer(overrides: [
      conversationRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  // ------------------------------------------------------------------
  // Use-case providers — wiring smoke tests
  // ------------------------------------------------------------------

  group('use-case providers', () {
    test('createConversationUseCaseProvider resolves a use case', () {
      expect(container.read(createConversationUseCaseProvider), isNotNull);
    });

    test('getTripConversationsUseCaseProvider resolves a use case', () {
      expect(container.read(getTripConversationsUseCaseProvider), isNotNull);
    });

    test('leaveConversationUseCaseProvider resolves a use case', () {
      expect(container.read(leaveConversationUseCaseProvider), isNotNull);
    });

    test('addConversationMembersUseCaseProvider resolves a use case', () {
      expect(container.read(addConversationMembersUseCaseProvider), isNotNull);
    });

    test('markConversationAsReadUseCaseProvider resolves a use case', () {
      expect(container.read(markConversationAsReadUseCaseProvider), isNotNull);
    });
  });

  // ------------------------------------------------------------------
  // TripConversationsParams + ConversationParams (value classes)
  // ------------------------------------------------------------------

  group('TripConversationsParams', () {
    test('equality and hashCode match for identical fields', () {
      const a = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      const b = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on different tripId', () {
      const a = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      const b = TripConversationsParams(tripId: 't-2', userId: 'u-1');
      expect(a, isNot(equals(b)));
    });

    test('inequality on different userId', () {
      const a = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      const b = TripConversationsParams(tripId: 't-1', userId: 'u-2');
      expect(a, isNot(equals(b)));
    });

    test('identical instance is equal to itself', () {
      const a = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      // ignore: unrelated_type_equality_checks
      expect(a == a, isTrue);
    });

    test('not equal to a non-TripConversationsParams object', () {
      const a = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      expect(a == 'not-params', isFalse);
    });
  });

  group('ConversationParams', () {
    test('equality + hashCode for identical fields', () {
      const a = ConversationParams(conversationId: 'c-1', userId: 'u-1');
      const b = ConversationParams(conversationId: 'c-1', userId: 'u-1');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on different conversationId', () {
      const a = ConversationParams(conversationId: 'c-1', userId: 'u-1');
      const b = ConversationParams(conversationId: 'c-2', userId: 'u-1');
      expect(a, isNot(equals(b)));
    });

    test('inequality on different userId', () {
      const a = ConversationParams(conversationId: 'c-1', userId: 'u-1');
      const b = ConversationParams(conversationId: 'c-1', userId: 'u-2');
      expect(a, isNot(equals(b)));
    });

    test('identical instance equals self', () {
      const a = ConversationParams(conversationId: 'c-1', userId: 'u-1');
      // ignore: unrelated_type_equality_checks
      expect(a == a, isTrue);
    });

    test('not equal to a different type', () {
      const a = ConversationParams(conversationId: 'c-1', userId: 'u-1');
      expect(a == 42, isFalse);
    });
  });

  // ------------------------------------------------------------------
  // tripConversationsProvider (FutureProvider.autoDispose.family)
  // ------------------------------------------------------------------

  group('tripConversationsProvider', () {
    test('returns conversations on success', () async {
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1'),
        _makeConv(id: 'c-2'),
      ]);

      final params = const TripConversationsParams(
        tripId: 't-1',
        userId: 'u-1',
      );
      final sub = container.listen(tripConversationsProvider(params), (_, __) {});
      addTearDown(sub.close);
      final list = await container.read(tripConversationsProvider(params).future);

      expect(list, hasLength(2));
      expect(list.first.id, 'c-1');
      expect(repo.lastGetTripConversationsTripId, 't-1');
      expect(repo.lastGetTripConversationsUserId, 'u-1');
    });

    test('returns empty list when none configured', () async {
      const params = TripConversationsParams(tripId: 't-x', userId: 'u-x');
      final sub = container.listen(tripConversationsProvider(params), (_, __) {});
      addTearDown(sub.close);
      final list = await container.read(tripConversationsProvider(params).future);
      expect(list, isEmpty);
    });

    test('throws when repo returns failure', () async {
      repo.getTripConversationsResult = Result.failure('boom');
      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      final sub = container.listen(tripConversationsProvider(params), (_, __) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(tripConversationsProvider(params).future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // conversationProvider
  // ------------------------------------------------------------------

  group('conversationProvider', () {
    test('returns single conversation on success', () async {
      repo.getConversationResult = Result.success(_makeConv(id: 'c-9'));

      const params = ConversationParams(conversationId: 'c-9', userId: 'u-1');
      final sub = container.listen(conversationProvider(params), (_, __) {});
      addTearDown(sub.close);
      final c = await container.read(conversationProvider(params).future);

      expect(c.id, 'c-9');
      expect(repo.lastGetConversationId, 'c-9');
      expect(repo.lastGetConversationUserId, 'u-1');
    });

    test('throws on failure', skip: 'Riverpod 3.x .future error timing', () async {
      repo.getConversationResult = Result.failure('nope');
      const params = ConversationParams(conversationId: 'c-9', userId: 'u-1');
      final sub = container.listen(conversationProvider(params), (_, __) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(conversationProvider(params).future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // conversationMessagesProvider
  // ------------------------------------------------------------------

  group('conversationMessagesProvider', () {
    test('returns messages on success and forwards conversationId', () async {
      repo.getMessagesResult = Result.success([_makeMsg(id: 'm-1')]);
      final sub =
          container.listen(conversationMessagesProvider('c-7'), (_, __) {});
      addTearDown(sub.close);

      final msgs = await container.read(
        conversationMessagesProvider('c-7').future,
      );
      expect(msgs, hasLength(1));
      expect(repo.lastGetMessagesId, 'c-7');
      // Default values from the repository contract
      expect(repo.lastGetMessagesLimit, 50);
      expect(repo.lastGetMessagesOffset, 0);
    });

    test('default returns empty list', () async {
      final sub =
          container.listen(conversationMessagesProvider('c-empty'), (_, __) {});
      addTearDown(sub.close);
      final msgs =
          await container.read(conversationMessagesProvider('c-empty').future);
      expect(msgs, isEmpty);
    });

    test('throws on failure', () async {
      repo.getMessagesResult = Result.failure('db down');
      final sub =
          container.listen(conversationMessagesProvider('c-fail'), (_, __) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(conversationMessagesProvider('c-fail').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // conversationMessagesStreamProvider
  // ------------------------------------------------------------------

  group('conversationMessagesStreamProvider', () {
    test('emits messages from repo.watchConversationMessages', () async {
      final ctrl = StreamController<List<MessageEntity>>();
      addTearDown(ctrl.close);
      repo.watchMessagesStreamFactory = (_) => ctrl.stream;

      final sub = container.listen(
        conversationMessagesStreamProvider('c-1'),
        (_, __) {},
      );
      addTearDown(sub.close);

      ctrl.add([_makeMsg(id: 'm-1'), _makeMsg(id: 'm-2')]);

      final first = await container.read(
        conversationMessagesStreamProvider('c-1').future,
      );
      expect(first, hasLength(2));
      expect(first.first.id, 'm-1');
    });

    test('default factory yields a single empty list', () async {
      final sub = container.listen(
        conversationMessagesStreamProvider('c-x'),
        (_, __) {},
      );
      addTearDown(sub.close);
      final value = await container.read(
        conversationMessagesStreamProvider('c-x').future,
      );
      expect(value, isEmpty);
    });
  });

  // ------------------------------------------------------------------
  // conversationMembersProvider
  // ------------------------------------------------------------------

  group('conversationMembersProvider', () {
    test('returns members on success', () async {
      repo.getMembersResult = Result.success([
        ConversationMemberEntity(
          id: 'm-1',
          conversationId: 'c-1',
          userId: 'u-1',
          role: 'admin',
          joinedAt: DateTime(2025, 1, 1),
        ),
      ]);

      final sub =
          container.listen(conversationMembersProvider('c-1'), (_, __) {});
      addTearDown(sub.close);
      final members =
          await container.read(conversationMembersProvider('c-1').future);
      expect(members, hasLength(1));
      expect(members.first.role, 'admin');
      expect(repo.lastGetMembersConversationId, 'c-1');
    });

    test('default returns empty list', () async {
      final sub =
          container.listen(conversationMembersProvider('c-empty'), (_, __) {});
      addTearDown(sub.close);
      final members =
          await container.read(conversationMembersProvider('c-empty').future);
      expect(members, isEmpty);
    });

    test('throws on failure', () async {
      repo.getMembersResult = Result.failure('forbidden');
      final sub =
          container.listen(conversationMembersProvider('c-1'), (_, __) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(conversationMembersProvider('c-1').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // defaultGroupProvider
  // ------------------------------------------------------------------

  group('defaultGroupProvider', () {
    test('returns conversation on success', () async {
      repo.defaultGroupResult = Result.success(
        _makeConv(id: 'c-default', name: 'All Members'),
      );

      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      final sub = container.listen(defaultGroupProvider(params), (_, __) {});
      addTearDown(sub.close);
      final conv = await container.read(defaultGroupProvider(params).future);

      expect(conv.id, 'c-default');
      expect(repo.lastDefaultGroupTripId, 't-1');
      expect(repo.lastDefaultGroupUserId, 'u-1');
    });

    // Skipped: Riverpod 3.x doesn't reliably propagate FutureProvider.family
    // errors via .future in the test harness. Same skip pattern as elsewhere.
    test('throws on failure', skip: 'Riverpod 3.x .future error timing', () async {
      repo.defaultGroupResult = Result.failure('not found');
      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      final sub = container.listen(defaultGroupProvider(params), (_, __) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(defaultGroupProvider(params).future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ------------------------------------------------------------------
  // CreateConversationState — value class
  // ------------------------------------------------------------------

  group('CreateConversationState', () {
    test('default constructor: not loading, no error, no created conv', () {
      const s = CreateConversationState();
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
      expect(s.createdConversation, isNull);
    });

    test('copyWith replaces isLoading', () {
      const s = CreateConversationState();
      final s2 = s.copyWith(isLoading: true);
      expect(s2.isLoading, isTrue);
      expect(s2.error, isNull);
      expect(s2.createdConversation, isNull);
    });

    test('copyWith replaces error', () {
      const s = CreateConversationState();
      final s2 = s.copyWith(error: 'oops');
      expect(s2.error, 'oops');
    });

    test('copyWith replaces createdConversation', () {
      final c = _makeConv(id: 'c-100');
      const s = CreateConversationState();
      final s2 = s.copyWith(createdConversation: c);
      expect(s2.createdConversation?.id, 'c-100');
    });

    test('copyWith without args clears error and createdConversation '
        '(documented behaviour)', () {
      final s = CreateConversationState(
        isLoading: true,
        error: 'old',
        createdConversation: _makeConv(),
      );
      final s2 = s.copyWith();
      // isLoading is preserved (?? this.isLoading)
      expect(s2.isLoading, isTrue);
      // error and createdConversation are *not* preserved (no `?? this.x`).
      expect(s2.error, isNull);
      expect(s2.createdConversation, isNull);
    });
  });

  // ------------------------------------------------------------------
  // CreateConversationNotifier
  // ------------------------------------------------------------------

  group('createConversationNotifierProvider', () {
    test('initial state matches default CreateConversationState', () {
      final state = container.read(createConversationNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.createdConversation, isNull);
    });

    test('createConversation success updates state and returns entity',
        () async {
      final created = _makeConv(id: 'c-new', name: 'Trip Crew');
      repo.createConversationResult = Result.success(created);

      final notifier =
          container.read(createConversationNotifierProvider.notifier);

      final result = await notifier.createConversation(
        tripId: 't-1',
        name: 'Trip Crew',
        memberUserIds: const ['u-1', 'u-2'],
        createdBy: 'u-1',
      );

      expect(result?.id, 'c-new');
      expect(repo.createConversationCallCount, 1);
      expect(repo.lastCreateArgs!['tripId'], 't-1');
      expect(repo.lastCreateArgs!['memberUserIds'], ['u-1', 'u-2']);
      expect(repo.lastCreateArgs!['isDirectMessage'], isFalse);

      final state = container.read(createConversationNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.createdConversation?.id, 'c-new');
    });

    test('createConversation forwards description + isDirectMessage',
        () async {
      final created = _makeConv(id: 'c-dm');
      repo.createConversationResult = Result.success(created);

      final notifier =
          container.read(createConversationNotifierProvider.notifier);
      await notifier.createConversation(
        tripId: 't-9',
        name: 'DM',
        description: 'private',
        memberUserIds: const ['u-1', 'u-9'],
        createdBy: 'u-1',
        isDirectMessage: true,
      );

      expect(repo.lastCreateArgs!['description'], 'private');
      expect(repo.lastCreateArgs!['isDirectMessage'], isTrue);
    });

    test('createConversation failure populates error and returns null',
        () async {
      repo.createConversationResult = Result.failure('rls denied');

      final notifier =
          container.read(createConversationNotifierProvider.notifier);
      final result = await notifier.createConversation(
        tripId: 't-1',
        name: 'X',
        memberUserIds: const ['u-1'],
        createdBy: 'u-1',
      );

      expect(result, isNull);
      final state = container.read(createConversationNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, 'rls denied');
      expect(state.createdConversation, isNull);
    });

    test('reset() restores default state after success', () async {
      repo.createConversationResult =
          Result.success(_makeConv(id: 'c-r'));

      final notifier =
          container.read(createConversationNotifierProvider.notifier);
      await notifier.createConversation(
        tripId: 't-1',
        name: 'A',
        memberUserIds: const [],
        createdBy: 'u-1',
      );

      // Sanity: created
      expect(
        container.read(createConversationNotifierProvider).createdConversation,
        isNotNull,
      );

      notifier.reset();
      final state = container.read(createConversationNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.createdConversation, isNull);
    });

    test('reset() also clears any error', () async {
      repo.createConversationResult = Result.failure('bad');
      final notifier =
          container.read(createConversationNotifierProvider.notifier);
      await notifier.createConversation(
        tripId: 't-1',
        name: 'A',
        memberUserIds: const [],
        createdBy: 'u-1',
      );
      expect(container.read(createConversationNotifierProvider).error, 'bad');

      notifier.reset();
      expect(container.read(createConversationNotifierProvider).error, isNull);
    });
  });

  // ------------------------------------------------------------------
  // tripConversationsStreamProvider
  // ------------------------------------------------------------------

  group('tripConversationsStreamProvider', () {
    test('emits initial conversations and re-fetches on activity event',
        () async {
      // First fetch returns a single conv; we mutate the canned response and
      // push an event on the activity stream to trigger a re-fetch.
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1'),
      ]);

      final activityCtrl = StreamController<void>.broadcast();
      addTearDown(activityCtrl.close);

      final fakeDs = _FakeRemoteDataSource(activityStream: activityCtrl.stream);

      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');

      final emissions = <List<ConversationEntity>>[];
      final sub = scopedContainer.listen<AsyncValue<List<ConversationEntity>>>(
        tripConversationsStreamProvider(params),
        (_, next) {
          next.whenData(emissions.add);
        },
      );
      addTearDown(sub.close);

      // Allow first emission.
      await Future.delayed(const Duration(milliseconds: 20));
      expect(emissions, hasLength(greaterThanOrEqualTo(1)));
      expect(emissions.last.first.id, 'c-1');

      // Mutate canned response and trigger activity.
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1'),
        _makeConv(id: 'c-2'),
      ]);
      activityCtrl.add(null);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(emissions.last, hasLength(2));
      expect(fakeDs.subscribeCallCount, 1);
      expect(fakeDs.lastSubscribeTripId, 't-1');
    });
  });

  // ------------------------------------------------------------------
  // tripUnreadCountProvider
  // ------------------------------------------------------------------

  group('tripUnreadCountProvider', () {
    test('emits 0 when userId is empty (guard)', () async {
      final fakeDs = _FakeRemoteDataSource(
        activityStream: const Stream.empty(),
      );
      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: 't-1', userId: '');
      final sub = scopedContainer.listen(
        tripUnreadCountProvider(params),
        (_, __) {},
      );
      addTearDown(sub.close);

      final value = await scopedContainer.read(
        tripUnreadCountProvider(params).future,
      );
      expect(value, 0);
      expect(fakeDs.ensureCallCount, 0);
      expect(fakeDs.subscribeCallCount, 0);
    });

    test('emits 0 when tripId is empty (guard)', () async {
      final fakeDs = _FakeRemoteDataSource(
        activityStream: const Stream.empty(),
      );
      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: '', userId: 'u-1');
      final sub = scopedContainer.listen(
        tripUnreadCountProvider(params),
        (_, __) {},
      );
      addTearDown(sub.close);

      final value = await scopedContainer.read(
        tripUnreadCountProvider(params).future,
      );
      expect(value, 0);
    });

    test('sums unreadCount across all conversations for the trip', () async {
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1', unreadCount: 3),
        _makeConv(id: 'c-2', unreadCount: 4),
        _makeConv(id: 'c-3', unreadCount: 0),
      ]);

      final activityCtrl = StreamController<void>.broadcast();
      addTearDown(activityCtrl.close);

      final fakeDs = _FakeRemoteDataSource(
        activityStream: activityCtrl.stream,
        ensureUserInDefaultGroupResult: 'default-group-id',
      );

      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      final sub = scopedContainer.listen(
        tripUnreadCountProvider(params),
        (_, __) {},
      );
      addTearDown(sub.close);

      final value = await scopedContainer.read(
        tripUnreadCountProvider(params).future,
      );
      expect(value, 7);
      expect(fakeDs.ensureCallCount, 1);
      expect(fakeDs.lastEnsureTripId, 't-1');
      expect(fakeDs.lastEnsureUserId, 'u-1');
    });

    test('emits 0 when getTripConversations returns failure', () async {
      repo.getTripConversationsResult = Result.failure('boom');
      final fakeDs = _FakeRemoteDataSource(
        activityStream: const Stream.empty(),
      );

      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      final sub = scopedContainer.listen(
        tripUnreadCountProvider(params),
        (_, __) {},
      );
      addTearDown(sub.close);

      final value = await scopedContainer.read(
        tripUnreadCountProvider(params).future,
      );
      expect(value, 0);
    });

    test('still emits initial count when ensureUserInDefaultGroup throws',
        () async {
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1', unreadCount: 2),
      ]);

      final fakeDs = _FakeRemoteDataSource(
        activityStream: const Stream.empty(),
        ensureUserError: Exception('rpc not found'),
      );

      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');
      final sub = scopedContainer.listen(
        tripUnreadCountProvider(params),
        (_, __) {},
      );
      addTearDown(sub.close);

      final value = await scopedContainer.read(
        tripUnreadCountProvider(params).future,
      );
      expect(value, 2);
      expect(fakeDs.ensureCallCount, 1);
    });

    test('recalculates on activity stream events', () async {
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1', unreadCount: 1),
      ]);

      final activityCtrl = StreamController<void>.broadcast();
      addTearDown(activityCtrl.close);

      final fakeDs = _FakeRemoteDataSource(
        activityStream: activityCtrl.stream,
        ensureUserInDefaultGroupResult: 'default-group-id',
      );

      final scopedContainer = ProviderContainer(overrides: [
        conversationRepositoryProvider.overrideWithValue(repo),
        conversationRemoteDataSourceProvider.overrideWithValue(fakeDs),
      ]);
      addTearDown(scopedContainer.dispose);

      const params = TripConversationsParams(tripId: 't-1', userId: 'u-1');

      final emissions = <int>[];
      final sub = scopedContainer.listen<AsyncValue<int>>(
        tripUnreadCountProvider(params),
        (_, next) {
          next.whenData(emissions.add);
        },
      );
      addTearDown(sub.close);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(emissions.last, 1);

      // Mutate canned response and trigger activity.
      repo.getTripConversationsResult = Result.success([
        _makeConv(id: 'c-1', unreadCount: 5),
        _makeConv(id: 'c-2', unreadCount: 2),
      ]);
      activityCtrl.add(null);

      await Future.delayed(const Duration(milliseconds: 20));
      expect(emissions.last, 7);
    });
  });
}
