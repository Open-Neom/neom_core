import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/constants/url_constants.dart';
import '../widgets/appbar_child.dart';
import '../widgets/header_widget.dart';
import '../widgets/title_subtitle_row.dart';
import 'app_settings_controller.dart';

class AboutPage extends StatelessWidget {

  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColor.main50,
        appBar: AppBarChild(title: AppTranslationConstants.aboutApp.tr),
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              HeaderWidget(
                AppTranslationConstants.help.tr,
                secondHeader: true,
              ),
              TitleSubtitleRow(
                AppTranslationConstants.helpCenter.tr,
                vPadding: 0,
                showDivider: false,
                url: AppFlavour.getWebContact(),
              ),
              HeaderWidget(AppTranslationConstants.websites.tr),
              TitleSubtitleRow(
                  AppConstants.appTitle.tr,
                  showDivider: true,
                  url: AppFlavour.getLandingPageUrl(),
              ),
              TitleSubtitleRow(
                  AppConstants.blog,
                  showDivider: true,
                  url: AppFlavour.getBlogUrl(),
              ),
              HeaderWidget(AppTranslationConstants.developer.tr),
              const TitleSubtitleRow(
                AppConstants.github,
                showDivider: true,
                url: UrlConstants.devGithub
              ),
              const TitleSubtitleRow(
                AppConstants.linkedin,
                showDivider: true,
                url: UrlConstants.devLinkedIn
              ),
            ],
          ),
        ),
      ),
    );
  }
}
