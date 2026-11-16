import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:neom_core/data/firestore/core_firestore_guard.dart';
import 'package:sint_sentinel/sint_sentinel_core.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('core_sentinel_test_');
    Hive.init(tempDir.path);
    await SintSentinel.init(
      config: const SentinelConfig(
        failureThreshold: 3,
        openDuration: Duration(seconds: 10),
        maxRequestsPerMinute: 100,
        maxDailyRequests: 1000,
        maxDailyWrites: 500,
      ),
    );
  });

  tearDown(() async {
    SintSentinel.dispose();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CoreFirestoreGuard + SintSentinel integration', () {
    test('classifies transient infrastructure failures vs domain errors', () {
      expect(
        CoreFirestoreGuard.isInfrastructureFailure(
          TimeoutException('deadline'),
        ),
        isTrue,
      );
      expect(
        CoreFirestoreGuard.isInfrastructureFailure(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'Backend unavailable',
          ),
        ),
        isTrue,
      );
      expect(
        CoreFirestoreGuard.isInfrastructureFailure(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'resource-exhausted',
            message: 'Quota exceeded',
          ),
        ),
        isTrue,
      );
      expect(
        CoreFirestoreGuard.isInfrastructureFailure(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Missing permissions',
          ),
        ),
        isFalse,
      );
      expect(
        CoreFirestoreGuard.isInfrastructureFailure(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'Doc missing',
          ),
        ),
        isFalse,
      );
      expect(
        CoreFirestoreGuard.isInfrastructureFailure(ArgumentError('bad id')),
        isFalse,
      );
    });

    test('permission-denied errors do not trip global SintSentinel circuit',
        () async {
      for (var i = 0; i < 6; i++) {
        await expectLater(
          CoreFirestoreGuard.guardRead<String>(
            () async => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
            tag: 'user_firestore.getById',
          ),
          throwsA(isA<FirebaseException>()),
        );
      }

      final status = await SintSentinel.getStatus();
      expect(status['circuitState'], 'closed');
      expect(SintSentinel.isBlocking, isFalse);
    });

    test('repeated unavailable errors trip SintSentinel circuit and use fallback',
        () async {
      for (var i = 0; i < 3; i++) {
        await expectLater(
          CoreFirestoreGuard.guardWrite<bool>(
            () async => throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
            ),
            tag: 'inbox_firestore.addMessage',
          ),
          throwsA(isA<FirebaseException>()),
        );
      }

      expect(SintSentinel.isBlocking, isTrue);

      final degraded = await CoreFirestoreGuard.guardRead<String>(
        () async => 'live',
        fallback: () => 'cached',
        tag: 'post_firestore.retrievePosts',
      );
      expect(degraded, 'cached');
    });
  });
}
