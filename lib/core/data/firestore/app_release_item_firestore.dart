import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_release_item.dart';
import '../../domain/repository/app_release_item_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class AppReleaseItemFirestore implements AppReleaseItemRepository {

  var logger = AppUtilities.logger;
  final appReleaseItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appReleaseItems);
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<String> insert(AppReleaseItem appReleaseItem) async {
    logger.d("Adding appReleaseItem to database collection");
    String releaseItemId = "";
    try {
      DocumentReference documentReference = await appReleaseItemReference.add(
          appReleaseItem.toJSON());
      releaseItemId = documentReference.id;
      logger.d("AppReleaseItem inserted into Firestore with id: $releaseItemId");
    } catch (e) {
      logger.e(e.toString());
      logger.i("AppReleaseItem not inserted into Firestore");
    }

    return releaseItemId;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveAll() async {
    logger.t("Get all AppReleaseItem");

    Map<String, AppReleaseItem> releaseItems = {};
    try {
      QuerySnapshot querySnapshot = await appReleaseItemReference.get();
      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(queryDocumentSnapshot.data());
          releaseItem.id = queryDocumentSnapshot.id;

          if(releaseItem.isAvailable || DateTime.fromMillisecondsSinceEpoch(releaseItem.createdTime).add(const Duration(days: 28)).millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch) {
            releaseItems[releaseItem.id] = releaseItem;
          }
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.t("${releaseItems.length} releaseItems found");
    return releaseItems;
  }

  @override
  Future<AppReleaseItem> retrieve(String releaseItemId) async {
    logger.d("Getting item $releaseItemId");
    AppReleaseItem appReleaseItem = AppReleaseItem();
    try {
      await appReleaseItemReference.doc(releaseItemId).get().then((doc) {
        if (doc.exists) {
          appReleaseItem = AppReleaseItem.fromJSON(doc.data());
          appReleaseItem.id = doc.id;
          logger.d("AppReleaseItem ${appReleaseItem.name} was retrieved with details");
        } else {
          logger.d("AppReleaseItem not found");
        }
      });
    } catch (e) {
      logger.d(e);
      rethrow;
    }
    return appReleaseItem;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveFromList(List<String> releaseItemIds) async {
    logger.t("Getting ${releaseItemIds}appReleaseItems from list");

    Map<String, AppReleaseItem> appItems = {};

    try {
      QuerySnapshot querySnapshot = await appReleaseItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          if(releaseItemIds.contains(documentSnapshot.id)){
            AppReleaseItem releaseItem = AppReleaseItem.fromJSON(documentSnapshot.data());
            logger.d("AppReleaseItem ${releaseItem.name} was retrieved with details");
            appItems[documentSnapshot.id] = releaseItem;
          }
        }
      }

    } catch (e) {
      logger.d(e);
    }
    return appItems;
  }

  @override
  Future<bool> remove(AppReleaseItem appReleaseItem) async {
    logger.d("Removing appReleaseItem ${appReleaseItem.name} with id ${appReleaseItem.id} from database collection");
    try {
      await appReleaseItemReference.doc(appReleaseItem.id).delete();
      return true;
    } catch (e) {
      logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addBoughtUser({required String releaseItemId, required String userId}) async {
    logger.t("$releaseItemId would add User $userId");

    try {
      await appReleaseItemReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == releaseItemId) {
            await document.reference
                .update({AppFirestoreConstants.boughtUsers: FieldValue.arrayUnion([userId])});

          }
        }
      });

      logger.d("$releaseItemId has added boughtItem $userId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }
    return false;
  }

}
