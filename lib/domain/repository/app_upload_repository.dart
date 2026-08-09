import 'dart:typed_data';

import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';
import '../../utils/platform/core_io.dart';

/// Called with upload progress as a 0.0–1.0 fraction. Optional on every
/// method; implementations only wire it when provided.
typedef UploadProgressCallback = void Function(double progress);

abstract class AppUploadRepository {

  Future<String> uploadMediaFile(String mediaId, File file, MediaType mediaType, MediaUploadDestination uploadDestination, {UploadProgressCallback? onProgress});
  Future<String> uploadMediaBytes(String mediaId, Uint8List bytes, MediaType mediaType, MediaUploadDestination uploadDestination, {UploadProgressCallback? onProgress});
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type, {UploadProgressCallback? onProgress});
  Future<String> uploadReleaseItemBytes(String fileName, Uint8List bytes, AppMediaType type, {UploadProgressCallback? onProgress});

}
