import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/app_currency.dart';
import 'stripe/stripe_price.dart';

class Price {

  AppCurrency currency;
  double amount = 0.0;

  Price({
    this.amount = 0.0,
    this.currency = AppCurrency.appCoin,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'amount': amount,
      'currency': currency.name,
    };
  }

  Price.fromJSON(dynamic data) :
        amount = (data["amount"] == null) ? 0.0 : double.parse(data["amount"].toString()),
        currency = EnumToString.fromString(AppCurrency.values, data["currency"] ?? AppCurrency.appCoin.name) ?? AppCurrency.appCoin;

  Price.fromStripe(StripePrice stripePrice) :
        amount = stripePrice.unitAmount,
        currency = EnumToString.fromString(AppCurrency.values, stripePrice.currency)!;

}
