// Tests for Itemlist domain model — central to playlists/giglists/readlists.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';

void main() {
  group('Itemlist constructor defaults', () {
    test('default type is playlist', () {
      final l = Itemlist();
      expect(l.type, ItemlistType.playlist);
      expect(l.ownerType, OwnerType.profile);
      expect(l.public, isTrue);
      expect(l.isModifiable, isTrue);
    });
  });

  group('Itemlist.createBasic', () {
    test('creates list with name/desc/owner/type', () {
      final l = Itemlist.createBasic(
          'My Tunes', 'Best of', 'owner1', 'Owner', ItemlistType.album);
      expect(l.name, 'My Tunes');
      expect(l.description, 'Best of');
      expect(l.ownerId, 'owner1');
      expect(l.ownerName, 'Owner');
      expect(l.type, ItemlistType.album);
      expect(l.appMediaItems, isEmpty);
      expect(l.appReleaseItems, isEmpty);
    });
  });

  group('Itemlist.toJSON / fromJSON', () {
    test('round-trip preserves scalar fields', () {
      final l = Itemlist(
        id: 'lst_1',
        name: 'My Playlist',
        description: 'Tracks I love',
        ownerId: 'u1',
        ownerName: 'User One',
        ownerType: OwnerType.profile,
        href: 'http://h',
        imgUrl: 'http://img',
        public: false,
        isModifiable: false,
        uri: 'http://uri',
        type: ItemlistType.album,
        createdTime: 1700000000000,
        modifiedTime: 1700000999999,
        language: 'es',
        categories: ['rock', 'jazz'],
        tags: ['summer'],
        appMediaItems: [AppMediaItem(id: 'm1', name: 'Song A')],
        appReleaseItems: [AppReleaseItem(id: 'r1', name: 'Release A')],
        externalItems: [],
      );

      final json = l.toJSON();
      // toJSON doesn't include id; ensure it's not crash on encoding.
      final raw = jsonEncode(json);
      expect(raw, contains('"name":"My Playlist"'));
      expect(raw, contains('"type":"album"'));

      final r = Itemlist.fromJSON(json);
      expect(r.name, l.name);
      expect(r.description, l.description);
      expect(r.ownerId, l.ownerId);
      expect(r.ownerName, l.ownerName);
      expect(r.ownerType, OwnerType.profile);
      expect(r.public, isFalse);
      expect(r.isModifiable, isFalse);
      expect(r.type, ItemlistType.album);
      expect(r.createdTime, l.createdTime);
      expect(r.modifiedTime, l.modifiedTime);
      expect(r.language, 'es');
      expect(r.categories, l.categories);
      expect(r.tags, l.tags);
      expect(r.appMediaItems?.first.id, 'm1');
      expect(r.appReleaseItems?.first.id, 'r1');
    });

    test('fromJSON with unknown type falls back to playlist', () {
      final l = Itemlist.fromJSON({
        'type': 'definitely_not_an_enum_value',
        'uri': '',
      });
      expect(l.type, ItemlistType.playlist);
    });

    test('fromJSON with empty data uses defaults', () {
      // Note: fromJSON requires "uri" key (no ?? fallback) — document this.
      final l = Itemlist.fromJSON({'uri': ''});
      expect(l.id, '');
      expect(l.name, '');
      expect(l.public, isTrue);
      expect(l.isModifiable, isTrue);
      expect(l.type, ItemlistType.playlist);
    });
  });

  group('Itemlist.toJSONWithID', () {
    test('contains id field', () {
      final l = Itemlist(id: 'list_42', name: 'Hello', uri: '');
      // Verify toJSONWithID exists by calling it; fields should include id.
      final m = l.toJSONWithID();
      expect(m['id'], 'list_42');
    });
  });
}
