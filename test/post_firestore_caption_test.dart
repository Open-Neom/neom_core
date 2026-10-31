import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud captions without GPS remain readable in the Blup timeline', () async {
    AppConfig.instance
      ..appInUse = AppInUse.b
      ..isGuestMode = true;
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('posts').doc('caption').set(Post(
      ownerId: 'own-profile',
      caption: 'Written on the other device without a location fix',
      createdTime: 100,
      lastInteraction: 100,
    ).toJSON());

    final timeline = await PostFirestore(firestore: firestore).getTimeline(
      forceRefresh: true,
      throwOnError: true,
    );

    expect(timeline.keys, ['caption']);
    // The shared parser represents a missing fix with its zero coordinate
    // sentinel. Reading the caption must not request reverse geocoding.
    expect(timeline['caption']!.position!.latitude, 0);
    expect(timeline['caption']!.position!.longitude, 0);
    expect(timeline['caption']!.location, isEmpty);
  });
}
