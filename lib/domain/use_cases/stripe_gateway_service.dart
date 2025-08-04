import '../model/address.dart';
import '../model/app_transaction.dart';

abstract class StripeGatewayService {

  Future<void> init();
  Future<void> handlePayment();
  Future<void> handlePaymentMethod(AppTransaction transaction, {
    String name = '', String email = '', String phone = '', Address? address
  });

  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency);
  Future<void> confirmIntent(String paymentIntentId);

}
