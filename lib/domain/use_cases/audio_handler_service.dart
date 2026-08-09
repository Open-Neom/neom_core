import 'package:rxdart/rxdart.dart';

/// Asks for a fresh playable URL for a media item. Modules that know how to
/// re-resolve their links (expired signed URLs, rotated CDN paths, quality
/// variants) register one of these on the audio handler; the handler calls
/// them — in registration order — before declaring a track dead.
///
/// Returns the fresh URL, or null/empty when this resolver cannot help.
typedef MediaUrlResolver = Future<String?> Function(
    String itemId, Map<String, dynamic> extras);

abstract class AudioHandlerService {

  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;

  bool get isPlaying;
  bool get stoppedByVideo;
  set stoppedByVideo(bool value);

  /// Registers [resolver] under [owner] (idempotent per owner: re-registering
  /// replaces the previous one). Consulted by the playback error recovery
  /// flow before a failing track is retried/skipped.
  void registerUrlResolver(String owner, MediaUrlResolver resolver);
  void unregisterUrlResolver(String owner);

}
