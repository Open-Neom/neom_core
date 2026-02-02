import 'dart:core';

import 'package:sint/sint.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/report.dart';
import '../../domain/use_cases/report_service.dart';
import '../../domain/use_cases/user_service.dart';
import '../../utils/enums/reference_type.dart';
import '../../utils/enums/report_type.dart';
import '../firestore/report_firestore.dart';

class ReportController extends SintController implements ReportService {
  
  final userServiceImpl = Sint.find<UserService>();

  AppProfile profile = AppProfile();

  final RxBool isLoading = true.obs;
  final RxBool _isButtonDisabled = false.obs;
  final RxString message = "".obs;
  final Rx<ReportType> _reportType = ReportType.other.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.i("Report Controller Init");

    try {
      profile = userServiceImpl.user.profiles.first;

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    AppConfig.logger.d("Report Controller Ready");
    isLoading.value = false;
  }

  @override
  void setMessage(String text) {
    message.value = text;
    update();
  }


  @override
  void setReportType(ReportType type) {
    _reportType.value = type;
    update();
  }


  @override
  Future<void> sendReport(ReferenceType referenceType, String referenceId) async {

    AppConfig.logger.d("Sending Report from User ${profile.name} ${profile.id}");
    try {

      _isButtonDisabled.value = true;
      update();

      Report report = Report(
        ownerId: profile.id,
        type: _reportType.value,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        message: message.value,
        referenceId: referenceId,
        referenceType: referenceType
      );

      ReportFirestore().insert(report);

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    _isButtonDisabled.value = false;
    update();
  }

  @override
  ReportType get reportType => _reportType.value;

  @override
  bool get isButtonDisabled => _isButtonDisabled.value;

}
