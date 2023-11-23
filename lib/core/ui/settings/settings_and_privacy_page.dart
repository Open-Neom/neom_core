import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_flavour.dart';
import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_constants.dart';
import '../../utils/constants/app_page_id_constants.dart';
import '../../utils/constants/app_route_constants.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/core_utilities.dart';
import '../../utils/enums/app_in_use.dart';
import '../../utils/enums/user_role.dart';
import '../widgets/app_circular_progress_indicator.dart';
import '../widgets/appbar_child.dart';
import '../widgets/header_widget.dart';
import '../widgets/title_subtitle_row.dart';
import 'app_settings_controller.dart';

class SettingsPrivacyPage extends StatelessWidget {

  const SettingsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppSettingsController>(
      id: AppPageIdConstants.settingsPrivacy,
      init: AppSettingsController(),
      builder: (_) => Scaffold(
        appBar: AppBarChild(title: AppConstants.settingsPrivacy.tr),
        backgroundColor: AppColor.main50,
        body: Obx(()=>Container(
          decoration: AppTheme.appBoxDecoration,
          child: _.isLoading ? Container(
              decoration: AppTheme.appBoxDecoration,
              child: const AppCircularProgressIndicator()) :
          ListView(
          children: <Widget>[
            HeaderWidget(_.userController.user!.name),
            TitleSubtitleRow(AppTranslationConstants.account.tr, navigateTo: AppRouteConstants.settingsAccount),
            TitleSubtitleRow(AppTranslationConstants.privacyAndPolicy.tr, navigateTo: AppRouteConstants.privacyAndTerms),
            TitleSubtitleRow(AppTranslationConstants.contentPreferences.tr, navigateTo: AppRouteConstants.contentPreferences),
            const HeaderWidget(AppTranslationConstants.general, secondHeader: true,),
            TitleSubtitleRow(AppTranslationConstants.aboutApp.tr, navigateTo: AppRouteConstants.about),
            TitleSubtitleRow(AppTranslationConstants.likeMyWork.tr, subtitle: AppTranslationConstants.buyCoffee.tr,
              onPressed: () => launchUrl(Uri.parse(AppFlavour.getBuyMeACoffeeURL(),),)),
            TitleSubtitleRow(AppTranslationConstants.contactUs.tr, subtitle: AppTranslationConstants.contactUsSub.tr,
                onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 100,
                      child: Container(
                        decoration: AppTheme.appBoxDecoration75,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.envelope,),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.gmail.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    final email = Uri.encodeFull(AppFlavour.getEmail());
                                    final subject = Uri.encodeFull('Regarding Mobile App');
                                    final uri = Uri.parse(
                                      'mailto:$email?subject=$subject',
                                    );
                                    launchUrl(uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(AppTranslationConstants.gmail.tr,),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.whatsapp,),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.whatsContact.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    CoreUtilities.launchWhatsappURL(AppFlavour.getWhatsappBusinessNumber(), AppTranslationConstants.hello.tr);
                                  },
                                ),
                                Text(AppTranslationConstants.whatsapp.tr,),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.instagram,),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.instagram.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    launchUrl(Uri.parse(AppFlavour.getInstagram(),),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.insta.tr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            TitleSubtitleRow(AppTranslationConstants.joinWhats.tr, subtitle: AppTranslationConstants.joinWhatsSub.tr,
            onPressed: () {
              AppFlavour.appInUse == AppInUse.g ? showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 100,
                      child: Container(
                        decoration: AppTheme.appBoxDecoration75,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.whatsapp,),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.whatsRock.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    launchUrl(Uri.parse('https://chat.whatsapp.com/FX7m5OJrtodLePy9YtfHo5',),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.whatsRock.tr,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(FontAwesomeIcons.whatsapp,),
                                  iconSize: 40,
                                  tooltip: AppTranslationConstants.whatsCommunity.tr,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    launchUrl(Uri.parse('https://chat.whatsapp.com/EtXFBdRIWFf00rDmYNen3n',),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  },
                                ),
                                Text(
                                  AppTranslationConstants.whatsCommunity.tr,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ) : launchUrl(Uri.parse('https://chat.whatsapp.com/HVE32LpAFyi4jABuBTV2hB',),
                mode: LaunchMode.externalApplication,
              );
              },
            ),
            //TODO
            _.userController.user!.userRole != UserRole.subscriber ?
            Column(
              children: [
                HeaderWidget(AppTranslationConstants.adminCenter.tr, secondHeader: true),
                TitleSubtitleRow(AppTranslationConstants.createCoupon.tr, navigateTo: AppRouteConstants.createCoupon),
                TitleSubtitleRow(AppTranslationConstants.createSponsor.tr, navigateTo: AppRouteConstants.createSponsor),
                TitleSubtitleRow(AppTranslationConstants.seeAnalytics.tr, navigateTo: AppRouteConstants.analytics),
                _.userController.user!.userRole == UserRole.superAdmin ?
                Column(
                  children: [
                    TitleSubtitleRow(AppTranslationConstants.runAnalyticsJobs.tr, onPressed: _.runAnalyticJobs),
                    TitleSubtitleRow(AppTranslationConstants.runProfileJobs.tr, onPressed: _.runProfileJobs),
                ],) : Container(),
              ],
            ) : Container(),
            TitleSubtitleRow("", showDivider: false, vPadding: 10, subtitle: AppTranslationConstants.settingPrivacyMsg.tr),
          ],
        ),
        ),),
    ),);
  }
}
