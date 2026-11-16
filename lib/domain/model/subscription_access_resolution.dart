import '../../utils/enums/subscription_level.dart';
import '../../utils/enums/subscription_status.dart';
import 'user_subscription.dart';

/// Selects a usable plan independently of the order returned by Firestore.
/// A failed plan must not mask another paid plan or an unexpired trial.
class SubscriptionAccessResolution {
  const SubscriptionAccessResolution({
    required this.selected,
    required this.suspended,
  });
  final UserSubscription? selected;
  final bool suspended;

  static SubscriptionAccessResolution resolve(
    List<UserSubscription> subscriptions, {
    required int now,
  }) {
    bool usable(UserSubscription sub) {
      if (sub.billingStatus == 'past_due') {
        return (sub.status == SubscriptionStatus.active ||
                sub.status == SubscriptionStatus.pastDue) &&
            (sub.graceUntil ?? 0) > now;
      }
      final notExpired = sub.endDate <= 0 || sub.endDate > now;
      if (!notExpired) return false;
      return sub.status == SubscriptionStatus.active ||
          sub.status == SubscriptionStatus.trial ||
          (sub.status == SubscriptionStatus.pastDue &&
              (sub.graceUntil ?? 0) > now);
    }

    UserSubscription? selected;
    for (final sub in subscriptions.where(usable)) {
      if (selected == null ||
          (sub.level ?? SubscriptionLevel.freemium).value >
              (selected.level ?? SubscriptionLevel.freemium).value) {
        selected = sub;
      }
    }
    final anySuspended = subscriptions.any(
      (sub) =>
          sub.status == SubscriptionStatus.suspended ||
          (sub.billingStatus == 'past_due' && (sub.graceUntil ?? 0) <= now) ||
          (sub.status == SubscriptionStatus.pastDue &&
              (sub.graceUntil ?? 0) <= now),
    );
    return SubscriptionAccessResolution(
      selected: selected,
      suspended: selected == null && anySuspended,
    );
  }
}
