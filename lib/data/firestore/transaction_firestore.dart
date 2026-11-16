import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_transaction.dart';
import '../../domain/repository/transaction_repository.dart';
import '../../utils/enums/transaction_status.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class TransactionFirestore implements TransactionRepository {

  CollectionReference<Map<String, dynamic>> get transactionReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.transactions);

  @override
  Future<AppTransaction?> retrieve(String transactionId) async {
    final cleanId = transactionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return null;
    AppConfig.logger.d("Retrieving AppTransaction for id $cleanId");
    AppTransaction? transaction;

    try {
      DocumentSnapshot documentSnapshot = await transactionReference.doc(cleanId).get();

      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        AppConfig.logger.d("Snapshot is not empty");
        transaction = AppTransaction.fromJSON(documentSnapshot.data() as Map<String, dynamic>);
        transaction.id = documentSnapshot.id;
        AppConfig.logger.d("AppTransaction ${transaction.id} was retrieved");
      } else {
        AppConfig.logger.w("AppTransaction $cleanId was not found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.retrieve');
    }
    return transaction;
  }


  @override
  Future<String> insert(AppTransaction transaction) async {
    if (!transaction.amount.isFinite || transaction.amount < 0) {
      AppConfig.logger.w("Rejected AppTransaction with invalid amount: ${transaction.amount}");
      return '';
    }
    AppConfig.logger.d("Inserting transaction ${transaction.id}");

    try {
      transaction.createdTime = DateTime.now().millisecondsSinceEpoch;

      if (transaction.id.trim().isEmpty) {
        final recipient = CoreFirestoreGuard.sanitizeFieldSegment(
          transaction.recipientId ?? '',
          maxChars: 96,
        );
        final sender = CoreFirestoreGuard.sanitizeFieldSegment(
          transaction.senderId ?? '',
          maxChars: 96,
        );
        if (recipient.isNotEmpty) {
          transaction.id = "${recipient}_${transaction.createdTime}";
        } else if (sender.isNotEmpty) {
          transaction.id = "${sender}_${transaction.createdTime}";
        }
      }

      if (transaction.id.trim().isNotEmpty) {
        final cleanId = transaction.id.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        transaction.id = cleanId;
        await transactionReference.doc(cleanId).set(transaction.toJSON());
      } else {
        DocumentReference documentReference = await transactionReference.add(transaction.toJSON());
        transaction.id = documentReference.id;
      }
      AppConfig.logger.i("AppTransaction for Order ${transaction.orderId} was added with id ${transaction.id}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.insert');
    }

    return transaction.id;
  }


  @override
  Future<bool> remove(AppTransaction transaction) async {
    final cleanId = transaction.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Removing transaction $cleanId");

    try {
      await transactionReference.doc(cleanId).delete();
      AppConfig.logger.d("AppTransaction $cleanId was removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.remove');
    }
    return false;
  }

  @override
  Future<bool> updateStatus(String transactionId, TransactionStatus status) async {
    final cleanId = transactionId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Updating AppTransaction Status for AppTransaction Id $cleanId to ${status.name}");

    try {
      await transactionReference
          .doc(cleanId)
          .update({AppFirestoreConstants.status: status.name});

      AppConfig.logger.d("AppTransaction $cleanId status was updated to ${status.name}");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.updateStatus');
    }

    AppConfig.logger.d("AppTransaction $cleanId status was not updated");
    return false;
  }


  @override
  Future<Map<String, AppTransaction>> retrieveFromList(List<String> transactionIds, {TransactionStatus? status}) async {
    AppConfig.logger.d("Getting transactions from list (${transactionIds.length} ids)");

    Map<String, AppTransaction> transactions = {};
    final chunks = CoreFirestoreGuard.chunkValidIds(transactionIds);
    if (chunks.isEmpty) return transactions;

    try {
      for (final batch in chunks) {
        QuerySnapshot querySnapshot = await transactionReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          final data = documentSnapshot.data();
          if (data == null) continue;
          AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
          transaction.id = documentSnapshot.id;
          if (status != null && transaction.status != status) continue;
          transactions[transaction.id] = transaction;
        }
      }

      AppConfig.logger.d("${transactions.length} Transactions were retrieved");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.retrieveFromList');
    }
    return transactions;
  }

  @override
  Future<List<AppTransaction>> retrieveByOrderId(String orderId) async {
    final cleanOrderId = orderId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanOrderId)) return [];
    AppConfig.logger.d("retrieveByOrderId: $cleanOrderId");

    List<AppTransaction> transactions = [];

    try {
      QuerySnapshot snapshot = await transactionReference
          .where('orderId', isEqualTo: cleanOrderId)
          .limit(200)
          .get();

      for (var document in snapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
        transaction.id = document.id;
        transactions.add(transaction);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.retrieveByOrderId');
    }

    return transactions;
  }

  Future<Map<String, AppTransaction>> retrieveByEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return {};
    AppConfig.logger.d("retrieveByEmail for $cleanEmail");

    Map<String, AppTransaction> transactions = {};

    try {
      QuerySnapshot senderSnapshot = await transactionReference
          .where('senderId', isEqualTo: cleanEmail)
          .orderBy('createdTime', descending: true)
          .limit(200)
          .get();

      for (var document in senderSnapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
        transaction.id = document.id;
        transactions[transaction.id] = transaction;
      }

      QuerySnapshot recipientSnapshot = await transactionReference
          .where('recipientId', isEqualTo: cleanEmail)
          .orderBy('createdTime', descending: true)
          .limit(200)
          .get();

      for (var document in recipientSnapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        AppTransaction transaction = AppTransaction.fromJSON(data as Map<String, dynamic>);
        transaction.id = document.id;
        transactions[transaction.id] = transaction;
      }

      AppConfig.logger.d("${transactions.length} Transactions were retrieved");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'TransactionFirestore.retrieveByEmail');
    }

    return transactions;
  }
}
