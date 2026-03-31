import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../app_config.dart';
import '../../domain/repository/app_upload_repository.dart';
import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/media_type.dart';
import '../../utils/enums/media_upload_destination.dart';
import '../../utils/neom_error_logger.dart';
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

      final subFolder = _subFolder(uploadDestination);
      final fileName = "${uploadDestination.name.toLowerCase()}_$mediaId$extension";
      AppConfig.logger.d('uploadMediaFile - uploading to: $folderName/$subFolder/$fileName');

      final Uint8List bytes = await file.readAsBytes();
      UploadTask uploadTask = storageRef.child(folderName).child(subFolder).child(fileName).putData(bytes);
      TaskSnapshot storageSnap = await uploadTask;

      fileUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadMediaFile - success! URL: $fileUrl');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadMediaFile');
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

      final subFolder = _subFolder(uploadDestination);
      final fileName = "${uploadDestination.name.toLowerCase()}_$mediaId$extension";
      UploadTask uploadTask = storageRef.child(folderName).child(subFolder).child(fileName).putData(bytes);
      TaskSnapshot storageSnap = await uploadTask;

      fileUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadMediaBytes - success! URL: $fileUrl');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadMediaBytes');
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
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadReleaseItem');
    }

    return releaseItemUrl;
  }

  @override
  Future<String> uploadReleaseItemBytes(String fileName, Uint8List bytes, AppMediaType type) async {
    String releaseItemUrl = '';
    try {
      AppConfig.logger.d('uploadReleaseItemBytes - $fileName (${bytes.length} bytes)');
      UploadTask uploadTask = storageRef.child(AppFirestoreConstants.releaseItemsFolder).child('$fileName.${type.value}').putData(bytes);
      TaskSnapshot storageSnap = await uploadTask;
      releaseItemUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadReleaseItemBytes - success! URL: $releaseItemUrl');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadReleaseItemBytes');
    }
    return releaseItemUrl;
  }

  /// Maps upload destination to a subfolder name for organized storage.
  String _subFolder(MediaUploadDestination destination) => switch (destination) {
    MediaUploadDestination.post => 'posts',
    MediaUploadDestination.thumbnail => 'thumbnails',
    MediaUploadDestination.event => 'events',
    MediaUploadDestination.profile => 'profiles',
    MediaUploadDestination.cover => 'covers',
    MediaUploadDestination.comment => 'comments',
    MediaUploadDestination.message => 'messages',
    MediaUploadDestination.itemlist => 'itemlists',
    MediaUploadDestination.releaseItem => 'releases',
    MediaUploadDestination.sponsor => 'sponsors',
    MediaUploadDestination.ad => 'ads',
    MediaUploadDestination.room => 'rooms',
  };

}
