// AppCoupon computed-field and JSON round-trip tests.
// Coupons gate revenue-sensitive flows (discounts, free months).
// Bugs here either leak free subscriptions or reject legitimate ones.
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/app_coupon.dart';
import 'package:neom_core/utils/enums/coupon_type.dart';

void main() {
  group('AppCoupon.isExpired', () {
    test('expiresAt == 0 means never expires', () {
      final c = AppCoupon(expiresAt: 0);
      expect(c.isExpired, isFalse);
    });

    test('expiresAt in the past → expired', () {
      final c = AppCoupon(expiresAt: 1);
      expect(c.isExpired, isTrue);
    });

    test('expiresAt far in future → not expired', () {
      final far = DateTime.now()
          .add(const Duration(days: 365))
          .millisecondsSinceEpoch;
      final c = AppCoupon(expiresAt: far);
      expect(c.isExpired, isFalse);
    });
  });

  group('AppCoupon.isUsedUp', () {
    test('no usedBy + usageLimit > 0 → not used up', () {
      final c = AppCoupon(usageLimit: 5);
      expect(c.isUsedUp, isFalse);
    });

    test('usedBy.length < usageLimit → not used up', () {
      final c = AppCoupon(
          usageLimit: 3, usedBy: ['a@x.com', 'b@x.com']);
      expect(c.isUsedUp, isFalse);
    });

    test('usedBy.length == usageLimit → used up', () {
      final c = AppCoupon(
          usageLimit: 2, usedBy: ['a@x.com', 'b@x.com']);
      expect(c.isUsedUp, isTrue);
    });

    test('usageLimit == 0 with no users → used up (degenerate but predictable)',
        () {
      final c = AppCoupon(usageLimit: 0);
      expect(c.isUsedUp, isTrue,
          reason: '0 users >= 0 limit — any redemption should be blocked');
    });
  });

  group('AppCoupon.isValid', () {
    test('not expired and not used up → valid', () {
      final c = AppCoupon(expiresAt: 0, usageLimit: 100);
      expect(c.isValid, isTrue);
    });

    test('expired → invalid', () {
      final c = AppCoupon(expiresAt: 1, usageLimit: 100);
      expect(c.isValid, isFalse);
    });

    test('used up → invalid', () {
      final c = AppCoupon(usageLimit: 1, usedBy: ['x']);
      expect(c.isValid, isFalse);
    });
  });

  group('AppCoupon JSON round-trip', () {
    test('fromJSON restores core fields', () {
      final original = AppCoupon(
        id: 'ID1',
        code: 'SUMMER24',
        amount: 25.5,
        ownerEmail: 'owner@example.com',
        ownerAmount: 2.0,
        description: 'Summer promo',
        type: CouponType.oneMonthFree,
        planId: 'plan_basic',
        usageLimit: 42,
        durationMonths: 3,
        expiresAt: 1234567890,
        createdAt: 1111111111,
        usedBy: ['u1', 'u2'],
        productIds: ['p1'],
        excludedProductIds: ['px'],
        allowedEmails: ['ok@x.com'],
        excludedEmails: ['bad@x.com'],
      );

      final json = original.toJSON();
      final restored = AppCoupon.fromJSON(json);

      expect(restored.id, original.id);
      expect(restored.code, original.code);
      expect(restored.amount, original.amount);
      expect(restored.ownerEmail, original.ownerEmail);
      expect(restored.ownerAmount, original.ownerAmount);
      expect(restored.description, original.description);
      expect(restored.type, original.type);
      expect(restored.planId, original.planId);
      expect(restored.usageLimit, original.usageLimit);
      expect(restored.durationMonths, original.durationMonths);
      expect(restored.expiresAt, original.expiresAt);
      expect(restored.createdAt, original.createdAt);
      expect(restored.usedBy, original.usedBy);
      expect(restored.productIds, original.productIds);
      expect(restored.excludedProductIds, original.excludedProductIds);
      expect(restored.allowedEmails, original.allowedEmails);
      expect(restored.excludedEmails, original.excludedEmails);
    });

    test('fromJSON with missing fields uses sane defaults', () {
      final c = AppCoupon.fromJSON(<String, dynamic>{});
      expect(c.id, '');
      expect(c.code, '');
      expect(c.amount, 0);
      expect(c.type, CouponType.oneMonthFree);
      // Note: constructor default is 100 but fromJSON defaults to 25.
      expect(c.usageLimit, 25);
      expect(c.durationMonths, 1);
      expect(c.expiresAt, 0);
      expect(c.usedBy, isEmpty);
    });
  });
}
