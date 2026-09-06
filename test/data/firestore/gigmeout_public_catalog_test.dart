import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_media_item_firestore.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/data/firestore/public_catalog_read_policy.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/domain/use_cases/login_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/auth_status.dart';
import 'package:sint/sint.dart';

class _UserService extends Fake implements UserService {
  @override
  final user = AppUser(id: 'legacy-account');

  @override
  final profile = AppProfile(id: 'own-profile', name: 'Account owner');
}

class _NoCatalogueAccess extends Fake implements FirebaseFirestore {
  int calls = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    calls++;
    throw StateError('A disabled catalogue mutation must not access Firestore');
  }

  @override
  Query<Map<String, dynamic>> collectionGroup(String path) {
    calls++;
    throw StateError('A disabled catalogue mutation must not access Firestore');
  }
}

class _FirebaseUser extends Fake implements fba.User {}

class _LoginService extends Fake implements LoginService {
  @override
  AuthStatus getAuthStatus() => AuthStatus.loggedIn;
  @override
  fba.User get fbaUser => _FirebaseUser();
}

class _ProfileQueryProbe extends Fake implements FirebaseFirestore {
  final FirebaseFirestore delegate;
  final paths = <String>[];
  int directReads = 0;
  _ProfileQueryProbe(this.delegate);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    paths.add(path);
    if (path != 'publicProfiles') throw StateError('Legacy read forbidden');
    return _PublicProfileCollection(delegate.collection(path), this);
  }
}

// Test double intercepts forbidden direct gets; queries delegate to the fake.
// ignore: subtype_of_sealed_class
class _PublicProfileCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> delegate;
  final _ProfileQueryProbe probe;
  _PublicProfileCollection(this.delegate, this.probe);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      return Function.apply(
        delegate.where,
        invocation.positionalArguments,
        invocation.namedArguments,
      );
    }
    if (invocation.memberName == #doc) return _DeniedPublicDocument(probe);
    return super.noSuchMethod(invocation);
  }
}

// ignore: subtype_of_sealed_class
class _DeniedPublicDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _ProfileQueryProbe probe;
  _DeniedPublicDocument(this.probe);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    probe.directReads++;
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  final config = AppConfig.instance;
  const publicMarker = {'visibility': 'public', 'schemaVersion': 1};
  const profile = {
    'id': 'artist',
    'name': 'Public Artist',
    'slug': 'public-artist',
    'searchName': 'public artist',
    'directoryVisible': true,
    'showPhone': false,
    'type': 'appArtist',
  };
  const post = {
    'ownerId': 'artist',
    'caption': 'Public Post',
    'slug': 'public-post',
    'type': 'caption',
    'createdTime': 20,
    'lastInteraction': 20,
    'isPrivate': false,
    'isDraft': false,
    'isHidden': false,
    'isScheduled': false,
    'likeCount': 2,
    'commentCount': 1,
  };
  const release = {
    'name': 'Public Release',
    'slug': 'public-release',
    'ownerName': 'Public Artist',
    'ownerProfileId': 'artist',
    'ownerSlug': 'public-artist',
    'status': 'publish',
    'isSuspended': false,
    'createdTime': 20,
    'type': 'single',
    'categories': ['rock'],
    'language': 'es',
  };
  const media = {
    'id': 'track',
    'name': 'Public Track',
    'ownerId': 'artist',
    'type': 'song',
    'isSuspended': false,
  };
  const playlist = {
    'name': 'Public Playlist',
    'slug': 'public-playlist',
    'ownerId': 'artist',
    'ownerName': 'Public Artist',
    'ownerSlug': 'public-artist',
    'ownerType': 'profile',
    'public': true,
    'type': 'playlist',
    'appReleaseItemIds': ['release', 'legacy-release'],
    'appMediaItemIds': ['track', 'legacy-track'],
  };

  setUp(() async {
    Sint.reset();
    config.appInUse = AppInUse.g;
    config.isGuestMode = true;
    ProfileFirestore.invalidateAllProfilesCache();
    AppReleaseItemFirestore.invalidateAllReleaseItemsCache();
    firestore = FakeFirebaseFirestore();
    await firestore.doc('users/legacy-account/profiles/legacy-artist').set({
      ...profile,
      'id': 'legacy-artist',
      'name': 'Legacy Artist',
      'email': 'private@example.invalid',
    });
    await firestore.doc('posts/legacy-post').set({
      ...post,
      'caption': 'Legacy Post',
    });
    await firestore.doc('appReleaseItems/legacy-release').set({
      ...release,
      'name': 'Legacy Release',
    });
    await firestore.doc('appMediaItems/legacy-track').set({
      ...media,
      'name': 'Legacy Track',
    });
    await firestore.doc('itemlists/legacy-list').set({
      ...playlist,
      'name': 'Legacy Playlist',
    });
  });

  tearDown(() {
    Sint.reset();
    config.isGuestMode = true;
    config.appInUse = AppInUse.o;
    ProfileFirestore.invalidateAllProfilesCache();
    AppReleaseItemFirestore.invalidateAllReleaseItemsCache();
  });

  Future<void> seedPublic() async {
    await firestore.doc('publicProfiles/artist').set({
      ...profile,
      ...publicMarker,
    });
    await firestore.doc('publicPosts/post').set({...post, ...publicMarker});
    await firestore.doc('publicAppReleaseItems/release').set({
      ...release,
      ...publicMarker,
    });
    await firestore.doc('publicAppMediaItems/track').set({
      ...media,
      ...publicMarker,
    });
    await firestore.doc('publicItemlists/list').set({
      ...playlist,
      ...publicMarker,
    });
    await firestore.doc('publicPosts/blog').set({
      ...post,
      ...publicMarker,
      'type': 'blogEntry',
      'slug': 'public-blog',
    });
  }

  void signIn() {
    config.isGuestMode = false;
    Sint.put<LoginService>(_LoginService());
    Sint.put<UserService>(_UserService());
  }

  test('Gigmeout catalogue source is public regardless of authentication', () {
    for (final app in AppInUse.values) {
      expect(
        PublicCatalogReadPolicy.usesPublicCatalog(
          app: app,
          canPersistUserActivity: false,
        ),
        app == AppInUse.g,
      );
      expect(
        PublicCatalogReadPolicy.usesPublicCatalog(
          app: app,
          canPersistUserActivity: true,
        ),
        app == AppInUse.g,
      );
    }
  });

  test(
    'empty public collections never fall back to populated legacy data',
    () async {
      final profiles = ProfileFirestore(firestore: firestore);
      expect(await profiles.retrieveAllProfiles(), isEmpty);
      expect((await profiles.retrieve('legacy-artist')).id, isEmpty);
      expect(await profiles.retrieveByUserId('legacy-account'), isEmpty);
      expect(await profiles.getByEmail('private@example.invalid'), isNull);
      expect(await profiles.retrievedFcmToken('legacy-artist'), isEmpty);
      expect((await profiles.retrieveFull('legacy-artist')).id, isEmpty);
      expect(
        await PostFirestore(firestore: firestore).retrievePosts(),
        isEmpty,
      );
      expect(
        await AppReleaseItemFirestore(firestore: firestore).retrieveAll(),
        isEmpty,
      );
      expect(
        await AppMediaItemFirestore(firestore: firestore).fetchAll(),
        isEmpty,
      );
      expect(await ItemlistFirestore(firestore: firestore).fetchAll(), isEmpty);
    },
  );

  test('all five list surfaces select only valid public schema', () async {
    await seedPublic();
    for (final entry in <String, Map<String, dynamic>>{
      'publicProfiles': profile,
      'publicPosts': post,
      'publicAppReleaseItems': release,
      'publicAppMediaItems': media,
      'publicItemlists': playlist,
    }.entries) {
      await firestore.doc('${entry.key}/missing-marker').set(entry.value);
      await firestore.doc('${entry.key}/wrong-version').set({
        ...entry.value,
        'visibility': 'public',
        'schemaVersion': 2,
      });
      await firestore.doc('${entry.key}/private').set({
        ...entry.value,
        'visibility': 'private',
        'schemaVersion': 1,
      });
    }
    expect(
      (await ProfileFirestore(firestore: firestore).retrieveAllProfiles()).keys,
      ['artist'],
    );
    expect(
      (await PostFirestore(
        firestore: firestore,
      ).retrievePosts()).map((p) => p.id),
      unorderedEquals(['post', 'blog']),
    );
    expect(
      (await AppReleaseItemFirestore(firestore: firestore).retrieveAll()).keys,
      ['release'],
    );
    expect(
      (await AppMediaItemFirestore(firestore: firestore).fetchAll()).keys,
      ['track'],
    );
    expect((await ItemlistFirestore(firestore: firestore).fetchAll()).keys, [
      'list',
    ]);
  });

  test('profile id, slug, search and feature APIs stay public', () async {
    await seedPublic();
    final repo = ProfileFirestore(firestore: firestore);
    expect((await repo.retrieve('artist')).name, 'Public Artist');
    expect((await repo.retrieveSimple('public-artist'))?.id, 'artist');
    expect((await repo.getBySlug('public-artist'))?.id, 'artist');
    expect((await repo.searchByName('public')).map((p) => p.id), ['artist']);
    expect((await repo.retrieveFromList(['artist', 'legacy-artist'])).keys, [
      'artist',
    ]);
    expect(
      (await repo.getProfileFeatures(AppProfile(id: 'artist'))).email,
      isEmpty,
    );
    expect(await repo.getFollowers('artist'), isEmpty);
    expect(await repo.getFollowed('artist'), isEmpty);
  });

  test(
    'slug lookup uses public queries when nonexistent direct get is denied',
    () async {
      await seedPublic();
      final probe = _ProfileQueryProbe(firestore);
      await expectLater(
        probe.collection('publicProfiles').doc('public-artist').get(),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      final repo = ProfileFirestore(firestore: probe);
      expect((await repo.retrieve('public-artist')).id, 'artist');
      expect((await repo.retrieveSimple('public-artist'))?.id, 'artist');
      expect((await repo.retrieve('artist')).id, 'artist');
      expect((await repo.retrieve('missing-public-profile')).id, isEmpty);
      expect(
        probe.directReads,
        1,
        reason: 'Only the explicit denied probe may call get',
      );
      expect(probe.paths.every((path) => path == 'publicProfiles'), isTrue);
    },
  );

  test('direct reads reject unversioned public documents', () async {
    await firestore.doc('publicProfiles/invalid').set(profile);
    await firestore.doc('publicPosts/invalid').set(post);
    await firestore.doc('publicAppReleaseItems/invalid').set(release);
    await firestore.doc('publicAppMediaItems/invalid').set(media);
    await firestore.doc('publicItemlists/invalid').set(playlist);
    expect(
      (await ProfileFirestore(firestore: firestore).retrieve('invalid')).id,
      isEmpty,
    );
    expect(
      (await PostFirestore(firestore: firestore).retrieve('invalid')).id,
      isEmpty,
    );
    expect(
      (await AppReleaseItemFirestore(
        firestore: firestore,
      ).retrieve('invalid')).id,
      isEmpty,
    );
    expect(
      (await AppMediaItemFirestore(
        firestore: firestore,
      ).retrieve('invalid')).id,
      isEmpty,
    );
    expect(
      (await ItemlistFirestore(firestore: firestore).retrieve('invalid')).id,
      isEmpty,
    );
    expect(
      await AppReleaseItemFirestore(
        firestore: firestore,
      ).retrieveByOwner('private@example.invalid'),
      isEmpty,
    );
  });

  test('post timelines, profile feed, blog and slug use public data', () async {
    await seedPublic();
    final repo = PostFirestore(firestore: firestore);
    expect((await repo.retrieve('post')).caption, 'Public Post');
    expect((await repo.getBySlug('public-post'))?.id, 'post');
    expect((await repo.getTimeline()).keys, unorderedEquals(['post', 'blog']));
    expect(
      (await repo.getProfilePosts('artist')).map((p) => p.id),
      unorderedEquals(['post', 'blog']),
    );
    expect(
      (await repo.getCommunityBlogEntries(authorId: 'artist')).map((p) => p.id),
      ['blog'],
    );
    expect(
      (await repo.getCommunityBlogEntriesStream().first).map((p) => p.id),
      ['blog'],
    );
    final diverse = await PostFirestore(
      firestore: firestore,
    ).getDiverseTimeline();
    expect(diverse.keys, unorderedEquals(['post', 'blog']));
    expect((await repo.retrievePostForEvent('event')).id, isEmpty);
  });

  test(
    'release and media details and owner queries never use legacy',
    () async {
      await seedPublic();
      final repo = AppReleaseItemFirestore(firestore: firestore);
      expect((await repo.retrieve('release')).name, 'Public Release');
      expect((await repo.getBySlug('public-release'))?.id, 'release');
      expect(
        (await repo.getByOwnerAndSlug('public-artist', 'public-release'))?.id,
        'release',
      );
      expect((await repo.retrieveByOwnerProfileId('artist')).keys, ['release']);
      expect((await repo.retrieveByOwnerSlug('public-artist')).keys, [
        'release',
      ]);
      expect((await repo.retrieveByCategory('rock')).keys, ['release']);
      expect((await repo.retrieveByLanguage('es')).keys, ['release']);
      expect(
        (await repo.retrieveFromList(['release', 'legacy-release'])).keys,
        ['release'],
      );
      final mediaRepo = AppMediaItemFirestore(firestore: firestore);
      expect((await mediaRepo.retrieve('track')).name, 'Public Track');
      expect(await mediaRepo.exists('legacy-track'), isFalse);
      expect(
        (await mediaRepo.retrieveFromList(['track', 'legacy-track'])).keys,
        ['track'],
      );
    },
  );

  test(
    'public playlists hydrate IDs exclusively from public catalogues',
    () async {
      await seedPublic();
      final repo = ItemlistFirestore(firestore: firestore);
      final list = await repo.retrieve('list');
      expect(list.appReleaseItems?.map((item) => item.id), ['release']);
      expect(list.appMediaItems?.map((item) => item.id), ['track']);
      expect(
        (await repo.getBySlug('public-playlist'))?.appReleaseItems?.single.id,
        'release',
      );
      expect(
        (await repo.getByOwnerAndSlug(
          'public-artist',
          'public-playlist',
        ))?.appMediaItems?.single.id,
        'track',
      );
      expect((await repo.getByOwnerId('artist')).keys, ['list']);
    },
  );

  test('guest mutation APIs cannot write legacy or public documents', () async {
    await seedPublic();
    final before = firestore.dump();
    expect(
      await ProfileFirestore(
        firestore: firestore,
      ).insert('legacy-account', AppProfile(name: 'No')),
      isEmpty,
    );
    expect(
      await ProfileFirestore(firestore: firestore).updateName('artist', 'No'),
      isFalse,
    );
    expect(
      await PostFirestore(firestore: firestore).insert(Post(caption: 'No')),
      isEmpty,
    );
    await AppMediaItemFirestore(
      firestore: firestore,
    ).insert(AppMediaItem(id: 'no'));
    expect(
      await AppMediaItemFirestore(
        firestore: firestore,
      ).remove(AppMediaItem(id: 'track')),
      isFalse,
    );
    expect(
      await ItemlistFirestore(
        firestore: firestore,
      ).insert(Itemlist(name: 'No')),
      isEmpty,
    );
    expect(
      await ItemlistFirestore(firestore: firestore).delete('list'),
      isFalse,
    );
    expect(firestore.dump(), before);
  });

  test(
    'sign-in retains public catalogue reads without replacing the authenticated profile',
    () async {
      await seedPublic();
      final releases = AppReleaseItemFirestore(firestore: firestore);
      expect((await releases.retrieveAll()).keys, ['release']);
      signIn();
      final ownProfile = Sint.find<UserService>().profile;
      expect(config.isGuestMode, isFalse);
      expect(config.canPersistUserActivity, isTrue);
      expect(PublicCatalogReadPolicy.canWriteLegacyCatalog, isFalse);
      expect((await releases.retrieveAll()).keys, ['release']);
      expect(
        (await PostFirestore(
          firestore: firestore,
        ).retrievePosts()).map((post) => post.id),
        unorderedEquals(['post', 'blog']),
      );
      expect(
        (await ProfileFirestore(firestore: firestore).retrieve('artist')).name,
        'Public Artist',
      );
      expect(
        (await ProfileFirestore(
          firestore: firestore,
        ).retrieve('legacy-artist')).id,
        isEmpty,
      );
      expect((await ItemlistFirestore(firestore: firestore).fetchAll()).keys, [
        'list',
      ]);
      expect(
        (await AppMediaItemFirestore(firestore: firestore).fetchAll()).keys,
        ['track'],
      );
      final list = await ItemlistFirestore(
        firestore: firestore,
      ).retrieve('list');
      expect(list.appReleaseItems?.single.id, 'release');
      expect(list.appMediaItems?.single.id, 'track');
      expect(identical(Sint.find<UserService>().profile, ownProfile), isTrue);
      expect(ownProfile.id, 'own-profile');
      expect(ownProfile.name, 'Account owner');
      config.isGuestMode = true;
      expect((await releases.retrieveAll()).keys, ['release']);
    },
  );

  test(
    'authenticated Gigmeout directory never reuses a legacy profile cache',
    () async {
      await seedPublic();
      signIn();
      final profiles = ProfileFirestore(firestore: firestore);
      config.appInUse = AppInUse.e;
      expect((await profiles.retrieveAllProfiles()).keys, ['legacy-artist']);

      config.appInUse = AppInUse.g;
      expect((await profiles.retrieveAllProfiles()).keys, ['artist']);
      expect(config.canPersistUserActivity, isTrue);
      expect(config.isGuestMode, isFalse);

      config.isGuestMode = true;
      expect((await profiles.retrieveAllProfiles()).keys, ['artist']);
    },
  );

  test(
    'authenticated Gigmeout catalogue mutations never attempt Firestore access',
    () async {
      signIn();
      expect(config.canPersistUserActivity, isTrue);
      final noAccess = _NoCatalogueAccess();
      final posts = PostFirestore(firestore: noAccess);
      expect(await posts.insert(Post(id: 'post')), isEmpty);
      expect(await posts.handleLikePost('own-profile', 'post', false), isFalse);
      expect(await posts.updateFields('post', {'caption': 'changed'}), isFalse);
      expect(await posts.remove('own-profile', 'post'), isFalse);
      await posts.updateAllPostsLastInteraction();
      final releases = AppReleaseItemFirestore(firestore: noAccess);
      expect(await releases.insert(AppReleaseItem(id: 'release')), isEmpty);
      expect(
        await releases.updateFields('release', {'name': 'changed'}),
        isFalse,
      );
      expect(await releases.remove(AppReleaseItem(id: 'release')), isFalse);
      expect(
        await releases.addBoughtUser(
          releaseItemId: 'release',
          userId: 'own-profile',
        ),
        isFalse,
      );
      expect(await releases.incrementPageView('release', 1), isFalse);
      await releases.existsOrInsert(AppReleaseItem(id: 'release'));
      expect(
        await ProfileFirestore(
          firestore: noAccess,
        ).updateName('artist', 'changed'),
        isFalse,
      );
      await AppMediaItemFirestore(
        firestore: noAccess,
      ).insert(AppMediaItem(id: 'track'));
      expect(
        await ItemlistFirestore(firestore: noAccess).delete('list'),
        isFalse,
      );
      expect(noAccess.calls, 0);
      expect(config.canPersistUserActivity, isTrue);
      expect(config.isGuestMode, isFalse);
    },
  );

  test(
    'other authenticated apps retain their legacy collection and write capability',
    () async {
      config.appInUse = AppInUse.e;
      signIn();
      expect(PublicCatalogReadPolicy.enabled, isFalse);
      expect(PublicCatalogReadPolicy.canWriteLegacyCatalog, isTrue);
      expect(
        (await PostFirestore(firestore: firestore).retrievePosts()).single.id,
        'legacy-post',
      );
      expect(
        (await AppReleaseItemFirestore(
          firestore: firestore,
        ).retrieveAll()).keys,
        ['legacy-release'],
      );
      expect(
        (await ProfileFirestore(
          firestore: firestore,
        ).retrieve('legacy-artist')).name,
        'Legacy Artist',
      );
    },
  );

  test(
    'EMXI/other guest apps keep their existing collection routing',
    () async {
      config.appInUse = AppInUse.e;
      expect(
        (await AppReleaseItemFirestore(
          firestore: firestore,
        ).retrieveAll()).keys,
        ['legacy-release'],
      );
      expect(
        (await PostFirestore(firestore: firestore).retrievePosts()).single.id,
        'legacy-post',
      );
      expect(
        (await ProfileFirestore(
          firestore: firestore,
        ).retrieveAllProfiles()).keys,
        ['legacy-artist'],
      );
      expect((await ItemlistFirestore(firestore: firestore).fetchAll()).keys, [
        'legacy-list',
      ]);
      expect(
        (await AppMediaItemFirestore(firestore: firestore).fetchAll()).keys,
        ['legacy-track'],
      );
    },
  );
}
