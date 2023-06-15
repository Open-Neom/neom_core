import 'dart:async';
import '../model/app_analytics.dart';
import '../model/app_coupon.dart';

abstract class AppAnalyticsRepository {


  Future<List<AppAnalytics>> getAnalytics();
  Future<Map<String, AppCoupon>> getUserAnalytics();
  Future<AppCoupon> getAnalyticsByType(String couponCode);
  Future<void> setUserAnalytics();

}
