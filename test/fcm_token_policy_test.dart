import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/fcm_token_policy.dart';

void main() {
  group('FcmTokenPolicy', () {
    test('skips registration whenever Firebase emulators are enabled', () {
      expect(
        FcmTokenPolicy.shouldSkipRegistration(
          usesFirebaseEmulators: true,
          firebaseProjectId: 'emxi-9c5b5',
        ),
        isTrue,
      );
    });

    test('skips registration for an isolated Firebase demo project', () {
      expect(
        FcmTokenPolicy.shouldSkipRegistration(
          usesFirebaseEmulators: false,
          firebaseProjectId: 'demo-emxi-local',
        ),
        isTrue,
      );
    });

    test('keeps registration enabled for a production backend', () {
      expect(
        FcmTokenPolicy.shouldSkipRegistration(
          usesFirebaseEmulators: false,
          firebaseProjectId: 'emxi-9c5b5',
        ),
        isFalse,
      );
    });

    test('does not confuse an embedded demo label with a demo project', () {
      expect(
        FcmTokenPolicy.isFirebaseDemoProject('emxi-demo-production'),
        isFalse,
      );
    });
  });
}
