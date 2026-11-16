import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/subscription_access_resolution.dart';
import 'package:neom_core/domain/model/user_subscription.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';

void main() {
  const now = 1700000000000;
  test('valid active subscription wins even when another is suspended', () {
    final failed = UserSubscription(
      subscriptionId: 'old',
      status: SubscriptionStatus.suspended,
      level: SubscriptionLevel.premium,
    );
    final active = UserSubscription(
      subscriptionId: 'new',
      status: SubscriptionStatus.active,
      level: SubscriptionLevel.basic,
      endDate: now + 1,
    );
    for (final plans in [
      [failed, active],
      [active, failed],
    ]) {
      final result = SubscriptionAccessResolution.resolve(plans, now: now);
      expect(result.selected, same(active));
      expect(result.suspended, isFalse);
    }
  });
  test(
    'suspension removes paid entitlement without invalidating the account',
    () {
      final result = SubscriptionAccessResolution.resolve([
        UserSubscription(
          status: SubscriptionStatus.suspended,
          level: SubscriptionLevel.basic,
        ),
      ], now: now);
      expect(result.selected, isNull);
      expect(result.suspended, isTrue);
    },
  );
  test('trial and grace remain usable only before expiry', () {
    final trial = UserSubscription(
      status: SubscriptionStatus.trial,
      level: SubscriptionLevel.freeMonth,
      endDate: now + 1,
    );
    final due = UserSubscription(
      status: SubscriptionStatus.pastDue,
      level: SubscriptionLevel.basic,
      graceUntil: now + 1,
    );
    expect(
      SubscriptionAccessResolution.resolve([trial, due], now: now).selected,
      same(due),
    );
    expect(
      SubscriptionAccessResolution.resolve([trial, due], now: now + 1).selected,
      isNull,
    );
    expect(
      SubscriptionAccessResolution.resolve([
        trial,
        due,
      ], now: now + 1).suspended,
      isTrue,
    );
  });
  test('expired paid plans cannot hide another valid lower tier', () {
    final expired = UserSubscription(
      status: SubscriptionStatus.active,
      level: SubscriptionLevel.premium,
      endDate: now,
    );
    final current = UserSubscription(
      status: SubscriptionStatus.active,
      level: SubscriptionLevel.basic,
      endDate: now + 1,
    );
    expect(
      SubscriptionAccessResolution.resolve([
        expired,
        current,
      ], now: now).selected,
      same(current),
    );
  });
  test(
    'Stripe trialing status maps to a valid trial; canceled has no access',
    () {
      final trial = UserSubscription.fromJSON({
        'status': 'trialing',
        'endDate': now + 1,
        'level': 'freeMonth',
      });
      final canceled = UserSubscription.fromJSON({
        'status': 'canceled',
        'level': 'basic',
      });
      expect(
        SubscriptionAccessResolution.resolve([
          trial,
          canceled,
        ], now: now).selected,
        same(trial),
      );
      expect(
        SubscriptionAccessResolution.resolve([canceled], now: now).selected,
        isNull,
      );
    },
  );
  test('verified overdue grace supersedes old period end and expires on time', () {
    final overdue = UserSubscription.fromJSON({
      'status': 'active', 'billingStatus': 'past_due', 'graceUntil': now + 10,
      'endDate': now - 100, 'level': 'basic',
    });
    expect(SubscriptionAccessResolution.resolve([overdue], now: now).selected, same(overdue));
    final expired = SubscriptionAccessResolution.resolve([overdue], now: now + 10);
    expect(expired.selected, isNull);
    expect(expired.suspended, isTrue);
  });
}
