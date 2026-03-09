import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app_config.dart';
import '../../../domain/model/app_profile.dart';
import '../../../domain/model/app_release_item.dart';
import '../../../domain/model/band.dart';
import '../../../domain/model/blog_entry.dart';
import '../../../domain/model/event.dart';
import '../../../domain/model/post.dart';
import '../constants/app_firestore_collection_constants.dart';

/// Backfill service to populate the `slug` field on existing Firestore documents.
///
/// Supports 6 collections: profiles, appReleaseItems, blog, events, bands, posts.
/// Uses a local Set for collision detection (no per-doc queries).
/// WriteBatch commits every 500 documents.
class SlugMigrationService {

  static const int _batchLimit = 500;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Per-collection statistics from the last run.
  Map<String, SlugMigrationStats> collectionStats = {};

  /// All supported collections and their config.
  static final List<_CollectionConfig> _collections = [
    _CollectionConfig(
      name: AppFirestoreCollectionConstants.profiles,
      label: 'Profiles',
      sourceField: 'name',
      generateSlug: AppProfile.generateSlug,
      fallbackFields: [],
    ),
    _CollectionConfig(
      name: AppFirestoreCollectionConstants.appReleaseItems,
      label: 'Releases',
      sourceField: 'name',
      generateSlug: AppReleaseItem.generateSlug,
      fallbackFields: ['ownerName'],
    ),
    _CollectionConfig(
      name: AppFirestoreCollectionConstants.blog,
      label: 'Blog',
      sourceField: 'title',
      generateSlug: BlogEntry.generateSlug,
      fallbackFields: ['profileName'],
    ),
    _CollectionConfig(
      name: AppFirestoreCollectionConstants.events,
      label: 'Events',
      sourceField: 'name',
      generateSlug: Event.generateSlug,
      fallbackFields: ['ownerName'],
    ),
    _CollectionConfig(
      name: AppFirestoreCollectionConstants.bands,
      label: 'Bands',
      sourceField: 'name',
      generateSlug: Band.generateSlug,
      fallbackFields: ['email'],
    ),
    _CollectionConfig(
      name: AppFirestoreCollectionConstants.posts,
      label: 'Posts',
      sourceField: 'caption',
      generateSlug: Post.generateSlug,
      fallbackFields: ['profileName'],
    ),
  ];

  /// Migrate all 6 collections.
  ///
  /// [onProgress] is called after each collection completes, enabling
  /// real-time UI updates (inspired by go_router's NavigatorObserver pattern).
  Future<Map<String, SlugMigrationStats>> migrateAll({
    bool dryRun = true,
    void Function(SlugMigrationProgress)? onProgress,
  }) async {
    AppConfig.logger.i('=== Slug Migration — ${dryRun ? "DRY RUN" : "LIVE"} ===');
    collectionStats = {};

    for (int i = 0; i < _collections.length; i++) {
      final config = _collections[i];
      onProgress?.call(SlugMigrationProgress(
        currentCollection: config.label,
        collectionIndex: i,
        totalCollections: _collections.length,
        phase: SlugMigrationPhase.started,
      ));

      final stats = await migrateCollection(config.name, dryRun: dryRun);
      collectionStats[config.name] = stats;

      onProgress?.call(SlugMigrationProgress(
        currentCollection: config.label,
        collectionIndex: i + 1,
        totalCollections: _collections.length,
        phase: SlugMigrationPhase.collectionDone,
        stats: stats,
      ));
    }

    onProgress?.call(SlugMigrationProgress(
      currentCollection: '',
      collectionIndex: _collections.length,
      totalCollections: _collections.length,
      phase: SlugMigrationPhase.allDone,
    ));

    AppConfig.logger.i('=== Slug Migration Complete ===');
    for (final entry in collectionStats.entries) {
      AppConfig.logger.i('  ${entry.key}: ${entry.value}');
    }

    return collectionStats;
  }

  /// Migrate a single collection by Firestore collection name.
  Future<SlugMigrationStats> migrateCollection(String collection, {bool dryRun = true}) async {
    final config = _collections.firstWhere(
      (c) => c.name == collection,
      orElse: () => throw ArgumentError('Unknown collection: $collection'),
    );

    AppConfig.logger.i('Migrating ${config.label} (${config.name})...');
    final stats = SlugMigrationStats(collection: config.label);

    try {
      // 1. Read all docs
      final snapshot = await _firestore.collection(config.name).get();
      stats.total = snapshot.docs.length;

      // 2. Build set of existing slugs
      final Set<String> usedSlugs = {};
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> needSlug = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final existingSlug = (data['slug'] as String?) ?? '';
        if (existingSlug.isNotEmpty) {
          usedSlugs.add(existingSlug);
          stats.alreadyHaveSlug++;
        } else {
          needSlug.add(doc);
        }
      }

      AppConfig.logger.d('  Total: ${stats.total}, already have slug: ${stats.alreadyHaveSlug}, need slug: ${needSlug.length}');

      if (needSlug.isEmpty) {
        AppConfig.logger.i('  All docs already have slugs — skipping.');
        return stats;
      }

      // 3. Generate slugs and batch-update
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in needSlug) {
        final data = doc.data();
        final sourceValue = data[config.sourceField] as String? ?? '';

        if (sourceValue.isEmpty) {
          stats.errors++;
          AppConfig.logger.w('  Doc ${doc.id} has empty ${config.sourceField} — skipping.');
          continue;
        }

        // Generate primary slug
        String slug = config.generateSlug(sourceValue);

        if (slug.isEmpty) {
          stats.errors++;
          AppConfig.logger.w('  Doc ${doc.id} generated empty slug from "$sourceValue" — skipping.');
          continue;
        }

        // Check collision
        if (usedSlugs.contains(slug)) {
          stats.collisions++;
          // Try fallback: combine fallback field + source
          String fallbackSlug = '';
          for (final fallbackField in config.fallbackFields) {
            final fallbackValue = data[fallbackField] as String? ?? '';
            if (fallbackValue.isNotEmpty) {
              // For email field, take prefix before @
              final prefix = fallbackField == 'email'
                  ? fallbackValue.split('@').first
                  : fallbackValue;
              fallbackSlug = config.generateSlug('$prefix $sourceValue');
              break;
            }
          }

          if (fallbackSlug.isNotEmpty && !usedSlugs.contains(fallbackSlug)) {
            slug = fallbackSlug;
          } else {
            // Append numeric suffix
            int suffix = 2;
            while (usedSlugs.contains('$slug-$suffix')) {
              suffix++;
            }
            slug = '$slug-$suffix';
          }
        }

        usedSlugs.add(slug);

        if (!dryRun) {
          batch.update(doc.reference, {'slug': slug});
          batchCount++;

          if (batchCount >= _batchLimit) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
            AppConfig.logger.d('  Committed batch of $_batchLimit');
          }
        }

        stats.migrated++;
      }

      // Commit remaining
      if (!dryRun && batchCount > 0) {
        await batch.commit();
        AppConfig.logger.d('  Committed final batch of $batchCount');
      }

      AppConfig.logger.i('  ${config.label}: ${stats.migrated} migrated, ${stats.collisions} collisions, ${stats.errors} errors');

    } catch (e) {
      AppConfig.logger.e('Error migrating ${config.name}: $e');
      stats.errors++;
    }

    return stats;
  }

  /// Verify that all docs in all collections have a non-empty slug.
  Future<Map<String, SlugVerificationResult>> verifyAll() async {
    final results = <String, SlugVerificationResult>{};

    for (final config in _collections) {
      results[config.name] = await verifyCollection(config.name);
    }

    return results;
  }

  /// Verify a single collection.
  Future<SlugVerificationResult> verifyCollection(String collection) async {
    final config = _collections.firstWhere(
      (c) => c.name == collection,
      orElse: () => throw ArgumentError('Unknown collection: $collection'),
    );

    int total = 0;
    int withSlug = 0;
    int withoutSlug = 0;

    try {
      final snapshot = await _firestore.collection(config.name).get();
      total = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final slug = doc.data()['slug'] as String? ?? '';
        if (slug.isNotEmpty) {
          withSlug++;
        } else {
          withoutSlug++;
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error verifying ${config.name}: $e');
    }

    return SlugVerificationResult(
      collection: config.label,
      total: total,
      withSlug: withSlug,
      withoutSlug: withoutSlug,
    );
  }

  /// Get all collection labels.
  static List<String> get collectionNames =>
      _collections.map((c) => c.name).toList();

  /// Get label for a collection.
  static String labelFor(String collection) =>
      _collections.firstWhere((c) => c.name == collection).label;
}

/// Internal config for each collection.
class _CollectionConfig {
  final String name;
  final String label;
  final String sourceField;
  final String Function(String) generateSlug;
  final List<String> fallbackFields;

  const _CollectionConfig({
    required this.name,
    required this.label,
    required this.sourceField,
    required this.generateSlug,
    required this.fallbackFields,
  });
}

/// Statistics for a single collection migration.
class SlugMigrationStats {
  final String collection;
  int total;
  int alreadyHaveSlug;
  int migrated;
  int collisions;
  int errors;

  SlugMigrationStats({
    required this.collection,
    this.total = 0,
    this.alreadyHaveSlug = 0,
    this.migrated = 0,
    this.collisions = 0,
    this.errors = 0,
  });

  @override
  String toString() =>
      '$collection — total: $total, existing: $alreadyHaveSlug, migrated: $migrated, collisions: $collisions, errors: $errors';
}

/// Result of verifying slug coverage for a collection.
class SlugVerificationResult {
  final String collection;
  final int total;
  final int withSlug;
  final int withoutSlug;

  const SlugVerificationResult({
    required this.collection,
    required this.total,
    required this.withSlug,
    required this.withoutSlug,
  });

  bool get isComplete => withoutSlug == 0;
}

/// Phase of migration progress.
enum SlugMigrationPhase { started, collectionDone, allDone }

/// Progress event emitted during migration — like go_router's NavigatorObserver.
class SlugMigrationProgress {
  final String currentCollection;
  final int collectionIndex;
  final int totalCollections;
  final SlugMigrationPhase phase;
  final SlugMigrationStats? stats;

  const SlugMigrationProgress({
    required this.currentCollection,
    required this.collectionIndex,
    required this.totalCollections,
    required this.phase,
    this.stats,
  });

  double get progress => totalCollections > 0 ? collectionIndex / totalCollections : 0;
}
