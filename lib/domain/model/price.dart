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

  Price.fromJSON(data) :
        amount = (data["amount"] == null) ? 0.0 : double.parse(data["amount"].toString()),
        currency = (data["currency"] == null) ? AppCurrency.appCoin : EnumToString.fromString(AppCurrency.values, data["currency"])!;

  Price.fromStripe(StripePrice stripePrice) :
        amount = stripePrice.unitAmount,
        currency = EnumToString.fromString(AppCurrency.values, stripePrice.currency)!;

}
