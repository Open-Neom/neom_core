import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/model/item_list.dart';
import '../../domain/model/post.dart';
import '../../utils/enums/release_status.dart';
import '../../utils/neom_error_logger.dart';
import 'app_release_item_firestore.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

/// Service responsible for identifying duplicate [AppReleaseItem]s,
/// scoring their completeness to determine the canonical record,
/// merging user interactions/metadata, and executing a complete
/// cascading purge across all related Firestore collections.
class ReleaseDeduplicationService {

  static final ReleaseDeduplicationService _instance = ReleaseDeduplicationService._internal();
  factory ReleaseDeduplicationService() => _instance;
  ReleaseDeduplicationService._internal();

  CollectionReference get _releaseItemsRef =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.appReleaseItems);
  CollectionReference get _itemlistsRef =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.itemlists);
  CollectionReference get _usersRef =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.users);
  CollectionReference get _postsRef =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.posts);
  CollectionReference get _requestsRef =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.requests);
  CollectionReference get _activityFeedRef =>
      FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.activityFeed);

  bool _isDeduplicating = false;

  /// Generates a normalized deduplication key for an [AppReleaseItem].
  /// Items sharing the same key are candidates for deduplication.
  String normalizeKey(AppReleaseItem item) {
    if (item.name.trim().isEmpty) return item.id;

    final titleSlug = AppReleaseItem.generateSlug(item.name.trim());
    String ownerKey = '';

    if (item.ownerProfileId != null && item.ownerProfileId!.trim().isNotEmpty) {
      ownerKey = item.ownerProfileId!.trim().toLowerCase();
    } else if (item.ownerName.trim().isNotEmpty) {
      ownerKey = AppReleaseItem.generateSlug(item.ownerName.trim());
    } else if (item.ownerEmail.trim().isNotEmpty) {
      ownerKey = item.ownerEmail.trim().toLowerCase();
    }

    return '$titleSlug::$ownerKey';
  }

  /// Calculates a completeness and quality score for an [AppReleaseItem].
  /// Higher score means the item is more complete, valid, and rich in metadata.
  int calculateCompletenessScore(AppReleaseItem item) {
    int score = 0;

    // Cover image validity
    if (item.imgUrl.isNotEmpty) {
      score += item.imgUrl.startsWith('http') ? 20 : 5;
    }

    // Media / preview URL validity
    if (item.previewUrl.isNotEmpty) {
      score += item.previewUrl.startsWith('http') ? 25 : 5;
    }

    // Description presence & length
    final desc = item.description.trim();
    if (desc.isNotEmpty) {
      score += 10 + min(10, desc.length ~/ 25);
    }

    // Gallery images
    if (item.galleryUrls != null && item.galleryUrls!.isNotEmpty) {
      score += 10 + min(5, item.galleryUrls!.length * 2);
    }

    // Categories / genres
    if (item.categories.isNotEmpty) {
      score += 10 + min(5, item.categories.length * 2);
    }

    // Pricing models
    if (item.digitalPrice != null && (item.digitalPrice!.amount > 0 || (item.digitalPrice!.currency != null))) {
      score += 10;
    }
    if (item.physicalPrice != null && (item.physicalPrice!.amount > 0 || (item.physicalPrice!.currency != null))) {
      score += 10;
    }

    // User engagement (likes, purchases, comments, shares)
    score += (item.boughtUsers?.length ?? 0) * 10;
    score += (item.likedProfiles?.length ?? 0) * 3;
    score += (item.commentIds?.length ?? 0) * 3;
    score += (item.sharedProfiles?.length ?? 0) * 2;

    // Metadata details
    if (item.publishedYear != null && item.publishedYear! > 0) score += 5;
    if (item.duration > 0) score += 5;
    if (item.dominantColor.isNotEmpty) score += 3;
    if (item.slug.isNotEmpty) score += 3;
    if (item.metaId != null && item.metaId!.isNotEmpty) score += 5;

    // Status
    if (item.status == ReleaseStatus.publish) {
      score += 15;
    } else if (item.status == ReleaseStatus.pending) {
      score += 5;
    }

    // Penalties
    if (item.isSuspended) score -= 50;

    return score;
  }

  /// Groups items by normalized key and filters to only clusters with duplicates (> 1 item).
  Map<String, List<AppReleaseItem>> groupDuplicates(Iterable<AppReleaseItem> items) {
    final Map<String, List<AppReleaseItem>> groups = {};

    for (final item in items) {
      final key = normalizeKey(item);
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => []).add(item);
    }

    groups.removeWhere((key, list) => list.length <= 1);
    return groups;
  }

  /// Selects the canonical item from a list of duplicate [AppReleaseItem]s.
  /// The canonical item is the one with the highest completeness score.
  /// If tied, prefers the older item (earliest `createdTime`).
  AppReleaseItem selectCanonicalItem(List<AppReleaseItem> duplicates) {
    if (duplicates.isEmpty) throw ArgumentError('Duplicates list cannot be empty');
    if (duplicates.length == 1) return duplicates.first;

    final sorted = List<AppReleaseItem>.from(duplicates)..sort((a, b) {
      final scoreA = calculateCompletenessScore(a);
      final scoreB = calculateCompletenessScore(b);
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA); // Higher score first
      }
      // Tie-breaker: older creation time
      if (a.createdTime > 0 && b.createdTime > 0) {
        return a.createdTime.compareTo(b.createdTime);
      }
      return b.id.compareTo(a.id);
    });

    return sorted.first;
  }

  /// In-memory deduplication: given a list of [AppReleaseItem]s, returns a clean list
  /// containing only the canonical item for each duplicate group, with merged metadata.
  List<AppReleaseItem> deduplicateList(List<AppReleaseItem> items) {
    if (items.length <= 1) return items;

    final Map<String, List<AppReleaseItem>> groups = {};
    for (final item in items) {
      final key = normalizeKey(item);
      groups.putIfAbsent(key, () => []).add(item);
    }

    final List<AppReleaseItem> result = [];
    for (final entry in groups.entries) {
      if (entry.value.length == 1) {
        result.add(entry.value.first);
      } else {
        final canonical = selectCanonicalItem(entry.value);
        for (final dup in entry.value) {
          if (dup.id != canonical.id) {
            mergeMetadata(canonical, dup);
          }
        }
        result.add(canonical);
      }
    }

    return result;
  }

  /// Merges engagement, interactions and missing metadata from [duplicate] into [canonical].
  bool mergeMetadata(AppReleaseItem canonical, AppReleaseItem duplicate) {
    bool changed = false;

    // Fill missing description
    if (canonical.description.trim().isEmpty && duplicate.description.trim().isNotEmpty) {
      canonical.description = duplicate.description;
      changed = true;
    }

    // Fill missing image URL
    if ((canonical.imgUrl.isEmpty || !canonical.imgUrl.startsWith('http')) &&
        duplicate.imgUrl.isNotEmpty && duplicate.imgUrl.startsWith('http')) {
      canonical.imgUrl = duplicate.imgUrl;
      changed = true;
    }

    // Fill missing preview URL
    if ((canonical.previewUrl.isEmpty || !canonical.previewUrl.startsWith('http')) &&
        duplicate.previewUrl.isNotEmpty && duplicate.previewUrl.startsWith('http')) {
      canonical.previewUrl = duplicate.previewUrl;
      changed = true;
    }

    // Merge gallery URLs
    if (duplicate.galleryUrls != null && duplicate.galleryUrls!.isNotEmpty) {
      final current = Set<String>.from(canonical.galleryUrls ?? []);
      final beforeSize = current.length;
      current.addAll(duplicate.galleryUrls!);
      if (current.length != beforeSize) {
        canonical.galleryUrls = current.toList();
        changed = true;
      }
    }

    // Merge categories
    if (duplicate.categories.isNotEmpty) {
      final current = Set<String>.from(canonical.categories);
      final beforeSize = current.length;
      current.addAll(duplicate.categories);
      if (current.length != beforeSize) {
        canonical.categories = current.toList();
        changed = true;
      }
    }

    // Merge prices if missing
    if (canonical.digitalPrice == null && duplicate.digitalPrice != null) {
      canonical.digitalPrice = duplicate.digitalPrice;
      changed = true;
    }
    if (canonical.physicalPrice == null && duplicate.physicalPrice != null) {
      canonical.physicalPrice = duplicate.physicalPrice;
      changed = true;
    }

    // Merge likes
    if (duplicate.likedProfiles != null && duplicate.likedProfiles!.isNotEmpty) {
      final current = Set<String>.from(canonical.likedProfiles ?? []);
      final beforeSize = current.length;
      current.addAll(duplicate.likedProfiles!);
      if (current.length != beforeSize) {
        canonical.likedProfiles = current.toList();
        changed = true;
      }
    }

    // Merge buyers
    if (duplicate.boughtUsers != null && duplicate.boughtUsers!.isNotEmpty) {
      final current = Set<String>.from(canonical.boughtUsers ?? []);
      final beforeSize = current.length;
      current.addAll(duplicate.boughtUsers!);
      if (current.length != beforeSize) {
        canonical.boughtUsers = current.toList();
        changed = true;
      }
    }

    // Merge comments
    if (duplicate.commentIds != null && duplicate.commentIds!.isNotEmpty) {
      final current = Set<String>.from(canonical.commentIds ?? []);
      final beforeSize = current.length;
      current.addAll(duplicate.commentIds!);
      if (current.length != beforeSize) {
        canonical.commentIds = current.toList();
        changed = true;
      }
    }

    // Published year & duration fallbacks
    if ((canonical.publishedYear == null || canonical.publishedYear! <= 0) &&
        duplicate.publishedYear != null && duplicate.publishedYear! > 0) {
      canonical.publishedYear = duplicate.publishedYear;
      changed = true;
    }
    if (canonical.duration <= 0 && duplicate.duration > 0) {
      canonical.duration = duplicate.duration;
      changed = true;
    }

    return changed;
  }

  /// Purges a single [duplicate] [AppReleaseItem] and removes all its cascading references.
  Future<bool> purgeDuplicate(AppReleaseItem duplicate, AppReleaseItem canonical) async {
    if (duplicate.id.isEmpty || duplicate.id == canonical.id) return false;

    AppConfig.logger.w('🗑️ [Deduplication] Purging duplicate AppReleaseItem "${duplicate.name}" '
        '(ID: ${duplicate.id}) in favor of canonical (ID: ${canonical.id})');

    try {
      // 1. Merge metadata & engagement into canonical and update canonical doc
      final hasChanges = mergeMetadata(canonical, duplicate);
      if (hasChanges) {
        await _releaseItemsRef.doc(canonical.id).update(canonical.toJSON());
        AppConfig.logger.i('  ✓ Merged interactions & metadata into canonical ${canonical.id}');
      }

      // 2. Delete duplicate document from releaseItems collection
      await _releaseItemsRef.doc(duplicate.id).delete();
      AppConfig.logger.i('  ✓ Deleted releaseItems/${duplicate.id}');

      // 3. Cascading cleanup in itemlists
      await _cleanupItemlists(duplicate.id, canonical.id);

      // 4. Cascading cleanup in users / profiles
      await _cleanupUsersAndProfiles(duplicate.id, canonical.id);

      // 5. Cascading cleanup in posts
      await _cleanupPosts(duplicate.id, canonical.id);

      // 6. Cascading cleanup in requests
      await _cleanupRequests(duplicate.id);

      // 7. Cascading cleanup in activityFeed
      await _cleanupActivityFeed(duplicate.id);

      // Invalidate memory cache
      AppReleaseItemFirestore.invalidateAllReleaseItemsCache();

      AppConfig.logger.i('✅ [Deduplication] Duplicate ${duplicate.id} fully purged and reconciled.');
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: 'ReleaseDeduplicationService.purgeDuplicate');
      return false;
    }
  }

  /// Removes [duplicateId] from all itemlists and cleans empty orphan itemlists.
  Future<void> _cleanupItemlists(String duplicateId, String canonicalId) async {
    try {
      final querySnapshot = await _itemlistsRef.get();
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final rawItems = data[AppFirestoreConstants.appReleaseItems] as List<dynamic>?;

        if (rawItems != null && rawItems.isNotEmpty) {
          final List<Map<String, dynamic>> filteredItems = [];
          bool foundDuplicate = false;

          for (final itemJson in rawItems) {
            if (itemJson is Map<String, dynamic>) {
              final id = itemJson['id'] as String? ?? '';
              if (id == duplicateId) {
                foundDuplicate = true;
              } else {
                filteredItems.add(itemJson);
              }
            }
          }

          if (foundDuplicate) {
            if (filteredItems.isEmpty) {
              // Itemlist was created solely for this duplicate; delete orphan itemlist
              await _itemlistsRef.doc(doc.id).delete();
              AppConfig.logger.i('  ✓ Deleted orphan itemlist/${doc.id}');
            } else {
              await _itemlistsRef.doc(doc.id).update({
                AppFirestoreConstants.appReleaseItems: filteredItems,
              });
              AppConfig.logger.i('  ✓ Removed duplicate from itemlist/${doc.id}');
            }
          }
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: '_cleanupItemlists');
    }
  }

  /// Removes [duplicateId] from user and profile references.
  Future<void> _cleanupUsersAndProfiles(String duplicateId, String canonicalId) async {
    try {
      // Clean users
      final userSnapshot = await _usersRef
          .where('releaseItemIds', arrayContains: duplicateId)
          .get();

      for (final doc in userSnapshot.docs) {
        await _usersRef.doc(doc.id).update({
          'releaseItemIds': FieldValue.arrayRemove([duplicateId]),
        });
        AppConfig.logger.i('  ✓ Removed $duplicateId from user/${doc.id}.releaseItemIds');
      }

      // Clean profiles (favoriteItems)
      final profileGroup = FirebaseFirestore.instance.collectionGroup(AppFirestoreCollectionConstants.profiles);
      final profileSnapshot = await profileGroup
          .where('favoriteItems', arrayContains: duplicateId)
          .get();

      for (final doc in profileSnapshot.docs) {
        await doc.reference.update({
          'favoriteItems': FieldValue.arrayRemove([duplicateId]),
        });
        // Ensure canonical is present
        await doc.reference.update({
          'favoriteItems': FieldValue.arrayUnion([canonicalId]),
        });
        AppConfig.logger.i('  ✓ Replaced $duplicateId with $canonicalId in profile/${doc.id}.favoriteItems');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: '_cleanupUsersAndProfiles');
    }
  }

  /// Removes redundant duplicate posts referencing [duplicateId].
  Future<void> _cleanupPosts(String duplicateId, String canonicalId) async {
    try {
      final duplicatePostsSnapshot = await _postsRef
          .where('referenceId', isEqualTo: duplicateId)
          .get();

      if (duplicatePostsSnapshot.docs.isEmpty) return;

      final canonicalPostsSnapshot = await _postsRef
          .where('referenceId', isEqualTo: canonicalId)
          .get();

      final hasCanonicalPost = canonicalPostsSnapshot.docs.isNotEmpty;

      for (final doc in duplicatePostsSnapshot.docs) {
        if (hasCanonicalPost) {
          // Already have a post for canonical; delete duplicate post
          await _postsRef.doc(doc.id).delete();
          AppConfig.logger.i('  ✓ Deleted redundant post/${doc.id} (ref: $duplicateId)');
        } else {
          // Repoint referenceId to canonical
          await _postsRef.doc(doc.id).update({'referenceId': canonicalId});
          AppConfig.logger.i('  ✓ Repointed post/${doc.id} to canonical $canonicalId');
        }
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: '_cleanupPosts');
    }
  }

  /// Deletes approval requests created for [duplicateId].
  Future<void> _cleanupRequests(String duplicateId) async {
    try {
      final reqSnapshot = await _requestsRef
          .where('positionRequestedId', isEqualTo: duplicateId)
          .get();

      for (final doc in reqSnapshot.docs) {
        await _requestsRef.doc(doc.id).delete();
        AppConfig.logger.i('  ✓ Deleted request/${doc.id} for duplicate $duplicateId');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: '_cleanupRequests');
    }
  }

  /// Deletes activity feed entries referencing [duplicateId].
  Future<void> _cleanupActivityFeed(String duplicateId) async {
    try {
      final feedSnapshot = await _activityFeedRef
          .where('referenceId', isEqualTo: duplicateId)
          .get();

      for (final doc in feedSnapshot.docs) {
        await _activityFeedRef.doc(doc.id).delete();
        AppConfig.logger.i('  ✓ Deleted activityFeed/${doc.id} for duplicate $duplicateId');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: '_cleanupActivityFeed');
    }
  }

  /// Scans all releases in Firestore, detects duplicates, and executes automated cleanup.
  /// Returns the number of purged duplicate items.
  Future<int> runAutomatedDeduplication({bool dryRun = false}) async {
    if (_isDeduplicating) {
      AppConfig.logger.d('[Deduplication] Deduplication process is already running, skipping.');
      return 0;
    }

    _isDeduplicating = true;
    int purgedCount = 0;

    try {
      AppConfig.logger.i('🔍 [Deduplication] Starting automated release deduplication audit...');

      final allItemsMap = await AppReleaseItemFirestore().retrieveAll(forceRefresh: true);
      final duplicateGroups = groupDuplicates(allItemsMap.values);

      if (duplicateGroups.isEmpty) {
        AppConfig.logger.i('✨ [Deduplication] No duplicate releases found in database.');
        return 0;
      }

      AppConfig.logger.w('⚠️ [Deduplication] Found ${duplicateGroups.length} duplicate release cluster(s)!');

      for (final entry in duplicateGroups.entries) {
        final key = entry.key;
        final duplicates = entry.value;

        AppConfig.logger.i('━━━ Cluster: "$key" (${duplicates.length} items) ━━━');
        for (final item in duplicates) {
          final score = calculateCompletenessScore(item);
          AppConfig.logger.d('  • ID: ${item.id} | Name: "${item.name}" | Score: $score | '
              'Img: ${item.imgUrl.isNotEmpty ? "OK" : "EMPTY"} | '
              'File: ${item.previewUrl.isNotEmpty ? "OK" : "EMPTY"} | '
              'Created: ${item.createdTime}');
        }

        final canonical = selectCanonicalItem(duplicates);
        AppConfig.logger.i('  ⭐ Designated Canonical: "${canonical.name}" (ID: ${canonical.id}) '
            'with score ${calculateCompletenessScore(canonical)}');

        for (final dup in duplicates) {
          if (dup.id == canonical.id) continue;

          if (dryRun) {
            AppConfig.logger.i('  [DRY RUN] Would purge duplicate ${dup.id}');
            purgedCount++;
          } else {
            final success = await purgeDuplicate(dup, canonical);
            if (success) purgedCount++;
          }
        }
      }

      AppConfig.logger.i('🏁 [Deduplication] Audit complete. Purged $purgedCount duplicate release(s).');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: 'runAutomatedDeduplication');
    } finally {
      _isDeduplicating = false;
    }

    return purgedCount;
  }
}
