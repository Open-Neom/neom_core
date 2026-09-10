import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart' as geo;

export 'package:geocoding/geocoding.dart' show Placemark, Location;

Future<List<geo.Placemark>> placemarkFromCoordinates(
  double latitude,
  double longitude, {
  String? localeIdentifier,
}) {
  return geo.Geocoding(
    locale: localeIdentifier != null ? Locale(localeIdentifier) : null,
  ).placemarkFromCoordinates(latitude, longitude);
}

Future<List<geo.Location>> locationFromAddress(
  String address, {
  String? localeIdentifier,
}) {
  return geo.Geocoding(
    locale: localeIdentifier != null ? Locale(localeIdentifier) : null,
  ).locationFromAddress(address);
}
