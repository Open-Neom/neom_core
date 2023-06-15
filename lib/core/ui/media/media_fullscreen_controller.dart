import 'package:get/get.dart';
import '../../utils/app_utilities.dart';

class MediaFullScreenController extends GetxController {

  var logger = AppUtilities.logger;
  String mediaUrl = "";
  bool isRemote = true;

  @override
  void onInit() async {
    super.onInit();
    logger.i("MediaFullScreen Controller Init");

    try {

      if(Get.arguments != null && Get.arguments.isNotEmpty) {
        mediaUrl = Get.arguments[0];
        if(Get.arguments.length > 1) {
          isRemote = Get.arguments[1];
        }
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }


}
