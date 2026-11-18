import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../data_backend_policy.dart';
import '../../domain/model/app_release_item.dart';
import '../../domain/repository/app_release_item_repository.dart';
import 'release_sync_queue.dart';

class ReleaseApiException implements Exception {
  const ReleaseApiException(this.status);
  final int status;
  @override
  String toString() => 'Release API HTTP $status';
}

class ReleaseServerUnavailable implements Exception {
  const ReleaseServerUnavailable();
}

/// Durable acceptance is explicit, never reported as a confirmed remote write.
class ReleaseWritePending implements Exception {
  const ReleaseWritePending(this.operationId);
  final String operationId;
}

class AppReleaseItemApi implements AppReleaseItemRepository {
  AppReleaseItemApi({
    required this.policy,
    required this.firebase,
    required this.queueForActor,
    required this.actorId,
    required this.idToken,
    required this.canWrite,
    this.publicOnly = false,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final DataBackendPolicy policy;
  final AppReleaseItemRepository firebase;
  final ReleaseSyncQueue Function(String actor) queueForActor;
  final String Function() actorId;
  final Future<String?> Function() idToken;
  final bool Function() canWrite;
  final bool publicOnly;
  final http.Client _client;
  Future<void>? _syncing;
  Object? lastSyncError;
  final Set<String> _catalogReconciliationActors = {};

  /// Schedules a server-side incremental cloud reconciliation, not a blind
  /// upload of client snapshots. The server owns cursors and conflict checks.
  Future<void> requestCloudReconciliation() async {
    if (!policy.syncEnabled) return;
    final actor = actorId();
    await queueForActor(actor).put('cloud:catalog', {
      'operationId': const Uuid().v4(),
      'kind': 'reconcileFirestoreCatalog',
      'audience': publicOnly ? 'public' : 'account',
      'actor': actor,
    });
    _catalogReconciliationActors.add(actor);
  }

  Uri _url(String suffix, Map<String, String> query) {
    final base = policy.baseUrl!;
    return base.replace(
      path:
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}'
          '/v1/apps/${policy.app.name}/releases$suffix',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<dynamic> _request(
    String method,
    String suffix, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
    String? operationId,
    String? expectedActor,
  }) async {
    if (!policy.hasServer) throw const ReleaseServerUnavailable();
    final before = actorId();
    if (expectedActor != null && expectedActor != before) {
      throw StateError('Release session changed');
    }
    final token = await idToken();
    if (actorId() != before) throw StateError('Release session changed');
    final request = http.Request(method, _url(suffix, query))
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Idempotency-Key': ?operationId,
      });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    http.Response response;
    try {
      response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(policy.timeout);
    } on TimeoutException {
      throw const ReleaseServerUnavailable();
    } on http.ClientException {
      throw const ReleaseServerUnavailable();
    }
    if (actorId() != before) throw StateError('Release session changed');
    if ([502, 503, 504].contains(response.statusCode)) {
      throw const ReleaseServerUnavailable();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ReleaseApiException(response.statusCode);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  AppReleaseItem _decode(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Expected a release document');
    }
    final data = Map<String, dynamic>.from(value);
    if (data['id'] is! String || (data['id'] as String).isEmpty) {
      throw const FormatException('Release ID is required');
    }
    if (publicOnly &&
        (data['visibility'] != 'public' || data['schemaVersion'] != 1)) {
      throw const FormatException('Expected a public release projection');
    }
    // Store portable media paths; resolve them against this app's configured
    // server rather than embedding localhost into Mongo documents.
    String resolveMedia(String value) {
      if (!value.startsWith('/media/')) return value;
      return policy.baseUrl!.resolve(value).toString();
    }

    for (final key in ['previewUrl', 'streamingUrl', 'imgUrl']) {
      if (data[key] is String) data[key] = resolveMedia(data[key] as String);
    }
    if (data['galleryUrls'] is List) {
      data['galleryUrls'] = (data['galleryUrls'] as List)
          .map((value) => value is String ? resolveMedia(value) : value)
          .toList();
    }
    final item = AppReleaseItem.fromJSON(data);
    if (publicOnly && !item.isPubliclyVisible) {
      throw const FormatException('Release is not published');
    }
    return publicOnly ? item.toPublicProjection() : item;
  }

  Future<void> _remember(Iterable<AppReleaseItem> items, String actor) async {
    if (!policy.syncEnabled || actor != actorId()) return;
    final queue = queueForActor(actor);
    for (final item in items) {
      if (item.id.isEmpty) continue;
      // References only: the server must fetch and authorize the cloud source.
      await queue.put('cloud:${item.id}', {
        'operationId': const Uuid().v4(),
        'kind': 'reconcileFirestore',
        'releaseId': item.id,
        'audience': publicOnly ? 'public' : 'account',
        'actor': actor,
      });
    }
  }

  Future<Map<String, AppReleaseItem>> _read(
    Map<String, String> query,
    Future<Map<String, AppReleaseItem>> Function() fallback,
  ) async {
    final actor = actorId();
    try {
      final map = <String, AppReleaseItem>{};
      String? cursor;
      final seenCursors = <String>{};
      final limit = int.tryParse(query['limit'] ?? '');
      do {
        final result = await _request(
          'GET',
          '',
          query: {
            ...query,
            'audience': publicOnly ? 'public' : 'account',
            'cursor': ?cursor,
            if (limit != null) 'limit': '${limit - map.length}',
          },
        );
        if (result is! Map || result['items'] is! List) {
          throw const FormatException('Expected items');
        }
        for (final item in (result['items'] as List).map(_decode)) {
          if (limit != null && map.length >= limit) break;
          map[item.id] = item;
        }
        final next = result['nextCursor'];
        if (next != null && next is! String) {
          throw const FormatException('Invalid pagination cursor');
        }
        cursor = next == '' ? null : next as String?;
        if (cursor != null && !seenCursors.add(cursor)) {
          throw const FormatException('Repeated pagination cursor');
        }
      } while (cursor != null && (limit == null || map.length < limit));
      if (actor != actorId()) throw StateError('Release session changed');
      unawaited(
        flushPending().catchError((Object error) {
          lastSyncError = error;
        }),
      );
      return map;
    } on ReleaseServerUnavailable {
      if (!policy.firebaseFallback) rethrow;
      final result = await fallback();
      if (actor != actorId()) throw StateError('Release session changed');
      try {
        await _remember(result.values, actor);
      } catch (error) {
        lastSyncError = error;
      }
      return result;
    }
  }

  @override
  Future<AppReleaseItem> retrieve(String releaseItemId) async {
    if (releaseItemId.isEmpty) return AppReleaseItem();
    final items = await retrieveFromList([releaseItemId]);
    return items[releaseItemId] ?? AppReleaseItem();
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveFromList(
    List<String> releaseItemIds,
  ) {
    if (releaseItemIds.isEmpty) return Future.value({});
    return _read({
      'ids': jsonEncode(releaseItemIds),
    }, () => firebase.retrieveFromList(releaseItemIds));
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveAll({
    bool forceRefresh = false,
  }) => _retrieveAll(forceRefresh);
  Future<Map<String, AppReleaseItem>> _retrieveAll(bool forceRefresh) async {
    if (forceRefresh || !_catalogReconciliationActors.contains(actorId())) {
      try {
        await requestCloudReconciliation();
      } catch (error) {
        lastSyncError = error;
      }
    }
    return _read({
      'forceRefresh': '$forceRefresh',
    }, () => firebase.retrieveAll(forceRefresh: forceRefresh));
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveByCategory(
    String category, {
    int limit = 30,
  }) => category.isEmpty || limit <= 0
      ? Future.value({})
      : _read({
          'category': category,
          'limit': '$limit',
        }, () => firebase.retrieveByCategory(category, limit: limit));
  @override
  Future<Map<String, AppReleaseItem>> retrieveByOwner(
    String ownerEmail, {
    int limit = 30,
  }) {
    // Preserve the existing public-catalogue restriction on owner email queries.
    if (publicOnly || ownerEmail.isEmpty || limit <= 0) return Future.value({});
    return _read({
      'ownerEmail': ownerEmail,
      'limit': '$limit',
    }, () => firebase.retrieveByOwner(ownerEmail, limit: limit));
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveByLanguage(
    String language, {
    int limit = 30,
  }) => language.isEmpty || limit <= 0
      ? Future.value({})
      : _read({
          'language': language,
          'limit': '$limit',
        }, () => firebase.retrieveByLanguage(language, limit: limit));
  @override
  Future<AppReleaseItem?> getBySlug(String slug) async {
    if (slug.isEmpty) return null;
    final items = await _read({'slug': slug}, () async {
      final item = await firebase.getBySlug(slug);
      return item == null ? {} : {item.id: item};
    });
    return items.values.firstOrNull;
  }

  @override
  Future<bool> exists(String releaseItemId) async =>
      (await retrieve(releaseItemId)).id.isNotEmpty;

  Future<void> _write(String kind, Map<String, dynamic> payload) async {
    final actor = actorId();
    if (actor.isEmpty || !canWrite()) throw const ReleaseApiException(403);
    final operationId = const Uuid().v4();
    final job = {
      'operationId': operationId,
      'kind': kind,
      'payload': payload,
      'actor': actor,
    };
    final queue = queueForActor(actor);
    // Persist before sending, including for ambiguous network failures.
    await queue.put(operationId, job);
    try {
      await _sendJob(job, actor);
    } on ReleaseServerUnavailable {
      throw ReleaseWritePending(operationId);
    } on ReleaseApiException catch (error) {
      if (error.status >= 500 || error.status == 408 || error.status == 429) {
        throw ReleaseWritePending(operationId);
      }
      await queue.remove(operationId, operationId: operationId);
      rethrow;
    }
    await queue.remove(operationId, operationId: operationId);
  }

  Future<void> _sendJob(Map<String, dynamic> job, String actor) async {
    final result = await _request(
      'POST',
      '/operations',
      body: job,
      operationId: job['operationId'] as String,
      expectedActor: actor,
    );
    if (result is! Map ||
        result['acknowledgedOperationId'] != job['operationId']) {
      throw const FormatException(
        'Expected a matching durable operation acknowledgement',
      );
    }
  }

  /// FIFO per actor. The endpoint must deduplicate IDs and validate cloud data.
  Future<void> flushPending() =>
      _syncing ??= _flush().whenComplete(() => _syncing = null);
  Future<void> _flush() async {
    if (!policy.hasServer || !policy.syncEnabled) return;
    final actor = actorId();
    final queue = queueForActor(actor);
    for (final entry in (await queue.pending()).entries) {
      if (actorId() != actor) return;
      if (entry.value['actor'] != actor) {
        throw StateError('Outbox actor mismatch');
      }
      if (![
            'reconcileFirestore',
            'reconcileFirestoreCatalog',
          ].contains(entry.value['kind']) &&
          !canWrite()) {
        return;
      }
      await _sendJob(entry.value, actor);
      await queue.remove(
        entry.key,
        operationId: entry.value['operationId'] as String,
      );
    }
    lastSyncError = null;
  }

  @override
  Future<void> insert(AppReleaseItem releaseItem) {
    if (releaseItem.id.isEmpty) releaseItem.id = const Uuid().v4();
    return _write('upsert', {'item': releaseItem.toJSON()});
  }

  @override
  Future<bool> remove(AppReleaseItem releaseItem) async {
    await _write('remove', {'releaseId': releaseItem.id});
    return true;
  }

  @override
  Future<bool> addBoughtUser({
    required String releaseItemId,
    required String userId,
  }) async {
    await _write('addBoughtUser', {
      'releaseId': releaseItemId,
      'userId': userId,
    });
    return true;
  }

  void close() => _client.close();
}
