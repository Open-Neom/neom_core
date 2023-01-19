import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/app_currency.dart';

class Price {

  AppCurrency currency;
  double amount = 0.0;

  Price({
    this.amount = 0.0,
    this.currency = AppCurrency.appCoin,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'currency': currency.name,
      'amount': amount,
    };
  }

  Price.fromJSON(data) :
        currency = (data["currency"] == null) ? AppCurrency.appCoin : EnumToString.fromString(AppCurrency.values, data["currency"])!,
        amount = (data["amount"] == null) ? 0.0 : double.parse(data["amount"].toString());

}
