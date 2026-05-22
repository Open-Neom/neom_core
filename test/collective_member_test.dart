// Tests for `CollectiveMember`.
//
// NC-37 esperado: `operator==` línea 40 usa `instrument!.name` que crashea
// si `instrument` es null en cualquiera de los dos miembros comparados.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_member.dart';
import 'package:neom_core/domain/model/instrument.dart';
import 'package:neom_core/utils/enums/collective_member_role.dart';
import 'package:neom_core/utils/enums/vocal_type.dart';

void main() {
  group('CollectiveMember — defaults', () {
    test('constructor sin params', () {
      final m = CollectiveMember();
      expect(m.id, '');
      expect(m.name, '');
      expect(m.imgUrl, '');
      expect(m.profileId, '');
      expect(m.instrument, isNull);
      expect(m.vocalType, VocalType.none);
      expect(m.role, CollectiveMemberRole.member);
      expect(m.isMuted, isTrue, reason: 'constructor default isMuted=true');
    });

    test('parámetros nombrados', () {
      final m = CollectiveMember(
        id: 'm1',
        name: 'Ana',
        imgUrl: 'https://x',
        profileId: 'u1',
        instrument: Instrument(name: 'Bass'),
        vocalType: VocalType.none,
        role: CollectiveMemberRole.member,
        isMuted: false,
      );
      expect(m.id, 'm1');
      expect(m.name, 'Ana');
      expect(m.profileId, 'u1');
      expect(m.instrument?.name, 'Bass');
      expect(m.role, CollectiveMemberRole.member);
      expect(m.isMuted, isFalse);
    });
  });

  group('CollectiveMember — toJSON', () {
    test('NO incluye id (Firebase docId)', () {
      final m = CollectiveMember(id: 'm1', instrument: Instrument());
      expect(m.toJSON().containsKey('id'), isFalse);
    });

    test('serializa enums como strings', () {
      final m = CollectiveMember(
        instrument: Instrument(),
        vocalType: VocalType.none,
        role: CollectiveMemberRole.member,
      );
      final json = m.toJSON();
      expect(json['vocalType'], 'none');
      expect(json['role'], 'member');
    });

    test('instrument null usa Instrument() default', () {
      final m = CollectiveMember();
      final json = m.toJSON();
      expect(json['instrument'], isA<Map>());
    });
  });

  group('CollectiveMember — round-trip', () {
    test('preserva campos básicos', () {
      final original = CollectiveMember(
        id: 'm1',
        name: 'Ana',
        imgUrl: 'https://x',
        profileId: 'u1',
        instrument: Instrument(id: 'Bass', name: 'Bass'),
        vocalType: VocalType.none,
        role: CollectiveMemberRole.member,
        isMuted: false,
      );
      final json = {...original.toJSON(), 'id': original.id};
      final restored = CollectiveMember.fromJSON(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.profileId, original.profileId);
      expect(restored.instrument?.name, original.instrument?.name);
      expect(restored.vocalType, original.vocalType);
      expect(restored.role, original.role);
      expect(restored.isMuted, original.isMuted);
    });

    test('mapa vacío usa defaults', () {
      final m = CollectiveMember.fromJSON(<String, dynamic>{});
      expect(m.id, '');
      expect(m.vocalType, VocalType.none);
      expect(m.role, CollectiveMemberRole.member);
      expect(m.isMuted, isTrue);
    });
  });

  group('CollectiveMember.operator== (puede revelar NC-37)', () {
    test('dos miembros con instrument no-null e iguales son iguales', () {
      final inst = Instrument(id: 'Bass', name: 'Bass');
      final a = CollectiveMember(
        id: 'm1', name: 'Ana', profileId: 'u1', instrument: inst,
      );
      final b = CollectiveMember(
        id: 'm2', name: 'Ana', profileId: 'u1', instrument: inst,
      );
      // operator== ignora id (línea 40: empieza con name)
      expect(a == b, isTrue);
    });

    test('NC-37: comparar dos miembros con instrument null crashea', () {
      // Bug: línea 40 `instrument!.name == other.instrument!.name` lanza
      // `Null check operator used on a null value` cuando AMBOS instrument
      // son null. Esto es lo que pasa al comparar miembros nuevos.
      final a = CollectiveMember(name: 'Ana', profileId: 'u1');
      final b = CollectiveMember(name: 'Ana', profileId: 'u1');
      try {
        final result = a == b;
        expect(result, isTrue,
            reason: 'instrument null en ambos lados debería contar como iguales');
      } on TypeError catch (e) {
        fail('NC-37: operator== usa `!` sobre instrument null. $e');
      } catch (e) {
        fail('NC-37: operator== crashea con instrument null: $e');
      }
    });

    test('NC-37: comparar uno con instrument y otro sin crashea', () {
      // Bug: misma raíz — `!` en cualquier lado es null.
      final a = CollectiveMember(
        name: 'Ana', profileId: 'u1', instrument: Instrument(name: 'Bass'),
      );
      final b = CollectiveMember(name: 'Ana', profileId: 'u1');
      try {
        final result = a == b;
        // Esperamos false porque uno tiene instrument y el otro no.
        expect(result, isFalse);
      } on TypeError catch (e) {
        fail('NC-37: operator== crashea cuando un instrument es null. $e');
      }
    });
  });

  group('CollectiveMember.toString', () {
    test('contiene los campos clave', () {
      final m = CollectiveMember(
        id: 'm1',
        name: 'Ana',
        profileId: 'u1',
      );
      final s = m.toString();
      expect(s, contains('m1'));
      expect(s, contains('Ana'));
    });
  });
}
