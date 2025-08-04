import 'package:rxdart/rxdart.dart';

abstract class AudioHandlerService {

  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;

}
