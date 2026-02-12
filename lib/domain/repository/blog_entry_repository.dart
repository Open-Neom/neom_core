import '../model/blog_entry.dart';

/// Repository interface for BlogEntry operations.
abstract class BlogEntryRepository {

  /// Insert a new blog entry.
  Future<String> insert(BlogEntry entry);

  /// Update an existing blog entry.
  Future<bool> update(BlogEntry entry);

  /// Remove a blog entry.
  Future<bool> remove(String entryId);

  /// Retrieve a single blog entry by ID.
  Future<BlogEntry> retrieve(String entryId);

  /// Get all published blog entries for the community feed.
  Future<List<BlogEntry>> getCommunityEntries({
    int limit = 20,
    String? lastEntryId,
    String? authorId,
    String? searchQuery,
  });

  /// Get blog entries for a specific profile.
  Future<List<BlogEntry>> getProfileEntries(String profileId, {bool includeDrafts = false});

  /// Get draft entries for a specific profile.
  Future<List<BlogEntry>> getDrafts(String profileId);

  /// Publish a draft entry.
  Future<bool> publish(String entryId);

  /// Unpublish an entry (convert back to draft).
  Future<bool> unpublish(String entryId);

  /// Add a profile to savedByProfiles (bookmark).
  Future<bool> addSavedByProfile(String entryId, String profileId);

  /// Remove a profile from savedByProfiles (unbookmark).
  Future<bool> removeSavedByProfile(String entryId, String profileId);

  /// Increment view count.
  Future<bool> incrementViewCount(String entryId);

  /// Get entries saved by a profile.
  Future<List<BlogEntry>> getSavedEntries(String profileId);

}
