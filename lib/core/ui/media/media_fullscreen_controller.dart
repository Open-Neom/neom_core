import 'package:get/get.dart';
import '../../utils/app_utilities.dart';

class MediaFullScreenController extends GetxController {

  var logger = AppUtilities.logger;
  String mediaUrl = "";

  @override
  void onInit() async {
    super.onInit();
    logger.i("MediaFullScreen Controller Init");

    try {

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        mediaUrl = Get.arguments[0];
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }


}
