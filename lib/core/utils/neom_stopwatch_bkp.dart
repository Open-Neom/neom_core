import 'package:neom_commons/core/utils/app_utilities.dart';

class NeomStopwatch {

  static final stopwatch = Stopwatch();
  ///Stopwatch to measure execution time of tasks
  static final _stopwatch = Stopwatch();
  static String reference = '';
  static Map<String, int> playerReferences = {};

  /// Starts the stopwatch
  static void startPlayerStopwatch(String ref) {
    if(!_stopwatch.isRunning) {
      _stopwatch.start();
      reference = ref;
      AppUtilities.logger.i('Stopwatch instance started for $reference.');
    } else if(reference != ref) {
      int totalSeconds = 0;
      if(playerReferences.containsKey(ref)) {
        totalSeconds = playerReferences[ref] ?? 0 + _stopwatch.elapsed.inSeconds;
      }

      playerReferences[ref] = totalSeconds;
      _stopwatch.stop();

      reference = ref;
      _stopwatch.start();
      AppUtilities.logger.i('New stopwatch instance started for $reference.');
    } else {
      AppUtilities.logger.i('Instance of stopwatch is running for $reference.');
    }
  }

  /// Retrueve the lapse of seconds in the stopwatch
  static int elapsedPlayerStopwatch() {
    int elapsedSeconds = _stopwatch.elapsed.inSeconds;

    AppUtilities.logger.i('Elapsed Time: $elapsedSeconds s'
        '${reference.isNotEmpty ? ' for $reference' : ''}');

    return elapsedSeconds;
  }

  /// Stops the stopwatch, logs the execution time, and resets the stopwatch
  static void stopStopwatch() {
    _stopwatch.stop();

    int total = playerReferences[reference] ?? 0 + elapsedPlayerStopwatch();
    playerReferences[reference] = total;
    AppUtilities.logger.i('Execution Time: ${_stopwatch.elapsed.inSeconds} s'
        ' of a total as ${playerReferences[reference]}'
        '${reference.isNotEmpty ? ' for $reference' : ''}');


    _stopwatch.reset();
    AppUtilities.logger.i('Execution Time: ${_stopwatch.elapsed.inSeconds} s'
        ' of a total as ${playerReferences[reference]}'
        '${reference.isNotEmpty ? ' for $reference' : ''}');
  }

}
