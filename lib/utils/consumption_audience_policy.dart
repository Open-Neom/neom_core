import 'enums/consumption_audience.dart';
import 'enums/subscription_level.dart';

/// Decides which [ConsumptionAudience] a CASETE or NUPALE session belongs to.
class ConsumptionAudiencePolicy {
  ConsumptionAudiencePolicy._();

  /// The tiers someone pays for, which put money into the royalty pool.
  ///
  /// Not a `>=` comparison: the enum's order is not the order of payment.
  /// [SubscriptionLevel.creator], [SubscriptionLevel.ambassador] and
  /// [SubscriptionLevel.artist] sit above basic but are granted, not sold
  /// (SubscriptionResolver.gemName shows them as "Free"), and
  /// [SubscriptionLevel.freeMonth] is a registered account with no
  /// subscription. [SubscriptionLevel.lifetime] is the one-time Jade
  /// founder payment.
  static const Set<SubscriptionLevel> paidLevels = {
    SubscriptionLevel.basic,
    SubscriptionLevel.plus,
    SubscriptionLevel.family,
    SubscriptionLevel.professional,
    SubscriptionLevel.corporate,
    SubscriptionLevel.premium,
    SubscriptionLevel.platinum,
    SubscriptionLevel.lifetime,
  };

  static bool isPaid(SubscriptionLevel? level) => paidLevels.contains(level);

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
