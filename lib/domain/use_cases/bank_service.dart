import 'dart:async';

import '../../utils/enums/transaction_type.dart';
import '../model/app_transaction.dart';


abstract class BankService {

  Future<void> init();
  Future<bool> processTransaction(AppTransaction transaction);
  Future<bool> addCoinsToWallet(String walletId, double amount,
      {TransactionType transactionType = TransactionType.purchase});

}
