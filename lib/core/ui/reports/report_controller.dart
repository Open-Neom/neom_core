import 'dart:core';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:get/get.dart';

import '../../data/firestore/report_firestore.dart';
import '../../data/implementations/user_controller.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/report.dart';
import '../../domain/use_cases/report_service.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/enums/reference_type.dart';
import '../../utils/enums/report_type.dart';

class ReportController extends GetxController implements ReportService {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxString _message = "".obs;
  String get message => _message.value;
  set message(String message) => _message.value = message;

  final RxString _reportType = ReportType.other.name.obs;
  String get reportType => _reportType.value;
  set reportType(String reportType) => _reportType.value = reportType;


  @override
  void onInit() async {
    super.onInit();
    logger.i("Report Controller Init");

    try {
      profile = userController.user!.profiles.first;

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();
    logger.d("Report Controller Ready");
    isLoading = false;
  }

  @override
  void setMessage(String text) {
    message = text;
    update([AppPageIdConstants.report]);
  }


  @override
  void setReportType(String type) {
    reportType = type;
    update([AppPageIdConstants.report]);
  }


  @override
  Future<void> sendReport(ReferenceType referenceType, String referenceId) async {

    logger.d("Sending Report from User ${profile.name} ${profile.id}");
    try {

      isButtonDisabled = true;
      update([AppPageIdConstants.report]);

      Report report = Report(
        ownerId: profile.id,
        type: EnumToString.fromString(ReportType.values, reportType) ?? ReportType.other,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        message: message,
        referenceId: referenceId,
        referenceType: referenceType
      );

      report.id = await ReportFirestore().insert(report);

      Get.back();
      Get.back();

    } catch (e) {
      logger.e(e.toString());
    }

    isButtonDisabled = false;
    update([AppPageIdConstants.report]);
  }


}
