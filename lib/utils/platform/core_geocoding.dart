// Conditional export for geocoding functionality.
// On IO platforms, wraps the geocoding package (placemarkFromCoordinates, etc.).
// On web, provides stubs that return empty results.
export 'core_geocoding_stub.dart'
    if (dart.library.io) 'core_geocoding_io.dart';
