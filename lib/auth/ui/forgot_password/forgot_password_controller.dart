import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/firestore/user_firestore.dart';
import '../../../core/ui/widgets/custom_loader.dart';
import '../../../core/utils/app_utilities.dart';
import '../../../core/utils/constants/app_route_constants.dart';
import '../../../core/utils/constants/app_translation_constants.dart';
import '../../../core/utils/validator.dart';
import '../../domain/use_cases/forgot_password_service.dart';
import '../login/login_controller.dart';


class ForgotPasswordController extends GetxController implements ForgotPasswordService {

  final loginController = Get.find<LoginController>();
  CustomLoader loader = CustomLoader();

  late FocusNode focusNode;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  fba.FirebaseAuth auth = fba.FirebaseAuth.instance;

  final RxBool isLoading = true.obs;
  final RxBool isButtonDisabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    AppUtilities.logger.d("onInit ForgotPassword Controller");
    focusNode = FocusNode();
    emailController.text = '';
    focusNode.requestFocus();

  }

  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.d("");

    isLoading.value = false;
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Future<bool> submitForm(BuildContext context) async {

    String email = emailController.text.trim();
    String validateEmailMsg = Validator.validateEmail(email);
    if(await UserFirestore().isAvailableEmail(email)) {
      validateEmailMsg = AppTranslationConstants.emailNotFound.tr;
    }
    try {
      if(validateEmailMsg.isEmpty) {
        await auth.sendPasswordResetEmail(email: email);
      } else {
        Get.snackbar(AppTranslationConstants.passwordReset.tr,
          validateEmailMsg.tr,
          snackPosition: SnackPosition.bottom,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        AppTranslationConstants.passwordReset.tr,
        e.toString(),
        snackPosition: SnackPosition.bottom,);
      return false;
    }



    await Get.toNamed(AppRouteConstants.forgotPasswordSending, arguments: [AppRouteConstants.forgotPassword]);
    return true;
  }

}
