import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../app_config.dart';
import '../../domain/repository/app_upload_repository.dart';
import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';
import '../../utils/platform/core_io.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class AppUploadFirestore implements AppUploadRepository {

  final postsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.posts);
  final Reference storageRef = FirebaseStorage.instance.ref();

  @override
  Future<String> uploadMediaFile(String mediaId, File file, MediaType mediaType, MediaUploadDestination uploadDestination) async {
    String fileUrl = "";
    try {
      AppConfig.logger.d('uploadMediaFile - mediaId: $mediaId, type: ${mediaType.name}, destination: ${uploadDestination.name}');
      AppConfig.logger.d('uploadMediaFile - file path: ${file.path}');
      if (!file.existsSync()) {
        AppConfig.logger.e('El archivo no existe en la ruta: ${file.path}');
        return "";
      }
      AppConfig.logger.d('uploadMediaFile - file exists, size: ${file.lengthSync()} bytes');

      String folderName = '';
      String extension = '';
      switch(mediaType) {
        case MediaType.image:
          folderName = AppFirestoreConstants.imagesFolder;
          extension = '.jpg';
        case MediaType.video:
          folderName = AppFirestoreConstants.videosFolder;
          extension = '.mp4';
        case MediaType.audio:
          folderName = AppFirestoreConstants.audiosFolder;
          extension = '.mp3';
        case MediaType.document:
          folderName = AppFirestoreConstants.documentsFolder;
          extension = '.pdf';
        case MediaType.unknown:
          folderName = AppFirestoreConstants.miscFolder;
        default:
          break;
      }

      final fileName = "${uploadDestination.name.toLowerCase()}_$mediaId$extension";
      AppConfig.logger.d('uploadMediaFile - uploading to: $folderName/$fileName');

      final Uint8List bytes = await file.readAsBytes();
      UploadTask uploadTask = storageRef.child(folderName).child(fileName).putData(bytes);
      TaskSnapshot storageSnap = await uploadTask;

      fileUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadMediaFile - success! URL: $fileUrl');
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return fileUrl;
  }

  @override
  Future<String> uploadMediaBytes(String mediaId, Uint8List bytes, MediaType mediaType, MediaUploadDestination uploadDestination) async {
    String fileUrl = "";
    try {
      AppConfig.logger.d('uploadMediaBytes - mediaId: $mediaId, type: ${mediaType.name}, size: ${bytes.length} bytes');

      String folderName = '';
      String extension = '';
      switch(mediaType) {
        case MediaType.image:
          folderName = AppFirestoreConstants.imagesFolder;
          extension = '.jpg';
        case MediaType.video:
          folderName = AppFirestoreConstants.videosFolder;
          extension = '.mp4';
        case MediaType.audio:
          folderName = AppFirestoreConstants.audiosFolder;
          extension = '.mp3';
        case MediaType.document:
          folderName = AppFirestoreConstants.documentsFolder;
          extension = '.pdf';
        case MediaType.unknown:
          folderName = AppFirestoreConstants.miscFolder;
        default:
          break;
      }

      final fileName = "${uploadDestination.name.toLowerCase()}_$mediaId$extension";
      UploadTask uploadTask = storageRef.child(folderName).child(fileName).putData(bytes);
      TaskSnapshot storageSnap = await uploadTask;

      fileUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadMediaBytes - success! URL: $fileUrl');
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return fileUrl;
  }

  @override
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type) async {

    String releaseItemUrl = '';
    try {
      final Uint8List fileBytes = await file.readAsBytes();
      UploadTask uploadTask = storageRef.child(AppFirestoreConstants.releaseItemsFolder).child('$fileName.${type.value}').putData(fileBytes);
      TaskSnapshot storageSnap = await uploadTask;
      releaseItemUrl = await storageSnap.ref.getDownloadURL();
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    return releaseItemUrl;
  }

}
