/// Stub Placemark for web where geocoding is unavailable.
class Placemark {
  final String? name;
  final String? street;
  final String? isoCountryCode;
  final String? country;
  final String? postalCode;
  final String? administrativeArea;
  final String? subAdministrativeArea;
  final String? locality;
  final String? subLocality;
  final String? thoroughfare;
  final String? subThoroughfare;

  const Placemark({
    this.name,
    this.street,
    this.isoCountryCode,
    this.country,
    this.postalCode,
    this.administrativeArea,
    this.subAdministrativeArea,
    this.locality,
    this.subLocality,
    this.thoroughfare,
    this.subThoroughfare,
  });
}

/// Stub Location for web.
class Location {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  const Location({this.latitude = 0, this.longitude = 0, this.timestamp});
}

/// Returns empty list on web — geocoding not available.
Future<List<Placemark>> placemarkFromCoordinates(double latitude, double longitude,
    {String? localeIdentifier}) async {
  return const [];
}

/// Returns empty list on web — geocoding not available.
Future<List<Location>> locationFromAddress(String address,
    {String? localeIdentifier}) async {
  return const [];
}
