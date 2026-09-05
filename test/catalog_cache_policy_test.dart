import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/catalog_cache_policy.dart';

void main() {
  group('CatalogCachePolicy', () {
    test('guest sessions always bypass persistent catalogue data', () {
      expect(
        CatalogCachePolicy.shouldBypassPersistentCache(
          hasAuthenticatedSession: false,
          firebaseProjectId: 'emxi-9c5b5',
        ),
        isTrue,
      );
    });

    test('Firebase demo projects bypass cache for authenticated sessions', () {
      expect(
        CatalogCachePolicy.shouldBypassPersistentCache(
          hasAuthenticatedSession: true,
          firebaseProjectId: 'demo-emxi-local',
        ),
        isTrue,
      );
    });

    test('authenticated production sessions keep the offline cache', () {
      expect(
        CatalogCachePolicy.shouldBypassPersistentCache(
          hasAuthenticatedSession: true,
          firebaseProjectId: 'emxi-9c5b5',
        ),
        isFalse,
      );
    });

    test(
      'does not confuse an arbitrary project containing demo with emulator',
      () {
        expect(
          CatalogCachePolicy.isFirebaseDemoProject('emxi-demo-production'),
          isFalse,
        );
      },
    );
  });
}
