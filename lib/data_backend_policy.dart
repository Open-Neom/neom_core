import 'package:flutter/foundation.dart';

import 'utils/enums/app_in_use.dart';

/// Per-app opt-in. An AI endpoint is never inferred to be a data endpoint.
class DataBackendPolicy {
  const DataBackendPolicy({
    required this.app,
    this.enabled = false,
    this.baseUrl,
    this.firebaseFallback = true,
    this.syncEnabled = true,
    this.timeout = const Duration(seconds: 4),
  });

  static const bool _hasEnvOverride = bool.hasEnvironment(
    'DATA_BACKEND_ENABLED',
  );
  static const bool _envEnabled = bool.fromEnvironment('DATA_BACKEND_ENABLED');

  /// Evaluates whether the own-server data backend is enabled for [app].
  ///
  /// When `dataBackend.enabled` in `properties.json` is `false` (default),
  /// Gigmeout runs 100% against Firebase (`gig-me-out`). Setting
  /// `dataBackend.enabled` to `true` (or passing
  /// `--dart-define=DATA_BACKEND_ENABLED=true`) switches eligible apps
  /// (`AppInUse.g` / `AppInUse.i`) to their own server.
  static bool isEnabledFor(AppInUse app, dynamic properties) {
    final eligible = app == AppInUse.g || app == AppInUse.i;
    if (!eligible) return false;
    if (_hasEnvOverride) return _envEnabled;
    final raw = properties is Map ? properties['dataBackend'] : null;
    final config = raw is Map ? raw : const {};
    return config['enabled'] == true;
  }

  factory DataBackendPolicy.fromProperties(AppInUse app, dynamic properties) {
    final raw = properties is Map ? properties['dataBackend'] : null;
    final config = raw is Map ? raw : const {};
    final configuredBase = (config['baseUrl'] ?? '').toString().trim();
    final mobileBase = (config['mobileBaseUrl'] ?? '').toString().trim();
    final effectiveConfig = (!kIsWeb && configuredBase == 'same-origin' && mobileBase.isNotEmpty)
        ? mobileBase
        : configuredBase;
    final url = resolveBaseUrl(
      effectiveConfig,
      isWeb: kIsWeb,
      browserLocation: Uri.base,
      allowedOrigins: config['serverOrigins'] is List
          ? (config['serverOrigins'] as List).whereType<String>()
          : const [],
    );
    final ms = config['timeoutMs'];
    return DataBackendPolicy(
      app: app,
      enabled: isEnabledFor(app, properties),
      baseUrl: url,
      firebaseFallback: config['firebaseFallback'] != false,
      syncEnabled: config['syncEnabled'] != false,
      timeout: Duration(milliseconds: ms is int ? ms.clamp(500, 30000) : 4000),
    );
  }

  /// A hosted web app can use its own origin without making a visitor's
  /// computer the data server. Native clients still need an explicit URL.
  /// Exact `serverOrigins` opt-ins keep existing Firebase-hosted web builds
  /// using Firestore when their host does not serve these API routes.
  @visibleForTesting
  static Uri? resolveBaseUrl(
    String configured, {
    required bool isWeb,
    required Uri browserLocation,
    Iterable<String> allowedOrigins = const [],
  }) {
    final Uri? url;
    if (configured == 'same-origin') {
      if (!isWeb ||
          !browserLocation.hasAuthority ||
          !['https', 'http'].contains(browserLocation.scheme) ||
          browserLocation.userInfo.isNotEmpty ||
          !allowedOrigins.contains(browserLocation.origin)) {
        return null;
      }
      url = Uri.parse(browserLocation.origin);
    } else {
      url = Uri.tryParse(configured);
    }
    return url != null &&
            url.hasAuthority &&
            ['https', 'http'].contains(url.scheme) &&
            url.userInfo.isEmpty &&
            !url.hasQuery &&
            !url.hasFragment
        ? url
        : null;
  }

  final AppInUse app;
  final bool enabled;
  final Uri? baseUrl;
  final bool firebaseFallback;
  final bool syncEnabled;
  final Duration timeout;
  bool get hasServer => enabled && baseUrl != null;
}
