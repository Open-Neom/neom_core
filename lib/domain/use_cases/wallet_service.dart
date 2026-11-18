import 'package:flutter/material.dart';

import '../../utils/enums/app_currency.dart';
import '../model/app_product.dart';

abstract class WalletService {

  double get balance => 0;
  Future<void> refreshWallet() async {}

  void changeAppCoinProduct(AppProduct selectedProduct);
  void setActualCurrency({required AppCurrency productCurrency});
  void changePaymentCurrency({required AppCurrency newCurrency});
  void changePaymentAmount({double newAmount = 0});
  Future<void> payAppProduct(BuildContext context);

}
