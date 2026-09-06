import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../utils/enums/app_in_use.dart';

/// Gigmeout catalogue reads always use server-created public projections.
/// Authentication is independent: own-account reads use their bounded account
/// repository, while catalogue writes remain disabled during recovery.
/// Other apps retain their existing repositories and authenticated writes.
abstract final class PublicCatalogReadPolicy {
  static bool get enabled =>
      usesPublicCatalog(app: AppConfig.instance.appInUse);

  /// The optional session argument remains source-compatible with existing
  /// callers. Logging in no longer changes Gigmeout's catalogue source.
  static bool usesPublicCatalog({
    required AppInUse app,
    bool? canPersistUserActivity,
  }) => app == AppInUse.g;

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
