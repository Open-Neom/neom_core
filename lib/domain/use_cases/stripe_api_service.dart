import 'dart:core';

import '../model/stripe/stripe_price.dart';
import '../model/stripe/stripe_product.dart';
import '../model/stripe/stripe_session.dart';

abstract class StripeApiService {

  Future<StripeCheckoutSession> createCheckoutSessionUrl(String email, String priceId, {int trialPeriodDays = 0, String orderId = ''});
  Future<String> getSubscriptionId(String sessionId);
  Future<String> getCustomerId(String sessionId);
  /// Schedules cancellation at period end. Returns the period end timestamp (seconds since epoch), or 0 on failure.
  Future<int> cancelSubscription(String subscriptionId);
  Future<void> getSubscriptionDetails(String subscriptionId);
  Future<void> getCustomerIdByEmail(String email);
  Future<void> getSubscriptionsFromCustomer(String customerId);
  Future<List<StripeProduct>> getProducts();
  Future<StripeProduct?> getProductById(String productId);
  Future<StripePrice?> getPrice(String priceId);
  Future<List<StripePrice>> getProductPrices(String productId);
  Future<Map<String, List<StripePrice>>> getRecurringPricesFromStripe();
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency);
  Future<StripeCheckoutSession> createPaymentCheckoutSessionUrl(String email, {
    required int amountInCents, required String currency, required String productName,
    String productDescription = '', String orderId = '',
  });
  Future<StripeCheckoutSession> createFilCheckoutSession(String email, {int amount = 5000});
  Future<String> createBillingPortalSession(String customerId, {String returnUrl = ''});
  Future<Map<String, dynamic>?> getSubscriptionInfo(String subscriptionId);

  // ERP / Dashboard endpoints
  Future<Map<String, dynamic>?> getBalance();
  Future<List<Map<String, dynamic>>> getBalanceTransactions({int limit = 20});
  Future<List<Map<String, dynamic>>> getDisputes({int limit = 20});
  Future<List<Map<String, dynamic>>> getPayouts({int limit = 20});
  Future<List<Map<String, dynamic>>> getInvoices({String? customerId, int limit = 20, String? status});

}
