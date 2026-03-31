import '../../utils/enums/fan_tier.dart';
import 'fan_segment.dart';

/// Aggregated fan breakdown for a creator.
class FanBreakdown {
  final List<FanSegment> segments;

  const FanBreakdown(this.segments);

  int get superfanCount => segments.where((s) => s.tier == FanTier.superfan).length;
  int get fanCount => segments.where((s) => s.tier == FanTier.fan).length;
  int get supporterCount => segments.where((s) => s.tier == FanTier.supporter).length;
  int get casualCount => segments.where((s) => s.tier == FanTier.casual).length;
  int get totalCount => segments.length;

  List<FanSegment> get superfans => segments.where((s) => s.tier == FanTier.superfan).toList();
  List<FanSegment> get fans => segments.where((s) => s.tier == FanTier.fan).toList();

  /// Empty breakdown
  static const empty = FanBreakdown([]);
}
