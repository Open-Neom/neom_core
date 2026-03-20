import '../../app_config.dart';

/// Singleton stopwatch manager supporting multiple independent references.
///
/// Used for:
/// - **Audio**: tracking listening time per media item (CaseteSession)
/// - **Books**: tracking total reading session + per-page duration (NupaleSession)
/// - **Generator**: tracking frequency chamber sessions
///
/// Each reference (e.g. media item ID, book name, page key) gets its own
/// Stopwatch instance with accumulated time across pause/resume cycles.
class NeomStopwatch {

  static final NeomStopwatch _instance = NeomStopwatch._internal();
  factory NeomStopwatch() => _instance;
  NeomStopwatch._internal();

  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, int> _accumulatedTime = {};
  String currentReference = '';

  /// Starts (or resumes) the stopwatch for [ref].
  void start({String? ref}) {
    ref ??= currentReference;
    if (!_stopwatches.containsKey(ref)) {
      _stopwatches[ref] = Stopwatch();
      _accumulatedTime[ref] = 0;
      AppConfig.logger.i('NeomStopwatch created for $ref.');
    }
    if (!_stopwatches[ref]!.isRunning) {
      _stopwatches[ref]!.start();
      AppConfig.logger.i('NeomStopwatch started for $ref.');
    }
    currentReference = ref;
  }

  /// Pauses the stopwatch for [ref] and accumulates elapsed time.
  void pause({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref) && _stopwatches[ref]!.isRunning) {
      _stopwatches[ref]!.stop();
      _accumulatedTime[ref] = _accumulatedTime[ref]! + _stopwatches[ref]!.elapsed.inSeconds;
      _stopwatches[ref]!.reset();
      AppConfig.logger.i('NeomStopwatch paused for $ref; accumulated: ${_accumulatedTime[ref]}s.');
    }
  }

  /// Returns total elapsed seconds for [ref] (accumulated + current if running).
  int elapsed({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref)) {
      return _accumulatedTime[ref]! +
          (_stopwatches[ref]!.isRunning ? _stopwatches[ref]!.elapsed.inSeconds : 0);
    }
    return 0;
  }

  /// Returns total elapsed **milliseconds** for [ref].
  int elapsedMilliseconds({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref)) {
      return (_accumulatedTime[ref]! * 1000) +
          (_stopwatches[ref]!.isRunning ? _stopwatches[ref]!.elapsed.inMilliseconds : 0);
    }
    return 0;
  }

  /// Stops the stopwatch for [ref] and returns total accumulated seconds.
  int stop({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref)) {
      if (_stopwatches[ref]!.isRunning) {
        pause(ref: ref);
      }
      AppConfig.logger.i('NeomStopwatch stopped for $ref; total: ${_accumulatedTime[ref]}s.');
      return _accumulatedTime[ref]!;
    }
    return 0;
  }

  /// Resets the accumulated time for [ref] to 0 without removing the stopwatch.
  void reset({String? ref}) {
    ref ??= currentReference;
    stop(ref: ref);
    if (_stopwatches.containsKey(ref)) {
      _stopwatches[ref]!.reset();
      _accumulatedTime[ref] = 0;
      AppConfig.logger.i('NeomStopwatch reset for $ref.');
    }
  }

  /// Stops, removes the stopwatch for [ref], and returns total seconds.
  int stopAndClear(String ref) {
    int total = stop(ref: ref);
    _stopwatches.remove(ref);
    _accumulatedTime.remove(ref);
    AppConfig.logger.i('NeomStopwatch cleared for $ref; total: ${total}s.');
    return total;
  }

  /// Returns elapsed seconds for [ref] and restarts its counter from 0.
  /// Useful for per-page tracking: get the time spent, then restart for the next page.
  int lap({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref)) {
      int secs;
      if (_stopwatches[ref]!.isRunning) {
        secs = _accumulatedTime[ref]! + _stopwatches[ref]!.elapsed.inSeconds;
        _stopwatches[ref]!.reset();
        _stopwatches[ref]!.start();
      } else {
        secs = _accumulatedTime[ref]!;
      }
      _accumulatedTime[ref] = 0;
      return secs;
    }
    return 0;
  }

  /// Whether a stopwatch exists and is running for [ref].
  bool isRunning({String? ref}) {
    ref ??= currentReference;
    return _stopwatches.containsKey(ref) && _stopwatches[ref]!.isRunning;
  }

  void resume() {
    start(ref: currentReference);
  }
}
