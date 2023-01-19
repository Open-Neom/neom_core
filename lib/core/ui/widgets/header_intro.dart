import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../utils/constants/app_assets.dart';

class HeaderIntro extends StatelessWidget{

  final String subtitle;

  const HeaderIntro({this.subtitle = "", Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(AppAssets.logoAppWhite,
            height: 140,
            width: 140,
          ),
        Image.asset(AppAssets.logoCompanyWhite,
        height: 80,
        width: 320,
        ),
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
