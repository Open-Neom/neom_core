import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:neom_core/data/api/app_accounts.dart';
import 'package:neom_core/data/api/app_release_items.dart';

import '../app_config.dart';
import '../data/firestore/blog_entry_firestore.dart';
import '../data/firestore/collective_firestore.dart';
import '../data/firestore/core_firestore_guard.dart';
import '../data/firestore/event_firestore.dart';
import '../data/firestore/post_firestore.dart';

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
        final profile = await AppProfiles.directory.getBySlug(slug);
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
        final item = await AppReleaseItems.repository.getBySlug(slug);
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
      type: 'collective',
      priority: 3,
      resolve: (slug) async {
        final collective = await CollectiveFirestore().getBySlug(slug);
        if (collective != null && collective.id.isNotEmpty) {
          return SlugMatch(type: 'collective', id: collective.id, slug: slug, entity: collective);
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

  static final RegExp _unsafeSlugChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2069\uFEFF/\\?&#]',
  );
  static final RegExp _encodedSlugUnsafe = RegExp(
    r'%(?:00|2e|2f|5c|25|c2%[89][0-9a-f]|d8%9c|e2%80%(?:8[b-f]|a[8-e])|e2%81%a[0-9]|ef%bb%bf)',
    caseSensitive: false,
  );

  @visibleForTesting
  static String? normalizeSafeSlugInput(String? raw, {int maxLength = 128}) {
    if (raw == null ||
        _unsafeSlugChars.hasMatch(raw) ||
        _encodedSlugUnsafe.hasMatch(raw)) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.length > maxLength ||
        trimmed == '.' ||
        trimmed.contains('..') ||
        !CoreFirestoreGuard.isSafeDocId(trimmed)) {
      return null;
    }
    return trimmed;
  }

  /// Resolve a vanity slug — fires ALL queries in parallel,
  /// returns the highest-priority match.
  ///
  /// With 5 sequential queries each taking ~200ms, the old approach
  /// took up to 1s worst case. Parallel resolution completes in ~200ms.
  static Future<SlugMatch?> resolve(String slug) async {
    final safeSlug = normalizeSafeSlugInput(slug);
    if (safeSlug == null) return null;

    AppConfig.logger.d('SlugRouter: resolving "$safeSlug" across ${_routes.length} routes (parallel)');

    // Fire all queries simultaneously
    final futures = _routes.map((route) => route.resolve(safeSlug));
    final results = await Future.wait(futures);

    // Collect non-null matches
    final matches = <SlugMatch>[];
    for (int i = 0; i < results.length; i++) {
      if (results[i] != null) {
        matches.add(results[i]!);
      }
    }

    if (matches.isEmpty) {
      AppConfig.logger.d('SlugRouter: no match for "$safeSlug"');
      return null;
    }

    // Return highest priority (lowest number) match
    if (matches.length > 1) {
      AppConfig.logger.w('SlugRouter: ${matches.length} matches for "$safeSlug": '
          '${matches.map((m) => m.type).join(", ")}. Using highest priority.');
    }

    // matches are already ordered by _routes priority since we iterated in order
    final match = matches.first;
    AppConfig.logger.i('SlugRouter: resolved "$safeSlug" → ${match.type} (${match.id})');
    return match;
  }

  /// Resolve a profile by slug or ID — used for /@username or /u/{slug} URLs.
  static Future<SlugMatch?> resolveProfile(String slugOrId) async {
    final safeSlugOrId = normalizeSafeSlugInput(slugOrId);
    if (safeSlugOrId == null) return null;

    AppConfig.logger.d('SlugRouter: resolving profile "$safeSlugOrId"');
    final profile = await AppProfiles.directory.getBySlug(safeSlugOrId);
    if (profile != null && profile.id.isNotEmpty) {
      return SlugMatch(type: 'profile', id: profile.id, slug: safeSlugOrId, entity: profile);
    }

    // Fallback: try by profile document ID
    final profileById = await AppProfiles.repository.retrieve(safeSlugOrId);
    if (profileById.id.isNotEmpty) {
      return SlugMatch(type: 'profile', id: profileById.id, slug: profileById.slug, entity: profileById);
    }

    return null;
  }

  /// Resolve a prefixed blog slug/ID — tries slug first, then ID.
  static Future<SlugMatch?> resolveBlog(String slugOrId) async {
    final safeSlugOrId = normalizeSafeSlugInput(slugOrId);
    if (safeSlugOrId == null) return null;

    final entry = await BlogEntryFirestore().getBySlug(safeSlugOrId);
    if (entry != null && entry.id.isNotEmpty) {
      return SlugMatch(type: 'blog', id: entry.id, slug: safeSlugOrId, entity: entry);
    }

    // Fallback: try by ID
    final entryById = await BlogEntryFirestore().retrieve(safeSlugOrId);
    if (entryById.id.isNotEmpty) {
      return SlugMatch(type: 'blog', id: entryById.id, slug: '', entity: entryById);
    }

    return null;
  }

  /// Get all registered content types.
  static List<String> get registeredTypes => _routes.map((r) => r.type).toList();
}
