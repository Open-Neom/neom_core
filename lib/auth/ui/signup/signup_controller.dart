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

  final logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();
  CustomLoader loader = CustomLoader();

  final TextEditingController _firstNameController = TextEditingController();
  TextEditingController get firstNameController => _firstNameController;

  final TextEditingController _lastNameController = TextEditingController();
  TextEditingController get lastNameController => _lastNameController;

  final TextEditingController _usernameController = TextEditingController();
  TextEditingController get usernameController => _usernameController;

  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  final TextEditingController _passwordController = TextEditingController();
  TextEditingController get passwordController => _passwordController;

  final TextEditingController _confirmController = TextEditingController();
  TextEditingController get confirmController => _confirmController;

  final Rxn<AppUser> _user = Rxn<AppUser>();
  AppUser? get user => _user.value;
  set user(AppUser? user) => _user.value = user;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _isButtonDisabled = false.obs;
  bool get isButtonDisabled => _isButtonDisabled.value;
  set isButtonDisabled(bool isButtonDisabled) => _isButtonDisabled.value = isButtonDisabled;

  final RxString _email = "".obs;
  String get email => _email.value;
  set email(String email) => _email.value = email;

  final RxString _password = "".obs;
  String get password => _password.value;
  set password(String password) => _password.value = password;

  final RxBool _agreeTerms = false.obs;
  bool get agreeTerms => _agreeTerms.value;
  set agreeTerms(bool agreeTerms) => _agreeTerms.value = agreeTerms;

  @override
  void onInit() async {
    super.onInit();
    logger.d("");
  }

  @override
  void onReady() async {
    super.onReady();
    logger.d("");
    isLoading = false;
    // _firstNameController.text = "JEME";
    // _lastNameController.text = "MONTOYA";
    // _emailController.text = "jonas"+Random().nextInt(1000).toString()+"@gmail.com";
    // _passwordController.text = "123123123";
    // _usernameController.text = "Jonazxvss";
    // _confirmController.text = "123123123";
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Future<bool> submit(BuildContext context) async {

    try {

      if(await validateInfo()) {
        User? fbaUser = (await loginController.auth
            .createUserWithEmailAndPassword(
            email: _emailController.text.toLowerCase().trim(),
            password: _passwordController.text.trim())
        ).user;

        loginController.signedInWith = SignedInWith.signUp;
        loginController.fbaUser = fbaUser;
        setUserFromSignUp();
        Get.offAllNamed(AppRouteConstants.introCreating, arguments: [AppRouteConstants.signup]);

      }
    } on FirebaseAuthException catch (e) {
      String fbAuthExceptionMsg = "";
      switch(e.code) {
        case AppFirestoreConstants.emailInUse:
          fbAuthExceptionMsg = MessageTranslationConstants.emailUsed;
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
    logger.d("Getting User Info From Sign-up text fields");

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
      logger.e(e.toString());
    }

    logger.d(userController.user.toString());
  }

  @override
  Future<bool> validateInfo() async {

    Validator validator = Validator();

    String validatorMsg = validator.validateName(_firstNameController.text);

    if (validatorMsg.isEmpty) {

      validatorMsg = validator.validateName(_lastNameController.text);

      if (validatorMsg.isEmpty) {
        validatorMsg = validator.validateUsername(_usernameController.text);

        if (validatorMsg.isEmpty && _emailController.text.isEmpty
            && _passwordController.text.isEmpty) {
          validatorMsg = MessageTranslationConstants.pleaseFillSignUpForm;
        }

        if (validatorMsg.isEmpty) {
          validatorMsg = validator.validateEmail(_emailController.text);
        }
        if (validatorMsg.isEmpty) {
          validatorMsg = validator.validatePassword(
            _passwordController.text, _confirmController.text);
        }
      }
    }

    if(validatorMsg.isEmpty && !await UserFirestore().isAvailableEmail(_emailController.text)) {
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
    logger.d("");
    try {
      agreeTerms = agree;
    } catch (e) {
      logger.e(e.toString());
    }

    update([AppPageIdConstants.signUp]);
  }

}
