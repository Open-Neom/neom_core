import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_product.dart';
import '../../domain/repository/product_repository.dart';
import '../../utils/enums/product_type.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

class ProductFirestore implements ProductRepository {
  
  CollectionReference<Map<String, dynamic>> get productReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.products);

  @override
  Future<List<AppProduct>> retrieveProductsByType({required ProductType type}) async {
    AppConfig.logger.d("Retrieving Products by type ${type.name}");
    List<AppProduct> products = [];

    try {

      QuerySnapshot querySnapshot = await productReference
          .where(AppFirestoreConstants.type, isEqualTo: type.name)
          .where(AppFirestoreConstants.isAvailable, isEqualTo: true)
          .limit(500)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.t("Snapshot is not empty");
        for (var productSnapshot in querySnapshot.docs) {
          AppProduct product = AppProduct.fromJSON(productSnapshot.data());
          product.id = productSnapshot.id;
          AppConfig.logger.t(product.toString());
          products.add(product);
        }
        AppConfig.logger.d("${products.length} products found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ProductFirestore.retrieveProductsByType');
    }
    return products;
  }


  @override
  Future<String> insert(AppProduct product) async {
    AppConfig.logger.d("Inserting product ${product.name}");
    String productId = "";

    try {
      final cleanId = product.id.trim();
      if (cleanId.isNotEmpty) {
        if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return '';
        await productReference.doc(cleanId).set(product.toJSON());
        productId = cleanId;
      } else {
        DocumentReference documentReference = await productReference
            .add(product.toJSON());
        productId = documentReference.id;
        product.id = productId;
        
      }
      AppConfig.logger.d("Product ${product.name} added with id ${product.id}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ProductFirestore.insert');
    }

    return productId;

  }


  @override
  Future<bool> remove(AppProduct product) async {
    final cleanId = product.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Removing product $cleanId");

    try {
      await productReference.doc(cleanId).delete();
      AppConfig.logger.d("Product $cleanId removed");
      return true;

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ProductFirestore.remove');
    }
    return false;
  }


}
