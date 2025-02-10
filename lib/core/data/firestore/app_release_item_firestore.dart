import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_release_item.dart';
import '../../domain/repository/app_release_item_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/release_status.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class AppReleaseItemFirestore implements AppReleaseItemRepository {
  
  final appReleaseItemReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appReleaseItems);
  final userReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  final profileReference = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);

  @override
  Future<String> insert(AppReleaseItem appReleaseItem) async {
    AppUtilities.logger.d("Adding appReleaseItem to database collection");
    String releaseItemId = appReleaseItem.id;
    try {
      if(releaseItemId.isNotEmpty) {
        await appReleaseItemReference.doc(releaseItemId).set(appReleaseItem.toJSON());
      } else {
        DocumentReference documentReference = await appReleaseItemReference.add(appReleaseItem.toJSON());
        releaseItemId = documentReference.id;
      }

      AppUtilities.logger.d("AppReleaseItem inserted into Firestore with id: $releaseItemId");
    } catch (e) {
      AppUtilities.logger.e(e.toString());
      AppUtilities.logger.i("AppReleaseItem not inserted into Firestore");
    }

    return releaseItemId;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveAll() async {
    AppUtilities.logger.t("Get all AppReleaseItem");

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
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.t("${releaseItems.length} releaseItems found");
    return releaseItems;
  }

  @override
  Future<AppReleaseItem> retrieve(String releaseItemId) async {
    AppUtilities.logger.d("Getting item $releaseItemId");
    AppReleaseItem appReleaseItem = AppReleaseItem();
    try {
      await appReleaseItemReference.doc(releaseItemId).get().then((doc) {
        if (doc.exists) {
          appReleaseItem = AppReleaseItem.fromJSON(doc.data());
          appReleaseItem.id = doc.id;
          AppUtilities.logger.d("AppReleaseItem ${appReleaseItem.name} was retrieved with details");
        } else {
          AppUtilities.logger.d("AppReleaseItem not found");
        }
      });
    } catch (e) {
      AppUtilities.logger.d(e);
      rethrow;
    }
    return appReleaseItem;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveFromList(List<String> releaseItemIds) async {
    AppUtilities.logger.t("Getting ${releaseItemIds}appReleaseItems from list");

    Map<String, AppReleaseItem> appItems = {};

    try {
      QuerySnapshot querySnapshot = await appReleaseItemReference.get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var documentSnapshot in querySnapshot.docs) {
          if(releaseItemIds.contains(documentSnapshot.id)){
            AppReleaseItem releaseItem = AppReleaseItem.fromJSON(documentSnapshot.data());
            AppUtilities.logger.d("AppReleaseItem ${releaseItem.name} was retrieved with details");
            appItems[documentSnapshot.id] = releaseItem;
          }
        }
      }

    } catch (e) {
      AppUtilities.logger.d(e);
    }
    return appItems;
  }

  @override
  Future<bool> remove(AppReleaseItem appReleaseItem) async {
    AppUtilities.logger.d("Removing appReleaseItem ${appReleaseItem.name} with id ${appReleaseItem.id} from database collection");
    try {
      await appReleaseItemReference.doc(appReleaseItem.id).delete();
      return true;
    } catch (e) {
      AppUtilities.logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addBoughtUser({required String releaseItemId, required String userId}) async {
    AppUtilities.logger.t("$releaseItemId would add user $userId");

    try {
      await appReleaseItemReference.get()
          .then((querySnapshot) async {
        for (var document in querySnapshot.docs) {
          if(document.id == releaseItemId) {
            await document.reference.update({AppFirestoreConstants.boughtUsers: FieldValue.arrayUnion([userId])});
            AppUtilities.logger.d("$releaseItemId has added user $userId");
            return true;
          }
        }
      });
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
    return false;
  }
  @override
  Future<bool> exists(String releaseItemId) async {
    AppUtilities.logger.d("Getting releaseItem $releaseItemId");

    try {
      if(releaseItemId.isEmpty) false;
      await appReleaseItemReference.doc(releaseItemId).get().then((doc) {
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

}
