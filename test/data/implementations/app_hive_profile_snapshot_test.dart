import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_hive_constants.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import 'package:sint/sint.dart';

class _UserService extends Fake implements UserService {
  @override
  AppUser user = AppUser(
    id: 'account-one',
    name: 'First reader',
    photoUrl: 'photo-one',
  );
  @override
  AppProfile profile = AppProfile(id: 'profile-one');
}

class _Box extends Fake implements Box {
  final stored = <dynamic, dynamic>{};
  Map<dynamic, dynamic>? submitted;
  int putCalls = 0;
  int putAllCalls = 0;
  Object? failure;
  Completer<void>? writeBarrier;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      stored[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    putCalls++;
    throw StateError('Profile cache must use a single snapshot');
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> entries) async {
    putAllCalls++;
    submitted = entries;
    final error = failure;
    if (error != null) throw error;
    stored.addAll(entries);
    await writeBarrier?.future;
  }
}

void main() {
  late _UserService service;
  late _Box box;
  late Completer<Box> openBarrier;
  late AppHiveController controller;

  setUp(() {
    Sint.reset();
    service = _UserService();
    Sint.put<UserService>(service);
    box = _Box();
    openBarrier = Completer<Box>();
    controller = AppHiveController.withBoxLoader((name) {
      expect(name, AppHiveBox.profile.name);
      return openBarrier.future;
    });
  });

  tearDown(Sint.reset);

  test(
    'writes one immutable snapshot captured before opening the box',
    () async {
      final writing = controller.writeProfileInfo();
      service.user.name = 'Edited while opening';
      service.user.photoUrl = 'edited-photo';
      openBarrier.complete(box);
      await writing;
      expect(box.putCalls, 0);
      expect(box.putAllCalls, 1);
      expect(box.stored, {
        AppHiveConstants.userId: 'account-one',
        AppHiveConstants.username: 'First reader',
        AppHiveConstants.profileId: 'profile-one',
        AppHiveConstants.photoUrl: 'photo-one',
        AppHiveConstants.firstTime: false,
      });
      expect(
        () => box.submitted![AppHiveConstants.username] = 'Not mutable',
        throwsUnsupportedError,
      );
    },
  );

  test(
    'immutable snapshot persists and reloads with a real local Hive box',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'neom_profile_snapshot_',
      );
      const name = 'profile_snapshot_local_test';
      Hive.init(directory.path);
      try {
        final localBox = await Hive.openBox(name);
        final localController = AppHiveController.withBoxLoader(
          (_) async => localBox,
        );
        await localController.writeProfileInfo(
          overwrite: true,
          throwOnError: true,
        );
        await localBox.close();
        final reopened = await Hive.openBox(name);
        expect(reopened.get(AppHiveConstants.userId), 'account-one');
        expect(reopened.get(AppHiveConstants.profileId), 'profile-one');
        expect(reopened.get(AppHiveConstants.username), 'First reader');
        expect(reopened.get(AppHiveConstants.photoUrl), 'photo-one');
        await reopened.close();
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('replacing the account while opening discards the old write', () async {
    final writing = controller.writeProfileInfo(overwrite: true);
    service.user = AppUser(id: 'account-two', name: 'Second reader');
    service.profile = AppProfile(id: 'profile-two');
    openBarrier.complete(box);
    await writing;
    expect(box.putAllCalls, 0);
    expect(box.stored, isEmpty);
  });

  test('same UID with a new session object discards the old write', () async {
    final writing = controller.writeProfileInfo(overwrite: true);
    service.user = AppUser(id: 'account-one', name: 'Restored reader');
    openBarrier.complete(box);
    await writing;
    expect(box.putAllCalls, 0);
  });

  test('changing profile while opening discards the old write', () async {
    final writing = controller.writeProfileInfo(overwrite: true);
    service.profile = AppProfile(id: 'profile-two');
    openBarrier.complete(box);
    await writing;
    expect(box.putAllCalls, 0);
  });

  test(
    'replacing the same profile ID also discards its stale snapshot',
    () async {
      final writing = controller.writeProfileInfo(overwrite: true);
      service.profile = AppProfile(id: 'profile-one');
      openBarrier.complete(box);
      await writing;
      expect(box.putAllCalls, 0);
    },
  );

  for (final changeUser in [true, false]) {
    test(
      'mutating the ${changeUser ? 'user' : 'profile'} ID discards the write',
      () async {
        final writing = controller.writeProfileInfo(overwrite: true);
        if (changeUser) {
          service.user.id = 'account-two';
        } else {
          service.profile.id = 'profile-two';
        }
        openBarrier.complete(box);
        await writing;
        expect(box.putAllCalls, 0);
      },
    );
  }

  test(
    'replacing UserService discards even matching model references',
    () async {
      final writing = controller.writeProfileInfo(overwrite: true);
      final replacement = _UserService()
        ..user = service.user
        ..profile = service.profile;
      Sint.delete<UserService>(force: true);
      Sint.put<UserService>(replacement);
      openBarrier.complete(box);
      await writing;
      expect(box.putAllCalls, 0);
    },
  );

  test('existing cache is retained when overwrite is false', () async {
    box.stored.addAll({
      AppHiveConstants.userId: 'existing-cached-account',
      AppHiveConstants.username: 'Existing reader',
    });
    final writing = controller.writeProfileInfo();
    openBarrier.complete(box);
    await writing;
    expect(box.putAllCalls, 0);
    expect(box.stored[AppHiveConstants.username], 'Existing reader');
  });

  test(
    'overwrite preserves unrelated cache fields and replaces the snapshot',
    () async {
      box.stored.addAll({
        AppHiveConstants.userId: 'existing-cached-account',
        AppHiveConstants.username: 'Existing reader',
        AppHiveConstants.appLocale: 'spanish',
      });
      final writing = controller.writeProfileInfo(overwrite: true);
      openBarrier.complete(box);
      await writing;
      expect(box.putAllCalls, 1);
      expect(box.stored[AppHiveConstants.userId], 'account-one');
      expect(box.stored[AppHiveConstants.username], 'First reader');
      expect(box.stored[AppHiveConstants.appLocale], 'spanish');
    },
  );

  test(
    'changing session during putAll cannot mix individual account fields',
    () async {
      box.writeBarrier = Completer<void>();
      final writing = controller.writeProfileInfo(overwrite: true);
      openBarrier.complete(box);
      await Future<void>.delayed(Duration.zero);
      expect(box.putAllCalls, 1);
      service.user = AppUser(
        id: 'second',
        name: 'Second reader',
        photoUrl: 'second-photo',
      );
      service.profile = AppProfile(id: 'second-profile');
      box.writeBarrier!.complete();
      await writing;
      expect(box.putCalls, 0);
      expect(box.stored[AppHiveConstants.userId], 'account-one');
      expect(box.stored[AppHiveConstants.username], 'First reader');
      expect(box.stored[AppHiveConstants.profileId], 'profile-one');
      expect(box.stored[AppHiveConstants.photoUrl], 'photo-one');
      expect(service.user.id, 'second');
    },
  );

  for (final strict in [false, true]) {
    test('box-open failure preserves throwOnError=$strict behavior', () async {
      final expected = expectLater(
        controller.writeProfileInfo(throwOnError: strict),
        strict ? throwsStateError : completes,
      );
      openBarrier.completeError(StateError('Test box unavailable'));
      await expected;
      expect(box.putAllCalls, 0);
    });

    test(
      'batch-write failure preserves throwOnError=$strict behavior',
      () async {
        box.failure = StateError('Test write unavailable');
        final expected = expectLater(
          controller.writeProfileInfo(throwOnError: strict),
          strict ? throwsStateError : completes,
        );
        openBarrier.complete(box);
        await expected;
        expect(box.putAllCalls, 1);
        expect(box.putCalls, 0);
      },
    );
  }
}
