import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'neom_error_logger.dart';

class PositionParser {
  static const int _maxSafeEpochMs = 8640000000000000;
  static const int _maxSnapshotJsonLength = 65536;

  // ignore: non_constant_identifier_names
  static Position JSONtoPosition(dynamic positionSnapshot) {
    Position position = _defaultPosition();
    try {
      if (positionSnapshot == null) return position;

      Map<dynamic, dynamic>? positionJSON;
      if (positionSnapshot is Map) {
        positionJSON = positionSnapshot;
      } else if (positionSnapshot is String) {
        final trimmed = positionSnapshot.trim();
        if (trimmed.isEmpty ||
            trimmed == 'null' ||
            trimmed.length > _maxSnapshotJsonLength) {
          return position;
        }
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          positionJSON = decoded;
        }
      }

      if (positionJSON != null) {
        final double longitude = _parseDouble(positionJSON['longitude'])
            .clamp(-180.0, 180.0)
            .toDouble();
        final double latitude = _parseDouble(positionJSON['latitude'])
            .clamp(-90.0, 90.0)
            .toDouble();
        final DateTime timestamp = _parseTimestamp(positionJSON['timestamp']);
        final double accuracy = _nonNegative(_parseDouble(positionJSON['accuracy']));
        final double altitude = _parseDouble(positionJSON['altitude']);
        final double heading = _parseDouble(positionJSON['heading']);
        final double speed = _nonNegative(_parseDouble(positionJSON['speed']));
        final double speedAccuracy = _nonNegative(
          _parseDouble(
            positionJSON['speed_accuracy'] ?? positionJSON['speedAccuracy'],
          ),
        );
        final double altitudeAccuracy = _nonNegative(
          _parseDouble(
            positionJSON['altitude_accuracy'] ?? positionJSON['altitudeAccuracy'],
            fallback: 1.0,
          ),
        );
        final double headingAccuracy = _nonNegative(
          _parseDouble(
            positionJSON['heading_accuracy'] ?? positionJSON['headingAccuracy'],
            fallback: 1.0,
          ),
        );
        final bool isMocked = _parseBool(
          positionJSON['is_mocked'] ?? positionJSON['isMocked'],
        );

        position = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: timestamp,
          accuracy: accuracy,
          altitude: altitude,
          heading: heading,
          speed: speed,
          speedAccuracy: speedAccuracy,
          isMocked: isMocked,
          altitudeAccuracy: altitudeAccuracy,
          headingAccuracy: headingAccuracy,
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'JSONtoPosition');
    }

    return position;
  }

  static Position _defaultPosition() => Position(
        longitude: 0.0,
        latitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      );

  static double _parseDouble(dynamic raw, {double fallback = 0.0}) {
    if (raw == null) return fallback;
    final double? parsed = raw is num
        ? raw.toDouble()
        : double.tryParse(raw.toString().trim());
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed;
  }

  static double _nonNegative(double value) => value < 0.0 ? 0.0 : value;

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw == 1;
    if (raw is String) {
      final lower = raw.trim().toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is num && raw.isFinite) {
      final intVal = raw.toInt();
      if (intVal > 0 && intVal <= _maxSafeEpochMs) {
        return DateTime.fromMillisecondsSinceEpoch(intVal);
      }
    }
    if (raw is String) {
      final trimmed = raw.trim();
      final asInt = int.tryParse(trimmed);
      if (asInt != null && asInt > 0 && asInt <= _maxSafeEpochMs) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
