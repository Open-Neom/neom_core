// Conditional export for app exit functionality.
// On IO platforms, uses Platform detection + SystemNavigator.
// On web, no-op (browser tabs cannot be closed programmatically).
export 'core_exit_app_stub.dart'
    if (dart.library.io) 'core_exit_app_io.dart';
