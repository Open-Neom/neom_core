import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../data_backend_policy.dart';
import 'release_sync_queue.dart';

class AppDataApiException implements Exception {
  const AppDataApiException(this.status);
  final int status;
  @override
  String toString() => 'App data API HTTP $status';
}

class AppDataUnavailable implements Exception {
  const AppDataUnavailable();
}

class AppDataWritePending implements Exception {
  const AppDataWritePending(this.operationId);
  final String operationId;
}

enum AppDataReadSource { server, firestore }

/// A session-scoped client for user/profile contracts. Read-only POST /query
/// keeps emails, location and other private filters out of URL access logs.
class AppDataApiClient {
  AppDataApiClient({
    required this.policy,
    required this.resource,
    required this.actorId,
    required this.idToken,
    required this.queueForActor,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    if (!{
      'users',
      'profiles',
      'wallets',
      'tips',
      'casete',
      'ytmusic',
      'itemlists',
      'booking',
      'requests',
      'events',
      'tickets',
      'pos',
      'payments',
      'subscriptions',
    }.contains(resource)) {
      throw ArgumentError('Invalid resource');
    }
  }
  final DataBackendPolicy policy;
  final String resource;
  final String Function() actorId;
  final Future<String?> Function() idToken;
  final ReleaseSyncQueue Function(String actor) queueForActor;
  final http.Client _client;
  Future<void>? _syncing;
  Object? lastSyncError;
  AppDataReadSource? lastReadSource;
  int serverReadCount = 0;
  int firestoreReadCount = 0;

  Future<Map<String, dynamic>> _request(
    String action,
    Map<String, dynamic> body, {
    required String actor,
    required bool private,
    String? operationId,
  }) async {
    if (actor != actorId()) throw StateError('Data session changed');
    if (private && actor.isEmpty) throw const AppDataApiException(401);
    final token = await idToken();
    if (actor != actorId()) throw StateError('Data session changed');
    if (private && (token == null || token.isEmpty)) {
      throw const AppDataApiException(401);
    }
    if (!policy.hasServer) throw const AppDataUnavailable();
    final base = policy.baseUrl!;
    final url = base.replace(
      path:
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}'
          '/v1/apps/${policy.app.name}/$resource/$action',
    );
    http.Response response;
    try {
      response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
              'Idempotency-Key': ?operationId,
            },
            body: jsonEncode(body),
          )
          .timeout(policy.timeout);
    } on TimeoutException {
      throw const AppDataUnavailable();
    } on http.ClientException {
      throw const AppDataUnavailable();
    }
    if (actor != actorId()) throw StateError('Data session changed');
    if ([502, 503, 504].contains(response.statusCode)) {
      throw const AppDataUnavailable();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppDataApiException(response.statusCode);
    }
    final value = jsonDecode(response.body);
    if (value is! Map) throw const FormatException('Expected data response');
    final result = Map<String, dynamic>.from(value);
    if (private && result['actorUid'] != actor) {
      throw StateError('Data response session mismatch');
    }
    return result;
  }

  Future<T> read<T>(
    String operation,
    Map<String, Object?> arguments, {
    T Function(Map<String, dynamic>)? decode,
    FutureOr<T> Function()? fallback,
    Iterable<String> Function(T)? referenceIds,
    bool private = true,
    String audience = 'account',
  }) async {
    final actor = actorId();
    lastReadSource = null;
    // A missing session must never downgrade a private read into a guest read.
    if (private && actor.isEmpty) throw const AppDataApiException(401);
    try {
      Map<String, dynamic> result;
      final allItems = <dynamic>[];
      final seenCursors = <String>{};
      String? cursor;
      do {
        result = await _request(
          'query',
          {
            'operation': operation,
            'arguments': arguments,
            'audience': audience,
            'cursor': ?cursor,
          },
          actor: actor,
          private: private,
        );
        if (result['ready'] == false) throw const AppDataUnavailable();
        final next = result['nextCursor'];
        if (next != null && next is! String) {
          throw const FormatException('Invalid query cursor');
        }
        cursor = next == '' ? null : next as String?;
        if (cursor != null && !seenCursors.add(cursor)) {
          throw const FormatException('Repeated query cursor');
        }
        if (result['items'] is List) {
          allItems.addAll(result['items'] as List);
        } else if (cursor != null) {
          throw const FormatException('Paginated queries require items');
        }
      } while (cursor != null);
      if (result['items'] is List) result['items'] = allItems;
      final value = decode != null ? decode(result) : result as T;
      if (actor != actorId()) throw StateError('Data session changed');
      lastReadSource = AppDataReadSource.server;
      serverReadCount++;
      unawaited(
        flushPending().catchError((Object error) {
          lastSyncError = error;
        }),
      );
      return value;
    } on AppDataUnavailable {
      if (!policy.firebaseFallback || fallback == null) rethrow;
      final value = await Future<T>.sync(fallback);
      if (actor != actorId()) throw StateError('Data session changed');
      lastReadSource = AppDataReadSource.firestore;
      firestoreReadCount++;
      if (policy.syncEnabled && referenceIds != null) {
        try {
          final queue = queueForActor(actor);
          for (final id in referenceIds(value).toSet()) {
            if (id.isEmpty) continue;
            await queue.put('cloud:$id', {
              'operationId': const Uuid().v4(),
              'kind': 'reconcileFirestore',
              'resource': resource,
              'id': id,
              'audience': audience,
              'actor': actor,
            });
          }
        } catch (error) {
          lastSyncError = error;
        }
      }
      return value;
    }
  }

  Future<dynamic> mutate(
    String operation,
    Map<String, Object?> arguments, {
    bool durable = true,
  }) async {
    final actor = actorId();
    if (actor.isEmpty) throw const AppDataApiException(401);
    final operationId = const Uuid().v4();
    final job = {
      'operationId': operationId,
      'kind': operation,
      'resource': resource,
      'arguments': arguments,
      'actor': actor,
    };
    final queue = queueForActor(actor);
    if (durable) await queue.put(operationId, job);
    Map<String, dynamic> result;
    try {
      result = await _sendJob(job, actor);
    } on AppDataUnavailable {
      if (!durable) rethrow;
      throw AppDataWritePending(operationId);
    } on AppDataApiException catch (error) {
      if (error.status >= 500 || [408, 429].contains(error.status)) {
        if (!durable) rethrow;
        throw AppDataWritePending(operationId);
      }
      await queue.remove(operationId, operationId: operationId);
      rethrow;
    }
    await queue.remove(operationId, operationId: operationId);
    return result['value'];
  }

  Future<Map<String, dynamic>> _sendJob(
    Map<String, dynamic> job,
    String actor,
  ) async {
    final publicReconciliation =
        job['kind'] == 'reconcileFirestore' && job['audience'] == 'public';
    final result = await _request(
      'operations',
      job,
      actor: actor,
      private: !publicReconciliation,
      operationId: job['operationId'] as String,
    );
    if (result['acknowledgedOperationId'] != job['operationId']) {
      throw const FormatException('Expected durable operation acknowledgement');
    }
    return result;
  }

  Future<void> flushPending() =>
      _syncing ??= _flush().whenComplete(() => _syncing = null);
  Future<void> _flush() async {
    if (!policy.hasServer || !policy.syncEnabled) return;
    final actor = actorId();
    final queue = queueForActor(actor);
    for (final entry in (await queue.pending()).entries) {
      if (actor != actorId()) return;
      if (entry.value['actor'] != actor ||
          entry.value['resource'] != resource) {
        throw StateError('Outbox scope mismatch');
      }
      await _sendJob(entry.value, actor);
      await queue.remove(
        entry.key,
        operationId: entry.value['operationId'] as String,
      );
    }
    lastSyncError = null;
  }

  void close() => _client.close();
}
