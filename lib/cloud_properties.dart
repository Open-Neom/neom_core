import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'cloud_endpoint_policy.dart';
import 'utils/constants/data_assets.dart';
import 'utils/enums/app_in_use.dart';
import 'utils/neom_error_logger.dart';
import 'utils/neom_logger.dart';
import 'utils/secure_logger.dart';

/// Sensitive values (API keys, secrets) and cloud operations (proxies, secureOps).
///
/// Reads from the shared config map loaded by [AppProperties].
/// Call [init] after AppProperties loads the JSON.
class CloudProperties {
  static const int maxSecureOpsResponseBytes = 8 * 1024 * 1024;
  static const int _maxNormalizeDepth = 32;
  static const int _maxCollectionItems = 4096;
  static const Set<String> _forbiddenProtoKeys = <String>{
    '__proto__',
    'constructor',
    'prototype',
  };
  static const Set<String> _allowedProxyMethods = <String>{
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
  };
  static final RegExp _unsafeControlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2064\u2066-\u2069\uFEFF]',
  );
  static final RegExp _stripeSessionIdPattern = RegExp(
    r'^[A-Za-z0-9_-]{1,128}$',
  );
  static final RegExp _secretKeyNamePattern = RegExp(
    r'^[A-Za-z0-9_.-]{1,128}$',
  );
  static final RegExp _encodedPathTraversalRe = RegExp(
    r'%(?:2e|2f|5c|25|00)',
    caseSensitive: false,
  );

  @visibleForTesting
  static String? sanitizeBearerToken(String? raw) {
    if (raw == null) return null;
    if (_unsafeControlOrBidi.hasMatch(raw)) return null;
    final clean = raw.trim();
    if (clean.isEmpty || clean.length > 8192 || RegExp(r'\s').hasMatch(clean)) {
      return null;
    }
    return clean;
  }

  @visibleForTesting
  static bool isValidStripeSessionId(String raw) {
    if (raw.isEmpty || _unsafeControlOrBidi.hasMatch(raw)) return false;
    final clean = raw.trim();
    if (!_stripeSessionIdPattern.hasMatch(clean)) return false;
    if ((clean.startsWith('__') && clean.endsWith('__')) ||
        _forbiddenProtoKeys.contains(clean.toLowerCase())) {
      return false;
    }
    return true;
  }

  @visibleForTesting
  static bool isSafeHttpMethod(String raw) =>
      !_unsafeControlOrBidi.hasMatch(raw) &&
      !RegExp(r'\s').hasMatch(raw.trim()) &&
      _allowedProxyMethods.contains(raw.trim().toUpperCase());

  @visibleForTesting
  static bool isSafeProxyPath(String raw) {
    if (raw.isEmpty ||
        raw.length > 1024 ||
        _unsafeControlOrBidi.hasMatch(raw) ||
        raw.contains(r'\') ||
        _encodedPathTraversalRe.hasMatch(raw)) {
      return false;
    }
    final clean = raw.trim();
    if (clean.isEmpty ||
        clean.startsWith('//') ||
        clean.contains('://') ||
        RegExp(r'\s').hasMatch(clean)) {
      return false;
    }
    final pathPart = clean.split('?').first.split('#').first;
    final segments = pathPart.split('/');
    for (final seg in segments) {
      if (seg == '.' ||
          seg == '..' ||
          _forbiddenProtoKeys.contains(seg.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  @visibleForTesting
  static bool isSafeSecretKeyName(String raw) {
    if (raw.isEmpty || _unsafeControlOrBidi.hasMatch(raw)) return false;
    final clean = raw.trim();
    if (!_secretKeyNamePattern.hasMatch(clean) ||
        clean == '.' ||
        clean.contains('..') ||
        (clean.startsWith('__') && clean.endsWith('__')) ||
        _forbiddenProtoKeys.contains(clean.toLowerCase())) {
      return false;
    }
    return true;
  }
  static AppInUse? appInUse;
  static dynamic appProperties = {};

  /// Shared config loaded by AppProperties.
  static dynamic get _config => appProperties;

  /// Service account JSON (mobile only).
  static dynamic serviceAccount = {};

  /// Whether config was loaded from Cloud Functions (secrets are server-side).
  static bool isSecureMode = false;

  /// Initialize cloud-specific state after AppProperties loads the JSON.
  static Future<void> init() async {
    if (!isSecureMode) {
      await readServiceAccount();
    }
  }

  /// Returns the secureOpsWeb URL for the current app.
  static String _getSecureOpsWebUrl() {
    final String productionUrl;
    switch (appInUse ?? AppInUse.o) {
      case AppInUse.g:
        productionUrl =
            'https://us-central1-gig-me-out.cloudfunctions.net/secureOpsWeb';
        break;
      case AppInUse.c:
        productionUrl =
            'https://us-central1-cyberneom-edd2d.cloudfunctions.net/secureOpsWeb';
        break;
      case AppInUse.i:
        productionUrl =
            'https://us-central1-itzli-app.cloudfunctions.net/secureOpsWeb';
        break;
      case AppInUse.e:
      default:
        productionUrl = 'https://secureopsweb-uzmgogia7a-uc.a.run.app';
    }

    if (appInUse != AppInUse.e &&
        !const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      return productionUrl;
    }

    return CloudEndpointPolicy.functionUrl(
      functionName: 'secureOpsWeb',
      productionUrl: productionUrl,
    );
  }

  /// Returns the PDF proxy endpoint without allowing non-release builds to
  /// contact EMXI production.
  static String getPdfProxyUrl() {
    return CloudEndpointPolicy.functionUrl(
      functionName: 'pdfProxy',
      productionUrl:
          'https://us-central1-emxi-9c5b5.cloudfunctions.net/pdfProxy',
    );
  }

  /// Exposes the secureOpsWeb URL publicly.
  static String getSecureOpsWebUrl() => _getSecureOpsWebUrl();

  /// Loads config from Cloud Functions on web.
  /// Stores into [AppProperties.appProperties] so both classes share the same data.
  static Future<void> loadFromCloud() async {
    final data = await callSecureOps({'action': 'getConfig'});
    appProperties = data;
    isSecureMode = true;
    neomLogger.t("Properties loaded from Cloud Functions (${(data as Map).length} keys)");
  }

  // ═══════════════════════════════════════════
  // Cloud Operations
  // ═══════════════════════════════════════════

  /// Garantiza que haya una sesión de Firebase antes de llamar al servidor.
  ///
  /// El servidor pasó a exigir autenticación en las acciones que gastan
  /// dinero (`aiProxy`, `geminiProxy`, `synthesizeSpeech`, `embeddingProxy`),
  /// porque estaban abiertas a cualquiera en internet. El modo invitado no
  /// desaparece por eso: se firma anónimamente, lo que da un `uid` al que
  /// atribuir consumo y aplicar límites **sin pedirle nada al usuario**.
  ///
  /// Si el invitado se registra después, `linkWithCredential` conserva este
  /// mismo uid — el historial de consumo no se parte en dos.
  ///
  /// Devuelve null si el proveedor anónimo no está habilitado en el
  /// proyecto; quien llama trata ese caso como falta de autenticación.
  /// Igual que [_ensureSignedIn], para quien no pasa por [callSecureOps].
  ///
  /// El streaming de IA arma su propia petición HTTP —necesita la respuesta
  /// por trozos y `callSecureOps` devuelve el cuerpo entero—, y ahí leía
  /// `currentUser` sin firmar si no había nadie. Mientras el servidor
  /// aceptaba llamadas sin sesión eso pasaba desapercibido; al exigirlas,
  /// cualquier visitante nuevo se quedaba sin chat con un 401, porque la
  /// sesión anónima solo nacía en el camino no-streaming.
  static Future<User?> ensureSignedIn() => _ensureSignedIn();

  static Future<User?> _ensureSignedIn() async {
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return existing;
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      neomLogger.t('Sesión anónima creada para invitado: ${cred.user?.uid}');
      return cred.user;
    } catch (e, st) {
      // Falla si el proveedor anónimo está deshabilitado. Se devuelve null y
      // la llamada de arriba dará el error de autenticación — mejor un fallo
      // claro que una llamada sin identificar que el servidor rechazará.
      NeomErrorLogger.recordError(e, st,
          module: 'neom_core', operation: '_ensureSignedIn');
      return null;
    }
  }

  /// Calls secureOps. On web, uses secureOpsWeb (HTTP with CORS).
  /// On mobile, uses the callable secureOps via Firebase SDK.
  static Future<Map<String, dynamic>> callSecureOps(Map<String, dynamic> data) async {
    if (kIsWeb) {
      // `getConfig` no requiere sesión. En apps embebidas (EMXI/Cyberneom/Gigmeout)
      // donde Firebase Auth anónimo se mantiene desactivado por seguridad de
      // Firestore, `geminiProxy` intenta firmar si hay sesión y, si no, deja que
      // `secureOpsWeb` valide el origen oficial + rate-limit por IP en servidor.
      final action = data['action'];
      final isPublicAction = action == 'getConfig';
      final allowsGuestOriginProxy =
          action == 'geminiProxy' && (appInUse ?? AppInUse.o) != AppInUse.i;
      final user = isPublicAction
          ? FirebaseAuth.instance.currentUser
          : await _ensureSignedIn();

      if (user == null && !isPublicAction && !allowsGuestOriginProxy) {
        throw Exception('Authentication required — user not logged in');
      }

      final url = Uri.parse(_getSecureOpsWebUrl());

      final rawToken = user != null ? await user.getIdToken() : null;
      final token = sanitizeBearerToken(rawToken);
      if (!isPublicAction && !allowsGuestOriginProxy && token == null) {
        throw Exception('Authentication required — invalid ID token');
      }
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      late final http.Response response;
      try {
        response = await http
            .post(
              url,
              headers: headers,
              body: jsonEncode({'data': data}),
            )
            .timeout(const Duration(seconds: 15));
      } catch (error) {
        if (CloudEndpointPolicy.usesLocalEndpoints) {
          throw StateError(
            '${CloudEndpointPolicy.emulatorUnavailableMessage} '
            'Error original: ${SecureLogger.sanitize(error.toString())}',
          );
        }
        rethrow;
      }

      if (response.bodyBytes.length > maxSecureOpsResponseBytes) {
        throw const FormatException(
          'secureOpsWeb response exceeds 8 MiB limit',
        );
      }

      if (response.statusCode != 200) {
        final safeBody = SecureLogger.sanitize(response.body);
        throw Exception('secureOpsWeb HTTP ${response.statusCode}: $safeBody');
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] != null) {
          final err = body['error'];
          final rawErrMsg =
              err is Map ? (err['message'] ?? 'Unknown error') : err.toString();
          throw Exception(SecureLogger.sanitize(rawErrMsg.toString()));
        }
        // onCall wraps in 'result', HTTP returns directly
        final rawPayload =
            (body.containsKey('result') && body['result'] is Map)
                ? body['result']
                : body;
        final normalizedWeb = normalizeJsonValue(rawPayload);
        return normalizedWeb is Map<String, dynamic> ? normalizedWeb : {};
      }
      return {};
    }

    // Mobile: use Firebase SDK callable.
    //
    // `httpsCallable` adjunta el token solo si YA hay un usuario; si no,
    // `request.auth` llega null y el servidor rechaza. Se firma antes, igual
    // que en la rama web, para que el invitado en móvil siga funcionando.
    if (data['action'] != 'getConfig') {
      await _ensureSignedIn();
    }
    final callable = FirebaseFunctions.instance.httpsCallable('secureOps');
    final result = await callable.call(data);
    final normalized = _normalizeJsonValue(result.data);
    if (normalized is Map<String, dynamic>) {
      return normalized;
    }
    return {};
  }

  @visibleForTesting
  static dynamic normalizeJsonValue(dynamic value, [int depth = 0]) {
    if (depth > _maxNormalizeDepth || value == null) return null;
    if (value is num) {
      if (value is double && !value.isFinite) return null;
      return value;
    }
    if (value is Map) {
      final out = <String, dynamic>{};
      for (final entry in value.entries) {
        if (out.length >= _maxCollectionItems) break;
        final key = entry.key?.toString() ?? '';
        if (key.isEmpty || _forbiddenProtoKeys.contains(key.toLowerCase())) {
          continue;
        }
        out[key] = normalizeJsonValue(entry.value, depth + 1);
      }
      return out;
    }
    if (value is List) {
      final out = <dynamic>[];
      for (final item in value.take(_maxCollectionItems)) {
        out.add(normalizeJsonValue(item, depth + 1));
      }
      return out;
    }
    return value;
  }

  static dynamic _normalizeJsonValue(dynamic value) =>
      normalizeJsonValue(value);

  /// Calls secureOps Cloud Function to send a push notification server-side.
  /// Targets a device [token] or, alternatively, an FCM [topic] (e.g. 'allUsers').
  /// Returns true if sent successfully, false otherwise.
  static Future<bool> sendNotificationViaCloud({
    String token = '',
    String topic = '',
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (token.isEmpty && topic.isEmpty) return false;
    try {
      final result = await callSecureOps({
        'action': 'sendNotification',
        if (token.isNotEmpty) 'token': token,
        if (topic.isNotEmpty) 'topic': topic,
        'title': title,
        'body': body,
        'data': data ?? {},
      });
      return result['success'] == true;
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'sendNotificationViaCloud');
      return false;
    }
  }

  /// Verifies a Stripe Checkout Session via Cloud Function without exposing secret key.
  static Future<bool> verifyStripeSession(String sessionId) async {
    if (!isValidStripeSessionId(sessionId)) return false;
    final cleanSessionId = sessionId.trim();
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyStripeSession');
      final result = await callable.call({'sessionId': cleanSessionId});
      if (result.data != null && result.data is Map) {
        final map = Map<String, dynamic>.from(result.data as Map);
        return map['isPaid'] == true;
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'verifyStripeSession');
    }
    return false;
  }

  /// Calls secureOps Cloud Function to proxy a Stripe API call.
  /// [isLive] determines whether to use the live or test Stripe key.
  static Future<Map<String, dynamic>?> stripeProxy({
    required String path,
    String method = 'POST',
    String? body,
    bool isLive = true,
  }) async {
    if (!isSafeProxyPath(path) || !isSafeHttpMethod(method)) {
      return null;
    }
    try {
      return await callSecureOps({
        'action': 'stripeProxy',
        'method': method.trim().toUpperCase(),
        'path': path.trim(),
        'body': body,
        'isLive': isLive,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'stripeProxy');
      return null;
    }
  }

  /// Calls secureOps Cloud Function to proxy a WooCommerce API call.
  static Future<dynamic> wooProxy({
    required String path,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    if (!isSafeProxyPath(path) || !isSafeHttpMethod(method)) {
      return null;
    }
    try {
      return await callSecureOps({
        'action': 'wooProxy',
        'method': method.trim().toUpperCase(),
        'path': path.trim(),
        'body': body,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'wooProxy');
      return null;
    }
  }

  /// Retrieves a specific secret from Cloud Functions (e.g. googleApiKey for Maps)
  static Future<String> getSecretFromCloud(String key) async {
    if (!isSafeSecretKeyName(key)) return '';
    try {
      final result = await callSecureOps({
        'action': 'getSecret',
        'key': key.trim(),
      });
      return result['value'] ?? '';
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'getSecretFromCloud');
      return '';
    }
  }

  /// Calls secureOps Cloud Function to proxy a WordPress Media API call.
  static Future<dynamic> wooMediaProxy({
    required String path,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    if (!isSafeProxyPath(path) || !isSafeHttpMethod(method)) {
      return null;
    }
    try {
      return await callSecureOps({
        'action': 'wooMediaProxy',
        'method': method.trim().toUpperCase(),
        'path': path.trim(),
        'body': body,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'wooMediaProxy');
      return null;
    }
  }

  /// Calls secureOps Cloud Function to proxy AI API calls (OpenRouter, Brave).
  static Future<Map<String, dynamic>?> aiProxy({
    String provider = 'openrouter',
    String? model,
    List<Map<String, dynamic>>? messages,
    int maxTokens = 2048,
    String? query,
  }) async {
    try {
      return await callSecureOps({
        'action': 'aiProxy',
        'provider': provider,
        'model': model,
        'messages': messages,
        'maxTokens': maxTokens,
        'query': query,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'aiProxy');
      return null;
    }
  }

  /// Calls secureOps Cloud Function to orchestrate multi-API audio mastering
  /// (Music.AI Reference/Parametric, RoEx Tonn, LANDR, Auphonic).
  static Future<Map<String, dynamic>?> masteringProxy({
    required String operation,
    String provider = 'auto',
    Map<String, dynamic>? payload,
  }) async {
    try {
      return await callSecureOps({
        'action': 'masteringProxy',
        'operation': operation,
        'provider': provider,
        ...?payload,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'masteringProxy');
      return null;
    }
  }

  /// Calls secureOps Cloud Function to proxy cached YouTube Music searches and
  /// public playlist imports without exposing `GOOGLE_API_KEY` to the client.
  static Future<Map<String, dynamic>?> ytmusicProxy({
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    try {
      return await callSecureOps({
        'action': 'ytmusicProxy',
        'operation': operation,
        ...?payload,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'ytmusicProxy');
      return null;
    }
  }

  /// Calls secureOps Cloud Function to compute Songmates repertoire matches
  /// across public Giglists/repertoires in Firestore.
  static Future<Map<String, dynamic>?> findRepertoireMatchesViaCloud({
    required String profileId,
    int limit = 50,
  }) async {
    try {
      return await callSecureOps({
        'action': 'findRepertoireMatches',
        'profileId': profileId,
        'limit': limit,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'findRepertoireMatchesViaCloud',
      );
      return null;
    }
  }

  /// Calls secureOps Cloud Function to execute an atomic server-side GigCoins
  /// tip transfer from the authenticated caller to a creator's wallet.
  static Future<Map<String, dynamic>?> sendTipViaCloud({
    required String recipientId,
    required double amount,
    String? recipientEmail,
    String? senderProfileId,
    String? senderName,
    String? senderAvatarUrl,
    String tier = 'custom',
    String? message,
    String? contextType,
    String? contextId,
  }) async {
    try {
      return await callSecureOps({
        'action': 'sendTip',
        'recipientId': recipientId,
        'amount': amount,
        if (recipientEmail != null && recipientEmail.isNotEmpty)
          'recipientEmail': recipientEmail,
        if (senderProfileId != null && senderProfileId.isNotEmpty)
          'senderProfileId': senderProfileId,
        if (senderName != null && senderName.isNotEmpty)
          'senderName': senderName,
        if (senderAvatarUrl != null && senderAvatarUrl.isNotEmpty)
          'senderAvatarUrl': senderAvatarUrl,
        'tier': tier,
        if (message != null && message.isNotEmpty) 'message': message,
        if (contextType != null && contextType.isNotEmpty)
          'contextType': contextType,
        if (contextId != null && contextId.isNotEmpty) 'contextId': contextId,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'sendTipViaCloud',
      );
      return null;
    }
  }

  /// Calls secureOps Cloud Function to fetch/refresh aggregated monthly CASETE
  /// pool stats (`casetePoolStats/{YYYY-MM}`).
  static Future<Map<String, dynamic>?> fetchCasetePoolStatsViaCloud({
    int? year,
    int? month,
  }) async {
    try {
      return await callSecureOps({
        'action': 'casetePoolStats',
        'year': ?year,
        'month': ?month,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(
        e,
        st,
        module: 'neom_core',
        operation: 'fetchCasetePoolStatsViaCloud',
      );
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // Service Account
  // ═══════════════════════════════════════════

  static Future<void> readServiceAccount() async {
    // SECURITY: a service account JSON bundled in a client app is a critical
    // leak — anyone can extract it from the APK/IPA and mint OAuth tokens.
    // Push notifications are proxied via Cloud Functions (sendNotificationViaCloud).
    // The asset is only loaded when explicitly allowed for admin tooling
    // ('allowClientServiceAccount': true in properties.json) or in debug builds.
    final bool allowClient = _config is Map && _config['allowClientServiceAccount'] == true;
    if (kIsWeb || (!allowClient && !kDebugMode)) {
      neomLogger.t("readServiceAccount skipped on client (security) — using Cloud Functions proxy");
      return;
    }

    neomLogger.t("readServiceAccount (allowClientServiceAccount=$allowClient, debug=$kDebugMode)");
    try {
      String jsonString = await rootBundle.loadString(DataAssets.serviceAccountJsonPath);
      serviceAccount = jsonDecode(jsonString);
      neomLogger.t("Service Account Loaded (${(serviceAccount as Map).length} keys)");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'readServiceAccount');
      return;
    }
  }

  // ═══════════════════════════════════════════
  // Sensitive Getters
  // ═══════════════════════════════════════════

  static String getGoogleApiKey() {
    return _config['googleApiKey'] ?? '';
  }

  static String getSpotifyClientId() {
    return _config['spotifyClientId'] ?? '';
  }

  /// Returns Spotify client secret. Empty in secure mode — use spotifyToken action via Cloud Functions.
  static String getSpotifyClientSecret() {
    return _config['spotifyClientSecret'] ?? '';
  }

  static String getStripePublishableKey() {
    return _config['stripePublishableKey'] ?? '';
  }

  /// Returns Stripe secret key. Empty in secure mode — use stripeProxy() instead.
  /// SECURITY: never ship this key in a client app; all Stripe calls must go
  /// through the Cloud Functions proxy (stripeProxy).
  @Deprecated('Use stripeProxy() — the secret key must never reach the client')
  static String getStripeSecretKey({bool isLive = true}) {
    return isLive
        ? (_config['stripeSecretLiveKey'] ?? '')
        : (_config['stripeSecretTestKey'] ?? '');
  }

  /// Returns WooCommerce client key. Empty in secure mode — use wooProxy() instead.
  static String getWooClientKey() {
    return _config['wooClientKey'] ?? '';
  }

  /// Returns WooCommerce client secret. Empty in secure mode — use wooProxy() instead.
  static String getWooClientSecret() {
    return _config['wooClientSecret'] ?? '';
  }

  /// Returns WordPress account. Empty in secure mode — use wooMediaProxy() instead.
  static String getWooAccount() {
    return _config['wooAccount'] ?? '';
  }

  /// Returns WordPress password. Empty in secure mode — use wooMediaProxy() instead.
  static String getWooPass() {
    return _config['wooPass'] ?? '';
  }

  static String getWebCliendId() {
    return _config['webClientId'] ?? '';
  }

  static String getServerCliendId() {
    return _config['serverClientId'] ?? '';
  }

  static String getGeminiApiKey() {
    return _config['geminiApiKey'] ?? '';
  }

  static String getBraveKey() {
    return _config['braveKey'] ?? '';
  }

  /// API key para OpenRouter (proveedores OpenAI-compatible: Qwen, DeepSeek, etc.)
  static String getOpenRouterApiKey() {
    return _config['openRouterApiKey'] ?? '';
  }

  /// Base URL para OpenRouter (o cualquier endpoint OpenAI-compatible)
  static String getOpenRouterBaseUrl() {
    return _config['openRouterBaseUrl'] ?? 'https://openrouter.ai/api/v1';
  }

}
