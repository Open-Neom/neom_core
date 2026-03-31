import 'dart:async';

import '../model/neom/neom_neuro_state.dart';

/// Snapshot of the current neuro-harmonic state with audio metrics.
///
/// Emitted by [NeuroStateService] whenever the state or audio parameters
/// change. Consumers read this to update visuals, breathing patterns, etc.
class NeuroStateSnapshot {
  final NeomNeuroState state;
  final double amplitude;
  final double frequency;
  final double breath;
  final double beat;
  final double phase;
  final double neuro;
  final double coherence;
  final DateTime timestamp;

  const NeuroStateSnapshot({
    required this.state,
    this.amplitude = 0.0,
    this.frequency = 0.0,
    this.breath = 0.0,
    this.beat = 0.0,
    this.phase = 0.0,
    this.neuro = 0.0,
    this.coherence = 0.0,
    required this.timestamp,
  });

  factory NeuroStateSnapshot.neutral() => NeuroStateSnapshot(
    state: NeomNeuroState.neutral,
    timestamp: DateTime.now(),
  );

  /// Create from binaural beat frequencies (used by neom_states).
  /// Infers the neuro state from the beat frequency automatically.
  factory NeuroStateSnapshot.fromBinaural({
    required double leftFreqHz,
    required double rightFreqHz,
    double amplitude = 0.7,
    double pulseFreqHz = 0.0,
  }) {
    final beatHz = (rightFreqHz - leftFreqHz).abs();
    return NeuroStateSnapshot(
      state: NeomNeuroState.fromBinauralBeatHz(beatHz),
      amplitude: amplitude,
      frequency: (leftFreqHz + rightFreqHz) / 2.0,
      beat: beatHz,
      breath: pulseFreqHz,
      neuro: NeomNeuroState.fromBinauralBeatHz(beatHz).normalizedValue,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'amplitude': amplitude,
    'frequency': frequency,
    'breath': breath,
    'beat': beat,
    'phase': phase,
    'neuro': neuro,
    'coherence': coherence,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() =>
    'NeuroStateSnapshot(state=$state, freq=${frequency.toStringAsFixed(1)}Hz, '
    'amp=${amplitude.toStringAsFixed(2)}, coherence=${coherence.toStringAsFixed(2)})';
}

/// Abstract service for neuro-harmonic state management.
///
/// Implemented by the audio generator (neom_generator) to broadcast state
/// changes. Consumed by experiences (neom_experiences) and other modules
/// that need to react to consciousness state transitions.
///
/// Modules depend on this abstraction — not on each other.
///
/// ```
/// neom_generator implements NeuroStateService (provider)
/// neom_experiences reads NeuroStateService (consumer)
/// neom_core defines NeuroStateService (contract)
/// ```
abstract class NeuroStateService {
  /// Current neuro-harmonic state.
  NeomNeuroState get currentState;

  /// Whether the service is actively generating/tracking audio.
  bool get isActive;

  /// Stream of state snapshots emitted on every audio tick or state change.
  /// Experiences subscribe to this for real-time visual updates.
  Stream<NeuroStateSnapshot> get stateStream;

  /// Latest snapshot (synchronous access for paint methods).
  NeuroStateSnapshot get latestSnapshot;

  /// Request a state transition.
  /// The service applies audio parameter changes (breathing, modulation,
  /// isochronic, spatial) and emits a new snapshot.
  void setNeuroState(NeomNeuroState state);
}

/// Mixin for experience controllers that consume [NeuroStateService].
///
/// Provides automatic subscription management and a callback pattern
/// for reacting to state changes without importing the provider module.
///
/// Usage in an experience controller:
/// ```dart
/// class MyController extends SintController with NeuroStateConsumer {
///   @override
///   void onNeuroStateChanged(NeuroStateSnapshot snapshot) {
///     myEngine.setNeuroState(snapshot.state);
///     myEngine.updateAudio(
///       amplitude: snapshot.amplitude,
///       frequency: snapshot.frequency,
///     );
///   }
/// }
/// ```
mixin NeuroStateConsumer {
  StreamSubscription<NeuroStateSnapshot>? _neuroSub;

  /// Override to handle state changes.
  void onNeuroStateChanged(NeuroStateSnapshot snapshot);

  /// Call during init to start listening.
  void subscribeToNeuroState(NeuroStateService service) {
    _neuroSub?.cancel();
    _neuroSub = service.stateStream.listen(onNeuroStateChanged);
  }

  /// Call during dispose to stop listening.
  void unsubscribeFromNeuroState() {
    _neuroSub?.cancel();
    _neuroSub = null;
  }
}
