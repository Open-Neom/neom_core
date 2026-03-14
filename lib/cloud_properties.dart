import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'app_properties.dart';
import 'utils/constants/data_assets.dart';

/// Sensitive values (API keys, secrets) and cloud operations (proxies, secureOps).
///
/// Reads from the shared config map loaded by [AppProperties].
/// Call [init] after AppProperties loads the JSON.
class CloudProperties {

  /// Shared config loaded by AppProperties.
  static dynamic get _config => AppProperties.appProperties;

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

  /// Loads config from Cloud Functions on web.
  /// Stores into [AppProperties.appProperties] so both classes share the same data.
  static Future<void> loadFromCloud() async {
    final data = await callSecureOps({'action': 'getConfig'});
    AppProperties.appProperties = data;
    isSecureMode = true;
    AppConfig.logger.t("Properties loaded from Cloud Functions (${(data as Map).length} keys)");
  }

  // ═══════════════════════════════════════════
  // Cloud Operations
  // ═══════════════════════════════════════════

  /// Calls secureOps. On web, uses secureOpsWeb (HTTP with CORS).
  /// On mobile, uses the callable secureOps via Firebase SDK.
  static Future<Map<String, dynamic>> callSecureOps(Map<String, dynamic> data) async {
    if (kIsWeb) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Authentication required — user not logged in');
      }

      final url = Uri.parse(
        'https://secureopsweb-uzmgogia7a-uc.a.run.app',
      );

      final token = await user.getIdToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'data': data}),
      );

      if (response.statusCode != 200) {
        throw Exception('secureOpsWeb HTTP ${response.statusCode}: ${response.body}');
      }

      final body = jsonDecode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']['message'] ?? 'Unknown error');
      }
      return (body['result'] as Map<String, dynamic>?) ?? {};
    }

    // Mobile: use Firebase SDK callable
    final callable = FirebaseFunctions.instance.httpsCallable('secureOps');
    final result = await callable.call<Map<String, dynamic>>(data);
    return result.data;
  }

  /// Calls secureOps Cloud Function to send a push notification server-side.
  /// Returns true if sent successfully, false otherwise.
  static Future<bool> sendNotificationViaCloud({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final result = await callSecureOps({
        'action': 'sendNotification',
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
      });
      return result['success'] == true;
    } catch (e) {
      AppConfig.logger.e("sendNotificationViaCloud error: $e");
      return false;
    }
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
    } catch (e) {
      AppConfig.logger.e("stripeProxy error: $e");
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
    } catch (e) {
      AppConfig.logger.e("wooProxy error: $e");
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
    } catch (e) {
      AppConfig.logger.e("getSecretFromCloud($key) error: $e");
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
    } catch (e) {
      AppConfig.logger.e("wooMediaProxy error: $e");
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
    } catch (e) {
      AppConfig.logger.e("aiProxy error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════
  // Service Account
  // ═══════════════════════════════════════════

  static Future<void> readServiceAccount() async {
    // On web, service account assets are publicly accessible via the browser.
    // Skip loading — push notifications are handled via Cloud Functions.
    if (kIsWeb) {
      AppConfig.logger.t("readServiceAccount skipped on web (security)");
      return;
    }

    AppConfig.logger.t("readServiceAccount");
    try {
      String jsonString = await rootBundle.loadString(DataAssets.serviceAccountJsonPath);
      serviceAccount = jsonDecode(jsonString);
      AppConfig.logger.t("Service Account Loaded (${(serviceAccount as Map).length} keys)");
    } catch (e) {
      AppConfig.logger.e("Error reading service account: $e");
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
