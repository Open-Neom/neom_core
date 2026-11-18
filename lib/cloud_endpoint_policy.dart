import 'package:flutter/foundation.dart';

import 'utils/core_utilities.dart';

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

  static const Set<String> _forbiddenProtoKeys = <String>{
    '__proto__',
    'constructor',
    'prototype',
  };
  static final RegExp _safeEndpointSegmentPattern = RegExp(
    r'^[A-Za-z0-9._-]{1,128}$',
  );
  static final RegExp _unsafeEmulatorHostChars = RegExp(
    r'[\x00-\x20\x7F-\x9F/\\@?#\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2064\u2066-\u2069\u3002\uFF0E\uFF61\uFEFF]',
  );
  static final RegExp _rawEncodedTraversalRe = RegExp(
    r'%(?:2e|2f|5c|25|00)',
    caseSensitive: false,
  );

  static bool _isSafeEndpointSegment(String raw) =>
      _safeEndpointSegmentPattern.hasMatch(raw) &&
      raw != '.' &&
      raw != '..' &&
      !raw.contains('..') &&
      !(raw.startsWith('__') && raw.endsWith('__')) &&
      !_forbiddenProtoKeys.contains(raw.toLowerCase());

  static bool _hasRawUrlTraversal(String rawUrl) {
    if (rawUrl.contains(r'\') || _rawEncodedTraversalRe.hasMatch(rawUrl)) {
      return true;
    }
    final schemeIdx = rawUrl.indexOf('://');
    if (schemeIdx <= 0) return true;
    final afterScheme = rawUrl.substring(schemeIdx + 3);
    final beforeQuery = afterScheme.split('?').first.split('#').first;
    final slashIdx = beforeQuery.indexOf('/');
    if (slashIdx < 0) return false;
    final rawPath = beforeQuery.substring(slashIdx);
    for (final seg in rawPath.split('/')) {
      if (seg == '.' ||
          seg == '..' ||
          _forbiddenProtoKeys.contains(seg.toLowerCase())) {
        return true;
      }
    }
    return false;
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
    if (isRelease) {
      final trimmedProd = productionUrl.trim();
      if (_hasRawUrlTraversal(trimmedProd)) {
        throw StateError(
          'URL productiva insegura o invalida para "$functionName".',
        );
      }
      final prodUri = Uri.tryParse(trimmedProd);
      if (prodUri == null ||
          prodUri.scheme.toLowerCase() != 'https' ||
          prodUri.userInfo.isNotEmpty ||
          !CoreUtilities.isSafePublicMediaUri(prodUri)) {
        throw StateError(
          'URL productiva insegura o invalida para "$functionName".',
        );
      }
      return trimmedProd;
    }

    if (!usesEmulators) {
      throw StateError(
        'Cloud Functions productivas bloqueadas en debug/profile. '
        'Inicia Firebase Functions Emulator y usa '
        'USE_FIREBASE_EMULATORS=true.',
      );
    }

    final cleanHost = host.trim();
    if (!_isSafeEndpointSegment(functionName) ||
        cleanHost.isEmpty ||
        cleanHost.length > 255 ||
        _unsafeEmulatorHostChars.hasMatch(cleanHost) ||
        !port.toDouble().isFinite ||
        port <= 0 ||
        port > 65535 ||
        !_isSafeEndpointSegment(projectId) ||
        !_isSafeEndpointSegment(region)) {
      throw StateError(
        'Configuracion invalida del Functions Emulator para "$functionName".',
      );
    }

    return Uri(
      scheme: 'http',
      host: cleanHost,
      port: port,
      pathSegments: [projectId, region, functionName],
    ).toString();
  }

  static String get emulatorUnavailableMessage =>
      'Firebase Functions Emulator no esta disponible en '
      '$emulatorHost:$functionsEmulatorPort. Inicia el entorno local de EMXI.';
}
