import 'dart:async';
import '../model/app_coupon.dart';

abstract class CouponRepository {

  Future<String> insert(AppCoupon coupon);
  Future<Map<String, AppCoupon>> getCoupons();
  Future<AppCoupon> getCouponByCode(String couponCode);
  Future<bool> addUsedBy(String couponId, String email);

}
