import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/core_utilities.dart';
import 'package:neom_core/utils/enums/external_media_source.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';

void main() {
  group('Giglist vs Playlist semantics', () {
    test('ItemlistType.giglist is repertoire and NOT streamableAudio', () {
      expect(ItemlistType.giglist.isRepertoire, isTrue);
      expect(ItemlistType.giglist.isStreamableAudio, isFalse);
      expect(ItemlistType.playlist.isRepertoire, isFalse);
      expect(ItemlistType.playlist.isStreamableAudio, isTrue);
      expect(ItemlistType.album.isStreamableAudio, isTrue);
    });

    test('filterItemlists strictly separates giglist and playlist without mutating input', () {
      final giglist = Itemlist(id: 'g1', name: 'Rock 90s', type: ItemlistType.giglist);
      final playlist = Itemlist(id: 'p1', name: 'Favoritas', type: ItemlistType.playlist);
      final readlist = Itemlist(id: 'r1', name: 'Libros', type: ItemlistType.readlist);
      final original = [giglist, playlist, readlist];

      final onlyPlaylists = CoreUtilities.filterItemlists(original, ItemlistType.playlist);
      final onlyGiglists = CoreUtilities.filterItemlists(original, ItemlistType.giglist);

      expect(original.length, 3); // original list is never mutated
      expect(onlyPlaylists.map((e) => e.id).toList(), ['p1']);
      expect(onlyGiglists.map((e) => e.id).toList(), ['g1']);
    });

    test('Itemlist.createBasic initializes externalItems and getItem returns null safely', () {
      final list = Itemlist.createBasic('Mi Giglist', 'Repertorio', 'owner1', 'Serzen', ItemlistType.giglist);
      expect(list.externalItems, isNotNull);
      expect(list.externalItems, isEmpty);
      expect(list.getItem('non-existent'), isNull);

      list.externalItems!.add(ExternalItem(
        id: 'yt123456789',
        name: 'De Música Ligera',
        ownerName: 'Soda Stereo',
        source: ExternalSource.youtube,
      ));
      expect(list.getItem('yt123456789'), isA<ExternalItem>());
    });

    test('normalizeSongMatchKey matches across YouTube Topic and Official Video variants', () {
      final k1 = CoreUtilities.normalizeSongMatchKey(
        'Enanitos Verdes - Lamento Boliviano (Official Video)',
        'EnanitosVerdesVEVO',
      );
      final k2 = CoreUtilities.normalizeSongMatchKey(
        'Lamento Boliviano',
        'Enanitos Verdes - Topic',
      );
      expect(k1, 'lamento-boliviano::enanitosverdes');
      expect(k2, k1);
    });
  });
}
