import 'dart:io';

import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';

abstract class AppUploadRepository {

  Future<String> uploadMediaFile(String mediaId, File file, MediaType mediaType, MediaUploadDestination uploadDestination);
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type);

}
