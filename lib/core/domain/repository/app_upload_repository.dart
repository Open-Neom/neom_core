import 'dart:io';

import '../../utils/enums/upload_image_type.dart';

abstract class AppUploadRepository {

  Future<String> uploadImage(String mediaId, File file, UploadImageType uploadImageType);
  Future<String> uploadVideo(String mediaId, File file);
  Future<String> uploadPdf(String mediaId, File file);

}
