// Tests for `AppOrder`.
//
// AppOrder linka a un AppProduct + SubscriptionPlan + purchase details
// nativos. Tests cubren defaults, round-trip de campos top-level y un
// posible bug en customerType (NC-07: fromJSON lee llave 'type' pero
// toJSON escribe 'customerType').

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_order.dart';
import 'package:neom_core/utils/enums/profile_type.dart';

void main() {
  group('AppOrder — defaults', () {
    test('constructor sin params', () {
      final o = AppOrder();
      expect(o.id, '');
      expect(o.description, '');
      expect(o.url, '');
      expect(o.createdTime, 0);
      expect(o.customerEmail, '');
      expect(o.customerType, ProfileType.general);
      expect(o.couponId, '');
      expect(o.invoiceIds, isNull);
      expect(o.product, isNull);
      expect(o.subscriptionPlan, isNull);
    });

    test('parámetros nombrados se asignan', () {
      final o = AppOrder(
        id: 'o1',
        description: 'Suscripción Pro',
        url: 'https://x',
        createdTime: 1700000000000,
        customerEmail: 'c@x.com',
        customerType: ProfileType.general,
        couponId: 'coup1',
        invoiceIds: ['inv1', 'inv2'],
      );
      expect(o.id, 'o1');
      expect(o.description, 'Suscripción Pro');
      expect(o.customerEmail, 'c@x.com');
      expect(o.couponId, 'coup1');
      expect(o.invoiceIds, ['inv1', 'inv2']);
    });
  });

  group('AppOrder — toJSON', () {
    test('contiene 13 llaves esperadas', () {
      final json = AppOrder().toJSON();
      expect(
        json.keys,
        containsAll([
          'id', 'description', 'url', 'createdTime', 'customerEmail',
          'customerType', 'couponId', 'invoiceIds', 'product',
          'subscriptionPlan',
          'googlePlayPurchaseDetails', 'appStorePurchaseDetails',
        ]),
      );
    });

    test('customerType serializa como string (.name)', () {
      final json = AppOrder(customerType: ProfileType.general).toJSON();
      expect(json['customerType'], 'general');
    });
  });

  group('AppOrder — round-trip (puede revelar NC-07)', () {
    test('campos string básicos se preservan', () {
      final original = AppOrder(
        id: 'o1',
        description: 'desc',
        url: 'https://x',
        createdTime: 1700000000000,
        customerEmail: 'c@x.com',
        couponId: 'coup1',
        invoiceIds: ['i1', 'i2'],
      );
      final restored = AppOrder.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.description, original.description);
      expect(restored.url, original.url);
      expect(restored.createdTime, original.createdTime);
      expect(restored.customerEmail, original.customerEmail);
      expect(restored.couponId, original.couponId);
      expect(restored.invoiceIds, original.invoiceIds);
    });

    test('customerType debería preservarse tras round-trip (con valor != default)', () {
      // NC-07: toJSON escribe llave 'customerType' pero fromJSON lee 'type'.
      // El bug se enmascara cuando el valor coincide con el default
      // (general) porque el fallback aterriza ahí. Con `appArtist` el bug
      // queda evidente.
      final original = AppOrder(customerType: ProfileType.appArtist);
      final restored = AppOrder.fromJSON(original.toJSON());
      expect(
        restored.customerType,
        original.customerType,
        reason: 'NC-07: fromJSON lee `data["type"]` pero toJSON escribe '
            '`customerType`. El round-trip degrada a `general` cualquier '
            'tipo distinto al default.',
      );
    });
  });

  group('AppOrder — fromJSON con datos legacy', () {
    test('fromJSON con mapa vacío usa defaults', () {
      final o = AppOrder.fromJSON(<String, dynamic>{});
      expect(o.id, '');
      expect(o.customerEmail, '');
      expect(o.customerType, ProfileType.general);
    });

    test('fromJSON con la llave `type` (legacy) restaura customerType', () {
      // Si el doc viene de versión anterior que escribía `type`, debe leerse.
      final o = AppOrder.fromJSON({'type': 'general'});
      expect(o.customerType, ProfileType.general);
    });

    test('invoiceIds null se hidrata como lista vacía', () {
      final o = AppOrder.fromJSON({'invoiceIds': null});
      expect(o.invoiceIds, isEmpty);
    });

    test('invoiceIds desde lista se cast<String>', () {
      final o = AppOrder.fromJSON({'invoiceIds': ['a', 'b']});
      expect(o.invoiceIds, ['a', 'b']);
    });
  });
}
