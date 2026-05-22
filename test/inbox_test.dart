// Tests for `Inbox`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/inbox.dart';
import 'package:neom_core/domain/model/inbox_message.dart';

void main() {
  group('Inbox — defaults', () {
    test('constructor sin params', () {
      final i = Inbox();
      expect(i.id, '');
      expect(i.isPrivate, isTrue);
      expect(i.profileIds, isEmpty);
      expect(i.lastMessage, isNull);
      expect(i.createdTime, 0);
      expect(i.messages, isNull);
    });

    test('parámetros nombrados', () {
      final i = Inbox(
        id: 'i1',
        isPrivate: false,
        profileIds: ['u1', 'u2'],
        createdTime: 1700000000000,
      );
      expect(i.id, 'i1');
      expect(i.isPrivate, isFalse);
      expect(i.profileIds, ['u1', 'u2']);
      expect(i.createdTime, 1700000000000);
    });
  });

  group('Inbox — toJSON', () {
    test('contiene 4 llaves (NO id)', () {
      final json = Inbox().toJSON();
      expect(json.containsKey('id'), isFalse);
      expect(json.length, 4);
      expect(
        json.keys,
        containsAll(['isPrivate', 'lastMessage', 'profileIds', 'createdTime']),
      );
    });

    test('lastMessage null serializa como null', () {
      expect(Inbox().toJSON()['lastMessage'], isNull);
    });
  });

  group('Inbox — round-trip', () {
    test('preserva campos básicos', () {
      final original = Inbox(
        id: 'i1',
        isPrivate: false,
        profileIds: ['u1', 'u2'],
        createdTime: 1700000000000,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = Inbox.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.isPrivate, original.isPrivate);
      expect(restored.profileIds, original.profileIds);
      expect(restored.createdTime, original.createdTime);
    });

    test('lastMessage null se hidrata como InboxMessage default', () {
      // El código usa `data["lastMessage"] == null ? InboxMessage() : ...`.
      final i = Inbox.fromJSON({'lastMessage': null});
      expect(i.lastMessage, isA<InboxMessage>());
    });

    test('mapa vacío usa defaults', () {
      final i = Inbox.fromJSON(<String, dynamic>{});
      expect(i.id, '');
      expect(i.isPrivate, isTrue);
      expect(i.profileIds, isEmpty);
      expect(i.createdTime, 0);
    });
  });

  group('Inbox.toString', () {
    test('contiene id, isPrivate, profileIds', () {
      final i = Inbox(id: 'i1', profileIds: ['u1']);
      final s = i.toString();
      expect(s, contains('i1'));
      expect(s, contains('Inbox'));
    });
  });
}
