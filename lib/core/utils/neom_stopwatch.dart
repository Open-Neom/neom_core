import 'package:neom_commons/core/utils/app_utilities.dart';

class NeomStopwatch {
  // Mapa que asocia cada referencia (p. ej. el id del media item) a su Stopwatch
  static final Map<String, Stopwatch> _stopwatches = {};
  // Mapa para acumular el tiempo reproducido de cada referencia en segundos
  static final Map<String, int> _accumulatedTime = {};
  static String currentReference = '';

  /// Inicia (o reanuda) el stopwatch para la referencia [ref]
  static void start(String ref) {
    // Si no existe, se crea un Stopwatch para esta referencia y se inicializa el acumulado
    if (!_stopwatches.containsKey(ref)) {
      _stopwatches[ref] = Stopwatch();
      _accumulatedTime[ref] = 0;
      AppUtilities.logger.i('Creado stopwatch para $ref.');
    }
    // Si no está corriendo, se inicia
    if (!_stopwatches[ref]!.isRunning) {
      _stopwatches[ref]!.start();
      AppUtilities.logger.i('Stopwatch iniciado para $ref.');
    } else {
      AppUtilities.logger.i('El stopwatch ya está corriendo para $ref.');
    }
    currentReference = ref;
  }

  /// Pausa el stopwatch para [ref] y acumula el tiempo transcurrido
  static void pause(String ref) {
    if (_stopwatches.containsKey(ref) && _stopwatches[ref]!.isRunning) {
      _stopwatches[ref]!.stop();
      // Acumula los segundos transcurridos
      _accumulatedTime[ref] = _accumulatedTime[ref]! + _stopwatches[ref]!.elapsed.inSeconds;
      _stopwatches[ref]!.reset();
      AppUtilities.logger.i('Stopwatch pausado para $ref; tiempo acumulado: ${_accumulatedTime[ref]} s.');
    }
  }

  /// Retorna el tiempo total reproducido para la referencia [ref]
  static int elapsed(String ref) {
    if (_stopwatches.containsKey(ref)) {
      // Suma el acumulado más el tiempo actual (si está corriendo)
      return _accumulatedTime[ref]! +
          (_stopwatches[ref]!.isRunning ? _stopwatches[ref]!.elapsed.inSeconds : 0);
    }
    return 0;
  }

  /// Detiene el stopwatch para [ref] (pausándolo si está corriendo) y devuelve el tiempo total
  static int stop({String? ref}) {
    if(ref == null) ref = currentReference;
    if (_stopwatches.containsKey(ref)) {
      if (_stopwatches[ref]!.isRunning) {
        pause(ref);
      }
      AppUtilities.logger.i('Stopwatch detenido para $ref; tiempo total: ${_accumulatedTime[ref]} s.');
      return _accumulatedTime[ref]!;
    }
    return 0;
  }

  /// (Opcional) Limpia el stopwatch y el acumulado para [ref]
  static void reset(String ref) {
    if (_stopwatches.containsKey(ref)) {
      _stopwatches[ref]!.reset();
      _accumulatedTime[ref] = 0;
      AppUtilities.logger.i('Stopwatch reseteado para $ref.');
    }
  }

  /// (Opcional) Detiene y remueve el stopwatch para [ref] devolviendo el tiempo total
  static int stopAndClear(String ref) {
    int total = stop(ref: ref);
    _stopwatches.remove(ref);
    _accumulatedTime.remove(ref);
    AppUtilities.logger.i('Stopwatch limpiado para $ref; tiempo total: $total s.');
    return total;
  }
}
