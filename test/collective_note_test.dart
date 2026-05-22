// Tests for `CollectiveNote` domain model.
//
// CollectiveNote almacena Quill Delta para wiki colaborativo. Estructura
// simple: 12 campos string/int/bool, factory fromJSON, sin enums.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_note.dart';

void main() {
  group('CollectiveNote — defaults', () {
    test('constructor sin params usa defaults', () {
      final n = CollectiveNote();
      expect(n.id, '');
      expect(n.collectiveId, '');
      expect(n.title, '');
      expect(n.contentJson, '');
      expect(n.plainText, '');
      expect(n.createdBy, '');
      expect(n.lastEditedBy, '');
      expect(n.lastEditorName, '');
      expect(n.createdAt, 0);
      expect(n.updatedAt, 0);
      expect(n.isPinned, isFalse);
      expect(n.emoji, '');
    });

    test('parámetros nombrados se asignan', () {
      final n = CollectiveNote(
        id: 'n1',
        collectiveId: 'c1',
        title: 'Roadmap Q1',
        contentJson: '{"ops":[{"insert":"hi"}]}',
        plainText: 'hi',
        createdBy: 'u1',
        lastEditedBy: 'u2',
        lastEditorName: 'Ana',
        createdAt: 1700000000000,
        updatedAt: 1700000001000,
        isPinned: true,
        emoji: '📌',
      );
      expect(n.id, 'n1');
      expect(n.collectiveId, 'c1');
      expect(n.title, 'Roadmap Q1');
      expect(n.contentJson, '{"ops":[{"insert":"hi"}]}');
      expect(n.plainText, 'hi');
      expect(n.createdBy, 'u1');
      expect(n.lastEditedBy, 'u2');
      expect(n.lastEditorName, 'Ana');
      expect(n.createdAt, 1700000000000);
      expect(n.updatedAt, 1700000001000);
      expect(n.isPinned, isTrue);
      expect(n.emoji, '📌');
    });
  });

  group('CollectiveNote — toJSON', () {
    test('contiene 11 llaves (NO incluye id, persistido como docId)', () {
      // OBS: el id NO está en toJSON — es el doc.id de Firestore.
      // Esto es por diseño en este modelo.
      final json = CollectiveNote(id: 'n1').toJSON();
      expect(json.length, 11);
      expect(json.keys, isNot(contains('id')));
      expect(json.keys, containsAll([
        'collectiveId', 'title', 'contentJson', 'plainText',
        'createdBy', 'lastEditedBy', 'lastEditorName',
        'createdAt', 'updatedAt', 'isPinned', 'emoji',
      ]));
    });
  });

  group('CollectiveNote — round-trip', () {
    test('preserva todos los campos persistidos', () {
      final original = CollectiveNote(
        id: 'n1',
        collectiveId: 'c1',
        title: 'Roadmap',
        contentJson: '{"ops":[{"insert":"texto"}]}',
        plainText: 'texto',
        createdBy: 'u1',
        lastEditedBy: 'u2',
        lastEditorName: 'Ana',
        createdAt: 1700000000000,
        updatedAt: 1700000001000,
        isPinned: true,
        emoji: '📌',
      );

      // El id se hidrata desde data['id'] separadamente — simulamos eso.
      final json = {...original.toJSON(), 'id': original.id};
      final restored = CollectiveNote.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.title, original.title);
      expect(restored.contentJson, original.contentJson);
      expect(restored.plainText, original.plainText);
      expect(restored.createdBy, original.createdBy);
      expect(restored.lastEditedBy, original.lastEditedBy);
      expect(restored.lastEditorName, original.lastEditorName);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.isPinned, original.isPinned);
      expect(restored.emoji, original.emoji);
    });

    test('fromJSON con mapa vacío usa defaults', () {
      final n = CollectiveNote.fromJSON(<String, dynamic>{});
      expect(n.id, '');
      expect(n.title, '');
      expect(n.contentJson, '');
      expect(n.isPinned, isFalse);
    });

    test('fromJSON con campos null usa defaults', () {
      final n = CollectiveNote.fromJSON({
        'title': null,
        'contentJson': null,
        'isPinned': null,
        'createdAt': null,
      });
      expect(n.title, '');
      expect(n.contentJson, '');
      expect(n.isPinned, isFalse);
      expect(n.createdAt, 0);
    });

    test('emojis Unicode multi-byte se preservan', () {
      for (final emoji in ['📌', '🎵', '🎸', '🇲🇽', '👨‍👩‍👧']) {
        final n = CollectiveNote(emoji: emoji);
        expect(CollectiveNote.fromJSON(n.toJSON()).emoji, emoji);
      }
    });

    test('JSON Delta de Quill se preserva como string', () {
      const delta = '{"ops":[{"insert":"título\\n"},'
          '{"attributes":{"bold":true},"insert":"negritas"},'
          '{"insert":"\\n"}]}';
      final n = CollectiveNote(contentJson: delta);
      expect(CollectiveNote.fromJSON(n.toJSON()).contentJson, delta);
    });
  });

  group('CollectiveNote.toString', () {
    test('contiene id, title y collectiveId', () {
      final n = CollectiveNote(
        id: 'n1',
        title: 'My Note',
        collectiveId: 'c1',
        isPinned: true,
      );
      final s = n.toString();
      expect(s, contains('n1'));
      expect(s, contains('My Note'));
      expect(s, contains('c1'));
      expect(s, contains('true'));
    });
  });
}
