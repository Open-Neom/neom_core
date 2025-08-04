import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/app_info.dart';
import '../../domain/repository/app_info_repository.dart';

import 'constants/app_firestore_collection_constants.dart';

class AppInfoFirestore implements AppInfoRepository {

  final appReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.app);

  @override
  Future<AppInfo> retrieve() async {
    AppConfig.logger.t("Retrieving App Info from Firestore");
    AppInfo appInfo = AppInfo();

    try {
      DocumentSnapshot documentSnapshot = await appReference
          .doc(AppFirestoreCollectionConstants.app).get();
      if (documentSnapshot.exists) {
        appInfo = AppInfo.fromJSON(documentSnapshot.data());
        AppConfig.logger.t("App Info Found: ${appInfo.toString()}");
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
      rethrow;
    }

    return appInfo;
  }


}
