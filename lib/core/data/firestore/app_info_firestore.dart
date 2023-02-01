import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/model/app_info.dart';
import '../../domain/repository/app_info_repository.dart';
import '../../utils/app_utilities.dart';
import 'constants/app_firestore_collection_constants.dart';

class AppInfoFirestore implements AppInfoRepository {

  final logger = AppUtilities.logger;
  final appReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.app);

  @override
  Future<AppInfo> retrieve() async {
    logger.i("Retrieving App Info");
    AppInfo appInfo = AppInfo();

    try {
      DocumentSnapshot documentSnapshot = await appReference
          .doc(AppFirestoreCollectionConstants.app).get();
      if (documentSnapshot.exists) {
        appInfo = AppInfo.fromJSON(documentSnapshot.data());
        logger.i("App found with AppVersion ${appInfo.version}");
      }
    } catch (e) {
      logger.e(e.toString());
      rethrow;
    }

    return appInfo;
  }


}
