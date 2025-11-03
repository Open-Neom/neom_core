import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/external_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/repository/external_item_repository.dart';
import '../../utils/enums/external_media_source.dart';
import '../../utils/enums/media_item_type.dart';
import 'constants/app_firestore_collection_constants.dart';

class ExternalItemFirestore implements ExternalItemRepository {

  final externalItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.externalItems);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<ExternalItem> retrieve(String itemId) async {
    AppConfig.logger.d("Getting item $itemId");
    ExternalItem externalItem = ExternalItem();
    try {
      await externalItemReference.doc(itemId).get().then((doc) {
        if (doc.exists) {
          externalItem = ExternalItem.fromJSON(jsonEncode(doc.data()));
          AppConfig.logger.d("ExternalItem ${externalItem.name} was retrieved with details");
        } else {
          AppConfig.logger.d("ExternalItem not found");
        }
      });
    } catch (e) {
      AppConfig.logger.d(e);
      rethrow;
    }
    return externalItem;
  }


  @override
  Future<Map<String, ExternalItem>> fetchAll({ int minItems = 0, int maxLength = 100,
    MediaItemType? type, List<MediaItemType>? excludeTypes}) async {
    AppConfig.logger.t("Getting externalItems from list");

    Map<String, ExternalItem> externalItems = {};

    try {
      QuerySnapshot querySnapshot = await externalItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppConfig.logger.t("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          ExternalItem externalItem = ExternalItem.fromJSON(documentSnapshot.data());
          externalItem.id = documentSnapshot.id;

          if((type == null || externalItem.type == type)
              && (excludeTypes == null || !excludeTypes.contains(externalItem.type))) {
            externalItems[externalItem.id] = externalItem;
          }
          AppConfig.logger.t("Add ${externalItem.name} to fetchAll list");
        }
      }
    } catch (e) {
      AppConfig.logger.d(e);
    }

    AppConfig.logger.d("${externalItems.length} externalItems found");
    return externalItems;
  }

  @override
  Future<Map<String, ExternalItem>> retrieveFromList(List<String> externalItemIds) async {
    AppConfig.logger.t("Getting ${externalItemIds.length} externalItems from firestore");

    Map<String, ExternalItem> externalItems = {};

    try {
      QuerySnapshot querySnapshot = await externalItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          if(externalItemIds.contains(documentSnapshot.id)){
            ExternalItem externalItem = ExternalItem.fromJSON(documentSnapshot.data());
            AppConfig.logger.d("ExternalItem ${externalItem.name} was retrieved with details");
            externalItems[documentSnapshot.id] = externalItem;
          }
        }
      }

    } catch (e) {
      AppConfig.logger.d(e);
    }
    return externalItems;
  }

  @override
  Future<bool> exists(String externalItemId) async {
    AppConfig.logger.d("Getting externalItem $externalItemId");

    try {
      await externalItemReference.doc(externalItemId).get().then((doc) {
        if (doc.exists) {
          AppConfig.logger.d("ExternalItem found");
          return true;
        }
      });
    } catch (e) {
      AppConfig.logger.e(e);
    }
    AppConfig.logger.d("ExternalItem not found");
    return false;
  }

  @override
  Future<void> insert(ExternalItem externalItem) async {
    AppConfig.logger.t("Adding externalItem to database collection");
    try {
      if(externalItem.url.contains("spotify") || externalItem.url.contains("p.scdn.co")) {
        externalItem.source = ExternalSource.spotify;
      } else if(externalItem.url.contains("youtube")) {
        externalItem.source = ExternalSource.youtube;
      } else {
        externalItem.source = ExternalSource.other;
      }

      await externalItemReference.doc(externalItem.id).set(externalItem.toJSON());
      AppConfig.logger.d("ExternalItem inserted into Firestore");
    } catch (e) {
      AppConfig.logger.e(e.toString());
      AppConfig.logger.i("ExternalItem not inserted into Firestore");
    }
  }

  @override
  Future<bool> remove(ExternalItem externalItem) async {
    AppConfig.logger.d("Removing externalItem from database collection");
    try {
      await externalItemReference.doc(externalItem.id).delete();
      return true;
    } catch (e) {
      AppConfig.logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> removeItemFromList(String profileId, String itemlistId, ExternalItem externalItem) async {
    AppConfig.logger.d("Removing ItemlistItem for user $profileId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            DocumentSnapshot snapshot  = await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).get();

            Itemlist itemlist = Itemlist.fromJSON(snapshot.data());
            itemlist.externalItems?.removeWhere((element) => element.id == externalItem.id);
            await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).update(itemlist.toJSON());

          }
        }
      });

      AppConfig.logger.i("ItemlistItem ${externalItem.name} was updated to ${externalItem.state}");
      return true;
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    AppConfig.logger.d("ItemlistItem ${externalItem.name} was not updated");
    return false;
  }

  @override
  Future<void> existsOrInsert(ExternalItem externalItem) async {
    AppConfig.logger.t("existsOrInsert externalItem ${externalItem.id}");

    try {
      externalItemReference.doc(externalItem.id).get().then((doc) {
        if (doc.exists) {
          AppConfig.logger.t("ExternalItem found");
        } else {
          AppConfig.logger.d("ExternalItem ${externalItem.id}. ${externalItem.name} not found. Inserting");
          insert(externalItem);
        }
      });
    } catch (e) {
      AppConfig.logger.e(e);
    }

  }

}
