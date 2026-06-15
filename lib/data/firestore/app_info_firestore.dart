import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/neom_logger.dart';
import '../../domain/model/app_info.dart';
import '../../domain/repository/app_info_repository.dart';
import '../../utils/neom_error_logger.dart';

import 'constants/app_firestore_collection_constants.dart';

class AppInfoFirestore implements AppInfoRepository {

  final appReference = FirebaseFirestore.instance.collection(AppFirestoreCollectionConstants.app);

  @override
  Future<AppInfo> retrieve() async {
    neomLogger.t("Retrieving App Info from Firestore");
    AppInfo appInfo = AppInfo();

    try {
      DocumentSnapshot documentSnapshot = await appReference
          .doc(AppFirestoreCollectionConstants.app).get();
      if (documentSnapshot.exists) {
        appInfo = AppInfo.fromJSON(documentSnapshot.data());
        neomLogger.t("App Info Found: ${appInfo.toString()}");
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_core', operation: 'retrieve');
      rethrow;
    }

    return appInfo;
  }


}
