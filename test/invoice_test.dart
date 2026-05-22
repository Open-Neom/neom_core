// Tests for `Invoice`.
//
// Posibles bugs:
// - NC-30: AppUser/AppTransaction/Address.fromJSON nested sin `?? {}`
//   crashean con campos null.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/invoice.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/model/app_transaction.dart';
import 'package:neom_core/domain/model/address.dart';

void main() {
  group('Invoice — defaults', () {
    test('constructor sin params', () {
      final i = Invoice();
      expect(i.id, '');
      expect(i.description, '');
      expect(i.orderId, '');
      expect(i.createdTime, 0);
      expect(i.transaction, isNull);
    });
  });

  group('Invoice — toJSON', () {
    test('NO incluye id (Firebase docId)', () {
      final i = Invoice(id: 'inv1');
      expect(i.toJSON().containsKey('id'), isFalse);
    });

    test('contiene 6 llaves (incluye address)', () {
      final json = Invoice().toJSON();
      expect(json.length, 6);
      expect(
        json.keys,
        containsAll([
          'description', 'toUser', 'orderId', 'createdTime', 'transaction', 'address',
        ]),
      );
    });
  });

  group('Invoice — round-trip', () {
    test('round-trip con todos los campos', () {
      final i = Invoice(
        id: 'inv1',
        description: 'Compra Pro',
        orderId: 'o1',
        createdTime: 1700000000000,
      );
      i.toUser = AppUser(id: 'u1', name: 'Ana', email: 'ana@x.com');
      i.transaction = AppTransaction(id: 'tx1', amount: 99.5);
      i.address = Address(country: 'MX', city: 'CDMX');

      // Provee los nested explícitos para evitar nulls que crashearían.
      final json = {
        ...i.toJSON(),
        'id': i.id,
      };
      final restored = Invoice.fromJSON(json);

      expect(restored.id, i.id);
      expect(restored.description, i.description);
      expect(restored.orderId, i.orderId);
      expect(restored.createdTime, i.createdTime);
      expect(restored.toUser.id, i.toUser.id);
      expect(restored.toUser.name, i.toUser.name);
      expect(restored.toUser.email, i.toUser.email);
      expect(restored.transaction?.id, i.transaction?.id);
      expect(restored.transaction?.amount, i.transaction?.amount);
      expect(restored.address?.country, i.address?.country);
      expect(restored.address?.city, i.address?.city);
    });
  });

  group('Invoice — fromJSON (puede revelar NC-30)', () {
    test('NC-30: toUser null no debería crashear', () {
      // Bug: AppUser.fromJSON(data["toUser"]) sin `?? {}` — null crashea.
      try {
        final i = Invoice.fromJSON({
          'id': 'inv1',
          'description': 'desc',
          'toUser': null,
          'transaction': <String, dynamic>{},
          'address': <String, dynamic>{},
        });
        // toUser quedaría con un AppUser default
        expect(i.toUser, isA<AppUser>());
      } on NoSuchMethodError catch (e) {
        fail('NC-30: Invoice.fromJSON con toUser null crashea. $e');
      }
    });

    test('NC-30: transaction null no debería crashear', () {
      try {
        final i = Invoice.fromJSON({
          'id': 'inv1',
          'toUser': <String, dynamic>{},
          'transaction': null,
          'address': <String, dynamic>{},
        });
        expect(i.transaction, isNotNull);
      } on NoSuchMethodError catch (e) {
        fail('NC-30: transaction null crashea. $e');
      }
    });

    test('NC-30: address null no debería crashear', () {
      try {
        final i = Invoice.fromJSON({
          'id': 'inv1',
          'toUser': <String, dynamic>{},
          'transaction': <String, dynamic>{},
          'address': null,
        });
        expect(i.address, isNotNull);
      } on NoSuchMethodError catch (e) {
        fail('NC-30: address null crashea. $e');
      }
    });

    test('NC-30: mapa vacío no debería crashear (combina los 3 nulls)', () {
      try {
        final i = Invoice.fromJSON(<String, dynamic>{});
        expect(i.id, '');
      } on Object catch (e) {
        fail('NC-30: Invoice.fromJSON({}) crashea: $e');
      }
    });
  });
}
