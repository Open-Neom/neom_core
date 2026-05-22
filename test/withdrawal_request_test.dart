// Tests for `WithdrawalRequest`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/withdrawal_request.dart';

void main() {
  group('WithdrawalStatus enum', () {
    test('tiene 4 valores', () {
      expect(WithdrawalStatus.values.length, 4);
    });

    test('values numéricos secuenciales 0..3', () {
      expect(WithdrawalStatus.pending.value, 0);
      expect(WithdrawalStatus.processing.value, 1);
      expect(WithdrawalStatus.completed.value, 2);
      expect(WithdrawalStatus.rejected.value, 3);
    });
  });

  group('WithdrawalRequest — defaults', () {
    test('constructor sin params', () {
      final r = WithdrawalRequest();
      expect(r.id, '');
      expect(r.ownerEmail, '');
      expect(r.appCoinsAmount, 0.0);
      expect(r.mxnAmount, 0.0);
      expect(r.bankClabe, '');
      expect(r.status, WithdrawalStatus.pending);
      expect(r.createdTime, 0);
      expect(r.processedTime, 0);
      expect(r.adminNote, '');
    });
  });

  group('WithdrawalRequest — round-trip', () {
    test('preserva todos los campos', () {
      final original = WithdrawalRequest(
        id: 'wr1',
        ownerEmail: 'creator@x.com',
        appCoinsAmount: 5000.0,
        mxnAmount: 2500.0,
        bankClabe: '012345678901234567',
        status: WithdrawalStatus.processing,
        createdTime: 1700000000000,
        processedTime: 1700001000000,
        adminNote: 'Verificando CLABE',
      );
      final restored = WithdrawalRequest.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.appCoinsAmount, original.appCoinsAmount);
      expect(restored.mxnAmount, original.mxnAmount);
      expect(restored.bankClabe, original.bankClabe);
      expect(restored.status, original.status);
      expect(restored.createdTime, original.createdTime);
      expect(restored.processedTime, original.processedTime);
      expect(restored.adminNote, original.adminNote);
    });

    test('appCoinsAmount como int se convierte a double', () {
      final r = WithdrawalRequest.fromJSON({'appCoinsAmount': 100});
      expect(r.appCoinsAmount, 100.0);
    });

    test('mapa vacío usa defaults', () {
      final r = WithdrawalRequest.fromJSON(<String, dynamic>{});
      expect(r.id, '');
      expect(r.appCoinsAmount, 0.0);
      expect(r.status, WithdrawalStatus.pending);
    });

    test('status desconocido cae a pending', () {
      final r = WithdrawalRequest.fromJSON({'status': 'invalid_status'});
      expect(r.status, WithdrawalStatus.pending);
    });

    test('todos los status son round-trip-able', () {
      for (final s in WithdrawalStatus.values) {
        final original = WithdrawalRequest(status: s);
        final restored = WithdrawalRequest.fromJSON(original.toJSON());
        expect(restored.status, s);
      }
    });
  });
}
