// Tests for `PostComment`.
//
// Posibles bugs en fromJSON: NC-23 (type sin fallback string),
// NC-24 (postOwnerId/mediaUrl/createdTime/replies sin null safety).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/post_comment.dart';
import 'package:neom_core/utils/enums/app_media_type.dart';

void main() {
  group('PostComment — constructor (campos required)', () {
    test('crea con required positivos', () {
      final c = PostComment(
        postOwnerId: 'po1',
        text: 'comentario',
        postId: 'p1',
        ownerId: 'u1',
        ownerImgUrl: 'https://x',
        ownerName: 'Ana',
        createdTime: 1700000000000,
      );
      expect(c.id, '');
      expect(c.postOwnerId, 'po1');
      expect(c.text, 'comentario');
      expect(c.postId, 'p1');
      expect(c.ownerId, 'u1');
      expect(c.ownerName, 'Ana');
      expect(c.createdTime, 1700000000000);
      expect(c.type, AppMediaType.text);
      expect(c.replies, isEmpty);
      expect(c.likedProfiles, isEmpty);
      expect(c.isHidden, isFalse);
      expect(c.modifiedTime, 0);
      expect(c.mediaUrl, '');
    });
  });

  group('PostComment — toJSON', () {
    test('contiene 13 llaves', () {
      final json = PostComment(
        postOwnerId: 'po', text: 't', postId: 'p',
        ownerId: 'u', ownerImgUrl: '', ownerName: '',
        createdTime: 0,
      ).toJSON();
      expect(
        json.keys,
        containsAll([
          'text', 'likedProfiles', 'type', 'isHidden',
          'ownerId', 'ownerImgUrl', 'ownerName', 'postOwnerId',
          'mediaUrl', 'createdTime', 'modifiedTime', 'replies', 'postId',
        ]),
      );
    });

    test('NO incluye id (Firebase docId)', () {
      final c = PostComment(
        id: 'c1',
        postOwnerId: 'po', text: 't', postId: 'p',
        ownerId: 'u', ownerImgUrl: '', ownerName: '',
        createdTime: 0,
      );
      expect(c.toJSON().containsKey('id'), isFalse);
    });

    test('type serializa como string (.name)', () {
      final c = PostComment(
        postOwnerId: 'po', text: 't', postId: 'p',
        ownerId: 'u', ownerImgUrl: '', ownerName: '',
        createdTime: 0, type: AppMediaType.text,
      );
      expect(c.toJSON()['type'], 'text');
    });
  });

  group('PostComment — fromJSON (puede revelar NC-23 y NC-24)', () {
    test('round-trip con todos los campos completos', () {
      final original = PostComment(
        postOwnerId: 'po1',
        text: 'reply',
        postId: 'p1',
        ownerId: 'u1',
        ownerImgUrl: 'https://x',
        ownerName: 'Ana',
        createdTime: 1700000000000,
        modifiedTime: 1700000001000,
        type: AppMediaType.text,
        likedProfiles: ['u2'],
        isHidden: false,
        mediaUrl: '',
      );
      final json = {
        ...original.toJSON(),
        'replies': <Map<String, dynamic>>[],
      };
      final restored = PostComment.fromJSON(json);

      expect(restored.text, original.text);
      expect(restored.postOwnerId, original.postOwnerId);
      expect(restored.postId, original.postId);
      expect(restored.ownerId, original.ownerId);
      expect(restored.ownerName, original.ownerName);
      expect(restored.createdTime, original.createdTime);
      expect(restored.modifiedTime, original.modifiedTime);
      expect(restored.type, original.type);
      expect(restored.likedProfiles, original.likedProfiles);
      expect(restored.isHidden, original.isHidden);
    });

    test('NC-23/NC-24: mapa vacío no debería crashear', () {
      // Bug múltiple: postOwnerId, mediaUrl, createdTime, modifiedTime
      // sin null check; replies con `.map` directo (crash si null).
      try {
        final c = PostComment.fromJSON(<String, dynamic>{});
        // Si pasa, queremos defaults razonables
        expect(c.text, '');
        expect(c.type, AppMediaType.text);
      } on Object catch (e) {
        fail('NC-23/NC-24: PostComment.fromJSON con mapa vacío crashea: $e');
      }
    });

    test('NC-24: replies null no debería crashear', () {
      try {
        final c = PostComment.fromJSON({
          'text': 't',
          'postOwnerId': 'po',
          'mediaUrl': '',
          'createdTime': 0,
          'modifiedTime': 0,
          'replies': null,
        });
        expect(c.replies, isEmpty);
      } on Object catch (e) {
        fail('NC-24: replies null crashea fromJSON. $e');
      }
    });
  });
}
