import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';

void main() {
  test('AppReleaseItem.fromJSON safely coerces Map<dynamic, dynamic> featInternalArtists', () {
    final dynamic rawFeat = <dynamic, dynamic>{
      'artist_1': 'Serzen Montoya',
      42: 99,
    };
    final item = AppReleaseItem.fromJSON({
      'id': 'rel_1',
      'name': 'Demo Track',
      'imgUrl': '',
      'ownerName': 'Banda Gigmeout',
      'featInternalArtists': rawFeat,
    });

    expect(item.id, 'rel_1');
    expect(item.name, 'Demo Track');
    expect(item.featInternalArtists, {'artist_1': 'Serzen Montoya', '42': '99'});
  });
}
