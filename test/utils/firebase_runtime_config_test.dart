import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/firebase_runtime_config.dart';

void main() {
  group('NeomFirebaseRuntimeConfig.blocksRealFirebase', () {
    test('blocks non-release builds pointed at a real project', () {
      expect(
        NeomFirebaseRuntimeConfig.blocksRealFirebase(
          isRelease: false,
          usesEmulators: false,
          allowsNonReleaseProduction: false,
        ),
        isTrue,
      );
    });

    test('allows non-release builds when emulators are enabled', () {
      expect(
        NeomFirebaseRuntimeConfig.blocksRealFirebase(
          isRelease: false,
          usesEmulators: true,
          allowsNonReleaseProduction: false,
        ),
        isFalse,
      );
    });

    test('allows non-release real backend only with explicit opt-in', () {
      expect(
        NeomFirebaseRuntimeConfig.blocksRealFirebase(
          isRelease: false,
          usesEmulators: false,
          allowsNonReleaseProduction: true,
        ),
        isFalse,
      );
    });

    test('never blocks release builds', () {
      expect(
        NeomFirebaseRuntimeConfig.blocksRealFirebase(
          isRelease: true,
          usesEmulators: false,
          allowsNonReleaseProduction: false,
        ),
        isFalse,
      );
    });
  });

  group('NeomFirebaseRuntimeConfig.forApp presets', () {
    test('EMXI and Admineom isolate debug runs to demo emulator projects', () {
      final emxi = NeomFirebaseRuntimeConfig.forApp(AppInUse.e);
      expect(emxi.useEmulators, isTrue);
      expect(emxi.allowNonReleaseProduction, isFalse);
      expect(emxi.localProjectId, 'demo-emxi-local');
      expect(emxi.optionsFor(null)?.projectId, 'demo-emxi-local');

      final admineom = NeomFirebaseRuntimeConfig.forApp(AppInUse.a);
      expect(admineom.useEmulators, isTrue);
      expect(admineom.allowNonReleaseProduction, isFalse);
      expect(admineom.localProjectId, 'demo-admineom-local');
      expect(admineom.optionsFor(null)?.projectId, 'demo-admineom-local');
    });

    test('Gigmeout defaults to shared QA backend while supporting emulator isolation', () {
      final gigmeout = NeomFirebaseRuntimeConfig.forApp(AppInUse.g);
      expect(gigmeout.useEmulators, isFalse);
      expect(gigmeout.allowNonReleaseProduction, isTrue);
      expect(gigmeout.localProjectId, 'demo-gigmeout-local');

      const prod = FirebaseOptions(
        apiKey: 'qa-key',
        appId: 'qa-app',
        messagingSenderId: 'qa-sender',
        projectId: 'gig-me-out',
      );
      expect(gigmeout.optionsFor(prod), same(prod));
      expect(gigmeout.optionsFor(null), isNull);
      expect(
        gigmeout.selectOptions(prod, usesEmulators: true)?.projectId,
        'demo-gigmeout-local',
      );
    });

    test('fallback preset generates isolated project id for other apps', () {
      final generic = NeomFirebaseRuntimeConfig.forApp(AppInUse.p);
      expect(generic.localProjectId, 'demo-p-local');
      expect(generic.useEmulators, isTrue);
    });
  });
}
