// Conditional export for geocoding functionality.
// Provides Placemark, Location, placemarkFromCoordinates, and locationFromAddress.
export 'core_geocoding_stub.dart'
    if (dart.library.io) 'core_geocoding_io.dart';
