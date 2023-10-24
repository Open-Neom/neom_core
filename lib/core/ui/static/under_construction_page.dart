import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_color.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants/app_assets.dart';
import '../../utils/constants/app_translation_constants.dart';


class UnderConstructionPage extends StatelessWidget {

  final Color? color;

  const UnderConstructionPage({this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color ?? AppColor.main50,
      body: Container(
        width: AppTheme.fullWidth(context),
        decoration: color == null ? AppTheme.appBoxDecoration : const BoxDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.underConstruction, height: 150),
              AppTheme.heightSpace10,
              Text(AppTranslationConstants.underConstruction.tr,
                style: const TextStyle(fontSize: 15)
              ),
            ]
          )
          )

      );
  }

}
