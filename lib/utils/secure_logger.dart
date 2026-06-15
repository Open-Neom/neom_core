import 'neom_logger.dart';

/// Security-aware logging wrapper that redacts sensitive data before output.
///
/// Wraps [AppConfig.logger] with automatic sanitization of:
/// - Bearer tokens and authorization headers
/// - API keys, secrets, and passwords
/// - Sensitive query parameters
///
/// Usage:
/// ```dart
/// SecureLogger.i('user_auth', 'Response: $responseBody');
/// // Automatically redacts: Bearer xyz → Bearer [REDACTED]
/// ```
///
/// Inspired by SpotiFLAC-Mobile's logger.dart pattern.
class SecureLogger {
  SecureLogger._();

  /// Enable/disable redaction (disable in debug for full output).
  static bool redactionEnabled = true;

  /// Maximum message length before truncation.
  static const int maxMessageLength = 2000;

  /// Patterns to redact from log messages.
  static final List<_RedactionPattern> _patterns = [
    // Bearer tokens
    _RedactionPattern(
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
      'Bearer [REDACTED]',
    ),
    // Common token fields in JSON
    _RedactionPattern(
      RegExp(r'"(access_token|refresh_token|id_token|client_secret|api_key|apiKey|password|secret)"\s*:\s*"[^"]*"', caseSensitive: false),
      r'"$1": "[REDACTED]"',
    ),
    // Authorization headers
    _RedactionPattern(
      RegExp(r'(Authorization|X-Api-Key|X-Secret)\s*[:=]\s*\S+', caseSensitive: false),
      r'$1: [REDACTED]',
    ),
    // Query string sensitive params
    _RedactionPattern(
      RegExp(r'([?&])(token|key|secret|password|api_key|apiKey|access_token)=([^&\s]*)', caseSensitive: false),
      r'$1$2=[REDACTED]',
    ),
    // Firebase credentials
    _RedactionPattern(
      RegExp(r'AIza[A-Za-z0-9\-_]{35}'),
      '[FIREBASE_KEY_REDACTED]',
    ),
  ];

  /// Sanitize a message by applying all redaction patterns.
  static String sanitize(String message) {
    if (!redactionEnabled) return _truncate(message);

    String sanitized = message;
    for (final pattern in _patterns) {
      sanitized = sanitized.replaceAll(pattern.regex, pattern.replacement);
    }
    return _truncate(sanitized);
  }

  /// Debug log with tag and redaction.
  static void d(String tag, String message) {
    neomLogger.d('[$tag] ${sanitize(message)}');
  }

  /// Info log with tag and redaction.
  static void i(String tag, String message) {
    neomLogger.i('[$tag] ${sanitize(message)}');
  }

  /// Warning log with tag and redaction.
  static void w(String tag, String message) {
    neomLogger.w('[$tag] ${sanitize(message)}');
  }

  /// Error log with tag, redaction, and optional error/stackTrace.
  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final sanitizedMsg = sanitize(message);
    final sanitizedError = error != null ? sanitize(error.toString()) : null;
    if (sanitizedError != null) {
      neomLogger.e('[$tag] $sanitizedMsg | Error: $sanitizedError');
    } else {
      neomLogger.e('[$tag] $sanitizedMsg');
    }
  }

  static String _truncate(String s) {
    return s.length > maxMessageLength ? '${s.substring(0, maxMessageLength)}... [TRUNCATED]' : s;
  }
}

class _RedactionPattern {
  final RegExp regex;
  final String replacement;
  const _RedactionPattern(this.regex, this.replacement);
}
