// Tests for `CollectivePoll` y `PollOption`.
//
// Estructura nested: poll contiene una lista de PollOption. Tests cubren
// constructor, computed properties (totalVotes, voteCount), round-trip
// JSON con anidación, y casos límite (poll vacío, multi-opción).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_poll.dart';

void main() {
  group('PollOption — defaults y round-trip', () {
    test('constructor sin params usa defaults', () {
      final o = PollOption();
      expect(o.id, '');
      expect(o.text, '');
      expect(o.voterIds, isEmpty);
      expect(o.voteCount, 0);
    });

    test('voteCount == voterIds.length', () {
      final o = PollOption(voterIds: ['u1', 'u2', 'u3']);
      expect(o.voteCount, 3);
    });

    test('round-trip JSON preserva todos los campos', () {
      final original = PollOption(
        id: 'opt1',
        text: 'Sí',
        voterIds: ['u1', 'u2'],
      );
      final restored = PollOption.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.voterIds, original.voterIds);
      expect(restored.voteCount, 2);
    });

    test('voterIds list es independiente tras deserializar', () {
      // List<String>.from crea copia — modificar restored no afecta original.
      final original = PollOption(voterIds: ['u1']);
      final restored = PollOption.fromJSON(original.toJSON());
      restored.voterIds.add('u2');
      expect(original.voterIds.length, 1);
      expect(restored.voterIds.length, 2);
    });

    test('voterIds null en JSON ⇒ lista vacía', () {
      final o = PollOption.fromJSON({'voterIds': null});
      expect(o.voterIds, isEmpty);
    });

    test('toString contiene id, text y voteCount', () {
      final o = PollOption(id: 'o1', text: 'opción', voterIds: ['u1', 'u2']);
      final s = o.toString();
      expect(s, contains('o1'));
      expect(s, contains('opción'));
      expect(s, contains('2'));
    });
  });

  group('CollectivePoll — defaults', () {
    test('constructor sin params', () {
      final p = CollectivePoll();
      expect(p.id, '');
      expect(p.collectiveId, '');
      expect(p.question, '');
      expect(p.options, isEmpty);
      expect(p.createdBy, '');
      expect(p.creatorName, '');
      expect(p.createdAt, 0);
      expect(p.expiresAt, 0,
          reason: 'expiresAt 0 significa sin expiración');
      expect(p.isAnonymous, isFalse);
      expect(p.isMultiChoice, isFalse);
      expect(p.isClosed, isFalse);
    });
  });

  group('CollectivePoll.totalVotes', () {
    test('poll vacío tiene 0 votos', () {
      expect(CollectivePoll().totalVotes, 0);
    });

    test('suma los voteCount de cada opción', () {
      final p = CollectivePoll(options: [
        PollOption(id: 'a', voterIds: ['u1', 'u2']),
        PollOption(id: 'b', voterIds: ['u3']),
        PollOption(id: 'c', voterIds: []),
      ]);
      expect(p.totalVotes, 3);
    });

    test('cuenta correctamente con un solo votante en multi-choice', () {
      // En multi-choice, un usuario puede aparecer en varias opciones —
      // totalVotes cuenta votos no votantes únicos.
      final p = CollectivePoll(
        isMultiChoice: true,
        options: [
          PollOption(voterIds: ['u1']),
          PollOption(voterIds: ['u1']),
        ],
      );
      expect(p.totalVotes, 2);
    });
  });

  group('CollectivePoll — round-trip JSON', () {
    test('preserva campos top-level y opciones anidadas', () {
      final original = CollectivePoll(
        id: 'p1',
        collectiveId: 'c1',
        question: '¿Modo oscuro?',
        options: [
          PollOption(id: 'o1', text: 'Sí', voterIds: ['u1', 'u2']),
          PollOption(id: 'o2', text: 'No', voterIds: ['u3']),
          PollOption(id: 'o3', text: 'Ambos', voterIds: []),
        ],
        createdBy: 'u_creator',
        creatorName: 'Ana',
        createdAt: 1700000000000,
        expiresAt: 1700100000000,
        isAnonymous: true,
        isMultiChoice: true,
        isClosed: false,
      );

      final json = {...original.toJSON(), 'id': original.id};
      final restored = CollectivePoll.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.question, original.question);
      expect(restored.options.length, original.options.length);
      for (var i = 0; i < original.options.length; i++) {
        expect(restored.options[i].id, original.options[i].id);
        expect(restored.options[i].text, original.options[i].text);
        expect(restored.options[i].voterIds, original.options[i].voterIds);
      }
      expect(restored.createdBy, original.createdBy);
      expect(restored.creatorName, original.creatorName);
      expect(restored.createdAt, original.createdAt);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.isAnonymous, original.isAnonymous);
      expect(restored.isMultiChoice, original.isMultiChoice);
      expect(restored.isClosed, original.isClosed);
    });

    test('totalVotes se recalcula correctamente tras round-trip', () {
      final original = CollectivePoll(options: [
        PollOption(voterIds: ['u1', 'u2']),
        PollOption(voterIds: ['u3']),
      ]);
      final restored = CollectivePoll.fromJSON(original.toJSON());
      expect(restored.totalVotes, 3);
    });

    test('options null en JSON ⇒ lista vacía', () {
      final p = CollectivePoll.fromJSON({'options': null});
      expect(p.options, isEmpty);
      expect(p.totalVotes, 0);
    });

    test('mapa vacío produce poll cerrado-por-defecto-no', () {
      final p = CollectivePoll.fromJSON(<String, dynamic>{});
      expect(p.id, '');
      expect(p.options, isEmpty);
      expect(p.isClosed, isFalse);
    });
  });

  group('CollectivePoll.toString', () {
    test('contiene id, question, collectiveId y totalVotes', () {
      final p = CollectivePoll(
        id: 'p1',
        question: '¿Color?',
        collectiveId: 'c1',
        options: [PollOption(voterIds: ['a', 'b'])],
      );
      final s = p.toString();
      expect(s, contains('p1'));
      expect(s, contains('¿Color?'));
      expect(s, contains('c1'));
      expect(s, contains('2'));
    });
  });
}
