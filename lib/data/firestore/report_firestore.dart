import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/report.dart';
import '../../domain/repository/report_repository.dart';
import 'constants/app_firestore_collection_constants.dart';
import 'core_firestore_guard.dart';


class ReportFirestore implements ReportRepository {

  var logger = AppConfig.logger;
  CollectionReference<Map<String, dynamic>> get reportsReference =>
      FirebaseFirestore.instance.collection(
          AppFirestoreCollectionConstants.reports);


  @override
  Future<String> insert(Report report) async {
    logger.d("");
    String reportId = "";
    try {
      DocumentReference documentReference = await reportsReference.add(
          report.toJSON());
      reportId = documentReference.id;
    } catch (e) {
      logger.e(e.toString());
    }

    return reportId;
  }


  @override
  Future<bool> remove(Report report) async {
    logger.d("");
    final cleanId = report.id.trim();
    if (!CoreFirestoreGuard.isSafeDocId(cleanId)) return false;
    bool wasDeleted = false;
    try {
      await reportsReference.doc(cleanId).delete();
      wasDeleted = true;
    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }

}
