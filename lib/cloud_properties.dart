import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'cloud_endpoint_policy.dart';
import 'utils/constants/data_assets.dart';
import 'utils/enums/app_in_use.dart';
import 'utils/neom_error_logger.dart';
import 'utils/neom_logger.dart';

/// Sensitive values (API keys, secrets) and cloud operations (proxies, secureOps).
///
/// Reads from the shared config map loaded by [AppProperties].
/// Call [init] after AppProperties loads the JSON.
class CloudProperties {
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
            'https://us-central1-cyberneom-app.cloudfunctions.net/secureOpsWeb';
        break;
      case AppInUse.i:
        productionUrl =
            'https://us-central1-itzli-app.cloudfunctions.net/secureOpsWeb';
        break;
      case AppInUse.e:
      default:
        productionUrl = 'https://secureopsweb-uzmgogia7a-uc.a.run.app';
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

  /// Calls secureOps. On web, uses secureOpsWeb (HTTP with CORS).
  /// On mobile, uses the callable secureOps via Firebase SDK.
  static Future<Map<String, dynamic>> callSecureOps(Map<String, dynamic> data) async {
    if (kIsWeb) {
      final user = FirebaseAuth.instance.currentUser;
      final isPublicAction = data['action'] == 'getConfig' ||
          data['action'] == 'geminiProxy' ||
          data['action'] == 'askSaia' ||
          data['action'] == 'chat' ||
          data['action'] == 'embeddingProxy' ||
          data['action'] == 'synthesizeSpeech';

      if (user == null && !isPublicAction) {
        throw Exception('Authentication required — user not logged in');
      }

      final url = Uri.parse(_getSecureOpsWebUrl());

      final token = user != null ? await user.getIdToken() : null;
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
            'Error original: $error',
          );
        }
        rethrow;
      }

      if (response.statusCode != 200) {
        throw Exception('secureOpsWeb HTTP ${response.statusCode}: ${response.body}');
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['error'] != null) {
          final err = body['error'];
          throw Exception(err is Map ? (err['message'] ?? 'Unknown error') : err.toString());
        }
        // onCall wraps in 'result', HTTP returns directly
        if (body.containsKey('result') && body['result'] is Map) {
          return body['result'] as Map<String, dynamic>;
        }
        return body;
      }
      return {};
    }

    // Mobile: use Firebase SDK callable
    final callable = FirebaseFunctions.instance.httpsCallable('secureOps');
    final result = await callable.call<Map<String, dynamic>>(data);
    return result.data;
  }

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
    if (sessionId.isEmpty) return false;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyStripeSession');
      final result = await callable.call({'sessionId': sessionId});
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
    try {
      return await callSecureOps({
        'action': 'stripeProxy',
        'method': method,
        'path': path,
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
    try {
      return await callSecureOps({
        'action': 'wooProxy',
        'method': method,
        'path': path,
        'body': body,
      });
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'wooProxy');
      return null;
    }
  }

  /// Retrieves a specific secret from Cloud Functions (e.g. googleApiKey for Maps)
  static Future<String> getSecretFromCloud(String key) async {
    try {
      final result = await callSecureOps({
        'action': 'getSecret',
        'key': key,
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
    try {
      return await callSecureOps({
        'action': 'wooMediaProxy',
        'method': method,
        'path': path,
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
