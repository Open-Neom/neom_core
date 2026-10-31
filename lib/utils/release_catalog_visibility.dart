import '../domain/model/app_release_item.dart';
import 'enums/app_in_use.dart';

/// Reversible, client-side availability policy shared by web and mobile.
///
/// This is not an authorization rule: records, ownership and purchases remain
/// intact. Apply it to discovery lists (including cached/embedded releases),
/// not to maintenance lookups or duplicate detection during an upload.
abstract final class ReleaseCatalogVisibility {
  static bool isVisible(AppReleaseItem item, {required AppInUse app}) {
    if (app != AppInUse.e) return true;

    // Legacy WooCommerce imports are also AppReleaseItems in Firestore. Their
    // IDs alone cannot distinguish them from migrated, working releases.
    // Check assets used by the cover, native reader and web reader instead.
    final assets = [
      item.previewUrl,
      item.webPreviewUrl,
      item.imgUrl,
      item.streamingUrl,
    ];
    if (assets.any(_usesUnavailableHost)) return false;

    // A migrated PDF may retain its old physical-shop link; that link is not
    // grounds to hide a usable digital release. Link-only legacy entries are.
    final hasDigitalFile =
        item.previewUrl.trim().isNotEmpty ||
        (item.streamingUrl?.trim().isNotEmpty ?? false);
    return hasDigitalFile || !_usesUnavailableHost(item.externalUrl);
  }

  static bool _usesUnavailableHost(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(
      url.contains('://') || url.startsWith('//') ? url : 'https://$url',
    );
    final host =
        uri?.host.toLowerCase().replaceFirst(RegExp(r'\.+$'), '') ?? '';
    return host == 'escritoresmxi.org' || host.endsWith('.escritoresmxi.org');
  }
}
