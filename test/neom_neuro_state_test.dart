// Tests for `NeomNeuroState` enum.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/neom/neom_neuro_state.dart';

void main() {
  group('NeomNeuroState enum', () {
    test('tiene 6 valores', () {
      expect(NeomNeuroState.values.length, 6);
    });

    test('orden semántico: neutral primero, integration último', () {
      expect(NeomNeuroState.values.first, NeomNeuroState.neutral);
      expect(NeomNeuroState.values.last, NeomNeuroState.integration);
    });
  });

  group('NeomNeuroState.nameKey', () {
    test('cada estado tiene su translation key con prefijo neuroState', () {
      expect(NeomNeuroState.neutral.nameKey, 'neuroStateNeutral');
      expect(NeomNeuroState.calm.nameKey, 'neuroStateCalm');
      expect(NeomNeuroState.focus.nameKey, 'neuroStateFocus');
      expect(NeomNeuroState.sleep.nameKey, 'neuroStateSleep');
      expect(NeomNeuroState.creativity.nameKey, 'neuroStateCreativity');
      expect(NeomNeuroState.integration.nameKey, 'neuroStateIntegration');
    });

    test('todos los nameKey son únicos', () {
      final keys = NeomNeuroState.values.map((s) => s.nameKey).toSet();
      expect(keys.length, NeomNeuroState.values.length);
    });
  });

  group('NeomNeuroState.normalizedValue', () {
    test('rango 0.0 a 1.0', () {
      expect(NeomNeuroState.neutral.normalizedValue, 0.0);
      expect(NeomNeuroState.integration.normalizedValue, 1.0);
    });

    test('valores intermedios crecen monotónicamente', () {
      final values = NeomNeuroState.values
          .map((s) => s.normalizedValue)
          .toList();
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThan(values[i - 1]),
            reason: '$i debería ser mayor que ${i - 1}');
      }
    });

    test('todos los valores están en [0, 1]', () {
      for (final s in NeomNeuroState.values) {
        expect(s.normalizedValue, greaterThanOrEqualTo(0.0));
        expect(s.normalizedValue, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('NeomNeuroState.fromBinauralBeatHz', () {
    test('< 0.5 Hz → neutral', () {
      expect(NeomNeuroState.fromBinauralBeatHz(0), NeomNeuroState.neutral);
      expect(NeomNeuroState.fromBinauralBeatHz(0.3), NeomNeuroState.neutral);
    });

    test('Delta (0.5–4 Hz) → sleep', () {
      expect(NeomNeuroState.fromBinauralBeatHz(2), NeomNeuroState.sleep);
      expect(NeomNeuroState.fromBinauralBeatHz(4), NeomNeuroState.sleep);
    });

    test('Theta bajo (4–6 Hz) → creativity', () {
      expect(NeomNeuroState.fromBinauralBeatHz(5), NeomNeuroState.creativity);
      expect(NeomNeuroState.fromBinauralBeatHz(6), NeomNeuroState.creativity);
    });

    test('Theta alto (6–8 Hz) → calm', () {
      expect(NeomNeuroState.fromBinauralBeatHz(7), NeomNeuroState.calm);
      expect(NeomNeuroState.fromBinauralBeatHz(8), NeomNeuroState.calm);
    });

    test('Alpha (8–13 Hz) → neutral', () {
      expect(NeomNeuroState.fromBinauralBeatHz(10), NeomNeuroState.neutral);
      expect(NeomNeuroState.fromBinauralBeatHz(13), NeomNeuroState.neutral);
    });

    test('Beta (13–30 Hz) → focus', () {
      expect(NeomNeuroState.fromBinauralBeatHz(20), NeomNeuroState.focus);
      expect(NeomNeuroState.fromBinauralBeatHz(30), NeomNeuroState.focus);
    });

    test('Gamma (30+ Hz) → integration', () {
      expect(NeomNeuroState.fromBinauralBeatHz(40), NeomNeuroState.integration);
      expect(NeomNeuroState.fromBinauralBeatHz(100), NeomNeuroState.integration);
    });

    test('toma valor absoluto (negativos OK)', () {
      expect(
        NeomNeuroState.fromBinauralBeatHz(-2),
        NeomNeuroState.sleep,
      );
    });
  });
}
