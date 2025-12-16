import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../../utils/enums/app_file_from.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';

abstract class MediaUploadService {

  Future<File> pickMedia({MediaType type = MediaType.media});
  Future<File> pickMultipleMedia({MediaType type = MediaType.media});

  Future<void> handleMedia(File file);
  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    MediaUploadDestination uploadDestination = MediaUploadDestination.post, File? imageFile,
    double ratioX = 1, double ratioY = 1, bool crop = true, BuildContext? context});
  Future<void> handleVideo({AppFileFrom appFileFrom = AppFileFrom.gallery, File? videoFile});

  Future<String?> uploadFile(MediaUploadDestination uploadDestination);
  Future<String> uploadThumbnail();
  Future<void> deleteFileFromUrl(String fileUrl);

  File getMediaFile();
  void setMediaFile(File file);

  String getMediaId();
  Future<void> setProcessedVideo(File videoFile);

  void clearMedia();

  bool mediaFileExists();

  String getReleaseFilePath();
  List<File> get releaseFiles;
  String get mediaUrl;
  MediaType get mediaType;

}
