import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'neom_error_logger.dart';

class PositionParser {
  // ignore: non_constant_identifier_names
  static Position JSONtoPosition(dynamic positionSnapshot) {
    Position position = Position(
        longitude: 0.0, latitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0, altitude: 0.0,
        heading: 0.0, speed: 0.0, speedAccuracy: 0.0,
        altitudeAccuracy: 1.0, headingAccuracy: 1.0
    );
    try {
      if (positionSnapshot != null && positionSnapshot != "null") {
        dynamic positionJSON = jsonDecode(positionSnapshot);
        double longitude = double.tryParse(positionJSON['longitude'].toString()) ?? 0;
        double latitude = double.tryParse(positionJSON['latitude'].toString()) ?? 0;
        DateTime timestamp = DateTime.now();
        double accuracy = double.tryParse(positionJSON['accuracy'].toString()) ?? 0;
        double altitude = double.tryParse(positionJSON['altitude'].toString()) ?? 0;
        double heading = double.tryParse(positionJSON['heading'].toString()) ?? 0;
        double speed = double.tryParse(positionJSON['speed'].toString()) ?? 0;
        double speedAccuracy = double.tryParse(positionJSON['speed_accuracy'].toString()) ?? 0;
        bool isMocked = positionJSON['is_mocked'];

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
            altitudeAccuracy: 1.0,
            headingAccuracy: 1.0
        );
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'JSONtoPosition');
    }

    return position;
  }
}
