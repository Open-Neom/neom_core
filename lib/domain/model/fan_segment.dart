import '../../utils/enums/fan_tier.dart';

/// A fan's engagement profile relative to a specific creator.
class FanSegment {
  /// Reader/listener email
  final String email;

  /// Creator email this segment is relative to
  final String creatorEmail;

  /// Total engagement value (pages read or seconds listened)
  final int totalEngagement;

  /// Number of distinct sessions
  final int sessionCount;

  /// Number of distinct works consumed from this creator
  final int worksConsumed;

  /// Number of distinct months with activity
  final int activeMonths;

  /// Computed fan tier
  final FanTier tier;

  const FanSegment({
    required this.email,
    required this.creatorEmail,
    required this.totalEngagement,
    required this.sessionCount,
    required this.worksConsumed,
    required this.activeMonths,
    required this.tier,
  });

  /// Whether this fan is recurring (2+ sessions)
  bool get isRecurring => sessionCount > 1;

  /// Whether this fan consumed multiple works
  bool get isMultiWork => worksConsumed > 1;
}
