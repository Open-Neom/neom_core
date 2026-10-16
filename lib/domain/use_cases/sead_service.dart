import 'dart:async';

/// Ecosystem-wide contract for the NEOM SEAD Phased-Array (`DAAL 4x4`) and
/// Physical `Cámara Neom` (`Tinaco Cilíndrico 360°`) hardware controller.
///
/// Defined in `neom_core` so any module (`neom_generator`, `neom_levitation`,
/// `neom_eeg`, `neom_ble`) can interact with the physical acoustic hardware
/// without importing `neom_sead` directly.
abstract class SeadService {
  /// Whether at least one physical (`ESP32-S3` or `ESP32-S3-Touch-LCD-1.69`)
  /// or simulated SEAD/Chamber node is active.
  bool get isHardwareConnected;

  /// Active topology ID (`DAAL_4X4`, `CAMARA_TINACO_360`, `ESCUDO_ANC`, `EXO_WEARABLE`).
  String get activeTopologyId;

  /// Set carrier frequency in Hz ($20\text{ Hz} – 8,000\text{ Hz}$).
  void setCarrierFrequency(double freqHz);

  /// Set digital output power multiplier ($0.0 – 1.0$).
  void setPowerGain(double normalizedPower);

  /// Set horizontal beam steering angle in degrees ($-45^\circ .. +45^\circ$).
  void setSteeringAngle(double angleDeg);

  /// Switch between `DAAL_4X4`, `CAMARA_TINACO_360`, `ESCUDO_ANC`, or `EXO_WEARABLE`.
  void setTopologyById(String topologyId);

  /// Process a natural voice command (from phone mic or `ESP32-S3` `INMP441` offline mic).
  /// Returns a human-readable confirmation of the executed action.
  String executeVoiceCommand(String spokenText);

  /// Emergency kill-switch (<10 ms mute across all connected ESP32-S3 nodes).
  void emergencyMute();
}
