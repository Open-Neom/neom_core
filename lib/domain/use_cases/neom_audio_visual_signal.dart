/// Read-only bridge from audio visualization producers to experiences.
///
/// Keeping this contract in core avoids coupling the generator and experience
/// modules to each other's concrete painter engines. Consumers sample these
/// values on their own visual clock; they never start or stop audio playback.
abstract interface class NeomAudioVisualSignal {
  double get waveHeight;
  double get waveStretch;
  double get visualPhase;
  double get binauralPhase;
  double get breathPulse;
  double get glowIntensity;
  double get hemisphericCoherence;
}

/// Optional, richer bridge. Legacy visual producers remain source compatible.
/// Hz and level describe generated PCM, not a microphone/EEG measurement.
abstract interface class NeomAudioSessionSignal
    implements NeomAudioVisualSignal {
  NeomAudioSessionSnapshot get audioSession;
}

/// Read-only telemetry at the output playhead (one PCM block of resolution).
/// Frequencies are the block-mean oscillator increments after FM/spatial pitch
/// and Nyquist limiting. PM changes phase, not these carrier increments.
/// [level] is stereo PCM RMS in [0, 1], not physical speaker loudness.
/// [phaseRelationship] is abs(cos(R phase - L phase)), NOT neural coherence.
class NeomAudioSessionSnapshot {
  const NeomAudioSessionSnapshot({
    this.isPlaying = false,
    this.multiFrequency = false,
    this.breathingEnabled = false,
    this.playedFrames = 0,
    this.sampleRate = 44100,
    this.leftHz = 0,
    this.rightHz = 0,
    this.subHz = 0,
    this.subGain = 0,
    this.level = 0,
    this.breathValue = 0,
    this.breathRateHz = 0,
    this.beatPhase = 0,
    this.phaseRelationship = 0,
  });

  final bool isPlaying;
  final bool multiFrequency;
  final bool breathingEnabled;
  final int playedFrames;
  final int sampleRate;
  final double leftHz;
  final double rightHz;
  final double subHz;
  final double subGain;
  final double level;
  final double breathValue;
  final double breathRateHz;
  final double beatPhase;
  final double phaseRelationship;

  double get beatHz => (rightHz - leftHz).abs();
  double get elapsedSeconds => sampleRate > 0 ? playedFrames / sampleRate : 0;
}
