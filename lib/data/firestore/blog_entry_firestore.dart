import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/blog_entry.dart';
import '../../domain/repository/blog_entry_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

/// Firestore implementation for BlogEntry operations.
/// Collection: /blog/{blogId}
class BlogEntryFirestore implements BlogEntryRepository {

  final blogReference = FirebaseFirestore.instance.collection(
    AppFirestoreCollectionConstants.blog,
  );

  // Pagination cache
  DocumentSnapshot? _lastCommunityDocument;
  DocumentSnapshot? _lastProfileDocument;

  /// Reset pagination cache.
  void resetPagination() {
    _lastCommunityDocument = null;
    _lastProfileDocument = null;
  }

  @override
  Future<String> insert(BlogEntry entry) async {
    AppConfig.logger.d("Insert BlogEntry");
    String entryId = "";
    try {
      DocumentReference documentReference = await blogReference.add(entry.toJSON());
      entryId = documentReference.id;
      AppConfig.logger.d("BlogEntry inserted with ID: $entryId");
    } catch (e) {
      AppConfig.logger.e("Error inserting BlogEntry: $e");
    }
    return entryId;
  }

  @override
  Future<bool> update(BlogEntry entry) async {
    AppConfig.logger.d("Update BlogEntry: ${entry.id}");
    try {
      await blogReference.doc(entry.id).update(entry.toJSON());
      return true;
    } catch (e) {
      AppConfig.logger.e("Error updating BlogEntry: $e");
      return false;
    }
  }

  @override
  Future<bool> remove(String entryId) async {
    AppConfig.logger.d("Remove BlogEntry: $entryId");
    try {
      await blogReference.doc(entryId).delete();
      return true;
    } catch (e) {
      AppConfig.logger.e("Error removing BlogEntry: $e");
      return false;
    }
  }

  @override
  Future<BlogEntry> retrieve(String entryId) async {
    AppConfig.logger.d("Retrieve BlogEntry: $entryId");
    BlogEntry entry = BlogEntry();
    try {
      DocumentSnapshot snapshot = await blogReference.doc(entryId).get();
      if (snapshot.exists && snapshot.data() != null) {
        entry = BlogEntry.fromJSON(snapshot.data() as Map<String, dynamic>);
        entry.id = snapshot.id;
      }
    } catch (e) {
      AppConfig.logger.e("Error retrieving BlogEntry: $e");
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
    AppConfig.logger.d("getCommunityEntries - limit: $limit, authorId: $authorId");
    List<BlogEntry> entries = [];

    try {
      Query query = blogReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .orderBy('publishedTime', descending: true)
          .limit(limit);

      // Filter by author if specified
      if (authorId != null && authorId.isNotEmpty) {
        query = blogReference
            .where(AppFirestoreConstants.isDraft, isEqualTo: false)
            .where(AppFirestoreConstants.isHidden, isEqualTo: false)
            .where(AppFirestoreConstants.ownerId, isEqualTo: authorId)
            .orderBy('publishedTime', descending: true)
            .limit(limit);
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
    } catch (e) {
      AppConfig.logger.e("Error getting community entries: $e");
    }

    return entries;
  }

  @override
  Future<List<BlogEntry>> getProfileEntries(String profileId, {bool includeDrafts = false}) async {
    AppConfig.logger.d("getProfileEntries for: $profileId, includeDrafts: $includeDrafts");
    List<BlogEntry> entries = [];

    try {
      Query query;
      if (includeDrafts) {
        // Get all entries for this profile
        query = blogReference
            .where(AppFirestoreConstants.ownerId, isEqualTo: profileId)
            .orderBy(AppFirestoreConstants.modifiedTime, descending: true);
      } else {
        // Get only published entries
        query = blogReference
            .where(AppFirestoreConstants.ownerId, isEqualTo: profileId)
            .where(AppFirestoreConstants.isDraft, isEqualTo: false)
            .orderBy('publishedTime', descending: true);
      }

      QuerySnapshot snapshot = await query.get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        entries.add(entry);
      }

      AppConfig.logger.d("Profile entries found: ${entries.length}");
    } catch (e) {
      AppConfig.logger.e("Error getting profile entries: $e");
    }

    return entries;
  }

  /// Quick check if a profile has any published blog entries.
  /// Uses a simple query with limit(1) to minimize reads.
  Future<bool> hasPublishedEntries(String profileId) async {
    AppConfig.logger.d("hasPublishedEntries for: $profileId");
    try {
      // Simple query: just check if ANY entry exists for this owner
      // This avoids the compound index requirement for ownerId + isDraft
      QuerySnapshot snapshot = await blogReference
          .where(AppFirestoreConstants.ownerId, isEqualTo: profileId)
          .limit(1)
          .get();

      final hasEntries = snapshot.docs.isNotEmpty;
      AppConfig.logger.d("hasPublishedEntries: $hasEntries for $profileId");
      return hasEntries;
    } catch (e) {
      AppConfig.logger.e("Error checking hasPublishedEntries: $e");
      return false;
    }
  }

  @override
  Future<List<BlogEntry>> getDrafts(String profileId) async {
    AppConfig.logger.d("getDrafts for: $profileId");
    List<BlogEntry> drafts = [];

    try {
      QuerySnapshot snapshot = await blogReference
          .where(AppFirestoreConstants.ownerId, isEqualTo: profileId)
          .where(AppFirestoreConstants.isDraft, isEqualTo: true)
          .orderBy(AppFirestoreConstants.modifiedTime, descending: true)
          .get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        drafts.add(entry);
      }

      AppConfig.logger.d("Drafts found: ${drafts.length}");
    } catch (e) {
      AppConfig.logger.e("Error getting drafts: $e");
    }

    return drafts;
  }

  @override
  Future<bool> publish(String entryId) async {
    AppConfig.logger.d("Publish BlogEntry: $entryId");
    try {
      await blogReference.doc(entryId).update({
        AppFirestoreConstants.isDraft: false,
        'publishedTime': DateTime.now().millisecondsSinceEpoch,
        AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      AppConfig.logger.e("Error publishing BlogEntry: $e");
      return false;
    }
  }

  @override
  Future<bool> unpublish(String entryId) async {
    AppConfig.logger.d("Unpublish BlogEntry: $entryId");
    try {
      await blogReference.doc(entryId).update({
        AppFirestoreConstants.isDraft: true,
        AppFirestoreConstants.modifiedTime: DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      AppConfig.logger.e("Error unpublishing BlogEntry: $e");
      return false;
    }
  }

  @override
  Future<bool> addSavedByProfile(String entryId, String profileId) async {
    AppConfig.logger.d("Add bookmark for entry: $entryId by profile: $profileId");
    try {
      await blogReference.doc(entryId).update({
        AppFirestoreConstants.savedByProfiles: FieldValue.arrayUnion([profileId]),
      });
      return true;
    } catch (e) {
      AppConfig.logger.e("Error adding bookmark: $e");
      return false;
    }
  }

  @override
  Future<bool> removeSavedByProfile(String entryId, String profileId) async {
    AppConfig.logger.d("Remove bookmark for entry: $entryId by profile: $profileId");
    try {
      await blogReference.doc(entryId).update({
        AppFirestoreConstants.savedByProfiles: FieldValue.arrayRemove([profileId]),
      });
      return true;
    } catch (e) {
      AppConfig.logger.e("Error removing bookmark: $e");
      return false;
    }
  }

  @override
  Future<bool> incrementViewCount(String entryId) async {
    AppConfig.logger.t("Increment view count for entry: $entryId");
    try {
      await blogReference.doc(entryId).update({
        'viewCount': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      AppConfig.logger.e("Error incrementing view count: $e");
      return false;
    }
  }

  @override
  Future<List<BlogEntry>> getSavedEntries(String profileId) async {
    AppConfig.logger.d("getSavedEntries for: $profileId");
    List<BlogEntry> entries = [];

    try {
      QuerySnapshot snapshot = await blogReference
          .where(AppFirestoreConstants.savedByProfiles, arrayContains: profileId)
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .orderBy('publishedTime', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        BlogEntry entry = BlogEntry.fromJSON(doc.data());
        entry.id = doc.id;
        entries.add(entry);
      }

      AppConfig.logger.d("Saved entries found: ${entries.length}");
    } catch (e) {
      AppConfig.logger.e("Error getting saved entries: $e");
    }

    return entries;
  }

  /// Stream for real-time community entries updates.
  Stream<List<BlogEntry>> getCommunityEntriesStream({int limit = 50}) {
    AppConfig.logger.t("Starting community entries stream");

    return blogReference
        .where(AppFirestoreConstants.isDraft, isEqualTo: false)
        .where(AppFirestoreConstants.isHidden, isEqualTo: false)
        .orderBy('publishedTime', descending: true)
        .limit(limit)
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
  }) async {
    AppConfig.logger.d("getLatestEntriesForTimeline - limit: $limit");
    List<BlogEntry> entries = [];

    try {
      Query query = blogReference
          .where(AppFirestoreConstants.isDraft, isEqualTo: false)
          .where(AppFirestoreConstants.isHidden, isEqualTo: false)
          .orderBy('publishedTime', descending: true)
          .limit(limit);

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

      AppConfig.logger.d("Latest entries for timeline: ${entries.length}");
    } catch (e) {
      AppConfig.logger.e("Error getting latest entries for timeline: $e");
    }

    return entries;
  }

  /// Get entries by IDs (for timeline mixing).
  Future<List<BlogEntry>> getEntriesByIds(List<String> ids) async {
    AppConfig.logger.d("getEntriesByIds: ${ids.length} IDs");
    List<BlogEntry> entries = [];

    if (ids.isEmpty) return entries;

    try {
      // Firestore limits whereIn to 10 items, so batch if needed
      for (var i = 0; i < ids.length; i += 10) {
        final batch = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);

        QuerySnapshot snapshot = await blogReference
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          BlogEntry entry = BlogEntry.fromJSON(doc.data());
          entry.id = doc.id;
          entries.add(entry);
        }
      }

      AppConfig.logger.d("Entries by IDs found: ${entries.length}");
    } catch (e) {
      AppConfig.logger.e("Error getting entries by IDs: $e");
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
    } catch (e) {
      AppConfig.logger.e("Error migrating Post to BlogEntry: $e");
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
      } catch (e) {
        AppConfig.logger.e("Error migrating Post ${post.id}: $e");
      }
    }

    AppConfig.logger.d("Migration complete: ${migrationMap.length}/${posts.length} successful");
    return migrationMap;
  }

}
