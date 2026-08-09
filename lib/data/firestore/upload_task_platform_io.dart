import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// IO platforms: `putFile` streams the file from disk in chunks, so large
/// videos/audio no longer load entirely into memory via `readAsBytes()`.
///
/// Imports `dart:io` directly (not the `core_io` conditional export): this
/// file is only ever compiled for IO targets, and `putFile` requires the
/// real `dart:io` [File] type. On IO builds `core_io.File` IS this type.
Future<UploadTask> startFileUpload(
    Reference ref, File file, SettableMetadata metadata) async {
  return ref.putFile(file, metadata);
}
