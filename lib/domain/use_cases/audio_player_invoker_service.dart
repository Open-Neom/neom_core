import '../model/app_media_item.dart';
import '../model/app_release_item.dart';
import 'audio_handler_service.dart';

abstract class AudioPlayerInvokerService {

  Future<void> init({List<AppReleaseItem>? releaseItems, List<AppMediaItem>? mediaItems,
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

}
