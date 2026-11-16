
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Add this import for UUID generation

import '../../app_config.dart';
import '../../domain/model/app_order.dart';
import '../../domain/repository/order_repository.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class OrderFirestore implements OrderRepository {

  CollectionReference<Map<String, dynamic>> get orderReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.orders);

  @override
  Future<String> insert(AppOrder order) async {
    AppConfig.logger.d("Inserting order ${order.id}");

    String orderId = '';
    try {
      if (order.id.isNotEmpty) {
        final cleanId = order.id.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        order.id = cleanId;
        await orderReference.doc(cleanId).set(order.toJSON());
      } else {
        var uuid = const Uuid();
        order.id = uuid.v4();
        await orderReference.doc(order.id).set(order.toJSON());
      }
      orderId = order.id;
      AppConfig.logger.d("Order for ${order.description} was added with id $orderId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.insert');
    }

    return orderId;
  }


  @override
  Future<bool> remove(AppOrder order) async {
    final cleanId = order.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Removing product $cleanId");

    try {
      await orderReference.doc(cleanId).delete();
      AppConfig.logger.d("Order $cleanId was removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.remove');
    }
    return false;
  }


  @override
  Future<AppOrder> retrieveOrder(String orderId) async {
    final cleanId = orderId.trim();
    AppOrder order = AppOrder();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return order;
    AppConfig.logger.d("Retrieving Order for id $cleanId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference.doc(cleanId).get();

      if (documentSnapshot.exists && documentSnapshot.data() != null) {
        AppConfig.logger.d("Snapshot is not empty");
        order = AppOrder.fromJSON(documentSnapshot.data());
        order.id = documentSnapshot.id;
        AppConfig.logger.d(order.toString());
        AppConfig.logger.d("Order ${order.id} was retrieved");
      } else {
        AppConfig.logger.w("Order $cleanId was not found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.retrieveOrder');
    }
    return order;
  }


  @override
  Future<Map<String, AppOrder>> retrieveFromList(List<String> orderIds) async {
    AppConfig.logger.d("Getting orders from list");

    Map<String, AppOrder> orders = {};
    final chunks = CoreFirestoreGuard.chunkValidIds(orderIds);
    if (chunks.isEmpty) return orders;

    try {
      for (final chunk in chunks) {
        final querySnapshot = await orderReference
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          AppOrder order = AppOrder.fromJSON(documentSnapshot.data());
          order.id = documentSnapshot.id;
          orders[order.id] = order;
        }
      }

      AppConfig.logger.d("${orders.length} Orders were retrieved");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.retrieveFromList');
    }
    return orders;
  }


  @override
  Future<bool> addInvoiceId({required String orderId, required String invoiceId}) async {
    final cleanOrderId = orderId.trim();
    final cleanInvoiceId = invoiceId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanOrderId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanInvoiceId)) {
      return false;
    }
    AppConfig.logger.d("Invoice $cleanInvoiceId would be added to order $cleanOrderId");

    try {
      await orderReference.doc(cleanOrderId).update({
        AppFirestoreConstants.invoiceIds: FieldValue.arrayUnion([cleanInvoiceId])
      });
      AppConfig.logger.d("Invoice $cleanInvoiceId is now at Order $cleanOrderId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.addInvoiceId');
    }

    return false;
  }


  @override
  Future<bool> removeInvoiceId({required String orderId, required String invoiceId}) async {
    final cleanOrderId = orderId.trim();
    final cleanInvoiceId = invoiceId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanOrderId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanInvoiceId)) {
      return false;
    }
    AppConfig.logger.d("Invoice $cleanInvoiceId would be removed from order $cleanOrderId");

    try {
      await orderReference.doc(cleanOrderId).update({
        AppFirestoreConstants.invoiceIds: FieldValue.arrayRemove([cleanInvoiceId])
      });
      AppConfig.logger.d("Invoice $cleanInvoiceId was removed from Order $cleanOrderId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.removeInvoiceId');
    }

    return false;
  }


  @override
  Future<bool> addPaymentId({required String orderId, required String paymentId}) async {
    final cleanOrderId = orderId.trim();
    final cleanPaymentId = paymentId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanOrderId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanPaymentId)) {
      return false;
    }
    AppConfig.logger.d("Payment $cleanPaymentId would be added to order $cleanOrderId");

    try {
      await orderReference.doc(cleanOrderId).update({
        AppFirestoreConstants.paymentIds: FieldValue.arrayUnion([cleanPaymentId])
      });
      AppConfig.logger.d("Payment $cleanPaymentId is now at Order $cleanOrderId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.addPaymentId');
    }

    return false;
  }


  @override
  Future<bool> removePaymentId({required String orderId, required String paymentId}) async {
    final cleanOrderId = orderId.trim();
    final cleanPaymentId = paymentId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanOrderId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanPaymentId)) {
      return false;
    }
    AppConfig.logger.d("Payment $cleanPaymentId would be removed from order $cleanOrderId");

    try {
      await orderReference.doc(cleanOrderId).update({
        AppFirestoreConstants.paymentIds: FieldValue.arrayRemove([cleanPaymentId])
      });
      AppConfig.logger.d("Payment $cleanPaymentId was removed from Order $cleanOrderId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'OrderFirestore.removePaymentId');
    }

    return false;
  }

}
