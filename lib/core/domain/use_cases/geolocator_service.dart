import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

abstract class GeoLocatorService {

  Future<Placemark> getPlaceMark(Position currentPos);
  Future<String> getAddressSimple(Position currentPos);
  Future<LocationPermission> requestPermission();
  Future<Position?> getCurrentPosition();
  Future<Position?> updateLocation(String profileId, Position currentPosition);

}
