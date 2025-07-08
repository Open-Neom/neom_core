import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../../utils/enums/app_file_from.dart';
import '../../utils/enums/upload_image_type.dart';

abstract class PostUploadService {

  Future<void> handleMedia(File file);
  Future<void> handleImage({AppFileFrom appFileFrom = AppFileFrom.gallery,
    UploadImageType imageType = UploadImageType.post, File? imageFile, BuildContext? context});

  void clearMedia();

  Future<void> handleVideo({AppFileFrom appFileFrom = AppFileFrom.gallery, File? videoFile, BuildContext? context});
  Future<void> playPauseVideo();
  void disposeVideoPlayer();


  Future<void> handleSubmit();
  Future<void> handlePostUpload();

  void setUserLocation(String locationSuggestion);
  void clearUserLocation();
  void getBackToUploadImage(BuildContext context);
  void updatePage();

  Future<void> getLocation(context);
  File getMediaFile();
  String getMediaId();

  Future<void> setProcessedVideo(File videoFile);

}
