import '../domain/model/app_media_item.dart';
import '../domain/model/app_release_item.dart';
import '../domain/model/external_item.dart';
import '../domain/model/post.dart';
import 'enums/app_in_use.dart';
import 'enums/post_type.dart';

/// Reversible, client-side availability policy shared by web and mobile.
///
/// This is not an authorization rule: records, ownership and purchases remain
/// intact. Apply it to discovery lists (including cached/embedded releases),
/// not to maintenance lookups or duplicate detection during an upload.
abstract final class ReleaseCatalogVisibility {
  static const Map<AppInUse, List<String>> _unavailableHostsByApp = {
    AppInUse.e: ['escritoresmxi.org'],
    AppInUse.g: ['gigmeout.io'],
  };

  /// Returns `true` when [value] points to a retired legacy domain (or any of
  /// its subdomains) for [app].
  static bool usesUnavailableHost(String? value, {required AppInUse app}) {
    final blockedDomains = _unavailableHostsByApp[app];
    if (blockedDomains == null || blockedDomains.isEmpty) return false;

    final url = value?.trim() ?? '';
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(
      url.contains('://') || url.startsWith('//') ? url : 'https://$url',
    );
    final host =
        uri?.host.toLowerCase().replaceFirst(RegExp(r'\.+$'), '') ?? '';
    if (host.isEmpty) return false;

    for (final domain in blockedDomains) {
      if (host == domain || host.endsWith('.$domain')) {
        return true;
      }
    }
    return false;
  }

  static bool isVisible(AppReleaseItem item, {required AppInUse app}) {
    if (!_unavailableHostsByApp.containsKey(app)) return true;

    // Legacy imports (e.g. WooCommerce on escritoresmxi.org or legacy Gigmeout
    // catalog on gigmeout.io) are also AppReleaseItems in Firestore. Their IDs
    // alone cannot distinguish them from migrated, working Firebase releases.
    // Check assets used by the cover, gallery, native/web reader and player.
    final assets = <String?>[
      item.previewUrl,
      item.webPreviewUrl,
      item.imgUrl,
      item.streamingUrl,
      ...?item.galleryUrls,
    ];
    if (assets.any((url) => usesUnavailableHost(url, app: app))) return false;

    // A migrated release may retain its old physical-shop link; that link is
    // not grounds to hide a usable digital release. Link-only legacy entries
    // are hidden.
    final hasDigitalFile =
        item.previewUrl.trim().isNotEmpty ||
        (item.streamingUrl?.trim().isNotEmpty ?? false);
    return hasDigitalFile || !usesUnavailableHost(item.externalUrl, app: app);
  }

  static bool isMediaItemVisible(AppMediaItem item, {required AppInUse app}) {
    if (!_unavailableHostsByApp.containsKey(app)) return true;

    final assets = <String?>[
      item.url,
      item.imgUrl,
      ...?item.galleryUrls,
      ...?item.allUrls,
    ];
    if (assets.any((url) => usesUnavailableHost(url, app: app))) return false;

    final hasStreamUrl = item.url.trim().isNotEmpty;
    return hasStreamUrl || !usesUnavailableHost(item.permaUrl, app: app);
  }

  static bool isExternalItemVisible(
    ExternalItem item, {
    required AppInUse app,
  }) {
    if (!_unavailableHostsByApp.containsKey(app)) return true;

    final assets = <String?>[
      item.url,
      item.imgUrl,
      ...?item.galleryUrls,
      ...?item.allUrls,
    ];
    if (assets.any((url) => usesUnavailableHost(url, app: app))) return false;

    final hasStreamUrl = item.url.trim().isNotEmpty;
    return hasStreamUrl || !usesUnavailableHost(item.permaUrl, app: app);
  }

  static bool isPostVisible(Post post, {required AppInUse app}) {
    if (!_unavailableHostsByApp.containsKey(app)) return true;

    if (usesUnavailableHost(post.mediaUrl, app: app) ||
        usesUnavailableHost(post.thumbnailUrl, app: app)) {
      return false;
    }

    if (post.type == PostType.releaseItem &&
        post.mediaUrl.trim().isEmpty &&
        usesUnavailableHost(post.externalUrl, app: app)) {
      return false;
    }

    return true;
  }
}
