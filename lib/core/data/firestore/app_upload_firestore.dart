import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import '../../domain/repository/app_upload_repository.dart';
import '../../utils/enums/app_media_type.dart';
import '../../utils/enums/upload_image_type.dart';
import 'constants/app_firestore_collection_constants.dart';

class AppUploadFirestore implements AppUploadRepository {

  var logger = Logger();
  final postsReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.posts);
  final Reference storageRef = FirebaseStorage.instance.ref();

  @override
  Future<String> uploadImage(String mediaId, File file, UploadImageType uploadImageType) async {
    String imgUrl = "";
    try {
      UploadTask uploadTask = storageRef.child("${uploadImageType.name.toLowerCase()}""_$mediaId.jpg").putFile(file);

      TaskSnapshot storageSnap = await uploadTask;
      return await storageSnap.ref.getDownloadURL();
    } catch (e) {
      logger.e(e.toString());
    }

    return imgUrl;
  }

  @override
  Future<String> uploadVideo(String mediaId, File file) async {
    UploadTask uploadTask= storageRef.child('video_$mediaId.mp4').putFile(file); //, StorageMetadata(contentType: 'video/mp4')
    TaskSnapshot storageSnap = await uploadTask;
    return await storageSnap.ref.getDownloadURL();
  }

  @override
  Future<String> uploadReleaseItem(String fileName, File file, AppMediaType type) async {

    String downloadURL = '';
    try {
      UploadTask uploadTask = storageRef.child('ReleaseItems/$fileName.${type.value}').putFile(file);
      TaskSnapshot storageSnap = await uploadTask;
      downloadURL = await storageSnap.ref.getDownloadURL();
    } catch (e) {
      logger.e(e.toString());
    }

    return downloadURL;
  }

}
