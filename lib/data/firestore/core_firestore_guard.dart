import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:sint_sentinel/sint_sentinel_core.dart';

import '../../utils/enums/external_media_source.dart';

/// Pure-Dart security, circuit-breaker, and resource bounds helpers for
/// `neom_core` Firestore and Firebase Storage repositories.
class CoreFirestoreGuard {
  CoreFirestoreGuard._();

  static const Set<String> _infrastructureErrorCodes = <String>{
    'unavailable',
    'deadline-exceeded',
    'resource-exhausted',
    'aborted',
    'internal',
    'unknown',
  };

  /// Returns `true` only for transient infrastructure, quota, or timeout
  /// failures so normal domain outcomes (`permission-denied`, `not-found`,
  /// `unauthenticated`, `ArgumentError`, etc.) never trip the global circuit.
  static bool isInfrastructureFailure(Object error) {
    if (error is ArgumentError ||
        error is FormatException ||
        error is StateError ||
        error is UnsupportedError) {
      return false;
    }
    if (error is TimeoutException) return true;
    if (error is FirebaseException) {
      return _infrastructureErrorCodes.contains(error.code.toLowerCase());
    }
    return false;
  }

  /// Guards a Firestore/Storage read call with [SintSentinel] rate limiting
  /// and circuit-breaker protection.
  static Future<T> guardRead<T>(
    Future<T> Function() action, {
    T Function()? fallback,
    String? tag,
  }) =>
      SintSentinel.guard<T>(
        action,
        fallback: fallback,
        isWrite: false,
        tag: tag,
        countFailureIf: isInfrastructureFailure,
      );

  /// Guards a Firestore/Storage write mutation with [SintSentinel] write-quota
  /// tracking and circuit-breaker protection.
  static Future<T> guardWrite<T>(
    Future<T> Function() action, {
    T Function()? fallback,
    String? tag,
  }) =>
      SintSentinel.guardWrite<T>(
        action,
        fallback: fallback,
        tag: tag,
        countFailureIf: isInfrastructureFailure,
      );

  static const int _maxNestedSanitizeDepth = 16;

  static final RegExp _controlOrBidi = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF]',
  );
  static final RegExp _encodedTraversalOrNull = RegExp(
    r'(%00|%2e|%2f|%5c)',
    caseSensitive: false,
  );
  static final RegExp _idnDotHomoglyphs = RegExp(r'[\u3002\uFF0E\uFF61]');
  static final RegExp _windowsReservedStem = RegExp(
    r'^(?:con|prn|aux|nul|com[1-9]|lpt[1-9])$',
    caseSensitive: false,
  );

  static bool _isForbiddenMapKey(String key) {
    if (key.isEmpty || key.length > 128) return true;
    final lower = key.toLowerCase();
    return lower == 'constructor' ||
        lower == 'prototype' ||
        lower == '__proto__' ||
        key.startsWith('__') ||
        key.contains('/') ||
        key.contains(r'\') ||
        _controlOrBidi.hasMatch(key);
  }

  /// Validates a Firestore document ID (non-empty, `<= 256` chars, no path
  /// separators, `.` / `..`, Firestore-reserved `__.*__`, or control/Bidi characters).
  static bool isSafeDocId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 256) return false;
    if (trimmed == '.' || trimmed == '..') return false;
    final lower = trimmed.toLowerCase();
    if (lower == 'constructor' ||
        lower == 'prototype' ||
        lower == '__proto__') {
      return false;
    }
    if (trimmed.length >= 4 &&
        trimmed.startsWith('__') &&
        trimmed.endsWith('__')) {
      return false;
    }
    if (trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        _encodedTraversalOrNull.hasMatch(trimmed)) {
      return false;
    }
    if (_controlOrBidi.hasMatch(trimmed)) return false;
    return true;
  }

  /// Clamps a Firestore query limit to `[1, maxLimit]`.
  static int clampLimit(
    int limit, {
    int defaultLimit = 50,
    int maxLimit = 500,
  }) {
    final safeDefault =
        (defaultLimit.toDouble().isFinite && defaultLimit > 0)
            ? defaultLimit
            : 50;
    final safeMax =
        (maxLimit.toDouble().isFinite && maxLimit >= safeDefault)
            ? maxLimit
            : 500;
    if (!limit.toDouble().isFinite || limit <= 0) return safeDefault;
    return limit > safeMax ? safeMax : limit;
  }

  /// Deduplicates valid document IDs and splits them into `whereIn`-safe chunks
  /// (`<= 30` IDs per query).
  static List<List<String>> chunkValidIds(
    Iterable<String> rawIds, {
    int chunkSize = 30,
    int maxTotal = 300,
  }) {
    final safeChunk =
        chunkSize.toDouble().isFinite ? chunkSize.clamp(1, 30) : 30;
    final safeMaxTotal =
        (maxTotal.toDouble().isFinite && maxTotal > 0)
            ? maxTotal.clamp(1, 3000)
            : 300;
    final unique = <String>[];
    final seen = <String>{};
    for (final raw in rawIds) {
      final clean = raw.trim();
      if (!isSafeDocId(clean)) continue;
      if (seen.add(clean)) {
        unique.add(clean);
        if (unique.length >= safeMaxTotal) break;
      }
    }
    final chunks = <List<String>>[];
    for (var i = 0; i < unique.length; i += safeChunk) {
      final end =
          (i + safeChunk < unique.length) ? i + safeChunk : unique.length;
      chunks.add(unique.sublist(i, end));
    }
    return chunks;
  }

  static Object? _sanitizeNestedValue(
    Object? value, {
    required int depth,
    required Set<int> active,
  }) {
    if (value == null) return null;
    if (value is num) {
      return value.toDouble().isFinite ? value : _dropNonFiniteSentinel;
    }
    if (value is Map) {
      if (depth >= _maxNestedSanitizeDepth) return const <String, dynamic>{};
      final id = identityHashCode(value);
      if (!active.add(id)) return const <String, dynamic>{};
      try {
        final nested = <String, dynamic>{};
        value.forEach((rawKey, rawVal) {
          if (rawKey is! String) return;
          final cleanKey = rawKey.trim();
          if (_isForbiddenMapKey(cleanKey)) return;
          final sanitizedVal = _sanitizeNestedValue(
            rawVal,
            depth: depth + 1,
            active: active,
          );
          if (identical(sanitizedVal, _dropNonFiniteSentinel)) return;
          nested[cleanKey] = sanitizedVal;
        });
        return nested;
      } finally {
        active.remove(id);
      }
    }
    if (value is List) {
      if (depth >= _maxNestedSanitizeDepth) return const <dynamic>[];
      final id = identityHashCode(value);
      if (!active.add(id)) return const <dynamic>[];
      try {
        final sanitizedList = <dynamic>[];
        for (final item in value) {
          final sanitizedItem = _sanitizeNestedValue(
            item,
            depth: depth + 1,
            active: active,
          );
          if (identical(sanitizedItem, _dropNonFiniteSentinel)) continue;
          sanitizedList.add(sanitizedItem);
        }
        return sanitizedList;
      } finally {
        active.remove(id);
      }
    }
    return value;
  }

  static final Object _dropNonFiniteSentinel = Object();

  /// Sanitizes a partial Firestore `.update(...)` map, stripping immutable keys,
  /// dot/slash/control/prototype keys, and non-finite `double` values (`NaN`/`Infinity`).
  static Map<String, dynamic> sanitizeUpdateMap(
    Map<String, dynamic> raw, {
    Set<String> immutableKeys = const {'id', 'createdAt', 'createdTime'},
  }) {
    final safe = <String, dynamic>{};
    final active = <int>{identityHashCode(raw)};
    raw.forEach((key, value) {
      final cleanKey = key.trim();
      if (_isForbiddenMapKey(cleanKey)) return;
      if (immutableKeys.contains(cleanKey)) return;
      final sanitizedVal = _sanitizeNestedValue(
        value,
        depth: 1,
        active: active,
      );
      if (identical(sanitizedVal, _dropNonFiniteSentinel)) return;
      safe[cleanKey] = sanitizedVal;
    });
    return safe;
  }

  /// Sanitizes a dynamic segment interpolated into a Firestore dot-notation
  /// field path (e.g. `reactions.$emoji`), preventing field-path injection.
  static String sanitizeFieldSegment(String raw, {int maxChars = 32}) {
    if (!maxChars.toDouble().isFinite || maxChars <= 0) return '';
    final cleaned = raw
        .replaceAll(_controlOrBidi, '')
        .replaceAll(RegExp(r'[./\\\[\]*`~]'), '')
        .trim();
    if (_isForbiddenMapKey(cleaned)) return '';
    if (cleaned.runes.length <= maxChars) return cleaned;
    return cleaned.runes.take(maxChars).map(String.fromCharCode).join();
  }

  /// Sanitizes a Firebase Storage path segment (`mediaId` / `fileName`),
  /// stripping `/`, `\`, `..`, Windows device stems, and control/Bidi characters.
  static String sanitizeStorageSegment(String raw, {int maxChars = 128}) {
    if (!maxChars.toDouble().isFinite || maxChars <= 0) return '';
    var cleaned = raw
        .replaceAll(_controlOrBidi, '')
        .replaceAll(RegExp(r'[/\\<>:"|?*]+'), '_')
        .replaceAll('..', '_')
        .trim();
    while (cleaned.startsWith('.')) {
      cleaned = cleaned.substring(1).trimLeft();
    }
    while (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trimRight();
    }
    if (cleaned.isEmpty || _isForbiddenMapKey(cleaned)) return '';
    final dotIdx = cleaned.indexOf('.');
    final stem = dotIdx == -1 ? cleaned : cleaned.substring(0, dotIdx);
    if (_windowsReservedStem.hasMatch(stem)) {
      cleaned = '_$cleaned';
    }
    if (cleaned.length > maxChars) {
      var cut = maxChars;
      final lastUnit = cleaned.codeUnitAt(cut - 1);
      if (lastUnit >= 0xD800 && lastUnit <= 0xDBFF) {
        cut -= 1;
      }
      if (cut <= 0) return '';
      cleaned = cleaned.substring(0, cut);
    }
    return cleaned;
  }

  /// Strictly classifies an external media URL by its parsed authority host
  /// rather than substring `.contains(...)`.
  static ExternalSource classifyExternalUrlSource(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 4096 ||
        trimmed.contains(r'\') ||
        _idnDotHomoglyphs.hasMatch(trimmed) ||
        _controlOrBidi.hasMatch(trimmed)) {
      return ExternalSource.other;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.userInfo.isNotEmpty) {
      return ExternalSource.other;
    }
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return ExternalSource.other;
    }
    if (uri.host.isEmpty) return ExternalSource.other;
    final host = uri.host.toLowerCase();
    if (host == 'spotify.com' ||
        host.endsWith('.spotify.com') ||
        host == 'scdn.co' ||
        host.endsWith('.scdn.co')) {
      return ExternalSource.spotify;
    }
    if (host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be') {
      return ExternalSource.youtube;
    }
    return ExternalSource.other;
  }
}
