import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/external_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/repository/external_item_repository.dart';
import '../../utils/enums/media_item_type.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';
import 'profile_document_locator.dart';

class ExternalItemFirestore implements ExternalItemRepository {

  CollectionReference<Map<String, dynamic>> get externalItemReference =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.externalItems);
  Query<Map<String, dynamic>> get profileReference =>
      FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);
  final ProfileDocumentLocator _profileLocator = ProfileDocumentLocator();

  @override
  Future<ExternalItem> retrieve(String itemId) async {
    final cleanId = itemId.trim();
    ExternalItem externalItem = ExternalItem();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return externalItem;
    AppConfig.logger.d("Getting item $cleanId");
    try {
      final doc = await externalItemReference.doc(cleanId).get();
      if (doc.exists && doc.data() != null) {
        externalItem = ExternalItem.fromJSON(jsonEncode(doc.data()));
        externalItem.id = doc.id;
        AppConfig.logger.d("ExternalItem ${externalItem.name} was retrieved with details");
      } else {
        AppConfig.logger.d("ExternalItem not found");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.retrieve');
      rethrow;
    }
    return externalItem;
  }


  @override
  Future<Map<String, ExternalItem>> fetchAll({ int minItems = 0, int maxLength = 100,
    MediaItemType? type, List<MediaItemType>? excludeTypes}) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(maxLength, defaultLimit: 100, maxLimit: 500);
    AppConfig.logger.t("Getting externalItems from list (limit: $safeLimit)");

    Map<String, ExternalItem> externalItems = {};

    try {
      QuerySnapshot querySnapshot = await externalItemReference.limit(safeLimit).get();

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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.fetchAll');
    }

    AppConfig.logger.d("${externalItems.length} externalItems found");
    return externalItems;
  }

  @override
  Future<Map<String, ExternalItem>> retrieveFromList(List<String> externalItemIds) async {
    AppConfig.logger.t("Getting ${externalItemIds.length} externalItems from firestore");

    Map<String, ExternalItem> externalItems = {};
    final chunks = CoreFirestoreGuard.chunkValidIds(externalItemIds);
    if (chunks.isEmpty) return externalItems;

    try {
      for (final chunk in chunks) {
        final querySnapshot = await externalItemReference
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          ExternalItem externalItem = ExternalItem.fromJSON(documentSnapshot.data());
          externalItem.id = documentSnapshot.id;
          externalItems[documentSnapshot.id] = externalItem;
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.retrieveFromList');
    }
    return externalItems;
  }

  @override
  Future<bool> exists(String externalItemId) async {
    final cleanId = externalItemId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Getting externalItem $cleanId");

    try {
      final doc = await externalItemReference.doc(cleanId).get();
      if (doc.exists) {
        AppConfig.logger.d("ExternalItem found");
        return true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.exists');
    }
    AppConfig.logger.d("ExternalItem not found");
    return false;
  }

  @override
  Future<void> insert(ExternalItem externalItem) async {
    final cleanId = externalItem.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    externalItem.id = cleanId;
    AppConfig.logger.t("Adding externalItem to database collection");
    try {
      externalItem.source = CoreFirestoreGuard.classifyExternalUrlSource(externalItem.url);

      await externalItemReference.doc(cleanId).set(externalItem.toJSON());
      AppConfig.logger.d("ExternalItem inserted into Firestore");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.insert');
      AppConfig.logger.i("ExternalItem not inserted into Firestore");
    }
  }

  @override
  Future<bool> remove(ExternalItem externalItem) async {
    final cleanId = externalItem.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Removing externalItem from database collection");
    try {
      await externalItemReference.doc(cleanId).delete();
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.remove');
      return false;
    }
  }

  @override
  Future<bool> removeItemFromList(String profileId, String itemlistId, ExternalItem externalItem) async {
    final cleanProfileId = profileId.trim();
    final cleanItemlistId = itemlistId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanItemlistId)) {
      return false;
    }
    AppConfig.logger.d("Removing ItemlistItem for user $cleanProfileId");

    try {
      final profileDocRef = await _profileLocator.locate(cleanProfileId);
      if (profileDocRef == null) return false;

      final itemlistRef = profileDocRef
          .collection(AppFirestoreCollectionConstants.itemlists)
          .doc(cleanItemlistId);
      final snapshot = await itemlistRef.get();
      if (!snapshot.exists || snapshot.data() == null) return false;

      final itemlist = Itemlist.fromJSON(snapshot.data()!);
      itemlist.externalItems?.removeWhere((element) => element.id == externalItem.id);
      await itemlistRef.update(itemlist.toJSON());

      AppConfig.logger.i("ItemlistItem ${externalItem.name} was updated to ${externalItem.state}");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.removeItemFromList');
    }

    AppConfig.logger.d("ItemlistItem ${externalItem.name} was not updated");
    return false;
  }

  @override
  Future<void> existsOrInsert(ExternalItem externalItem) async {
    final cleanId = externalItem.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return;
    AppConfig.logger.t("existsOrInsert externalItem $cleanId");

    try {
      final doc = await externalItemReference.doc(cleanId).get();
      if (doc.exists) {
        AppConfig.logger.t("ExternalItem found");
      } else {
        AppConfig.logger.d("ExternalItem $cleanId. ${externalItem.name} not found. Inserting");
        await insert(externalItem);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ExternalItemFirestore.existsOrInsert');
    }
  }

}
