import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../app_properties.dart';
import '../../data_backend_policy.dart';
import '../../utils/enums/app_in_use.dart';

/// Controls whether Gigmeout Firestore reads/writes are restricted to
/// read-only `public*` projection collections (`dataBackend.enabled: true`
/// fallback mode) or connected directly to live Firebase collections
/// (`dataBackend.enabled: false` — full Firebase mode).
abstract final class PublicCatalogReadPolicy {
  static bool get enabled =>
      usesPublicCatalog(app: AppConfig.instance.appInUse);

  /// Public catalogue reads do not imply unmetered continuous playback:
  /// Gigmeout (`AppInUse.g`) enforces its timed free window (`300s` guest /
  /// `3000s` registered free user) and unlocks uninterrupted listening via
  /// the Gig Music (`$80 MXN/mes`) subscription.
  static bool get unmeteredPlayback => false;

  /// In Firebase mode (`dataBackend.enabled == false`), Gigmeout reads and
  /// writes the live Firebase collections (`appReleaseItems`, `itemlists`,
  /// `posts`, `profiles`), while guest privacy projections remain enforced per
  /// model. When `dataBackend.enabled` is `true` (own-server mode) or
  /// `dataBackend.publicCatalogOnly` is `true`, Firestore fallback stays
  /// restricted to read-only `public*` projections.
  static bool usesPublicCatalog({
    required AppInUse app,
    bool? canPersistUserActivity,
    dynamic properties,
  }) {
    if (app != AppInUse.g) return false;
    final props = properties ?? AppProperties.appProperties;
    final raw = props is Map ? props['dataBackend'] : null;
    if (raw is Map && raw['publicCatalogOnly'] is bool) {
      return raw['publicCatalogOnly'] as bool;
    }
    return DataBackendPolicy.isEnabledFor(app, props);
  }

  static bool get canWriteLegacyCatalog =>
      !enabled && AppConfig.instance.canPersistUserActivity;

  static const collections = <String, String>{
    'profiles': 'publicProfiles',
    'posts': 'publicPosts',
    'appReleaseItems': 'publicAppReleaseItems',
    'appMediaItems': 'publicAppMediaItems',
    'itemlists': 'publicItemlists',
  };

  static CollectionReference<Map<String, dynamic>> collection(
    FirebaseFirestore firestore,
    String legacyName,
  ) => firestore.collection(enabled ? collections[legacyName]! : legacyName);

  static Query<Map<String, dynamic>> query(
    CollectionReference<Map<String, dynamic>> collection,
  ) => enabled
      ? collection
            .where('visibility', isEqualTo: 'public')
            .where('schemaVersion', isEqualTo: 1)
      : collection;

  static bool accepts(Map<String, dynamic>? data) =>
      data != null &&
      (!enabled ||
          (data['visibility'] == 'public' && data['schemaVersion'] == 1));
}
