import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/ui/widgets/header_intro.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants/app_page_id_constants.dart';
import '../../../core/utils/constants/app_translation_constants.dart';
import '../widgets/login_widgets.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
        id: AppPageIdConstants.login,
        init: LoginController(),
        builder: (_) => Scaffold(
          body: Container(
            width: AppTheme.fullWidth(context),
            height: AppTheme.fullHeight(context),
            decoration: AppTheme.appBoxDecoration,
            child: _.isLoading ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                AppTheme.heightSpace20,
                Text(AppTranslationConstants.loadingAccount.tr,
                  style: const TextStyle(fontSize: 20)
                )
              ])
              : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: Platform.isIOS ? 50 : 80),
                  const HeaderIntro(),
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
                  (Platform.isIOS && !_.isIOS13) ? Container() :
                  Column(
                    children: [
                      buildSignInWithText(),
                      buildSocialBtnRow(_),
                    ],
                  ),
                  buildSignupBtn(_),
                ],
              ),
            ),
          ),
        ),
    );
  }


}
