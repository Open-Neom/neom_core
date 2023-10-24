import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../widgets/appbar_child.dart';
import '../widgets/header_widget.dart';
import '../widgets/title_subtitle_row.dart';
import 'account_settings_controller.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AccountSettingsController>(
      init: AccountSettingsController(),
      builder: (_) => Scaffold(
      appBar: AppBarChild(title: AppTranslationConstants.accountSettings.tr),
      backgroundColor: AppColor.main50,
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: ListView(
        children: <Widget>[
          HeaderWidget(AppTranslationConstants.loginAndSecurity.tr),
          TitleSubtitleRow(
            AppTranslationConstants.username.tr,
            subtitle: _.userController.user!.name,
          ),
          const Divider(height: 0),
          TitleSubtitleRow(
            AppTranslationConstants.phone.tr,
            subtitle: _.userController.user!.phoneNumber.isEmpty ? AppTranslationConstants.notSpecified.tr : "${_.userController.user!.countryCode}${_.userController.user!.phoneNumber}",
          ),
          TitleSubtitleRow(
            AppTranslationConstants.emailAddress.tr,
            subtitle: _.userController.user!.email,
          ),
          const Divider(height: 0),
          _.userController.user?.profiles.length == 1 ? Container() :
          TitleSubtitleRow(AppTranslationConstants.removeProfile.tr,  textColor: AppColor.ceriseRed,
            onPressed: (){
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      backgroundColor: AppColor.main50,
                      title: Text(AppTranslationConstants.removeThisAccount.tr),
                      children: <Widget>[
                        SimpleDialogOption(
                          child: Text(
                            AppTranslationConstants.remove.tr,
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Get.toNamed(AppRouteConstants.profileRemove, arguments: [AppRouteConstants.accountSettings, AppRouteConstants.profileRemove]);
                          },
                        ),
                        SimpleDialogOption(
                          child: Text(
                            AppTranslationConstants.cancel.tr,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  }
              );

            },
          ),
          TitleSubtitleRow(AppTranslationConstants.removeAccount.tr,  textColor: AppColor.ceriseRed,
              onPressed: (){
                showDialog(
                    context: context,
                    builder: (context) {
                      return SimpleDialog(
                        backgroundColor: AppColor.main50,
                        title: Text(AppTranslationConstants.removeThisAccount.tr),
                        children: <Widget>[
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.remove.tr,
                              style: const TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Get.toNamed(AppRouteConstants.accountRemove, arguments: [AppRouteConstants.accountSettings, AppRouteConstants.accountRemove]);
                            },
                          ),
                          SimpleDialogOption(
                            child: Text(
                              AppTranslationConstants.cancel.tr,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    }
                    );

             },
          ),
        ],
      ),
    ),),
    );
  }
}
