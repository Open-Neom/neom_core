import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_config.dart';
import '../../domain/model/report.dart';
import '../../domain/repository/report_repository.dart';
import 'constants/app_firestore_collection_constants.dart';


class ReportFirestore implements ReportRepository {

  var logger = AppConfig.logger;
  final reportsReference = FirebaseFirestore.instance.collection(
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
    bool wasDeleted = false;
    try {
      await reportsReference.doc(report.id).delete();
    } catch (e) {
      logger.e(e.toString());
    }

    return wasDeleted;
  }

}
