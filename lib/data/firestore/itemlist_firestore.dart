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
import '../../utils/enums/external_media_source.dart';
import '../../utils/enums/itemlist_type.dart';
import '../../utils/enums/owner_type.dart';
import '../../utils/neom_error_logger.dart';
import '../api/app_platform_api.dart';
import 'app_media_item_firestore.dart';
import 'app_release_item_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'public_catalog_read_policy.dart';

class ItemlistFirestore implements ItemlistRepository {
  final FirebaseFirestore? _injectedFirestore;
  ItemlistFirestore({FirebaseFirestore? firestore})
    : _injectedFirestore = firestore;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get itemlistReference =>
      PublicCatalogReadPolicy.collection(
        _firestore,
        AppFirestoreCollectionConstants.itemlists,
      );
  Query<Map<String, dynamic>> get _itemlistQuery =>
      PublicCatalogReadPolicy.query(itemlistReference);

  Future<Itemlist> _readItemlist(String id, Map<String, dynamic> data) async {
    final itemlist = Itemlist.fromJSON(data)..id = id;
    if (!PublicCatalogReadPolicy.enabled) return itemlist;
    List<String> ids(String field) => (data[field] is List)
        ? (data[field] as List)
              .whereType<String>()
              .where((id) => id.isNotEmpty && !id.contains('/'))
              .take(100)
              .toList()
        : <String>[];
    // Public lists carry only item IDs. Embedded legacy objects are never used.
    final releases = await AppReleaseItemFirestore(
      firestore: _firestore,
    ).retrieveFromList(ids('appReleaseItemIds'));
    final media = await AppMediaItemFirestore(
      firestore: _firestore,
    ).retrieveFromList(ids('appMediaItemIds'));
    itemlist.appReleaseItems = releases.values.toList();
    itemlist.appMediaItems = media.values.toList();
    if (itemlist.public && itemlist.type == ItemlistType.giglist) {
      // Public Giglists expose reference-only external repertoire metadata
      // (never stream URLs) so musicians and visitors can browse repertoires.
      itemlist.externalItems = (itemlist.externalItems ?? const <ExternalItem>[])
          .map(
            (e) => ExternalItem(
              id: e.id,
              name: e.name,
              ownerName: e.ownerName,
              ownerId: e.ownerId,
              album: e.album,
              duration: e.duration,
              imgUrl: e.imgUrl,
              galleryUrls: e.galleryUrls,
              url: '',
              permaUrl: e.permaUrl,
              source: e.source,
              type: e.type,
              state: e.state,
              publishedYear: e.publishedYear,
            ),
          )
          .toList();
    } else {
      itemlist.externalItems = [];
    }
    return itemlist;
  }

  @override
  Future<String> insert(Itemlist itemlist) async {
    if (AppPlatformApi.isEnabled) {
      try {
        if (itemlist.ownerSlug.isEmpty && itemlist.ownerName.isNotEmpty) {
          itemlist.ownerSlug = Itemlist.generateOwnerSlug(itemlist.ownerName);
        }
        if (itemlist.slug.isEmpty && itemlist.name.isNotEmpty) {
          itemlist.slug = Itemlist.generateSlug(itemlist.name);
        }
        final value = await AppPlatformApi.client('itemlists').mutate(
          'insert',
          {'itemlist': itemlist.toJSON()},
          durable: false,
        );
        return (value ?? '').toString();
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.insert.platform',
        );
        return '';
      }
    }
    if (PublicCatalogReadPolicy.enabled) return '';
    AppConfig.logger.d("Creating itemlist for Profile ${itemlist.ownerId}");
    String itemlistId = "";

    try {
      // Address is `/{kind}/{ownerSlug}/{slug}`, unique because an artist does
      // not release two albums with the same name. Derived here so every write
      // path gets it, not just the release upload flow.
      if (itemlist.ownerSlug.isEmpty && itemlist.ownerName.isNotEmpty) {
        itemlist.ownerSlug = Itemlist.generateOwnerSlug(itemlist.ownerName);
      }
      if (itemlist.slug.isEmpty && itemlist.name.isNotEmpty) {
        itemlist.slug = Itemlist.generateSlug(itemlist.name);
      }

      // Re-publishing the same album is an update, not a rival address.
      // Scope by type so a Giglist and a Playlist with the same title never collide.
      if (itemlist.id.isEmpty &&
          itemlist.ownerSlug.isNotEmpty &&
          itemlist.slug.isNotEmpty) {
        final existing = await getByOwnerAndSlug(
          itemlist.ownerSlug,
          itemlist.slug,
          type: itemlist.type,
        );
        if (existing != null &&
            existing.id.isNotEmpty &&
            existing.type == itemlist.type) {
          AppConfig.logger.w(
            "Itemlist '${itemlist.name}' (${itemlist.type.name}) by ${itemlist.ownerName} "
            "already exists (${existing.id}); updating it",
          );
          itemlist.id = existing.id;
        }
      }

      // Rapid duplicate insert protection for itemlists within 120s
      if (itemlist.id.isEmpty &&
          (itemlist.ownerSlug.isNotEmpty || itemlist.ownerId.isNotEmpty)) {
        try {
          final recentThreshold =
              DateTime.now().millisecondsSinceEpoch - 120000;
          Query<Map<String, dynamic>> query = itemlistReference;
          if (itemlist.ownerSlug.isNotEmpty) {
            query = query.where('ownerSlug', isEqualTo: itemlist.ownerSlug);
          } else if (itemlist.ownerId.isNotEmpty) {
            query = query.where(
              AppFirestoreConstants.ownerId,
              isEqualTo: itemlist.ownerId,
            );
          }

          final recentDocs = await query
              .where('createdTime', isGreaterThan: recentThreshold)
              .get();

          for (var doc in recentDocs.docs) {
            final data = doc.data();
            final existingType = (data['type'] as String? ?? '').trim();
            if (existingType.isNotEmpty && existingType != itemlist.type.name) {
              continue;
            }
            final existingSlug = data['slug'] as String? ?? '';
            final existingName = data['name'] as String? ?? '';
            if ((itemlist.slug.isNotEmpty && existingSlug == itemlist.slug) ||
                (itemlist.name.trim().isNotEmpty &&
                    existingName.trim().toLowerCase() ==
                        itemlist.name.trim().toLowerCase())) {
              AppConfig.logger.w(
                "Rapid duplicate itemlist detected for owner "
                "${itemlist.ownerSlug.isNotEmpty ? itemlist.ownerSlug : itemlist.ownerId} "
                "(existing ID: ${doc.id}, name: '$existingName'). Reusing existing doc.",
              );
              itemlist.id = doc.id;
              break;
            }
          }
        } catch (e) {
          AppConfig.logger.w(
            "Rapid duplicate check in ItemlistFirestore failed: $e",
          );
        }
      }


      if (itemlist.id.isEmpty) {
        DocumentReference? documentReference = await itemlistReference.add(
          itemlist.toJSON(),
        );
        itemlistId = documentReference.id;
      } else {
        await itemlistReference.doc(itemlist.id).set(itemlist.toJSON());
        itemlistId = itemlist.id;
      }

      AppConfig.logger.d("Public Itemlist $itemlistId inserted");
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.insert',
      );
    }

    return itemlistId;
  }

  @override
  Future<bool> addMediaItem(
    String itemlistId,
    AppMediaItem appMediaItem,
  ) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'addAppMediaItem',
          {
            'itemlistId': itemlistId,
            'appMediaItem': appMediaItem.toJSON(),
          },
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.addMediaItem.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      if (documentReference.id.isNotEmpty) {
        await documentReference.update({
          AppFirestoreConstants.appMediaItems: FieldValue.arrayUnion([
            appMediaItem.toJSON(),
          ]),
        });

        addedItem = true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.addMediaItem',
      );
    }

    addedItem
        ? AppConfig.logger.d("AppMediaItem was added to itemlist $itemlistId")
        : AppConfig.logger.d(
            "AppMediaItem was not added to itemlist $itemlistId",
          );
    return addedItem;
  }

  @override
  Future<bool> deleteMediaItem({
    required String itemlistId,
    required String itemId,
  }) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'deleteAppMediaItem',
          {'itemlistId': itemlistId, 'itemId': itemId},
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.deleteMediaItem.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
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
          AppFirestoreConstants.appMediaItems: itemlist.appMediaItems
              ?.map((item) => item.toJSON())
              .toList(),
        });
      }

      AppConfig.logger.d("Item was removed from itemlist $itemlistId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.deleteMediaItem',
      );
    }

    AppConfig.logger.d("Item was not  removed from itemlist $itemlistId");
    return false;
  }

  @override
  Future<Itemlist> retrieve(String itemlistId) async {
    if (AppPlatformApi.isEnabled) {
      if (itemlistId.isEmpty) return Itemlist();
      try {
        return await AppPlatformApi.client('itemlists').read<Itemlist>(
          'retrieve',
          {'itemlistId': itemlistId},
          private: false,
          decode: (res) {
            final items = res['items'] as List? ?? const [];
            if (items.isEmpty) return Itemlist();
            final map = Map<String, dynamic>.from(items.first as Map);
            return Itemlist.fromJSON(map)..id = (map['id'] ?? itemlistId).toString();
          },
          fallback: () async => Itemlist(),
          referenceIds: (l) => l.id.isNotEmpty ? [l.id] : const [],
        );
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.retrieve.platform',
        );
        return Itemlist();
      }
    }
    AppConfig.logger.t("Retrieving Itemlist by ID: $itemlistId");
    Itemlist itemlist = Itemlist();

    try {
      DocumentSnapshot documentSnapshot = await itemlistReference
          .doc(itemlistId)
          .get();
      if (documentSnapshot.exists &&
          PublicCatalogReadPolicy.accepts(
            documentSnapshot.data() as Map<String, dynamic>?,
          )) {
        AppConfig.logger.t("Snapshot is not empty");
        final data = documentSnapshot.data();
        if (data == null) return itemlist;
        itemlist = await _readItemlist(
          documentSnapshot.id,
          data as Map<String, dynamic>,
        );
        AppConfig.logger.t(itemlist.toString());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.retrieve',
      );
    }

    return itemlist;
  }

  /// OPTIMIZED: Reduced default limit from 1000 to 50, added server-side filtering
  @override
  Future<Map<String, Itemlist>> fetchAll({
    bool onlyPublic = false,
    int maxLength = 50,
    String ownerId = '',
    String excludeFromProfileId = '',
    OwnerType ownerType = OwnerType.profile,
    ItemlistType? itemlistType,
    bool includeAllOwnerTypes = false,
  }) async {
    if (AppPlatformApi.isEnabled) {
      try {
        return await AppPlatformApi.client('itemlists').read<Map<String, Itemlist>>(
          'fetchItemlists',
          {
            if (ownerId.isNotEmpty) 'ownerId': ownerId,
            if (itemlistType != null) 'itemlistType': itemlistType.name,
          },
          private: false,
          decode: (res) {
            final map = <String, Itemlist>{};
            final raw = res['items'] as List? ?? const [];
            for (final entry in raw) {
              if (entry is! Map) continue;
              final json = Map<String, dynamic>.from(entry);
              final list = Itemlist.fromJSON(json)..id = (json['id'] ?? '').toString();
              if (list.id.isEmpty) continue;
              if (onlyPublic && !list.public) continue;
              if (excludeFromProfileId.isNotEmpty && list.ownerId == excludeFromProfileId) continue;
              map[list.id] = list;
              if (map.length >= maxLength) break;
            }
            return map;
          },
          fallback: () async => <String, Itemlist>{},
          referenceIds: (m) => m.keys,
        );
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.fetchAll.platform',
        );
        return {};
      }
    }
    AppConfig.logger.t(
      "Retrieving Itemlists from firestore (limit: $maxLength)",
    );
    Map<String, Itemlist> itemlists = {};

    try {
      // OPTIMIZATION: Apply server-side filters instead of reading all then filtering client-side
      Query query = _itemlistQuery;

      // Server-side filtering where possible
      if (ownerId.isNotEmpty) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }
      if (onlyPublic) {
        query = query.where('public', isEqualTo: true);
      }
      if (!includeAllOwnerTypes) {
        query = query.where('ownerType', isEqualTo: ownerType.name);
      }
      if (itemlistType != null) {
        query = query.where('type', isEqualTo: itemlistType.name);
      }

      QuerySnapshot querySnapshot = await query.limit(maxLength).get();

      for (var document in querySnapshot.docs) {
        final data = document.data();
        if (data == null) continue;
        Itemlist itemlist = await _readItemlist(
          document.id,
          data as Map<String, dynamic>,
        );
        // Client-side filter only for excludeFromProfileId (can't do != in Firestore easily)
        if (excludeFromProfileId.isEmpty ||
            itemlist.ownerId != excludeFromProfileId) {
          itemlists[itemlist.id] = itemlist;
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.fetchAll',
      );
    }

    AppConfig.logger.d("${itemlists.length} itemlists found in total.");
    return itemlists;
  }

  @override
  Future<Map<String, Itemlist>> getByOwnerId(
    String ownerId, {
    bool onlyPublic = false,
    bool excludeMyFavorites = true,
    int maxLength = 100,
    OwnerType ownerType = OwnerType.profile,
    ItemlistType? itemlistType,
  }) async {
    if (AppPlatformApi.isEnabled) {
      if (ownerId.isEmpty) return {};
      try {
        return await AppPlatformApi.client('itemlists').read<Map<String, Itemlist>>(
          'getByOwnerId',
          {
            'ownerId': ownerId,
            if (itemlistType != null) 'itemlistType': itemlistType.name,
          },
          private: false,
          decode: (res) {
            final map = <String, Itemlist>{};
            final raw = res['items'] as List? ?? const [];
            for (final entry in raw) {
              if (entry is! Map) continue;
              final json = Map<String, dynamic>.from(entry);
              final list = Itemlist.fromJSON(json)..id = (json['id'] ?? '').toString();
              if (list.id.isEmpty) continue;
              if (onlyPublic && !list.public) continue;
              if (excludeMyFavorites && list.id == CoreConstants.myFavorites) continue;
              map[list.id] = list;
              if (map.length >= maxLength) break;
            }
            return map;
          },
          fallback: () async => <String, Itemlist>{},
          referenceIds: (m) => m.keys,
        );
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.getByOwnerId.platform',
        );
        return {};
      }
    }
    AppConfig.logger.d(
      "Retrieving Itemlists from firestore for owner $ownerId",
    );
    Map<String, Itemlist> itemlists = {};

    try {
      if (ownerId.isNotEmpty) {
        Query query = _itemlistQuery.limit(maxLength);
        query = query.where('ownerId', isEqualTo: ownerId);
        query = query.where('ownerType', isEqualTo: ownerType.name);
        if (itemlistType != null) {
          query = query.where('type', isEqualTo: itemlistType.name);
        }

        await query.get().then((querySnapshot) async {
          for (var document in querySnapshot.docs) {
            final data = document.data();
            if (data == null) continue;
            Itemlist itemlist = await _readItemlist(
              document.id,
              data as Map<String, dynamic>,
            );
            if ((!onlyPublic || itemlist.public) &&
                (!excludeMyFavorites ||
                    itemlist.id != CoreConstants.myFavorites)) {
              itemlists[itemlist.id] = itemlist;
            }
          }
        });
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.getByOwnerId',
      );
    }

    AppConfig.logger.d("${itemlists.length} itemlists found in total.");
    return itemlists;
  }

  @override
  Future<bool> delete(itemlistId) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'delete',
          {'itemlistId': itemlistId.toString()},
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.delete.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Removing public itemlist $itemlistId");
    try {
      await itemlistReference.doc(itemlistId).delete();
      AppConfig.logger.d("Itemlist $itemlistId removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.delete',
      );
      return false;
    }
  }

  @override
  Future<bool> update(Itemlist itemlist) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'update',
          {
            'itemlistId': itemlist.id,
            'itemlist': itemlist.toJSON(),
          },
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.update.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Updating Itemlist for user ${itemlist.id}");

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlist.id);
      await documentReference.update({
        AppFirestoreConstants.name: itemlist.name,
        AppFirestoreConstants.description: itemlist.description,
        AppFirestoreConstants.imgUrl: itemlist.imgUrl,
        'public': itemlist.public,
        AppFirestoreConstants.modifiedTime:
            DateTime.now().millisecondsSinceEpoch,
      });

      AppConfig.logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.update',
      );
    }

    AppConfig.logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  Future<bool> updateType(Itemlist itemlist) async {
    if (AppPlatformApi.isEnabled) return update(itemlist);
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Updating Itemlist for user ${itemlist.id}");

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlist.id);
      await documentReference.update({
        AppFirestoreConstants.type: itemlist.type.name,
      });

      AppConfig.logger.d("Itemlist ${itemlist.id} was updated");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.updateType',
      );
    }

    AppConfig.logger.d("Itemlist ${itemlist.id} was not updated");
    return false;
  }

  @override
  Future<bool> addReleaseItem(
    String itemlistId,
    AppReleaseItem releaseItem,
  ) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'addAppMediaItem',
          {
            'itemlistId': itemlistId,
            'appMediaItem': releaseItem.toJSON(),
          },
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.addReleaseItem.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      await documentReference.update({
        AppFirestoreConstants.appReleaseItems: FieldValue.arrayUnion([
          releaseItem.toJSON(),
        ]),
      });

      addedItem = true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.addReleaseItem',
      );
    }

    addedItem
        ? AppConfig.logger.d("AppReleaseItem was added to itemlist $itemlistId")
        : AppConfig.logger.d(
            "AppReleaseItem was not added to itemlist $itemlistId",
          );
    return addedItem;
  }

  @override
  Future<bool> deleteReleaseItem({
    required String itemlistId,
    required String itemId,
  }) async {
    if (AppPlatformApi.isEnabled) {
      return deleteMediaItem(itemlistId: itemlistId, itemId: itemId);
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    try {
      if (itemId.isEmpty || itemlistId.isEmpty) return false;
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      DocumentSnapshot snapshot = await documentReference.get();

      final data = snapshot.data();
      if (data == null) return false;
      Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
      itemlist.appReleaseItems?.removeWhere((element) => element.id == itemId);

      await documentReference.update(itemlist.toJSON());

      AppConfig.logger.i("releaseItem $itemId was removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.deleteReleaseItem',
      );
    }

    AppConfig.logger.d("releaseItem $itemId was not removed");
    return false;
  }

  @override
  Future<bool> addPreset(String chamberId, NeomChamberPreset preset) async {
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Adding preset to chamber $chamberId");
    bool addedItem = false;

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayUnion([
          preset.toJSON(),
        ]),
      });
      addedItem = true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.addPreset',
      );
    }

    addedItem
        ? AppConfig.logger.d("Preset was added to chamber $chamberId")
        : AppConfig.logger.d("Preset was not added to chamber $chamberId");
    return addedItem;
  }

  @override
  Future<bool> deletePreset(NeomChamberPreset preset, String chamberId) async {
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Removing preset from chamber $chamberId");

    try {
      DocumentReference documentReference = itemlistReference.doc(chamberId);
      await documentReference.update({
        AppFirestoreConstants.chamberPresets: FieldValue.arrayRemove([
          preset.toJSON(),
        ]),
      });

      AppConfig.logger.d("Preset was removed from chamber $chamberId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.deletePreset',
      );
    }

    AppConfig.logger.d("Preset was not  removed from chamber $chamberId");
    return false;
  }

  static ExternalItem _sanitizeExternalItemForStorage(ExternalItem item) {
    // YouTube Music repertoire items must never store a direct streaming URL.
    if (item.source == ExternalSource.youtube) {
      item.url = '';
    }
    return item;
  }

  @override
  Future<bool> addExternalItem(
    String itemlistId,
    ExternalItem externalItem,
  ) async {
    final safeItem = _sanitizeExternalItemForStorage(externalItem);
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'addExternalItem',
          {
            'itemlistId': itemlistId,
            'externalItem': safeItem.toJSON(),
          },
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.addExternalItem.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    AppConfig.logger.d("Adding item to itemlist $itemlistId");
    bool addedItem = false;

    try {
      final documentReference = itemlistReference.doc(itemlistId);
      final snapshot = await documentReference.get();
      if (snapshot.exists && snapshot.data() != null) {
        final existing = Itemlist.fromJSON(snapshot.data()!);
        final list = List<ExternalItem>.from(existing.externalItems ?? const []);
        list.removeWhere((e) => e.id == safeItem.id);
        list.add(safeItem);
        await documentReference.update({
          AppFirestoreConstants.externalItems:
              list.map((e) => e.toJSON()).toList(),
          AppFirestoreConstants.modifiedTime:
              DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await documentReference.update({
          AppFirestoreConstants.externalItems: FieldValue.arrayUnion([
            safeItem.toJSON(),
          ]),
        });
      }

      addedItem = true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.addExternalItem',
      );
    }

    addedItem
        ? AppConfig.logger.d("ExternalItem was added to itemlist $itemlistId")
        : AppConfig.logger.d(
            "ExternalItem was not added to itemlist $itemlistId",
          );
    return addedItem;
  }

  /// Adds multiple external repertoire items (e.g. imported from a YouTube
  /// playlist) in a single deduplicated Firestore update.
  Future<int> addExternalItemsBulk(
    String itemlistId,
    List<ExternalItem> items,
  ) async {
    if (itemlistId.trim().isEmpty || items.isEmpty) return 0;
    final sanitized = items
        .where((e) => e.id.trim().isNotEmpty)
        .map(_sanitizeExternalItemForStorage)
        .toList();
    if (sanitized.isEmpty) return 0;

    if (AppPlatformApi.isEnabled) {
      int added = 0;
      for (final item in sanitized) {
        if (await addExternalItem(itemlistId, item)) added++;
      }
      return added;
    }
    if (PublicCatalogReadPolicy.enabled) return 0;

    try {
      final documentReference = itemlistReference.doc(itemlistId);
      final snapshot = await documentReference.get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return 0;

      final existing = Itemlist.fromJSON(data);
      final mergedById = <String, ExternalItem>{
        for (final e in existing.externalItems ?? const <ExternalItem>[])
          if (e.id.isNotEmpty) e.id: e,
      };
      int newlyAdded = 0;
      for (final item in sanitized) {
        if (!mergedById.containsKey(item.id)) newlyAdded++;
        mergedById[item.id] = item;
      }

      await documentReference.update({
        AppFirestoreConstants.externalItems:
            mergedById.values.map((e) => e.toJSON()).toList(),
        if (existing.imgUrl.isEmpty && sanitized.first.imgUrl.isNotEmpty)
          AppFirestoreConstants.imgUrl: sanitized.first.imgUrl,
        AppFirestoreConstants.modifiedTime:
            DateTime.now().millisecondsSinceEpoch,
      });

      return newlyAdded > 0 ? newlyAdded : sanitized.length;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.addExternalItemsBulk',
      );
      return 0;
    }
  }

  /// Persists the reordered item arrays cleanly without mixing external items
  /// into internal `appMediaItems`.
  Future<bool> updateItemsOrder(Itemlist itemlist) async {
    if (itemlist.id.trim().isEmpty) return false;
    if (AppPlatformApi.isEnabled) {
      return update(itemlist);
    }
    if (PublicCatalogReadPolicy.enabled) return false;

    try {
      await itemlistReference.doc(itemlist.id).update({
        AppFirestoreConstants.appMediaItems:
            itemlist.appMediaItems?.map((m) => m.toJSON()).toList() ?? [],
        AppFirestoreConstants.appReleaseItems:
            itemlist.appReleaseItems?.map((r) => r.toJSON()).toList() ?? [],
        AppFirestoreConstants.externalItems:
            itemlist.externalItems
                ?.map((e) => _sanitizeExternalItemForStorage(e).toJSON())
                .toList() ??
            [],
        AppFirestoreConstants.modifiedTime:
            DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.updateItemsOrder',
      );
      return false;
    }
  }

  @override
  Future<bool> deleteExternalItem({
    required String itemlistId,
    required String itemId,
  }) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'deleteExternalItem',
          {'itemlistId': itemlistId, 'itemId': itemId},
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.deleteExternalItem.platform',
        );
        return false;
      }
    }
    if (PublicCatalogReadPolicy.enabled) return false;
    try {
      if (itemId.isEmpty || itemlistId.isEmpty) return false;
      DocumentReference documentReference = itemlistReference.doc(itemlistId);
      DocumentSnapshot snapshot = await documentReference.get();

      final data = snapshot.data();
      if (data == null) return false;
      Itemlist itemlist = Itemlist.fromJSON(data as Map<String, dynamic>);
      itemlist.externalItems?.removeWhere((element) => element.id == itemId);

      await documentReference.update(itemlist.toJSON());

      AppConfig.logger.i("externalItem $itemId was removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.deleteExternalItem',
      );
    }

    AppConfig.logger.d("externalItem $itemId was not removed");
    return false;
  }

  Future<bool> updateItemState({
    required String itemlistId,
    required String itemId,
    required int state,
  }) async {
    if (AppPlatformApi.isEnabled) {
      try {
        final ok = await AppPlatformApi.client('itemlists').mutate(
          'updateItemState',
          {
            'itemlistId': itemlistId,
            'itemId': itemId,
            'state': state,
          },
          durable: false,
        );
        return ok == true;
      } catch (e, st) {
        NeomErrorLogger.recordError(
          e,
          st,
          module: 'neom_core',
          operation: 'ItemlistFirestore.updateItemState.platform',
        );
        return false;
      }
    }
    return false;
  }

  /// The itemlist addressed by `/{kind}/{ownerSlug}/{slug}`.
  ///
  /// The kind is not part of the match: it makes the URL self-describing, but
  /// an album re-labelled as an EP should keep resolving from links already
  /// shared. The artist plus the title is what identifies it.
  Future<Itemlist?> getByOwnerAndSlug(
    String ownerSlug,
    String slug, {
    ItemlistType? type,
  }) async {
    if (ownerSlug.isEmpty || slug.isEmpty) return null;

    try {
      Query<Map<String, dynamic>> query = _itemlistQuery
          .where('ownerSlug', isEqualTo: ownerSlug)
          .where('slug', isEqualTo: slug);
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      final querySnapshot = await query.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return await _readItemlist(doc.id, doc.data());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.getByOwnerAndSlug',
      );
    }
    return null;
  }

  @override
  Future<Itemlist?> getBySlug(String slug) async {
    if (slug.isEmpty) return null;

    try {
      final querySnapshot = await _itemlistQuery
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return await _readItemlist(doc.id, doc.data());
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'ItemlistFirestore.getBySlug',
      );
    }
    return null;
  }
}
