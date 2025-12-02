import 'package:rxdart/rxdart.dart';

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

}
