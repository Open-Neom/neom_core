import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app_flavour.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/app_translation_constants.dart';
import '../../utils/enums/app_in_use.dart';

class HeaderIntro extends StatelessWidget{

  final String subtitle;
  final bool showLogo;
  final bool showPreLogo;

  const HeaderIntro({this.subtitle = "", this.showLogo = true, this.showPreLogo = true, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (AppFlavour.appInUse == AppInUse.emxi && showPreLogo)
              ? Image.asset(AppAssets.logoAppWhite,
            height: 140,
            width: 140,
          ) : Container(),
          showLogo ? Image.asset(AppFlavour.appInUse == AppInUse.emxi
              ? AppAssets.logoCompanyWhite : (AppTranslationConstants.languageFromLocale(Get.locale!)
              == AppTranslationConstants.spanish ? AppAssets.logoSloganSpanish
              : AppAssets.logoSloganEnglish),
            height: 180,
            width: 320,
          ) : Container(),
          subtitle.isEmpty ? Container() : Text(subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
          color: Colors.white.withOpacity(1.0),
          fontFamily: AppTheme.fontFamily,
          fontSize: 20.0,
          ),
        ),
      ]),
    );
  }
}
