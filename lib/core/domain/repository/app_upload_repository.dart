import 'dart:io';

import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/upload_image_type.dart';

abstract class AppUploadRepository {

  Future<String> uploadImage(String mediaId, File file, UploadImageType uploadImageType);
  Future<String> uploadVideo(String mediaId, File file);
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type);

}
