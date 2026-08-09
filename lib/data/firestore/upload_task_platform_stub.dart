import 'package:firebase_storage/firebase_storage.dart';

import '../../utils/platform/core_io.dart';

/// Web fallback: the platform `File` is a stub without disk access, and the
/// File-based entry points are not exercised on web at runtime (web callers
/// use the `*Bytes` variants). Kept so the shared code compiles everywhere.
Future<UploadTask> startFileUpload(
    Reference ref, File file, SettableMetadata metadata) async {
  final bytes = await file.readAsBytes();
  return ref.putData(bytes, metadata);
}
