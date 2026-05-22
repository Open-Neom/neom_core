// Tests for `CommentReply` domain model.
//
// Foco: constructor con defaults, toString legible, JSON round-trip,
// y serialización del enum AppMediaType (que viaja como string vía .name).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/comment_reply.dart';
import 'package:neom_core/utils/enums/app_media_type.dart';

void main() {
  group('CommentReply — defaults del constructor', () {
    test('todos los campos opcionales tienen valores por defecto', () {
      final r = CommentReply();
      expect(r.id, '');
      expect(r.profileId, '');
      expect(r.text, '');
      expect(r.likeCount, 0);
      expect(r.mediaType, isNull);
      expect(r.isHidden, isFalse);
      expect(r.createdTime, 0);
      expect(r.modifiedTime, 0);
    });

    test('parámetros nombrados se asignan', () {
      final r = CommentReply(
        id: 'r1',
        profileId: 'u1',
        text: 'hello',
        likeCount: 5,
        mediaType: AppMediaType.image,
        isHidden: true,
        createdTime: 1700000000000,
        modifiedTime: 1700000001000,
      );
      expect(r.id, 'r1');
      expect(r.profileId, 'u1');
      expect(r.text, 'hello');
      expect(r.likeCount, 5);
      expect(r.mediaType, AppMediaType.image);
      expect(r.isHidden, isTrue);
      expect(r.createdTime, 1700000000000);
      expect(r.modifiedTime, 1700000001000);
    });
  });

  group('CommentReply.toString', () {
    test('contiene el id y el texto', () {
      final r = CommentReply(id: 'xyz', text: 'hello world');
      final s = r.toString();
      expect(s, contains('xyz'));
      expect(s, contains('hello world'));
    });

    test('incluye nombre de la clase', () {
      final r = CommentReply();
      expect(r.toString(), contains('CommentReply'));
    });
  });

  group('CommentReply — JSON round-trip', () {
    test('round-trip preserva todos los campos', () {
      final original = CommentReply(
        id: 'r1',
        profileId: 'u1',
        text: 'reply',
        likeCount: 3,
        mediaType: AppMediaType.image,
        isHidden: true,
        createdTime: 1700000000000,
        modifiedTime: 1700000001000,
      );

      final json = original.toJSON();
      final restored = CommentReply.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.profileId, original.profileId);
      expect(restored.text, original.text);
      expect(restored.likeCount, original.likeCount);
      expect(restored.mediaType, original.mediaType);
      expect(restored.isHidden, original.isHidden);
      expect(restored.createdTime, original.createdTime);
      expect(restored.modifiedTime, original.modifiedTime);
    });

    test('toJSON serializa mediaType como string (.name)', () {
      final r = CommentReply(mediaType: AppMediaType.image);
      final json = r.toJSON();
      expect(json['mediaType'], 'image');
    });

    test('toJSON con mediaType null serializa como cadena vacía', () {
      final r = CommentReply();
      final json = r.toJSON();
      expect(json['mediaType'], '');
    });

    test('round-trip de mediaType null → null tras deserializar', () {
      // EnumToString.fromString de "" devuelve null. Confirmamos.
      final r = CommentReply();
      final restored = CommentReply.fromJSON(r.toJSON());
      expect(restored.mediaType, isNull);
    });

    test('toJSON contiene exactamente 8 llaves', () {
      final json = CommentReply().toJSON();
      expect(json.length, 8);
      expect(json.keys, containsAll([
        'id', 'text', 'likeCount', 'mediaType',
        'isHidden', 'profileId', 'createdTime', 'modifiedTime',
      ]));
    });
  });

  group('CommentReply — escenarios límite', () {
    test('texto muy largo se preserva', () {
      final long = 'a' * 10000;
      final r = CommentReply(text: long);
      final restored = CommentReply.fromJSON(r.toJSON());
      expect(restored.text.length, 10000);
    });

    test('likeCount negativo no falla (defensivo)', () {
      // El modelo no valida — esto documenta el comportamiento actual.
      final r = CommentReply(likeCount: -1);
      expect(r.likeCount, -1);
      final restored = CommentReply.fromJSON(r.toJSON());
      expect(restored.likeCount, -1);
    });
  });
}
