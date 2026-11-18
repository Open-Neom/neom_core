import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../app_config.dart';
import '../../app_properties.dart';
import '../../data_backend_policy.dart';
import '../../utils/enums/app_in_use.dart';
import 'app_data_api_client.dart';
import 'release_sync_queue.dart';

class AppPlatformSseFrame {
  final String event;
  final Map<String, dynamic> data;

  const AppPlatformSseFrame({required this.event, required this.data});
}

/// Shared factory for Gigmeout's local server platform resources (`/v1/apps/g/<resource>/*`).
/// Leaves EMXI (`AppInUse.e`) and other apps completely untouched (`isEnabled == false`).
abstract final class AppPlatformApi {
  static final Map<String, AppDataApiClient> _clients = {};
  static final Map<String, ReleaseSyncQueue> _queues = {};

  static DataBackendPolicy get policy => DataBackendPolicy.fromProperties(
        AppConfig.instance.appInUse,
        AppProperties.appProperties,
      );

  static bool get isEnabled {
    if (AppConfig.instance.appInUse != AppInUse.g) return false;
    final p = policy;
    if (!p.hasServer) return false;
    if (Firebase.apps.isNotEmpty &&
        Firebase.app().options.projectId.startsWith('demo-')) {
      return false;
    }
    return true;
  }

  static Uri? get baseUrl => isEnabled ? policy.baseUrl : null;

  static Future<String?> currentIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  static String currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<Map<String, dynamic>?> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final base = baseUrl;
    if (base == null) return null;
    final token = authenticated ? await currentIdToken() : null;
    final uri = base.replace(
      path: path,
      queryParameters: (queryParameters == null || queryParameters.isEmpty)
          ? null
          : queryParameters,
    );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode} on GET $path: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  static Future<Map<String, dynamic>?> postJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final base = baseUrl;
    if (base == null) return null;
    final token = authenticated ? await currentIdToken() : null;
    final uri = base.replace(path: path, queryParameters: null);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('HTTP ${response.statusCode} on POST $path: ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// Streams Server-Sent Events on native platforms (`IOClient` streams chunks live).
  /// On Flutter Web (`BrowserClient` buffers until EOF), returns an empty stream
  /// so callers rely on lightweight JSON polling without holding browser XHR slots.
  static Stream<AppPlatformSseFrame> streamSse(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) {
    if (kIsWeb || !isEnabled) return const Stream<AppPlatformSseFrame>.empty();

    late StreamController<AppPlatformSseFrame> controller;
    http.Client? httpClient;
    StreamSubscription<String>? lineSub;
    bool cancelled = false;

    Future<void> connect() async {
      final base = baseUrl;
      if (base == null || cancelled) return;
      try {
        final token = authenticated ? await currentIdToken() : null;
        if (cancelled) return;
        httpClient = http.Client();
        final uri = base.replace(
          path: path,
          queryParameters: (queryParameters == null || queryParameters.isEmpty)
              ? null
              : queryParameters,
        );
        final req = http.Request('GET', uri)
          ..headers['Accept'] = 'text/event-stream';
        if (token != null && token.isNotEmpty) {
          req.headers['Authorization'] = 'Bearer $token';
        }
        final res = await httpClient!.send(req);
        if (cancelled || res.statusCode != 200) {
          httpClient?.close();
          return;
        }
        String currentEvent = 'message';
        lineSub = res.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (cancelled || controller.isClosed) return;
            if (line.isEmpty) {
              currentEvent = 'message';
              return;
            }
            if (line.startsWith(':')) return;
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
              return;
            }
            if (line.startsWith('data:')) {
              final raw = line.substring(5).trim();
              if (raw.isEmpty) return;
              try {
                final parsed = jsonDecode(raw);
                if (parsed is Map<String, dynamic>) {
                  controller.add(
                    AppPlatformSseFrame(event: currentEvent, data: parsed),
                  );
                }
              } catch (_) {}
            }
          },
          onError: (_) {},
          onDone: () {},
        );
      } catch (_) {
        httpClient?.close();
      }
    }

    controller = StreamController<AppPlatformSseFrame>.broadcast(
      onListen: connect,
      onCancel: () {
        cancelled = true;
        lineSub?.cancel();
        httpClient?.close();
      },
    );
    return controller.stream;
  }

  static AppDataApiClient client(String resource) {
    final p = policy;
    final cacheKey = '${p.app.name}:${p.baseUrl}:$resource';
    return _clients.putIfAbsent(
      cacheKey,
      () => AppDataApiClient(
        policy: p,
        resource: resource,
        actorId: currentUid,
        idToken: currentIdToken,
        queueForActor: (actor) => _queues.putIfAbsent(
          '${p.app.name}:$resource:$actor',
          () => HiveReleaseSyncQueue('${p.app.name}:$resource:$actor'),
        ),
      ),
    );
  }
}
