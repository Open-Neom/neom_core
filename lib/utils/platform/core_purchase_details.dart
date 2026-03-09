// Conditional export for in-app purchase serialization.
// On IO platforms, uses in_app_purchase_android/storekit types.
// On web, provides stub serialization functions.
export 'core_purchase_details_stub.dart'
    if (dart.library.io) 'core_purchase_details_io.dart';
