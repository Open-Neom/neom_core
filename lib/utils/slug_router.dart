import '../app_config.dart';
import '../data/firestore/app_release_item_firestore.dart';
import '../data/firestore/band_firestore.dart';
import '../data/firestore/blog_entry_firestore.dart';
import '../data/firestore/event_firestore.dart';
import '../data/firestore/post_firestore.dart';
import '../data/firestore/profile_firestore.dart';

/// Declarative slug route definition — inspired by go_router's GoRoute.
///
/// Each entry maps a content type to its Firestore resolution function
/// and navigation target. Routes are evaluated by priority (lower = higher).
class SlugRoute {
  final String type;
  final int priority;
  final Future<SlugMatch?> Function(String slug) resolve;

  const SlugRoute({
    required this.type,
    required this.priority,
    required this.resolve,
  });
}

/// Result of resolving a slug — type-safe like GoRouterState.
class SlugMatch {
  final String type;
  final String id;
  final String slug;
  final dynamic entity;

  const SlugMatch({
    required this.type,
    required this.id,
    required this.slug,
    this.entity,
  });

  @override
  String toString() => 'SlugMatch($type, id=$id, slug=$slug)';
}

/// Centralized slug resolution with parallel Firestore queries.
///
/// Inspired by go_router patterns:
/// - **Declarative registry**: routes defined once, not scattered if/else
/// - **Parallel resolution**: all queries fire simultaneously via Future.wait
/// - **Priority-based**: when multiple matches exist, highest priority wins
/// - **Single source of truth**: used by both SlugResolverPage and DeeplinkUtilities
class SlugRouter {

  SlugRouter._();

  /// The declarative route registry — ordered by priority.
  /// Priority 0 = highest (profile slugs win over everything).
  static final List<SlugRoute> _routes = [
    SlugRoute(
      type: 'profile',
      priority: 0,
      resolve: (slug) async {
        final profile = await ProfileFirestore().getBySlug(slug);
        if (profile != null && profile.id.isNotEmpty) {
          return SlugMatch(type: 'profile', id: profile.id, slug: slug, entity: profile);
        }
        return null;
      },
    ),
    SlugRoute(
      type: 'item',
      priority: 1,
      resolve: (slug) async {
        final item = await AppReleaseItemFirestore().getBySlug(slug);
        if (item != null && item.id.isNotEmpty) {
          return SlugMatch(type: 'item', id: item.id, slug: slug, entity: item);
        }
        return null;
      },
    ),
    SlugRoute(
      type: 'event',
      priority: 2,
      resolve: (slug) async {
        final event = await EventFirestore().getBySlug(slug);
        if (event != null && event.id.isNotEmpty) {
          return SlugMatch(type: 'event', id: event.id, slug: slug, entity: event);
        }
        return null;
      },
    ),
    SlugRoute(
      type: 'band',
      priority: 3,
      resolve: (slug) async {
        final band = await BandFirestore().getBySlug(slug);
        if (band != null && band.id.isNotEmpty) {
          return SlugMatch(type: 'band', id: band.id, slug: slug, entity: band);
        }
        return null;
      },
    ),
    SlugRoute(
      type: 'post',
      priority: 4,
      resolve: (slug) async {
        final post = await PostFirestore().getBySlug(slug);
        if (post != null && post.id.isNotEmpty) {
          return SlugMatch(type: 'post', id: post.id, slug: slug, entity: post);
        }
        return null;
      },
    ),
  ];

  /// Resolve a vanity slug — fires ALL queries in parallel,
  /// returns the highest-priority match.
  ///
  /// With 5 sequential queries each taking ~200ms, the old approach
  /// took up to 1s worst case. Parallel resolution completes in ~200ms.
  static Future<SlugMatch?> resolve(String slug) async {
    if (slug.isEmpty) return null;

    AppConfig.logger.d('SlugRouter: resolving "$slug" across ${_routes.length} routes (parallel)');

    // Fire all queries simultaneously
    final futures = _routes.map((route) => route.resolve(slug));
    final results = await Future.wait(futures);

    // Collect non-null matches
    final matches = <SlugMatch>[];
    for (int i = 0; i < results.length; i++) {
      if (results[i] != null) {
        matches.add(results[i]!);
      }
    }

    if (matches.isEmpty) {
      AppConfig.logger.d('SlugRouter: no match for "$slug"');
      return null;
    }

    // Return highest priority (lowest number) match
    if (matches.length > 1) {
      AppConfig.logger.w('SlugRouter: ${matches.length} matches for "$slug": '
          '${matches.map((m) => m.type).join(", ")}. Using highest priority.');
    }

    // matches are already ordered by _routes priority since we iterated in order
    final match = matches.first;
    AppConfig.logger.i('SlugRouter: resolved "$slug" → ${match.type} (${match.id})');
    return match;
  }

  /// Resolve a profile by slug — used for /p/{slug} short URLs.
  static Future<SlugMatch?> resolveProfile(String slug) async {
    if (slug.isEmpty) return null;

    AppConfig.logger.d('SlugRouter: resolving profile "$slug"');
    final profile = await ProfileFirestore().getBySlug(slug);
    if (profile != null && profile.id.isNotEmpty) {
      return SlugMatch(type: 'profile', id: profile.id, slug: slug, entity: profile);
    }
    return null;
  }

  /// Resolve a prefixed blog slug/ID — tries slug first, then ID.
  static Future<SlugMatch?> resolveBlog(String slugOrId) async {
    if (slugOrId.isEmpty) return null;

    final entry = await BlogEntryFirestore().getBySlug(slugOrId);
    if (entry != null && entry.id.isNotEmpty) {
      return SlugMatch(type: 'blog', id: entry.id, slug: slugOrId, entity: entry);
    }

    // Fallback: try by ID
    final entryById = await BlogEntryFirestore().retrieve(slugOrId);
    if (entryById.id.isNotEmpty) {
      return SlugMatch(type: 'blog', id: entryById.id, slug: '', entity: entryById);
    }

    return null;
  }

  /// Get all registered content types.
  static List<String> get registeredTypes => _routes.map((r) => r.type).toList();
}
