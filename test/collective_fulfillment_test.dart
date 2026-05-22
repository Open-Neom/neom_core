// Tests for `CollectiveFulfillment`.
//
// El modelo tiene un bug potencial en fromJSON: `hasAccepted = data[...] ?? ""`
// asigna string a un campo bool cuando el dato viene null. Si el test falla,
// queda registrado como NC-03 en docs/test_findings.md.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/collective_fulfillment.dart';

void main() {
  group('CollectiveFulfillment — defaults', () {
    test('constructor sin params usa defaults', () {
      final f = CollectiveFulfillment();
      expect(f.collectiveId, '');
      expect(f.collectiveImgUrl, '');
      expect(f.collectiveName, '');
      expect(f.hasAccepted, isFalse);
    });

    test('parámetros nombrados se asignan', () {
      final f = CollectiveFulfillment(
        collectiveId: 'c1',
        collectiveImgUrl: 'https://x',
        collectiveName: 'The Beatles',
        hasAccepted: true,
      );
      expect(f.collectiveId, 'c1');
      expect(f.collectiveImgUrl, 'https://x');
      expect(f.collectiveName, 'The Beatles');
      expect(f.hasAccepted, isTrue);
    });
  });

  group('CollectiveFulfillment — toJSON / fromJSON', () {
    test('toJSON contiene 4 llaves', () {
      final json = CollectiveFulfillment().toJSON();
      expect(json.length, 4);
      expect(json.keys, containsAll([
        'collectiveId', 'collectiveImgUrl', 'collectiveName', 'hasAccepted',
      ]));
    });

    test('round-trip preserva campos cuando hasAccepted es bool', () {
      final original = CollectiveFulfillment(
        collectiveId: 'c1',
        collectiveImgUrl: 'https://x',
        collectiveName: 'Banda',
        hasAccepted: true,
      );
      final restored = CollectiveFulfillment.fromJSON(original.toJSON());
      expect(restored.collectiveId, original.collectiveId);
      expect(restored.collectiveImgUrl, original.collectiveImgUrl);
      expect(restored.collectiveName, original.collectiveName);
      expect(restored.hasAccepted, original.hasAccepted);
    });

    test('fromJSON con hasAccepted null debería usar false (puede revelar bug)', () {
      // Bug potencial: el modelo hace `data["hasAccepted"] ?? ""` que asigna
      // String a un campo bool. Si Dart permite el assignment dinámico, el
      // estado queda inválido. Si lanza, queda evidenciado.
      try {
        final f = CollectiveFulfillment.fromJSON({'hasAccepted': null});
        // Si el null-coalescing devuelve "" (String), el campo bool queda
        // con un valor inválido (potencial cast error en Dart sound mode).
        expect(f.hasAccepted, isFalse,
            reason: 'fromJSON debería defaultear hasAccepted a false, no a "".');
      } on TypeError catch (e) {
        fail('NC-03 detectado: hasAccepted lanza TypeError porque '
            'fromJSON usa default "" (String) sobre campo bool. $e');
      }
    });

    test('fromJSON con mapa vacío produce fulfillment vacío', () {
      try {
        final f = CollectiveFulfillment.fromJSON(<String, dynamic>{});
        expect(f.collectiveId, '');
        expect(f.collectiveName, '');
        expect(f.hasAccepted, isFalse);
      } on TypeError catch (e) {
        fail('NC-03: fromJSON con mapa vacío lanza por default "" sobre bool. $e');
      }
    });
  });
}
