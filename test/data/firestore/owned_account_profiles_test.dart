import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/domain/model/account_load_exception.dart';
import 'package:neom_core/domain/repository/account_profiles_reader.dart';

class _AuthUser extends Fake implements auth.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;

  _AuthUser({
    this.uid = 'UidCase',
    this.email = 'Owner@example.test',
    this.emailVerified = true,
  });
}

class _Filter {
  final Object field;
  final Map<Symbol, dynamic> arguments;
  _Filter(this.field, this.arguments);
}

class _Read {
  final String path;
  final bool isQuery;
  final GetOptions? options;
  final int? limit;
  final String? cursor;
  final List<Object> orderedFields;
  final List<_Filter> filters;

  _Read(
    this.path, {
    required this.isQuery,
    this.options,
    this.limit,
    this.cursor,
    this.orderedFields = const [],
    this.filters = const [],
  });
}

class _ControlledFirestore extends Fake implements FirebaseFirestore {
  final delegate = FakeFirebaseFirestore();
  final reads = <_Read>[];
  FutureOr<void> Function(_Read)? afterRead;
  Object? Function(_Read)? failureFor;
  int collectionGroupCalls = 0;

  List<_Read> get profileReads => reads
      .where((read) => read.isQuery && read.path.endsWith('/profiles'))
      .toList();

  Future<DocumentSnapshot<Map<String, dynamic>>> readDocument(
    DocumentReference<Map<String, dynamic>> document,
    GetOptions? options,
  ) async {
    final read = _Read(document.path, isQuery: false, options: options);
    reads.add(read);
    final failure = failureFor?.call(read);
    if (failure != null) throw failure;
    final result = await document.get(options);
    await afterRead?.call(read);
    return result;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> readQuery(
    Query<Map<String, dynamic>> query,
    _Read read,
  ) async {
    reads.add(read);
    final failure = failureFor?.call(read);
    if (failure != null) throw failure;
    final result = await query.get(read.options);
    await afterRead?.call(read);
    return result;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _QueryProxy(delegate.collection(path), this, path);

  @override
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _DocumentProxy(delegate.doc(path), this);

  @override
  Query<Map<String, dynamic>> collectionGroup(String collectionId) {
    collectionGroupCalls++;
    throw StateError('Owned profiles must never use collectionGroup');
  }
}

// SDK proxies only record reads and inject local failures. Seed writes use the
// in-memory delegate directly; no Firebase app, credentials or network is used.
// ignore: subtype_of_sealed_class
class _DocumentProxy extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final DocumentReference<Map<String, dynamic>> delegate;
  final _ControlledFirestore control;
  _DocumentProxy(this.delegate, this.control);

  @override
  String get id => delegate.id;
  @override
  String get path => delegate.path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _QueryProxy(delegate.collection(path), control, '${delegate.path}/$path');

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      control.readDocument(delegate, options);
}

// ignore: subtype_of_sealed_class
class _QueryProxy extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Query<Map<String, dynamic>> delegate;
  final _ControlledFirestore control;
  @override
  final String path;
  final String? cursor;
  final int? maxLimit;
  final List<Object> orderedFields;
  final List<_Filter> filters;

  _QueryProxy(
    this.delegate,
    this.control,
    this.path, {
    this.cursor,
    this.maxLimit,
    this.orderedFields = const [],
    this.filters = const [],
  });

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _DocumentProxy(
    (delegate as CollectionReference<Map<String, dynamic>>).doc(path),
    control,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get) {
      final options = invocation.positionalArguments.isEmpty
          ? null
          : invocation.positionalArguments.first as GetOptions?;
      // Firestore applies cursors before limits, independent of builder order.
      // The fake applies each builder sequentially, so defer limit until get.
      return control.readQuery(
        maxLimit == null ? delegate : delegate.limit(maxLimit!),
        _Read(
          path,
          isQuery: true,
          options: options,
          limit: maxLimit,
          cursor: cursor,
          orderedFields: orderedFields,
          filters: filters,
        ),
      );
    }
    if (invocation.memberName == #limit) {
      return _QueryProxy(
        delegate,
        control,
        path,
        cursor: cursor,
        maxLimit: invocation.positionalArguments.first as int,
        orderedFields: orderedFields,
        filters: filters,
      );
    }
    final Function function;
    var nextCursor = cursor;
    var nextOrder = orderedFields;
    var nextFilters = filters;
    switch (invocation.memberName) {
      case #where:
        function = delegate.where;
        nextFilters = [
          ...filters,
          _Filter(
            invocation.positionalArguments.first as Object,
            invocation.namedArguments,
          ),
        ];
      case #orderBy:
        function = delegate.orderBy;
        nextOrder = [
          ...orderedFields,
          invocation.positionalArguments.first as Object,
        ];
      case #startAfterDocument:
        function = delegate.startAfterDocument;
        nextCursor =
            (invocation.positionalArguments.first as DocumentSnapshot).id;
      default:
        return super.noSuchMethod(invocation);
    }
    final query =
        Function.apply(
              function,
              invocation.positionalArguments,
              invocation.namedArguments,
            )
            as Query<Map<String, dynamic>>;
    return _QueryProxy(
      query,
      control,
      path,
      cursor: nextCursor,
      maxLimit: maxLimit,
      orderedFields: nextOrder,
      filters: nextFilters,
    );
  }
}

void main() {
  late _ControlledFirestore firestore;
  late auth.User? session;
  late UserFirestore repository;

  setUp(() {
    firestore = _ControlledFirestore();
    session = _AuthUser();
    repository = UserFirestore(
      firestore: firestore,
      currentUser: () => session,
    );
  });

  Future<void> seedOwner({
    String id = 'UidCase',
    Map<String, dynamic> extra = const {},
  }) => firestore.delegate.doc('users/$id').set({
    'email': 'Owner@example.test',
    'currentProfileId': 'profile-000',
    ...extra,
  });

  Future<void> seedProfiles(int count, {String userId = 'UidCase'}) async {
    for (var index = 0; index < count; index++) {
      final id = 'profile-${index.toString().padLeft(3, '0')}';
      await firestore.delegate.doc('users/$userId/profiles/$id').set({
        'id': 'embedded-id-is-not-authoritative',
        'name': 'Profile $index',
      });
    }
  }

  void expectServerReads() {
    expect(firestore.reads, isNotEmpty);
    expect(
      firestore.reads.map((read) => read.options?.source),
      everyElement(Source.server),
    );
    expect(firestore.collectionGroupCalls, 0);
  }

  Future<void> expectRejected(String userId) async {
    await expectLater(
      repository.getOwnedProfiles(userId),
      throwsA(isA<AccountLoadException>()),
    );
    expect(firestore.profileReads, isEmpty);
    expect(firestore.collectionGroupCalls, 0);
  }

  test(
    'optional capability returns all profiles despite selected profile',
    () async {
      await seedOwner();
      await seedProfiles(3);
      final AccountProfilesReader reader = repository;

      final profiles = await reader.getOwnedProfiles('UidCase');

      expect(profiles.map((profile) => profile.id), [
        'profile-000',
        'profile-001',
        'profile-002',
      ]);
      expect(profiles.map((profile) => profile.name), [
        'Profile 0',
        'Profile 1',
        'Profile 2',
      ]);
      expect(
        firestore.reads.where((read) => !read.isQuery).map((read) => read.path),
        ['users/UidCase'],
      );
      expectServerReads();
    },
  );

  for (final selected in ['', 'missing-profile', 'invalid/profile']) {
    test('selected profile "$selected" does not limit owned list', () async {
      await seedOwner(extra: {'currentProfileId': selected});
      await seedProfiles(2);
      expect(await repository.getOwnedProfiles('UidCase'), hasLength(2));
      expectServerReads();
    });
  }

  test(
    'valid owner with no profiles returns an authoritative empty list',
    () async {
      await seedOwner();
      expect(await repository.getOwnedProfiles('UidCase'), isEmpty);
      expect(firestore.profileReads, hasLength(1));
      expectServerReads();
    },
  );

  test('53 profiles use ordered pages of 50 and a document cursor', () async {
    await seedOwner();
    await seedProfiles(53);

    final profiles = await repository.getOwnedProfiles('UidCase');

    expect(profiles, hasLength(53));
    expect(profiles.map((profile) => profile.id).toSet(), hasLength(53));
    expect(profiles.first.id, 'profile-000');
    expect(profiles.last.id, 'profile-052');
    expect(firestore.profileReads.map((read) => read.limit), [50, 50]);
    expect(firestore.profileReads.map((read) => read.cursor), [
      null,
      'profile-049',
    ]);
    for (final read in firestore.profileReads) {
      expect(read.path, 'users/UidCase/profiles');
      expect(read.orderedFields, [FieldPath.documentId]);
      expect(read.filters, isEmpty);
    }
    expectServerReads();
  });

  test('1000 profiles succeed after a bounded overflow check', () async {
    await seedOwner();
    await seedProfiles(1000);

    expect(await repository.getOwnedProfiles('UidCase'), hasLength(1000));
    expect(firestore.profileReads, hasLength(21));
    expect(
      firestore.profileReads.take(20).map((read) => read.limit),
      everyElement(50),
    );
    expect(firestore.profileReads.last.limit, 1);
    expect(firestore.profileReads.last.cursor, 'profile-999');
    expectServerReads();
  });

  test('1001 profiles fail instead of returning a partial list', () async {
    await seedOwner();
    await seedProfiles(1000);
    await firestore.delegate.doc('users/UidCase/profiles/zz-overflow').set({
      'name': 'Overflow profile',
    });

    await expectLater(
      repository.getOwnedProfiles('UidCase'),
      throwsA(isA<AccountLoadException>()),
    );
    expect(firestore.profileReads, hasLength(21));
    expect(firestore.profileReads.last.limit, 1);
    expect(firestore.profileReads.last.cursor, 'profile-999');
    expectServerReads();
  });

  test('second page failure discards the first page', () async {
    await seedOwner();
    await seedProfiles(51);
    firestore.failureFor = (read) =>
        read.path.endsWith('/profiles') && read.cursor == 'profile-049'
        ? FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')
        : null;

    await expectLater(
      repository.getOwnedProfiles('UidCase'),
      throwsA(isA<AccountLoadException>()),
    );
    expect(firestore.profileReads.map((read) => read.cursor), [
      null,
      'profile-049',
    ]);
    expectServerReads();
  });

  test(
    'UID ownership works without verified email or an email query',
    () async {
      session = _AuthUser(email: null, emailVerified: false);
      await seedOwner(extra: {'email': 'unrelated@example.test'});
      await seedProfiles(2);

      expect(await repository.getOwnedProfiles('UidCase'), hasLength(2));
      expect(
        firestore.reads.where((read) => read.isQuery && read.path == 'users'),
        isEmpty,
      );
      expectServerReads();
    },
  );

  test(
    'unique legacy lookup uses only exact raw auth email allowed by owner rules',
    () async {
      await seedOwner(id: 'LegacyCase');
      await seedProfiles(2, userId: 'LegacyCase');

      expect(await repository.getOwnedProfiles('LegacyCase'), hasLength(2));
      final documents = firestore.reads.where((read) => !read.isQuery);
      expect(documents.map((read) => read.path), [
        'users/LegacyCase',
        'users/UidCase',
      ]);
      final identities = firestore.reads
          .where((read) => read.isQuery && read.path == 'users')
          .toList();
      expect(identities, hasLength(1));
      expect(identities.map((read) => read.limit), everyElement(2));
      for (final identity in identities) {
        expect(identity.filters, hasLength(1));
        final filter = identity.filters.single;
        expect(filter.field, 'email');
        expect(filter.arguments[#isEqualTo], 'Owner@example.test');
        expect(filter.arguments[#whereIn], isNull);
      }
      expect(firestore.profileReads.map((read) => read.path), [
        'users/LegacyCase/profiles',
      ]);
      expectServerReads();
    },
  );

  test('legacy case variants cannot expand the authorized email query', () async {
    await seedOwner(id: 'LegacyCase', extra: {'email': 'owner@example.test'});
    await seedProfiles(2, userId: 'LegacyCase');

    await expectRejected('LegacyCase');

    final query = firestore.reads.singleWhere(
      (read) => read.isQuery && read.path == 'users',
    );
    expect(query.limit, 2);
    expect(query.filters.single.arguments[#isEqualTo], 'Owner@example.test');
    expect(query.filters.single.arguments[#whereIn], isNull);
    expectServerReads();
  });

  test('legacy duplicate email fails before reading profiles', () async {
    await seedOwner(id: 'LegacyCase');
    await seedOwner(id: 'Duplicate', extra: {'email': 'Owner@example.test'});
    await seedProfiles(2, userId: 'LegacyCase');
    await expectRejected('LegacyCase');
    expectServerReads();
  });

  test(
    'an existing UID account takes priority over a matching legacy email',
    () async {
      await seedOwner();
      await seedOwner(id: 'LegacyCase');
      await expectRejected('LegacyCase');
      expectServerReads();
    },
  );

  test('unverified legacy email cannot establish profile ownership', () async {
    session = _AuthUser(emailVerified: false);
    await seedOwner(id: 'LegacyCase');
    await expectRejected('LegacyCase');
    expectServerReads();
  });

  test('another account email cannot establish ownership', () async {
    await seedOwner(id: 'OtherOwner', extra: {'email': 'other@example.test'});
    await expectRejected('OtherOwner');
    expectServerReads();
  });

  test('missing owner fails before reading profiles', () async {
    await expectRejected('UidCase');
    expectServerReads();
  });

  test('banned owner fails before reading profiles', () async {
    await seedOwner(extra: {'isBanned': true});
    await expectRejected('UidCase');
    expectServerReads();
  });

  for (final key in ['authUid', 'firebaseUid', 'uid']) {
    test('foreign $key binding fails before reading profiles', () async {
      await seedOwner(extra: {key: 'AnotherUid'});
      await expectRejected('UidCase');
      expectServerReads();
    });
  }

  for (final change in [
    {'isBanned': true},
    {'authUid': 'AnotherUid'},
  ]) {
    test(
      'fresh legacy identity rejects changed authorization $change',
      () async {
        await seedOwner(id: 'LegacyCase');
        firestore.afterRead = (read) async {
          if (read.path == 'users/LegacyCase' && !read.isQuery) {
            await firestore.delegate.doc('users/LegacyCase').update(change);
          }
        };
        await expectRejected('LegacyCase');
        expectServerReads();
      },
    );
  }

  test('no session performs no Firestore reads', () async {
    session = null;
    await expectRejected('UidCase');
    expect(firestore.reads, isEmpty);
  });

  for (final id in [
    '',
    '.',
    '..',
    'bad/id',
    'bad\nid',
    'bad\u0000id',
    'x' * 513,
  ]) {
    test(
      'invalid owner ID is rejected before any read (${id.length} chars)',
      () async {
        await expectRejected(id);
        expect(firestore.reads, isEmpty);
      },
    );
  }

  test('owner and profile document IDs retain their exact case', () async {
    await seedOwner();
    await seedOwner(id: 'uidcase', extra: {'email': 'other@example.test'});
    await firestore.delegate.doc('users/UidCase/profiles/ProfileA').set({
      'name': 'Upper',
    });
    await firestore.delegate.doc('users/UidCase/profiles/profilea').set({
      'name': 'Lower',
    });

    final profiles = await repository.getOwnedProfiles('UidCase');

    expect(profiles.map((profile) => profile.id), ['ProfileA', 'profilea']);
    expect(firestore.profileReads.single.path, 'users/UidCase/profiles');
    firestore.reads.clear();
    await expectRejected('uidcase');
    expectServerReads();
  });

  for (final stage in ['owner', 'first profile page', 'last profile page']) {
    test('session replacement after $stage discards all results', () async {
      await seedOwner();
      await seedProfiles(51);
      firestore.afterRead = (read) {
        final atStage = switch (stage) {
          'owner' => !read.isQuery && read.path == 'users/UidCase',
          'first profile page' =>
            read.path.endsWith('/profiles') && read.cursor == null,
          _ => read.path.endsWith('/profiles') && read.cursor == 'profile-049',
        };
        if (atStage) session = _AuthUser(uid: 'OtherUid');
      };

      await expectLater(
        repository.getOwnedProfiles('UidCase'),
        throwsA(isA<AccountLoadException>()),
      );
      if (stage == 'owner') expect(firestore.profileReads, isEmpty);
      expectServerReads();
    });
  }

  test('sign-out after a profile response discards results', () async {
    await seedOwner();
    await seedProfiles(2);
    firestore.afterRead = (read) {
      if (read.path.endsWith('/profiles')) session = null;
    };
    await expectLater(
      repository.getOwnedProfiles('UidCase'),
      throwsA(isA<AccountLoadException>()),
    );
    expectServerReads();
  });

  test(
    'legacy email verification change after identity query discards results',
    () async {
      await seedOwner(id: 'LegacyCase');
      firestore.afterRead = (read) {
        if (read.isQuery && read.path == 'users') {
          session = _AuthUser(emailVerified: false);
        }
      };
      await expectRejected('LegacyCase');
      expectServerReads();
    },
  );

  for (final stage in ['owner', 'legacy identity']) {
    test('$stage read failure is explicit and never reads profiles', () async {
      await seedOwner(id: 'LegacyCase');
      firestore.failureFor = (read) {
        final fails = stage == 'owner'
            ? !read.isQuery && read.path == 'users/LegacyCase'
            : read.isQuery && read.path == 'users';
        return fails
            ? FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
              )
            : null;
      };
      await expectRejected('LegacyCase');
      expectServerReads();
    });
  }
}
