import 'dart:async';
import 'dart:js_interop';

import 'package:geolocator/geolocator.dart';
import 'package:web/web.dart' as web;

/// On web, bypasses geolocator_web (which has a LegacyJavaScriptObject bug)
/// and calls the browser Geolocation API directly via dart:js_interop.
Future<Position?> platformGetCurrentPosition() async {
  return _browserGetCurrentPosition(enableHighAccuracy: false);
}

Future<Position?> platformGetCurrentPositionHighAccuracy() async {
  return _browserGetCurrentPosition(enableHighAccuracy: true);
}

Future<Position?> _browserGetCurrentPosition({required bool enableHighAccuracy}) async {
  final completer = Completer<Position?>();

  try {
    web.window.navigator.geolocation.getCurrentPosition(
      (web.GeolocationPosition pos) {
        final coords = pos.coords;
        completer.complete(Position(
          latitude: coords.latitude,
          longitude: coords.longitude,
          timestamp: DateTime.fromMillisecondsSinceEpoch(pos.timestamp),
          altitude: coords.altitude ?? 0.0,
          altitudeAccuracy: coords.altitudeAccuracy ?? 0.0,
          accuracy: coords.accuracy,
          heading: coords.heading ?? 0.0,
          headingAccuracy: 0.0,
          speed: coords.speed ?? 0.0,
          speedAccuracy: 0.0,
        ));
      }.toJS,
      (web.GeolocationPositionError error) {
        completer.complete(null);
      }.toJS,
      web.PositionOptions(
        enableHighAccuracy: enableHighAccuracy,
        timeout: 10000,
        maximumAge: 0,
      ),
    );
  } catch (_) {
    completer.complete(null);
  }

  return completer.future;
}
