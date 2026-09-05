import 'package:logger/logger.dart';

/// Compact application logger.
///
/// The default PrettyPrinter includes method frames for every debug/info
/// message, which makes Flutter web startup logs overwhelmingly noisy. Keep
/// stack frames for actual errors while routine diagnostics stay one-line.
final neomLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
