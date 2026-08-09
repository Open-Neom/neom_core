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
import '../../utils/upload_metadata_resolver.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';
import 'upload_task_platform.dart';

class AppUploadFirestore implements AppUploadRepository {

  final postsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.posts);
  final Reference storageRef = FirebaseStorage.instance.ref();

  /// Firebase Storage error codes worth retrying (transient/network).
  /// Everything else (unauthorized, quota, canceled, not-found…) fails fast.
  static const Set<String> _retryableStorageCodes = {
    'unknown',
    'retry-limit-exceeded',
    'invalid-checksum',
    'server-file-wrong-size',
  };

  static const int _maxUploadAttempts = 3;

  @override
  Future<String> uploadMediaFile(String mediaId, File file, MediaType mediaType, MediaUploadDestination uploadDestination, {UploadProgressCallback? onProgress}) async {
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
      switch(mediaType) {
        case MediaType.image:
          folderName = AppFirestoreConstants.imagesFolder;
        case MediaType.video:
          folderName = AppFirestoreConstants.videosFolder;
        case MediaType.audio:
          folderName = AppFirestoreConstants.audiosFolder;
        case MediaType.document:
          folderName = AppFirestoreConstants.documentsFolder;
        case MediaType.media:
        case MediaType.unknown:
          folderName = AppFirestoreConstants.miscFolder;
      }

      // Preserve the real file extension (a .m4a must not be stored as .mp3);
      // fall back to the historical per-type default for unknown sources.
      final extension = UploadMetadataResolver.resolveExtension(
          filePath: file.path, mediaType: mediaType);
      final metadata = SettableMetadata(
          contentType: UploadMetadataResolver.contentTypeForExtension(extension));

      final subFolder = _subFolder(uploadDestination);
      final fileName = "${uploadDestination.name.toLowerCase()}_$mediaId$extension";
      AppConfig.logger.d('uploadMediaFile - uploading to: $folderName/$subFolder/$fileName ($metadata)');

      final ref = storageRef.child(folderName).child(subFolder).child(fileName);
      final storageSnap = await _uploadWithRetry(
          () => startFileUpload(ref, file, metadata), onProgress: onProgress);

      fileUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadMediaFile - success! URL: $fileUrl');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadMediaFile');
    }

    return fileUrl;
  }

  @override
  Future<String> uploadMediaBytes(String mediaId, Uint8List bytes, MediaType mediaType, MediaUploadDestination uploadDestination, {UploadProgressCallback? onProgress}) async {
    String fileUrl = "";
    try {
      AppConfig.logger.d('uploadMediaBytes - mediaId: $mediaId, type: ${mediaType.name}, size: ${bytes.length} bytes');

      String folderName = '';
      switch(mediaType) {
        case MediaType.image:
          folderName = AppFirestoreConstants.imagesFolder;
        case MediaType.video:
          folderName = AppFirestoreConstants.videosFolder;
        case MediaType.audio:
          folderName = AppFirestoreConstants.audiosFolder;
        case MediaType.document:
          folderName = AppFirestoreConstants.documentsFolder;
        case MediaType.media:
        case MediaType.unknown:
          folderName = AppFirestoreConstants.miscFolder;
      }

      final extension = UploadMetadataResolver.defaultExtensionFor(mediaType);
      final metadata = SettableMetadata(
          contentType: UploadMetadataResolver.contentTypeForExtension(extension));

      final subFolder = _subFolder(uploadDestination);
      final fileName = "${uploadDestination.name.toLowerCase()}_$mediaId$extension";
      final ref = storageRef.child(folderName).child(subFolder).child(fileName);
      final storageSnap = await _uploadWithRetry(
          () async => ref.putData(bytes, metadata), onProgress: onProgress);

      fileUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadMediaBytes - success! URL: $fileUrl');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadMediaBytes');
    }

    return fileUrl;
  }

  @override
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type, {UploadProgressCallback? onProgress}) async {

    String releaseItemUrl = '';
    try {
      final metadata = SettableMetadata(
          contentType: UploadMetadataResolver.contentTypeForAppMediaType(type));
      final ref = storageRef.child(AppFirestoreConstants.releaseItemsFolder)
          .child('$fileName.${type.value}');
      final storageSnap = await _uploadWithRetry(
          () => startFileUpload(ref, file, metadata), onProgress: onProgress);
      releaseItemUrl = await storageSnap.ref.getDownloadURL();
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadReleaseItem');
    }

    return releaseItemUrl;
  }

  @override
  Future<String> uploadReleaseItemBytes(String fileName, Uint8List bytes, AppMediaType type, {UploadProgressCallback? onProgress}) async {
    String releaseItemUrl = '';
    try {
      AppConfig.logger.d('uploadReleaseItemBytes - $fileName (${bytes.length} bytes)');
      final metadata = SettableMetadata(
          contentType: UploadMetadataResolver.contentTypeForAppMediaType(type));
      final ref = storageRef.child(AppFirestoreConstants.releaseItemsFolder)
          .child('$fileName.${type.value}');
      final storageSnap = await _uploadWithRetry(
          () async => ref.putData(bytes, metadata), onProgress: onProgress);
      releaseItemUrl = await storageSnap.ref.getDownloadURL();
      AppConfig.logger.i('uploadReleaseItemBytes - success! URL: $releaseItemUrl');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'uploadReleaseItemBytes');
    }
    return releaseItemUrl;
  }

  /// Runs one upload to completion with retries on transient Storage errors.
  ///
  /// The returned URL contract stays `String` (empty on total failure) for
  /// backwards compatibility, but failure is no longer silent: it is logged
  /// through [NeomErrorLogger] after [_maxUploadAttempts] attempts, and every
  /// call site validates the empty result.
  Future<TaskSnapshot> _uploadWithRetry(
      Future<UploadTask> Function() start, {UploadProgressCallback? onProgress}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final uploadTask = await start();
        final progressSub = onProgress == null ? null
            : uploadTask.snapshotEvents.listen((snapshot) {
                if (snapshot.totalBytes > 0) {
                  onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
                }
              });
        try {
          return await uploadTask;
        } finally {
          await progressSub?.cancel();
        }
      } catch (e) {
        final retryable = e is FirebaseException &&
            _retryableStorageCodes.contains(e.code);
        if (attempt >= _maxUploadAttempts || !retryable) {
          AppConfig.logger.e('Upload failed definitively '
              '(attempt $attempt/$_maxUploadAttempts, retryable: $retryable): $e');
          rethrow;
        }
        AppConfig.logger.w('Transient upload error '
            '(attempt $attempt/$_maxUploadAttempts): $e — retrying');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
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
