import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/api/app_data_api_client.dart';
import 'package:neom_core/data/api/app_profile_api.dart';
import 'package:neom_core/data/api/app_user_api.dart';
import 'package:neom_core/data/api/release_sync_queue.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
import 'package:neom_core/data_backend_policy.dart';
import 'package:neom_core/domain/model/account_load_exception.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/repository/account_profiles_reader.dart';
import 'package:neom_core/domain/repository/account_repository.dart';
import 'package:neom_core/domain/repository/profile_directory_repository.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

class _Queue implements ReleaseSyncQueue {
  final jobs = <String, Map<String, dynamic>>{};
  @override
  Future<void> put(String key, Map<String, dynamic> job) async {
    jobs[key] = job;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> pending() async => Map.of(jobs);
  @override
  Future<void> remove(String key, {String? operationId}) async {
    if (operationId == null || jobs[key]?['operationId'] == operationId) {
      jobs.remove(key);
    }
  }
}

class _Accounts extends Fake implements AccountRepository {
  int reads = 0;
  bool fail = false;
  bool missing = false;
  AppUser get value => AppUser(
    id: 'LegacyCase',
    email: 'owner@example.test',
    profiles: [AppProfile(id: 'own', name: 'Cloud owner')],
  );
  @override
  Future<AppUser> getById(
    String id, {
    bool getProfileFeatures = false,
    bool throwOnError = false,
  }) async {
    expect(throwOnError, true);
    reads++;
    if (fail) throw const AccountLoadException();
    return missing ? AppUser() : value;
  }

  @override
  Future<AppUser?> getByEmail(
    String email, {
    bool getProfile = false,
    bool getProfileFeatures = false,
    bool throwOnError = false,
  }) async {
    expect(throwOnError, true);
    reads++;
    if (fail) throw const AccountLoadException();
    return missing ? null : value;
  }

  @override
  Future<List<AppUser>> getAll() async {
    reads++;
    return [value];
  }
}

class _Profiles extends Fake implements ProfileDirectoryRepository {
  int reads = 0;
  @override
  Future<AppProfile> retrieve(String id) async {
    reads++;
    return AppProfile(
      id: id,
      name: 'Cloud public',
      phoneNumber: 'private',
      directoryVisible: true,
      showPhone: false,
    )..email = 'private@example.test';
  }

  @override
  Future<Map<String, AppProfile>> retrieveAllProfiles({
    int limit = 0,
    bool forceRefresh = false,
  }) async {
    final p = await retrieve('public');
    return {p.id: p};
  }
}

class _AccountsWithProfiles extends _Accounts implements AccountProfilesReader {
  int profileLists = 0;
  bool failListing = false;

  @override
  Future<List<AppProfile>> getOwnedProfiles(String userId) async {
    expect(userId, 'LegacyCase');
    profileLists++;
    if (failListing) throw const AccountLoadException();
    return [
      AppProfile(id: 'own', name: 'Selected owner'),
      AppProfile(id: 'another-own', name: 'Another owner'),
    ];
  }
}

void main() {
  late String actor;
  late String? token;
  late Map<String, _Queue> queues;
  late _Accounts cloud;
  late _Profiles cloudProfiles;
  Map<String, dynamic> userJson({bool profiles = true}) => {
    'id': 'LegacyCase',
    'email': 'owner@example.test',
    'name': 'Server owner',
    'currentProfileId': 'own',
    if (profiles)
      'profiles': [
        {'id': 'own', 'name': 'Own private', 'address': 'private'},
      ],
  };
  Map<String, dynamic> profileJson() => {
    'id': 'public',
    'name': 'Public artist',
    'visibility': 'public',
    'schemaVersion': 1,
    'directoryVisible': true,
    'showPhone': false,
    'phoneNumber': 'hidden',
    'email': 'private@example.test',
    'address': 'private',
    'position': {'latitude': 1.0, 'longitude': 2.0, 'is_mocked': false},
  };
  AppDataApiClient transport(
    String resource,
    Future<http.Response> Function(http.Request) handler, {
    bool fallback = true,
  }) => AppDataApiClient(
    policy: DataBackendPolicy(
      app: AppInUse.g,
      enabled: true,
      baseUrl: Uri.parse('https://data.example.test'),
      firebaseFallback: fallback,
    ),
    resource: resource,
    actorId: () => actor,
    idToken: () async => token,
    queueForActor: (id) => queues.putIfAbsent('$resource:$id', _Queue.new),
    client: MockClient(handler),
  );
  AppUserApi users(Future<http.Response> Function(http.Request) handler) =>
      AppUserApi(client: transport('users', handler), firebase: cloud);
  AppProfileApi profiles(
    Future<http.Response> Function(http.Request) handler, {
    bool Function()? publicReader,
  }) => AppProfileApi(
    client: transport('profiles', handler),
    firebase: cloudProfiles,
    accounts: cloud,
    publicReader: publicReader ?? () => true,
  );
  http.Response accountResponse(
    List<dynamic> items, {
    bool authoritative = true,
  }) => http.Response(
    jsonEncode({
      'actorUid': actor,
      'items': items,
      'authoritative': authoritative,
    }),
    200,
  );
  setUp(() {
    actor = 'authUid';
    token = 'auth-token';
    queues = {};
    cloud = _Accounts();
    cloudProfiles = _Profiles();
    AppConfig.instance.appInUse = AppInUse.g;
    AppConfig.instance.isGuestMode = true;
  });
  tearDown(() {
    AppConfig.instance.appInUse = AppInUse.o;
  });

  test(
    'login loads the private account and owned profile from the server',
    () async {
      final api = users((request) async {
        expect(request.url.path, '/v1/apps/g/users/query');
        expect(request.url.query, isEmpty);
        expect(request.headers['Authorization'], 'Bearer auth-token');
        expect(jsonDecode(request.body)['operation'], 'getByEmail');
        return accountResponse([userJson()]);
      });
      final controller = UserController(userFirestore: api);
      await controller.setUserByEmail('owner@example.test');
      expect(controller.user.id, 'LegacyCase');
      expect(controller.profile.name, 'Own private');
      expect(controller.profile.address, 'private');
      expect(controller.isNewUser, false);
      expect(cloud.reads, 0);
      expect(api.client.lastReadSource, AppDataReadSource.server);
    },
  );
  test(
    'offline account reads use strict Firestore and queue references only',
    () async {
      final api = users((_) async => throw http.ClientException('offline'));
      final controller = UserController(userFirestore: api);
      await controller.setUserByEmail('owner@example.test');
      expect(controller.profile.name, 'Cloud owner');
      expect(controller.isNewUser, false);
      expect(api.client.lastReadSource, AppDataReadSource.firestore);
      final job = queues['users:authUid']!.jobs.values.single;
      expect(job['id'], 'LegacyCase');
      expect(job.containsKey('arguments'), false);
      expect(job.containsKey('payload'), false);
    },
  );
  test(
    'an unseeded local account never sends an existing user into registration',
    () async {
      final api = users((_) async => accountResponse([], authoritative: false));
      final controller = UserController(userFirestore: api);
      await controller.setUserByEmail('owner@example.test');
      expect(cloud.reads, 1);
      expect(controller.isNewUser, false);
    },
  );
  test(
    'only authoritative successful absence can identify a new account',
    () async {
      final api = users((_) async => accountResponse([]));
      final controller = UserController(userFirestore: api);
      await controller.setUserByEmail('owner@example.test');
      expect(cloud.reads, 0);
      expect(controller.isNewUser, true);
    },
  );
  for (final status in [401, 403, 404, 409, 500]) {
    test(
      'account HTTP $status is an error, not missing data or a cloud fallback',
      () async {
        final api = users((_) async => http.Response('{}', status));
        final controller = UserController(userFirestore: api);
        await expectLater(
          controller.setUserByEmail('owner@example.test'),
          throwsA(isA<AccountLoadException>()),
        );
        expect(controller.isNewUser, false);
        expect(cloud.reads, 0);
      },
    );
  }
  test(
    'cloud permission/availability failure is never a new account',
    () async {
      cloud.fail = true;
      final api = users((_) async => throw http.ClientException('offline'));
      final controller = UserController(userFirestore: api);
      await expectLater(
        controller.setUserById('LegacyCase'),
        throwsA(isA<AccountLoadException>()),
      );
      expect(controller.isNewUser, false);
    },
  );
  test('case-sensitive legacy document IDs are preserved', () async {
    final api = users((request) async {
      expect(jsonDecode(request.body)['arguments']['userId'], 'LegacyCase');
      return accountResponse([userJson()]);
    });
    expect((await api.getById('LegacyCase')).id, 'LegacyCase');
  });
  test(
    'duplicate accounts or incomplete owned profiles do not become registrations',
    () async {
      for (final items in [
        [userJson(), userJson()],
        [userJson(profiles: false)],
      ]) {
        final api = users((_) async => accountResponse(items));
        final controller = UserController(userFirestore: api);
        await expectLater(
          controller.setUserByEmail('owner@example.test'),
          throwsA(isA<AccountLoadException>()),
        );
        expect(controller.isNewUser, false);
      }
    },
  );
  test(
    'anonymous private reads are rejected before any HTTP or cloud read',
    () async {
      actor = '';
      token = null;
      final api = users((_) async => throw StateError('Unexpected request'));
      await expectLater(
        api.getById('LegacyCase'),
        throwsA(isA<AppDataApiException>()),
      );
      expect(cloud.reads, 0);
    },
  );
  test(
    'a mismatched response actor cannot expose another session data',
    () async {
      final api = users(
        (_) async => http.Response(
          jsonEncode({
            'actorUid': 'other',
            'items': [userJson()],
          }),
          200,
        ),
      );
      await expectLater(api.getById('LegacyCase'), throwsStateError);
      expect(cloud.reads, 0);
    },
  );
  test(
    'logout during a request discards the account result without fallback',
    () async {
      final api = users((_) async {
        final response = accountResponse([userJson()]);
        actor = '';
        return response;
      });
      await expectLater(api.getById('LegacyCase'), throwsStateError);
      expect(cloud.reads, 0);
    },
  );
  test(
    'public profile server data is projected before reaching controllers',
    () async {
      actor = '';
      token = null;
      final api = profiles(
        (_) async => http.Response(
          jsonEncode({
            'items': [profileJson()],
          }),
          200,
        ),
      );
      final p = await api.retrieve('public');
      expect(p.email, isEmpty);
      expect(p.address, isEmpty);
      expect(p.position, isNull);
      expect(p.phoneNumber, isEmpty);
      expect(cloudProfiles.reads, 0);
    },
  );
  test(
    'private or hidden profiles cannot pass as public server data',
    () async {
      final raw = profileJson()..['directoryVisible'] = false;
      final api = profiles(
        (_) async => http.Response(
          jsonEncode({
            'items': [raw],
          }),
          200,
        ),
      );
      await expectLater(api.retrieve('public'), throwsFormatException);
      expect(cloudProfiles.reads, 0);
    },
  );
  test('offline public profile fallback is redacted too', () async {
    final api = profiles((_) async => throw http.ClientException('offline'));
    final p = await api.retrieve('public');
    expect(p.name, 'Cloud public');
    expect(p.email, isEmpty);
    expect(p.phoneNumber, isEmpty);
    expect(api.client.lastReadSource, AppDataReadSource.firestore);
  });
  test(
    'owned-profile fallback uses the owner account, never the public directory',
    () async {
      final api = profiles((_) async => throw http.ClientException('offline'));
      final items = await api.retrieveByUserId('LegacyCase');
      expect(items.single.name, 'Cloud owner');
      expect(cloud.reads, 1);
      expect(cloudProfiles.reads, 0);
    },
  );
  test('owned-profile fallback prefers the complete optional account listing', () async {
    final reader = _AccountsWithProfiles();
    cloud = reader;
    final api = profiles((_) async => throw http.ClientException('offline'));
    final items = await api.retrieveByUserId('LegacyCase');
    expect(items.map((profile) => profile.id), ['own', 'another-own']);
    expect(reader.profileLists, 1);
    expect(reader.reads, 0);
    expect(cloudProfiles.reads, 0);
    expect(api.client.lastReadSource, AppDataReadSource.firestore);
  });
  test('failed owned-profile capability does not downgrade to a partial bootstrap', () async {
    final reader = _AccountsWithProfiles()..failListing = true;
    cloud = reader;
    final api = profiles((_) async => throw http.ClientException('offline'));
    await expectLater(api.retrieveByUserId('LegacyCase'), throwsA(isA<AccountLoadException>()));
    expect(reader.profileLists, 1);
    expect(reader.reads, 0);
    expect(cloudProfiles.reads, 0);
  });
  test(
    'profile audience transition discards an in-flight private directory read',
    () async {
      var public = false;
      final api = profiles((_) async {
        public = true;
        return http.Response(
          jsonEncode({
            'actorUid': actor,
            'items': [profileJson()],
          }),
          200,
        );
      }, publicReader: () => public);
      await expectLater(api.retrieve('public'), throwsStateError);
    },
  );
  test(
    'profile insert preserves ID and requires matching durable acknowledgement',
    () async {
      final api = profiles((request) async {
        final body = jsonDecode(request.body);
        final id = body['arguments']['profile']['id'];
        return http.Response(
          jsonEncode({
            'actorUid': actor,
            'acknowledgedOperationId': body['operationId'],
            'value': id,
          }),
          200,
        );
      });
      final p = AppProfile(name: 'New');
      final id = await api.insert('LegacyCase', p);
      expect(id, p.id);
      expect(id, isNotEmpty);
      expect(queues['profiles:authUid']!.jobs, isEmpty);
    },
  );
  test(
    'atomic account creation uses one operation with stable account/profile IDs',
    () async {
      final api = users((request) async {
        final body = jsonDecode(request.body);
        expect(body['kind'], 'insertWithProfile');
        expect(body['arguments']['user']['id'], 'AuthCase');
        final id = body['arguments']['profile']['id'];
        return http.Response(
          jsonEncode({
            'actorUid': actor,
            'acknowledgedOperationId': body['operationId'],
            'value': id,
          }),
          200,
        );
      });
      final user = AppUser(id: 'AuthCase');
      final p = AppProfile(name: 'New');
      expect(await api.insertWithProfile(user, p), p.id);
      expect(user.currentProfileId, p.id);
    },
  );
  test(
    'ambiguous mutations replay the original operation ID without cloud writes',
    () async {
      var offline = true;
      final seen = <String>[];
      final api = users((request) async {
        final body = jsonDecode(request.body);
        seen.add(body['operationId'] as String);
        if (offline) throw http.ClientException('response lost');
        return http.Response(
          jsonEncode({
            'actorUid': actor,
            'acknowledgedOperationId': body['operationId'],
            'value': true,
          }),
          200,
        );
      });
      await expectLater(
        api.updatePhotoUrl('LegacyCase', 'https://image.test/photo'),
        throwsA(isA<AppDataWritePending>()),
      );
      offline = false;
      await api.client.flushPending();
      expect(seen.first, seen.last);
      expect(queues['users:authUid']!.jobs, isEmpty);
      expect(cloud.reads, 0);
    },
  );
  test('Spotify credentials are not persisted in the retry outbox', () async {
    final api = users((_) async => throw http.ClientException('offline'));
    await expectLater(
      api.updateSpotifyToken('LegacyCase', 'secret'),
      throwsA(isA<AppDataUnavailable>()),
    );
    expect(queues.values.expand((q) => q.jobs.values), isEmpty);
  });
  test(
    'real HTTP account request authenticates and falls back after server shutdown',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = AppDataApiClient(
        policy: DataBackendPolicy(
          app: AppInUse.g,
          enabled: true,
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        ),
        resource: 'users',
        actorId: () => actor,
        idToken: () async => token,
        queueForActor: (id) => queues.putIfAbsent('users:$id', _Queue.new),
      );
      addTearDown(client.close);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        expect(request.uri.path, '/v1/apps/g/users/query');
        expect(request.headers.value('Authorization'), 'Bearer $token');
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        expect(body['operation'], 'getById');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'actorUid': actor,
            'items': [userJson()],
          }),
        );
        await request.response.close();
      });
      final api = AppUserApi(client: client, firebase: cloud);
      expect((await api.getById('LegacyCase')).profiles.single.id, 'own');
      expect(client.lastReadSource, AppDataReadSource.server);
      await client.flushPending();
      await server.close(force: true);
      expect(
        (await api.getById('LegacyCase')).profiles.single.name,
        'Cloud owner',
      );
      expect(client.lastReadSource, AppDataReadSource.firestore);
      expect(
        queues['users:authUid']!.jobs.values.single['kind'],
        'reconcileFirestore',
      );
    },
  );
  test('query pagination merges pages and rejects repeated cursors', () async {
    final api = profiles((request) async {
      final cursor = jsonDecode(request.body)['cursor'];
      return http.Response(
        jsonEncode({
          'items': [
            {...profileJson(), 'id': cursor == null ? 'first' : 'second'},
          ],
          if (cursor == null) 'nextCursor': 'p2',
        }),
        200,
      );
    });
    expect((await api.retrieveAllProfiles()).keys, ['first', 'second']);
    final loop = profiles(
      (_) async => http.Response('{"items":[],"nextCursor":"same"}', 200),
    );
    await expectLater(loop.retrieveAllProfiles(), throwsFormatException);
  });
}
