// Tests for `EventActivity` y `EventOffer`.
//
// EventActivity tiene un bug visible: `toJSON()` serializa `'id': name`
// (no `'id': id`) y `fromJSON()` carga `id = data["name"]`. Round-trip de
// id se contamina con name. Si el test falla, queda registrado.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/event_activity.dart';
import 'package:neom_core/domain/model/event_offer.dart';
import 'package:neom_core/utils/enums/app_currency.dart';

void main() {
  group('EventActivity — defaults', () {
    test('constructor sin params', () {
      final a = EventActivity();
      expect(a.id, '');
      expect(a.name, '');
      expect(a.description, '');
    });

    test('parámetros nombrados se asignan', () {
      final a = EventActivity(
        id: 'a1',
        name: 'Concierto',
        description: 'Evento principal',
      );
      expect(a.id, 'a1');
      expect(a.name, 'Concierto');
      expect(a.description, 'Evento principal');
    });
  });

  group('EventActivity — toString', () {
    test('contiene los 3 campos', () {
      final a = EventActivity(id: 'a1', name: 'X', description: 'desc');
      final s = a.toString();
      expect(s, contains('a1'));
      expect(s, contains('X'));
      expect(s, contains('desc'));
    });
  });

  group('EventActivity — JSON (puede revelar NC-04)', () {
    test('round-trip preserva name y description', () {
      final original = EventActivity(name: 'Concierto', description: 'desc');
      final restored = EventActivity.fromJSON(original.toJSON());
      expect(restored.name, original.name);
      expect(restored.description, original.description);
    });

    test('round-trip de id es lossless cuando id == name', () {
      // Caso degenerado donde el bug NO se manifiesta porque id y name son iguales.
      final original = EventActivity(id: 'A', name: 'A');
      final restored = EventActivity.fromJSON(original.toJSON());
      expect(restored.id, 'A');
      expect(restored.name, 'A');
    });

    test('round-trip preserva el id distinto de name', () {
      // Posible bug NC-04: toJSON y fromJSON usan 'name' como fuente del id.
      // Si el bug existe, restored.id == original.name (no original.id).
      final original = EventActivity(id: 'real_id', name: 'visible_name');
      final restored = EventActivity.fromJSON(original.toJSON());
      expect(
        restored.id,
        original.id,
        reason: 'Si falla: NC-04 — toJSON serializa id desde name, '
            'no desde el campo id real.',
      );
    });
  });

  group('EventOffer — defaults', () {
    test('constructor con defaults', () {
      final o = EventOffer();
      expect(o.amount, 0);
      expect(o.currency, AppCurrency.appCoin);
    });

    test('parámetros nombrados', () {
      final o = EventOffer(amount: 99.5, currency: AppCurrency.appCoin);
      expect(o.amount, 99.5);
      expect(o.currency, AppCurrency.appCoin);
    });
  });

  group('EventOffer — JSON', () {
    test('toJSON serializa currency como string (.name)', () {
      final o = EventOffer(currency: AppCurrency.appCoin);
      final json = o.toJSON();
      expect(json['currency'], 'appCoin');
    });

    test('round-trip preserva amount y currency', () {
      final original = EventOffer(amount: 250.75, currency: AppCurrency.appCoin);
      final restored = EventOffer.fromJSON(original.toJSON());
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
    });

    test('fromJSON con currency null usa default appCoin', () {
      final o = EventOffer.fromJSON({'currency': null, 'amount': 5.0});
      expect(o.currency, AppCurrency.appCoin);
      expect(o.amount, 5.0);
    });

    test('fromJSON con mapa vacío usa amount=1 (NO 0 como constructor)', () {
      // Inconsistencia documentada: constructor default amount=0, fromJSON=1.
      // Esto es deuda menor — el comportamiento se documenta.
      final o = EventOffer.fromJSON(<String, dynamic>{});
      expect(o.amount, 1,
          reason: 'fromJSON usa default 1 (distinto del constructor que usa 0)');
      expect(o.currency, AppCurrency.appCoin);
    });

    test('fromJSON con currency desconocida cae a appCoin', () {
      final o = EventOffer.fromJSON({'currency': 'GBP_NOT_REAL'});
      expect(o.currency, AppCurrency.appCoin);
    });
  });
}
