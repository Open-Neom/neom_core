// Tests for `FinancialSnapshot`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/financial_snapshot.dart';

void main() {
  group('FinancialSnapshot — defaults', () {
    test('constructor sin params', () {
      final s = FinancialSnapshot();
      expect(s.id, '');
      expect(s.mrr, 0.0);
      expect(s.arr, 0.0);
      expect(s.activeSubscriptions, 0);
      expect(s.newSubscriptions, 0);
      expect(s.cancelledSubscriptions, 0);
      expect(s.churnRate, 0.0);
      expect(s.revenueProjected, 0.0);
      expect(s.byPlan, isEmpty);
      expect(s.byStatus, isEmpty);
      expect(s.computedAt, 0);
    });
  });

  group('FinancialSnapshot — computed', () {
    test('mrrGrowthPercent: previous mrr 0 → 0%', () {
      final current = FinancialSnapshot(mrr: 1000);
      final previous = FinancialSnapshot(mrr: 0);
      expect(current.mrrGrowthPercent(previous), 0.0);
    });

    test('mrrGrowthPercent: 100% growth', () {
      final current = FinancialSnapshot(mrr: 2000);
      final previous = FinancialSnapshot(mrr: 1000);
      expect(current.mrrGrowthPercent(previous), 100.0);
    });

    test('mrrGrowthPercent: 50% decline', () {
      final current = FinancialSnapshot(mrr: 500);
      final previous = FinancialSnapshot(mrr: 1000);
      expect(current.mrrGrowthPercent(previous), -50.0);
    });

    test('netMonthlyRevenue: aplica churn rate', () {
      final s = FinancialSnapshot(mrr: 1000, churnRate: 0.05);
      expect(s.netMonthlyRevenue, 950.0);
    });

    test('netMonthlyRevenue: churn 0 = mrr completo', () {
      expect(FinancialSnapshot(mrr: 1000).netMonthlyRevenue, 1000.0);
    });
  });

  group('FinancialSnapshot — round-trip', () {
    test('preserva todos los campos', () {
      final original = FinancialSnapshot(
        id: '2026-03-02',
        mrr: 50000.0,
        arr: 600000.0,
        activeSubscriptions: 250,
        newSubscriptions: 30,
        cancelledSubscriptions: 5,
        churnRate: 0.02,
        revenueProjected: 588000.0,
        byPlan: {'artist': 100, 'premium': 150},
        byStatus: {'active': 240, 'cancelled': 10},
        computedAt: 1700000000000,
      );
      final restored = FinancialSnapshot.fromJSON(original.toJSON());
      expect(restored.id, original.id);
      expect(restored.mrr, original.mrr);
      expect(restored.arr, original.arr);
      expect(restored.activeSubscriptions, original.activeSubscriptions);
      expect(restored.newSubscriptions, original.newSubscriptions);
      expect(restored.cancelledSubscriptions, original.cancelledSubscriptions);
      expect(restored.churnRate, original.churnRate);
      expect(restored.revenueProjected, original.revenueProjected);
      expect(restored.byPlan, original.byPlan);
      expect(restored.byStatus, original.byStatus);
      expect(restored.computedAt, original.computedAt);
    });

    test('valores num int se convierten a double', () {
      final s = FinancialSnapshot.fromJSON({
        'mrr': 1000,
        'arr': 12000,
        'churnRate': 0,
        'revenueProjected': 11760,
      });
      expect(s.mrr, 1000.0);
      expect(s.arr, 12000.0);
      expect(s.churnRate, 0.0);
    });

    test('mapa vacío usa defaults', () {
      final s = FinancialSnapshot.fromJSON(<String, dynamic>{});
      expect(s.id, '');
      expect(s.mrr, 0.0);
      expect(s.byPlan, isEmpty);
    });

    test('byPlan/byStatus null se hidratan vacíos', () {
      final s = FinancialSnapshot.fromJSON({
        'byPlan': null,
        'byStatus': null,
      });
      expect(s.byPlan, isEmpty);
      expect(s.byStatus, isEmpty);
    });
  });
}
