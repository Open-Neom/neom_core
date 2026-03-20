import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../app_config.dart';

/// Tracks user flow durations and screen activity for analytics.
///
/// Records flow start/end timestamps to measure how long key processes take
/// (registration, onboarding, login) and tracks screen visits to understand
/// what users do in the app.
///
/// Usage:
/// ```dart
/// NeomFlowTracker.startFlow('registration');
/// // ... user completes registration ...
/// NeomFlowTracker.endFlow('registration');
///
/// NeomFlowTracker.trackScreen('homePage');
/// ```
class NeomFlowTracker {

  static const String _flowLogsCollection = 'flowLogs';
  static const String _screenLogsCollection = 'screenLogs';

  /// Active flows with their start timestamps.
  static final Map<String, DateTime> _activeFlows = {};

  /// Pending completed flows to batch-write to Firestore.
  static final List<_FlowEntry> _pendingFlows = [];

  /// Pending screen visits to batch-write.
  static final List<_ScreenEntry> _pendingScreens = [];

  static bool _isFlushing = false;

  /// User ID set after login/registration for attributing events.
  static String _userId = '';

  /// Sets the current user ID for attributing flow events.
  static void setUserId(String userId) {
    _userId = userId;
  }

  /// Starts tracking a named flow (e.g. 'registration', 'onboarding', 'login').
  ///
  /// Call [endFlow] with the same name when the flow completes.
  /// If the flow was already started, it resets the start time.
  static void startFlow(String flowName, {Map<String, String>? metadata}) {
    AppConfig.logger.d('[FlowTracker] Start: $flowName');
    _activeFlows[flowName] = DateTime.now();
  }

  /// Marks a step within an active flow (e.g. 'onboarding/step_locale').
  ///
  /// Records the step with elapsed time since flow start.
  static void flowStep(String flowName, String stepName) {
    final start = _activeFlows[flowName];
    if (start == null) return;

    final elapsed = DateTime.now().difference(start).inMilliseconds;
    AppConfig.logger.d('[FlowTracker] Step: $flowName/$stepName (${elapsed}ms)');

    _pendingFlows.add(_FlowEntry(
      flowName: flowName,
      stepName: stepName,
      durationMs: elapsed,
      userId: _userId,
      timestamp: DateTime.now(),
    ));

    _tryFlush();
  }

  /// Ends a tracked flow and records total duration.
  ///
  /// [success] indicates if the flow completed successfully.
  static void endFlow(String flowName, {bool success = true}) {
    final start = _activeFlows.remove(flowName);
    if (start == null) {
      AppConfig.logger.w('[FlowTracker] endFlow called for unstarted flow: $flowName');
      return;
    }

    final durationMs = DateTime.now().difference(start).inMilliseconds;
    AppConfig.logger.d('[FlowTracker] End: $flowName (${durationMs}ms, success=$success)');

    _pendingFlows.add(_FlowEntry(
      flowName: flowName,
      stepName: success ? '_complete' : '_failed',
      durationMs: durationMs,
      userId: _userId,
      timestamp: DateTime.now(),
    ));

    _tryFlush();
  }

  /// Records a screen visit.
  static void trackScreen(String screenName) {
    _pendingScreens.add(_ScreenEntry(
      screenName: screenName,
      userId: _userId,
      timestamp: DateTime.now(),
    ));

    _tryFlush();
  }

  static void _tryFlush() {
    if (!_isFlushing && (_pendingFlows.length + _pendingScreens.length) >= 5) {
      _flush();
    }
  }

  /// Firestore document structure for `flowLogs/{flowName}`:
  /// ```json
  /// {
  ///   "flowName": "registration",
  ///   "totalCompletions": 42,
  ///   "totalFailures": 3,
  ///   "avgDurationMs": 15000,
  ///   "steps": {
  ///     "step_locale": {"count": 45, "avgDurationMs": 2000},
  ///     "step_profile_type": {"count": 44, "avgDurationMs": 5000}
  ///   },
  ///   "recentFlows": [
  ///     {"userId": "...", "durationMs": 12000, "success": true, "timestamp": ...}
  ///   ]
  /// }
  /// ```
  static Future<void> _flush() async {
    if (_isFlushing || (_pendingFlows.isEmpty && _pendingScreens.isEmpty)) return;
    _isFlushing = true;

    try {
      if (Firebase.apps.isEmpty) {
        _pendingFlows.clear();
        _pendingScreens.clear();
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // --- Flush flow entries ---
      if (_pendingFlows.isNotEmpty) {
        final flows = List<_FlowEntry>.from(_pendingFlows);
        _pendingFlows.clear();

        final Map<String, List<_FlowEntry>> byFlow = {};
        for (final f in flows) {
          byFlow.putIfAbsent(f.flowName, () => []).add(f);
        }

        for (final entry in byFlow.entries) {
          final flowName = entry.key;
          final entries = entry.value;
          final docRef = firestore.collection(_flowLogsCollection).doc(flowName);

          final completions = entries.where((e) => e.stepName == '_complete').toList();
          final failures = entries.where((e) => e.stepName == '_failed').toList();
          final steps = entries.where((e) => !e.stepName.startsWith('_')).toList();

          await firestore.runTransaction((transaction) async {
            final snapshot = await transaction.get(docRef);

            if (snapshot.exists) {
              final data = snapshot.data()!;
              final currentCompletions = (data['totalCompletions'] as int?) ?? 0;
              final currentFailures = (data['totalFailures'] as int?) ?? 0;
              final currentAvg = (data['avgDurationMs'] as num?)?.toDouble() ?? 0;
              final currentTotal = currentCompletions + currentFailures;
              final currentSteps = Map<String, dynamic>.from(data['steps'] ?? {});
              final currentRecent = List<Map<String, dynamic>>.from(data['recentFlows'] ?? []);

              // Update average duration with new completions
              double newAvg = currentAvg;
              if (completions.isNotEmpty) {
                final totalDuration = completions.fold(0, (acc, e) => acc + e.durationMs);
                final newCount = currentTotal + completions.length;
                newAvg = ((currentAvg * currentTotal) + totalDuration) / newCount;
              }

              // Update step counters
              for (final step in steps) {
                final stepData = Map<String, dynamic>.from(currentSteps[step.stepName] ?? {});
                final stepCount = (stepData['count'] as int?) ?? 0;
                final stepAvg = (stepData['avgDurationMs'] as num?)?.toDouble() ?? 0;
                final newStepCount = stepCount + 1;
                stepData['count'] = newStepCount;
                stepData['avgDurationMs'] = ((stepAvg * stepCount) + step.durationMs) / newStepCount;
                currentSteps[step.stepName] = stepData;
              }

              // Add recent flows
              for (final c in completions) {
                currentRecent.insert(0, {
                  'userId': c.userId,
                  'durationMs': c.durationMs,
                  'success': true,
                  'timestamp': Timestamp.fromDate(c.timestamp),
                });
              }
              for (final f in failures) {
                currentRecent.insert(0, {
                  'userId': f.userId,
                  'durationMs': f.durationMs,
                  'success': false,
                  'timestamp': Timestamp.fromDate(f.timestamp),
                });
              }
              if (currentRecent.length > 20) {
                currentRecent.removeRange(20, currentRecent.length);
              }

              transaction.update(docRef, {
                'totalCompletions': currentCompletions + completions.length,
                'totalFailures': currentFailures + failures.length,
                'avgDurationMs': newAvg.round(),
                'steps': currentSteps,
                'recentFlows': currentRecent,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              final stepsMap = <String, Map<String, dynamic>>{};
              for (final step in steps) {
                stepsMap[step.stepName] = {
                  'count': 1,
                  'avgDurationMs': step.durationMs,
                };
              }

              final recentFlows = <Map<String, dynamic>>[];
              for (final c in completions) {
                recentFlows.add({
                  'userId': c.userId,
                  'durationMs': c.durationMs,
                  'success': true,
                  'timestamp': Timestamp.fromDate(c.timestamp),
                });
              }
              for (final f in failures) {
                recentFlows.add({
                  'userId': f.userId,
                  'durationMs': f.durationMs,
                  'success': false,
                  'timestamp': Timestamp.fromDate(f.timestamp),
                });
              }

              transaction.set(docRef, {
                'flowName': flowName,
                'totalCompletions': completions.length,
                'totalFailures': failures.length,
                'avgDurationMs': completions.isNotEmpty
                    ? (completions.fold(0, (acc, e) => acc + e.durationMs) / completions.length).round()
                    : 0,
                'steps': stepsMap,
                'recentFlows': recentFlows,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          });
        }
      }

      // --- Flush screen entries ---
      if (_pendingScreens.isNotEmpty) {
        final screens = List<_ScreenEntry>.from(_pendingScreens);
        _pendingScreens.clear();

        // Group by screen name
        final Map<String, int> screenCounts = {};
        for (final s in screens) {
          screenCounts[s.screenName] = (screenCounts[s.screenName] ?? 0) + 1;
        }

        // Aggregate into a single daily document
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final docRef = firestore.collection(_screenLogsCollection).doc(dateKey);

        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);

          if (snapshot.exists) {
            final data = snapshot.data()!;
            final currentScreens = Map<String, dynamic>.from(data['screens'] ?? {});
            final currentTotal = (data['totalVisits'] as int?) ?? 0;

            for (final entry in screenCounts.entries) {
              currentScreens[entry.key] = ((currentScreens[entry.key] as int?) ?? 0) + entry.value;
            }

            transaction.update(docRef, {
              'screens': currentScreens,
              'totalVisits': currentTotal + screens.length,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(docRef, {
              'date': dateKey,
              'screens': screenCounts,
              'totalVisits': screens.length,
              'uniqueUsers': screens.map((s) => s.userId).where((u) => u.isNotEmpty).toSet().length,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    } catch (e) {
      AppConfig.logger.e('NeomFlowTracker flush failed: $e');
    } finally {
      _isFlushing = false;
      if ((_pendingFlows.length + _pendingScreens.length) >= 5) {
        _flush();
      }
    }
  }

  /// Force-flushes all pending events (call on app lifecycle events).
  static Future<void> flushAll() async {
    if (_pendingFlows.isNotEmpty || _pendingScreens.isNotEmpty) {
      await _flush();
    }
  }
}

class _FlowEntry {
  final String flowName;
  final String stepName;
  final int durationMs;
  final String userId;
  final DateTime timestamp;

  _FlowEntry({
    required this.flowName,
    required this.stepName,
    required this.durationMs,
    required this.userId,
    required this.timestamp,
  });
}

class _ScreenEntry {
  final String screenName;
  final String userId;
  final DateTime timestamp;

  _ScreenEntry({
    required this.screenName,
    required this.userId,
    required this.timestamp,
  });
}
