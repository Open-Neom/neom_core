import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/repository/app_release_item_repository.dart';
import '../../utils/enums/release_status.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class AppReleaseItemFirestore implements AppReleaseItemRepository {
  
  final appReleaseItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appReleaseItems);
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<String> insert(AppReleaseItem appReleaseItem) async {
    AppConfig.logger.d("Adding appReleaseItem to database collection");
    String releaseItemId = appReleaseItem.id;
    try {
      if(releaseItemId.isNotEmpty) {
        await appReleaseItemReference.doc(releaseItemId).set(appReleaseItem.toJSON());
      } else {
        DocumentReference documentReference = await appReleaseItemReference.add(appReleaseItem.toJSON());
        releaseItemId = documentReference.id;
      }

      AppConfig.logger.d("AppReleaseItem inserted into Firestore with id: $releaseItemId");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppConfig.logger.i("AppReleaseItem not inserted into Firestore");
    }

    return releaseItemId;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveAll() async {
    AppConfig.logger.t("Get all AppReleaseItem");

    Map<String, AppReleaseItem> releaseItems = {};
    try {
      QuerySnapshot querySnapshot = await appReleaseItemReference.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(queryDocumentSnapshot.data());
          releaseItem.id = queryDocumentSnapshot.id;

          if(releaseItem.status == ReleaseStatus.publish || DateTime.fromMillisecondsSinceEpoch(releaseItem.createdTime).add(const Duration(days: 28)).millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
            releaseItems[releaseItem.id] = releaseItem;
          }
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${releaseItems.length} releaseItems found");
    return releaseItems;
  }

  @override
  Future<AppReleaseItem> retrieve(String releaseItemId) async {
    AppConfig.logger.d("Getting item $releaseItemId");
    AppReleaseItem appReleaseItem = AppReleaseItem();
    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appReleaseItemReference.doc(releaseItemId).get();
      if (doc.exists) {
        appReleaseItem = AppReleaseItem.fromJSON(doc.data());
        appReleaseItem.id = doc.id;
        AppConfig.logger.d("AppReleaseItem ${appReleaseItem.name} was retrieved with details");
      } else {
        AppConfig.logger.d("AppReleaseItem not found");
      }
    } catch (e) {
      AppConfig.logger.d(e);
      rethrow;
    }
    return appReleaseItem;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveFromList(List<String> releaseItemIds) async {
    AppConfig.logger.t("Getting ${releaseItemIds}appReleaseItems from list");

    Map<String, AppReleaseItem> appItems = {};
    if (releaseItemIds.isEmpty) return appItems;

    try {
      // OPTIMIZED: Use whereIn with batching instead of getting all items
      const batchSize = 30;
      for (var i = 0; i < releaseItemIds.length; i += batchSize) {
        final batch = releaseItemIds.skip(i).take(batchSize).toList();
        final querySnapshot = await appReleaseItemReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(documentSnapshot.data());
          releaseItem.id = documentSnapshot.id;
          AppConfig.logger.d("AppReleaseItem ${releaseItem.name} was retrieved with details");
          appItems[documentSnapshot.id] = releaseItem;
        }
      }
    } catch (e) {
      AppConfig.logger.d(e);
    }
    return appItems;
  }

  @override
  Future<bool> remove(AppReleaseItem appReleaseItem) async {
    AppConfig.logger.d("Removing appReleaseItem ${appReleaseItem.name} with id ${appReleaseItem.id} from database collection");
    try {
      await appReleaseItemReference.doc(appReleaseItem.id).delete();
      return true;
    } catch (e) {
      AppConfig.logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addBoughtUser({required String releaseItemId, required String userId}) async {
    AppConfig.logger.t("$releaseItemId would add user $userId");

    try {
      // OPTIMIZED: Use direct update instead of iterating all items
      await appReleaseItemReference.doc(releaseItemId).update({
        AppFirestoreConstants.boughtUsers: FieldValue.arrayUnion([userId])
      });
      AppConfig.logger.d("$releaseItemId has added user $userId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
    return false;
  }

  @override
  Future<bool> exists(String releaseItemId) async {
    AppConfig.logger.d("Getting releaseItem $releaseItemId");

    try {
      if (releaseItemId.isEmpty) return false;
      // OPTIMIZED: Use await instead of .then()
      final doc = await appReleaseItemReference.doc(releaseItemId).get();
      if (doc.exists) {
        AppConfig.logger.d("AppMediaItem found");
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e);
    }
    AppConfig.logger.d("AppMediaItem not found");
    return false;
  }

  Future<void> existsOrInsert(AppReleaseItem releaseItem) async {
    AppConfig.logger.t("existsOrInsert releaseItem ${releaseItem.id}");

    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appReleaseItemReference.doc(releaseItem.id).get();
      if (doc.exists) {
        AppConfig.logger.t("AppReleaseItem found");
      } else {
        AppConfig.logger.d("AppReleaseItem ${releaseItem.id}. ${releaseItem.name} not found. Inserting");
        await insert(releaseItem);
      }
    } catch (e) {
      AppConfig.logger.e(e);
    }
  }

  /// Updates specific fields of an AppReleaseItem
  Future<bool> updateFields(String releaseItemId, Map<String, dynamic> fields) async {
    AppConfig.logger.d("Updating appReleaseItem $releaseItemId fields");
    try {
      await appReleaseItemReference.doc(releaseItemId).update(fields);
      AppConfig.logger.d("AppReleaseItem $releaseItemId updated successfully");
      return true;
    } catch (e) {
      AppConfig.logger.e("Error updating AppReleaseItem: $e");
      return false;
    }
  }

}
