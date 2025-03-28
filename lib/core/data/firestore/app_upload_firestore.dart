import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/repository/app_upload_repository.dart';
import '../../utils/app_utilities.dart';
import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/upload_image_type.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'constants/app_firestore_constants.dart';

class AppUploadFirestore implements AppUploadRepository {

  final postsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.posts);
  final Reference storageRef = FirebaseStorage.instance.ref();

  @override
  Future<String> uploadImage(String mediaId, File file, UploadImageType uploadImageType) async {
    String imgUrl = "";
    try {
      if (!file.existsSync()) {
        AppUtilities.logger.e('El archivo no existe en la ruta: ${file.path}');
        return "";
      }

      UploadTask uploadTask = storageRef.child("${uploadImageType.name.toLowerCase()}_imgs")
          .child("${uploadImageType.name.toLowerCase()}_$mediaId.jpg").putFile(file);
      TaskSnapshot storageSnap = await uploadTask;

      imgUrl = await storageSnap.ref.getDownloadURL();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return imgUrl;
  }

  @override
  Future<String> uploadVideo(String mediaId, File file) async {
    String downloadURL = '';
    try {
      UploadTask uploadTask = storageRef.child(AppFirestoreConstants.videoMediaFolder)
          .child('video_$mediaId.mp4').putFile(file);
      TaskSnapshot storageSnap = await uploadTask;
      downloadURL = await storageSnap.ref.getDownloadURL();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return downloadURL;
  }

  @override
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type) async {

    String downloadURL = '';
    try {
      UploadTask uploadTask = storageRef.child(AppFirestoreConstants.releaseItemsFolder).child('$fileName.${type.value}').putFile(file);
      TaskSnapshot storageSnap = await uploadTask;
      downloadURL = await storageSnap.ref.getDownloadURL();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    return downloadURL;
  }

}
