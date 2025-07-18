import 'dart:async';
import '../model/app_coupon.dart';

import '../model/user_locations.dart';

abstract class AnalyticsRepository {

  Future<List<UserLocations>> getUserLocations();
  Future<Map<String, AppCoupon>> getUserAnalytics();
  Future<AppCoupon> getAnalyticsByType(String couponCode);
  Future<void> setUserLocations();

}
