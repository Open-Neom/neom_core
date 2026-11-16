import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, visibleForTesting;
import 'package:sint_sentinel/sint_sentinel_core.dart';

import '../data/firestore/core_firestore_guard.dart';
import 'neom_logger.dart';
import 'secure_logger.dart';

/// Centralized error logger that sends errors to Firebase Crashlytics
/// and stores aggregated error counts in Firestore for the error monitor.
///
/// Usage:
/// ```dart
/// } catch (e, st) {
///   NeomErrorLogger.recordError(e, st, module: 'neom_shop', operation: 'retrieveProducts');
/// }
/// ```
class NeomErrorLogger {
  static String appInUseName = 'unknown';
  static String appVersion = 'unknown';

  static const String _errorLogsCollection = 'errorLogs';

  /// Maximum number of recent error messages to keep in the document.
  static const int _maxRecentErrors = 10;
  static const int _maxPendingErrors = 200;

  static final RegExp _unsafeIdentifierChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u061C\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
  );

  @visibleForTesting
  static String sanitizeTelemetryIdentifier(
    String raw, {
    String fallback = 'unknown',
    int maxLength = 64,
  }) {
    var cleaned = raw
        .replaceAll(_unsafeIdentifierChars, '')
        .replaceAll(RegExp(r'[/\\.\[\]*`~]+'), '_')
        .trim();
    if (cleaned.isEmpty ||
        cleaned == 'constructor' ||
        cleaned == 'prototype' ||
        (cleaned.length >= 4 &&
            cleaned.startsWith('__') &&
            cleaned.endsWith('__'))) {
      return fallback;
    }
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
    }
    return cleaned;
  }

  /// Optional test hook invoked with the sanitized error message.
  @visibleForTesting
  static void Function(
    String sanitizedErrorMessage,
    StackTrace? stackTrace, {
    required String module,
    required String operation,
  })? debugOnRecordError;

  /// Batch queue for throttled Firestore writes.
  static final List<_ErrorEntry> _pendingErrors = [];
  static bool _isFlushing = false;

  /// Records an error to Crashlytics and Firestore.
  ///
  /// [error] - The caught error/exception.
  /// [stackTrace] - The stack trace (pass StackTrace.current if not available from catch).
  /// [module] - The neom module name (e.g. 'neom_shop', 'neom_daw').
  /// [operation] - The operation that failed (e.g. 'retrieveProducts', 'startRecording').
  /// [fatal] - Whether this is a fatal error (default false).
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    required String module,
    required String operation,
    bool fatal = false,
    bool skipDebug = true,
  }) async {
    final safeModule = sanitizeTelemetryIdentifier(module);
    final safeOperation = sanitizeTelemetryIdentifier(operation);
    final sanitizedMessage = SecureLogger.sanitize(error.toString());
    debugOnRecordError?.call(
      sanitizedMessage,
      stackTrace,
      module: safeModule,
      operation: safeOperation,
    );

    // 1. Always log locally (redacted)
    neomLogger.e('[$safeModule/$safeOperation] $sanitizedMessage');
    if (localQaLogsEnabled) return;
    if (kDebugMode && skipDebug) return;

    // 2. Send sanitized error to Crashlytics
    _recordToCrashlytics(
      sanitizedMessage,
      stackTrace,
      safeModule,
      safeOperation,
      fatal,
    );

    // 3. Queue for Firestore aggregation (bounded)
    if (_pendingErrors.length >= _maxPendingErrors) {
      _pendingErrors.removeRange(0, _pendingErrors.length - _maxPendingErrors + 1);
    }
    _pendingErrors.add(_ErrorEntry(
      module: safeModule,
      operation: safeOperation,
      errorMessage: _truncate(sanitizedMessage, 500),
      timestamp: DateTime.now(),
    ));

    // Flush in batches to avoid excessive Firestore writes
    if (!_isFlushing && _pendingErrors.length >= 3) {
      _flush();
    }
  }

  /// Lightweight version that only logs to Crashlytics without Firestore.
  /// Use for high-frequency errors where Firestore writes would be too expensive.
  static void recordErrorLight(
    Object error,
    StackTrace? stackTrace, {
    required String module,
    required String operation,
  }) {
    final safeModule = sanitizeTelemetryIdentifier(module);
    final safeOperation = sanitizeTelemetryIdentifier(operation);
    final sanitizedMessage = SecureLogger.sanitize(error.toString());
    debugOnRecordError?.call(
      sanitizedMessage,
      stackTrace,
      module: safeModule,
      operation: safeOperation,
    );
    neomLogger.e('[$safeModule/$safeOperation] $sanitizedMessage');
    if (localQaLogsEnabled) return;
    _recordToCrashlytics(
      sanitizedMessage,
      stackTrace,
      safeModule,
      safeOperation,
      false,
    );
  }

  static void _recordToCrashlytics(
    Object error,
    StackTrace? stackTrace,
    String module,
    String operation,
    bool fatal,
  ) {
    try {
      if (kIsWeb || Firebase.apps.isEmpty) return;

      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.setCustomKey('module', module);
      crashlytics.setCustomKey('operation', operation);
      crashlytics.setCustomKey('app', appInUseName);
      crashlytics.setCustomKey('appVersion', appVersion);

      crashlytics.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: '$module/$operation',
        fatal: fatal,
      );
    } catch (_) {
      // Crashlytics itself failed — don't crash the app
    }
  }

  /// Flushes pending errors to Firestore using incremental counters.
  ///
  /// Document structure in `errorLogs/{module}`:
  /// ```json
  /// {
  ///   "module": "neom_shop",
  ///   "totalErrors": 42,
  ///   "operations": {
  ///     "retrieveProducts": 15,
  ///     "addToCart": 27
  ///   },
  ///   "recentErrors": [
  ///     {"operation": "addToCart", "message": "...", "timestamp": ...},
  ///   ],
  ///   "lastErrorAt": Timestamp,
  ///   "updatedAt": Timestamp
  /// }
  /// ```
  static Future<void> _flush() async {
    if (_isFlushing || _pendingErrors.isEmpty || SintSentinel.isBlocking) return;
    _isFlushing = true;

    try {
      if (Firebase.apps.isEmpty ||
          FirebaseAuth.instance.currentUser == null) {
        _pendingErrors.clear();
        return;
      }

      // Take a snapshot of pending errors
      final errors = List<_ErrorEntry>.from(_pendingErrors);
      _pendingErrors.clear();

      // Group by module
      final Map<String, List<_ErrorEntry>> byModule = {};
      for (final e in errors) {
        byModule.putIfAbsent(e.module, () => []).add(e);
      }

      final firestore = FirebaseFirestore.instance;

      for (final entry in byModule.entries) {
        final moduleName = entry.key;
        final moduleErrors = entry.value;
        final docRef = firestore.collection(_errorLogsCollection).doc(moduleName);

        // Count per operation
        final Map<String, int> opCounts = {};
        for (final e in moduleErrors) {
          opCounts[e.operation] = (opCounts[e.operation] ?? 0) + 1;
        }

        // Build recent errors list (newest first)
        final recentItems = moduleErrors.reversed.take(_maxRecentErrors).map((e) => {
          'operation': e.operation,
          'message': e.errorMessage,
          'timestamp': Timestamp.fromDate(e.timestamp),
        }).toList();

        await CoreFirestoreGuard.guardWrite(
          () => firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);

          if (snapshot.exists) {
            final data = snapshot.data()!;
            final currentTotal = (data['totalErrors'] as int?) ?? 0;
            final currentOps = Map<String, dynamic>.from(data['operations'] ?? {});
            final currentRecent = List<Map<String, dynamic>>.from(data['recentErrors'] ?? []);

            // Increment operation counters
            for (final op in opCounts.entries) {
              currentOps[op.key] = ((currentOps[op.key] as int?) ?? 0) + op.value;
            }

            // Merge recent errors (keep newest N)
            currentRecent.insertAll(0, recentItems);
            if (currentRecent.length > _maxRecentErrors) {
              currentRecent.removeRange(_maxRecentErrors, currentRecent.length);
            }

            transaction.update(docRef, {
              'totalErrors': currentTotal + moduleErrors.length,
              'operations': currentOps,
              'recentErrors': currentRecent,
              'lastErrorAt': Timestamp.fromDate(moduleErrors.last.timestamp),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            final opsMap = <String, int>{};
            for (final op in opCounts.entries) {
              opsMap[op.key] = op.value;
            }

            transaction.set(docRef, {
              'module': moduleName,
              'totalErrors': moduleErrors.length,
              'operations': opsMap,
              'recentErrors': recentItems,
              'lastErrorAt': Timestamp.fromDate(moduleErrors.last.timestamp),
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }),
          tag: 'NeomErrorLogger.flush',
        );
      }
    } catch (e) {
      neomLogger.e('NeomErrorLogger flush failed: $e');
    } finally {
      _isFlushing = false;
      // If more errors accumulated during flush, flush again
      if (_pendingErrors.length >= 3) {
        _flush();
      }
    }
  }

  /// Force-flushes all pending errors (call on app lifecycle events).
  static Future<void> flushAll() async {
    if (_pendingErrors.isNotEmpty) {
      await _flush();
    }
  }

  /// Resets all error counts in Firestore (admin action).
  static Future<void> resetAllCounts() async {
    try {
      if (Firebase.apps.isEmpty) return;

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection(_errorLogsCollection).get();

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      neomLogger.d('NeomErrorLogger: All error counts reset');
    } catch (e) {
      neomLogger.e('NeomErrorLogger: Reset failed: $e');
    }
  }

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    var end = maxLen;
    if (end > 0) {
      final prevUnit = s.codeUnitAt(end - 1);
      if (prevUnit >= 0xD800 && prevUnit <= 0xDBFF) {
        end -= 1;
      }
    }
    return s.substring(0, end);
  }
}

class _ErrorEntry {
  final String module;
  final String operation;
  final String errorMessage;
  final DateTime timestamp;

  _ErrorEntry({
    required this.module,
    required this.operation,
    required this.errorMessage,
    required this.timestamp,
  });
}
