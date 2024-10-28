import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/ui/widgets/app_circular_progress_indicator.dart';
import '../../../core/ui/widgets/header_intro.dart';
import '../../../core/utils/app_color.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/constants/app_page_id_constants.dart';
import '../../../core/utils/constants/app_translation_constants.dart';
import '../widgets/login_widgets.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
        id: AppPageIdConstants.login,
        init: LoginController(),
        builder: (_) => Scaffold(
          backgroundColor: AppColor.main50,
          body: SafeArea(child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              width: AppTheme.fullWidth(context),
              height: AppTheme.fullHeight(context),
              decoration: AppTheme.appBoxDecoration,
              child: _.isLoading.value ? AppCircularProgressIndicator(
                subtitle:AppTranslationConstants.loadingAccount.tr,
                fontSize: 20,
              ) : SingleChildScrollView(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AppTheme.heightSpace20,
                  HeaderIntro(title: kDebugMode && !kIsWeb && Platform.isAndroid ? AppConstants.dev : "",),
                  AppTheme.heightSpace20,
                  Text(AppTranslationConstants.signIn.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppTheme.heightSpace10,
                  buildEmailTF(_),
                  AppTheme.heightSpace10,
                  buildPasswordTF(_),
                  buildForgotPasswordBtn(_),
                  buildLoginBtn(_),
                  (!kIsWeb && ((Platform.isIOS && !_.isIOS13OrHigher) || (!_.appInfo.value.googleLoginEnabled && !kDebugMode)))
                      ? const SizedBox.shrink() :
                  Column(
                    children: [
                      buildSignInWithText(),
                      buildSocialBtnRow(_),
                    ],
                  ),
                  buildSignupBtn(_),
                  if(MediaQuery.of(context).orientation == Orientation.landscape) AppTheme.heightSpace50,
                ],
              ),),
            ),
          ),),
        ),
    );
  }


}
