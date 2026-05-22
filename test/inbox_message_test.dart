// Tests for `InboxMessage`.
//
// Posible bug NC-31: toJSON sobrescribe `createdTime` con DateTime.now() —
// mismo patrón NC-10 AppProduct.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/inbox_message.dart';
import 'package:neom_core/utils/enums/app_media_type.dart';

void main() {
  group('InboxMessage — defaults', () {
    test('constructor sin params', () {
      final m = InboxMessage();
      expect(m.id, '');
      expect(m.ownerId, '');
      expect(m.profileName, '');
      expect(m.profileImgUrl, '');
      expect(m.text, '');
      expect(m.createdTime, 0);
      expect(m.seenTime, 0);
      expect(m.type, AppMediaType.text);
      expect(m.mediaUrl, '');
      expect(m.referenceId, '');
      expect(m.audioDuration, 0);
      expect(m.likedProfiles, isEmpty);
      expect(m.isPinned, isFalse);
      expect(m.pollId, '');
    });
  });

  group('InboxMessage — toJSON (puede revelar NC-31)', () {
    test('NC-31: createdTime se sobrescribe con DateTime.now()', () {
      // Bug: línea 54 `'createdTime': DateTime.now().millisecondsSinceEpoch`
      // — ignora el campo del modelo. Mismo patrón NC-10 (AppProduct).
      final original = InboxMessage(createdTime: 1700000000000);
      final json = original.toJSON();
      expect(
        json['createdTime'],
        1700000000000,
        reason: 'NC-31: toJSON ignora `createdTime` del modelo y usa now()',
      );
    });

    test('NO incluye id (Firebase docId)', () {
      final m = InboxMessage(id: 'm1');
      expect(m.toJSON().containsKey('id'), isFalse);
    });

    test('type serializa como string (.name)', () {
      expect(InboxMessage(type: AppMediaType.text).toJSON()['type'], 'text');
    });
  });

  group('InboxMessage — round-trip', () {
    test('preserva campos string + bool + int', () {
      final original = InboxMessage(
        id: 'm1',
        ownerId: 'u1',
        profileName: 'Ana',
        profileImgUrl: 'https://x',
        text: 'Hola',
        seenTime: 1700000001000,
        type: AppMediaType.text,
        mediaUrl: 'https://media',
        referenceId: 'ref1',
        audioDuration: 5000,
        likedProfiles: ['u2'],
        isPinned: true,
        pollId: 'poll1',
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = InboxMessage.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.ownerId, original.ownerId);
      expect(restored.profileName, original.profileName);
      expect(restored.profileImgUrl, original.profileImgUrl);
      expect(restored.text, original.text);
      expect(restored.seenTime, original.seenTime);
      expect(restored.type, original.type);
      expect(restored.mediaUrl, original.mediaUrl);
      expect(restored.referenceId, original.referenceId);
      expect(restored.audioDuration, original.audioDuration);
      expect(restored.likedProfiles, original.likedProfiles);
      expect(restored.isPinned, original.isPinned);
      expect(restored.pollId, original.pollId);
    });

    test('mapa vacío usa defaults', () {
      final m = InboxMessage.fromJSON(<String, dynamic>{});
      expect(m.id, '');
      expect(m.text, '');
      expect(m.type, AppMediaType.text);
      expect(m.audioDuration, 0);
      expect(m.isPinned, isFalse);
    });

    test('type desconocido cae a text', () {
      final m = InboxMessage.fromJSON({'type': 'unknown_media_type'});
      expect(m.type, AppMediaType.text);
    });
  });
}
