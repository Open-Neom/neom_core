import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/app_release_item_firestore.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

typedef _Read =
    Future<QuerySnapshot<Map<String, dynamic>>> Function(
      Query<Map<String, dynamic>> query,
      GetOptions? options,
    );

class _ControlledFirestore extends Fake implements FirebaseFirestore {
  final FakeFirebaseFirestore delegate = FakeFirebaseFirestore();
  _Read? nextRead;
  final cursors = <String?>[];

  void failNext(Object error) {
    nextRead = (_, _) => Future.error(error);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> read(
    Query<Map<String, dynamic>> query,
    GetOptions? options,
    String? cursor,
  ) {
    cursors.add(cursor);
    final action = nextRead;
    nextRead = null;
    return action == null ? query.get(options) : action(query, options);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _QueryProxy(delegate.collection(path), this);
}

// A test-only SDK proxy delegates queries and injects failures at their get.
// ignore: subtype_of_sealed_class
class _QueryProxy extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final Query<Map<String, dynamic>> delegate;
  final _ControlledFirestore control;
  final String? cursor;
  final int? maxLimit;
  _QueryProxy(this.delegate, this.control, [this.cursor, this.maxLimit]);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get) {
      final options = invocation.positionalArguments.isEmpty
          ? null
          : invocation.positionalArguments.first as GetOptions?;
      // Firestore applies a cursor before the limit regardless of builder
      // call order. Normalize that order for the sequential in-memory fake.
      return control.read(
        maxLimit == null ? delegate : delegate.limit(maxLimit!),
        options,
        cursor,
      );
    }
    if (invocation.memberName == #limit) {
      return _QueryProxy(
        delegate,
        control,
        cursor,
        invocation.positionalArguments.first as int,
      );
    }
    final Function function;
    String? nextCursor = cursor;
    switch (invocation.memberName) {
      case #where:
        function = delegate.where;
      case #orderBy:
        function = delegate.orderBy;
      case #startAfterDocument:
        function = delegate.startAfterDocument;
        nextCursor =
            (invocation.positionalArguments.first as DocumentSnapshot).id;
      default:
        return super.noSuchMethod(invocation);
    }
    final query =
        Function.apply(
              function,
              invocation.positionalArguments,
              invocation.namedArguments,
            )
            as Query<Map<String, dynamic>>;
    return _QueryProxy(query, control, nextCursor, maxLimit);
  }
}

void main() {
  late _ControlledFirestore firestore;
  final config = AppConfig.instance;
  const marker = {'visibility': 'public', 'schemaVersion': 1};

  setUp(() {
    Sint.reset();
    config.appInUse = AppInUse.g;
    config.isGuestMode = true;
    AppReleaseItemFirestore.invalidateAllReleaseItemsCache();
    firestore = _ControlledFirestore();
  });

  tearDown(() {
    Sint.reset();
    config.appInUse = AppInUse.o;
    config.isGuestMode = true;
    AppReleaseItemFirestore.invalidateAllReleaseItemsCache();
  });

  Future<void> seedPosts() async {
    for (final time in [30, 20, 10]) {
      await firestore.delegate.doc('publicPosts/post-$time').set({
        ...marker,
        'caption': 'Post $time',
        'lastInteraction': time,
      });
    }
  }

  Future<void> seedRelease(String id) => firestore.delegate
      .doc('publicAppReleaseItems/$id')
      .set({...marker, 'name': id, 'status': 'publish', 'createdTime': 10});

  test(
    'strict empty success remains distinguishable from a failed read',
    () async {
      expect(
        await PostFirestore(
          firestore: firestore,
        ).getTimeline(throwOnError: true),
        isEmpty,
      );
      expect(
        await AppReleaseItemFirestore(
          firestore: firestore,
        ).retrieveAll(throwOnError: true),
        isEmpty,
      );
      expect(firestore.cursors, [null, null]);
    },
  );

  for (final code in ['unavailable', 'permission-denied']) {
    test(
      'timeline rethrows the same $code and retries the same page',
      () async {
        await seedPosts();
        final repo = PostFirestore(firestore: firestore);
        expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
          'post-30',
        ]);
        final failure = FirebaseException(
          plugin: 'cloud_firestore',
          code: code,
        );
        firestore.failNext(failure);
        await expectLater(
          repo.getTimeline(limit: 1, throwOnError: true),
          throwsA(same(failure)),
        );
        expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
          'post-20',
        ]);
        expect(firestore.cursors, [null, 'post-30', 'post-30']);
      },
    );

    test(
      'releases rethrow the same $code without treating failure as cached success',
      () async {
        await seedRelease('first');
        final repo = AppReleaseItemFirestore(firestore: firestore);
        final failure = FirebaseException(
          plugin: 'cloud_firestore',
          code: code,
        );
        firestore.failNext(failure);
        await expectLater(
          repo.retrieveAll(throwOnError: true),
          throwsA(same(failure)),
        );
        expect((await repo.retrieveAll(throwOnError: true)).keys, ['first']);
        expect(firestore.cursors.length, 2);
      },
    );
  }

  test(
    'failed timeline refresh preserves cursor; successful refresh resets it',
    () async {
      await seedPosts();
      final repo = PostFirestore(firestore: firestore);
      expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
        'post-30',
      ]);
      firestore.failNext(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await expectLater(
        repo.getTimeline(limit: 1, forceRefresh: true, throwOnError: true),
        throwsA(isA<FirebaseException>()),
      );
      expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
        'post-20',
      ]);
      expect(
        (await repo.getTimeline(
          limit: 1,
          forceRefresh: true,
          throwOnError: true,
        )).keys,
        ['post-30'],
      );
      expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
        'post-20',
      ]);
      expect(firestore.cursors, [null, null, 'post-30', null, 'post-30']);
    },
  );

  test(
    'failed release refresh retains prior successful cache and can retry',
    () async {
      await seedRelease('first');
      final repo = AppReleaseItemFirestore(firestore: firestore);
      expect((await repo.retrieveAll(throwOnError: true)).keys, ['first']);
      await seedRelease('second');
      firestore.failNext(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await expectLater(
        repo.retrieveAll(forceRefresh: true, throwOnError: true),
        throwsA(isA<FirebaseException>()),
      );
      expect((await repo.retrieveAll(throwOnError: true)).keys, ['first']);
      expect(firestore.cursors.length, 2);
      expect(
        (await repo.retrieveAll(forceRefresh: true, throwOnError: true)).keys,
        unorderedEquals(['first', 'second']),
      );
      expect(firestore.cursors.length, 3);
    },
  );

  test('default calls retain non-throwing behavior', () async {
    firestore.failNext(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    expect(await PostFirestore(firestore: firestore).getTimeline(), isEmpty);
    firestore.failNext(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    expect(
      await AppReleaseItemFirestore(firestore: firestore).retrieveAll(),
      isEmpty,
    );
  });

  testWidgets(
    'strict timeline timeout does not advance pagination, even after late response',
    (tester) async {
      await seedPosts();
      final repo = PostFirestore(firestore: firestore);
      expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
        'post-30',
      ]);
      final delayed = Completer<QuerySnapshot<Map<String, dynamic>>>();
      firestore.nextRead = (_, _) => delayed.future;
      final result = repo.getTimeline(limit: 1, throwOnError: true);
      final assertion = expectLater(result, throwsA(isA<TimeoutException>()));
      await tester.pump(const Duration(seconds: 20));
      await assertion;
      delayed.complete(
        await firestore.delegate.collection('publicPosts').get(),
      );
      await tester.pump();
      expect((await repo.getTimeline(limit: 1, throwOnError: true)).keys, [
        'post-20',
      ]);
      expect(firestore.cursors, [null, 'post-30', 'post-30']);
    },
  );

  testWidgets(
    'strict release timeout leaves no successful cache, allowing retry',
    (tester) async {
      await seedRelease('first');
      final repo = AppReleaseItemFirestore(firestore: firestore);
      final delayed = Completer<QuerySnapshot<Map<String, dynamic>>>();
      firestore.nextRead = (_, _) => delayed.future;
      final result = repo.retrieveAll(throwOnError: true);
      final assertion = expectLater(result, throwsA(isA<TimeoutException>()));
      await tester.pump(const Duration(seconds: 20));
      await assertion;
      delayed.complete(
        await firestore.delegate.collection('publicAppReleaseItems').get(),
      );
      await tester.pump();
      await seedRelease('second');
      expect(
        (await repo.retrieveAll(throwOnError: true)).keys,
        unorderedEquals(['first', 'second']),
      );
      expect(firestore.cursors.length, 2);
    },
  );
}
