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
    _RedactionPattern.fixed(
      RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
      'Bearer [REDACTED]',
    ),
    // Common token/secret fields in double-quoted JSON
    _RedactionPattern.mapped(
      RegExp(
        r'"(access_token|refresh_token|id_token|idToken|identityToken|client_secret|clientSecret|api_key|apiKey|private_key|privateKey|rawNonce|session_token|sessionToken|session_id|sessionId|auth_token|authToken|oobCode|signature|cookie|password|secret)"\s*:\s*"[^"]*"',
        caseSensitive: false,
      ),
      (m) => '"${m.group(1)}": "[REDACTED]"',
    ),
    // Common token/secret fields in single-quoted maps/logs
    _RedactionPattern.mapped(
      RegExp(
        r"'(access_token|refresh_token|id_token|idToken|identityToken|client_secret|clientSecret|api_key|apiKey|private_key|privateKey|rawNonce|session_token|sessionToken|session_id|sessionId|auth_token|authToken|oobCode|signature|cookie|password|secret)'\s*:\s*'[^']*'",
        caseSensitive: false,
      ),
      (m) => "'${m.group(1)}': '[REDACTED]'",
    ),
    // Authorization / session / AppCheck / Google / Stripe headers
    _RedactionPattern.mapped(
      RegExp(
        r'(Authorization|X-Api-Key|X-Goog-Api-Key|X-Secret|X-Firebase-AppCheck|Stripe-Signature|X-Stripe-Signature|Cookie|Set-Cookie)\s*[:=]\s*\S+',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}: [REDACTED]',
    ),
    // Query string sensitive params (OAuth codes, Firebase oobCode, GCS signed URLs)
    _RedactionPattern.mapped(
      RegExp(
        r'([?&])(token|key|secret|password|api_key|apiKey|access_token|refresh_token|id_token|idToken|identityToken|client_secret|rawNonce|oobCode|code|signature|x-goog-signature|x-goog-credential|googleaccessid|session_id|sessionId)=([^&\s]*)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}${m.group(2)}=[REDACTED]',
    ),
    // Standalone JWTs (header.payload.signature)
    _RedactionPattern.fixed(
      RegExp(r'\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b'),
      '[JWT_REDACTED]',
    ),
    // URL userInfo credentials (https://user:pass@host)
    _RedactionPattern.mapped(
      RegExp(r'\b(https?|wss?|ftp)://([^\s/@:]+):([^\s/@]+)@', caseSensitive: false),
      (m) => '${m.group(1)}://[REDACTED]@',
    ),
    // PEM private key blocks
    _RedactionPattern.fixed(
      RegExp(
        r'-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----[\s\S]*?(?:-----END [A-Z0-9 ]*PRIVATE KEY-----|$)',
      ),
      '[PRIVATE_KEY_REDACTED]',
    ),
    // AWS access key IDs
    _RedactionPattern.fixed(
      RegExp(r'\b(?:AKIA|ASIA)[0-9A-Z]{16}\b'),
      '[AWS_KEY_REDACTED]',
    ),
    // Stripe / OpenAI / Anthropic / GitHub / GitLab / Slack / HuggingFace secret keys
    _RedactionPattern.fixed(
      RegExp(
        r'\b(?:sk_live|sk_test|rk_live|rk_test|whsec|sk-proj|sk-ant|ghp|gho|ghu|ghs|ghr|github_pat|glpat|xoxb|xoxp|xoxa|xoxr|hf)[_-][A-Za-z0-9_-]{12,}\b',
      ),
      '[API_KEY_REDACTED]',
    ),
    // Firebase credentials
    _RedactionPattern.fixed(
      RegExp(r'AIza[A-Za-z0-9\-_]{35}'),
      '[FIREBASE_KEY_REDACTED]',
    ),
  ];

  static final RegExp _unsafeLogTagChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2069\uFEFF\[\]]',
  );

  static final RegExp _unsafeLogMessageControlOrBidi = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u2028-\u202E\u2066-\u2069]',
  );

  static String _sanitizeTag(String tag) {
    final cleaned = tag.replaceAll(_unsafeLogTagChars, '_').trim();
    if (cleaned.isEmpty) return 'log';
    if (cleaned.length <= 64) return cleaned;
    var cut = 64;
    final lastUnit = cleaned.codeUnitAt(cut - 1);
    if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
      cut -= 1;
    }
    return cleaned.substring(0, cut);
  }

  /// Sanitize a message by stripping ANSI/OSC terminal escapes & BiDi overrides
  /// and applying all redaction patterns.
  static String sanitize(String message) {
    final decontrolled = message.replaceAll(_unsafeLogMessageControlOrBidi, '');
    if (!redactionEnabled) return _truncate(decontrolled);

    String sanitized = decontrolled;
    for (final pattern in _patterns) {
      sanitized = pattern.apply(sanitized);
    }
    return _truncate(sanitized);
  }

  /// Debug log with tag and redaction.
  static void d(String tag, String message) {
    neomLogger.d('[${_sanitizeTag(tag)}] ${sanitize(message)}');
  }

  /// Info log with tag and redaction.
  static void i(String tag, String message) {
    neomLogger.i('[${_sanitizeTag(tag)}] ${sanitize(message)}');
  }

  /// Warning log with tag and redaction.
  static void w(String tag, String message) {
    neomLogger.w('[${_sanitizeTag(tag)}] ${sanitize(message)}');
  }

  /// Error log with tag, redaction, and optional error/stackTrace.
  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    final safeTag = _sanitizeTag(tag);
    final sanitizedMsg = sanitize(message);
    final sanitizedError = error != null ? sanitize(error.toString()) : null;
    if (sanitizedError != null) {
      neomLogger.e('[$safeTag] $sanitizedMsg | Error: $sanitizedError');
    } else {
      neomLogger.e('[$safeTag] $sanitizedMsg');
    }
  }

  static String _truncate(String s) {
    if (s.length <= maxMessageLength) return s;
    int cut = maxMessageLength;
    final int lastUnit = s.codeUnitAt(cut - 1);
    if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
      cut -= 1;
    }
    return '${s.substring(0, cut)}... [TRUNCATED]';
  }
}

class _RedactionPattern {
  final RegExp regex;
  final String? _fixedReplacement;
  final String Function(Match match)? _mapper;

  const _RedactionPattern.fixed(this.regex, String replacement)
      : _fixedReplacement = replacement,
        _mapper = null;

  const _RedactionPattern.mapped(this.regex, String Function(Match match) mapper)
      : _fixedReplacement = null,
        _mapper = mapper;

  String apply(String input) {
    final mapper = _mapper;
    if (mapper != null) {
      return input.replaceAllMapped(regex, mapper);
    }
    return input.replaceAll(regex, _fixedReplacement!);
  }
}
