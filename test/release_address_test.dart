import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/collective.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

/// Pins the `/a/{ownerSlug}/{slug}` addressing scheme.
///
/// The address replaces opaque ids like `/item/2419_2`. It is unique by domain
/// rule — one band per name, one release per name per artist — so the slug can
/// stay the clean title instead of being prefixed on collision.
void main() {
  group('ownerSlug', () {
    test('hyphenates a multi-word artist', () {
      expect(AppReleaseItem.generateOwnerSlug('Novus Irae'), 'novus-irae');
    });

    test('matches what Collective would generate for the same name', () {
      // The artist URL must not change the day a band is registered.
      for (final name in ['Novus Irae', 'Winterfar', 'The Outside']) {
        expect(AppReleaseItem.generateOwnerSlug(name),
            Collective.generateSlug(name),
            reason: '$name must address the same way with or without a band');
      }
    });

    test('collapses repeated whitespace', () {
      expect(AppReleaseItem.generateOwnerSlug('Novus   Irae'), 'novus-irae');
    });

    test('drops punctuation but keeps accents', () {
      expect(AppReleaseItem.generateOwnerSlug('Jemefisto!'), 'jemefisto');
      expect(AppReleaseItem.generateOwnerSlug('Piedad Anónima'), 'piedad-anónima');
    });

    test('is empty for an empty name', () {
      expect(AppReleaseItem.generateOwnerSlug(''), '');
    });
  });

  group('release slug', () {
    test('is the clean title, not prefixed with the artist', () {
      expect(AppReleaseItem.generateSlug('Meretriz'), 'meretriz');
    });

    test('two artists may share a title', () {
      // Uniqueness comes from the pair, so this collision is expected.
      expect(AppReleaseItem.generateSlug('Piedad'),
          AppReleaseItem.generateSlug('Piedad'));
    });
  });

  group('releasePath', () {
    test('builds the artist/work address', () {
      expect(
        AppRouteConstants.releasePath('2419_2',
            ownerSlug: 'winterfar', slug: 'meretriz'),
        '/a/winterfar/meretriz',
      );
    });

    test('falls back to the id while the backfill has not run', () {
      expect(AppRouteConstants.releasePath('2419_2'), '/item/2419_2');
    });

    test('falls back when only the owner is known', () {
      expect(AppRouteConstants.releasePath('2419_2', ownerSlug: 'winterfar'),
          '/item/2419_2');
    });

    test('falls back to the plain slug when the owner is missing', () {
      expect(AppRouteConstants.releasePath('2419_2', slug: 'meretriz'),
          '/item/meretriz');
    });
  });

  group('artistPath', () {
    test('is the single-segment form of the same prefix', () {
      expect(AppRouteConstants.artistPath('novus-irae'), '/a/novus-irae');
    });

    test('shares its prefix with releasePath', () {
      final artist = AppRouteConstants.artistPath('winterfar');
      final release = AppRouteConstants.releasePath('id',
          ownerSlug: 'winterfar', slug: 'meretriz');
      expect(release.startsWith('$artist/'), isTrue);
    });
  });

  group('address round-trip', () {
    test('an item addresses back to its own segments', () {
      final item = AppReleaseItem(
        id: '2419_2',
        name: 'Meretriz',
        ownerName: 'Winterfar',
      );
      item.ownerSlug = AppReleaseItem.generateOwnerSlug(item.ownerName);
      item.slug = AppReleaseItem.generateSlug(item.name);

      final path = AppRouteConstants.releasePath(item.id,
          ownerSlug: item.ownerSlug, slug: item.slug);
      final segments = Uri.parse(path).pathSegments;

      expect(segments, [AppRouteConstants.releasePrefix, 'winterfar', 'meretriz']);
      expect(segments[1], item.ownerSlug);
      expect(segments[2], item.slug);
    });

    test('serialization carries both slugs', () {
      final item = AppReleaseItem(id: 'x', name: 'Piedad', ownerName: 'Novus Irae');
      item.ownerSlug = AppReleaseItem.generateOwnerSlug(item.ownerName);
      item.slug = AppReleaseItem.generateSlug(item.name);

      final restored = AppReleaseItem.fromJSON(item.toJSON());

      expect(restored.ownerSlug, 'novus-irae');
      expect(restored.slug, 'piedad');
    });

    test('an item without slugs deserializes to empty, not null', () {
      final restored = AppReleaseItem.fromJSON(<String, dynamic>{'name': 'X'});
      expect(restored.ownerSlug, '');
      expect(restored.slug, '');
    });
  });

  group('shared link', () {
    // generateVanityUrl composes siteUrl + releasePath, so the address a user
    // pastes is the same one the resolver parses.
    String vanity(String site, String id, {String ownerSlug = '', String slug = ''}) =>
        '$site${AppRouteConstants.releasePath(id, ownerSlug: ownerSlug, slug: slug)}';

    test('a release with slugs shares as /a/{artist}/{work}', () {
      expect(
        vanity('https://gigmeout.com', '2444_0',
            ownerSlug: 'winterfar', slug: 'meretriz'),
        'https://gigmeout.com/a/winterfar/meretriz',
      );
    });

    test('a release without slugs still shares a working /item link', () {
      expect(vanity('https://gigmeout.com', '2444_0'),
          'https://gigmeout.com/item/2444_0');
    });

    test('the shared link parses back into the resolver segments', () {
      final url = vanity('https://gigmeout.com', 'x',
          ownerSlug: 'novus-irae', slug: 'piedad');
      final segments = Uri.parse(url).pathSegments;

      expect(segments.first, AppRouteConstants.releasePrefix);
      expect(segments.length, 3);
      expect(segments[1], 'novus-irae');
      expect(segments[2], 'piedad');
    });

    test('two artists sharing a title get distinct links', () {
      final a = vanity('https://gigmeout.com', 'a',
          ownerSlug: 'novus-irae', slug: 'piedad');
      final b = vanity('https://gigmeout.com', 'b',
          ownerSlug: 'winterfar', slug: 'piedad');

      expect(a, isNot(b));
    });
  });
}
