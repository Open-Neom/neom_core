// Conditional export for geolocation (getCurrentPosition).
// On IO platforms, uses the geolocator package.
// On web, uses dart:js_interop + package:web to avoid geolocator_web bug.
export 'core_geolocation_stub.dart'
    if (dart.library.io) 'core_geolocation_io.dart';
