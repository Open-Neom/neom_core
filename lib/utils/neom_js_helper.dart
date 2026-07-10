/// Compile-time routing for cross-platform JavaScript interoperability.
export 'neom_js_helper_stub.dart'
  if (dart.library.js) 'neom_js_helper_web.dart';
