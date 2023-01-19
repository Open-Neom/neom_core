import 'dart:async';
import '../model/app_coupon.dart';

abstract class CouponRepository {

  Future<Map<String, AppCoupon>> getCoupons();
  Future<AppCoupon> getCouponByCode(String couponCode);
  Future<bool> incrementUsageCount(String couponId);
  Future<String> insert(AppCoupon coupon);

}
