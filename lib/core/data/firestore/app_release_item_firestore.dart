import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_release_item.dart';
import '../../domain/repository/app_release_item_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class AppReleaseItemFirestore implements AppReleaseItemRepository {

  var logger = AppUtilities.logger;
  final appItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appItems);
  final appReleaseItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appItems);
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<String> insert(AppReleaseItem appReleaseItem) async {
    logger.d("Adding appReleaseItem to database collection");
    String releaseItemId = "";
    try {
      DocumentReference documentReference = await appItemReference.add(
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
  Future<AppReleaseItem> retrieve(String itemId) async {
    logger.d("Getting item $itemId");
    AppReleaseItem appReleaseItem = AppReleaseItem();
    try {
      await appItemReference.doc(itemId).get().then((doc) {
        if (doc.exists) {
          appReleaseItem = AppReleaseItem.fromJSON(doc.data());
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
  Future<Map<String, AppReleaseItem>> retrieveFromList(List<String> appItemIds) async {
    logger.d("Getting appItems from list");

    Map<String, AppReleaseItem> appItems = {};

    try {
      QuerySnapshot querySnapshot = await appItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        logger.d("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          if(appItemIds.contains(documentSnapshot.id)){
            AppReleaseItem appItemm = AppReleaseItem.fromJSON(documentSnapshot.data());
            logger.d("AppReleaseItem ${appItemm.name} was retrieved with details");
            appItems[documentSnapshot.id] = appItemm;
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
    logger.d("Removing appReleaseItem from database collection");
    try {
      await appItemReference.doc(appReleaseItem.id).delete();
      return true;
    } catch (e) {
      logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addAppItem(String profileId, String itemlistId, AppReleaseItem releaseItem) async {
    logger.d("Adding item for profileId $profileId");
    logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {

      QuerySnapshot querySnapshot = await profileReference.get();

      for (var document in querySnapshot.docs) {
        if(document.id == profileId) {
          await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
              .doc(itemlistId)
              .update({
            AppFirestoreConstants.appReleaseItems: FieldValue.arrayUnion([releaseItem.toJSON()])
          });

          addedItem = true;
        }
      }
    } catch (e) {
      logger.e(e.toString());
    }

    //TODO Verify if needed of if was just because async shit not well implemented
    //await Future.delayed(const Duration(seconds: 1));
    addedItem ? logger.d("AppItem was added to itemlist $itemlistId") :
    logger.d("AppItem was not added to itemlist $itemlistId");
    return addedItem;
  }

  @override
  Future<bool> removeReleaseItemFromList(String profileId, String itemlistId, AppReleaseItem releaseItem) async {
    logger.d("Removing releaseItem for profile $profileId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).update({
              AppFirestoreConstants.appReleaseItems: FieldValue.arrayRemove([releaseItem.toJSON()])
            });
          }
        }
      });

      logger.i("releaseItem ${releaseItem.name} was removed");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("releaseItem ${releaseItem.name} was not removed");
    return false;
  }

}
