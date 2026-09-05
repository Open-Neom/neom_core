import 'package:firebase_core/firebase_core.dart';

import '../cloud_endpoint_policy.dart';

/// Prevents FCM registration against backends that cannot issue real tokens.
///
/// Firebase Emulator Suite does not emulate Cloud Messaging. Demo project IDs
/// are also deliberately isolated from production, so asking them for an FCM
/// token can only fail (and can surface `messaging/unsupported-browser` on
/// web). In both cases token registration must be a no-op.
class FcmTokenPolicy {
  FcmTokenPolicy._();

  static const String firebaseDemoProjectPrefix = 'demo-';

  static bool isFirebaseDemoProject(String? projectId) {
    return projectId?.startsWith(firebaseDemoProjectPrefix) ?? false;
  }

  static bool shouldSkipRegistration({
    required bool usesFirebaseEmulators,
    String? firebaseProjectId,
  }) {
    return usesFirebaseEmulators || isFirebaseDemoProject(firebaseProjectId);
  }

  static bool forCurrentBackend() {
    String? projectId;
    try {
      if (Firebase.apps.isNotEmpty) {
        projectId = Firebase.app().options.projectId;
      }
    } catch (_) {
      // Firebase may still be unavailable in a unit test or early bootstrap.
      // The explicit emulator flag remains a safe fail-closed signal.
    }

    return shouldSkipRegistration(
      usesFirebaseEmulators: CloudEndpointPolicy.useFirebaseEmulators,
      firebaseProjectId: projectId,
    );
  }
}
