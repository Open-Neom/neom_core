import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neom_core/data/api/app_release_item_api.dart';
import 'package:neom_core/data/api/release_sync_queue.dart';
import 'package:neom_core/data_backend_policy.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/repository/app_release_item_repository.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/release_status.dart';

class MemoryQueue implements ReleaseSyncQueue {
  final jobs = <String, Map<String, dynamic>>{};
  @override
  Future<void> put(String key, Map<String, dynamic> job) async =>
      jobs[key] = job;
  @override
  Future<Map<String, Map<String, dynamic>>> pending() async => Map.of(jobs);
  @override
  Future<void> remove(String key, {String? operationId}) async {
    if (operationId == null || jobs[key]?['operationId'] == operationId) {
      jobs.remove(key);
    }
  }
}

class Cloud extends Fake implements AppReleaseItemRepository {
  int reads = 0;
  final item = AppReleaseItem(id: 'cloud', status: ReleaseStatus.publish);
  @override
  Future<Map<String, AppReleaseItem>> retrieveAll({
    bool forceRefresh = false,
  }) async {
    reads++;
    return {item.id: item};
  }

  @override
  Future<Map<String, AppReleaseItem>> retrieveFromList(List<String> ids) async {
    reads++;
    return {item.id: item};
  }
}

void main() {
  final serverItem = AppReleaseItem(
    id: 'server',
    status: ReleaseStatus.publish,
    ownerEmail: 'private@example.org',
  );
  late Cloud cloud;
  late Map<String, MemoryQueue> queues;
  late String actor;
  AppReleaseItemApi create(
    http.Client client, {
    bool publicOnly = false,
    bool fallback = true,
    bool configured = true,
  }) => AppReleaseItemApi(
    policy: DataBackendPolicy(
      app: AppInUse.g,
      enabled: true,
      baseUrl: configured ? Uri.parse('https://data.example.org') : null,
      firebaseFallback: fallback,
    ),
    firebase: cloud,
    client: client,
    publicOnly: publicOnly,
    queueForActor: (id) => queues.putIfAbsent(id, MemoryQueue.new),
    actorId: () => actor,
    idToken: () async => 'session-token',
    canWrite: () => actor.isNotEmpty,
  );
  setUp(() {
    cloud = Cloud();
    queues = {};
    actor = 'alice';
  });

  test(
    'all apps except explicitly enabled Gigmeout/Itzli retain Firestore',
    () {
      for (final app in AppInUse.values) {
        final p = DataBackendPolicy.fromProperties(app, {
          'dataBackend': {
            'enabled': true,
            'baseUrl': 'https://data.example.org',
          },
        });
        expect(p.enabled, app == AppInUse.g || app == AppInUse.i);
        expect(DataBackendPolicy.fromProperties(app, {}).enabled, false);
      }
    },
  );
  test(
    'each app has an independent endpoint; missing/invalid endpoint cannot send',
    () {
      final p = DataBackendPolicy.fromProperties(AppInUse.g, {
        'dataBackend': {'enabled': true, 'baseUrl': 'file:///tmp/db'},
      });
      expect(p.hasServer, false);
      final q = DataBackendPolicy.fromProperties(AppInUse.i, {
        'dataBackend': {
          'enabled': true,
          'baseUrl': 'https://mini.example.org/data',
          'timeoutMs': 1,
        },
      });
      expect(q.baseUrl!.host, 'mini.example.org');
      expect(q.timeout.inMilliseconds, 500);
    },
  );
  test(
    'server is preferred, with app namespace and current identity token',
    () async {
      final api = create(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/apps/g/releases');
          expect(request.headers['Authorization'], 'Bearer session-token');
          return http.Response(
            jsonEncode({
              'items': [serverItem.toJSON()],
            }),
            200,
          );
        }),
      );
      expect((await api.retrieve('server')).id, 'server');
      expect(cloud.reads, 0);
    },
  );
  test(
    'local media URLs resolve against configured API while cloud URLs remain intact',
    () async {
      final api = create(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'items': [
                {
                  ...serverItem.toJSON(),
                  'previewUrl': '/media/audio.mp3',
                  'streamingUrl': '/media/audio.wav',
                  'imgUrl': '/media/cover.jpg',
                  'galleryUrls': [
                    '/media/other.png',
                    'https://images.example.test/cloud.jpg',
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      );
      final item = await api.retrieve('server');
      expect(item.previewUrl, 'https://data.example.org/media/audio.mp3');
      expect(item.streamingUrl, 'https://data.example.org/media/audio.wav');
      expect(item.imgUrl, 'https://data.example.org/media/cover.jpg');
      expect(item.galleryUrls, [
        'https://data.example.org/media/other.png',
        'https://images.example.test/cloud.jpg',
      ]);
    },
  );
  test(
    'unconfigured server preserves cloud reads and durable reconciliation references',
    () async {
      final api = create(
        MockClient((_) async => throw StateError('Network must not be used')),
        configured: false,
      );
      expect((await api.retrieveAll()).keys, ['cloud']);
      expect(cloud.reads, 1);
      expect(
        queues['alice']!.jobs.values.map((j) => j['kind']),
        containsAll(['reconcileFirestoreCatalog', 'reconcileFirestore']),
      );
      expect(
        queues['alice']!.jobs.values.any((j) => j.containsKey('payload')),
        false,
      );
    },
  );
  test(
    'transport failure uses cloud; disabling fallback propagates it',
    () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      expect((await create(client).retrieveFromList(['cloud'])).keys, [
        'cloud',
      ]);
      await expectLater(
        create(client, fallback: false).retrieve('cloud'),
        throwsA(isA<ReleaseServerUnavailable>()),
      );
      expect(cloud.reads, 1);
    },
  );
  for (final status in [401, 403, 404, 409, 429, 500]) {
    test(
      'HTTP $status does not conceal server errors by consulting Firebase',
      () async {
        final api = create(
          MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(
          api.retrieve('server'),
          throwsA(isA<ReleaseApiException>()),
        );
        expect(cloud.reads, 0);
      },
    );
  }
  test(
    'an empty authoritative server result never resurrects a cloud document',
    () async {
      final api = create(
        MockClient((_) async => http.Response('{"items":[]}', 200)),
      );
      expect((await api.retrieve('deleted')).id, isEmpty);
      expect(cloud.reads, 0);
    },
  );
  test(
    'public responses require projection metadata and strip account fields',
    () async {
      final api = create(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'items': [
                {
                  ...serverItem.toJSON(),
                  'visibility': 'public',
                  'schemaVersion': 1,
                },
              ],
            }),
            200,
          ),
        ),
        publicOnly: true,
      );
      expect((await api.retrieve('server')).ownerEmail, isEmpty);
      final invalid = create(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'items': [serverItem.toJSON()],
            }),
            200,
          ),
        ),
        publicOnly: true,
      );
      await expectLater(invalid.retrieve('server'), throwsFormatException);
      expect(cloud.reads, 0);
    },
  );
  test(
    'server acknowledgement removes a persisted write with the same operation ID',
    () async {
      final api = create(
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(queues['alice']!.jobs, isNotEmpty);
          expect(body['operationId'], request.headers['Idempotency-Key']);
          return http.Response(
            jsonEncode({'acknowledgedOperationId': body['operationId']}),
            200,
          );
        }),
      );
      final item = AppReleaseItem();
      await api.insert(item);
      expect(item.id, isNotEmpty);
      expect(queues['alice']!.jobs, isEmpty);
      expect(cloud.reads, 0);
    },
  );
  test(
    'ambiguous writes remain pending and replay with original ID, never cloud writes',
    () async {
      var offline = true;
      final seen = <String>[];
      final api = create(
        MockClient((request) async {
          seen.add(request.headers['Idempotency-Key']!);
          if (offline) throw http.ClientException('response lost');
          return http.Response(
            jsonEncode({'acknowledgedOperationId': seen.last}),
            200,
          );
        }),
      );
      await expectLater(
        api.insert(AppReleaseItem(id: 'new')),
        throwsA(isA<ReleaseWritePending>()),
      );
      expect(queues['alice']!.jobs.length, 1);
      offline = false;
      await api.flushPending();
      expect(seen.length, 2);
      expect(seen.first, seen.last);
      expect(queues['alice']!.jobs, isEmpty);
    },
  );
  test(
    'HTTP 500 mutation stays pending; HTTP 403 mutation is not replayed',
    () async {
      final pending = create(MockClient((_) async => http.Response('{}', 500)));
      await expectLater(
        pending.remove(AppReleaseItem(id: 'x')),
        throwsA(isA<ReleaseWritePending>()),
      );
      expect(queues['alice']!.jobs.length, 1);
      queues['alice']!.jobs.clear();
      final rejected = create(
        MockClient((_) async => http.Response('{}', 403)),
      );
      await expectLater(
        rejected.remove(AppReleaseItem(id: 'x')),
        throwsA(isA<ReleaseApiException>()),
      );
      expect(queues['alice']!.jobs, isEmpty);
    },
  );
  test('a wrong acknowledgement never removes a pending operation', () async {
    final api = create(
      MockClient(
        (_) async => http.Response('{"acknowledgedOperationId":"wrong"}', 200),
      ),
    );
    await expectLater(
      api.insert(AppReleaseItem(id: 'x')),
      throwsFormatException,
    );
    expect(queues['alice']!.jobs.length, 1);
  });
  test(
    'account change during an in-flight request never exposes its result',
    () async {
      final api = create(
        MockClient((_) async {
          actor = 'bob';
          return http.Response(
            jsonEncode({
              'items': [serverItem.toJSON()],
            }),
            200,
          );
        }),
      );
      await expectLater(api.retrieve('server'), throwsStateError);
      expect(cloud.reads, 0);
    },
  );
  test('a different actor never flushes another account outbox', () async {
    final api = create(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      api.insert(AppReleaseItem(id: 'x')),
      throwsA(isA<ReleaseWritePending>()),
    );
    actor = 'bob';
    await api.flushPending();
    expect(queues['alice']!.jobs.length, 1);
    expect(queues['bob']!.jobs, isEmpty);
  });

  test(
    'Hive outbox survives reopening, isolates apps/actors, and protects newer jobs',
    () async {
      final dir = await Directory.systemTemp.createTemp('neom-release-outbox-');
      Hive.init(dir.path);
      try {
        final queue = HiveReleaseSyncQueue('g:alice');
        await queue.put('cloud:x', {
          'operationId': 'one',
          'kind': 'reconcileFirestore',
        });
        await Hive.close();
        final restored = HiveReleaseSyncQueue('g:alice');
        expect((await restored.pending())['cloud:x']!['operationId'], 'one');
        expect(await HiveReleaseSyncQueue('i:alice').pending(), isEmpty);
        expect(await HiveReleaseSyncQueue('g:bob').pending(), isEmpty);
        await restored.put('cloud:x', {'operationId': 'two'});
        await restored.remove('cloud:x', operationId: 'one');
        expect((await restored.pending())['cloud:x']!['operationId'], 'two');
      } finally {
        await Hive.close();
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'server pagination preserves the full catalogue and rejects cursor loops',
    () async {
      final api = create(
        MockClient((request) async {
          final second = request.url.queryParameters['cursor'] == 'page2';
          return http.Response(
            jsonEncode({
              'items': [
                (second
                        ? AppReleaseItem(
                            id: 'second',
                            status: ReleaseStatus.publish,
                          )
                        : serverItem)
                    .toJSON(),
              ],
              if (!second) 'nextCursor': 'page2',
            }),
            200,
          );
        }),
      );
      expect((await api.retrieveFromList(['server', 'second'])).keys, [
        'server',
        'second',
      ]);
      final loop = create(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'items': [], 'nextCursor': 'same'}),
            200,
          ),
        ),
      );
      await expectLater(loop.retrieveFromList(['x']), throwsFormatException);
      expect(cloud.reads, 0);
    },
  );
  test('empty filters never turn into an unbounded server query', () async {
    final api = create(
      MockClient((_) async => throw StateError('Unexpected network request')),
    );
    expect(await api.retrieveByCategory(''), isEmpty);
    expect(await api.retrieveByLanguage('es', limit: 0), isEmpty);
    expect(await api.retrieveByOwner(''), isEmpty);
    expect(await api.getBySlug(''), isNull);
  });
}
