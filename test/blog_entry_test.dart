// Tests for `BlogEntry` — entrada de blog.
//
// Cubre defaults, computed properties (roomId, isPublished, wordCount,
// estimatedReadTime), generateSlug, round-trip, createClone.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/blog_entry.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

void main() {
  group('BlogEntry — defaults', () {
    test('constructor sin params', () {
      final e = BlogEntry();
      expect(e.id, '');
      expect(e.ownerId, '');
      expect(e.title, '');
      expect(e.content, '');
      expect(e.thumbnailUrl, '');
      expect(e.hashtags, isEmpty);
      expect(e.createdTime, 0);
      expect(e.modifiedTime, 0);
      expect(e.publishedTime, 0);
      expect(e.location, '');
      expect(e.isDraft, isTrue,
          reason: 'blog nuevo arranca como draft (publishedTime=0)');
      expect(e.isHidden, isFalse);
      expect(e.isCommentEnabled, isTrue);
      expect(e.themeMode, 'dark');
      expect(e.savedByProfiles, isEmpty);
      expect(e.viewCount, 0);
      expect(e.verificationLevel, isNull);
      expect(e.legacyPostId, isNull);
      expect(e.slug, '');
    });
  });

  group('BlogEntry.roomId', () {
    test('formato "blog_{id}"', () {
      final e = BlogEntry(id: 'b1');
      expect(e.roomId, 'blog_b1');
    });

    test('id vacío produce "blog_"', () {
      expect(BlogEntry().roomId, 'blog_');
    });
  });

  group('BlogEntry.isPublished', () {
    test('false cuando isDraft', () {
      final e = BlogEntry(isDraft: true, publishedTime: 1700000000000);
      expect(e.isPublished, isFalse);
    });

    test('false cuando publishedTime == 0', () {
      final e = BlogEntry(isDraft: false, publishedTime: 0);
      expect(e.isPublished, isFalse);
    });

    test('true cuando !isDraft && publishedTime > 0', () {
      final e = BlogEntry(isDraft: false, publishedTime: 1700000000000);
      expect(e.isPublished, isTrue);
    });
  });

  group('BlogEntry.wordCount', () {
    test('contenido vacío → 0', () {
      expect(BlogEntry().wordCount, 0);
    });

    test('cuenta palabras separadas por espacios', () {
      expect(BlogEntry(content: 'hola mundo').wordCount, 2);
      expect(BlogEntry(content: 'una dos tres cuatro').wordCount, 4);
    });

    test('múltiples espacios consecutivos NO inflan el conteo', () {
      expect(BlogEntry(content: 'hola    mundo').wordCount, 2);
    });

    test('contenido con saltos de línea', () {
      expect(BlogEntry(content: 'hola\nmundo\notra').wordCount, 3);
    });

    test('contenido solo whitespace → 0', () {
      expect(BlogEntry(content: '   \n\t  ').wordCount, 0);
    });
  });

  group('BlogEntry.estimatedReadTime', () {
    test('0 palabras → "0 min"', () {
      expect(BlogEntry().estimatedReadTime, '0 min');
    });

    test('1-200 palabras → "1 min"', () {
      final e = BlogEntry(content: List.filled(150, 'palabra').join(' '));
      expect(e.estimatedReadTime, '1 min');
    });

    test('201+ palabras → 2 min (200 wpm)', () {
      final e = BlogEntry(content: List.filled(250, 'palabra').join(' '));
      expect(e.estimatedReadTime, '2 min');
    });

    test('exactamente 200 → "1 min"', () {
      final e = BlogEntry(content: List.filled(200, 'palabra').join(' '));
      expect(e.estimatedReadTime, '1 min');
    });
  });

  group('BlogEntry.generateSlug', () {
    test('título simple → kebab-case', () {
      expect(BlogEntry.generateSlug('Mi Primer Articulo'), 'mi-primer-articulo');
    });

    test('preserva acentos', () {
      expect(BlogEntry.generateSlug('Año Nuevo'), 'año-nuevo');
    });

    test('elimina símbolos', () {
      expect(BlogEntry.generateSlug('Hola! ¿Mundo?'), 'hola-mundo');
    });
  });

  group('BlogEntry — round-trip', () {
    test('campos básicos se preservan', () {
      final original = BlogEntry(
        id: 'b1',
        ownerId: 'u1',
        profileName: 'Ana',
        profileImgUrl: 'https://x',
        title: 'Mi articulo',
        content: 'contenido completo',
        thumbnailUrl: 'https://thumb',
        hashtags: ['tech', 'flutter'],
        createdTime: 1700000000000,
        modifiedTime: 1700000001000,
        publishedTime: 1700000002000,
        location: 'CDMX',
        isDraft: false,
        isHidden: false,
        isCommentEnabled: true,
        themeMode: 'sepia',
        savedByProfiles: ['u2', 'u3'],
        viewCount: 42,
        verificationLevel: VerificationLevel.none,
        slug: 'mi-articulo',
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = BlogEntry.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.ownerId, original.ownerId);
      expect(restored.profileName, original.profileName);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
      expect(restored.hashtags, original.hashtags);
      expect(restored.createdTime, original.createdTime);
      expect(restored.modifiedTime, original.modifiedTime);
      expect(restored.publishedTime, original.publishedTime);
      expect(restored.location, original.location);
      expect(restored.isDraft, original.isDraft);
      expect(restored.themeMode, original.themeMode);
      expect(restored.savedByProfiles, original.savedByProfiles);
      expect(restored.viewCount, original.viewCount);
      expect(restored.verificationLevel, original.verificationLevel);
      expect(restored.slug, original.slug);
    });

    test('legacyPostId solo se serializa si !=null (clean JSON)', () {
      final without = BlogEntry().toJSON();
      expect(without.containsKey('legacyPostId'), isFalse);

      final withLegacy = BlogEntry(legacyPostId: 'p_old').toJSON();
      expect(withLegacy['legacyPostId'], 'p_old');
    });

    test('mapa vacío usa defaults', () {
      final e = BlogEntry.fromJSON(<String, dynamic>{});
      expect(e.id, '');
      expect(e.isDraft, isTrue);
      expect(e.themeMode, 'dark');
      expect(e.viewCount, 0);
    });
  });

  group('BlogEntry.createClone', () {
    test('preserva todos los campos primitivos', () {
      final original = BlogEntry(
        id: 'b1',
        title: 'My Title',
        content: 'My content',
        viewCount: 100,
      );
      final clone = BlogEntry.createClone(original);
      expect(clone.id, original.id);
      expect(clone.title, original.title);
      expect(clone.content, original.content);
      expect(clone.viewCount, original.viewCount);
    });

    test('clona listas en profundidad (hashtags, savedByProfiles)', () {
      final original = BlogEntry(
        hashtags: ['a', 'b'],
        savedByProfiles: ['u1', 'u2'],
      );
      final clone = BlogEntry.createClone(original);
      // Modificar clon NO afecta original (deep copy)
      clone.hashtags.add('c');
      expect(original.hashtags.length, 2);
      expect(clone.hashtags.length, 3);
    });
  });
}
