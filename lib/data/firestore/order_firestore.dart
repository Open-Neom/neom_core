
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Add this import for UUID generation

import '../../app_config.dart';
import '../../domain/model/app_order.dart';
import '../../domain/repository/order_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class OrderFirestore implements OrderRepository {

  final orderReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.orders);

  @override
  Future<String> insert(AppOrder order) async {
    AppConfig.logger.d("Inserting order ${order.id}");

    String orderId = '';
    try {

      if(order.id.isNotEmpty) {
        await orderReference.doc(order.id).set(order.toJSON());
      } else {
        var uuid = const Uuid();
        order.id = uuid.v4();
        await orderReference.doc(order.id).set(order.toJSON());
        // DocumentReference documentReference = await orderReference.add(order.toJSON());
        // order.id = documentReference.id;
      }
      orderId = order.id;
      AppConfig.logger.d("Order for ${order.description} was added with id $orderId");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return orderId;

  }


  @override
  Future<bool> remove(AppOrder order) async {
    AppConfig.logger.d("Removing product ${order.id}");

    try {
      await orderReference.doc(order.id).delete();
      AppConfig.logger.d("Order ${order.id} was removed");
      return true;

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }


  @override
  Future<AppOrder> retrieveOrder(String orderId) async {
    AppConfig.logger.d("Retrieving Order for id $orderId");
    AppOrder order = AppOrder();

    try {

      DocumentSnapshot documentSnapshot = await orderReference.doc(orderId).get();

      if (documentSnapshot.exists) {
        AppConfig.logger.d("Snapshot is not empty");
          order = AppOrder.fromJSON(documentSnapshot.data());
          order.id = documentSnapshot.id;
          AppConfig.logger.d(order.toString());
        AppConfig.logger.d("Order ${order.id} was retrieved");
      } else {
        AppConfig.logger.w("Order ${order.id} was not found");
      }

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return order;
  }


  @override
  Future<Map<String, AppOrder>> retrieveFromList(List<String> orderIds) async {
    AppConfig.logger.d("Getting orders from list");

    Map<String, AppOrder> orders = {};

    try {
      QuerySnapshot querySnapshot = await orderReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(orderIds.contains(documentSnapshot.id)){
            AppConfig.logger.t("DocumentSnapshot with ${documentSnapshot.id} about to be parsed");
            AppOrder order = AppOrder.fromJSON(documentSnapshot.data());
            order.id = documentSnapshot.id;
            AppConfig.logger.t("Order ${order.id} was retrieved with details");
            orders[order.id] = order;
          }
        }
      }

      AppConfig.logger.d("${orders.length} Orders were retrieved");
    } catch (e) {
      AppConfig.logger.e(e);
    }
    return orders;
  }



  @override
  Future<bool> addInvoiceId({required String orderId, required String invoiceId}) async {
    AppConfig.logger.d("Invoice $invoiceId would be added to order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.invoiceIds: FieldValue.arrayUnion([invoiceId])
      });
      AppConfig.logger.d("Invoice $invoiceId is now at Order $orderId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removeInvoiceId({required String orderId, required String invoiceId}) async {
    AppConfig.logger.d("Invoice $invoiceId would be removed from order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.invoiceIds: FieldValue.arrayRemove([invoiceId])
      });
      AppConfig.logger.d("Invoice $invoiceId was removed from Order $orderId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> addPaymentId({required String orderId, required String paymentId}) async {
    AppConfig.logger.d("Payment $paymentId would be added to order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.paymentIds: FieldValue.arrayUnion([paymentId])
      });
      AppConfig.logger.d("Payment $paymentId is now at Order $orderId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


  @override
  Future<bool> removePaymentId({required String orderId, required String paymentId}) async {
    AppConfig.logger.d("Payment $paymentId would be removed from order $orderId");

    try {
      DocumentSnapshot documentSnapshot = await orderReference
          .doc(orderId).get();

      await documentSnapshot.reference.update({
        AppFirestoreConstants.paymentIds: FieldValue.arrayRemove([paymentId])
      });
      AppConfig.logger.d("Payment $paymentId was removed from Order $orderId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return false;
  }


}
