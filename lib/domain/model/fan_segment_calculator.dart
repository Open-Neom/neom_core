import '../../utils/enums/fan_tier.dart';
import 'fan_breakdown.dart';
import 'fan_metrics.dart';
import 'fan_segment.dart';
import 'fan_session_data.dart';

/// Computes fan tiers from raw session data.
///
/// Uses percentile-based approach: engagement values are sorted and
/// thresholds are derived from the distribution itself, not fixed numbers.
/// This adapts to any creator's audience size.
class FanSegmentCalculator {

  /// Build fan segments for a specific creator from session-level data.
  ///
  /// [sessionsPerFan] maps fan email → list of (itemId, engagement, createdMonth).
  /// Each tuple represents one session's contribution.
  static FanBreakdown calculate({
    required String creatorEmail,
    required Map<String, List<FanSessionData>> sessionsPerFan,
  }) {
    if (sessionsPerFan.isEmpty) return FanBreakdown.empty;

    // Aggregate per-fan metrics
    final metrics = <String, FanMetrics>{};
    for (final entry in sessionsPerFan.entries) {
      final email = entry.key;
      final sessions = entry.value;

      final totalEngagement = sessions.fold<int>(0, (sum, s) => sum + s.engagement);
      final sessionCount = sessions.length;
      final worksConsumed = sessions.map((s) => s.itemId).toSet().length;
      final activeMonths = sessions.map((s) => s.monthKey).toSet().length;

      metrics[email] = FanMetrics(
        email: email,
        totalEngagement: totalEngagement,
        sessionCount: sessionCount,
        worksConsumed: worksConsumed,
        activeMonths: activeMonths,
      );
    }

    // Sort by total engagement to determine percentile thresholds
    final sortedEngagements = metrics.values.map((m) => m.totalEngagement).toList()..sort();
    final count = sortedEngagements.length;

    // Percentile thresholds
    final p50 = sortedEngagements[(count * 0.50).floor().clamp(0, count - 1)];
    final p80 = sortedEngagements[(count * 0.80).floor().clamp(0, count - 1)];
    final p95 = sortedEngagements[(count * 0.95).floor().clamp(0, count - 1)];

    // Assign tiers
    final segments = metrics.entries.map((entry) {
      final m = entry.value;
      FanTier tier;

      if (m.totalEngagement >= p95 && m.sessionCount >= 3) {
        tier = FanTier.superfan;
      } else if (m.totalEngagement >= p80 && m.sessionCount >= 2) {
        tier = FanTier.fan;
      } else if (m.totalEngagement >= p50) {
        tier = FanTier.supporter;
      } else {
        tier = FanTier.casual;
      }

      return FanSegment(
        email: m.email,
        creatorEmail: creatorEmail,
        totalEngagement: m.totalEngagement,
        sessionCount: m.sessionCount,
        worksConsumed: m.worksConsumed,
        activeMonths: m.activeMonths,
        tier: tier,
      );
    }).toList();

    // Sort by tier (highest first), then by engagement
    segments.sort((a, b) {
      final tierCmp = b.tier.value.compareTo(a.tier.value);
      if (tierCmp != 0) return tierCmp;
      return b.totalEngagement.compareTo(a.totalEngagement);
    });

    return FanBreakdown(segments);
  }

  /// Determine what tier the current user has for a specific creator.
  ///
  /// [userEngagement] is the user's total pages/seconds for this creator.
  /// [allEngagements] is the list of ALL fans' total engagement for comparison.
  static FanTier tierForUser({
    required int userEngagement,
    required int userSessionCount,
    required List<int> allEngagements,
  }) {
    if (allEngagements.isEmpty) return FanTier.casual;

    final sorted = List<int>.from(allEngagements)..sort();
    final count = sorted.length;
    final p50 = sorted[(count * 0.50).floor().clamp(0, count - 1)];
    final p80 = sorted[(count * 0.80).floor().clamp(0, count - 1)];
    final p95 = sorted[(count * 0.95).floor().clamp(0, count - 1)];

    if (userEngagement >= p95 && userSessionCount >= 3) return FanTier.superfan;
    if (userEngagement >= p80 && userSessionCount >= 2) return FanTier.fan;
    if (userEngagement >= p50) return FanTier.supporter;
    return FanTier.casual;
  }
}
