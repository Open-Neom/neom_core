/// Abstract contract for real-time 1:1 calls, kept in neom_core so callers
/// (e.g. neom_inbox) depend ONLY on this interface — never on the concrete
/// implementation. The WebRTC engine (neom_rooms) provides the implementation
/// and is wired via DI in the host app, so the inbox stays decoupled.
abstract class CallService {

  /// Starts a 1:1 call with [peerProfileId]: creates/joins the two-person room,
  /// rings the peer (push notification) and opens the call screen for the caller.
  /// [video] = false → voice-only call.
  Future<void> startCall(
    String peerProfileId, {
    String peerName,
    String peerPhotoUrl,
    bool video,
  });

  /// Joins an existing call room — e.g. after the callee taps the incoming-call
  /// notification.
  Future<void> joinCall(String roomId, {bool video});

  /// Whether a 1:1 call can be placed right now (engine ready / platform
  /// supported). Lets the UI hide the call button when unavailable.
  bool get canCall;
}
