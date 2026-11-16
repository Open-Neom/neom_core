import 'dart:io' show Platform;

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart' as geo;

import 'core_geocoding_stub.dart' as fallback;

export 'package:geocoding/geocoding.dart' show Placemark, Location;

bool get _supportsNativeGeocoding => Platform.isAndroid || Platform.isIOS;
bool get _isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');

Future<List<geo.Placemark>> placemarkFromCoordinates(
  double latitude,
  double longitude, {
  String? localeIdentifier,
}) async {
  if (!_supportsNativeGeocoding) {
    if (_isFlutterTest) return const <geo.Placemark>[];
    final stubs = await fallback.placemarkFromCoordinates(
      latitude,
      longitude,
      localeIdentifier: localeIdentifier,
    );
    return stubs
        .map(
          (p) => geo.Placemark(
            name: p.name,
            street: p.street,
            isoCountryCode: p.isoCountryCode,
            country: p.country,
            postalCode: p.postalCode,
            administrativeArea: p.administrativeArea,
            subAdministrativeArea: p.subAdministrativeArea,
            locality: p.locality,
            subLocality: p.subLocality,
            thoroughfare: p.thoroughfare,
            subThoroughfare: p.subThoroughfare,
          ),
        )
        .toList();
  }

  try {
    return await geo.Geocoding(
      locale: localeIdentifier != null ? Locale(localeIdentifier) : null,
    ).placemarkFromCoordinates(latitude, longitude);
  } on MissingPluginException {
    return const <geo.Placemark>[];
  } on UnimplementedError {
    return const <geo.Placemark>[];
  }
}

Future<List<geo.Location>> locationFromAddress(
  String address, {
  String? localeIdentifier,
}) async {
  if (!_supportsNativeGeocoding) {
    return const <geo.Location>[];
  }

  try {
    return await geo.Geocoding(
      locale: localeIdentifier != null ? Locale(localeIdentifier) : null,
    ).locationFromAddress(address);
  } on MissingPluginException {
    return const <geo.Location>[];
  } on UnimplementedError {
    return const <geo.Location>[];
  }
}
