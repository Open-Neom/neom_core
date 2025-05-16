// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../domain/repository/bank_repository.dart';
// import '../../utils/app_utilities.dart';
// import '../../utils/enums/app_currency.dart';
// import 'constants/app_firestore_collection_constants.dart';
// import 'constants/app_firestore_constants.dart';
//
// class BankFirestore implements BankRepository {
//
//   final bankReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.bank);
//
//   @override
//   Future<bool> addAmount(String fromEmail, double amount, String orderId, {AppCurrency appCurrency = AppCurrency.appCoin, String reason = ''}) async {
//
//     AppUtilities.logger.d("addToWallet BankFirestore from profileID $fromEmail");
//
//     try {
//       DocumentSnapshot coinsDoc = await bankReference.doc("appCoins").get();
//       Map<String, dynamic> data = coinsDoc.data() as Map<String, dynamic>;
//       double bankAmount = data['amount'] ?? 0;
//       bankAmount = bankAmount + amount;
//
//       AppUtilities.logger.i("Updating Bankto $bankAmount");
//       await coinsDoc.reference.update({
//         AppFirestoreConstants.amount: bankAmount,
//         AppFirestoreConstants.transactions: FieldValue.arrayUnion([{
//           'fromEmail': fromEmail,
//           'amount': amount,
//           'type': 'Addition',
//           'orderId': orderId,
//           'reason:': reason,
//           'date': DateTime.now().millisecondsSinceEpoch,
//         }])
//       });
//       AppUtilities.logger.d("Bank Wallet updated");
//       return true;
//     } catch (e) {
//       AppUtilities.logger.e(e.toString());
//     }
//
//     return false;
//   }
//
//   @override
//   Future<bool> subtractAmount(String fromEmail, double amount, {AppCurrency appCurrency = AppCurrency.appCoin, String? orderId, String reason = ''}) async {
//
//     AppUtilities.logger.d("subtractAmount BankFirestore from profileID $fromEmail");
//
//     try {
//       DocumentSnapshot coinsDoc = await bankReference.doc("appCoins").get();
//       Map<String, dynamic> data = coinsDoc.data() as Map<String, dynamic>;
//       double bankAmount = data['amount'] ?? 0;
//       bankAmount = bankAmount - amount;
//
//       AppUtilities.logger.i("Updating Bankto $bankAmount");
//       await coinsDoc.reference.update({
//         AppFirestoreConstants.amount: bankAmount,
//         AppFirestoreConstants.transactions: FieldValue.arrayUnion([{
//           'fromEmail': fromEmail,
//           'amount': amount,
//           'type': 'Subtraction',
//           'orderId': orderId,
//           'reason:': reason,
//           'date': DateTime.now().millisecondsSinceEpoch
//         }])
//       });
//       AppUtilities.logger.d("Bank Wallet updated");
//       return true;
//     } catch (e) {
//       AppUtilities.logger.e(e.toString());
//     }
//
//     return false;
//   }
//
// }
