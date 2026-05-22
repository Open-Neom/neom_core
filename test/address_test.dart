// Tests for `Address` domain model.
//
// Foco: constructor con defaults, JSON round-trip, fromJSON con campos
// faltantes o tipos inesperados. NO se prueba `getAddressSimple()` porque
// depende de `AppConfig.logger` y `NeomErrorLogger` (capas de infra que se
// inicializan a nivel app).

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/address.dart';

void main() {
  group('Address — defaults', () {
    test('constructor sin parámetros usa cadenas vacías', () {
      final a = Address();
      expect(a.country, '');
      expect(a.state, '');
      expect(a.city, '');
      expect(a.neighborhood, '');
      expect(a.street, '');
      expect(a.placeNumber, '');
      expect(a.zipCode, '');
    });

    test('constructor acepta parámetros nombrados', () {
      final a = Address(
        country: 'MX',
        state: 'CDMX',
        city: 'Ciudad de México',
        neighborhood: 'Roma',
        street: 'Av. Insurgentes',
        placeNumber: '123',
        zipCode: '06700',
      );
      expect(a.country, 'MX');
      expect(a.state, 'CDMX');
      expect(a.city, 'Ciudad de México');
      expect(a.neighborhood, 'Roma');
      expect(a.street, 'Av. Insurgentes');
      expect(a.placeNumber, '123');
      expect(a.zipCode, '06700');
    });
  });

  group('Address — toJSON / fromJSON round-trip', () {
    test('todos los campos se preservan tras round-trip', () {
      final original = Address(
        country: 'MX',
        state: 'Jalisco',
        city: 'Guadalajara',
        neighborhood: 'Centro',
        street: 'Av. Hidalgo',
        placeNumber: '500',
        zipCode: '44100',
      );

      final json = original.toJSON();
      final restored = Address.fromJSON(json);

      expect(restored.country, original.country);
      expect(restored.state, original.state);
      expect(restored.city, original.city);
      expect(restored.neighborhood, original.neighborhood);
      expect(restored.street, original.street);
      expect(restored.placeNumber, original.placeNumber);
      expect(restored.zipCode, original.zipCode);
    });

    test('toJSON contiene exactamente las 7 llaves esperadas', () {
      final json = Address().toJSON();
      expect(json.keys, containsAll([
        'country', 'state', 'city', 'neighborhood',
        'street', 'placeNumber', 'zipCode',
      ]));
      expect(json.length, 7);
    });

    test('fromJSON con campos null usa cadenas vacías', () {
      final a = Address.fromJSON({
        'country': null,
        'state': null,
        'city': null,
      });
      expect(a.country, '');
      expect(a.state, '');
      expect(a.city, '');
    });

    test('fromJSON con un mapa vacío produce dirección vacía', () {
      final a = Address.fromJSON(<String, dynamic>{});
      expect(a.country, '');
      expect(a.state, '');
      expect(a.city, '');
      expect(a.neighborhood, '');
      expect(a.street, '');
      expect(a.placeNumber, '');
      expect(a.zipCode, '');
    });

    test('fromJSON ignora llaves desconocidas sin lanzar', () {
      final a = Address.fromJSON({
        'country': 'AR',
        'unknown_key': 'should_not_break',
      });
      expect(a.country, 'AR');
    });
  });

  group('Address — escenarios reales', () {
    test('soporta caracteres acentuados y ñ', () {
      final a = Address(
        city: 'Ciudad de México',
        neighborhood: 'Coyoacán',
        street: 'Niño Perdido',
      );
      final restored = Address.fromJSON(a.toJSON());
      expect(restored.city, 'Ciudad de México');
      expect(restored.neighborhood, 'Coyoacán');
      expect(restored.street, 'Niño Perdido');
    });

    test('soporta strings largas (no trunca)', () {
      final long = 'a' * 500;
      final a = Address(street: long);
      expect(Address.fromJSON(a.toJSON()).street.length, 500);
    });
  });
}
