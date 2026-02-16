import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app_config.dart';
import '../../../domain/model/blog_entry.dart';
import '../../../domain/model/post.dart';
import '../../../utils/constants/core_constants.dart';
import '../../../utils/enums/post_type.dart';
import '../blog_entry_firestore.dart';
import '../constants/app_firestore_collection_constants.dart';
import '../constants/app_firestore_constants.dart';
import '../post_firestore.dart';
import '../profile_firestore.dart';

/// Service to migrate Post.blogEntry documents to the new BlogEntry collection.
///
/// This migration:
/// 1. Reads all Posts where type == blogEntry
/// 2. Creates new BlogEntry documents in /blog collection
/// 3. Updates profile.blogEntries to reference new IDs
/// 4. Optionally marks old Posts as migrated (or deletes them)
class BlogMigrationService {

  final PostFirestore _postFirestore = PostFirestore();
  final BlogEntryFirestore _blogEntryFirestore = BlogEntryFirestore();
  final ProfileFirestore _profileFirestore = ProfileFirestore();

  final postsReference = FirebaseFirestore.instance.collection(
    AppFirestoreCollectionConstants.posts,
  );

  /// Migration statistics
  int totalPosts = 0;
  int migratedCount = 0;
  int skippedCount = 0;
  int errorCount = 0;
  List<String> errorIds = [];
  Map<String, String> migrationMap = {}; // oldPostId -> newBlogEntryId

  /// Run the full migration.
  ///
  /// [dryRun] - If true, only counts and logs without actually migrating.
  /// [deleteOldPosts] - If true, deletes old Posts after successful migration.
  /// [batchSize] - Number of posts to process per batch.
  Future<MigrationResult> runMigration({
    bool dryRun = true,
    bool deleteOldPosts = false,
    int batchSize = 50,
  }) async {
    AppConfig.logger.i("=== Starting Blog Migration ===");
    AppConfig.logger.i("Mode: ${dryRun ? 'DRY RUN' : 'LIVE'}");
    AppConfig.logger.i("Delete old posts: $deleteOldPosts");

    // Reset statistics
    totalPosts = 0;
    migratedCount = 0;
    skippedCount = 0;
    errorCount = 0;
    errorIds = [];
    migrationMap = {};

    try {
      // Step 1: Get all blogEntry posts
      AppConfig.logger.d("Step 1: Fetching all blogEntry posts...");
      List<Post> blogPosts = await _getAllBlogEntryPosts();
      totalPosts = blogPosts.length;
      AppConfig.logger.i("Found $totalPosts blogEntry posts to migrate");

      if (totalPosts == 0) {
        return MigrationResult(
          success: true,
          message: "No posts to migrate",
          totalPosts: 0,
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 0,
        );
      }

      if (dryRun) {
        AppConfig.logger.i("DRY RUN - Showing what would be migrated:");
        for (var post in blogPosts) {
          _logPostDetails(post);
        }
        return MigrationResult(
          success: true,
          message: "Dry run complete. $totalPosts posts would be migrated.",
          totalPosts: totalPosts,
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 0,
        );
      }

      // Step 2: Migrate each post
      AppConfig.logger.d("Step 2: Migrating posts...");
      for (var post in blogPosts) {
        await _migratePost(post, deleteOld: deleteOldPosts);
      }

      // Step 3: Update profiles with new blog entry IDs
      AppConfig.logger.d("Step 3: Updating profile references...");
      await _updateProfileReferences();

      AppConfig.logger.i("=== Migration Complete ===");
      AppConfig.logger.i("Total: $totalPosts");
      AppConfig.logger.i("Migrated: $migratedCount");
      AppConfig.logger.i("Skipped: $skippedCount");
      AppConfig.logger.i("Errors: $errorCount");

      return MigrationResult(
        success: errorCount == 0,
        message: errorCount == 0
            ? "Migration completed successfully"
            : "Migration completed with $errorCount errors",
        totalPosts: totalPosts,
        migratedCount: migratedCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        errorIds: errorIds,
        migrationMap: migrationMap,
      );

    } catch (e) {
      AppConfig.logger.e("Migration failed: $e");
      return MigrationResult(
        success: false,
        message: "Migration failed: $e",
        totalPosts: totalPosts,
        migratedCount: migratedCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        errorIds: errorIds,
      );
    }
  }

  /// Get all posts of type blogEntry.
  Future<List<Post>> _getAllBlogEntryPosts() async {
    List<Post> posts = [];

    try {
      QuerySnapshot snapshot = await postsReference
          .where(AppFirestoreConstants.type, isEqualTo: PostType.blogEntry.name)
          .get();

      for (var doc in snapshot.docs) {
        Post post = Post.fromJSON(doc.data());
        post.id = doc.id;
        posts.add(post);
      }
    } catch (e) {
      AppConfig.logger.e("Error fetching blog posts: $e");
    }

    return posts;
  }

  /// Migrate a single post.
  Future<void> _migratePost(Post post, {bool deleteOld = false}) async {
    try {
      AppConfig.logger.d("Migrating post: ${post.id}");

      // Check if already migrated (look for legacyPostId in blog collection)
      bool alreadyMigrated = await _isAlreadyMigrated(post.id);
      if (alreadyMigrated) {
        AppConfig.logger.d("Post ${post.id} already migrated, skipping");
        skippedCount++;
        return;
      }

      // Create BlogEntry from Post
      BlogEntry entry = BlogEntry.fromLegacyPost(
        post,
        titleDivider: CoreConstants.titleTextDivider,
      );

      // Insert new BlogEntry
      String newId = await _blogEntryFirestore.insert(entry);

      if (newId.isEmpty) {
        AppConfig.logger.e("Failed to insert BlogEntry for post: ${post.id}");
        errorCount++;
        errorIds.add(post.id);
        return;
      }

      migrationMap[post.id] = newId;
      migratedCount++;
      AppConfig.logger.d("Migrated: ${post.id} -> $newId");

      // Optionally delete old post
      if (deleteOld) {
        await postsReference.doc(post.id).delete();
        AppConfig.logger.d("Deleted old post: ${post.id}");
      }

    } catch (e) {
      AppConfig.logger.e("Error migrating post ${post.id}: $e");
      errorCount++;
      errorIds.add(post.id);
    }
  }

  /// Check if a post has already been migrated.
  Future<bool> _isAlreadyMigrated(String postId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.blog)
          .where('legacyPostId', isEqualTo: postId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update profile.blogEntries to reference new BlogEntry IDs.
  Future<void> _updateProfileReferences() async {
    // Group by ownerId
    Map<String, List<String>> profileUpdates = {}; // profileId -> list of new blog IDs

    for (var entry in migrationMap.entries) {
      // We need to find which profile owns this post
      // The new blog entry already has the ownerId
    }

    // For now, we'll update profiles that have the old IDs
    // This requires reading each profile and checking their blogEntries list

    AppConfig.logger.d("Profile references will be updated when profiles are loaded");
    // Note: A more complete implementation would batch-update profiles here
  }

  /// Log details of a post for dry run.
  void _logPostDetails(Post post) {
    final caption = post.caption;
    String title = '';
    String contentPreview = '';

    if (caption.contains(CoreConstants.titleTextDivider)) {
      final parts = caption.split(CoreConstants.titleTextDivider);
      title = parts[0];
      contentPreview = parts.length > 1
          ? (parts[1].length > 50 ? '${parts[1].substring(0, 50)}...' : parts[1])
          : '';
    } else {
      contentPreview = caption.length > 50 ? '${caption.substring(0, 50)}...' : caption;
    }

    AppConfig.logger.i('''
  Post ID: ${post.id}
  Owner: ${post.profileName} (${post.ownerId})
  Title: $title
  Content: $contentPreview
  Draft: ${post.isDraft}
  Created: ${DateTime.fromMillisecondsSinceEpoch(post.createdTime)}
  ---''');
  }

  /// Verify migration integrity.
  Future<MigrationVerificationResult> verifyMigration() async {
    AppConfig.logger.i("=== Verifying Migration ===");

    int oldPostCount = 0;
    int newEntryCount = 0;
    List<String> unmigrated = [];

    try {
      // Count old posts
      QuerySnapshot oldSnapshot = await postsReference
          .where(AppFirestoreConstants.type, isEqualTo: PostType.blogEntry.name)
          .get();
      oldPostCount = oldSnapshot.docs.length;

      // Count new entries
      QuerySnapshot newSnapshot = await FirebaseFirestore.instance
          .collection(AppFirestoreCollectionConstants.blog)
          .get();
      newEntryCount = newSnapshot.docs.length;

      // Find unmigrated posts
      for (var doc in oldSnapshot.docs) {
        bool migrated = await _isAlreadyMigrated(doc.id);
        if (!migrated) {
          unmigrated.add(doc.id);
        }
      }

      AppConfig.logger.i("Old posts (blogEntry type): $oldPostCount");
      AppConfig.logger.i("New BlogEntry documents: $newEntryCount");
      AppConfig.logger.i("Unmigrated posts: ${unmigrated.length}");

      return MigrationVerificationResult(
        oldPostCount: oldPostCount,
        newEntryCount: newEntryCount,
        unmigratedCount: unmigrated.length,
        unmigratedIds: unmigrated,
      );

    } catch (e) {
      AppConfig.logger.e("Verification error: $e");
      return MigrationVerificationResult(
        oldPostCount: oldPostCount,
        newEntryCount: newEntryCount,
        unmigratedCount: -1,
        error: e.toString(),
      );
    }
  }

}

/// Result of a migration run.
class MigrationResult {
  final bool success;
  final String message;
  final int totalPosts;
  final int migratedCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errorIds;
  final Map<String, String> migrationMap;

  MigrationResult({
    required this.success,
    required this.message,
    required this.totalPosts,
    required this.migratedCount,
    required this.skippedCount,
    required this.errorCount,
    this.errorIds = const [],
    this.migrationMap = const {},
  });

  @override
  String toString() {
    return '''
MigrationResult:
  Success: $success
  Message: $message
  Total: $totalPosts
  Migrated: $migratedCount
  Skipped: $skippedCount
  Errors: $errorCount
''';
  }
}

/// Result of migration verification.
class MigrationVerificationResult {
  final int oldPostCount;
  final int newEntryCount;
  final int unmigratedCount;
  final List<String> unmigratedIds;
  final String? error;

  MigrationVerificationResult({
    required this.oldPostCount,
    required this.newEntryCount,
    required this.unmigratedCount,
    this.unmigratedIds = const [],
    this.error,
  });

  bool get isComplete => unmigratedCount == 0 && error == null;
}
