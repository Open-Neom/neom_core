/// Consciousness states for neuro-harmonic experiences.
///
/// Each state maps to specific audio parameters (breathing, modulation,
/// isochronic frequency, spatial mode) and visual parameters (color palette,
/// geometry, behavior) across the Neom ecosystem.
///
/// Used by neom_generator (audio), neom_experiences (visuals), and
/// neom_states (predefined frequency programs).
enum NeomNeuroState {
  /// Baseline — balanced, no entrainment bias.
  neutral,

  /// Deep parasympathetic activation — meditation target.
  /// Audio: box breathing, 4Hz isochronic (theta).
  calm,

  /// Sympathetic activation — directed attention.
  /// Audio: FM modulation, 14Hz isochronic (beta).
  focus,

  /// Low arousal — hypnagogic, pre-sleep.
  /// Audio: 4-7-8 breathing, 2.5Hz isochronic (delta).
  sleep,

  /// Disinhibited — associative, generative thinking.
  /// Audio: FM modulation, no isochronic.
  creativity,

  /// Whole-brain coherence — flow state, synthesis.
  /// Audio: PM modulation, no isochronic.
  integration;

  /// Human-readable key for translations.
  String get nameKey => switch (this) {
    neutral => 'neuroStateNeutral',
    calm => 'neuroStateCalm',
    focus => 'neuroStateFocus',
    sleep => 'neuroStateSleep',
    creativity => 'neuroStateCreativity',
    integration => 'neuroStateIntegration',
  };

  /// Normalized value (0.0–1.0) for shader/audio uniforms.
  double get normalizedValue => index / (NeomNeuroState.values.length - 1);

  /// Infer neuro state from a binaural beat frequency (Hz).
  ///
  /// Maps EEG band ranges to consciousness states:
  /// - Delta (0.5–4 Hz) → sleep
  /// - Theta (4–8 Hz) → calm / creativity
  /// - Alpha (8–13 Hz) → neutral / calm
  /// - Beta (13–30 Hz) → focus
  /// - Gamma (30+ Hz) → focus / integration
  ///
  /// Used by neom_states to derive the visual state from a FrequencyState's
  /// binaural beat without importing neom_experiences or neom_generator.
  static NeomNeuroState fromBinauralBeatHz(double beatHz) {
    final abs = beatHz.abs();
    if (abs < 0.5) return NeomNeuroState.neutral;
    if (abs <= 4.0) return NeomNeuroState.sleep;
    if (abs <= 6.0) return NeomNeuroState.creativity;
    if (abs <= 8.0) return NeomNeuroState.calm;
    if (abs <= 13.0) return NeomNeuroState.neutral;
    if (abs <= 30.0) return NeomNeuroState.focus;
    return NeomNeuroState.integration; // Gamma 30+ Hz
  }
}
