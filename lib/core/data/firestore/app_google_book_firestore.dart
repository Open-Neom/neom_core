import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_media_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/repository/app_media_item_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/app_media_source.dart';
import '../../utils/enums/media_item_type.dart';
import 'constants/app_firestore_collection_constants.dart';

class AppGoogleBookFirestore {

  final appGoogleBookReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.googleBooks);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<AppMediaItem> retrieve(String itemId) async {
    AppUtilities.logger.d("Getting item $itemId");
    AppMediaItem appMediaItem = AppMediaItem();
    try {
      await appGoogleBookReference.doc(itemId).get().then((doc) {
        if (doc.exists) {
          appMediaItem = AppMediaItem.fromJSON(jsonEncode(doc.data()));
          AppUtilities.logger.d("AppMediaItem ${appMediaItem.name} was retrieved with details");
        } else {
          AppUtilities.logger.d("AppMediaItem not found");
        }
      });
    } catch (e) {
      AppUtilities.logger.d(e);
      rethrow;
    }
    return appMediaItem;
  }


  @override
  Future<Map<String, AppMediaItem>> fetchAll({ int minItems = 0, int maxLength = 100,
    MediaItemType? type, List<MediaItemType>? excludeTypes}) async {
    AppUtilities.logger.t("Getting appMediaItems from list");

    Map<String, AppMediaItem> appMediaItems = {};

    try {
      QuerySnapshot querySnapshot = await appGoogleBookReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        AppUtilities.logger.t("QuerySnapshot is not empty");
        for (var documentSnapshot in querySnapshot.docs) {
          AppMediaItem appMediaItem = AppMediaItem.fromJSON(documentSnapshot.data());
          if(appMediaItem.name.toLowerCase() == 'no se vaya a confundir - en vivo') {
            AppUtilities.logger.i("Add ${appMediaItem.name} Debuggin next");
          }
          appMediaItem.id = documentSnapshot.id;
          if((type == null || appMediaItem.type == type)
              && (excludeTypes == null || !excludeTypes.contains(appMediaItem.type))) {
            appMediaItems[appMediaItem.id] = appMediaItem;
          }
          AppUtilities.logger.t("Add ${appMediaItem.name} to fetchAll list");
        }
      }
    } catch (e) {
      AppUtilities.logger.d(e);
    }
    return appMediaItems;
  }

  @override
  Future<Map<String, AppMediaItem>> retrieveFromList(List<String> appMediaItemIds) async {
    AppUtilities.logger.t("Getting ${appMediaItemIds.length} appMediaItems from firestore");

    Map<String, AppMediaItem> appMediaItems = {};

    try {
      QuerySnapshot querySnapshot = await appGoogleBookReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          if(appMediaItemIds.contains(documentSnapshot.id)){
            AppMediaItem appMediaItemm = AppMediaItem.fromJSON(documentSnapshot.data());
            AppUtilities.logger.d("AppMediaItem ${appMediaItemm.name} was retrieved with details");
            appMediaItems[documentSnapshot.id] = appMediaItemm;
          }
        }
      }

    } catch (e) {
      AppUtilities.logger.d(e);
    }
    return appMediaItems;
  }

  @override
  Future<bool> exists(String appMediaItemId) async {
    AppUtilities.logger.d("Getting appMediaItem $appMediaItemId");

    try {
      await appGoogleBookReference.doc(appMediaItemId).get().then((doc) {
        if (doc.exists) {
          AppUtilities.logger.d("AppMediaItem found");
          return true;
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e);
    }
    AppUtilities.logger.d("AppMediaItem not found");
    return false;
  }

  @override
  Future<void> insert(AppMediaItem appMediaItem) async {
    AppUtilities.logger.t("Adding appMediaItem to database collection");
    try {
      if((!appMediaItem.url.contains("gig-me-out") && !appMediaItem.url.contains("gigmeout")
          && !appMediaItem.url.contains("firebasestorage.googleapis.com")) && appMediaItem.mediaSource == AppMediaSource.internal) {
        if(appMediaItem.url.contains("spotify") || appMediaItem.url.contains("p.scdn.co")) {
          appMediaItem.mediaSource = AppMediaSource.spotify;
        } else if(appMediaItem.url.contains("youtube")) {
          appMediaItem.mediaSource = AppMediaSource.youtube;
        } else {
          appMediaItem.mediaSource = AppMediaSource.other;
        }
    }

      await appGoogleBookReference.doc(appMediaItem.id).set(appMediaItem.toJSON());
      AppUtilities.logger.d("AppMediaItem inserted into Firestore");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      AppUtilities.logger.i("AppMediaItem not inserted into Firestore");
    }
  }

  @override
  Future<bool> remove(AppMediaItem appMediaItem) async {
    AppUtilities.logger.d("Removing appMediaItem from database collection");
    try {
      await appGoogleBookReference.doc(appMediaItem.id).delete();
      return true;
    } catch (e) {
      AppUtilities.logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> removeItemFromList(String profileId, String itemlistId, AppMediaItem appMediaItem) async {
    AppUtilities.logger.d("Removing ItemlistItem for user $profileId");

    try {

      await profileReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == profileId) {
            DocumentSnapshot snapshot  = await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).get();

            Itemlist itemlist = Itemlist.fromJSON(snapshot.data());
            itemlist.appMediaItems?.removeWhere((element) => element.id == appMediaItem.id);
            await document.reference.collection(AppFirestoreCollectionConstants.itemlists)
                .doc(itemlistId).update(itemlist.toJSON());

          }
        }
      });

      AppUtilities.logger.i("ItemlistItem ${appMediaItem.name} was updated to ${appMediaItem.state}");
      return true;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d("ItemlistItem ${appMediaItem.name} was not updated");
    return false;
  }

  @override
  Future<void> existsOrInsert(AppMediaItem appMediaItem) async {
    AppUtilities.logger.t("existsOrInsert appMediaItem ${appMediaItem.id}");

    try {
      appGoogleBookReference.doc(appMediaItem.id).get().then((doc) {
        if (doc.exists) {
          AppUtilities.logger.t("AppMediaItem found");
        } else {
          AppUtilities.logger.d("AppMediaItem ${appMediaItem.id}. ${appMediaItem.name} not found. Inserting");
          insert(appMediaItem);
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e);
    }

  }

}
