// Tests for `Price`.
// Modelo simple, central en commerce. Cubre defaults, round-trip y parsing
// de amount como string.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/price.dart';
import 'package:neom_core/utils/enums/app_currency.dart';

void main() {
  group('Price — defaults', () {
    test('constructor sin params', () {
      final p = Price();
      expect(p.amount, 0.0);
      expect(p.currency, AppCurrency.appCoin);
    });

    test('parámetros nombrados', () {
      final p = Price(amount: 99.5, currency: AppCurrency.appCoin);
      expect(p.amount, 99.5);
      expect(p.currency, AppCurrency.appCoin);
    });
  });

  group('Price — toJSON', () {
    test('contiene amount y currency', () {
      final json = Price(amount: 50.0).toJSON();
      expect(json.length, 2);
      expect(json['amount'], 50.0);
      expect(json['currency'], 'appCoin');
    });

    test('currency se serializa como string (.name)', () {
      expect(Price(currency: AppCurrency.appCoin).toJSON()['currency'], 'appCoin');
    });
  });

  group('Price — fromJSON', () {
    test('round-trip preserva amount y currency', () {
      final original = Price(amount: 250.75, currency: AppCurrency.appCoin);
      final restored = Price.fromJSON(original.toJSON());
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
    });

    test('amount como string numérico se parsea', () {
      final p = Price.fromJSON({'amount': '99.5', 'currency': 'appCoin'});
      expect(p.amount, 99.5);
    });

    test('amount como int se parsea a double', () {
      final p = Price.fromJSON({'amount': 100, 'currency': 'appCoin'});
      expect(p.amount, 100.0);
    });

    test('amount null usa 0.0', () {
      final p = Price.fromJSON({'amount': null, 'currency': 'appCoin'});
      expect(p.amount, 0.0);
    });

    test('currency null usa appCoin', () {
      final p = Price.fromJSON({'amount': 10, 'currency': null});
      expect(p.currency, AppCurrency.appCoin);
    });

    test('mapa vacío usa defaults', () {
      final p = Price.fromJSON(<String, dynamic>{});
      expect(p.amount, 0.0);
      expect(p.currency, AppCurrency.appCoin);
    });
  });

  group('Price — currency desconocida (puede revelar NC-17)', () {
    test('currency con string no-enum debería caer al default sin crashear', () {
      // Bug potencial: el `!` en `EnumToString.fromString(...)!` crashea
      // cuando el string no matchea ningún valor del enum.
      try {
        final p = Price.fromJSON({'amount': 10, 'currency': 'XYZ_NOT_REAL'});
        expect(p.currency, isA<AppCurrency>(),
            reason: 'currency desconocida debería caer al default appCoin, no crashear');
      } on TypeError catch (e) {
        fail('NC-17: Price.fromJSON con currency desconocida usa "!" '
            'sobre un null y crashea. $e');
      } catch (e) {
        fail('NC-17 (otra exception): $e');
      }
    });
  });
}
