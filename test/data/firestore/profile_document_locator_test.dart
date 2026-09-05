import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/data/firestore/profile_document_locator.dart';

/// Profiles live at `users/{userId}/profiles/{profileId}`, so resolving a bare
/// profile id used to download the whole `profiles` collection group. These
/// tests pin the indexed lookup, the legacy fallback, and the memoization that
/// keeps that fallback from repeating.
void main() {
  late FakeFirebaseFirestore firestore;
  late ProfileDocumentLocator locator;

  Future<void> seedProfile(String userId, String profileId,
      {bool withIdField = true}) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .set({
      if (withIdField) 'id': profileId,
      'name': 'Profile $profileId',
    });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    locator = ProfileDocumentLocator.forTesting(firestore);
  });

  group('locate', () {
    test('resolves a profile by its indexed id field', () async {
      await seedProfile('user_a', 'profile_1');

      final reference = await locator.locate('profile_1');

      expect(reference, isNotNull);
      expect(reference!.id, 'profile_1');
      expect(reference.path, 'users/user_a/profiles/profile_1');
    });

    test('picks the right profile out of many', () async {
      for (int i = 0; i < 10; i++) {
        await seedProfile('user_$i', 'profile_$i');
      }

      final reference = await locator.locate('profile_7');

      expect(reference!.path, 'users/user_7/profiles/profile_7');
    });

    test('finds a legacy profile that has no id field', () async {
      await seedProfile('user_a', 'legacy_1', withIdField: false);

      final reference = await locator.locate('legacy_1');

      expect(reference, isNotNull);
      expect(reference!.id, 'legacy_1');
    });

    test('returns null for an unknown profile', () async {
      await seedProfile('user_a', 'profile_1');

      expect(await locator.locate('nope'), isNull);
    });

    test('returns null for an empty id without querying', () async {
      expect(await locator.locate(''), isNull);
      expect(locator.cachedCount, 0);
    });

    test('a miss is not memoized', () async {
      await locator.locate('nope');

      expect(locator.cachedCount, 0);
    });
  });

  group('memoization', () {
    test('a resolved reference is cached', () async {
      await seedProfile('user_a', 'profile_1');

      await locator.locate('profile_1');
      expect(locator.cachedCount, 1);

      await locator.locate('profile_1');
      expect(locator.cachedCount, 1);
    });

    test('the cached reference survives the document being deleted', () async {
      await seedProfile('user_a', 'profile_1');
      final first = await locator.locate('profile_1');

      await firestore.doc('users/user_a/profiles/profile_1').delete();
      final second = await locator.locate('profile_1');

      expect(second!.path, first!.path);
    });

    test('invalidate forgets a single profile', () async {
      await seedProfile('user_a', 'profile_1');
      await seedProfile('user_b', 'profile_2');
      await locator.locate('profile_1');
      await locator.locate('profile_2');

      locator.invalidate('profile_1');

      expect(locator.cachedCount, 1);
    });

    test('clear forgets everything', () async {
      await seedProfile('user_a', 'profile_1');
      await seedProfile('user_b', 'profile_2');
      await locator.locate('profile_1');
      await locator.locate('profile_2');

      locator.clear();

      expect(locator.cachedCount, 0);
    });
  });

  group('subcollection', () {
    test('points at the profile subcollection', () async {
      await seedProfile('user_a', 'profile_1');

      final genres = await locator.subcollection('profile_1', 'genres');

      expect(genres!.path, 'users/user_a/profiles/profile_1/genres');
    });

    test('round-trips a document written through it', () async {
      await seedProfile('user_a', 'profile_1');

      final genres = await locator.subcollection('profile_1', 'genres');
      await genres!.doc('rock').set({'name': 'rock', 'isMain': true});

      final snapshot = await genres.get();
      expect(snapshot.docs.single.id, 'rock');
    });

    test('returns null when the profile does not exist', () async {
      expect(await locator.subcollection('nope', 'genres'), isNull);
    });
  });
}
