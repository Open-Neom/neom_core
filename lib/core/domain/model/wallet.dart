import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enum_to_string/enum_to_string.dart';
import '../../utils/enums/app_currency.dart';

class Wallet {

  AppCurrency currency = AppCurrency.appCoin;
  double amount = 0.0;

  Wallet({
    this.amount = 0.0,
    this.currency = AppCurrency.appCoin,
  });


  Wallet.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) :
    currency =  EnumToString.fromString(AppCurrency.values,
        documentSnapshot.get("currency")) ?? AppCurrency.appCoin,
    amount = documentSnapshot.get("amount");


  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'currency': currency.name,
      'amount': amount,
    };
  }


  Wallet.fromJSON(Map<dynamic, dynamic> data) :
        currency = EnumToString.fromString(AppCurrency.values, data["currency"] ?? AppCurrency.appCoin.name) ?? AppCurrency.appCoin,
        amount = double.parse(data["amount"]?.toString() ?? "0");

}
