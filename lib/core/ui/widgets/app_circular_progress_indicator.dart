import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_flavour.dart';
import '../../utils/app_theme.dart';


class AppCircularProgressIndicator extends StatelessWidget {

  final bool showLogo;
  final String subtitle;
  const AppCircularProgressIndicator({this.subtitle = '', this.showLogo = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(showLogo)
              Image.asset(AppFlavour.getIconPath(),
              height: AppTheme.fullWidth(context)/6,
              width: AppTheme.fullWidth(context)/6,
              fit: BoxFit.fitWidth,),
            if(showLogo) AppTheme.heightSpace20,
            const CircularProgressIndicator(),
            if(subtitle.isNotEmpty) Column(
              children: [
                AppTheme.heightSpace10,
                Text(subtitle.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(1.0),
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.0,
                  ),
                )
              ],
            )
          ],
        )
    );
  }

}
