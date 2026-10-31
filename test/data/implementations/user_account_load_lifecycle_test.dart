import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/user_firestore.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/domain/model/account_load_exception.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/account_load_lifecycle.dart';
import 'package:neom_core/utils/enums/user_role.dart';

class _Read {
  _Read(this.key, {required this.strict, this.getProfile = true});
  final String key;
  final bool strict;
  final bool getProfile;
  final result = Completer<AppUser?>();
}

class _Repository extends Fake implements UserFirestore {
  final reads = <_Read>[];

  @override
  Future<AppUser> getById(
    String userId, {
    getProfileFeatures = false,
    bool throwOnError = false,
  }) {
    final read = _Read('id:$userId', strict: throwOnError);
    reads.add(read);
    return read.result.future.then((account) => account ?? AppUser());
  }

  @override
  Future<AppUser?> getByEmail(
    String email, {
    bool getProfile = false,
    bool getProfileFeatures = false,
    bool throwOnError = false,
  }) {
    final read = _Read(
      'email:$email',
      strict: throwOnError,
      getProfile: getProfile,
    );
    reads.add(read);
    return read.result.future;
  }
}

AppUser _account(String id, {UserRole role = UserRole.subscriber}) => AppUser(
  id: id,
  profiles: [AppProfile(id: '$id-profile', name: 'Test profile')],
  userRole: role,
);

void main() {
  late _Repository repository;
  late UserController controller;

  setUp(() {
    repository = _Repository();
    controller = UserController(
      userFirestore: repository,
      accountLoadTimeout: const Duration(milliseconds: 30),
    );
    AppConfig.instance.isAdminMode = false;
  });

  tearDown(() {
    controller.onClose();
    AppConfig.instance.isAdminMode = false;
  });

  Future<void> load(bool byEmail) => byEmail
      ? controller.setUserByEmail('reader@example.test')
      : controller.setUserById('auth-uid');

  test('account deadline rejects zero and negative configuration', () {
    for (final timeout in [Duration.zero, const Duration(milliseconds: -1)]) {
      expect(
        () => UserController(
          userFirestore: repository,
          accountLoadTimeout: timeout,
        ),
        throwsArgumentError,
      );
    }
  });

  for (final byEmail in [true, false]) {
    final label = byEmail ? 'email' : 'ID';

    testWidgets('$label read preserves legacy IDs and strict options', (
      tester,
    ) async {
      final pending = load(byEmail);
      final read = repository.reads.single;
      expect(read.strict, isTrue);
      expect(read.getProfile, isTrue);
      expect(read.key, byEmail ? 'email:reader@example.test' : 'id:auth-uid');
      read.result.complete(_account('legacy-account'));
      await pending;
      expect(controller.user.id, 'legacy-account');
      expect(controller.profile.id, 'legacy-account-profile');
      expect(controller.isNewUser, isFalse);
    });

    testWidgets('$label pending read times out without publishing late data', (
      tester,
    ) async {
      final previous = _account('previous-account');
      controller.user = previous;
      controller.profile = previous.profiles.single;
      final failure = expectLater(
        load(byEmail),
        throwsA(isA<AccountLoadException>()),
      );
      await tester.pump(const Duration(milliseconds: 31));
      await failure;
      expect(controller.isNewUser, isFalse);
      repository.reads.single.result.complete(
        _account('late', role: UserRole.admin),
      );
      await tester.pump();
      expect(identical(controller.user, previous), isTrue);
      expect(controller.profile.id, 'previous-account-profile');
      expect(controller.isNewUser, isFalse);
      expect(AppConfig.instance.isAdminMode, isFalse);
    });

    testWidgets('$label retry wins over the first timed-out result', (
      tester,
    ) async {
      final failure = expectLater(
        load(byEmail),
        throwsA(isA<AccountLoadException>()),
      );
      await tester.pump(const Duration(milliseconds: 31));
      await failure;
      final retry = load(byEmail);
      repository.reads.last.result.complete(_account('retry-account'));
      await retry;
      repository.reads.first.result.complete(
        _account('late-admin', role: UserRole.admin),
      );
      await tester.pump();
      expect(controller.user.id, 'retry-account');
      expect(controller.profile.id, 'retry-account-profile');
      expect(controller.isNewUser, isFalse);
      expect(AppConfig.instance.isAdminMode, isFalse);
    });

    testWidgets('$label explicit invalidation completes before the deadline', (
      tester,
    ) async {
      final failure = expectLater(
        load(byEmail),
        throwsA(isA<AccountLoadException>()),
      );
      (controller as AccountLoadLifecycle).invalidateAccountLoad();
      await tester.pump();
      await failure;
      repository.reads.single.result.complete(null);
      await tester.pump();
      expect(controller.user.id, isEmpty);
      expect(controller.profile.id, isEmpty);
      expect(controller.isNewUser, isFalse);
    });
  }

  testWidgets(
    'a new session supersedes a pending session across lookup methods',
    (tester) async {
      final superseded = expectLater(
        controller.setUserByEmail('first@example.test'),
        throwsA(isA<AccountLoadException>()),
      );
      final second = controller.setUserById('second-uid');
      repository.reads.last.result.complete(_account('second-legacy'));
      await second;
      await superseded;
      repository.reads.first.result.complete(
        _account('first-admin', role: UserRole.admin),
      );
      await tester.pump();
      expect(controller.user.id, 'second-legacy');
      expect(controller.profile.id, 'second-legacy-profile');
      expect(controller.isNewUser, isFalse);
      expect(AppConfig.instance.isAdminMode, isFalse);
    },
  );

  testWidgets('an old error cannot reset a newer confirmed missing account', (
    tester,
  ) async {
    final oldFailure = expectLater(
      load(true),
      throwsA(isA<AccountLoadException>()),
    );
    final current = load(false);
    repository.reads.last.result.complete(null);
    await current;
    await oldFailure;
    expect(controller.isNewUser, isTrue);
    repository.reads.first.result.completeError(
      StateError('late test failure'),
    );
    await tester.pump();
    expect(controller.isNewUser, isTrue);
    expect(controller.user.id, isEmpty);
    expect(controller.profile.id, isEmpty);
  });

  testWidgets(
    'a completed SDK read is fenced before its continuation publishes',
    (tester) async {
      final failure = expectLater(
        load(true),
        throwsA(isA<AccountLoadException>()),
      );
      repository.reads.single.result.complete(
        _account('stale', role: UserRole.admin),
      );
      controller.invalidateAccountLoad();
      await tester.pump();
      await failure;
      expect(controller.user.id, isEmpty);
      expect(controller.profile.id, isEmpty);
      expect(controller.isNewUser, isFalse);
      expect(AppConfig.instance.isAdminMode, isFalse);
    },
  );

  testWidgets(
    'clear prevents an in-flight result from restoring a signed-out account',
    (tester) async {
      final failure = expectLater(
        load(true),
        throwsA(isA<AccountLoadException>()),
      );
      controller.clear();
      await tester.pump();
      await failure;
      repository.reads.single.result.complete(
        _account('late', role: UserRole.admin),
      );
      await tester.pump();
      expect(controller.user.id, isEmpty);
      expect(controller.profile.id, isEmpty);
      expect(controller.isNewUser, isFalse);
      expect(AppConfig.instance.isAdminMode, isFalse);
    },
  );

  testWidgets(
    'disposal rejects a pending load and ignores its eventual result',
    (tester) async {
      final failure = expectLater(
        load(false),
        throwsA(isA<AccountLoadException>()),
      );
      controller.onClose();
      await tester.pump();
      await failure;
      repository.reads.single.result.complete(_account('late'));
      await tester.pump();
      expect(controller.user.id, isEmpty);
      expect(controller.profile.id, isEmpty);
      expect(controller.isNewUser, isFalse);
    },
  );

  testWidgets(
    'a timeout after confirmed absence clears new-account authority',
    (tester) async {
      final first = load(true);
      repository.reads.single.result.complete(null);
      await first;
      expect(controller.isNewUser, isTrue);
      final failure = expectLater(
        load(false),
        throwsA(isA<AccountLoadException>()),
      );
      expect(controller.isNewUser, isFalse);
      await tester.pump(const Duration(milliseconds: 31));
      await failure;
      repository.reads.last.result.complete(null);
      await tester.pump();
      expect(controller.isNewUser, isFalse);
    },
  );

  testWidgets('an existing account without profiles still fails closed', (
    tester,
  ) async {
    final failure = expectLater(
      load(true),
      throwsA(isA<AccountLoadException>()),
    );
    repository.reads.single.result.complete(AppUser(id: 'existing'));
    await failure;
    expect(controller.user.id, isEmpty);
    expect(controller.profile.id, isEmpty);
    expect(controller.isNewUser, isFalse);
  });
}
