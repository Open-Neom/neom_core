import 'dart:convert';
import 'package:http/http.dart' as http;

/// Stub Placemark for web.
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

/// Returns placemark on web via HTTPS reverse geocoding (BigDataCloud + OpenStreetMap Nominatim fallback).
Future<List<Placemark>> placemarkFromCoordinates(double latitude, double longitude,
    {String? localeIdentifier}) async {
  if (latitude == 0 && longitude == 0) return const [];

  final lang = localeIdentifier ?? 'es';

  // Primary: BigDataCloud client reverse geocoding (free, HTTPS, CORS-enabled)
  try {
    final uri = Uri.parse(
      'https://api-bdc.io/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=$lang',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final city = data['city']?.toString() ?? data['locality']?.toString() ?? '';
      final subdivision = data['principalSubdivision']?.toString() ?? '';
      final country = data['countryName']?.toString() ?? '';
      final countryCode = data['countryCode']?.toString() ?? '';
      final postal = data['postcode']?.toString() ?? '';

      if (city.isNotEmpty || subdivision.isNotEmpty || country.isNotEmpty) {
        return [
          Placemark(
            locality: city.isNotEmpty ? city : subdivision,
            administrativeArea: subdivision,
            country: country,
            isoCountryCode: countryCode,
            postalCode: postal,
          )
        ];
      }
    }
  } catch (_) {
    // Fallback: OpenStreetMap Nominatim
    try {
      final osmUri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&accept-language=$lang',
      );
      final osmResponse = await http.get(osmUri, headers: {
        'User-Agent': 'EMXI-App/1.0',
      }).timeout(const Duration(seconds: 6));

      if (osmResponse.statusCode == 200) {
        final osmData = jsonDecode(osmResponse.body);
        final addr = osmData['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? addr['state_district'] ?? '';
          final state = addr['state'] ?? '';
          final country = addr['country'] ?? '';
          final countryCode = addr['country_code']?.toString().toUpperCase() ?? '';
          final postal = addr['postcode'] ?? '';

          return [
            Placemark(
              locality: city.toString().isNotEmpty ? city.toString() : state.toString(),
              administrativeArea: state.toString(),
              country: country.toString(),
              isoCountryCode: countryCode,
              postalCode: postal.toString(),
            )
          ];
        }
      }
    } catch (_) {}
  }

  return const [];
}

/// Returns empty list on web — forward geocoding not available.
Future<List<Location>> locationFromAddress(String address,
    {String? localeIdentifier}) async {
  return const [];
}

