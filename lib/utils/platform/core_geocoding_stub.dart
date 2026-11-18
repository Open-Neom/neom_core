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

const int _maxGeocodingResponseBytes = 64 * 1024;
final RegExp _safeLocaleTagPattern = RegExp(
  r'^[a-zA-Z]{2,8}(?:[-_][a-zA-Z0-9]{2,8})*$',
);

/// Sanitizes [rawLocale] into an injection-safe BCP-47 language tag (default `'es'`).
String sanitizeGeocodingLocale(String? rawLocale) {
  if (rawLocale == null) return 'es';
  final trimmed = rawLocale.trim();
  if (trimmed.isEmpty ||
      trimmed.length > 24 ||
      !_safeLocaleTagPattern.hasMatch(trimmed)) {
    return 'es';
  }
  return trimmed.replaceAll('_', '-');
}

/// Validates finite geographic bounds excluding the `(0, 0)` sentinel.
bool areValidGeocodingCoordinates(double latitude, double longitude) {
  if (!latitude.isFinite || !longitude.isFinite) return false;
  if (latitude == 0 && longitude == 0) return false;
  return latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;
}

Future<Map<String, dynamic>?> _boundedHttpsJsonGet(
  Uri uri, {
  Map<String, String>? headers,
}) async {
  final client = http.Client();
  try {
    final req = http.Request('GET', uri)..followRedirects = false;
    if (headers != null) {
      req.headers.addAll(headers);
    }
    final streamed = await client.send(req).timeout(const Duration(seconds: 6));
    if (streamed.statusCode != 200) {
      return null;
    }
    final chunks = <int>[];
    await for (final chunk in streamed.stream.timeout(const Duration(seconds: 6))) {
      if (chunks.length + chunk.length > _maxGeocodingResponseBytes) {
        return null;
      }
      chunks.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(chunks, allowMalformed: true));
    return decoded is Map<String, dynamic> ? decoded : null;
  } finally {
    client.close();
  }
}

/// Returns placemark on web via HTTPS reverse geocoding (BigDataCloud + OpenStreetMap Nominatim fallback).
Future<List<Placemark>> placemarkFromCoordinates(double latitude, double longitude,
    {String? localeIdentifier}) async {
  if (!areValidGeocodingCoordinates(latitude, longitude)) return const [];

  final lang = sanitizeGeocodingLocale(localeIdentifier);

  // Primary: BigDataCloud client reverse geocoding (free, HTTPS, CORS-enabled)
  try {
    final uri = Uri.https(
      'api-bdc.io',
      '/data/reverse-geocode-client',
      <String, String>{
        'latitude': '$latitude',
        'longitude': '$longitude',
        'localityLanguage': lang,
      },
    );
    final data = await _boundedHttpsJsonGet(uri);
    if (data != null) {
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
  } catch (_) {}

  // Fallback: OpenStreetMap Nominatim
  try {
    final osmUri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      <String, String>{
        'format': 'json',
        'lat': '$latitude',
        'lon': '$longitude',
        'accept-language': lang,
      },
    );
    final osmData = await _boundedHttpsJsonGet(
      osmUri,
      headers: const <String, String>{'User-Agent': 'EMXI-App/1.0'},
    );
    if (osmData != null) {
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

  return const [];
}

/// Returns empty list on web — forward geocoding not available.
Future<List<Location>> locationFromAddress(String address,
    {String? localeIdentifier}) async {
  return const [];
}

