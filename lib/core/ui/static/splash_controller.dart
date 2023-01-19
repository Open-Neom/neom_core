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

  final RxString _subtitle = "".obs;
  String get subtitle => _subtitle.value;
  set subtitle(String subtitle) => _subtitle.value = subtitle;


  String fromRoute = "";
  String toRoute = "";

  @override
  void onInit() async {
    logger.d("");
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
            subtitle = AppTranslationConstants.removingAccount;
          } else if (toRoute == AppRouteConstants.profileRemove) {
            subtitle = AppTranslationConstants.removingProfile;
          }
          break;
        case AppRouteConstants.forgotPassword:
          subtitle = AppTranslationConstants.sendingPasswordRecovery;
          break;
        case AppRouteConstants.introReason:
          subtitle = AppTranslationConstants.creatingAccount;
          break;
        case AppRouteConstants.signup:
          subtitle = AppTranslationConstants.creatingAccount;
          break;
        case AppRouteConstants.introAddImage:
          subtitle = AppTranslationConstants.welcome;
          break;
        case AppRouteConstants.paymentGateway:
          subtitle = AppTranslationConstants.paymentProcessing;
          break;
        case AppRouteConstants.finishingSpotifySync:
          subtitle = AppTranslationConstants.finishingSpotifySync;
          break;
        case AppRouteConstants.refresh:
          subtitle = AppTranslationConstants.updatingApp;
          break;
        case "":
          logger.d("There is no fromRoute");
          break;
      }

    } catch (e) {
      logger.e(e.toString());
    }

  }

  @override
  void onReady() async {
    super.onReady();

    await Future.delayed(const Duration(seconds: 2));

    switch(fromRoute){
      case AppRouteConstants.home:
        await Get.offAndToNamed(toRoute);
        break;
      case AppRouteConstants.logout:
        await loginController.signOut();
        break;
      case AppRouteConstants.introRequiredPermissions:
        await loginController.signOut();
        break;
      case AppRouteConstants.accountSettings:
        if(toRoute == AppRouteConstants.accountRemove) {
          await changeSubtitle(AppTranslationConstants.removingAccount);
          await userController.removeAccount();
        } else if (toRoute == AppRouteConstants.profileRemove) {
          await changeSubtitle(AppTranslationConstants.removingProfile);
          await userController.removeProfile();
          Get.offAllNamed(AppRouteConstants.home);
        }
        break;
      case AppRouteConstants.forgotPassword:
        await changeSubtitle(AppTranslationConstants.sendingPasswordRecovery);
        break;
      case AppRouteConstants.introReason:
        await changeSubtitle(AppTranslationConstants.creatingAccount);
        await userController.createUser();
        break;
      case AppRouteConstants.signup:
        await changeSubtitle(AppTranslationConstants.creatingAccount);
        break;
      case AppRouteConstants.introAddImage:
        await changeSubtitle(AppTranslationConstants.welcome);
        await userController.createUser();
        break;
      case AppRouteConstants.createAdditionalProfile:
        await changeSubtitle(AppTranslationConstants.creatingProfile);
        await userController.createProfile();
        break;
      case AppRouteConstants.paymentGateway:
        await changeSubtitle(AppTranslationConstants.paymentProcessed);
        update([AppPageIdConstants.splash]);
        if(toRoute == AppRouteConstants.wallet) {
          await Get.offAllNamed(AppRouteConstants.home, arguments: [toRoute]);
        } else if (toRoute == AppRouteConstants.home) {
          //TODO VERIFY How to implement cleaner as event is not loaded
          //Event event = Get.find<EventDetailsController>().event;
          //await Get.offAllNamed(AppRouteConstants.home, arguments: [event]);
          await Get.offAllNamed(AppRouteConstants.home);
        }
        break;
      case AppRouteConstants.finishingSpotifySync:
        await Get.offAllNamed(AppRouteConstants.home);
        break;
      case AppRouteConstants.refresh:
        Get.offAllNamed(AppRouteConstants.home);
        break;
      case "":
        logger.d("There is no fromRoute");
        break;
    }

    if(loginController.authStatus == AuthStatus.loggingIn) {
      loginController.setAuthStatus(AuthStatus.loggedIn);
    }

    update();
  }

  Future<void> changeSubtitle(String newSubtitle) async {
    subtitle = newSubtitle;
    await Future.delayed(const Duration(seconds: 2));
    update([AppPageIdConstants.splash]);
  }

}
