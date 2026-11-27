import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/subscription_plan.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

void main() {
  group('SubscriptionPlan.fromJSON', () {
    test('maps legacy publish level to SubscriptionLevel.platinum', () {
      final plan = SubscriptionPlan.fromJSON({
        'id': 'publish',
        'name': 'publishPlan',
        'level': 'publish',
        'priceId': 'price_1Q8TjkHpVUHkmiYFfDmz1GBw',
        'productId': 'prod_R0Ujpm5bhLOLWY',
        'isActive': true,
        'isLive': true,
      });

      expect(plan.level, SubscriptionLevel.platinum);
    });

    test('preserves standard levels across EMXI plans', () {
      final expected = <String, SubscriptionLevel>{
        'basic': SubscriptionLevel.basic,
        'plus': SubscriptionLevel.plus,
        'creator': SubscriptionLevel.creator,
        'artist': SubscriptionLevel.artist,
        'professional': SubscriptionLevel.professional,
        'premium': SubscriptionLevel.premium,
        'platinum': SubscriptionLevel.platinum,
      };

      for (final entry in expected.entries) {
        final plan = SubscriptionPlan.fromJSON({
          'id': entry.key,
          'level': entry.key,
        });
        expect(plan.level, entry.value);
      }
    });
  });
}
