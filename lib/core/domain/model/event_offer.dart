import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/app_currency.dart';

class EventOffer {

  AppCurrency currency;
  double amount;

  EventOffer({
    this.amount = 0,
    this.currency = AppCurrency.appCoin,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'currency': currency.name,
      'amount': amount,
    };
  }


  EventOffer.fromJSON(Map<dynamic, dynamic> data) :
        currency = EnumToString.fromString(AppCurrency.values, data["currency"] ?? AppCurrency.appCoin.name) ?? AppCurrency.appCoin,
        amount = data["amount"] ?? 1;

}
