import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../widgets/appbar_child.dart';
import '../widgets/header_widget.dart';
import '../widgets/title_subtitle_row.dart';
import 'app_settings_controller.dart';

class PrivacyAndTermsPage extends StatelessWidget {

  const PrivacyAndTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: AppTranslationConstants.privacyAndPolicy.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Column(
            children: <Widget>[
              HeaderWidget(AppTranslationConstants.legal.tr),
              TitleSubtitleRow(
                AppTranslationConstants.termsOfService.tr,
                showDivider: true,
                url: AppFlavour.getTermsOfServiceUrl(),
              ),
              TitleSubtitleRow(
                AppTranslationConstants.privacyPolicy.tr,
                showDivider: true,
                url: AppFlavour.getPrivacyPolicyUrl(),
              ),
              TitleSubtitleRow(
                AppTranslationConstants.legalNotices.tr,
                showDivider: true,
                onPressed: () =>
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Theme(
                          data: ThemeData(
                            brightness: Brightness.dark,
                            fontFamily: AppTheme.fontFamily,
                            cardColor: AppColor.main50,
                          ),
                          child: LicensePage(
                            applicationVersion: AppFlavour.appVersion,
                            applicationName: AppFlavour.appInUse.value,
                          ),
                        ),
                      ),
                    )

              ),
            ],
          ),
        ),
      ),
    );
  }
}
