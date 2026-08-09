// Conditional export: streams file uploads from disk on IO platforms,
// falls back to in-memory bytes on web (where the File stub holds no data
// and File-based upload entry points are not used at runtime).
export 'upload_task_platform_stub.dart'
    if (dart.library.io) 'upload_task_platform_io.dart';
