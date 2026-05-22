// Tests for `RoyaltyPayout` — modelo bien defendido.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/nupale/royalty_payout.dart';
import 'package:neom_core/utils/enums/royalty_payout_status.dart';

void main() {
  group('RoyaltyPayout — defaults', () {
    test('constructor sin params', () {
      final r = RoyaltyPayout();
      expect(r.id, '');
      expect(r.ownerEmail, '');
      expect(r.month, 0);
      expect(r.year, 0);
      expect(r.totalNupale, 0);
      expect(r.platformTotalNupale, 0);
      expect(r.valuePerPage, 0.0);
      expect(r.grossAmountMxn, 0.0);
      expect(r.appCoinsDeposited, 0.0);
      expect(r.activeSubscriptions, 0);
      expect(r.transactionId, '');
      expect(r.status, RoyaltyPayoutStatus.pending);
      expect(r.createdTime, 0);
      expect(r.itemBreakdown, isEmpty);
    });
  });

  group('RoyaltyPayout — round-trip', () {
    test('preserva campos básicos', () {
      final original = RoyaltyPayout(
        id: 'rp1',
        ownerEmail: 'creator@x.com',
        month: 3,
        year: 2024,
        totalNupale: 1000,
        platformTotalNupale: 100000,
        valuePerPage: 0.5,
        grossAmountMxn: 500.0,
        appCoinsDeposited: 5000.0,
        activeSubscriptions: 250,
        transactionId: 'tx_1',
        status: RoyaltyPayoutStatus.pending,
        createdTime: 1700000000000,
        itemBreakdown: {'item1': 600, 'item2': 400},
      );
      final restored = RoyaltyPayout.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.month, original.month);
      expect(restored.year, original.year);
      expect(restored.totalNupale, original.totalNupale);
      expect(restored.valuePerPage, original.valuePerPage);
      expect(restored.grossAmountMxn, original.grossAmountMxn);
      expect(restored.appCoinsDeposited, original.appCoinsDeposited);
      expect(restored.transactionId, original.transactionId);
      expect(restored.status, original.status);
      expect(restored.itemBreakdown, original.itemBreakdown);
    });

    test('valores numéricos como int se convierten a double', () {
      final r = RoyaltyPayout.fromJSON({
        'valuePerPage': 1, 'grossAmountMxn': 100, 'appCoinsDeposited': 500,
      });
      expect(r.valuePerPage, 1.0);
      expect(r.grossAmountMxn, 100.0);
      expect(r.appCoinsDeposited, 500.0);
    });

    test('mapa vacío usa defaults', () {
      final r = RoyaltyPayout.fromJSON(<String, dynamic>{});
      expect(r.id, '');
      expect(r.status, RoyaltyPayoutStatus.pending);
      expect(r.itemBreakdown, isEmpty);
    });

    test('itemBreakdown null se hidrata como vacío', () {
      final r = RoyaltyPayout.fromJSON({'itemBreakdown': null});
      expect(r.itemBreakdown, isEmpty);
    });

    test('itemBreakdown con valores num int', () {
      final r = RoyaltyPayout.fromJSON({
        'itemBreakdown': {'item1': 100, 'item2': 200},
      });
      expect(r.itemBreakdown['item1'], 100);
      expect(r.itemBreakdown['item2'], 200);
    });

    test('status desconocido cae a pending', () {
      final r = RoyaltyPayout.fromJSON({'status': 'unknown_status'});
      expect(r.status, RoyaltyPayoutStatus.pending);
    });
  });
}
