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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (AppFlavour.appInUse == AppInUse.emxi && showPreLogo)
              ? Image.asset(AppAssets.logoAppWhite,
            height: AppTheme.fullWidth(context)/2.5,
            width: AppTheme.fullWidth(context)/2.5,
          ) : Container(),
          AppTheme.heightSpace20,
          showLogo ? Image.asset(AppFlavour.getAppLogoPath(),
            width: AppTheme.fullWidth(context)*0.75,
            fit: BoxFit.fitWidth,
          ) : Container(),
          subtitle.isEmpty ? Container() : Column(
            children: [
              showLogo ? Container() : AppTheme.heightSpace20,
              Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(1.0),
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 20.0,
                ),
              ),
            ],
          )
      ]),
    );
  }
}
