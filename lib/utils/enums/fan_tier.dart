/// Fan engagement tiers based on consumption patterns.
///
/// Calculated from session data (pages read / seconds listened) relative
/// to other fans of the same creator. Uses percentile-based thresholds:
/// - Superfan: top 5% of engagement
/// - Fan: top 20%
/// - Supporter: top 50%
/// - Casual: bottom 50%
enum FanTier {
  /// Top 5% — highest engagement, most loyal
  superfan(4, 'superfan'),

  /// Top 20% — regular, recurring engagement
  fan(3, 'fan'),

  /// Top 50% — moderate engagement
  supporter(2, 'supporter'),

  /// Bottom 50% — occasional or one-time
  casual(1, 'casual');

  final int value;
  final String label;

  const FanTier(this.value, this.label);
}
