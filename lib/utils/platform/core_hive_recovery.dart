// Conditional export for Hive box recovery.
// On IO platforms, deletes corrupted .hive/.lock files and reopens.
// On web (IndexedDB), simply reopens the box.
export 'core_hive_recovery_stub.dart'
    if (dart.library.io) 'core_hive_recovery_io.dart';
