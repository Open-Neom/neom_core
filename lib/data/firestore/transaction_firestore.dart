import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_transaction.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../utils/enums/transaction_status.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class TransactionFirestore implements TransactionRepository {
  
  final transactionReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.transactions);

  @override
  Future<AppTransaction?> retrieve(String transactionId) async {
    AppConfig.logger.d("Retrieving AppTransaction for id $transactionId");
    AppTransaction? transaction;

    try {

      DocumentSnapshot documentSnapshot = await transactionReference.doc(transactionId).get();

      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        AppConfig.logger.d("Snapshot is not empty");
          transaction = AppTransaction.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
          transaction.id = documentSnapshot.id;
          AppConfig.logger.d(transaction.toString());
        AppConfig.logger.d("AppTransaction ${transaction.id} was retrieved");
      } else {
        AppConfig.logger.w("AppTransaction $transactionId was not found");
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return transaction;
  }


  @override
  Future<String> insert(AppTransaction transaction) async {
    AppConfig.logger.d("Inserting transaction ${transaction.id}");

    try {

      transaction.createdTime = DateTime.now().millisecondsSinceEpoch;

      if(transaction.id.isEmpty) {
        if(transaction.recipientId?.isNotEmpty ?? false) {
          transaction.id = "${transaction.recipientId}_${transaction.createdTime}";
        } else {
          transaction.id = "${transaction.senderId}_${transaction.createdTime}";
        }
      }

      if(transaction.id.isNotEmpty) {
        await transactionReference.doc(transaction.id).set(transaction.toJSON());
      } else {
        DocumentReference documentReference = await transactionReference.add(transaction.toJSON());
        transaction.id = documentReference.id;
      }
      AppConfig.logger.i("AppTransaction for Order ${transaction.orderId} was added with id ${transaction.id}");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return transaction.id;

  }


  @override
  Future<bool> remove(AppTransaction transaction) async {
    AppConfig.logger.d("Removing transaction ${transaction.id}");

    try {
      await transactionReference.doc(transaction.id).delete();
      AppConfig.logger.d("AppTransaction ${transaction.id} was removed");
      return true;

    } catch (e) {
      AppConfig.logger.e(e.toString());      
    }
    return false;
  }

  @override
  Future<bool> updateStatus(String transactionId, TransactionStatus status) async {
    AppConfig.logger.d("Updating AppTransaction Status for AppTransaction Id $transactionId to ${status.name}");

    try {
      DocumentSnapshot documentSnapshot = await transactionReference.doc(transactionId).get();
      await documentSnapshot.reference
          .update({AppFirestoreConstants.status: status.name});


      AppConfig.logger.d("AppTransaction $transactionId status was updated to ${status.name}");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("AppTransaction $transactionId status was not updated");
    return false;
  }


  @override
  Future<Map<String, AppTransaction>> retrieveFromList(List<String> transactionIds, {TransactionStatus? status}) async {
    AppConfig.logger.d("Getting transactions from list");

    Map<String, AppTransaction> transactions = {};

    try {
      QuerySnapshot querySnapshot = await transactionReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(transactionIds.contains(documentSnapshot.id)){
            final data = documentSnapshot.data();
            if (data == null) continue;
            AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
            transaction.id = documentSnapshot.id;
            AppConfig.logger.d("AppTransaction ${transaction.id} was retrieved with details");
            if(status != null && transaction.status == status) {
              transactions[transaction.id] = transaction;
            } else {
              transactions[transaction.id] = transaction;
            }
          }
        }
      }

      AppConfig.logger.d("${transactions.length} Transactions were retrieved");
    } catch (e) {
      AppConfig.logger.e(e);
    }
    return transactions;
  }

  @override
  Future<List<AppTransaction>> retrieveByOrderId(String orderId) async {
    AppConfig.logger.d("retrieveByOrderId");

    List<AppTransaction> transactions = [];

    try {
      QuerySnapshot snapshot = await transactionReference.get();

      for(var document in snapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
        if(transaction.orderId == orderId) {
          transaction.id = document.id;
          transactions.add(transaction);
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return transactions;
  }

  Future<Map<String, AppTransaction>> retrieveByEmail(String email) async {
    AppConfig.logger.d("retrieveByEmail for $email");

    Map<String, AppTransaction> transactions = {};

    try {
      QuerySnapshot snapshot = await transactionReference.get();

      for(var document in snapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
        if(transaction.senderId == email || transaction.recipientId == email) {
          transaction.id = document.id;
          transactions[transaction.id] = transaction;
        }
      }
      AppConfig.logger.d("${transactions.length} Transactions were retrieved");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return transactions;
  }
}
