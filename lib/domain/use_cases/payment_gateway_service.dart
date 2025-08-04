import 'dart:async';



abstract class PaymentGatewayService {

  Future<void> handleProcessedTransaction();
  Future<void> handleStripePayment();
  Future<void> generateAndInsertInvoice();

}
