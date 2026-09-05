import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';

/// Exercises the `ownerSlug` + `slug` lookup behind `/a/{artist}/{work}`
/// against a fake Firestore, so the query shape is verified without needing
/// real data or a deployed index.
void main() {
  late FakeFirebaseFirestore firestore;

  Future<void> seed(String id, String name, String ownerName) async {
    await firestore.collection('appReleaseItems').doc(id).set({
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'slug': AppReleaseItem.generateSlug(name),
      'ownerSlug': AppReleaseItem.generateOwnerSlug(ownerName),
    });
  }

  Future<Map<String, dynamic>?> lookup(String ownerSlug, String slug) async {
    final snap = await firestore
        .collection('appReleaseItems')
        .where('ownerSlug', isEqualTo: ownerSlug)
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  setUp(() => firestore = FakeFirebaseFirestore());

  test('resolves the release addressed by artist and work', () async {
    await seed('2444_0', 'Meretriz', 'Winterfar');

    final found = await lookup('winterfar', 'meretriz');

    expect(found, isNotNull);
    expect(found!['name'], 'Meretriz');
  });

  test('two artists sharing a title resolve to their own release', () async {
    await seed('r1', 'Piedad', 'Novus Irae');
    await seed('r2', 'Piedad', 'Winterfar');

    expect((await lookup('novus-irae', 'piedad'))!['id'], 'r1');
    expect((await lookup('winterfar', 'piedad'))!['id'], 'r2');
  });

  test('the artist alone does not match a release', () async {
    await seed('r1', 'Piedad', 'Novus Irae');

    expect(await lookup('novus-irae', ''), isNull);
  });

  test('an unknown address resolves to nothing', () async {
    await seed('r1', 'Piedad', 'Novus Irae');

    expect(await lookup('winterfar', 'meretriz'), isNull);
  });

  test('legacy releases without the new fields are not reachable by address', () async {
    // What the current database looks like: a Woo id and no slugs at all.
    await firestore.collection('appReleaseItems').doc('2444_0').set({
      'id': '2444_0', 'name': 'Meretriz', 'ownerName': 'Winterfar',
    });

    expect(await lookup('winterfar', 'meretriz'), isNull);
  });

  test('all releases of an artist share one ownerSlug', () async {
    await seed('r1', 'Meretriz', 'Winterfar');
    await seed('r2', 'Ballenicidio', 'Winterfar');

    final snap = await firestore
        .collection('appReleaseItems')
        .where('ownerSlug', isEqualTo: 'winterfar')
        .get();

    expect(snap.docs.length, 2);
  });
}
