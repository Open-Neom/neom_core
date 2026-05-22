// Tests for `NeomVisualState` — value class const.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/domain/model/neom_visual_state.dart';

void main() {
  group('NeomVisualState', () {
    test('constructor con required', () {
      const s = NeomVisualState(
        phase: 0.5,
        amplitude: 0.8,
        pan: -0.5,
        breath: 0.3,
        modulation: 0.7,
        neuro: 0.4,
      );
      expect(s.phase, 0.5);
      expect(s.amplitude, 0.8);
      expect(s.pan, -0.5);
      expect(s.breath, 0.3);
      expect(s.modulation, 0.7);
      expect(s.neuro, 0.4);
      expect(s.frequency, 0,
          reason: 'frequency default es 0');
    });

    test('frequency custom', () {
      const s = NeomVisualState(
        phase: 0, amplitude: 0, pan: 0,
        breath: 0, modulation: 0, neuro: 0,
        frequency: 0.7,
      );
      expect(s.frequency, 0.7);
    });

    test('NeomVisualState.zero() es identity neutra', () {
      final z = NeomVisualState.zero();
      expect(z.phase, 0);
      expect(z.amplitude, 0);
      expect(z.pan, 0);
      expect(z.breath, 0);
      expect(z.modulation, 0);
      expect(z.neuro, 0);
      expect(z.frequency, 0);
    });

    test('es const-constructible', () {
      const a = NeomVisualState(
        phase: 0, amplitude: 0, pan: 0,
        breath: 0, modulation: 0, neuro: 0,
      );
      const b = NeomVisualState(
        phase: 0, amplitude: 0, pan: 0,
        breath: 0, modulation: 0, neuro: 0,
      );
      expect(identical(a, b), isTrue);
    });
  });
}
