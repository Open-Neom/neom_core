import '../model/app_media_item.dart';
import 'audio_handler_service.dart';

abstract class AudioPlayerInvokerService {

  Future<void> init({required List<AppMediaItem> appMediaItems, required int index,
    bool fromMiniPlayer = false, bool isOffline = false, bool recommend = true,
    bool fromDownloads = false, bool shuffle = false, String? playlistBox, bool playItem = true,});

  Future<void> initAudioHandler();
  Future<void> updateNowPlaying(List<AppMediaItem> appMediaItems, int index, {bool recommend = true, bool playItem = true});
  Future<AudioHandlerService?> getOrInitAudioHandler();

  Future<void> setValues(List<AppMediaItem> appMediaItems, int index, {bool recommend = true, bool playItem = false});
  void enforceRepeat();

  Future<void> play();
  Future<void> pause();
  Future<void> stop();

}
