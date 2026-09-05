import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';

/// Pins `/{kind}/{ownerSlug}/{slug}` — the address of an album, EP, podcast…
/// The kind names the path itself and comes from [ItemlistType], so the URL
/// explains what it points at without a lookup.
void main() {
  group('kind prefixes', () {
    test('every ItemlistType is a usable prefix', () {
      for (final type in ItemlistType.values) {
        expect(AppRouteConstants.itemlistPrefixes,
            contains(type.name.toLowerCase()),
            reason: '${type.name} must be addressable');
      }
    });

    test('a prefix maps back to its type', () {
      expect(AppRouteConstants.itemlistTypeFromPrefix('album'),
          ItemlistType.album);
      expect(AppRouteConstants.itemlistTypeFromPrefix('EP'), ItemlistType.ep);
      expect(AppRouteConstants.itemlistTypeFromPrefix('podcast'),
          ItemlistType.podcast);
    });

    test('a non-kind segment maps to nothing', () {
      // Otherwise an artist slug would be mistaken for a kind.
      expect(AppRouteConstants.itemlistTypeFromPrefix('novus-irae'), isNull);
      expect(AppRouteConstants.itemlistTypeFromPrefix('a'), isNull);
    });

    test('the release prefix is not a kind', () {
      // `/a/...` addresses tracks and artists; it must not collide.
      expect(AppRouteConstants.itemlistPrefixes,
          isNot(contains(AppRouteConstants.releasePrefix)));
    });
  });

  group('itemlistPath', () {
    test('builds a self-describing album address', () {
      expect(
        AppRouteConstants.itemlistPath(ItemlistType.album, 'id',
            ownerSlug: 'novus-irae', slug: 'letimum'),
        '/album/novus-irae/letimum',
      );
    });

    test('the kind changes the path', () {
      final ep = AppRouteConstants.itemlistPath(ItemlistType.ep, 'id',
          ownerSlug: 'novus-irae', slug: 'demos');
      final podcast = AppRouteConstants.itemlistPath(ItemlistType.podcast, 'id',
          ownerSlug: 'novus-irae', slug: 'demos');

      expect(ep, '/ep/novus-irae/demos');
      expect(podcast, '/podcast/novus-irae/demos');
    });

    test('falls back to the id route without slugs', () {
      expect(AppRouteConstants.itemlistPath(ItemlistType.album, 'abc123'),
          '${AppRouteConstants.listItems}/abc123');
    });
  });

  group('one artist, one slug everywhere', () {
    test('an album and its tracks address the same artist', () {
      const artist = 'Novus Irae';

      final albumOwner = Itemlist.generateOwnerSlug(artist);
      final trackOwner = AppReleaseItem.generateOwnerSlug(artist);
      final bandSlug = Collective.generateSlug(artist);

      expect(albumOwner, 'novus-irae');
      expect(trackOwner, albumOwner);
      expect(bandSlug, albumOwner);
    });

    test('an album and a track may share a title without colliding', () {
      // A title track is normal; the kind prefix keeps them apart.
      final album = AppRouteConstants.itemlistPath(ItemlistType.album, 'l',
          ownerSlug: 'novus-irae', slug: 'piedad');
      final track = AppRouteConstants.releasePath('t',
          ownerSlug: 'novus-irae', slug: 'piedad');

      expect(album, '/album/novus-irae/piedad');
      expect(track, '/a/novus-irae/piedad');
      expect(album, isNot(track));
    });
  });

  group('serialization', () {
    test('carries both slugs', () {
      final list = Itemlist(name: 'Letimum', ownerName: 'Novus Irae');
      list.ownerSlug = Itemlist.generateOwnerSlug(list.ownerName);
      list.slug = Itemlist.generateSlug(list.name);

      final restored = Itemlist.fromJSON(list.toJSON());

      expect(restored.ownerSlug, 'novus-irae');
      expect(restored.slug, 'letimum');
    });

    test('a list without slugs deserializes to empty', () {
      final restored = Itemlist.fromJSON(<String, dynamic>{'name': 'X'});
      expect(restored.ownerSlug, '');
      expect(restored.slug, '');
    });
  });
}
