// Tests for `AppUser` — modelo central del controlador de usuario.
//
// AppUser está en el corazón del flujo: login, perfil, suscripciones.
// Bugs aquí afectan **a todos los usuarios**. Tests cubren defaults,
// JSON round-trip, y revelan defaults peligrosos en isVerified/isBanned.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/utils/enums/user_role.dart';

void main() {
  group('AppUser — defaults del constructor', () {
    test('valores por defecto son sane', () {
      final u = AppUser();
      expect(u.id, '');
      expect(u.name, '');
      expect(u.email, '');
      expect(u.userRole, UserRole.subscriber);
      expect(u.isVerified, isFalse,
          reason: 'usuario nuevo NO debe asumirse verificado');
      expect(u.isBanned, isFalse,
          reason: 'usuario nuevo NO debe asumirse baneado');
      expect(u.profiles, isEmpty);
      expect(u.orderIds, isEmpty);
      expect(u.couponCode, '');
      expect(u.referralCode, '');
      expect(u.subscriptionId, '');
    });

    test('parámetros nombrados se asignan', () {
      final u = AppUser(
        id: 'u1',
        name: 'Juan Pérez',
        firstName: 'Juan',
        lastName: 'Pérez',
        email: 'juan@x.com',
        userRole: UserRole.admin,
        isVerified: true,
        customerId: 'cus_1',
        subscriptionId: 'sub_1',
      );
      expect(u.id, 'u1');
      expect(u.name, 'Juan Pérez');
      expect(u.firstName, 'Juan');
      expect(u.lastName, 'Pérez');
      expect(u.email, 'juan@x.com');
      expect(u.userRole, UserRole.admin);
      expect(u.isVerified, isTrue);
      expect(u.customerId, 'cus_1');
      expect(u.subscriptionId, 'sub_1');
    });
  });

  group('AppUser — round-trip JSON', () {
    test('preserva campos básicos', () {
      final original = AppUser(
        id: 'u1',
        name: 'Juan',
        firstName: 'Juan',
        lastName: 'Pérez',
        email: 'juan@x.com',
        phoneNumber: '5551234',
        countryCode: '+52',
        photoUrl: 'https://x',
        userRole: UserRole.admin,
        isVerified: true,
        isBanned: false,
        createdDate: 1700000000000,
        lastTimeOn: 1700000001000,
        customerId: 'cus_1',
        subscriptionId: 'sub_1',
      );

      // El id NO se serializa en toJSON (Firebase doc.id), simulamos eso.
      final json = {...original.toJSON(), 'id': original.id};
      final restored = AppUser.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.firstName, original.firstName);
      expect(restored.lastName, original.lastName);
      expect(restored.email, original.email);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.countryCode, original.countryCode);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.userRole, original.userRole);
      expect(restored.isVerified, original.isVerified);
      expect(restored.isBanned, original.isBanned);
      expect(restored.createdDate, original.createdDate);
      expect(restored.lastTimeOn, original.lastTimeOn);
      expect(restored.customerId, original.customerId);
      expect(restored.subscriptionId, original.subscriptionId);
    });

    test('listas de IDs (orderIds, releaseItemIds, boughtItems) se preservan', () {
      final original = AppUser(
        orderIds: ['o1', 'o2'],
      );
      original.releaseItemIds = ['r1', 'r2'];
      original.boughtItems = ['b1'];
      final restored = AppUser.fromJSON(original.toJSON());
      expect(restored.orderIds, ['o1', 'o2']);
      expect(restored.releaseItemIds, ['r1', 'r2']);
      expect(restored.boughtItems, ['b1']);
    });

    test('userRole nulo cae a UserRole.subscriber', () {
      final u = AppUser.fromJSON({'userRole': null});
      expect(u.userRole, UserRole.subscriber);
    });

    test('userRole desconocido cae a UserRole.subscriber', () {
      final u = AppUser.fromJSON({'userRole': 'nonexistentRole'});
      expect(u.userRole, UserRole.subscriber);
    });
  });

  group('AppUser — defaults peligrosos en fromJSON (NC-05)', () {
    test('isVerified default debería ser false cuando viene null', () {
      // Posible NC-05: el modelo defaultea a true en fromJSON.
      // Esto significa que cualquier campo missing en Firestore queda
      // marcado como verificado, lo cual viola el principio de "fallar seguro".
      final u = AppUser.fromJSON({'isVerified': null});
      expect(
        u.isVerified,
        isFalse,
        reason: 'NC-05: isVerified debería defaultear a false. '
            'Default actual `?? true` da credibilidad falsa a usuarios sin campo.',
      );
    });

    test('isBanned default debería ser false cuando viene null', () {
      // NC-05 — más grave: si el campo no existe, el modelo dice "baneado".
      // Esto bloquearía a TODOS los usuarios cuyo doc no tenga el campo
      // (probable que muchos legacy users).
      final u = AppUser.fromJSON({'isBanned': null});
      expect(
        u.isBanned,
        isFalse,
        reason: 'NC-05: isBanned default `?? true` baneara a usuarios legacy. '
            'Debería ser `?? false` (fail-safe: asumir no-baneado por default).',
      );
    });

    test('mapa vacío hidrata un usuario consistente con el constructor', () {
      // El test final de NC-05 es: ¿AppUser() y AppUser.fromJSON({}) coinciden?
      final defaultUser = AppUser();
      final fromEmpty = AppUser.fromJSON(<String, dynamic>{});

      expect(fromEmpty.isVerified, defaultUser.isVerified,
          reason: 'fromJSON({}) debería coincidir con AppUser()');
      expect(fromEmpty.isBanned, defaultUser.isBanned,
          reason: 'fromJSON({}) debería coincidir con AppUser()');
    });
  });

  group('AppUser — toJSON', () {
    test('NO serializa id (Firebase docId)', () {
      final json = AppUser(id: 'u1').toJSON();
      expect(json.containsKey('id'), isFalse);
    });

    test('NO serializa profiles (subcollection separada)', () {
      // Por diseño: profiles viven en subcollection users/{id}/profiles/.
      final json = AppUser().toJSON();
      expect(json.containsKey('profiles'), isFalse);
    });

    test('userRole se serializa como string (.name)', () {
      final json = AppUser(userRole: UserRole.admin).toJSON();
      expect(json['userRole'], 'admin');
    });
  });

  group('AppUser.toInvoiceJSON', () {
    test('contiene solo campos relevantes para factura', () {
      final u = AppUser(
        id: 'u1',
        name: 'Juan',
        email: 'j@x.com',
        password: 'secreto',
        photoUrl: 'https://x',
        subscriptionId: 'sub_1',
      );
      final json = u.toInvoiceJSON();

      // Datos personales + contacto
      expect(json.containsKey('id'), isTrue);
      expect(json['id'], 'u1');
      expect(json['email'], 'j@x.com');
      expect(json['name'], 'Juan');

      // Información SENSIBLE NO debe estar en factura
      expect(json.keys, isNot(contains('password')),
          reason: 'password NUNCA debe ir en factura');
      expect(json.keys, isNot(contains('subscriptionId')),
          reason: 'datos de Stripe no deben ir en factura clientside');
      expect(json.keys, isNot(contains('customerId')));
    });
  });

  group('AppUser — campos opcionales', () {
    test('referralCode y couponCode independientes', () {
      final u = AppUser(referralCode: 'REF1', couponCode: 'COUP1');
      expect(u.referralCode, 'REF1');
      expect(u.couponCode, 'COUP1');

      final restored = AppUser.fromJSON(u.toJSON());
      expect(restored.referralCode, 'REF1');
      expect(restored.couponCode, 'COUP1');
    });

    test('emails con caracteres especiales se preservan', () {
      for (final email in [
        'a+tag@x.com', 'foo.bar@example.co.uk', 'user_name@x.io',
      ]) {
        final u = AppUser(email: email);
        expect(AppUser.fromJSON(u.toJSON()).email, email);
      }
    });
  });
}
