import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_media_item.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/model/neom/chamber_preset.dart';
import '../../domain/repository/itemlist_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/enums/owner_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class ItemlistFirestore implements ItemlistRepository {
  
  final itemlistReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.itemlists);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<String> insert(Itemlist itemlist) async {
    AppUtilities.logger.d("Creating itemlist for Profile ${itemlist.ownerId}");
    String itemlistId = "";

    try {
      if(itemlist.id.isEmpty) {
        DocumentReference? documentReference = await itemlistReference
            .add(itemlist.toJSON());
        itemlistId = documentReference.id;
      } else {
        await itemlistReference.doc(itemlist.id).set(itemlist.toJSON());
        itemlistId = itemlist.id;
      }

      AppUtilities.logger.d("Public Itemlist $itemlistId inserted");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return itemlistId;
  }

  @override
  Future<bool> addAppMediaItem(AppMediaItem appMediaItem, String itemlistId) async {
    AppUtilities.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
       DocumentReference documentReference = itemlistReference.doc(itemlistId);
       if(documentReference.id.isNotEmpty) {
         await documentReference.update({
           AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([appMediaItem.toJSON()])
         });

         addedItem = true;
       }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    addedItem ? AppUtilities.logger.d("AppMediaItem was added to itemlist $itemlistId") :
    AppUtilities.logger.d("AppMediaItem was not added to itemlist $itemlistId");
    return addedItem;
  }


  @override
  Future<bool> deleteItem(AppMediaItem appMediaItem, String itemlistId) async {
    AppUtilities.logger.d("Removing item from itemlist $itemlistId");

    try {

      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      if(documentReference.id.isNotEmpty) {
        await documentReference.update({
          AppFirestoreConstants.appMediaItems: FieldValue.arrayRemove([appMediaItem.toJSON()])
        });
      }

      AppUtilities.logger.d("Item was removed from itemlist $itemlistId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("Item was not  removed from itemlist $itemlistId");
    return false;
  }

  @override
  Future<Itemlist> retrieve(String itemlistId) async {
    AppUtilities.logger.t("Retrieving Itemlist by ID: $itemlistId");
    Itemlist itemlist = Itemlist();

    try {
      DocumentSnapshot documentSnapshot = await itemlistReference.doc(itemlistId).get();
      if (documentSnapshot.exists) {
        AppUtilities.logger.t("Snapshot is not empty");
        itemlist = Itemlist.fromJSON(documentSnapshot.data());
        itemlist.id = documentSnapshot.id;
        AppUtilities.logger.t(itemlist.toString());
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }


    return itemlist;
  }

  @override
  Future<Map<String, Itemlist>> fetchAll({bool onlyPublic = false, bool excludeMyFavorites = true, int minItems = 0,
    int maxLength = 100, String ownerId = '', String excludeFromProfileId = '', OwnerType ownerType = OwnerType.profile}) async {
    AppUtilities.logger.t("Retrieving Itemlists from firestore");
    Map<String, Itemlist> itemlists = {};

    try {
      await itemlistReference.limit(maxLength).get().then((querySnapshot) {
        for (var document in querySnapshot.docs) {
          Itemlist itemlist = Itemlist.fromJSON(document.data());
          itemlist.id = document.id;
          if(itemlist.getTotalItems() >= minItems && (!onlyPublic || itemlist.public)
              && (!excludeMyFavorites || itemlist.id != AppConstants.myFavorites)
              && (ownerId.isEmpty || itemlist.ownerId == ownerId)
              && (excludeFromProfileId.isEmpty || itemlist.ownerId != excludeFromProfileId)
              && (itemlist.ownerType == ownerType)
          ) {
            itemlists[itemlist.id] = itemlist;
          }
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("${itemlists .length} itemlists found in total.");
    return itemlists;
  }


  @override
  Future<bool> delete(itemlistId) async {
    AppUtilities.logger.d("Removing public itemlist $itemlistId");
    try {

      await itemlistReference.doc(itemlistId).delete();
      AppUtilities.logger.d("Itemlist $itemlistId removed");
      return true;

    } catch (e) {
      AppUtilities.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> update(Itemlist itemlist) async {
    AppUtilities.logger.d("Updating Itemlist for user ${itemlist.id}");

    try {

      DocumentReference documentReference = itemlistReference.doc(itemlist.id);
      await documentReference.update({
        AppFirestoreConstants.name: itemlist.name,
        AppFirestoreConstants.description: itemlist.description,
      });

      AppUtilities.logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  @override
  Future<bool> updateItem(String itemlistId, AppMediaItem appMediaItem) async {
    AppUtilities.logger.d("Updating ItemlistItem for Public Itemlist $itemlistId");

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      await documentReference.update({
        AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([appMediaItem.toJSON()])
      });

      AppUtilities.logger.d("ItemlistItem ${appMediaItem.name} was updated to ${appMediaItem.state}");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("ItemlistItem ${appMediaItem.name} was not updated");
    return false;
  }

  @override
  Future<bool> addReleaseItem(String itemlistId, AppReleaseItem releaseItem) async {
    AppUtilities.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      await documentReference.update({
        AppFirestoreConstants.appReleaseItems: FieldValue.arrayUnion([releaseItem.toJSON()])
      });

      addedItem = true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    addedItem ? AppUtilities.logger.d("AppMediaItem was added to itemlist $itemlistId") :
    AppUtilities.logger.d("AppMediaItem was not added to itemlist $itemlistId");
    return addedItem;
  }

  @override
  Future<bool> deleteReleaseItem(String itemlistId, AppReleaseItem releaseItem) async {
      try {
        DocumentReference documentReference = itemlistReference.doc(itemlistId);
        DocumentSnapshot snapshot = await documentReference.get();

        Itemlist itemlist = Itemlist.fromJSON(snapshot.data());
        itemlist.appReleaseItems?.removeWhere((element) => element.id == releaseItem.id);

        await documentReference.update(itemlist.toJSON());


        AppUtilities.logger.i("releaseItem ${releaseItem.name} was removed");
        return true;
      } catch (e) {
        AppUtilities.logger.e(e.toString());
      }

      AppUtilities.logger.d("releaseItem ${releaseItem.name} was not removed");
      return false;
  }

  @override
  Future<bool> addPreset(String chamberId, ChamberPreset preset) async {
    AppUtilities.logger.d("Adding preset to chamber $chamberId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion([preset.toJSON()])
      });
      addedItem = true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    addedItem ? AppUtilities.logger.d("Preset was added to chamber $chamberId") :
    AppUtilities.logger.d("Preset was not added to chamber $chamberId");
    return addedItem;
  }


  @override
  Future<bool> deletePreset(ChamberPreset preset, String chamberId) async {
    AppUtilities.logger.d("Removing preset from chamber $chamberId");

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayRemove([preset.toJSON()])
      });


      AppUtilities.logger.d("Preset was removed from chamber $chamberId");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("Preset was not  removed from chamber $chamberId");
    return false;
  }

  @override
  Future<bool> updatePreset(String chamberId, ChamberPreset preset) async {
    AppUtilities.logger.d("Updating preset for profile $chamberId");

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion([preset.toJSON()])
      });

      AppUtilities.logger.d("Preset ${preset.name} was updated to ${preset.state}");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("Preset ${preset.name} was not updated");
    return false;
  }

}
