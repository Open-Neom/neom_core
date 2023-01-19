import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/repository/itemlist_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class ItemlistFirestore implements ItemlistRepository {

  var logger = AppUtilities.logger;
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<bool> addAppItem(String profileId, AppItem item, String itemlistId) async {
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
              AppFirestoreConstants.appItems: FieldValue.arrayUnion([item.toJSON()])
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
  Future<bool> removeItem(String profileId, AppItem appItem, String itemlistId) async {
    logger.d("Removing item from itemlist $itemlistId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference
                .collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId)
                .update({
                  AppFirestoreConstants.appItems: FieldValue.arrayRemove([appItem.toJSON()])
                });
          }
        }
      });

      logger.d("Item was removed from itemlist $itemlistId");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Item was not  removed from itemlist $itemlistId");
    return false;
  }


  @override
  Future<String> insert(String profileId, Itemlist itemlist) async {
    logger.d("Creating itemlist for Profile $profileId");
    String itemlistId = "";

    try {
      DocumentReference? documentReference;

      await profileReference.get()
        .then((querySnapshot) {
          for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            documentReference = document.reference;
          }
        }
      });

      if(documentReference != null) {
        if(itemlist.id.isEmpty) {
          DocumentReference docRef = await documentReference!
              .collection(AppFirestoreCollectionConstants.itemlists)
              .add(itemlist.toJSON());
          itemlistId = docRef.id;
        } else {
          await documentReference!
              .collection(AppFirestoreCollectionConstants.itemlists)
              .doc(itemlist.id)
              .set(itemlist.toJSON());
          itemlistId = itemlist.id;
        }

      }

      logger.d("Itemlist $itemlistId inserted to profile $profileId");
    } catch (e) {
      logger.e(e.toString());
    }

    return itemlistId;
  }


  @override
  Future<Map<String, Itemlist>> retrieveItemlists(String profileId) async {
    logger.d("Retrieving itemlists for Profile $profileId");
    Map<String, Itemlist> itemlists = <String,Itemlist>{};

    try {
      QuerySnapshot querySnapshot = await profileReference.get();
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            QuerySnapshot querySnapshot = await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists).get();

            for (var queryDocumentSnapshot in querySnapshot.docs) {
              Itemlist itemlist = Itemlist.fromJSON(queryDocumentSnapshot.data());
              itemlist.id = queryDocumentSnapshot.id;
              itemlists[itemlist.id] = itemlist;
            }
          }
        }
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("${itemlists.length} itemlists found");
    return itemlists;
  }

  @override
  Future<bool> remove(profileId, itemlistId) async {
    logger.d("Removing $itemlistId for by $profileId");
    try {

      await profileReference.get()
        .then((querySnapshot) async {
            for (var document in querySnapshot.docs) {
          if (document.id == profileId) {
            await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists).doc(itemlistId).delete();
          }
        }
      });

      logger.d("Itemlist $itemlistId removed");
      return true;

    } catch (e) {
      logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> update(String profileId, Itemlist itemlist) async {
    logger.d("Updating Itemlist for user $profileId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists)
                .doc(itemlist.id).update({
                  AppFirestoreConstants.name: itemlist.name,
                  AppFirestoreConstants.description: itemlist.description,

                });
          }
        }
      });

      logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  @override
  Future<bool> setAsFavorite(String profileId, Itemlist itemlist) async {
    logger.d("Updating to favorite Itemlist ${itemlist.id} for user $profileId");

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            DocumentReference documentReference = document.reference.collection(
                AppFirestoreCollectionConstants.itemlists)
                .doc(itemlist.id);

            await documentReference.update({
              AppFirestoreConstants.isFav: true
            });
          }
        }
      });

      logger.d("Itemlist ${itemlist.id} was set as favorite");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }


  @override
  Future<bool> unsetOfFavorite(String profileId, Itemlist itemlist) async {
    logger.d("Updating to unFavorite Itemlist for user $profileId");
    itemlist.isFav = false;

    try {
      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.collection(
                AppFirestoreCollectionConstants.itemlists)
                .doc(itemlist.id).update({AppFirestoreConstants.isFav: false});
          }
        }
      });

      logger.d("Itemlist ${itemlist.id} was unset of favorite");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  @override
  Future<bool> updateItem(String profileId, String itemlistId, AppItem appItem) async {
    logger.d("Updating ItemlistItem for profile $profileId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).update({
              AppFirestoreConstants.appItems: FieldValue.arrayUnion([appItem.toJSON()])
            });
          }}
      });

      logger.d("ItemlistItem ${appItem.name} was updated to ${appItem.state}");
      return true;
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("ItemlistItem ${appItem.name} was not updated");
    return false;
  }

}
