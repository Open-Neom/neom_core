// Tests for `Wallet`.
//
// Posible bug NC-29: fromJSON con status null cae a `WalletStatus.suspended`
// (no a `active` que es el constructor default) — cualquier doc legacy sin
// el campo `status` queda con la wallet suspendida, bloqueando pagos.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/wallet.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/wallet_status.dart';

void main() {
  group('Wallet — defaults', () {
    test('constructor sin params', () {
      final w = Wallet();
      expect(w.id, '');
      expect(w.balance, 0.0);
      expect(w.currency, AppCurrency.appCoin);
      expect(w.status, WalletStatus.active,
          reason: 'constructor default es active');
      expect(w.createdTime, 0);
      expect(w.lastUpdated, 0);
      expect(w.lastTransactionId, isNull);
    });
  });

  group('Wallet — toJSON', () {
    test('contiene 7 llaves', () {
      final json = Wallet().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'balance', 'currency', 'status',
          'createdTime', 'lastUpdated', 'lastTransactionId',
        ]),
      );
    });

    test('currency y status como strings (.name)', () {
      final json = Wallet(
        currency: AppCurrency.appCoin,
        status: WalletStatus.active,
      ).toJSON();
      expect(json['currency'], 'appCoin');
      expect(json['status'], 'active');
    });
  });

  group('Wallet — round-trip', () {
    test('preserva campos cuando todos están presentes', () {
      final original = Wallet(
        id: 'w1',
        balance: 1500.50,
        currency: AppCurrency.appCoin,
        status: WalletStatus.active,
        createdTime: 1700000000000,
        lastUpdated: 1700000001000,
        lastTransactionId: 'tx_1',
      );
      final restored = Wallet.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.balance, original.balance);
      expect(restored.currency, original.currency);
      expect(restored.status, original.status);
      expect(restored.createdTime, original.createdTime);
      expect(restored.lastUpdated, original.lastUpdated);
      expect(restored.lastTransactionId, original.lastTransactionId);
    });

    test('balance como int se convierte a double', () {
      final w = Wallet.fromJSON({'balance': 100, 'status': 'active'});
      expect(w.balance, 100.0);
    });
  });

  group('Wallet — defaults peligrosos en fromJSON (NC-29)', () {
    test('NC-29: status null debería defaultear a `active` (no `suspended`)', () {
      // Bug: fromJSON línea 42 `?? WalletStatus.suspended` — un doc legacy
      // sin el campo `status` queda como SUSPENDED, bloqueando pagos.
      // Esto es lo opuesto al constructor (default active).
      // Patrón gemelo de NC-05 AppUser.isBanned.
      final w = Wallet.fromJSON({
        'id': 'w1',
        'balance': 100,
        'currency': 'appCoin',
        // 'status' ausente
      });
      expect(
        w.status,
        WalletStatus.active,
        reason: 'NC-29: wallet sin campo status debería ser active por '
            'compatibilidad con docs legacy. Default suspended bloquea pagos.',
      );
    });

    test('mapa vacío → status fallback', () {
      // Documenta el comportamiento actual: fromJSON({}) → suspended.
      final w = Wallet.fromJSON(<String, dynamic>{});
      // Con el fix queremos que sea active. Sin fix sigue suspended.
      expect(w.status, WalletStatus.active);
    });
  });
}
