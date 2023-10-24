import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_utilities.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../widgets/appbar_child.dart';
import '../widgets/header_widget.dart';
import '../widgets/title_subtitle_row.dart';
import 'app_settings_controller.dart';

class ContentPreferencePage extends StatelessWidget {

  const ContentPreferencePage({super.key});


  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      init: AppSettingsController(),
      id: AppPageIdConstants.settingsPrivacy,
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppTranslationConstants.contentPreferences.tr),
        backgroundColor: AppColor.main50,
        body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            HeaderWidget(AppTranslationConstants.language.tr, secondHeader: true),
            TitleSubtitleRow(
                AppTranslationConstants.preferredLanguage.tr,
                subtitle: AppTranslationConstants.languageFromLocale(Get.locale!).tr,
                onPressed: () => Alert(
                  context: context,
                  style: AlertStyle(
                      backgroundColor: AppColor.main50,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  title: AppTranslationConstants.chooseYourLanguage.tr,
                  content: Obx(()=> DropdownButton<String>(
                        items: AppTranslationConstants.supportedLanguages.map<DropdownMenuItem<String>>((String language) {
                          return DropdownMenuItem<String>(
                              value: language,
                              child: Text(language.tr)
                          );
                        }).toList(),
                        onChanged: (String? selectedLanguage) {
                          _.setNewLanguage(selectedLanguage!);
                        },
                        value: _.newLanguage,
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: AppColor.main75,
                        underline: Container(
                            height: 1,
                            color: Colors.grey
                        ),
                      ),
                  ),
                  buttons: [
                    DialogButton(
                      color: AppColor.bondiBlue75,
                      onPressed: () => {
                        _.setNewLocale()
                      },
                      child: Text(AppTranslationConstants.setLocale.tr,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ).show()
            ),
            HeaderWidget(AppTranslationConstants.safety.tr, secondHeader: true),
            TitleSubtitleRow('${AppTranslationConstants.locationUsage.tr}: ${_.locationPermission.name.tr}',
              onPressed: () async {
                //Get.toNamed(GigRouteConstants.INTRO_REQUIRED_PERMISSIONS);
                _.locationPermission == LocationPermission.denied ?
                  await _.verifyLocationPermission()
                  : AppUtilities.showAlert(context, AppTranslationConstants.locationUsage.tr, AppTranslationConstants.changeThisInTheAppSettings.tr.tr);
              }
            ),
            TitleSubtitleRow(AppTranslationConstants.blockedProfiles.tr,
              onPressed: () => _.userController.profile.blockTo!.isNotEmpty
                  ? Get.toNamed(AppRouteConstants.blockedProfiles, arguments: _.userController.profile.blockTo)
                  : AppUtilities.showAlert(context, AppTranslationConstants.blockedProfiles.tr, AppTranslationConstants.blockedProfilesMsg.tr),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
