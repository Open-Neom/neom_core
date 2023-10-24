import 'package:get/get.dart';
import '../../data/implementations/user_controller.dart';
import '../../utils/app_utilities.dart';

class AccountSettingsController extends GetxController {

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();


  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  @override
  void onInit() async {
    super.onInit();
    logger.d("AccountSettings Controller Init for userId ${userController.user?.id ?? ""}");
    isLoading = false;
  }

}
