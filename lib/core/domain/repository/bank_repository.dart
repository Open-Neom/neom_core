import '../../utils/enums/app_currency.dart';

abstract class BankRepository {

  Future<bool> addAmount(String fromEmail, double amount, String orderId, {AppCurrency appCurrency = AppCurrency.appCoin, String reason = ''});
  Future<bool> subtractAmount(String fromEmail, double amount, {AppCurrency appCurrency = AppCurrency.appCoin, String? orderId, String reason = ''});

}
