import 'package:get/get.dart';
import '../../app_config.dart';
import '../../domain/model/app_profile.dart';
import '../../domain/model/app_user.dart';
import 'subscription_controller.dart';
import 'user_controller.dart';

//TODO IS MISSING INTERFACE AS SERVICE
class AppDrawerController extends GetxController {

  final userController = Get.find<UserController>();
  SubscriptionController? subscriptionController;

  AppUser user = AppUser();

  Rx<AppProfile> appProfile = AppProfile().obs;
  RxBool isButtonDisabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("SideBar Controller Init");
    user = userController.user;
    appProfile.value = userController.profile;

    if(user.subscriptionId.isEmpty) {
      subscriptionController = Get.put(SubscriptionController());
    }
  }

  void updateProfile(AppProfile profile) {
    appProfile.value = profile;
    update();
  }

}
