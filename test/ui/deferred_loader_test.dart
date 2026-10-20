import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/ui/deferred_loader.dart';

class _MaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(_MaterialDelegate old) => false;
}

class _CupertinoDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(_CupertinoDelegate old) => false;
}

Widget _app(Widget child, {String language = 'en'}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('fr'),
  ],
  localizationsDelegates: const [_MaterialDelegate(), _CupertinoDelegate()],
  home: child,
);

void main() {
  testWidgets('waits for the library before constructing the section', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    var builds = 0;
    await tester.pumpWidget(
      _app(
        DeferredLoader(
          () {
            calls++;
            return pending.future;
          },
          () {
            builds++;
            return const Text('Loaded section');
          },
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(calls, 1);
    expect(builds, 0);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Loaded section'), findsOneWidget);
    expect(builds, 1);
  });

  testWidgets('failure stays recoverable until explicit retry succeeds', (
    tester,
  ) async {
    final retry = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      _app(
        DeferredLoader(() {
          calls++;
          return calls == 1
              ? Future<void>.error(StateError('download failed'))
              : retry.future;
        }, () => const Text('Loaded section')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('This section could not be loaded'), findsOneWidget);
    expect(find.text('Loaded section'), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 1, reason: 'There is no automatic retry/reload loop.');

    // Two queued button taps must still produce just one in-flight retry.
    final retryButton = tester.widget<FilledButton>(find.byType(FilledButton));
    retryButton.onPressed!();
    retryButton.onPressed!();
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    retry.complete();
    await tester.pumpAndSettle();
    expect(find.text('Loaded section'), findsOneWidget);
  });

  testWidgets('parent and locale rebuilds do not restart a failed load', (
    tester,
  ) async {
    var calls = 0;
    Widget build(String language) => _app(
      DeferredLoader(() {
        calls++;
        return Future<void>.error(StateError('offline'));
      }, () => const Text('Loaded section')),
      language: language,
    );
    await tester.pumpWidget(build('en'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build('es'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Ir al inicio'), findsOneWidget);
    expect(find.text('No se pudo cargar esta sección'), findsOneWidget);
  });

  testWidgets('parent rebuild while loading keeps the original future', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    Widget build() => _app(
      DeferredLoader(() {
        calls++;
        return pending.future;
      }, () => const Text('Loaded section')),
    );
    await tester.pumpWidget(build());
    await tester.pumpWidget(build());
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Loaded section'), findsOneWidget);
  });

  testWidgets('synchronous loader throws use the same recoverable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DeferredLoader(
          () => throw StateError('sync failure'),
          () => const Text('Loaded section'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets('late ${fail ? 'failure' : 'success'} after dispose is safe', (
      tester,
    ) async {
      final pending = Completer<void>();
      await tester.pumpWidget(
        _app(
          DeferredLoader(
            () => pending.future,
            () => const Text('Loaded section'),
          ),
        ),
      );
      await tester.pumpWidget(_app(const Text('Another page')));
      if (fail) {
        pending.completeError(StateError('late failure'));
      } else {
        pending.complete();
      }
      await tester.pumpAndSettle();
      expect(find.text('Another page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'direct-link error can return to root without popping empty stack',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/cotizacion'),
              builder: (_) => DeferredLoader(
                () => Future<void>.error(StateError('offline')),
                () => const Text('Loaded section'),
              ),
            ),
          ],
          routes: {'/': (_) => const Scaffold(body: Text('Home'))},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Go to home'), findsOneWidget);
      await tester.tap(find.text('Go to home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nested error goes back to its existing previous route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DeferredLoader(
                    () => Future<void>.error(StateError('offline')),
                    () => const Text('Loaded section'),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Go back'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('console diagnostics omit credential URLs and personal data', (
    tester,
  ) async {
    final messages = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await tester.pumpWidget(
        _app(
          DeferredLoader(
            () => Future<void>.error(
              StateError(
                'https://private.example/main.dart.js_275.part.js'
                '?token=DO_NOT_LOG&email=reader@example.test',
              ),
            ),
            () => const Text('Loaded section'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      debugPrint = originalPrint;
    }
    final diagnostics = messages
        .where((message) => message.startsWith('DeferredLoader:'))
        .toList();
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single, contains('attempt=1; type=StateError'));
    expect(diagnostics.single, contains('chunk=main.dart.js_275.part.js'));
    expect(diagnostics.single, isNot(contains('private.example')));
    expect(diagnostics.single, isNot(contains('DO_NOT_LOG')));
    expect(diagnostics.single, isNot(contains('reader@example.test')));
  });

  for (final translation in {
    'de': 'Erneut versuchen',
    'fr': 'Réessayer',
  }.entries) {
    testWidgets('recovery is localized in ${translation.key}', (tester) async {
      await tester.pumpWidget(
        _app(
          DeferredLoader(
            () => Future<void>.error(StateError('offline')),
            () => const Text('Loaded section'),
          ),
          language: translation.key,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(translation.value), findsOneWidget);
    });
  }
}
