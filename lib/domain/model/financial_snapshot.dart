/// Pre-computed financial intelligence snapshot.
/// Generated daily by Cloud Function `computeFinancialSnapshot`.
/// Stored in Firestore `financialSnapshots` collection, keyed by date (YYYY-MM-DD).
class FinancialSnapshot {

  String id;                    // "2026-03-02" (YYYY-MM-DD)
  double mrr;                   // Monthly Recurring Revenue
  double arr;                   // Annual Recurring Revenue (MRR × 12)
  int activeSubscriptions;
  int newSubscriptions;         // new this period
  int cancelledSubscriptions;   // cancelled this period
  double churnRate;             // cancelled / total at start of period
  double revenueProjected;     // mrr × (1 - churnRate) × 12
  Map<String, int> byPlan;     // {"artist": 5, "premium": 3, ...}
  Map<String, int> byStatus;   // {"active": 20, "cancelled": 3, ...}
  int computedAt;               // timestamp of computation

  FinancialSnapshot({
    this.id = '',
    this.mrr = 0.0,
    this.arr = 0.0,
    this.activeSubscriptions = 0,
    this.newSubscriptions = 0,
    this.cancelledSubscriptions = 0,
    this.churnRate = 0.0,
    this.revenueProjected = 0.0,
    this.byPlan = const {},
    this.byStatus = const {},
    this.computedAt = 0,
  });

  /// Convenience: growth percentage between two snapshots
  double mrrGrowthPercent(FinancialSnapshot previous) {
    if (previous.mrr <= 0) return 0.0;
    return ((mrr - previous.mrr) / previous.mrr) * 100;
  }

  /// Net revenue after applying churn estimate
  double get netMonthlyRevenue => mrr * (1 - churnRate);

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'id': id,
      'mrr': mrr,
      'arr': arr,
      'activeSubscriptions': activeSubscriptions,
      'newSubscriptions': newSubscriptions,
      'cancelledSubscriptions': cancelledSubscriptions,
      'churnRate': churnRate,
      'revenueProjected': revenueProjected,
      'byPlan': byPlan,
      'byStatus': byStatus,
      'computedAt': computedAt,
    };
  }

  FinancialSnapshot.fromJSON(Map<String, dynamic> data)
      : id = data['id'] ?? '',
        mrr = (data['mrr'] ?? 0).toDouble(),
        arr = (data['arr'] ?? 0).toDouble(),
        activeSubscriptions = data['activeSubscriptions'] ?? 0,
        newSubscriptions = data['newSubscriptions'] ?? 0,
        cancelledSubscriptions = data['cancelledSubscriptions'] ?? 0,
        churnRate = (data['churnRate'] ?? 0).toDouble(),
        revenueProjected = (data['revenueProjected'] ?? 0).toDouble(),
        byPlan = Map<String, int>.from(data['byPlan'] ?? {}),
        byStatus = Map<String, int>.from(data['byStatus'] ?? {}),
        computedAt = data['computedAt'] ?? 0;
}
