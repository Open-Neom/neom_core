import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sint/sint.dart';
import '../../app_config.dart';
import '../../app_properties.dart';
import '../../data_backend_policy.dart';
import '../../domain/repository/app_release_item_repository.dart';
import '../firestore/app_release_item_firestore.dart';
import '../firestore/public_catalog_read_policy.dart';
import 'app_release_item_api.dart';
import 'release_sync_queue.dart';

/// Default remains Firestore for apps which do not register the new adapter.
abstract final class AppReleaseItems {
  static AppReleaseItemRepository get repository {
    if (!Sint.isRegistered<AppReleaseItemRepository>()) {
      return AppReleaseItemFirestore();
    }
    final repository = Sint.find<AppReleaseItemRepository>();
    if (repository is AppReleaseItemApi &&
        repository.policy.app != AppConfig.instance.appInUse) {
      return AppReleaseItemFirestore();
    }
    return repository;
  }

  static AppReleaseItemRepository create() {
    final policy = DataBackendPolicy.fromProperties(
      AppConfig.instance.appInUse,
      AppProperties.appProperties,
    );
    if (!policy.enabled ||
        Firebase.apps.isNotEmpty &&
            Firebase.app().options.projectId.startsWith('demo-')) {
      return AppReleaseItemFirestore();
    }
    final queues = <String, ReleaseSyncQueue>{};
    return AppReleaseItemApi(
      policy: policy,
      firebase: AppReleaseItemFirestore(),
      publicOnly: PublicCatalogReadPolicy.enabled,
      actorId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
      idToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
      canWrite: () => AppConfig.instance.canPersistUserActivity,
      queueForActor: (actor) => queues.putIfAbsent(
        actor,
        () => HiveReleaseSyncQueue('${policy.app.name}:$actor'),
      ),
    );
  }
}
