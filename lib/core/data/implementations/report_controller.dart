import 'dart:core';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:get/get.dart';

import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/report.dart';
import '../../domain/use_cases/report_service.dart';
import '../../utils/enums/reference_type.dart';
import '../../utils/enums/report_type.dart';
import '../firestore/report_firestore.dart';
import 'user_controller.dart';

class ReportController extends GetxController implements ReportService {
  
  final userController = Get.find<UserController>();

  AppProfile profile = AppProfile();

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;
  final RxString message = "".obs;
  final RxString reportType = ReportType.other.name.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.i("Report Controller Init");

    try {
      profile = userController.user.profiles.first;

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
  void setReportType(String type) {
    reportType.value = type;
    update();
  }


  @override
  Future<void> sendReport(ReferenceType referenceType, String referenceId) async {

    AppConfig.logger.d("Sending Report from User ${profile.name} ${profile.id}");
    try {

      isButtonDisabled.value = true;
      update();

      Report report = Report(
        ownerId: profile.id,
        type: EnumToString.fromString(ReportType.values, reportType.value) ?? ReportType.other,
        createdTime: DateTime.now().millisecondsSinceEpoch,
        message: message.value,
        referenceId: referenceId,
        referenceType: referenceType
      );

      ReportFirestore().insert(report);

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

    isButtonDisabled.value = false;
    update();
  }

  // @override
  // Future<void> showSendReportAlert(BuildContext context, String referenceId,
  //     {ReferenceType referenceType = ReferenceType.post}) async {
  //   Alert(
  //       context: context,
  //       style: AlertStyle(
  //         backgroundColor: AppColor.main50,
  //         titleStyle: const TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //       title: AppTranslationConstants.sendReport.tr,
  //       content: Column(
  //         children: <Widget>[
  //           Obx(()=>
  //               DropdownButton<String>(
  //                 dropdownColor: AppColor.getMain(),
  //                 items: ReportType.values.map((ReportType reportType) {
  //                   return DropdownMenuItem<String>(
  //                     value: reportType.name,
  //                     child: Text(reportType.name.tr),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? reportType) {
  //                   setReportType(reportType ?? "");
  //                 },
  //                 value: reportType.value,
  //                 alignment: Alignment.center,
  //                 icon: const Icon(Icons.arrow_downward),
  //                 iconSize: 20,
  //                 elevation: 16,
  //                 style: const TextStyle(color: Colors.white),
  //                 underline: Container(height: 1, color: Colors.grey,),
  //               ),
  //           ),
  //           TextField(
  //             onChanged: (text) {
  //               setMessage(text);
  //             },
  //             decoration: InputDecoration(
  //                 labelText: AppTranslationConstants.message.tr
  //             ),
  //           ),
  //         ],
  //       ),
  //       buttons: [
  //         DialogButton(
  //           color: AppColor.bondiBlue75,
  //           onPressed: () async {
  //             if(!isButtonDisabled.value) {
  //               sendReport(referenceType, referenceId);
  //               Navigator.pop(context);
  //               Navigator.pop(context);
  //               AppUtilities.showSnackBar(message: AppTranslationConstants.hasSentReport);
  //             }
  //           },
  //           child: Text(AppTranslationConstants.send.tr,
  //             style: const TextStyle(fontSize: 15),
  //           ),
  //         )
  //       ]
  //   ).show();
  //   update();
  // }


}
