import 'package:logger/logger.dart';

/// Enables console diagnostics for a local QA build, including release mode.
///
/// Opt in with `--dart-define=LOCAL_QA_LOGS=true`. Remote error reporting is
/// disabled by [NeomErrorLogger] for these builds; normal builds are unchanged.
const bool localQaLogsEnabled = bool.fromEnvironment(
  'LOCAL_QA_LOGS',
  defaultValue: false,
);

/// Compact application logger.
///
/// The default PrettyPrinter includes method frames for every debug/info
/// message, which makes Flutter web startup logs overwhelmingly noisy. Keep
/// stack frames for actual errors while routine diagnostics stay one-line.
final neomLogger = Logger(
  filter: localQaLogsEnabled ? ProductionFilter() : null,
  // Keep verbose debug/trace messages out of local production-data QA logs.
  level: localQaLogsEnabled ? Level.info : null,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
