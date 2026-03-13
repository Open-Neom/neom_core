import 'dart:typed_data';

import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';
import '../../utils/platform/core_io.dart';

abstract class AppUploadRepository {

  Future<String> uploadMediaFile(String mediaId, File file, MediaType mediaType, MediaUploadDestination uploadDestination);
  Future<String> uploadMediaBytes(String mediaId, Uint8List bytes, MediaType mediaType, MediaUploadDestination uploadDestination);
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type);
  Future<String> uploadReleaseItemBytes(String fileName, Uint8List bytes, AppMediaType type);

}
