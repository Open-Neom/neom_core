// Tests for `CollectiveChannel` — canales tipo Slack en collectives.
//
// Cubre: defaults, computed `roomId`, round-trip JSON, factory `defaults()`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_channel.dart';

void main() {
  group('CollectiveChannel — defaults', () {
    test('constructor sin params usa defaults', () {
      final c = CollectiveChannel();
      expect(c.id, '');
      expect(c.collectiveId, '');
      expect(c.name, 'general');
      expect(c.description, '');
      expect(c.emoji, '💬');
      expect(c.isDefault, isFalse);
      expect(c.order, 0);
      expect(c.createdAt, 0);
    });

    test('parámetros nombrados se asignan', () {
      final c = CollectiveChannel(
        id: 'ch1',
        collectiveId: 'c1',
        name: 'demos',
        description: 'demos en proceso',
        emoji: '🎵',
        isDefault: false,
        order: 2,
        createdAt: 1700000000000,
      );
      expect(c.id, 'ch1');
      expect(c.collectiveId, 'c1');
      expect(c.name, 'demos');
      expect(c.description, 'demos en proceso');
      expect(c.emoji, '🎵');
      expect(c.order, 2);
      expect(c.createdAt, 1700000000000);
    });
  });

  group('CollectiveChannel.roomId', () {
    test('combina collectiveId + id con guión bajo', () {
      final c = CollectiveChannel(id: 'ch1', collectiveId: 'col1');
      expect(c.roomId, 'col1_ch1');
    });

    test('roomId con id vacío conserva la separación', () {
      final c = CollectiveChannel(collectiveId: 'col1');
      expect(c.roomId, 'col1_');
    });

    test('roomId es estable (puro getter)', () {
      final c = CollectiveChannel(id: 'ch1', collectiveId: 'col1');
      expect(c.roomId, c.roomId);
    });
  });

  group('CollectiveChannel — round-trip', () {
    test('preserva todos los campos persistidos', () {
      final original = CollectiveChannel(
        id: 'ch1',
        collectiveId: 'col1',
        name: 'demos',
        description: 'desc',
        emoji: '🎵',
        isDefault: true,
        order: 3,
        createdAt: 1700000000000,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = CollectiveChannel.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.emoji, original.emoji);
      expect(restored.isDefault, original.isDefault);
      expect(restored.order, original.order);
      expect(restored.createdAt, original.createdAt);
    });

    test('toJSON contiene 7 llaves (id NO se serializa, va como docId)', () {
      final json = CollectiveChannel(id: 'ch1').toJSON();
      expect(json.length, 7);
      expect(json.keys, isNot(contains('id')));
    });

    test('fromJSON con mapa vacío usa defaults documentados', () {
      final c = CollectiveChannel.fromJSON(<String, dynamic>{});
      expect(c.name, 'general',
          reason: 'el default es #general');
      expect(c.emoji, '💬',
          reason: 'emoji default 💬 (chat)');
      expect(c.isDefault, isFalse);
    });
  });

  group('CollectiveChannel.defaults static', () {
    test('genera lista no vacía con channel #general', () {
      final defaults = CollectiveChannel.defaults('col1');
      expect(defaults, isNotEmpty);
      expect(defaults.first.name, 'general');
      expect(defaults.first.isDefault, isTrue);
      expect(defaults.first.collectiveId, 'col1');
    });

    test('createdAt se setea con epoch actual', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final defaults = CollectiveChannel.defaults('col1');
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(defaults.first.createdAt, greaterThanOrEqualTo(before));
      expect(defaults.first.createdAt, lessThanOrEqualTo(after));
    });

    test('emoji default es 💬 en general', () {
      final c = CollectiveChannel.defaults('any').first;
      expect(c.emoji, '💬');
    });
  });
}
