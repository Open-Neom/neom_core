
abstract class AudioLitePlayerService {

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> setFilePath(String path);
  void clear();

  int get durationInSeconds;

}
