import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/domain/model/app_user.dart';
import '../../../core/ui/widgets/custom_loader.dart';
import '../../../core/utils/app_utilities.dart';
import '../../../core/utils/constants/app_route_constants.dart';
import '../../../core/utils/constants/app_translation_constants.dart';
import '../../../core/utils/validator.dart';
import '../../domain/use_cases/forgot_password_service.dart';
import '../login/login_controller.dart';


class ForgotPasswordController extends GetxController implements ForgotPasswordService {

  final logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  CustomLoader loader = CustomLoader();

  late FocusNode _focusNode;
  FocusNode get focusNode => _focusNode;

  final TextEditingController _nameController = TextEditingController();
  TextEditingController get nameController => _nameController;

  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  fba.FirebaseAuth auth = fba.FirebaseAuth.instance;

  final Rxn<fba.User> _fbaUser = Rxn<fba.User>();
  fba.User get fbaUser => _fbaUser.value!;
  set fbaUser(fba.User? fbaUser) => _fbaUser.value = fbaUser;

  final Rxn<AppUser> _user = Rxn<AppUser>();
  AppUser? get user => _user.value;
  set user(AppUser? user) => _user.value = user;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  @override
  void onInit() async {
    super.onInit();
    logger.d("");
    _focusNode = FocusNode();
    _emailController.text = '';
    _focusNode.requestFocus();

  }

  @override
  void onReady() async {
    super.onReady();
    logger.d("");

    isLoading = false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Future<bool> submitForm(BuildContext context) async {

    String email = _emailController.text.trim();
    String validateEmailMsg = Validator.validateEmail(email);

    if(validateEmailMsg.isEmpty) {
      await auth.sendPasswordResetEmail(email: email);
    } else {
      Get.snackbar(
        AppTranslationConstants.passwordReset.tr,
        validateEmailMsg.tr,
        snackPosition: SnackPosition.bottom,);
      return false;
    }

    await Get.toNamed(AppRouteConstants.forgotPasswordSending, arguments: [AppRouteConstants.forgotPassword]);
    return true;
  }

}
