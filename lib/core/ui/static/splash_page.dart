import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../neom_commons.dart';

class SplashPage extends StatelessWidget {

  const SplashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      id: AppPageIdConstants.splash,
      builder: (_) => Scaffold(
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.logoAppWhite,
                height: AppFlavour.appInUse == AppInUse.gigmeout ? 50 : 150,
                width: 150,
              ),
              AppFlavour.appInUse == AppInUse.emxi ?
              Column(
                children: [
                  const SizedBox(height: 20,),
                  Text("#YoSoyEMXI",
                    style: TextStyle(
                        color: Colors.white.withOpacity(1.0),
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ) : Container(),
              const SizedBox(height: 30,),
              const CircularProgressIndicator(),
              const SizedBox(height: 30,),
              Obx(() => Text(_.subtitle.tr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(1.0),
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ]
          ),
        ),
        ),
      ),
    );
  }

}
