// Conditional export for dart:io types (File, Directory, Platform).
// On IO platforms (mobile, desktop), re-exports dart:io.
// On web, exports stub classes with no-op implementations.
export 'core_io_stub.dart'
    if (dart.library.io) 'core_io_io.dart';
