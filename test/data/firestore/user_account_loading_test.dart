import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/account_load_exception.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

class _AccountFirestore extends FakeFirebaseFirestore {
  _AccountFirestore({super.securityRules});
  Object? nextFailure;
  final collections = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    collections.add(path);
    final failure = nextFailure;
    nextFailure = null;
    if (failure != null) throw failure;
    return super.collection(path);
  }

  @override
  CollectionReference<Map<String, dynamic>> collectionGroup(String path) =>
      throw StateError('Login must not read a collection group');
}

void main() {
  final config = AppConfig.instance;
  late _AccountFirestore firestore;
  late UserFirestore repository;
  late UserController controller;

  setUp(() {
    config.appInUse = AppInUse.g;
    config.isGuestMode = true;
    firestore = _AccountFirestore();
    repository = UserFirestore(firestore: firestore);
    controller = UserController(userFirestore: repository);
  });

  tearDown(() {
    config.appInUse = AppInUse.o;
    config.isGuestMode = true;
  });

  Future<void> seedAccount({String currentProfileId = 'profile'}) async {
    await firestore.doc('users/account').set({
      'email': 'owner@example.test',
      'currentProfileId': currentProfileId,
    });
    await firestore.doc('users/account/profiles/profile').set({
      'name': 'Own profile',
    });
    await firestore.doc('users/other/profiles/profile').set({
      'name': 'Other profile',
    });
    await firestore.doc('publicProfiles/profile').set({
      'name': 'Public profile',
    });
    firestore.collections.clear();
  }

  test(
    'strict successful empty reads are the only new-account result',
    () async {
      expect(
        await repository.getByEmail('missing@example.test', throwOnError: true),
        isNull,
      );
      expect(
        (await repository.getById('missing', throwOnError: true)).id,
        isEmpty,
      );
      await controller.setUserByEmail('missing@example.test');
      expect(controller.isNewUser, isTrue);
      expect(controller.user.id, isEmpty);
    },
  );

  for (final code in ['permission-denied', 'unavailable']) {
    for (final byEmail in [true, false]) {
      test(
        '$code by ${byEmail ? 'email' : 'ID'} never marks a new user',
        () async {
          await controller.setUserByEmail('missing@example.test');
          expect(controller.isNewUser, isTrue);
          firestore.nextFailure = FirebaseException(
            plugin: 'cloud_firestore',
            code: code,
          );
          await expectLater(
            byEmail
                ? controller.setUserByEmail('owner@example.test')
                : controller.setUserById('account'),
            throwsA(isA<AccountLoadException>()),
          );
          expect(controller.isNewUser, isFalse);
        },
      );
    }
  }

  test(
    'strict existing account uses only its nested current profile while guest',
    () async {
      await seedAccount();
      await controller.setUserByEmail('owner@example.test');
      expect(controller.user.id, 'account');
      expect(controller.profile.name, 'Own profile');
      expect(controller.isNewUser, isFalse);
      expect(firestore.collections, everyElement('users'));
    },
  );

  for (final currentId in ['', 'missing', 'invalid/path']) {
    test(
      'own nested fallback works for current profile "$currentId"',
      () async {
        await seedAccount(currentProfileId: currentId);
        await controller.setUserById('account');
        expect(controller.profile.id, 'profile');
        expect(controller.profile.name, 'Own profile');
        expect(firestore.collections, everyElement('users'));
      },
    );
  }

  test(
    'existing user without profiles fails closed instead of signup',
    () async {
      await firestore.doc('users/account').set({'email': 'owner@example.test'});
      await expectLater(
        controller.setUserByEmail('owner@example.test'),
        throwsA(isA<AccountLoadException>()),
      );
      expect(controller.isNewUser, isFalse);
    },
  );

  test(
    'ambiguous email fails closed while legacy lookup remains compatible',
    () async {
      await seedAccount();
      await firestore.doc('users/duplicate').set({
        'email': 'owner@example.test',
      });
      await expectLater(
        controller.setUserByEmail('owner@example.test'),
        throwsA(isA<AccountLoadException>()),
      );
      expect(controller.isNewUser, isFalse);
      expect(await repository.getByEmail('owner@example.test'), isNotNull);
    },
  );

  test(
    'denied own profiles propagate instead of falling back to public profiles',
    () async {
      firestore = _AccountFirestore(
        securityRules: '''
      service cloud.firestore {
        match /databases/{database}/documents {
          match /users/{user} { allow read, write: if true; }
          match /users/{user}/profiles/{profile} { allow read: if false; allow write: if true; }
          match /publicProfiles/{profile} { allow read, write: if true; }
        }
      }
    ''',
      );
      repository = UserFirestore(firestore: firestore);
      await seedAccount();
      await expectLater(
        repository.getByEmail(
          'owner@example.test',
          getProfile: true,
          throwOnError: true,
        ),
        throwsA(isA<AccountLoadException>()),
      );
      expect(firestore.collections, everyElement('users'));
    },
  );

  test(
    'failed retry preserves already loaded account but never marks new',
    () async {
      await seedAccount();
      await controller.setUserById('account');
      final loaded = controller.user;
      firestore.nextFailure = StateError('offline');
      await expectLater(
        controller.setUserByEmail('owner@example.test'),
        throwsA(isA<AccountLoadException>()),
      );
      expect(identical(controller.user, loaded), isTrue);
      expect(controller.isNewUser, isFalse);
    },
  );

  test(
    'legacy repository callers retain nullable and empty error results',
    () async {
      firestore.nextFailure = StateError('offline');
      expect(await repository.getByEmail('owner@example.test'), isNull);
      firestore.nextFailure = StateError('offline');
      expect((await repository.getById('account')).id, isEmpty);
    },
  );

  test('safe insert never overwrites or deletes an existing account', () async {
    await firestore.doc('users/account').set({
      'name': 'Original',
      'privateMarker': 42,
    });
    expect(
      await repository.insert(AppUser(id: 'account', name: 'Replacement')),
      isFalse,
    );
    expect((await firestore.doc('users/account').get()).data(), {
      'name': 'Original',
      'privateMarker': 42,
    });
  });

  test('direct createUser is inert without confirmed account absence', () async {
    await seedAccount();
    await controller.setUserById('account');
    final loaded = controller.user;
    final profile = controller.profile;
    firestore.collections.clear();
    await controller.createUser();
    expect(identical(controller.user, loaded), isTrue);
    expect(identical(controller.profile, profile), isTrue);
    expect(firestore.collections, isEmpty);
  });

  test('safe insert creates an absent account only once', () async {
    expect(
      await repository.insert(AppUser(id: 'account', name: 'New account')),
      isTrue,
    );
    expect(
      await repository.insert(AppUser(id: 'account', name: 'Duplicate')),
      isFalse,
    );
    expect(
      (await firestore.doc('users/account').get()).data()?['name'],
      'New account',
    );
  });

  test(
    'failed account creation returns false without deleting existing data',
    () async {
      await firestore.doc('users/account').set({'name': 'Original'});
      firestore.nextFailure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      expect(await repository.insert(AppUser(id: 'account')), isFalse);
      expect(
        (await firestore.doc('users/account').get()).data()?['name'],
        'Original',
      );
    },
  );
}
