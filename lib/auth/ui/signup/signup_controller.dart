import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/firestore/constants/app_firestore_constants.dart';
import '../../../core/data/firestore/user_firestore.dart';
import '../../../core/data/implementations/user_controller.dart';
import '../../../core/domain/model/app_user.dart';
import '../../../core/ui/widgets/custom_loader.dart';
import '../../../core/utils/app_utilities.dart';
import '../../../core/utils/constants/app_page_id_constants.dart';
import '../../../core/utils/constants/app_route_constants.dart';
import '../../../core/utils/constants/app_translation_constants.dart';
import '../../../core/utils/constants/message_translation_constants.dart';
import '../../../core/utils/validator.dart';
import '../../domain/use_cases/signup_service.dart';
import '../../utils/enums/signed_in_with.dart';
import '../login/login_controller.dart';

class SignUpController extends GetxController implements SignUpService {

  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();
  CustomLoader loader = CustomLoader();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final RxBool agreeTerms = false.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("");
  }

  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.d("");
    isLoading.value = false;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Future<bool> submit(BuildContext context) async {

    try {

      if(await validateInfo()) {
        User? fbaUser = (await loginController.auth
            .createUserWithEmailAndPassword(
            email: emailController.text.toLowerCase().trim(),
            password: passwordController.text.trim())
        ).user;

        loginController.signedInWith = SignedInWith.signUp;
        loginController.fbaUser.value = fbaUser;
        setUserFromSignUp();
        Get.offAllNamed(AppRouteConstants.introCreating, arguments: [AppRouteConstants.signup]);

      }
    } on FirebaseAuthException catch (e) {
      String fbAuthExceptionMsg = "";
      switch(e.code) {
        case AppFirestoreConstants.emailInUse:
          fbAuthExceptionMsg = MessageTranslationConstants.emailUsed;
          break;
        case AppFirestoreConstants.operationNotAllowed:
          fbAuthExceptionMsg = AppFirestoreConstants.operationNotAllowed;
          break;
        case "":
          break;
      }

      Get.snackbar(
          MessageTranslationConstants.accountSignUp.tr,
          fbAuthExceptionMsg.tr,
          snackPosition: SnackPosition.bottom);

      return false;
    } catch (e) {
      Get.snackbar(
          MessageTranslationConstants.accountSignUp.tr,
          e.toString(),
          snackPosition: SnackPosition.bottom);
      return false;
    }

    return true;
  }

  void setUserFromSignUp() {
    AppUtilities.logger.d("Getting User Info From Sign-up text fields");

    try {
      userController.user =  AppUser(
        homeTown: AppTranslationConstants.somewhereUniverse.tr,
        photoUrl: "",
        name: usernameController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.toLowerCase().trim(),
        id: emailController.text.toLowerCase().trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.d(userController.user.toString());
  }

  @override
  Future<bool> validateInfo() async {

    String validatorMsg = Validator.validateName(firstNameController.text);

    if (validatorMsg.isEmpty) {

      validatorMsg = Validator.validateName(lastNameController.text);

      if (validatorMsg.isEmpty) {
        validatorMsg = Validator.validateUsername(usernameController.text);

        if (validatorMsg.isEmpty && emailController.text.isEmpty
            && passwordController.text.isEmpty) {
          validatorMsg = MessageTranslationConstants.pleaseFillSignUpForm;
        }

        if (validatorMsg.isEmpty) {
          validatorMsg = Validator.validateEmail(emailController.text);
        }
        if (validatorMsg.isEmpty) {
          validatorMsg = Validator.validatePassword(
            passwordController.text, confirmController.text);
        }
      }
    }

    if(validatorMsg.isEmpty && !await UserFirestore().isAvailableEmail(emailController.text)) {
      validatorMsg = MessageTranslationConstants.emailUsed;
    }

    if (validatorMsg.isNotEmpty) {
      Get.snackbar(
          MessageTranslationConstants.accountSignUp.tr,
          validatorMsg.tr,
          snackPosition: SnackPosition.bottom);
      return false;
    }

    return true;
  }

  @override
  void setTermsAgreement(bool agree) {
    AppUtilities.logger.d("");
    try {
      agreeTerms.value = agree;
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.signUp]);
  }

}
