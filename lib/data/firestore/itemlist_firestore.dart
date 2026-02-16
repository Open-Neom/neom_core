import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_media_item.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/model/external_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/model/neom/neom_chamber_preset.dart';
import '../../domain/repository/itemlist_repository.dart';

import '../../utils/constants/core_constants.dart';
import '../../utils/enums/itemlist_type.dart';
import '../../utils/enums/owner_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class ItemlistFirestore implements ItemlistRepository {
  
  final itemlistReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.itemlists);

  @override
  Future<String> insert(Itemlist itemlist) async {
    AppConfig.logger.d("Creating itemlist for Profile ${itemlist.ownerId}");
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

      AppConfig.logger.d("Public Itemlist $itemlistId inserted");
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return itemlistId;
  }

  @override
  Future<bool> addMediaItem(String itemlistId, AppMediaItem appMediaItem) async {
    AppConfig.logger.d("Adding item to itemlist $itemlistId");
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
      AppConfig.logger.e(e.toString());
    }

    addedItem ? AppConfig.logger.d("AppMediaItem was added to itemlist $itemlistId") :
    AppConfig.logger.d("AppMediaItem was not added to itemlist $itemlistId");
    return addedItem;
  }


  @override
  Future<bool> deleteMediaItem({required String itemlistId, required String itemId}) async {
    AppConfig.logger.d("Removing item from itemlist $itemlistId");

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);

      if (documentReference.id.isNotEmpty) {
        AppConfig.logger.t("Snapshot is not empty");
        DocumentSnapshot snapshot = await documentReference.get();
        final data = snapshot.data();
        if (data == null) return false;
        Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);

        itemlist.appMediaItems?.removeWhere((item) => item.id == itemId);
        await documentReference.update({
          AppFirestoreConstants.appMediaItems: itemlist.appMediaItems?.map((item) => item.toJSON()).toList(),
        });

      }

      AppConfig.logger.d("Item was removed from itemlist $itemlistId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Item was not  removed from itemlist $itemlistId");
    return false;
  }

  @override
  Future<Itemlist> retrieve(String itemlistId) async {
    AppConfig.logger.t("Retrieving Itemlist by ID: $itemlistId");
    Itemlist itemlist = Itemlist();

    try {
      DocumentSnapshot documentSnapshot = await itemlistReference.doc(itemlistId).get();
      if (documentSnapshot.exists) {
        AppConfig.logger.t("Snapshot is not empty");
        final data = documentSnapshot.data();
        if (data == null) return itemlist;
        itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
        itemlist.id = documentSnapshot.id;
        AppConfig.logger.t(itemlist.toString());
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }


    return itemlist;
  }

  /// OPTIMIZED: Reduced default limit from 1000 to 50, added server-side filtering
  @override
  Future<Map<String, Itemlist>> fetchAll({bool onlyPublic = false, int maxLength = 50,
    String ownerId = '', String excludeFromProfileId = '', OwnerType ownerType = OwnerType.profile,
    ItemlistType? itemlistType}) async {
    AppConfig.logger.t("Retrieving Itemlists from firestore (limit: $maxLength)");
    Map<String, Itemlist> itemlists = {};

    try {
      // OPTIMIZATION: Apply server-side filters instead of reading all then filtering client-side
      Query query = itemlistReference;

      // Server-side filtering where possible
      if (ownerId.isNotEmpty) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      if (onlyPublic) {
        query = query.where('public', isEqualTo: true);
      }
      query = query.where('ownerType', isEqualTo: ownerType.name);
      if (itemlistType != null) {
        query = query.where('type', isEqualTo: itemlistType.name);
      }

      QuerySnapshot querySnapshot = await query.limit(maxLength).get();

      for (var document in querySnapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
        itemlist.id = document.id;
        // Client-side filter only for excludeFromProfileId (can't do != in Firestore easily)
        if (excludeFromProfileId.isEmpty || itemlist.ownerId != excludeFromProfileId) {
          itemlists[itemlist.id] = itemlist;
        }
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${itemlists.length} itemlists found in total.");
    return itemlists;
  }

  @override
  Future<Map<String, Itemlist>> getByOwnerId(String ownerId, {bool onlyPublic = false, bool excludeMyFavorites = true,
    int maxLength = 100, OwnerType ownerType = OwnerType.profile, ItemlistType? itemlistType}) async {
    AppConfig.logger.d("Retrieving Itemlists from firestore for owner $ownerId");
    Map<String, Itemlist> itemlists = {};

    try {
      if (ownerId.isNotEmpty) {
        Query query = itemlistReference.limit(maxLength);
        query = query.where('ownerId', isEqualTo: ownerId);
        query = query.where('ownerType', isEqualTo: ownerType.name);
        if(itemlistType != null) query = query.where('type', isEqualTo: itemlistType.name);

        await query.get().then((querySnapshot) {
          for (var document in querySnapshot.docs) {
            final data = document.data();
            if (data == null) continue;
            Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
            itemlist.id = document.id;
            if((!onlyPublic || itemlist.public)
                && (!excludeMyFavorites || itemlist.id != CoreConstants.myFavorites)
            ) {
              itemlists[itemlist.id] = itemlist;
            }
          }
        });
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("${itemlists.length} itemlists found in total.");
    return itemlists;
  }

  @override
  Future<bool> delete(itemlistId) async {
    AppConfig.logger.d("Removing public itemlist $itemlistId");
    try {

      await itemlistReference.doc(itemlistId).delete();
      AppConfig.logger.d("Itemlist $itemlistId removed");
      return true;

    } catch (e) {
      AppConfig.logger.e(e.toString());
      return false;
    }
  }

  @override
  Future<bool> update(Itemlist itemlist) async {
    AppConfig.logger.d("Updating Itemlist for user ${itemlist.id}");

    try {

      DocumentReference documentReference = itemlistReference.doc(itemlist.id);
      await documentReference.update({
        AppFirestoreConstants.name: itemlist.name,
        AppFirestoreConstants.description: itemlist.description,
      });

      AppConfig.logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  Future<bool> updateType(Itemlist itemlist) async {
    AppConfig.logger.d("Updating Itemlist for user ${itemlist.id}");

    try {

      DocumentReference documentReference = itemlistReference.doc(itemlist.id);
      await documentReference.update({
        AppFirestoreConstants.type: itemlist.type.name,
      });

      AppConfig.logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  @override
  Future<bool> addReleaseItem(String itemlistId, AppReleaseItem releaseItem) async {
    AppConfig.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      await documentReference.update({
        AppFirestoreConstants.appReleaseItems: FieldValue.arrayUnion([releaseItem.toJSON()])
      });

      addedItem = true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    addedItem ? AppConfig.logger.d("AppReleaseItem was added to itemlist $itemlistId") :
    AppConfig.logger.d("AppReleaseItem was not added to itemlist $itemlistId");
    return addedItem;
  }

  @override
  Future<bool> deleteReleaseItem({required String itemlistId, required String itemId}) async {
      try {
        if(itemId.isEmpty || itemlistId.isEmpty) return false;
        DocumentReference documentReference = itemlistReference.doc(itemlistId);
        DocumentSnapshot snapshot = await documentReference.get();

        final data = snapshot.data();
        if (data == null) return false;
        Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
        itemlist.appReleaseItems?.removeWhere((element) => element.id == itemId);

        await documentReference.update(itemlist.toJSON());


        AppConfig.logger.i("releaseItem $itemId was removed");
        return true;
      } catch (e) {
        AppConfig.logger.e(e.toString());
      }

      AppConfig.logger.d("releaseItem $itemId was not removed");
      return false;
  }

  @override
  Future<bool> addPreset(String chamberId, NeomChamberPreset preset) async {
    AppConfig.logger.d("Adding preset to chamber $chamberId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion([preset.toJSON()])
      });
      addedItem = true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    addedItem ? AppConfig.logger.d("Preset was added to chamber $chamberId") :
    AppConfig.logger.d("Preset was not added to chamber $chamberId");
    return addedItem;
  }

  @override
  Future<bool> deletePreset(NeomChamberPreset preset, String chamberId) async {
    AppConfig.logger.d("Removing preset from chamber $chamberId");

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayRemove([preset.toJSON()])
      });


      AppConfig.logger.d("Preset was removed from chamber $chamberId");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("Preset was not  removed from chamber $chamberId");
    return false;
  }

  @override
  Future<bool> addExternalItem(String itemlistId, ExternalItem externalItem) async {
    AppConfig.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      await documentReference.update({
        AppFirestoreConstants.externalItems: FieldValue.arrayUnion([externalItem.toJSON()])
      });

      addedItem = true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    addedItem ? AppConfig.logger.d("ExternalItem was added to itemlist $itemlistId") :
    AppConfig.logger.d("ExternalItem was not added to itemlist $itemlistId");
    return addedItem;
  }

  @override
  Future<bool> deleteExternalItem({required String itemlistId, required String itemId}) async {
    try {
      if(itemId.isEmpty || itemlistId.isEmpty) return false;
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      DocumentSnapshot snapshot = await documentReference.get();

      final data = snapshot.data();
      if (data == null) return false;
      Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
      itemlist.externalItems?.removeWhere((element) => element.id == itemId);

      await documentReference.update(itemlist.toJSON());


      AppConfig.logger.i("externalItem $itemId was removed");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("externalItem $itemId was not removed");
    return false;
  }

}
