import 'dart:async';
import '../model/app_coupon.dart';

abstract class CouponRepository {

  Future<bool> insert(AppCoupon coupon);
  Future<Map<String, AppCoupon>> fetchAll();
  Future<AppCoupon> getCouponByCode(String couponCode);
  Future<bool> addUsedBy(String couponId, String email);

}
