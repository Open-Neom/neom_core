import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/repository/app_release_item_repository.dart';
import '../../utils/enums/release_status.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

import 'release_deduplication_service.dart';

class AppReleaseItemFirestore implements AppReleaseItemRepository {
  final appReleaseItemReference = FirebaseFirestore.instance.collection(
    AppFirestoreCollectionConstants.appReleaseItems,
  );
  final userReference = FirebaseFirestore.instance.collection(
    AppFirestoreCollectionConstants.users,
  );
  final profileReference = FirebaseFirestore.instance.collectionGroup(
    AppFirestoreCollectionConstants.profiles,
  );

  static Map<String, AppReleaseItem> _cachedAllReleaseItems = {};
  static DateTime? _lastAllReleaseItemsFetchTime;
  static const Duration _allReleaseItemsCacheTtl = Duration(minutes: 10);

  bool get _canPersistUserActivity => AppConfig.instance.canPersistUserActivity;

  bool _isVisibleToCurrentUser(AppReleaseItem item) =>
      _canPersistUserActivity || item.isPubliclyVisible;

  AppReleaseItem _projectForCurrentUser(AppReleaseItem item) =>
      _canPersistUserActivity ? item : item.toPublicProjection();

  Map<String, AppReleaseItem> _catalogForCurrentUser(
    Iterable<AppReleaseItem> items,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final filtered = items.where((item) {
      if (!_canPersistUserActivity) return item.isPubliclyVisible;

      // Preserve the historical signed-in catalogue behaviour while keeping
      // the anonymous contract strict.
      return !item.isSuspended &&
          (item.status == ReleaseStatus.publish ||
              (item.createdTime > 0 &&
                  DateTime.fromMillisecondsSinceEpoch(
                        item.createdTime,
                      ).add(const Duration(days: 28)).millisecondsSinceEpoch <
                      now));
    }).toList();

    final deduplicated = ReleaseDeduplicationService().deduplicateList(
      filtered,
    );
    return {
      for (final item in deduplicated) item.id: _projectForCurrentUser(item),
    };
  }

  static void invalidateAllReleaseItemsCache() {
    _cachedAllReleaseItems.clear();
    _lastAllReleaseItemsFetchTime = null;
  }

  @override
  Future<String> insert(AppReleaseItem appReleaseItem) async {
    if (!_canPersistUserActivity) return '';
    AppConfig.logger.d("Adding appReleaseItem to database collection");
    String releaseItemId = appReleaseItem.id;
    try {
      // Address is `/a/{ownerSlug}/{slug}`, unique because an artist cannot
      // publish two releases with the same name. The title slug therefore does
      // NOT need to be globally unique: two artists may each have a "Piedad".
      if (appReleaseItem.ownerSlug.isEmpty &&
          appReleaseItem.ownerName.isNotEmpty) {
        appReleaseItem.ownerSlug = AppReleaseItem.generateOwnerSlug(
          appReleaseItem.ownerName,
        );
      }

      if (appReleaseItem.slug.isEmpty && appReleaseItem.name.isNotEmpty) {
        appReleaseItem.slug = AppReleaseItem.generateSlug(appReleaseItem.name);
      }

      // Same artist re-uploading the same title is a duplicate, not a second
      // release: reuse the document instead of creating a rival address.
      if (appReleaseItem.ownerSlug.isNotEmpty &&
          appReleaseItem.slug.isNotEmpty) {
        final existing = await getByOwnerAndSlug(
          appReleaseItem.ownerSlug,
          appReleaseItem.slug,
        );
        if (existing != null && existing.id.isNotEmpty) {
          AppConfig.logger.w(
            "Duplicate release '${appReleaseItem.name}' by "
            "${appReleaseItem.ownerName}. Updating existing doc ${existing.id}",
          );
          releaseItemId = existing.id;
          appReleaseItem.id = existing.id;
        }
      }

      if (releaseItemId.isNotEmpty) {
        await appReleaseItemReference
            .doc(releaseItemId)
            .set(appReleaseItem.toJSON());
      } else {
        DocumentReference documentReference = await appReleaseItemReference.add(
          appReleaseItem.toJSON(),
        );
        releaseItemId = documentReference.id;
      }

      invalidateAllReleaseItemsCache();
      AppConfig.logger.d(
        "AppReleaseItem inserted into Firestore with id: $releaseItemId",
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'insert',
      );
      AppConfig.logger.i("AppReleaseItem not inserted into Firestore");
    }

    return releaseItemId;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveAll({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedAllReleaseItems.isNotEmpty &&
        _lastAllReleaseItemsFetchTime != null &&
        DateTime.now().difference(_lastAllReleaseItemsFetchTime!) <
            _allReleaseItemsCacheTtl) {
      AppConfig.logger.d(
        "retrieveAll returned from in-memory cache: ${_cachedAllReleaseItems.length} releaseItems",
      );
      return _catalogForCurrentUser(_cachedAllReleaseItems.values);
    }

    AppConfig.logger.t("Get all AppReleaseItem from Firestore");

    Map<String, AppReleaseItem> rawReleaseItems = {};
    try {
      final QuerySnapshot querySnapshot = forceRefresh
          ? await appReleaseItemReference.get(
              const GetOptions(source: Source.server),
            )
          : await appReleaseItemReference.get();

      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(
            queryDocumentSnapshot.data(),
          );
          releaseItem.id = queryDocumentSnapshot.id;
          rawReleaseItems[releaseItem.id] = releaseItem;
        }
      }

      final releaseItems = _catalogForCurrentUser(rawReleaseItems.values);

      // Keep duplicate records out of the UI, but never mutate Firestore from a
      // read path. Physical cleanup belongs in an authenticated admin job with
      // a dry-run and audit trail.
      if (rawReleaseItems.length > releaseItems.length) {
        AppConfig.logger.w(
          "Filtered ${rawReleaseItems.length - releaseItems.length} hidden, "
          "suspended, or duplicate release(s); no client cleanup was run.",
        );
      }

      // Cache raw documents so an authenticated -> guest session transition
      // cannot return a previously unfiltered map.
      _cachedAllReleaseItems = Map<String, AppReleaseItem>.from(
        rawReleaseItems,
      );
      _lastAllReleaseItemsFetchTime = DateTime.now();
      AppConfig.logger.d("${releaseItems.length} releaseItems found");
      return releaseItems;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'retrieveAll',
      );
    }

    AppConfig.logger.d("No releaseItems found");
    return {};
  }

  @override
  Future<AppReleaseItem> retrieve(String releaseItemId) async {
    AppConfig.logger.d("Getting item $releaseItemId");
    AppReleaseItem appReleaseItem = AppReleaseItem();
    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appReleaseItemReference.doc(releaseItemId).get();
      if (doc.exists) {
        final rawItem = AppReleaseItem.fromJSON(doc.data())..id = doc.id;
        if (_isVisibleToCurrentUser(rawItem)) {
          appReleaseItem = _projectForCurrentUser(rawItem);
          AppConfig.logger.d(
            "AppReleaseItem ${appReleaseItem.name} was retrieved with details",
          );
        } else {
          AppConfig.logger.d("AppReleaseItem is not available to this session");
        }
      } else {
        AppConfig.logger.d("AppReleaseItem not found");
      }
    } catch (e) {
      AppConfig.logger.d(e);
      rethrow;
    }
    return appReleaseItem;
  }

  /// Finds a release from either a Firestore document id or a public slug.
  ///
  /// Legacy EMXI book addresses can be `ownerSlug/releaseSlug`. Such a value
  /// must never be passed to `collection.doc(...)`, because `/` is a document
  /// path separator and would abort the remaining lookup fallbacks on web.
  Future<AppReleaseItem?> findByIdOrSlug(String idOrSlug) async {
    final value = idOrSlug.trim();
    if (value.isEmpty) return null;

    if (value.contains('/')) {
      final segments = value
          .split('/')
          .where((part) => part.isNotEmpty)
          .toList();
      if (segments.length >= 2) {
        final byOwnerAndSlug = await getByOwnerAndSlug(
          segments.first,
          segments.skip(1).join('/'),
        );
        if (byOwnerAndSlug != null && byOwnerAndSlug.id.isNotEmpty) {
          return byOwnerAndSlug;
        }
      }

      final legacySlug = await getBySlug(value);
      return legacySlug?.id.isNotEmpty == true ? legacySlug : null;
    }

    try {
      final byId = await retrieve(value);
      if (byId.id.isNotEmpty) return byId;
    } catch (e) {
      AppConfig.logger.d('Release id lookup failed; trying slug: $e');
    }

    final bySlug = await getBySlug(value);
    return bySlug?.id.isNotEmpty == true ? bySlug : null;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveFromList(
    List<String> releaseItemIds,
  ) async {
    AppConfig.logger.t("Getting ${releaseItemIds}appReleaseItems from list");

    Map<String, AppReleaseItem> appItems = {};
    if (releaseItemIds.isEmpty) return appItems;

    try {
      // OPTIMIZED: Use whereIn with batching instead of getting all items
      const batchSize = 30;
      for (var i = 0; i < releaseItemIds.length; i += batchSize) {
        final batch = releaseItemIds.skip(i).take(batchSize).toList();
        final querySnapshot = await appReleaseItemReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var documentSnapshot in querySnapshot.docs) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(
            documentSnapshot.data(),
          );
          releaseItem.id = documentSnapshot.id;
          if (_isVisibleToCurrentUser(releaseItem)) {
            AppConfig.logger.d(
              "AppReleaseItem ${releaseItem.name} was retrieved with details",
            );
            appItems[documentSnapshot.id] = _projectForCurrentUser(releaseItem);
          }
        }
      }
    } catch (e) {
      AppConfig.logger.d(e);
    }
    return appItems;
  }

  @override
  Future<bool> remove(AppReleaseItem appReleaseItem) async {
    if (!_canPersistUserActivity) return false;
    AppConfig.logger.d(
      "Removing appReleaseItem ${appReleaseItem.name} with id ${appReleaseItem.id} from database collection",
    );
    try {
      await appReleaseItemReference.doc(appReleaseItem.id).delete();
      invalidateAllReleaseItemsCache();
      return true;
    } catch (e) {
      AppConfig.logger.d(e.toString());
      return false;
    }
  }

  @override
  Future<bool> addBoughtUser({
    required String releaseItemId,
    required String userId,
  }) async {
    if (!_canPersistUserActivity) return false;
    AppConfig.logger.t("$releaseItemId would add user $userId");

    try {
      // OPTIMIZED: Use direct update instead of iterating all items
      await appReleaseItemReference.doc(releaseItemId).update({
        AppFirestoreConstants.boughtUsers: FieldValue.arrayUnion([userId]),
      });
      AppConfig.logger.d("$releaseItemId has added user $userId");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'addBoughtUser',
      );
    }
    return false;
  }

  @override
  Future<bool> exists(String releaseItemId) async {
    AppConfig.logger.d("Getting releaseItem $releaseItemId");

    try {
      if (releaseItemId.isEmpty) return false;
      if (!_canPersistUserActivity) {
        return (await retrieve(releaseItemId)).id.isNotEmpty;
      }
      // OPTIMIZED: Use await instead of .then()
      final doc = await appReleaseItemReference.doc(releaseItemId).get();
      if (doc.exists) {
        AppConfig.logger.d("AppMediaItem found");
        return true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'exists',
      );
    }
    AppConfig.logger.d("AppMediaItem not found");
    return false;
  }

  Future<void> existsOrInsert(AppReleaseItem releaseItem) async {
    if (!_canPersistUserActivity) return;
    AppConfig.logger.t("existsOrInsert releaseItem ${releaseItem.id}");

    try {
      // OPTIMIZED: Use await instead of .then()
      final doc = await appReleaseItemReference.doc(releaseItem.id).get();
      if (doc.exists) {
        AppConfig.logger.t("AppReleaseItem found");
      } else {
        AppConfig.logger.d(
          "AppReleaseItem ${releaseItem.id}. ${releaseItem.name} not found. Inserting",
        );
        await insert(releaseItem);
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'existsOrInsert',
      );
    }
  }

  /// Updates specific fields of an AppReleaseItem
  Future<bool> updateFields(
    String releaseItemId,
    Map<String, dynamic> fields,
  ) async {
    if (!_canPersistUserActivity) return false;
    AppConfig.logger.d("Updating appReleaseItem $releaseItemId fields");
    try {
      await appReleaseItemReference.doc(releaseItemId).update(fields);
      AppConfig.logger.d("AppReleaseItem $releaseItemId updated successfully");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'updateFields',
      );
      return false;
    }
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveByCategory(
    String category, {
    int limit = 30,
  }) async {
    AppConfig.logger.t("Getting AppReleaseItems by category: $category");
    Map<String, AppReleaseItem> releaseItems = {};
    if (category.isEmpty) return releaseItems;

    try {
      final querySnapshot = await appReleaseItemReference
          .where('categories', arrayContains: category)
          .where(
            AppFirestoreConstants.status,
            isEqualTo: ReleaseStatus.publish.name,
          )
          .limit(limit)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(doc.data());
          releaseItem.id = doc.id;
          if (!releaseItem.isSuspended &&
              _isVisibleToCurrentUser(releaseItem)) {
            releaseItems[doc.id] = _projectForCurrentUser(releaseItem);
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'retrieveByCategory',
      );
    }

    AppConfig.logger.d(
      "${releaseItems.length} releaseItems found for category: $category",
    );
    return releaseItems;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveByOwner(
    String ownerEmail, {
    int limit = 30,
  }) async {
    AppConfig.logger.t("Getting AppReleaseItems by owner: $ownerEmail");
    Map<String, AppReleaseItem> releaseItems = {};
    if (ownerEmail.isEmpty) return releaseItems;

    try {
      final querySnapshot = await appReleaseItemReference
          .where('ownerEmail', isEqualTo: ownerEmail)
          .where(
            AppFirestoreConstants.status,
            isEqualTo: ReleaseStatus.publish.name,
          )
          .limit(limit)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(doc.data());
          releaseItem.id = doc.id;
          if (!releaseItem.isSuspended &&
              _isVisibleToCurrentUser(releaseItem)) {
            releaseItems[doc.id] = _projectForCurrentUser(releaseItem);
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'retrieveByOwner',
      );
    }

    AppConfig.logger.d(
      "${releaseItems.length} releaseItems found for owner: $ownerEmail",
    );
    return releaseItems;
  }

  /// Public-safe author shelves use stable profile/slug identifiers instead
  /// of carrying the owner's account email in guest controller state.
  Future<Map<String, AppReleaseItem>> retrieveByOwnerProfileId(
    String ownerProfileId, {
    int limit = 30,
  }) => _retrievePublishedByOwnerField(
    field: 'ownerProfileId',
    value: ownerProfileId,
    limit: limit,
  );

  Future<Map<String, AppReleaseItem>> retrieveByOwnerSlug(
    String ownerSlug, {
    int limit = 30,
  }) => _retrievePublishedByOwnerField(
    field: 'ownerSlug',
    value: ownerSlug,
    limit: limit,
  );

  Future<Map<String, AppReleaseItem>> _retrievePublishedByOwnerField({
    required String field,
    required String value,
    required int limit,
  }) async {
    final releaseItems = <String, AppReleaseItem>{};
    if (value.trim().isEmpty) return releaseItems;

    try {
      final querySnapshot = await appReleaseItemReference
          .where(field, isEqualTo: value.trim())
          .where(
            AppFirestoreConstants.status,
            isEqualTo: ReleaseStatus.publish.name,
          )
          .limit(limit)
          .get();

      for (final doc in querySnapshot.docs) {
        final releaseItem = AppReleaseItem.fromJSON(doc.data())..id = doc.id;
        if (!releaseItem.isSuspended && _isVisibleToCurrentUser(releaseItem)) {
          releaseItems[doc.id] = _projectForCurrentUser(releaseItem);
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'retrieveByOwnerIdentity',
      );
    }
    return releaseItems;
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveByLanguage(
    String language, {
    int limit = 30,
  }) async {
    AppConfig.logger.t("Getting AppReleaseItems by language: $language");
    Map<String, AppReleaseItem> releaseItems = {};
    if (language.isEmpty) return releaseItems;

    try {
      final querySnapshot = await appReleaseItemReference
          .where('language', isEqualTo: language)
          .where(
            AppFirestoreConstants.status,
            isEqualTo: ReleaseStatus.publish.name,
          )
          .limit(limit)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(doc.data());
          releaseItem.id = doc.id;
          if (!releaseItem.isSuspended &&
              _isVisibleToCurrentUser(releaseItem)) {
            releaseItems[doc.id] = _projectForCurrentUser(releaseItem);
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'retrieveByLanguage',
      );
    }

    AppConfig.logger.d(
      "${releaseItems.length} releaseItems found for language: $language",
    );
    return releaseItems;
  }

  /// Retrieves all AppReleaseItems with pending status (for admin review)
  /// Note: "pending" is used for items awaiting admin review,
  /// while "draft" is for items still in local cache/editing
  Future<List<AppReleaseItem>> retrievePendingReleases() async {
    if (!_canPersistUserActivity) return [];
    AppConfig.logger.t("Retrieving pending AppReleaseItems for review");

    List<AppReleaseItem> pendingReleases = [];
    try {
      QuerySnapshot querySnapshot = await appReleaseItemReference
          .where(
            AppFirestoreConstants.status,
            isEqualTo: ReleaseStatus.pending.name,
          )
          .orderBy(AppFirestoreConstants.createdTime, descending: true)
          .limit(50)
          .get();

      for (var queryDocumentSnapshot in querySnapshot.docs) {
        if (queryDocumentSnapshot.exists) {
          AppReleaseItem releaseItem = AppReleaseItem.fromJSON(
            queryDocumentSnapshot.data(),
          );
          releaseItem.id = queryDocumentSnapshot.id;
          pendingReleases.add(releaseItem);
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'retrievePendingReleases',
      );
    }

    AppConfig.logger.d("${pendingReleases.length} pending releases found");
    return pendingReleases;
  }

  /// Approves a release by changing its status to publish
  Future<bool> approveRelease(String releaseItemId) async {
    if (!_canPersistUserActivity) return false;
    AppConfig.logger.d("Approving release $releaseItemId");
    try {
      await appReleaseItemReference.doc(releaseItemId).update({
        AppFirestoreConstants.status: ReleaseStatus.publish.name,
        AppFirestoreConstants.modifiedTime:
            DateTime.now().millisecondsSinceEpoch,
      });
      AppConfig.logger.d("Release $releaseItemId approved successfully");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'approveRelease',
      );
      return false;
    }
  }

  /// Rejects a release by removing it or marking as rejected
  Future<bool> rejectRelease(String releaseItemId) async {
    if (!_canPersistUserActivity) return false;
    AppConfig.logger.d("Rejecting release $releaseItemId");
    try {
      await appReleaseItemReference.doc(releaseItemId).delete();
      AppConfig.logger.d("Release $releaseItemId rejected and removed");
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'rejectRelease',
      );
      return false;
    }
  }

  /// Increments the total page view counter for a book and tracks
  /// individual page views in a subcollection for granular analytics.
  ///
  /// Uses [FieldValue.increment] for atomic, race-condition-free counting.
  /// The subcollection stores per-page view counts with timestamps.
  Future<bool> incrementPageView(String releaseItemId, int pageNumber) async {
    if (!AppConfig.instance.canPersistUserActivity) {
      AppConfig.logger.d(
        "Skipping page-view persistence for guest or unloaded user",
      );
      return false;
    }

    AppConfig.logger.t(
      "Increment page view for item: $releaseItemId, page: $pageNumber",
    );
    try {
      await appReleaseItemReference.doc(releaseItemId).update({
        'totalPageViews': FieldValue.increment(1),
      });

      await appReleaseItemReference
          .doc(releaseItemId)
          .collection('pageViews')
          .doc(pageNumber.toString())
          .set({
            'views': FieldValue.increment(1),
            'lastViewed': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'incrementPageView',
      );
      return false;
    }
  }

  /// Retrieve the release addressed by `/a/{ownerSlug}/{slug}`.
  ///
  /// The pair is unique by domain rule — an artist cannot publish two releases
  /// with the same name — so no disambiguation is needed and the slug can stay
  /// the clean title instead of being prefixed on collision.
  Future<AppReleaseItem?> getByOwnerAndSlug(
    String ownerSlug,
    String slug,
  ) async {
    if (ownerSlug.isEmpty || slug.isEmpty) return null;

    try {
      final querySnapshot = await appReleaseItemReference
          .where('ownerSlug', isEqualTo: ownerSlug)
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final item = AppReleaseItem.fromJSON(doc.data());
        item.id = doc.id;
        return _isVisibleToCurrentUser(item)
            ? _projectForCurrentUser(item)
            : null;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'getByOwnerAndSlug',
      );
    }
    return null;
  }

  /// Retrieve an AppReleaseItem by its URL slug.
  /// Used for vanity URL resolution: emxi.org/quemando-mis-razones → book
  @override
  Future<AppReleaseItem?> getBySlug(String slug) async {
    if (slug.isEmpty) return null;

    try {
      final querySnapshot = await appReleaseItemReference
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final item = AppReleaseItem.fromJSON(doc.data());
        item.id = doc.id;
        return _isVisibleToCurrentUser(item)
            ? _projectForCurrentUser(item)
            : null;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'getBySlug',
      );
    }
    return null;
  }
}
