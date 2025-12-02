import '../../app_config.dart';

class NeomStopwatch {

  static final NeomStopwatch _instance = NeomStopwatch._internal();
  factory NeomStopwatch() => _instance;
  NeomStopwatch._internal();

  // Mapa que asocia cada referencia (p. ej. el id del media item) a su Stopwatch
  final Map<String, Stopwatch> _stopwatches = {};
  // Mapa para acumular el tiempo reproducido de cada referencia en segundos
  final Map<String, int> _accumulatedTime = {};
  String currentReference = '';

  /// Inicia (o reanuda) el stopwatch para la referencia [ref]
  void start({String? ref}) {
    ref ??= currentReference;
    // Si no existe, se crea un Stopwatch para esta referencia y se inicializa el acumulado
    if (!_stopwatches.containsKey(ref)) {
      _stopwatches[ref] = Stopwatch();
      _accumulatedTime[ref] = 0;
      AppConfig.logger.i('Creado stopwatch para $ref.');
    }
    // Si no está corriendo, se inicia
    if (!_stopwatches[ref]!.isRunning) {
      _stopwatches[ref]!.start();
      AppConfig.logger.i('Stopwatch iniciado para $ref.');
    } else {
      AppConfig.logger.i('El stopwatch ya está corriendo para $ref.');
    }
    currentReference = ref;
  }

  /// Pausa el stopwatch para [ref] y acumula el tiempo transcurrido
  void pause({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref) && _stopwatches[ref]!.isRunning) {
      _stopwatches[ref]!.stop();
      // Acumula los segundos transcurridos
      _accumulatedTime[ref] = _accumulatedTime[ref]! + _stopwatches[ref]!.elapsed.inSeconds;
      _stopwatches[ref]!.reset();
      AppConfig.logger.i('Stopwatch pausado para $ref; tiempo acumulado: ${_accumulatedTime[ref]} s.');
    }
  }

  /// Retorna el tiempo total reproducido para la referencia [ref]
  int elapsed({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref)) {
      // Suma el acumulado más el tiempo actual (si está corriendo)
      return _accumulatedTime[ref]! +
          (_stopwatches[ref]!.isRunning ? _stopwatches[ref]!.elapsed.inSeconds : 0);
    }
    return 0;
  }

  /// Detiene el stopwatch para [ref] (pausándolo si está corriendo) y devuelve el tiempo total
  int stop({String? ref}) {
    ref ??= currentReference;
    if (_stopwatches.containsKey(ref)) {
      if (_stopwatches[ref]!.isRunning) {
        pause(ref: ref);
      }
      AppConfig.logger.i('Stopwatch detenido para $ref; tiempo total: ${_accumulatedTime[ref]} s.');
      return _accumulatedTime[ref]!;
    }
    return 0;
  }

  /// (Opcional) Detiene y limpia el stopwatch y el acumulado para [ref]
  void reset({String? ref}) {
    ref ??= currentReference;
    stop(ref: ref);
    if (_stopwatches.containsKey(ref)) {
      _stopwatches[ref]!.reset();
      _accumulatedTime[ref] = 0;
      AppConfig.logger.i('Stopwatch reseteado para $ref.');
    }
  }

  /// (Opcional) Detiene y remueve el stopwatch para [ref] devolviendo el tiempo total
  int stopAndClear(String ref) {
    int total = stop(ref: ref);
    _stopwatches.remove(ref);
    _accumulatedTime.remove(ref);
    AppConfig.logger.i('Stopwatch limpiado para $ref; tiempo total: $total s.');
    return total;
  }

  void resume() {
    start(ref: currentReference);
  }
}
