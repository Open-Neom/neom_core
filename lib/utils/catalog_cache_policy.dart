import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Decides whether the persistent catalogue cache is safe for this session.
///
/// Hive boxes are shared by every session running on the same browser origin.
/// Anonymous sessions must therefore not restore a previous account's
/// catalogue. Firebase demo projects are also treated as isolated backends so
/// a local emulator run cannot consume or overwrite a production catalogue.
class CatalogCachePolicy {
  CatalogCachePolicy._();

  static const String firebaseDemoProjectPrefix = 'demo-';

  @visibleForTesting
  static bool isFirebaseDemoProject(String? projectId) {
    return projectId?.startsWith(firebaseDemoProjectPrefix) ?? false;
  }

  @visibleForTesting
  static bool shouldBypassPersistentCache({
    required bool hasAuthenticatedSession,
    String? firebaseProjectId,
  }) {
    return !hasAuthenticatedSession || isFirebaseDemoProject(firebaseProjectId);
  }

  static bool forCurrentSession({required bool hasAuthenticatedSession}) {
    String? projectId;
    try {
      if (Firebase.apps.isNotEmpty) {
        projectId = Firebase.app().options.projectId;
      }
    } catch (_) {
      // Firebase can be unavailable in unit tests or before app bootstrap.
      // The authenticated-session gate still protects anonymous transitions.
    }

    return shouldBypassPersistentCache(
      hasAuthenticatedSession: hasAuthenticatedSession,
      firebaseProjectId: projectId,
    );
  }
}
