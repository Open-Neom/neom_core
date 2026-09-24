import '../../app_config.dart';
import '../firestore/app_release_item_firestore.dart';
import '../firestore/public_catalog_read_policy.dart';

/// Answers whether an account owns any release item — the line between a
/// member whose paid time funds creators and an author whose time must not.
///
/// `AppUser.releaseItemIds` cannot answer it: publishing stopped adding to
/// that list, so it only knows about old releases. The catalog is asked
/// instead, by profile id (present in public projections) and by owner email
/// (absent from them), and the answer is cached per account so listening
/// sessions do not each cost a query.
class ReleaseOwnershipResolver {
  ReleaseOwnershipResolver({
    Future<bool> Function(String profileId)? ownsByProfileId,
    Future<bool> Function(String email)? ownsByEmail,
    DateTime Function()? now,
  })  : _ownsByProfileId = ownsByProfileId ?? _catalogOwnsByProfileId,
        _ownsByEmail = ownsByEmail ?? _catalogOwnsByEmail,
        _now = now ?? DateTime.now;

  final Future<bool> Function(String profileId) _ownsByProfileId;
  final Future<bool> Function(String email) _ownsByEmail;
  final DateTime Function() _now;

  /// How long an answer is trusted. A new author's first release is picked
  /// up after this at the latest, or at once through [invalidate].
  static const Duration cacheTtl = Duration(minutes: 30);

  static final Map<String, ({bool owns, DateTime at})> _cache = {};

  /// Forgets the cached answer for [email] — call it after a publish.
  static void invalidate(String email) => _cache.remove(email);

  static void clearCache() => _cache.clear();

  Future<bool> ownsAnyReleaseItem({
    required String email,
    Iterable<String> profileIds = const [],
    List<String>? legacyReleaseItemIds,
  }) async {
    if (legacyReleaseItemIds?.isNotEmpty ?? false) return true;
    final cached = _cache[email];
    if (cached != null && _now().difference(cached.at) < cacheTtl) {
      return cached.owns;
    }

    var owns = false;
    try {
      for (final id in profileIds.where((id) => id.isNotEmpty)) {
        if (await _ownsByProfileId(id)) {
          owns = true;
          break;
        }
      }
      if (!owns && email.isNotEmpty) owns = await _ownsByEmail(email);
    } catch (e) {
      // An unknown answer is not cached: the next session asks again.
      AppConfig.logger.w('Release ownership lookup failed for $email: $e');
      return false;
    }
    if (email.isNotEmpty) _cache[email] = (owns: owns, at: _now());
    return owns;
  }

  // Own queries rather than the catalog's retrieveBy* helpers: those swallow
  // errors and return empty, which would cache a failed lookup as "not an
  // author". Any status counts — owning an unpublished release is still
  // owning one.
  static Future<bool> _catalogOwnsByProfileId(String profileId) async {
    final snapshot = await PublicCatalogReadPolicy.query(
      AppReleaseItemFirestore().appReleaseItemReference,
    ).where('ownerProfileId', isEqualTo: profileId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> _catalogOwnsByEmail(String email) async {
    // Public projections carry no account email.
    if (PublicCatalogReadPolicy.enabled) return false;
    final snapshot = await AppReleaseItemFirestore()
        .appReleaseItemReference
        .where('ownerEmail', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
