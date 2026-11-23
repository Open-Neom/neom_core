import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'enums/app_in_use.dart';

/// Shared runtime Firebase backend guard parameterized per [AppInUse].
///
/// Most apps (e.g. `AppInUse.e` EMXI, `AppInUse.a` Admineom) isolate debug and
/// profile builds onto the local Emulator Suite by default and require explicit
/// `--dart-define=USE_FIREBASE_EMULATORS=false` +
/// `--dart-define=ALLOW_NON_RELEASE_PRODUCTION_FIREBASE=true` to reach a real
/// backend. Apps with owner-authorized shared QA defaults (such as `AppInUse.g`
/// Gigmeout) opt into shared backend defaults while preserving explicit
/// emulator opt-in via `--dart-define=USE_FIREBASE_EMULATORS=true`.
class NeomFirebaseRuntimeConfig {
  const NeomFirebaseRuntimeConfig._({
    required this.app,
    required this.localProjectId,
    required this.defaultUseEmulators,
    required this.defaultAllowNonReleaseProduction,
    required this.brandLabel,
  });

  /// Resolves the canonical runtime backend policy for [app].
  factory NeomFirebaseRuntimeConfig.forApp(AppInUse app) {
    switch (app) {
      case AppInUse.e:
        return const NeomFirebaseRuntimeConfig._(
          app: AppInUse.e,
          localProjectId: 'demo-emxi-local',
          defaultUseEmulators: !kReleaseMode,
          defaultAllowNonReleaseProduction: false,
          brandLabel: 'EMXI',
        );
      case AppInUse.a:
        return const NeomFirebaseRuntimeConfig._(
          app: AppInUse.a,
          localProjectId: 'demo-admineom-local',
          defaultUseEmulators: !kReleaseMode,
          defaultAllowNonReleaseProduction: false,
          brandLabel: 'Admineom',
        );
      case AppInUse.g:
        // Owner-authorized shared QA backend by default; emulator isolation
        // remains available via `--dart-define=USE_FIREBASE_EMULATORS=true`.
        return const NeomFirebaseRuntimeConfig._(
          app: AppInUse.g,
          localProjectId: 'demo-gigmeout-local',
          defaultUseEmulators: false,
          defaultAllowNonReleaseProduction: true,
          brandLabel: 'Gigmeout',
        );
      case AppInUse.c:
        return const NeomFirebaseRuntimeConfig._(
          app: AppInUse.c,
          localProjectId: 'demo-cyberneom-local',
          defaultUseEmulators: !kReleaseMode,
          defaultAllowNonReleaseProduction: false,
          brandLabel: 'Cyberneom',
        );
      case AppInUse.i:
        return const NeomFirebaseRuntimeConfig._(
          app: AppInUse.i,
          localProjectId: 'demo-itzli-local',
          defaultUseEmulators: !kReleaseMode,
          defaultAllowNonReleaseProduction: false,
          brandLabel: 'Itzli',
        );
      case AppInUse.b:
        return const NeomFirebaseRuntimeConfig._(
          app: AppInUse.b,
          localProjectId: 'demo-blup-local',
          defaultUseEmulators: !kReleaseMode,
          defaultAllowNonReleaseProduction: false,
          brandLabel: 'Blup',
        );
      default:
        return NeomFirebaseRuntimeConfig._(
          app: app,
          localProjectId: 'demo-${app.name}-local',
          defaultUseEmulators: !kReleaseMode,
          defaultAllowNonReleaseProduction: false,
          brandLabel: app.name.toUpperCase(),
        );
    }
  }

  final AppInUse app;
  final String localProjectId;
  final bool defaultUseEmulators;
  final bool defaultAllowNonReleaseProduction;
  final String brandLabel;

  static const bool _hasUseEmulatorsOverride =
      bool.hasEnvironment('USE_FIREBASE_EMULATORS');
  static const bool _useEmulatorsOverride =
      bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  static const bool _hasAllowNonReleaseProductionOverride =
      bool.hasEnvironment('ALLOW_NON_RELEASE_PRODUCTION_FIREBASE');
  static const bool _allowNonReleaseProductionOverride =
      bool.fromEnvironment('ALLOW_NON_RELEASE_PRODUCTION_FIREBASE');

  static const String _configuredHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '',
  );

  static const int firestorePort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );
  static const int authPort = int.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );
  static const int functionsPort = int.fromEnvironment(
    'FIREBASE_FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );
  static const int storagePort = int.fromEnvironment(
    'FIREBASE_STORAGE_EMULATOR_PORT',
    defaultValue: 9199,
  );

  bool get useEmulators =>
      _hasUseEmulatorsOverride ? _useEmulatorsOverride : defaultUseEmulators;

  bool get allowNonReleaseProduction => _hasAllowNonReleaseProductionOverride
      ? _allowNonReleaseProductionOverride
      : defaultAllowNonReleaseProduction;

  static String get emulatorHost {
    if (_configuredHost.isNotEmpty) return _configuredHost;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  @visibleForTesting
  static bool blocksRealFirebase({
    required bool isRelease,
    required bool usesEmulators,
    required bool allowsNonReleaseProduction,
  }) {
    return !isRelease && !usesEmulators && !allowsNonReleaseProduction;
  }

  void assertSafeConfiguration() {
    if (blocksRealFirebase(
      isRelease: kReleaseMode,
      usesEmulators: useEmulators,
      allowsNonReleaseProduction: allowNonReleaseProduction,
    )) {
      throw StateError(
        'Firebase productivo bloqueado para builds debug/profile de $brandLabel. '
        'Usa Emulator Suite (predeterminado) o, solo para una prueba '
        'deliberada, define --dart-define=USE_FIREBASE_EMULATORS=false '
        '--dart-define=ALLOW_NON_RELEASE_PRODUCTION_FIREBASE=true.',
      );
    }
  }

  /// Returns isolated demo-project options while using emulators, or
  /// [productionOptions] otherwise.
  FirebaseOptions? optionsFor(FirebaseOptions? productionOptions) =>
      selectOptions(productionOptions, usesEmulators: useEmulators);

  @visibleForTesting
  FirebaseOptions? selectOptions(
    FirebaseOptions? productionOptions, {
    required bool usesEmulators,
  }) {
    if (!usesEmulators) return productionOptions;
    return FirebaseOptions(
      apiKey: '$localProjectId-api-key',
      appId: '1:1234567890:web:$localProjectId',
      messagingSenderId: '1234567890',
      projectId: localProjectId,
      authDomain: '$localProjectId.firebaseapp.com',
      storageBucket: '$localProjectId.appspot.com',
    );
  }

  void assertInitializedAppMatches(FirebaseOptions expectedOptions) {
    final actualProjectId = Firebase.app().options.projectId;
    if (actualProjectId != expectedOptions.projectId) {
      throw StateError(
        'Firebase ya estaba inicializado para "$actualProjectId", pero '
        '$brandLabel requiere "${expectedOptions.projectId}". Cierra la '
        'pestana y vuelve a iniciar para evitar mezclar backends.',
      );
    }
  }

  Future<void> connectDefaultAppToEmulators() async {
    if (!useEmulators) return;

    final host = emulatorHost;
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    FirebaseFunctions.instance.useFunctionsEmulator(host, functionsPort);
    await FirebaseStorage.instance.useStorageEmulator(host, storagePort);
  }

  void connectFirestoreAppToEmulator(FirebaseApp firebaseApp) {
    if (!useEmulators) return;
    FirebaseFirestore.instanceFor(
      app: firebaseApp,
    ).useFirestoreEmulator(emulatorHost, firestorePort);
  }
}
