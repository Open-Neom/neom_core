import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/blog_entry.dart';
import '../../domain/repository/blog_entry_repository.dart';
import '../../utils/neom_error_logger.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'core_firestore_guard.dart';

/// Firestore implementation for BlogEntry operations.
/// Collection: /blog/{blogId}
class BlogEntryFirestore implements BlogEntryRepository {

  CollectionReference<Map<String, dynamic>> get blogReference =>
      FirebaseFirestore.instance.collection(
        AppFirestoreCollectionConstants.blog,
      );

  // Pagination cache
  DocumentSnapshot? _lastCommunityDocument;

  static List<BlogEntry> _cachedTimelineEntries = [];
  static DateTime? _lastTimelineEntriesFetchTime;
  static const Duration _timelineEntriesCacheTtl = Duration(minutes: 5);

  static void invalidateTimelineCache() {
    _cachedTimelineEntries.clear();
    _lastTimelineEntriesFetchTime = null;
  }

  /// Reset pagination cache.
  void resetPagination() {
    _lastCommunityDocument = null;
  }

  @override
  Future<String> insert(BlogEntry entry) async {
    AppConfig.logger.d("Insert BlogEntry");
    String entryId = "";
    try {
      // Auto-generate slug from title if empty
      if (entry.slug.isEmpty && entry.title.isNotEmpty) {
        final titleSlug = BlogEntry.generateSlug(entry.title);
        final existing = await getBySlug(titleSlug);
        if (existing == null) {
          entry.slug = titleSlug;
        } else {
          // Collision: prepend author name
          entry.slug = BlogEntry.generateSlug('${entry.profileName} ${entry.title}');
        }
      }

      DocumentReference documentReference = await blogReference.add(entry.toJSON());
      entryId = documentReference.id;
      AppConfig.logger.d("BlogEntry inserted with ID: $entryId");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'insert');
    }
    return entryId;
  }

  /// Retrieve a published BlogEntry by its URL slug.
  Future<BlogEntry?> getBySlug(String slug) async {
    final cleanSlug = slug.trim();
    if (cleanSlug.isEmpty) return null;
    try {
      final querySnapshot = await blogReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .where('slug', isEqualTo: cleanSlug)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        return entry;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getBySlug');
    }
    return null;
  }

  @override
  Future<bool> update(BlogEntry entry) async {
    final cleanId = entry.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Update BlogEntry: $cleanId");
    try {
      await blogReference.doc(cleanId).update(entry.toJSON());
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'update');
      return false;
    }
  }

  @override
  Future<bool> remove(String entryId) async {
    final cleanId = entryId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Remove BlogEntry: $cleanId");
    try {
      await blogReference.doc(cleanId).delete();
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'remove');
      return false;
    }
  }

  @override
  Future<BlogEntry> retrieve(String entryId) async {
    final cleanId = entryId.trim();
    BlogEntry entry = BlogEntry();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return entry;
    AppConfig.logger.d("Retrieve BlogEntry: $cleanId");
    try {
      DocumentSnapshot snapshot = await blogReference.doc(cleanId).get();
      if (snapshot.exists && snapshot.data() != null) {
        entry = BlogEntry.fromJSON(snapshot.data() as Map<String, dynamic>);
        entry.id = snapshot.id;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'retrieve');
    }
    return entry;
  }

  @override
  Future<List<BlogEntry>> getCommunityEntries({
    int limit = 1000,
    String? lastEntryId,
    String? authorId,
    String? searchQuery,
  }) async {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 500);
    AppConfig.logger.d("getCommunityEntries - limit: $safeLimit, authorId: $authorId");
    List<BlogEntry> entries = [];

    try {
      Query query = blogReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .orderBy('publishedTime', descending: true)
          .limit(safeLimit);

      // Filter by author if specified
      if (authorId != null && authorId.trim().isNotEmpty) {
        final cleanAuthorId = authorId.trim();
        if (!CoreFirestoreGuard.isSafeDocId(cleanAuthorId)) return entries;
        query = blogReference
            .where(AppFirestoreConstants.isDraft, isEqualTo: false)
            .where(AppFirestoreConstants.isHidden, isEqualTo: false)
            .where(AppFirestoreConstants.ownerId, isEqualTo: cleanAuthorId)
            .orderBy('publishedTime', descending: true)
            .limit(safeLimit);
      }

      // Pagination
      if (_lastCommunityDocument != null && lastEntryId == null) {
        query = query.startAfterDocument(_lastCommunityDocument!);
      } else if (lastEntryId != null) {
        // Reset pagination if specific ID provided
        _lastCommunityDocument = null;
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastCommunityDocument = snapshot.docs.last;
      }

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;

        // Client-side search filtering
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final queryLower = searchQuery.toLowerCase();
          final titleLower = entry.title.toLowerCase();
          final contentLower = entry.content.toLowerCase();
          final authorLower = entry.profileName.toLowerCase();

          if (!titleLower.contains(queryLower) &&
              !contentLower.contains(queryLower) &&
              !authorLower.contains(queryLower) &&
              !entry.hashtags.any((tag) => tag.toLowerCase().contains(queryLower))) {
            continue;
          }
        }

        entries.add(entry);
      }

      AppConfig.logger.d("Community entries found: ${entries.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getCommunityEntries');
    }

    return entries;
  }

  @override
  Future<List<BlogEntry>> getProfileEntries(String profileId, {bool includeDrafts = false}) async {
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return [];
    AppConfig.logger.d("getProfileEntries for: $cleanProfileId, includeDrafts: $includeDrafts");
    List<BlogEntry> entries = [];

    try {
      Query query;
      if (includeDrafts) {
        query = blogReference
            .where(AppFirestoreConstants.ownerId, isEqualTo: cleanProfileId)
            .orderBy(AppFirestoreConstants.modifiedTime, descending: true)
            .limit(200);
      } else {
        query = blogReference
            .where(AppFirestoreConstants.isDraft, isEqualTo: false)
            .where(AppFirestoreConstants.isHidden, isEqualTo: false)
            .where(AppFirestoreConstants.ownerId, isEqualTo: cleanProfileId)
            .orderBy('publishedTime', descending: true)
            .limit(200);
      }

      QuerySnapshot snapshot = await query.get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        entries.add(entry);
      }

      AppConfig.logger.d("Profile entries found: ${entries.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getProfileEntries');
    }

    return entries;
  }

  /// Quick check if a profile has any published blog entries.
  /// Uses a simple query with limit(1) to minimize reads.
  Future<bool> hasPublishedEntries(String profileId) async {
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return false;
    AppConfig.logger.d("hasPublishedEntries for: $cleanProfileId");
    try {
      QuerySnapshot snapshot = await blogReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .where(AppFirestoreConstants.ownerId, isEqualTo: cleanProfileId)
          .limit(1)
          .get();

      final hasEntries = snapshot.docs.isNotEmpty;
      AppConfig.logger.d("hasPublishedEntries: $hasEntries for $cleanProfileId");
      return hasEntries;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'hasPublishedEntries');
      return false;
    }
  }

  @override
  Future<List<BlogEntry>> getDrafts(String profileId) async {
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return [];
    AppConfig.logger.d("getDrafts for: $cleanProfileId");
    List<BlogEntry> drafts = [];

    try {
      QuerySnapshot snapshot = await blogReference
          .where(AppFirestoreConstants.ownerId, isEqualTo: cleanProfileId)
          .where(AppFirestoreConstants.isDraft, isEqualTo: true)
          .orderBy(AppFirestoreConstants.modifiedTime, descending: true)
          .limit(200)
          .get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        drafts.add(entry);
      }

      AppConfig.logger.d("Drafts found: ${drafts.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getDrafts');
    }

    return drafts;
  }

  @override
  Future<bool> publish(String entryId) async {
    final cleanId = entryId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Publish BlogEntry: $cleanId");
    try {
      await blogReference.doc(cleanId).update({
        AppFirestoreConstants.isDraft: false,
        'publishedTime': DateTime.now().millisecondsSinceEpoch,
        AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'publish');
      return false;
    }
  }

  @override
  Future<bool> unpublish(String entryId) async {
    final cleanId = entryId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.d("Unpublish BlogEntry: $cleanId");
    try {
      await blogReference.doc(cleanId).update({
        AppFirestoreConstants.isDraft: true,
        AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'unpublish');
      return false;
    }
  }

  @override
  Future<bool> addSavedByProfile(String entryId, String profileId) async {
    final cleanEntryId = entryId.trim();
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanEntryId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanProfileId)) {
      return false;
    }
    AppConfig.logger.d("Add bookmark for entry: $cleanEntryId by profile: $cleanProfileId");
    try {
      await blogReference.doc(cleanEntryId).update({
        AppFirestoreConstants.savedByProfiles: FieldValue.arrayUnion([cleanProfileId]),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'addSavedByProfile');
      return false;
    }
  }

  @override
  Future<bool> removeSavedByProfile(String entryId, String profileId) async {
    final cleanEntryId = entryId.trim();
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanEntryId) ||
        !CoreFirestoreGuard.isSafeDocId(cleanProfileId)) {
      return false;
    }
    AppConfig.logger.d("Remove bookmark for entry: $cleanEntryId by profile: $cleanProfileId");
    try {
      await blogReference.doc(cleanEntryId).update({
        AppFirestoreConstants.savedByProfiles: FieldValue.arrayRemove([cleanProfileId]),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'removeSavedByProfile');
      return false;
    }
  }

  @override
  Future<bool> incrementViewCount(String entryId) async {
    final cleanId = entryId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    AppConfig.logger.t("Increment view count for entry: $cleanId");
    try {
      await blogReference.doc(cleanId).update({
        'viewCount': FieldValue.increment(1),
      });
      return true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'incrementViewCount');
      return false;
    }
  }

  @override
  Future<List<BlogEntry>> getSavedEntries(String profileId) async {
    final cleanProfileId = profileId.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanProfileId)) return [];
    AppConfig.logger.d("getSavedEntries for: $cleanProfileId");
    List<BlogEntry> entries = [];

    try {
      QuerySnapshot snapshot = await blogReference
          .where(AppFirestoreConstants.savedByProfiles, arrayContains: cleanProfileId)
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .orderBy('publishedTime', descending: true)
          .limit(200)
          .get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        entries.add(entry);
      }

      AppConfig.logger.d("Saved entries found: ${entries.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getSavedEntries');
    }

    return entries;
  }

  /// Stream for real-time community entries updates.
  Stream<List<BlogEntry>> getCommunityEntriesStream({int limit = 50}) {
    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 50, maxLimit: 200);
    AppConfig.logger.t("Starting community entries stream");

    return blogReference
        .where(AppFirestoreConstants.isDraft, isEqualTo: false)
        .where(AppFirestoreConstants.isHidden, isEqualTo: false)
        .orderBy('publishedTime', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snapshot) {
      List<BlogEntry> entries = [];
      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        entries.add(entry);
      }
      AppConfig.logger.d("Community entries stream: ${entries.length}");
      return entries;
    });
  }

  /// Get latest published entries for timeline mixing.
  /// Returns entries as Posts for easy integration with existing timeline.
  /// Supports pagination via [lastPublishedTime].
  Future<List<BlogEntry>> getLatestEntriesForTimeline({
    int limit = 20,
    int? lastPublishedTime,
    bool forceRefresh = false,
  }) async {
    if (lastPublishedTime == null && !forceRefresh && _cachedTimelineEntries.isNotEmpty && _lastTimelineEntriesFetchTime != null &&
        DateTime.now().difference(_lastTimelineEntriesFetchTime!) < _timelineEntriesCacheTtl) {
      AppConfig.logger.d("getLatestEntriesForTimeline returned from in-memory cache: ${_cachedTimelineEntries.length} entries");
      return List<BlogEntry>.from(_cachedTimelineEntries);
    }

    final safeLimit = CoreFirestoreGuard.clampLimit(limit, defaultLimit: 20, maxLimit: 200);
    AppConfig.logger.d("getLatestEntriesForTimeline from Firestore - limit: $safeLimit");
    List<BlogEntry> entries = [];

    try {
      Query query = blogReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .orderBy('publishedTime', descending: true)
          .limit(safeLimit);

      // Pagination using timestamp
      if (lastPublishedTime != null) {
        query = query.startAfter([lastPublishedTime]);
      }

      QuerySnapshot snapshot = await query.get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        entries.add(entry);
      }

      if (lastPublishedTime == null) {
        _cachedTimelineEntries = List<BlogEntry>.from(entries);
        _lastTimelineEntriesFetchTime = DateTime.now();
      }

      AppConfig.logger.d("Latest entries for timeline: ${entries.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getLatestEntriesForTimeline');
    }

    return entries;
  }

  /// Get entries by IDs (for timeline mixing).
  Future<List<BlogEntry>> getEntriesByIds(List<String> ids) async {
    AppConfig.logger.d("getEntriesByIds: ${ids.length} IDs");
    List<BlogEntry> entries = [];

    final chunks = CoreFirestoreGuard.chunkValidIds(ids);
    if (chunks.isEmpty) return entries;

    try {
      for (final batch in chunks) {
        QuerySnapshot snapshot = await blogReference
            .where(FieldPath.documentId, whereIn: batch)
            .where(AppFirestoreConstants.isDraft, isEqualTo: false)
            .where(AppFirestoreConstants.isHidden, isEqualTo: false)
            .get();

        for (var doc in snapshot.docs) {
          BlogEntry entry = BlogEntry.fromJSON(doc.data());
          entry.id = doc.id;
          entries.add(entry);
        }
      }

      AppConfig.logger.d("Entries by IDs found: ${entries.length}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getEntriesByIds');
    }

    return entries;
  }

  // ============================================================
  // MIGRATION METHODS
  // ============================================================

  /// Migrate a single Post (blogEntry type) to BlogEntry.
  /// Returns the new BlogEntry ID if successful, empty string otherwise.
  Future<String> migrateFromPost(dynamic post, {String titleDivider = '|||TITLE|||'}) async {
    AppConfig.logger.d("Migrating Post ${post.id} to BlogEntry");
    try {
      BlogEntry entry = BlogEntry.fromLegacyPost(post, titleDivider: titleDivider);
      String newId = await insert(entry);

      if (newId.isNotEmpty) {
        AppConfig.logger.d("Migration successful: Post ${post.id} -> BlogEntry $newId");
      }

      return newId;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'migrateFromPost');
      return '';
    }
  }

  /// Batch migrate multiple Posts to BlogEntries.
  /// Returns a map of oldPostId -> newBlogEntryId.
  Future<Map<String, String>> batchMigrateFromPosts(
    List<dynamic> posts, {
    String titleDivider = '|||TITLE|||',
  }) async {
    AppConfig.logger.d("Batch migrating ${posts.length} Posts to BlogEntries");
    Map<String, String> migrationMap = {};

    for (var post in posts) {
      try {
        String newId = await migrateFromPost(post, titleDivider: titleDivider);
        if (newId.isNotEmpty) {
          migrationMap[post.id] = newId;
        }
      } catch (e, st) {
        NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'batchMigrateFromPosts');
      }
    }

    AppConfig.logger.d("Migration complete: ${migrationMap.length}/${posts.length} successful");
    return migrationMap;
  }

}
