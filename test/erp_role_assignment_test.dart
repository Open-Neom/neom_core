// Tests for `ErpRoleAssignment`.
//
// Modelo gating de privilegios ERP — bug aquí abre o cierra accesos
// administrativos sin querer. Tests cubren: constructor, hasPrivilege,
// helpers can*, JSON round-trip con lista de enums.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/erp_role_assignment.dart';
import 'package:neom_core/utils/enums/erp_privilege.dart';

void main() {
  group('ErpRoleAssignment — defaults', () {
    test('constructor sin params', () {
      final r = ErpRoleAssignment();
      expect(r.userId, '');
      expect(r.displayName, '');
      expect(r.privileges, isEmpty);
      expect(r.assignedDate, 0);
      expect(r.assignedBy, '');
    });
  });

  group('ErpRoleAssignment.hasPrivilege', () {
    test('false cuando privilegios vacíos', () {
      final r = ErpRoleAssignment();
      for (final p in ErpPrivilege.values) {
        expect(r.hasPrivilege(p), isFalse);
      }
    });

    test('true cuando el privilegio está en la lista', () {
      final r = ErpRoleAssignment(privileges: [
        ErpPrivilege.viewFinancialKpis,
        ErpPrivilege.manageSubscriptionStatus,
      ]);
      expect(r.hasPrivilege(ErpPrivilege.viewFinancialKpis), isTrue);
      expect(r.hasPrivilege(ErpPrivilege.manageSubscriptionStatus), isTrue);
    });

    test('false cuando el privilegio NO está en la lista', () {
      final r = ErpRoleAssignment(privileges: [ErpPrivilege.viewFinancialKpis]);
      expect(r.hasPrivilege(ErpPrivilege.exportRevenueForecast), isFalse);
    });
  });

  group('ErpRoleAssignment — getters helpers', () {
    test('canViewKpis', () {
      expect(ErpRoleAssignment().canViewKpis, isFalse);
      expect(
        ErpRoleAssignment(privileges: [ErpPrivilege.viewFinancialKpis]).canViewKpis,
        isTrue,
      );
    });

    test('canManageSubscriptions', () {
      expect(ErpRoleAssignment().canManageSubscriptions, isFalse);
      expect(
        ErpRoleAssignment(
                privileges: [ErpPrivilege.manageSubscriptionStatus])
            .canManageSubscriptions,
        isTrue,
      );
    });

    test('canViewPayments', () {
      expect(ErpRoleAssignment().canViewPayments, isFalse);
      expect(
        ErpRoleAssignment(privileges: [ErpPrivilege.viewPaymentHistory])
            .canViewPayments,
        isTrue,
      );
    });

    test('canExportForecast', () {
      expect(ErpRoleAssignment().canExportForecast, isFalse);
      expect(
        ErpRoleAssignment(privileges: [ErpPrivilege.exportRevenueForecast])
            .canExportForecast,
        isTrue,
      );
    });

    test('todos los helpers true cuando se asignan todos los privilegios', () {
      final r = ErpRoleAssignment(privileges: ErpPrivilege.values);
      expect(r.canViewKpis, isTrue);
      expect(r.canManageSubscriptions, isTrue);
      expect(r.canViewPayments, isTrue);
      expect(r.canExportForecast, isTrue);
    });
  });

  group('ErpRoleAssignment — JSON round-trip', () {
    test('round-trip preserva todos los campos', () {
      final original = ErpRoleAssignment(
        userId: 'u1',
        displayName: 'COO',
        privileges: [
          ErpPrivilege.viewFinancialKpis,
          ErpPrivilege.viewPaymentHistory,
        ],
        assignedDate: 1700000000000,
        assignedBy: 'ceo',
      );
      final restored = ErpRoleAssignment.fromJSON(original.toJSON());
      expect(restored.userId, original.userId);
      expect(restored.displayName, original.displayName);
      expect(restored.privileges, original.privileges);
      expect(restored.assignedDate, original.assignedDate);
      expect(restored.assignedBy, original.assignedBy);
    });

    test('toJSON serializa privilegios como lista de strings', () {
      final r = ErpRoleAssignment(
        privileges: [ErpPrivilege.viewFinancialKpis],
      );
      final json = r.toJSON();
      expect(json['privileges'], isA<List>());
      expect((json['privileges'] as List).first, isA<String>());
      expect(json['privileges'], contains('viewFinancialKpis'));
    });

    test('fromJSON con privilegios desconocidos los descarta (whereType)', () {
      final r = ErpRoleAssignment.fromJSON({
        'userId': 'u1',
        'privileges': ['viewFinancialKpis', 'unknownNonsense'],
      });
      // El privilegio inválido se filtra vía whereType<ErpPrivilege>().
      expect(r.privileges.length, 1);
      expect(r.privileges.first, ErpPrivilege.viewFinancialKpis);
    });

    test('fromJSON con privileges null ⇒ lista vacía', () {
      final r = ErpRoleAssignment.fromJSON({'privileges': null});
      expect(r.privileges, isEmpty);
    });
  });
}
