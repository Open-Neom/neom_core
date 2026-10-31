import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/release_deduplication_service.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

class _FirebaseUser extends Fake implements fba.User {}

class _LoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;

  @override
  fba.User get fbaUser => _FirebaseUser();
}

class _UserService extends Fake implements UserService {
  @override
  final user = AppUser(id: 'test-account');

  @override
  final profile = AppProfile(id: 'test-profile');
}

void main() {
  final config = AppConfig.instance;
  late FakeFirebaseFirestore firestore;
  late AppReleaseItemFirestore repository;
  const firebasePdf =
      'https://firebasestorage.googleapis.com/v0/b/example.invalid/o/book.pdf?alt=media';
  const legacyPdf = 'https://escritoresmxi.org/wp-content/uploads/book.pdf';
  const sharedFields = <String, dynamic>{
    'ownerEmail': 'author@example.invalid',
    'ownerName': 'Test author',
    'ownerProfileId': 'test-author',
    'ownerSlug': 'test-author',
    'categories': ['literatura'],
    'language': 'es',
    'status': 'publish',
    'isSuspended': false,
    'createdTime': 20,
    'type': 'single',
  };

  void signIn() {
    config.isGuestMode = false;
    Sint.put<LoginService>(_LoginService());
    Sint.put<UserService>(_UserService());
    expect(config.canPersistUserActivity, isTrue);
  }

  Future<void> seedCatalog() async {
    await firestore.doc('appReleaseItems/firebase-release').set({
      ...sharedFields,
      'name': 'Firebase title',
      'slug': 'firebase-title',
      'previewUrl': firebasePdf,
    });
    await firestore.doc('appReleaseItems/legacy-release').set({
      ...sharedFields,
      'name': 'Legacy title',
      'slug': 'legacy-title',
      'previewUrl': legacyPdf,
    });
    await firestore.doc('appReleaseItems/migrated-release').set({
      ...sharedFields,
      'name': 'Migrated title',
      'slug': 'migrated-title',
      'previewUrl': firebasePdf,
      'externalUrl': legacyPdf,
      'metaId': 'woocommerce-product-123',
    });
    await firestore.doc('appReleaseItems/legacy-landing').set({
      ...sharedFields,
      'name': 'Legacy landing title',
      'slug': 'legacy-landing-title',
      'externalUrl': legacyPdf,
    });
  }

  setUp(() async {
    Sint.reset();
    config.appInUse = AppInUse.e;
    config.isGuestMode = true;
    AppReleaseItemFirestore.invalidateAllReleaseItemsCache();
    firestore = FakeFirebaseFirestore();
    repository = AppReleaseItemFirestore(firestore: firestore);
    await seedCatalog();
  });

  tearDown(() {
    Sint.reset();
    config.isGuestMode = true;
    config.appInUse = AppInUse.o;
    AppReleaseItemFirestore.invalidateAllReleaseItemsCache();
  });

  const visibleIds = ['firebase-release', 'migrated-release'];
  const allIds = [
    'firebase-release',
    'legacy-release',
    'migrated-release',
    'legacy-landing',
  ];

  for (final authenticated in [false, true]) {
    final sessionName = authenticated ? 'authenticated' : 'guest';

    test(
      '$sessionName lists hide old hosting without modifying documents',
      () async {
        if (authenticated) signIn();
        final before = firestore.dump();
        final results = <Map<String, AppReleaseItem>>[
          await repository.retrieveAll(),
          await repository.retrieveAll(), // Exercise the raw-document cache.
          await repository.retrieveFromList(allIds),
          await repository.retrieveByCategory('literatura'),
          await repository.retrieveByLanguage('es'),
          await repository.retrieveByOwner('author@example.invalid'),
          await repository.retrieveByOwnerProfileId('test-author'),
          await repository.retrieveByOwnerSlug('test-author'),
        ];
        for (final result in results) {
          expect(result.keys, unorderedEquals(visibleIds));
        }
        expect(firestore.dump(), before);
        expect(
          (await firestore.doc('appReleaseItems/legacy-release').get()).exists,
          isTrue,
        );
      },
    );
  }

  test(
    'cached releases are filtered again on app and session changes',
    () async {
      config.appInUse = AppInUse.c;
      signIn();
      expect((await repository.retrieveAll()).keys, unorderedEquals(allIds));

      config.appInUse = AppInUse.e;
      expect(
        (await repository.retrieveAll()).keys,
        unorderedEquals(visibleIds),
      );
      config.isGuestMode = true;
      expect(
        (await repository.retrieveAll()).keys,
        unorderedEquals(visibleIds),
      );

      config.appInUse = AppInUse.c;
      expect((await repository.retrieveAll()).keys, unorderedEquals(allIds));
    },
  );

  test(
    'filters unavailable records before choosing a duplicate winner',
    () async {
      final obsolete = <String, dynamic>{
        ...sharedFields,
        'name': 'Same title',
        'slug': 'same-title',
        'previewUrl': legacyPdf,
        'imgUrl': 'https://escritoresmxi.org/cover.jpg',
        'description': List.filled(
          50,
          'Legacy detailed description.',
        ).join(' '),
        'boughtUsers': ['test-buyer-1', 'test-buyer-2'],
        'duration': 120,
        'publishedYear': 2020,
      };
      final available = <String, dynamic>{
        ...sharedFields,
        'name': 'Same title',
        'slug': 'same-title',
        'previewUrl': firebasePdf,
      };
      final deduplication = ReleaseDeduplicationService();
      expect(
        deduplication.calculateCompletenessScore(
          AppReleaseItem.fromJSON(obsolete),
        ),
        greaterThan(
          deduplication.calculateCompletenessScore(
            AppReleaseItem.fromJSON(available),
          ),
        ),
      );
      await firestore.doc('appReleaseItems/duplicate-obsolete').set(obsolete);
      await firestore.doc('appReleaseItems/duplicate-available').set(available);
      final before = firestore.dump();

      final results = await repository.retrieveAll();
      expect(results.keys, contains('duplicate-available'));
      expect(results.keys, isNot(contains('duplicate-obsolete')));
      expect(results['duplicate-available']!.previewUrl, firebasePdf);
      expect(firestore.dump(), before);
    },
  );

  test(
    'individual lookups and pending review retain records for management',
    () async {
      signIn();
      await firestore.doc('appReleaseItems/legacy-pending').set({
        ...sharedFields,
        'name': 'Pending legacy title',
        'slug': 'pending-legacy-title',
        'status': 'pending',
        'previewUrl': legacyPdf,
      });
      final before = firestore.dump();

      expect(
        (await repository.retrieve('legacy-release')).id,
        'legacy-release',
      );
      expect(await repository.exists('legacy-release'), isTrue);
      expect(
        (await repository.getBySlug('legacy-title'))?.id,
        'legacy-release',
      );
      expect(
        (await repository.getByOwnerAndSlug('test-author', 'legacy-title'))?.id,
        'legacy-release',
      );
      expect(
        (await repository.findByIdOrSlug('legacy-release'))?.id,
        'legacy-release',
      );
      expect(
        (await repository.retrievePendingReleases()).map((item) => item.id),
        ['legacy-pending'],
      );
      expect(firestore.dump(), before);
    },
  );
}
