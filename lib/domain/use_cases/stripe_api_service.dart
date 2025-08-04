import 'dart:core';

import '../model/stripe/stripe_price.dart';
import '../model/stripe/stripe_product.dart';
import '../model/stripe/stripe_session.dart';

abstract class StripeApiService {

  Future<StripeCheckoutSession> createCheckoutSessionUrl(String email, String priceId, {bool isDebug = false, int trialPeriodDays = 0});
  Future<String> getSubscriptionId(String sessionId, {bool? isDebug});
  Future<String> getCustomerId(String sessionId);
  Future<bool> cancelSubscription(String subscriptionId, {bool? isDebug});
  Future<void> getSubscriptionDetails(String subscriptionId);
  Future<void> getCustomerIdByEmail(String email);
  Future<void> getSubscriptionsFromCustomer(String customerId);
  Future<List<StripeProduct>> getProducts({bool isDebug = false});
  Future<StripeProduct?> getProductById(String productId, {bool isDebug = false});
  Future<StripePrice?> getPrice(String priceId, {bool isDebug = false});
  Future<List<StripePrice>> getProductPrices(String productId, {bool isDebug = false});
  Future<Map<String, List<StripePrice>>> getRecurringPricesFromStripe();

}
