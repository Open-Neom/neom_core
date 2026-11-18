import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sint/sint.dart';
import '../../app_config.dart';
import '../../app_properties.dart';
import '../../data_backend_policy.dart';
import '../../domain/repository/account_repository.dart';
import '../../domain/repository/profile_directory_repository.dart';
import '../../domain/repository/profile_repository.dart';
import '../../domain/repository/user_repository.dart';
import '../firestore/profile_firestore.dart';
import '../firestore/public_catalog_read_policy.dart';
import '../firestore/user_firestore.dart';
import 'app_data_api_client.dart';
import 'app_profile_api.dart';
import 'app_user_api.dart';
import 'release_sync_queue.dart';

bool _enabled(DataBackendPolicy policy, String flag) {
  final properties = AppProperties.appProperties;
  final raw = properties is Map ? properties['dataBackend'] : null;
  final config = raw is Map ? raw : const {};
  return policy.hasServer &&
      config[flag] != false &&
      !(Firebase.apps.isNotEmpty &&
          Firebase.app().options.projectId.startsWith('demo-'));
}

AppDataApiClient _client(DataBackendPolicy policy, String resource) {
  final queues = <String, ReleaseSyncQueue>{};
  return AppDataApiClient(
    policy: policy,
    resource: resource,
    actorId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
    idToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    queueForActor: (actor) => queues.putIfAbsent(
      actor,
      () => HiveReleaseSyncQueue('${policy.app.name}:$resource:$actor'),
    ),
  );
}

abstract final class AppUsers {
  static UserRepository get repository {
    if (!Sint.isRegistered<UserRepository>()) return UserFirestore();
    final result = Sint.find<UserRepository>();
    if (result is AppUserApi &&
        result.client.policy.app != AppConfig.instance.appInUse) {
      return UserFirestore();
    }
    return result;
  }

  static AccountRepository get account {
    final result = repository;
    if (result is! AccountRepository) {
      throw StateError('Account lifecycle capability required');
    }
    return result;
  }

  static UserRepository create() {
    final policy = DataBackendPolicy.fromProperties(
      AppConfig.instance.appInUse,
      AppProperties.appProperties,
    );
    final firebase = UserFirestore();
    if (!_enabled(policy, 'usersEnabled')) return firebase;
    return AppUserApi(client: _client(policy, 'users'), firebase: firebase);
  }
}

abstract final class AppProfiles {
  static ProfileRepository get repository {
    if (!Sint.isRegistered<ProfileRepository>()) return ProfileFirestore();
    final result = Sint.find<ProfileRepository>();
    if (result is AppProfileApi &&
        result.client.policy.app != AppConfig.instance.appInUse) {
      return ProfileFirestore();
    }
    return result;
  }

  static ProfileDirectoryRepository get directory {
    final result = repository;
    if (result is! ProfileDirectoryRepository) {
      throw StateError('Profile directory capability required');
    }
    return result;
  }

  static ProfileRepository create() {
    final policy = DataBackendPolicy.fromProperties(
      AppConfig.instance.appInUse,
      AppProperties.appProperties,
    );
    final firebase = ProfileFirestore();
    if (!_enabled(policy, 'profilesEnabled')) return firebase;
    return AppProfileApi(
      client: _client(policy, 'profiles'),
      firebase: firebase,
      accounts: UserFirestore(),
      publicReader: () =>
          PublicCatalogReadPolicy.enabled ||
          !AppConfig.instance.canPersistUserActivity,
    );
  }
}
