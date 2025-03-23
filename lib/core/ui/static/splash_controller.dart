import 'package:get/get.dart';
import '../../../auth/ui/login/login_controller.dart';
import '../../data/implementations/user_controller.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/enums/auth_status.dart';

class SplashController extends GetxController {

  final logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  RxString subtitle = "".obs;

  String fromRoute = "";
  String toRoute = "";

  @override
  void onInit() {
    logger.t("onInit Splash");
    super.onInit();

    try {
      if (Get.arguments != null) {
        List<dynamic> arguments = Get.arguments;
        fromRoute = arguments.elementAt(0);
        if(arguments.length > 1) toRoute = arguments.elementAt(1);
      }

      switch(fromRoute){
        case AppRouteConstants.home:
          break;
        case AppRouteConstants.logout:
          break;
        case AppRouteConstants.introRequiredPermissions:
          break;
        case AppRouteConstants.accountSettings:
          if(toRoute == AppRouteConstants.accountRemove) {
            subtitle.value = AppTranslationConstants.removingAccount;
          } else if (toRoute == AppRouteConstants.profileRemove) {
            subtitle.value = AppTranslationConstants.removingProfile;
          }
          break;
        case AppRouteConstants.forgotPassword:
          subtitle.value = AppTranslationConstants.sendingPasswordRecovery;
          break;
        case AppRouteConstants.introReason:
          subtitle.value = AppTranslationConstants.creatingAccount;
          break;
        case AppRouteConstants.signup:
          subtitle.value = AppTranslationConstants.creatingAccount;
          break;
        case AppRouteConstants.introAddImage:
          subtitle.value = AppTranslationConstants.welcome;
          break;
        case AppRouteConstants.paymentGateway:
          subtitle.value = AppTranslationConstants.paymentProcessing;
          break;
        case AppRouteConstants.finishingSpotifySync:
          subtitle.value = AppTranslationConstants.finishingSpotifySync;
          break;
        case AppRouteConstants.refresh:
          subtitle.value = AppTranslationConstants.updatingApp;
          break;
        case AppRouteConstants.postUpload:
          subtitle.value = AppTranslationConstants.updatingApp;
          break;
        case "":
          logger.t("There is no fromRoute");
          break;
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() {
    super.onReady();
    logger.t("onReady Splash");

    // await Future.delayed(const Duration(seconds: 1));

    switch(fromRoute){
      case AppRouteConstants.home:
        Get.offAndToNamed(toRoute);
        break;
      case AppRouteConstants.logout:
        loginController.signOut();
        break;
      case AppRouteConstants.introRequiredPermissions:
        loginController.signOut();
        break;
      case AppRouteConstants.accountSettings:
        handleAccountSettings();
        break;
      case AppRouteConstants.forgotPassword:
        handleForgotPassword();
        break;
      case AppRouteConstants.introReason:
        changeSubtitle(AppTranslationConstants.creatingAccount);
        userController.createUser();
        break;
      case AppRouteConstants.signup:
        changeSubtitle(AppTranslationConstants.creatingAccount);
        break;
      case AppRouteConstants.introAddImage:
        changeSubtitle(AppTranslationConstants.welcome);
        userController.createUser();
        break;
      case AppRouteConstants.createAdditionalProfile:
        changeSubtitle(AppTranslationConstants.creatingProfile);
        userController.createProfile();
        break;
      case AppRouteConstants.paymentGateway:
        handlePaymentGateway();
        break;
      case AppRouteConstants.finishingSpotifySync:
        AppUtilities.showSnackBar(message: AppTranslationConstants.playlistSynchFinished.tr);
        Get.offAllNamed(AppRouteConstants.home);
        break;
      case AppRouteConstants.refresh:
        Get.offAllNamed(AppRouteConstants.home);
        break;
      case "":
        logger.t("There is no fromRoute");
        break;
    }

    if(loginController.authStatus.value == AuthStatus.loggingIn) {
      loginController.setAuthStatus(AuthStatus.loggedIn);
    }

    update();
  }

  Future<void> handlePaymentGateway() async {
    changeSubtitle(AppTranslationConstants.paymentProcessed);
    update([AppPageIdConstants.splash]);
    //TODO VERIFY FUNCTIONALITY
    // Get.delete<HomeController>();
    await Get.offAllNamed(AppRouteConstants.home, arguments: [toRoute]);
  }

  Future<void> handleAccountSettings() async {
    if(toRoute == AppRouteConstants.accountRemove) {
      changeSubtitle(AppTranslationConstants.removingAccount);
      await userController.removeAccount();
    } else if (toRoute == AppRouteConstants.profileRemove) {
      changeSubtitle(AppTranslationConstants.removingProfile);
      await userController.removeProfile();
      Get.offAllNamed(AppRouteConstants.home);
    }
  }

  Future<void> handleForgotPassword() async {
    changeSubtitle(AppTranslationConstants.sendingPasswordRecovery);
    Get.offAllNamed(AppRouteConstants.login);
    Get.snackbar(
      AppTranslationConstants.passwordReset.tr,
      AppTranslationConstants.passwordEmailResetSent.tr,
      snackPosition: SnackPosition.bottom,);
  }

  void changeSubtitle(String newSubtitle) {
    subtitle.value = newSubtitle;
    // await Future.delayed(const Duration(seconds: 1));
  }

}
