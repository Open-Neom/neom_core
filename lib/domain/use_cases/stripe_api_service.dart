import 'dart:core';

import '../model/stripe/stripe_price.dart';
import '../model/stripe/stripe_product.dart';
import '../model/stripe/stripe_session.dart';

abstract class StripeApiService {

  Future<StripeCheckoutSession> createCheckoutSessionUrl(String email, String priceId, {int trialPeriodDays = 0});
  Future<String> getSubscriptionId(String sessionId);
  Future<String> getCustomerId(String sessionId);
  Future<bool> cancelSubscription(String subscriptionId);
  Future<void> getSubscriptionDetails(String subscriptionId);
  Future<void> getCustomerIdByEmail(String email);
  Future<void> getSubscriptionsFromCustomer(String customerId);
  Future<List<StripeProduct>> getProducts();
  Future<StripeProduct?> getProductById(String productId);
  Future<StripePrice?> getPrice(String priceId);
  Future<List<StripePrice>> getProductPrices(String productId);
  Future<Map<String, List<StripePrice>>> getRecurringPricesFromStripe();
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency);

}
