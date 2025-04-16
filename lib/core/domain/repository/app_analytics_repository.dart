import 'dart:async';
import '../model/analytics/user_locations.dart';
import '../model/app_coupon.dart';

abstract class AppAnalyticsRepository {


  Future<List<UserLocations>> getUserLocations();
  Future<Map<String, AppCoupon>> getUserAnalytics();
  Future<AppCoupon> getAnalyticsByType(String couponCode);
  Future<void> setUserLocations();

}
