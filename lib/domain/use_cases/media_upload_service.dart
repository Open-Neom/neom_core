import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../../utils/enums/app_file_from.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';
import '../../utils/platform/core_io.dart';

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

  /// Bytes del archivo seleccionado — usado en web donde dart:io File no funciona.
  /// Retorna null en mobile (que usa File nativo).
  Uint8List? get mediaBytes;

  /// Bytes de un archivo de release específico por índice.
  /// Usado en web para subir tracks individuales de un álbum.
  Uint8List? getReleaseFileBytes(int index);

  /// Nombre del archivo de release por índice.
  String getReleaseFileName(int index);

}
