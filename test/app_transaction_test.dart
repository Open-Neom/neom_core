// Tests for `AppTransaction`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_transaction.dart';
import 'package:neom_core/utils/enums/app_currency.dart';
import 'package:neom_core/utils/enums/transaction_status.dart';
import 'package:neom_core/utils/enums/transaction_type.dart';

void main() {
  group('AppTransaction — defaults', () {
    test('constructor sin params', () {
      final t = AppTransaction();
      expect(t.id, '');
      expect(t.description, '');
      expect(t.createdTime, 0);
      expect(t.type, TransactionType.purchase);
      expect(t.amount, 0);
      expect(t.currency, AppCurrency.appCoin);
      expect(t.status, TransactionStatus.pending);
      expect(t.orderId, isNull);
    });
  });

  group('AppTransaction — toJSON', () {
    test('serializa enums como strings (.name)', () {
      final t = AppTransaction(
        type: TransactionType.purchase,
        currency: AppCurrency.appCoin,
        status: TransactionStatus.pending,
      );
      final json = t.toJSON();
      expect(json['type'], 'purchase');
      expect(json['currency'], 'appCoin');
      expect(json['status'], 'pending');
    });
  });

  group('AppTransaction — round-trip', () {
    test('preserva campos básicos', () {
      final original = AppTransaction(
        id: 't1',
        description: 'Compra',
        createdTime: 1700000000000,
        type: TransactionType.purchase,
        amount: 99.5,
        currency: AppCurrency.appCoin,
        status: TransactionStatus.pending,
        orderId: 'o1',
        senderId: 's1',
        recipientId: 'r1',
        secretKey: 'sk',
      );
      final restored = AppTransaction.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.createdTime, original.createdTime);
      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.status, original.status);
      expect(restored.orderId, original.orderId);
      expect(restored.senderId, original.senderId);
      expect(restored.recipientId, original.recipientId);
      expect(restored.secretKey, original.secretKey);
    });

    test('amount como string se parsea', () {
      final t = AppTransaction.fromJSON({'amount': '50.25'});
      expect(t.amount, 50.25);
    });

    test('amount null usa 0', () {
      final t = AppTransaction.fromJSON({'amount': null});
      expect(t.amount, 0);
    });

    test('mapa vacío usa defaults', () {
      final t = AppTransaction.fromJSON(<String, dynamic>{});
      expect(t.id, '');
      expect(t.type, TransactionType.purchase);
      expect(t.currency, AppCurrency.appCoin);
      expect(t.status, TransactionStatus.pending);
    });

    test('enum desconocido cae al default sin crashear', () {
      final t = AppTransaction.fromJSON({
        'type': 'unknown_type',
        'status': 'unknown_status',
        'currency': 'XYZ',
      });
      expect(t.type, TransactionType.purchase);
      expect(t.status, TransactionStatus.pending);
      expect(t.currency, AppCurrency.appCoin);
    });
  });
}
