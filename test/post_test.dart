// Tests for `Post` — modelo de feed/timeline.
//
// Foco: defaults, generateSlug (utility), toJSON omite id, round-trip de
// campos básicos sin tocar `position` (depende de Position+Geolocator y
// jsonEncode que requeriría setup adicional). createClone también cubierto.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/enums/post_type.dart';
import 'package:neom_core/utils/enums/verification_level.dart';

void main() {
  group('Post — defaults', () {
    test('constructor sin params', () {
      final p = Post();
      expect(p.id, '');
      expect(p.ownerId, '');
      expect(p.profileName, '');
      expect(p.caption, '');
      expect(p.type, PostType.caption);
      expect(p.mediaUrl, '');
      expect(p.thumbnailUrl, '');
      expect(p.externalUrl, '');
      expect(p.likedProfiles, isEmpty);
      expect(p.sharedProfiles, isEmpty);
      expect(p.savedByProfiles, isEmpty);
      expect(p.mentionedProfiles, isEmpty);
      expect(p.hashtags, isEmpty);
      expect(p.commentIds, isEmpty);
      expect(p.comments, isEmpty);
      expect(p.isCommentEnabled, isTrue);
      expect(p.isPrivate, isFalse);
      expect(p.isDraft, isFalse);
      expect(p.isHidden, isFalse);
      expect(p.isScheduled, isFalse);
      expect(p.isEdited, isFalse);
      expect(p.aspectRatio, 1);
      expect(p.slug, '');
      expect(p.originalPostId, isNull);
      expect(p.scheduledTime, isNull);
    });
  });

  group('Post.generateSlug', () {
    test('caption simple → slug en kebab-case', () {
      expect(Post.generateSlug('Hola Mundo'), 'hola-mundo');
    });

    test('multiples espacios consecutivos colapsan a un guión', () {
      expect(Post.generateSlug('hola    mundo'), 'hola-mundo');
    });

    test('preserva acentos y ñ', () {
      expect(Post.generateSlug('niño año mañana'), 'niño-año-mañana');
    });

    test('elimina caracteres especiales (no alfanuméricos)', () {
      expect(Post.generateSlug('hola!@#mundo\$%'), 'holamundo');
    });

    test('limita a 50 chars', () {
      final long = 'palabra ' * 20; // ~160 chars
      final slug = Post.generateSlug(long);
      expect(slug.length, lessThanOrEqualTo(50));
    });

    test('caption vacío produce slug vacío', () {
      expect(Post.generateSlug(''), '');
    });

    test('caption con solo símbolos produce slug vacío', () {
      expect(Post.generateSlug('!@#\$%^&*()'), '');
    });
  });

  group('Post — toJSON', () {
    test('NO incluye id (Firebase docId)', () {
      final p = Post(id: 'p1');
      expect(p.toJSON().containsKey('id'), isFalse);
    });

    test('type se serializa como string (.name)', () {
      final p = Post(type: PostType.caption);
      expect(p.toJSON()['type'], 'caption');
    });

    test('verificationLevel null serializa como null', () {
      final p = Post();
      expect(p.toJSON()['verificationLevel'], isNull);
    });

    test('verificationLevel se serializa como string cuando hay valor', () {
      final p = Post(verificationLevel: VerificationLevel.none);
      expect(p.toJSON()['verificationLevel'], 'none');
    });
  });

  group('Post — round-trip básico', () {
    test('campos string + bool + listas se preservan', () {
      final original = Post(
        id: 'p1',
        ownerId: 'u1',
        profileName: 'Ana',
        profileImgUrl: 'https://x',
        caption: '¡Hola!',
        type: PostType.caption,
        mediaUrl: 'https://m',
        thumbnailUrl: 'https://t',
        externalUrl: 'https://ext',
        createdTime: 1700000000000,
        modifiedTime: 1700000001000,
        location: 'CDMX',
        likedProfiles: ['u2', 'u3'],
        sharedProfiles: ['u4'],
        savedByProfiles: ['u5'],
        mentionedProfiles: ['u6'],
        hashtags: ['music', 'live'],
        commentIds: ['c1', 'c2'],
        isCommentEnabled: false,
        isPrivate: true,
        isDraft: false,
        isHidden: false,
        mediaOwner: 'mo',
        referenceId: 'ref',
        lastInteraction: 1700000002000,
        aspectRatio: 1.5,
        textStyleId: 'style1',
        slug: 'hola-mundo',
        isScheduled: true,
        isEdited: true,
      );

      // Asumimos Firestore agrega `id` al doc al cargar
      final json = {...original.toJSON(), 'id': original.id};
      final restored = Post.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.ownerId, original.ownerId);
      expect(restored.profileName, original.profileName);
      expect(restored.caption, original.caption);
      expect(restored.type, original.type);
      expect(restored.mediaUrl, original.mediaUrl);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
      expect(restored.externalUrl, original.externalUrl);
      expect(restored.createdTime, original.createdTime);
      expect(restored.modifiedTime, original.modifiedTime);
      expect(restored.location, original.location);
      expect(restored.likedProfiles, original.likedProfiles);
      expect(restored.sharedProfiles, original.sharedProfiles);
      expect(restored.savedByProfiles, original.savedByProfiles);
      expect(restored.mentionedProfiles, original.mentionedProfiles);
      expect(restored.hashtags, original.hashtags);
      expect(restored.commentIds, original.commentIds);
      expect(restored.isCommentEnabled, original.isCommentEnabled);
      expect(restored.isPrivate, original.isPrivate);
      expect(restored.isDraft, original.isDraft);
      expect(restored.isHidden, original.isHidden);
      expect(restored.mediaOwner, original.mediaOwner);
      expect(restored.referenceId, original.referenceId);
      expect(restored.lastInteraction, original.lastInteraction);
      expect(restored.aspectRatio, original.aspectRatio);
      expect(restored.textStyleId, original.textStyleId);
      expect(restored.slug, original.slug);
      expect(restored.isScheduled, original.isScheduled);
      expect(restored.isEdited, original.isEdited);
    });

    test('mapa vacío usa defaults', () {
      final p = Post.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.type, PostType.caption);
      expect(p.likedProfiles, isEmpty);
      expect(p.isCommentEnabled, isTrue);
      expect(p.isPrivate, isFalse);
      expect(p.aspectRatio, 1);
    });

    test('campos null se ignoran (defaults)', () {
      final p = Post.fromJSON({
        'caption': null,
        'type': null,
        'isCommentEnabled': null,
        'aspectRatio': null,
      });
      expect(p.caption, '');
      expect(p.type, PostType.caption);
      expect(p.isCommentEnabled, isTrue);
      expect(p.aspectRatio, 1);
    });

    test('repost fields null cuando no es repost', () {
      final p = Post();
      final restored = Post.fromJSON(p.toJSON());
      expect(restored.originalPostId, isNull);
      expect(restored.originalOwnerId, isNull);
    });

    test('repost fields se preservan cuando hay repost', () {
      final p = Post(
        originalPostId: 'orig_p1',
        originalOwnerId: 'orig_u1',
      );
      final restored = Post.fromJSON(p.toJSON());
      expect(restored.originalPostId, 'orig_p1');
      expect(restored.originalOwnerId, 'orig_u1');
    });
  });

  group('Post.createClone', () {
    test('preserva todos los campos primitivos', () {
      final original = Post(
        id: 'p1',
        ownerId: 'u1',
        caption: 'hola',
        type: PostType.caption,
        isCommentEnabled: false,
        isPrivate: true,
        aspectRatio: 1.5,
        slug: 'hola',
      );
      final clone = Post.createClone(original);
      expect(clone.id, original.id);
      expect(clone.ownerId, original.ownerId);
      expect(clone.caption, original.caption);
      expect(clone.type, original.type);
      expect(clone.isCommentEnabled, original.isCommentEnabled);
      expect(clone.isPrivate, original.isPrivate);
      expect(clone.aspectRatio, original.aspectRatio);
      expect(clone.slug, original.slug);
    });

    test('OBS: createClone NO clona listas en profundidad', () {
      // Las listas se comparten por referencia. Esto es comportamiento
      // actual — se documenta para que un cambio futuro no rompa la API
      // sin que el equipo lo note.
      final original = Post(likedProfiles: ['u1']);
      final clone = Post.createClone(original);
      expect(identical(clone.likedProfiles, original.likedProfiles), isTrue,
          reason: 'lista compartida por referencia — modificar el clon '
              'afecta al original');
    });
  });
}
