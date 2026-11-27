import '../model/app_media_item.dart';
import '../model/app_release_item.dart';
import '../model/playable_item.dart';
import 'audio_handler_service.dart';

abstract class AudioPlayerInvokerService {

  Future<void> init({List<PlayableItem>? items, List<AppReleaseItem>? releaseItems, List<AppMediaItem>? mediaItems,
    int index = 0, bool fromMiniPlayer = false, bool isOffline = false, bool recommend = true,
    bool fromDownloads = false, bool shuffle = false, String? playlistBox, bool playItem = true,});

  Future<void> initAudioHandler();
  Future<void> updateNowPlaying({List<AppMediaItem>? items, int index = 0, bool recommend = true,
    bool playItem = true, bool fromDownloads = false, bool isOffline = false});
  Future<AudioHandlerService?> getOrInitAudioHandler();

  Future<void> setValues(int index, {bool recommend = true, bool playItem = false});
  void enforceRepeat();

  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  /// True when the shared audio player is currently playing or loading an
  /// audiobook/track. Never lazily initializes the audio handler.
  bool get isAudioPlaying => false;

  /// Pauses active/loading audio playback without spinning up the audio
  /// handler if it has never been initialized.
  Future<void> pauseIfPlaying() async {
    if (isAudioPlaying) await pause();
  }

  /// Registers a callback invoked whenever audio playback begins, even if the
  /// underlying audio handler is initialized lazily at a later time.
  void registerPlaybackStartedListener(
    String owner,
    Future<void> Function() onPlaybackStarted,
  ) {}

  void unregisterPlaybackStartedListener(String owner) {}

}
