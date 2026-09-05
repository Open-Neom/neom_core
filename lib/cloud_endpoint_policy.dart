import 'package:flutter/foundation.dart';

/// Resolves direct HTTP Cloud Function endpoints without letting debug/profile
/// builds reach production by accident.
///
/// Release builds keep their existing production URLs. Non-release builds use
/// the local Functions emulator by default. Disabling the emulator in a
/// non-release build blocks the request instead of silently falling back to a
/// production endpoint.
class CloudEndpointPolicy {
  CloudEndpointPolicy._();

  static const bool useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: !kReleaseMode,
  );

  static const String emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int functionsEmulatorPort = int.fromEnvironment(
    'FIREBASE_FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );

  static const String emulatorProjectId = String.fromEnvironment(
    'FIREBASE_EMULATOR_PROJECT_ID',
    defaultValue: 'demo-emxi-local',
  );

  static const String functionsRegion = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  static bool get usesLocalEndpoints => !kReleaseMode && useFirebaseEmulators;

  static String functionUrl({
    required String functionName,
    required String productionUrl,
  }) {
    return resolveFunctionUrl(
      functionName: functionName,
      productionUrl: productionUrl,
      isRelease: kReleaseMode,
      usesEmulators: useFirebaseEmulators,
      host: emulatorHost,
      port: functionsEmulatorPort,
      projectId: emulatorProjectId,
      region: functionsRegion,
    );
  }

  @visibleForTesting
  static String resolveFunctionUrl({
    required String functionName,
    required String productionUrl,
    required bool isRelease,
    required bool usesEmulators,
    String host = '127.0.0.1',
    int port = 5001,
    String projectId = 'demo-emxi-local',
    String region = 'us-central1',
  }) {
    if (isRelease) return productionUrl;

    if (!usesEmulators) {
      throw StateError(
        'Cloud Functions productivas bloqueadas en debug/profile. '
        'Inicia Firebase Functions Emulator y usa '
        'USE_FIREBASE_EMULATORS=true.',
      );
    }

    if (functionName.isEmpty ||
        host.isEmpty ||
        port <= 0 ||
        projectId.isEmpty ||
        region.isEmpty) {
      throw StateError(
        'Configuracion invalida del Functions Emulator para "$functionName".',
      );
    }

    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      pathSegments: [projectId, region, functionName],
    ).toString();
  }

  static String get emulatorUnavailableMessage =>
      'Firebase Functions Emulator no esta disponible en '
      '$emulatorHost:$functionsEmulatorPort. Inicia el entorno local de EMXI.';
}
