import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/facility.dart';
import 'package:neom_core/domain/model/genre.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/domain/model/place.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:neom_core/utils/enums/facilitator_type.dart';
import 'package:neom_core/utils/enums/place_type.dart';
import 'package:sint/sint.dart';

class _LoginService extends Fake implements LoginService {
  final statuses = <AuthStatus>[];

  @override
  void setAuthStatus(AuthStatus status) => statuses.add(status);

  @override
  AuthStatus getAuthStatus() => statuses.lastOrNull ?? AuthStatus.waiting;
}

class _UnavailableCacheUser extends Fake implements UserService {
  @override
  AppUser get user => throw StateError('Profile cache is unavailable');
}

class _CreationRepository extends UserFirestore {
  _CreationRepository() : super(firestore: FakeFirebaseFirestore());

  Completer<void>? gate;
  Object? failure;
  bool committed = false;

  @override
  Future<AppUser?> getByEmail(
    String email, {
    bool getProfile = false,
    bool getProfileFeatures = false,
    bool throwOnError = false,
  }) async => null;

  @override
  Future<String> insertWithProfile(AppUser user, AppProfile profile) async {
    await gate?.future;
    if (failure != null) throw failure!;
    committed = true;
    profile.id = 'committed-profile';
    user.currentProfileId = profile.id;
    user.profiles = [profile];
    return profile.id;
  }
}

class _Metadata extends Fake implements auth.UserMetadata {
  @override
  DateTime? get lastSignInTime => null;
}

class _Provider extends Fake implements auth.UserInfo {
  _Provider(this.uid);

  @override
  final String uid;
}

class _AuthUser extends Fake implements auth.User {
  _AuthUser({this.providers = const []});

  final List<auth.UserInfo> providers;

  @override
  String get uid => 'MiXeD-Firebase-UID';
  @override
  String? get email => 'reader@example.test';
  @override
  String? get displayName => 'New reader';
  @override
  String? get phoneNumber => null;
  @override
  String? get photoURL => null;
  @override
  auth.UserMetadata get metadata => _Metadata();
  @override
  List<auth.UserInfo> get providerData => providers;
}

/// fake_cloud_firestore's default transaction does not await writes or model
/// commit failures. This harness captures queued writes and provides a commit
/// barrier; real atomic rollback/security behavior is tested by the emulator.
class _CommitFirestore extends FakeFirebaseFirestore {
  _CommitFirestore({super.securityRules});

  Completer<void>? commitBarrier;
  Object? commitFailure;
  final queuedPaths = <String>[];
  int transactionCount = 0;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    transactionCount++;
    final transaction = _Transaction(queuedPaths);
    final result = await transactionHandler(transaction);
    await commitBarrier?.future;
    if (commitFailure != null) throw commitFailure!;
    for (final write in transaction.writes) {
      await write();
    }
    return result;
  }

  @override
  CollectionReference<Map<String, dynamic>> collectionGroup(String path) =>
      throw StateError('Account creation must not query all profiles');
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.paths);

  final List<String> paths;
  final writes = <Future<void> Function()>[];

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) {
    if (writes.isNotEmpty) throw StateError('Reads must precede writes');
    return reference.get();
  }

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    paths.add(reference.path);
    writes.add(() => reference.set(data, options));
    return this;
  }
}

const _ownerRules = '''
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /profiles/{profileId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
''';

void main() {
  late _CommitFirestore firestore;
  late UserFirestore repository;

  setUp(() {
    Sint.reset();
    AppConfig.instance.appInUse = AppInUse.e;
    AppConfig.instance.isGuestMode = true;
    firestore = _CommitFirestore();
    repository = UserFirestore(firestore: firestore);
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.appInUse = AppInUse.o;
    AppConfig.instance.isGuestMode = true;
  });

  for (final providers in <List<auth.UserInfo>>[
    [],
    [_Provider('reader@example.test')],
    [_Provider('google-provider-id'), _Provider('other-provider-id')],
  ]) {
    test(
      'Firebase draft uses canonical UID with ${providers.length} providers',
      () {
        final controller = UserController(userFirestore: repository);
        controller.getUserFromFirebase(_AuthUser(providers: providers));
        expect(controller.user.id, 'MiXeD-Firebase-UID');
        expect(controller.user.email, 'reader@example.test');
      },
    );
  }

  test(
    'plain insert preserves mixed-case UID and does not write lowercase twin',
    () async {
      expect(
        await repository.insert(AppUser(id: 'MiXeD-Firebase-UID')),
        isTrue,
      );
      expect(
        (await firestore.doc('users/MiXeD-Firebase-UID').get()).exists,
        isTrue,
      );
      expect(
        (await firestore.doc('users/mixed-firebase-uid').get()).exists,
        isFalse,
      );
    },
  );

  test(
    'new account owns its linked initial profile under the exact UID',
    () async {
      firestore = _CommitFirestore(securityRules: _ownerRules);
      firestore.authObject.add({'uid': 'MiXeD-Firebase-UID'});
      repository = UserFirestore(firestore: firestore);
      final user = AppUser(
        id: 'MiXeD-Firebase-UID',
        email: 'reader@example.test',
      );
      final profile = AppProfile(name: 'New reader');

      final id = await repository.insertWithProfile(user, profile);

      expect(id, isNotEmpty);
      expect(firestore.transactionCount, 1);
      expect(firestore.queuedPaths, [
        'users/${user.id}',
        'users/${user.id}/profiles/$id',
      ]);
      final account = (await firestore.doc('users/${user.id}').get()).data()!;
      final savedProfile =
          (await firestore.doc('users/${user.id}/profiles/$id').get()).data()!;
      expect(account['currentProfileId'], id);
      expect(savedProfile['id'], id);
      expect(savedProfile['name'], 'New reader');
      expect(savedProfile['slug'], AppProfile.generateSlug('New reader'));
      expect(user.currentProfileId, id);
      expect(user.profiles.single, same(profile));
      expect(profile.id, id);
    },
  );

  test(
    'feature documents are committed on owner paths with account and profile',
    () async {
      final profile = AppProfile(name: 'Musician')
        ..instruments = {'guitar': Instrument(name: 'guitar', isMain: true)}
        ..genres = {'rock': Genre(name: 'rock', isFavorite: true)}
        ..places = {'cafe': Place(type: PlaceType.cafe, name: 'My cafe')}
        ..facilities = {
          'publisher': Facility(type: FacilityType.publisher, name: 'My press'),
        };
      final user = AppUser(id: 'OwnerUID');
      final id = await repository.insertWithProfile(user, profile);
      final base = 'users/OwnerUID/profiles/$id';

      expect(firestore.transactionCount, 1);
      expect(firestore.queuedPaths, [
        'users/OwnerUID',
        base,
        '$base/instruments/guitar',
        '$base/genres/rock',
        '$base/places/cafe',
        '$base/facilities/publisher',
      ]);
      expect(
        (await firestore.doc('$base/instruments/guitar').get())
            .data()?['isMain'],
        isTrue,
      );
      expect(
        (await firestore.doc('$base/genres/rock').get()).data()?['isFavorite'],
        isTrue,
      );
      expect(
        (await firestore.doc('$base/places/cafe').get()).data()?['name'],
        'My cafe',
      );
      expect(
        (await firestore.doc('$base/facilities/publisher').get())
            .data()?['name'],
        'My press',
      );
      final saved = (await firestore.doc(base).get()).data()!;
      expect((saved['instruments'] as Map)['guitar']['isMain'], isTrue);
    },
  );

  for (final id in ['ExistingUID', 'legacy@example.test']) {
    test(
      'existing account $id and profiles are neither replaced nor migrated',
      () async {
        await firestore.doc('users/$id').set({
          'name': 'Original',
          'currentProfileId': 'old',
        });
        await firestore.doc('users/$id/profiles/old').set({
          'name': 'Original profile',
        });
        final draft = AppUser(id: id, name: 'Replacement');
        final profile = AppProfile(name: 'Replacement profile');

        expect(await repository.insertWithProfile(draft, profile), isEmpty);
        expect(firestore.queuedPaths, isEmpty);
        expect(profile.id, isEmpty);
        expect(draft.currentProfileId, isEmpty);
        expect((await firestore.doc('users/$id').get()).data(), {
          'name': 'Original',
          'currentProfileId': 'old',
        });
        final profiles = await firestore.collection('users/$id/profiles').get();
        expect(profiles.docs.single.id, 'old');
        expect(profiles.docs.single.data()['name'], 'Original profile');
      },
    );
  }

  test(
    'draft stays uncommitted until account transaction has completed',
    () async {
      firestore.commitBarrier = Completer<void>();
      final user = AppUser(id: 'OwnerUID');
      final profile = AppProfile(name: 'Reader');
      var finished = false;
      final result = repository.insertWithProfile(user, profile).then((id) {
        finished = true;
        return id;
      });
      await Future<void>.delayed(Duration.zero);

      expect(firestore.queuedPaths.length, 2);
      expect(finished, isFalse);
      expect(user.currentProfileId, isEmpty);
      expect(profile.id, isEmpty);
      expect((await firestore.doc('users/OwnerUID').get()).exists, isFalse);

      firestore.commitBarrier!.complete();
      expect(await result, isNotEmpty);
      expect(user.currentProfileId, isNotEmpty);
    },
  );

  test(
    'commit error propagates with unchanged draft and retry can succeed',
    () async {
      firestore.commitFailure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      final user = AppUser(id: 'OwnerUID');
      final profile = AppProfile(name: 'Reader');

      await expectLater(
        repository.insertWithProfile(user, profile),
        throwsA(isA<FirebaseException>()),
      );
      expect(user.currentProfileId, isEmpty);
      expect(user.profiles, isEmpty);
      expect(profile.id, isEmpty);
      expect((await firestore.doc('users/OwnerUID').get()).exists, isFalse);
      expect(
        (await firestore.collection('users/OwnerUID/profiles').get()).docs,
        isEmpty,
      );

      firestore.commitFailure = null;
      expect(await repository.insertWithProfile(user, profile), isNotEmpty);
      expect(
        (await firestore.collection('users/OwnerUID/profiles').get()).docs,
        hasLength(1),
      );
    },
  );

  test('wrong-case UID is rejected by owner rules before any write', () async {
    firestore = _CommitFirestore(securityRules: _ownerRules);
    firestore.authObject.add({'uid': 'MiXeD-Firebase-UID'});
    repository = UserFirestore(firestore: firestore);
    await expectLater(
      repository.insertWithProfile(
        AppUser(id: 'mixed-firebase-uid'),
        AppProfile(),
      ),
      throwsA(isA<Exception>()),
    );
    expect(firestore.queuedPaths, isEmpty);
  });

  for (final id in ['', 'invalid/id']) {
    test('invalid account ID "$id" creates nothing', () async {
      await expectLater(
        repository.insertWithProfile(AppUser(id: id), AppProfile()),
        throwsArgumentError,
      );
      expect(firestore.transactionCount, 0);
      expect(firestore.queuedPaths, isEmpty);
    });
  }

  test(
    'standalone rejected profile insert returns failure without rollback',
    () async {
      firestore = _CommitFirestore(
        securityRules: '''
      service cloud.firestore {
        match /databases/{database}/documents {
          match /{document=**} { allow read: if true; allow write: if false; }
        }
      }
    ''',
      );
      final profiles = ProfileFirestore(firestore: firestore);
      expect(
        await profiles.insert('OwnerUID', AppProfile(name: 'Reader')),
        isEmpty,
      );
      expect(
        (await firestore.collection('users/OwnerUID/profiles').get()).docs,
        isEmpty,
      );
    },
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      SintMaterialApp(
        initialRoute: AppRouteConstants.introAddImage,
        sintPages: [
          SintPage(
            name: AppRouteConstants.introAddImage,
            page: () => const Scaffold(body: Text('Finish account')),
          ),
          SintPage(
            name: AppRouteConstants.home,
            page: () => const Scaffold(body: Text('Home after commit')),
          ),
          SintPage(
            name: AppRouteConstants.login,
            page: () => const Scaffold(body: Text('Retry login')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'new account leaves guest mode only after atomic commit and cache',
    (tester) async {
      final creationRepository = _CreationRepository();
      final cacheBarrier = Completer<void>();
      var cacheCalls = 0;
      final controller = UserController(
        userFirestore: creationRepository,
        persistProfileInfo: () {
          cacheCalls++;
          return cacheBarrier.future;
        },
      );
      await controller.setUserByEmail('reader@example.test');
      controller.getUserFromFirebase(_AuthUser());
      final login = _LoginService();
      Sint.put<UserService>(controller);
      Sint.put<LoginService>(login);
      await mount(tester);
      creationRepository.gate = Completer<void>();

      final creating = controller.createUser();
      await tester.pump();
      expect(controller.isNewUser, isTrue);
      expect(controller.profile.id, isEmpty);
      expect(AppConfig.instance.isGuestMode, isTrue);
      expect(login.statuses, isEmpty);
      expect(cacheCalls, 0);
      expect(find.text('Home after commit'), findsNothing);

      creationRepository.gate!.complete();
      await tester.pump();
      expect(creationRepository.committed, isTrue);
      expect(cacheCalls, 1);
      expect(controller.isNewUser, isTrue);
      expect(AppConfig.instance.isGuestMode, isTrue);
      expect(login.statuses, isEmpty);

      cacheBarrier.complete();
      await tester.pump();
      await creating;
      await tester.pumpAndSettle();

      expect(controller.isNewUser, isFalse);
      expect(creationRepository.committed, isTrue);
      expect(controller.profile.id, isNotEmpty);
      expect(AppConfig.instance.isGuestMode, isFalse);
      expect(login.statuses, [AuthStatus.loggedIn]);
      expect(find.text('Home after commit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rejected account commit does not authenticate or navigate home',
    (tester) async {
      final creationRepository = _CreationRepository();
      final controller = UserController(userFirestore: creationRepository);
      await controller.setUserByEmail('reader@example.test');
      controller.getUserFromFirebase(_AuthUser());
      final login = _LoginService();
      Sint.put<UserService>(controller);
      Sint.put<LoginService>(login);
      await mount(tester);
      creationRepository.failure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

      await controller.createUser();
      await tester.pumpAndSettle();

      expect(controller.isNewUser, isTrue);
      expect(controller.profile.id, isEmpty);
      expect(AppConfig.instance.isGuestMode, isTrue);
      expect(login.statuses, isEmpty);
      expect(find.text('Home after commit'), findsNothing);
      expect(creationRepository.committed, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('cache failure after commit does not enter a ready session', (
    tester,
  ) async {
    final creationRepository = _CreationRepository();
    final controller = UserController(
      userFirestore: creationRepository,
      persistProfileInfo: () async => throw StateError('Storage unavailable'),
    );
    await controller.setUserByEmail('reader@example.test');
    controller.getUserFromFirebase(_AuthUser());
    final login = _LoginService();
    Sint.put<UserService>(controller);
    Sint.put<LoginService>(login);
    await mount(tester);

    await controller.createUser();
    await tester.pumpAndSettle();
    expect(creationRepository.committed, isTrue);
    expect(controller.isNewUser, isTrue);
    expect(AppConfig.instance.isGuestMode, isTrue);
    expect(login.statuses, isEmpty);
    expect(find.text('Home after commit'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  test(
    'strict Hive cache failure propagates while legacy callers stay compatible',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'neom_signup_cache_',
      );
      Hive.init(directory.path);
      Sint.put<UserService>(_UnavailableCacheUser());
      try {
        await expectLater(
          AppHiveController().writeProfileInfo(
            overwrite: true,
            throwOnError: true,
          ),
          throwsStateError,
        );
        await expectLater(
          AppHiveController().writeProfileInfo(overwrite: true),
          completes,
        );
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
