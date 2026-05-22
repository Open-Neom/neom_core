// Wallet + Address: financial JSON round-trip and address formatting.
// Wallet bugs corrupt user balances; address formatting drives every UI label.
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/address.dart';
import 'package:neom_core/domain/model/wallet.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/wallet_status.dart';

void main() {
  group('Wallet JSON round-trip', () {
    test('full round-trip preserves all fields', () {
      final w = Wallet(
        id: 'wallet_123',
        balance: 1234.56,
        currency: AppCurrency.eur,
        status: WalletStatus.active,
        createdTime: 1700000000000,
        lastUpdated: 1700000999999,
        lastTransactionId: 'tx_42',
      );
      final r = Wallet.fromJSON(w.toJSON());
      expect(r.id, w.id);
      expect(r.balance, 1234.56);
      expect(r.currency, AppCurrency.eur);
      expect(r.status, WalletStatus.active);
      expect(r.createdTime, w.createdTime);
      expect(r.lastUpdated, w.lastUpdated);
      expect(r.lastTransactionId, 'tx_42');
    });

    test('integer balance is parsed as double', () {
      final r = Wallet.fromJSON({'balance': 100, 'currency': 'usd'});
      expect(r.balance, 100.0);
    });

    test('null balance falls back to 0', () {
      final r = Wallet.fromJSON({'currency': 'usd'});
      expect(r.balance, 0.0);
    });

    test('unknown status falls back to active (legacy compat — see NC-29)', () {
      // Updated as part of NC-29 fix: el default suspended bloqueaba pagos
      // a wallets legacy sin el campo status. Ahora cae a active (consistente
      // con el constructor default y con la mayoría de wallets en uso).
      final r = Wallet.fromJSON(
          {'status': 'nonexistent_state', 'currency': 'usd'});
      expect(r.status, WalletStatus.active);
    });

    test('null currency parses to appCoin', () {
      final r = Wallet.fromJSON({'currency': null});
      expect(r.currency, AppCurrency.appCoin);
    });

    test('zero balance + active status round-trips', () {
      final w = Wallet(balance: 0, status: WalletStatus.active);
      final r = Wallet.fromJSON(w.toJSON());
      expect(r.balance, 0.0);
      expect(r.status, WalletStatus.active);
    });

    test('large balance preserves precision', () {
      final w = Wallet(balance: 9999999.99, currency: AppCurrency.usd);
      final r = Wallet.fromJSON(w.toJSON());
      expect(r.balance, closeTo(9999999.99, 1e-6));
    });
  });

  group('Address JSON round-trip', () {
    test('full address round-trip', () {
      final a = Address(
        country: 'Mexico',
        state: 'CDMX',
        city: 'Coyoacán',
        neighborhood: 'Del Carmen',
        street: 'Av. Universidad',
        placeNumber: '1500',
        zipCode: '04000',
      );
      final r = Address.fromJSON(a.toJSON());
      expect(r.country, a.country);
      expect(r.state, a.state);
      expect(r.city, a.city);
      expect(r.neighborhood, a.neighborhood);
      expect(r.street, a.street);
      expect(r.placeNumber, a.placeNumber);
      expect(r.zipCode, a.zipCode);
    });

    test('empty fields default to ""', () {
      final r = Address.fromJSON(<String, dynamic>{});
      expect(r.country, '');
      expect(r.state, '');
      expect(r.city, '');
      expect(r.neighborhood, '');
      expect(r.street, '');
      expect(r.placeNumber, '');
      expect(r.zipCode, '');
    });
  });

  group('Address.getAddressSimple', () {
    test('city present → "city, country"', () {
      final a = Address(country: 'Mexico', city: 'Mérida');
      expect(a.getAddressSimple(), 'Mérida, Mexico');
    });

    test('no city → "street, country"', () {
      final a = Address(country: 'Mexico', street: 'Reforma 100');
      expect(a.getAddressSimple(), 'Reforma 100, Mexico');
    });

    test('totally empty address yields ", "', () {
      // Documenting current behavior — UI must guard.
      final a = Address();
      // Empty city → falls into the else branch using street (also empty).
      expect(a.getAddressSimple(), ', ');
    });
  });
}
