import 'enums/consumption_audience.dart';
import 'enums/subscription_level.dart';

/// Decides which [ConsumptionAudience] a CASETE or NUPALE session belongs to.
class ConsumptionAudiencePolicy {
  ConsumptionAudiencePolicy._();

  /// A tier that brings subscription revenue into the royalty pool.
  /// [SubscriptionLevel.freeMonth] is a trial of a paid plan and pays
  /// nothing, so it is not one.
  static bool isPaid(SubscriptionLevel? level) =>
      level != null && level.value >= SubscriptionLevel.basic.value;

  /// Authorship wins over the tier: an author on a paid plan is still an
  /// author, and their time must not reach the pool.
  static ConsumptionAudience classify({
    required bool isAuthor,
    required SubscriptionLevel? level,
  }) {
    if (isAuthor) return ConsumptionAudience.author;
    return isPaid(level) ? ConsumptionAudience.member : ConsumptionAudience.freeTier;
  }
}
