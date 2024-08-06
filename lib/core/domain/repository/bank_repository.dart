import '../../utils/enums/app_currency.dart';

abstract class BankRepository {

  Future<bool> addAmount(String profileId, double amount, String orderId, {AppCurrency appCurrency = AppCurrency.appCoin, String reason = ''});
  Future<bool> subtractAmount(String profileId, double amount, {AppCurrency appCurrency = AppCurrency.appCoin, String? orderId, String reason = ''});

}
