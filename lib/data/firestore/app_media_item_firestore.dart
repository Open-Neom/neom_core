import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_media_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/repository/app_media_item_repository.dart';
import '../../utils/enums/media_item_type.dart';
import 'constants/app_firestore_collection_constants.dart';

class AppMediaItemFirestore implements AppMediaItemRepository {

  final appMediaItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appMediaItems);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<AppMediaItem> retrieve(String itemId) async {
    AppConfig.logger.d("Getting item $itemId");
    AppMediaItem appMediaItem = AppMediaItem();
    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appMediaItemReference.doc(itemId).get();
      if (doc.exists) {
        appMediaItem = AppMediaItem.fromJSON(jsonEncode(doc.data()));
        AppConfig.logger.d("AppMediaItem ${appMediaItem.name} was retrieved with details");
      } else {
        AppConfig.logger.d("AppMediaItem not found");
      }
    } catch (e) {
      AppConfig.logger.d(e);
      rethrow;
    }
    return appMediaItem;
  }


  /// OPTIMIZED: Added pagination support with limit parameter
  @override
  Future<Map<String, AppMediaItem>> fetchAll({ int minItems = 0, int maxLength = 100,
    MediaItemType? type, List<MediaItemType>? excludeTypes, int? limit}) async {
    AppConfig.logger.t("Getting appMediaItems from list (limit: $limit)");

    Map<String, AppMediaItem> appMediaItems = {};

    try {
      // OPTIMIZATION: Apply limit to query if specified
      Query query = appMediaItemReference;
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.t("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          AppMediaItem appMediaItem = AppMediaItem.fromJSON(documentSnapshot.data());
          appMediaItem.id = documentSnapshot.id;

          if((type == null || appMediaItem.type == type)
              && (excludeTypes == null || !excludeTypes.contains(appMediaItem.type))) {
            appMediaItems[appMediaItem.id] = appMediaItem;
          }
          AppConfig.logger.t("Add ${appMediaItem.name} to fetchAll list");
        }
      }
    } catch (e) {
      AppConfig.logger.d(e);
    }

    AppConfig.logger.d("${appMediaItems.length} appMediaItems found");
    return appMediaItems;
  }

  @override
  Future<Map<String, AppMediaItem>> retrieveFromList(List<String> appMediaItemIds) async {
    AppConfig.logger.t("Getting ${appMediaItemIds.length} appMediaItems from firestore");

    Map<String, AppMediaItem> appMediaItems = {};
    if (appMediaItemIds.isEmpty) return appMediaItems;

    try {
      // OPTIMIZED: Use whereIn with batching instead of getting all items
      const batchSize = 30;
      for (var i = 0; i < appMediaItemIds.length; i += batchSize) {
        final batch = appMediaItemIds.skip(i).take(batchSize).toList();
        final querySnapshot = await appMediaItemReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          AppMediaItem appMediaItem = AppMediaItem.fromJSON(documentSnapshot.data());
          appMediaItem.id = documentSnapshot.id;
          AppConfig.logger.d("AppMediaItem ${appMediaItem.name} was retrieved with details");
          appMediaItems[documentSnapshot.id] = appMediaItem;
        }
      }
    } catch (e) {
      AppConfig.logger.d(e);
    }
    return appMediaItems;
  }

  @override
  Future<bool> exists(String appMediaItemId) async {
    AppConfig.logger.d("Getting appMediaItem $appMediaItemId");

    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appMediaItemReference.doc(appMediaItemId).get();
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

  @override
  Future<void> insert(AppMediaItem appMediaItem) async {
    AppConfig.logger.t("Adding appMediaItem to database collection");

    try {
      await appMediaItemReference.doc(appMediaItem.id).set(appMediaItem.toJSON());
      AppConfig.logger.d("AppMediaItem inserted into Firestore");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppConfig.logger.i("AppMediaItem not inserted into Firestore");
    }

  }

  @override
  Future<bool> remove(AppMediaItem appMediaItem) async {
    AppConfig.logger.d("Removing appMediaItem from database collection");
    try {
      await appMediaItemReference.doc(appMediaItem.id).delete();
      return true;
    } catch (e) {
      AppConfig.logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> removeItemFromList(String profileId, String itemlistId, AppMediaItem appMediaItem) async {
    AppConfig.logger.d("Removing ItemlistItem for user $profileId");

    if (profileId.isEmpty) {
      AppConfig.logger.w('Cannot remove item: profileId is empty');
      return false;
    }

    try {
      DocumentSnapshot? profileDoc;

      // First try: Query by 'id' field
      final querySnapshot = await profileReference
          .where('id', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        profileDoc = querySnapshot.docs.first;
      } else {
        // Fallback: Search by document ID (profiles use documentSnapshot.id)
        AppConfig.logger.t("Profile not found by 'id' field, searching by document ID...");
        final allProfilesSnapshot = await profileReference.get();
        for (var doc in allProfilesSnapshot.docs) {
          if (doc.id == profileId) {
            profileDoc = doc;
            AppConfig.logger.t("Profile found by document ID scan");
            break;
          }
        }
      }

      if (profileDoc != null) {
        final snapshot = await profileDoc.reference
            .collection(AppFirestoreCollectionConstants.itemlists)
            .doc(itemlistId)
            .get();

        Itemlist itemlist = Itemlist.fromJSON(snapshot.data());
        itemlist.appMediaItems?.removeWhere((element) => element.id == appMediaItem.id);
        await profileDoc.reference
            .collection(AppFirestoreCollectionConstants.itemlists)
            .doc(itemlistId)
            .update(itemlist.toJSON());

        AppConfig.logger.i("ItemlistItem ${appMediaItem.name} was updated to ${appMediaItem.state}");
        return true;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("ItemlistItem ${appMediaItem.name} was not updated");
    return false;
  }

  @override
  Future<void> existsOrInsert(AppMediaItem appMediaItem) async {
    AppConfig.logger.t("existsOrInsert appMediaItem ${appMediaItem.id}");

    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appMediaItemReference.doc(appMediaItem.id).get();
      if (doc.exists) {
        AppConfig.logger.t("AppMediaItem found");
      } else {
        AppConfig.logger.d("AppMediaItem ${appMediaItem.id}. ${appMediaItem.name} not found. Inserting");
        await insert(appMediaItem);
      }
    } catch (e) {
      AppConfig.logger.e(e);
    }

  }

}
