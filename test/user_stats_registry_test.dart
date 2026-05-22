// Tests for `UserStatsRegistry` — singleton para integración cross-module.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/user_stats_registry.dart';

void main() {
  // Cleanup: cada test arranca con registry limpio
  setUp(() {
    UserStatsRegistry.instance.clear();
  });

  group('UserStatsRegistry — singleton', () {
    test('instance es siempre el mismo objeto', () {
      final a = UserStatsRegistry.instance;
      final b = UserStatsRegistry.instance;
      expect(identical(a, b), isTrue);
    });
  });

  group('UserStatsRegistry — register & getAll', () {
    test('hasStats es false antes de registrar', () {
      expect(UserStatsRegistry.instance.hasStats, isFalse);
    });

    test('register agrega stats para un módulo', () {
      UserStatsRegistry.instance.register('nupale', {
        'Páginas leídas': '350',
        'Libros completados': '5',
      });
      expect(UserStatsRegistry.instance.hasStats, isTrue);
      expect(
        UserStatsRegistry.instance.getModule('nupale'),
        {'Páginas leídas': '350', 'Libros completados': '5'},
      );
    });

    test('getAll devuelve stats de todos los módulos', () {
      UserStatsRegistry.instance.register('nupale', {'pages': '100'});
      UserStatsRegistry.instance.register('casete', {'minutes': '200'});

      final all = UserStatsRegistry.instance.getAll();
      expect(all.length, 2);
      expect(all['nupale'], {'pages': '100'});
      expect(all['casete'], {'minutes': '200'});
    });

    test('register reemplaza stats previas del mismo módulo', () {
      UserStatsRegistry.instance.register('nupale', {'pages': '100'});
      UserStatsRegistry.instance.register('nupale', {'pages': '200'});

      expect(
        UserStatsRegistry.instance.getModule('nupale'),
        {'pages': '200'},
      );
    });

    test('getModule devuelve null para módulo no registrado', () {
      expect(UserStatsRegistry.instance.getModule('inexistente'), isNull);
    });

    test('register hace stats inmutables (Map.unmodifiable)', () {
      final stats = {'key': 'value'};
      UserStatsRegistry.instance.register('mod', stats);

      final retrieved = UserStatsRegistry.instance.getModule('mod')!;
      expect(
        () => retrieved['nuevo'] = 'X',
        throwsUnsupportedError,
      );
    });

    test('getAll devuelve Map inmutable', () {
      UserStatsRegistry.instance.register('mod', {'k': 'v'});
      final all = UserStatsRegistry.instance.getAll();
      expect(
        () => all['otro'] = {'x': 'y'},
        throwsUnsupportedError,
      );
    });
  });

  group('UserStatsRegistry — clear', () {
    test('clear remueve todo', () {
      UserStatsRegistry.instance.register('a', {'k': 'v'});
      UserStatsRegistry.instance.register('b', {'k2': 'v2'});
      expect(UserStatsRegistry.instance.hasStats, isTrue);

      UserStatsRegistry.instance.clear();

      expect(UserStatsRegistry.instance.hasStats, isFalse);
      expect(UserStatsRegistry.instance.getAll(), isEmpty);
      expect(UserStatsRegistry.instance.getModule('a'), isNull);
    });
  });
}
