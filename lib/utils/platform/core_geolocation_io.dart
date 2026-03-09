import 'package:geolocator/geolocator.dart';

/// On mobile/desktop, delegates to the geolocator package.
Future<Position?> platformGetCurrentPosition() async {
  return await Geolocator.getCurrentPosition();
}

Future<Position?> platformGetCurrentPositionHighAccuracy() async {
  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}
